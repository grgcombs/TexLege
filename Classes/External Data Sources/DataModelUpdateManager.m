//
//  DataModelUpdateManager.m
//  Created by Gregory Combs on 1/26/11.
//
//  StatesLege by Sunlight Foundation, based on work at https://github.com/sunlightlabs/StatesLege
//
//  This work is licensed under the Creative Commons Attribution-NonCommercial 3.0 Unported License. 
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc/3.0/
//  or send a letter to Creative Commons, 444 Castro Street, Suite 900, Mountain View, California, 94041, USA.
//
//

#import "DataModelUpdateManager.h"
#import "UtilityMethods.h"
#import "TexLegeReachability.h"
#import "TexLegeCoreDataUtils.h"
#import "LocalyticsSession.h"
#import "DistrictMapObj+RestKit.h"
#import "NSDate+Helper.h"
#import "SLToastManager+TexLege.h"
#import <SLToastKit/SLToastKit.h>
#import "LegislatorObj.h"

#define TXLUPDMGR_CLASSKEY		@"className"
#define TXLUPDMGR_QUERYKEY		@"queryType"
#define TXLUPDMGR_UPDATEDPROP	@"updatedDate"
#define TXLUPDMGR_UPDATEDPARAM	@"updated_since"


// QUERIES RETURN AN ARRAY OF ROWS
typedef NS_ENUM(NSUInteger, TXL_QueryTypes) {
    QUERYTYPE_IDS_NEW = 1,		//	 *filtered* by updated_since;	contains only primaryKey
    QUERYTYPE_IDS_ALL_PRUNE,	//	 **PRUNES CORE DATA**		;	contains only primaryKey
    QUERYTYPE_COMPLETE_NEW,		//   *filtered* by updated_since;	contains *all* properties
    QUERYTYPE_COMPLETE_ALL		//						all rows;	contains *all* properties
};

#define queryIsComplete(query) (query >= QUERYTYPE_COMPLETE_NEW)
#define queryIsNew(query) ((query == QUERYTYPE_IDS_NEW) || (query == QUERYTYPE_COMPLETE_NEW))

#define numToInt(number) (number ? [number integerValue] : 0)	// should this be NSNotFound or nil or null?
#define intToNum(integer) @(integer)

@interface DataModelUpdateManager()
@property (nonatomic,copy) NSDictionary *labelsForEntities;

@property (nonatomic,copy) NSCountedSet *activeUpdates;
@property (nonatomic,strong) NSMutableOrderedSet *updateErrors;
@property (nonatomic,strong) RKRequestQueue *requestQueue;

// Someday we may opt to handle updating for this aggregate partisanship file.  Right now it's manually updated.
// In the future, we might use a method like the following to get timestamps and update accordingly.
#define WNOMAGGREGATES_UPDATING 0
#if WNOMAGGREGATES_UPDATING
- (NSString *) localDataTimestampForArray:(NSArray *)entityArray;
#endif	
@end

@implementation DataModelUpdateManager

- (instancetype) init
{
    self = [super init];
	if (self)
    {
        //[[NSURLCache sharedURLCache] setMemoryCapacity:1024*1024]; // a more conservative value, 1MB

		_requestQueue = [[RKRequestQueue alloc] init];
        _requestQueue.delegate = self;
		_requestQueue.concurrentRequestsLimit = 1;
        _requestQueue.showsNetworkActivityIndicatorWhenBusy = YES;

		_activeUpdates = [[NSCountedSet alloc] init];
        _updateErrors = [[NSMutableOrderedSet alloc] init];

        NSString *file = @"DataTableUI";
        _labelsForEntities = @{
                               @"LegislatorObj": NSLocalizedStringFromTable(@"Legislators", file, nil),
                               @"WnomObj": NSLocalizedStringFromTable(@"Partisanship Scores", file, nil),
                               @"StafferObj": NSLocalizedStringFromTable(@"Staffers", file, nil),
                               @"CommitteeObj": NSLocalizedStringFromTable(@"Committees", file,nil),
                               @"CommitteePositionObj": NSLocalizedStringFromTable(@"Committee Positions", file, nil),
                               @"DistrictOfficeObj": NSLocalizedStringFromTable(@"District Offices", file, nil),
                               @"LinkObj": NSLocalizedStringFromTable(@"Resources", file, nil),
                               @"DistrictMapObj": NSLocalizedStringFromTable(@"District Maps", file, nil),
                               //@"WnomAggregateObj": NSLocalizedStringFromTable(@"Party Scores", file, nil),
                               };
	}
	return self;
}


- (void)dealloc {
	[[RKClient sharedClient].requestQueue cancelRequestsWithDelegate:self];
	[_requestQueue cancelRequestsWithDelegate:self];
}

#pragma mark - Check & Perform Updates

- (void)performDataUpdatesIfAvailable:(id)sender
{
    if (![TexLegeReachability texlegeReachable])
        return;

	NSArray *knownObjectTypes = self.labelsForEntities.allKeys;

    [[LocalyticsSession sharedLocalyticsSession] tagEvent:@"DATABASE_UPDATE_REQUEST"];

    NSString *statusString = NSLocalizedStringFromTable(@"Checking for Data Updates", @"DataTableUI", nil);

    SLToastManager *toastMgr = [SLToastManager txlSharedManager];
    [toastMgr addToastWithIdentifier:@"TXLStartingUpdates"
                                type:SLToastTypeActivity
                               title:NSLocalizedString(@"Data Update", nil)
                            subtitle:statusString
                               image:nil
                            duration:5];

    self.activeUpdates = [NSCountedSet set];
    self.updateErrors = [[NSMutableOrderedSet alloc] init];

    RKObjectManager* objectManager = [RKObjectManager sharedManager];
    RKObjectMappingProvider *provider = objectManager.mappingProvider;

    for (NSString *objectType in knownObjectTypes)
    {
        Class entityClass = NSClassFromString(objectType);

        [self.activeUpdates addObject:objectType];

        NSString *resourcePath = [NSString stringWithFormat:@"/%@.json", objectType];

        RKObjectLoader *loader = [objectManager objectLoaderWithResourcePath:resourcePath delegate:self];
        loader.method = RKRequestMethodGET;
        loader.cachePolicy = RKRequestCachePolicyDefault; // RKRequestCachePolicyEtag;
        loader.backgroundPolicy = RKRequestBackgroundPolicyContinue;
        loader.userData = @{TXLUPDMGR_CLASSKEY: objectType};

        if (entityClass)
        {
            if (!loader.objectMapping)
            {
                RKObjectMapping *mapping = [provider objectMappingForClass:entityClass];
                if (mapping)
                    loader.objectMapping = mapping;
            }
            if (!loader.objectMapping.objectClass && entityClass)
                loader.objectMapping.objectClass = entityClass;
        }

       //NSMutableURLRequest *request = loader.URLRequest;
       // request.cachePolicy = NSURLRequestUseProtocolCachePolicy;

        [_requestQueue addRequest:loader];
    }

    if (_requestQueue.count)
        [_requestQueue start];
}

// Send a simple query to our server's REST API.  The queryType determines the content and the resulting actions once we receive the response
- (void)queryIDsForModel:(NSString *)entityName
{
	NSString *resourcePath = [[NSString alloc] initWithFormat:@"/rest_ids.php/%@/", entityName];
	RKRequest *request = [[RKClient sharedClient] get:resourcePath delegate:self];	
	if (request && entityName)
    {
		request.userData = @{TXLUPDMGR_CLASSKEY: entityName,
                             TXLUPDMGR_QUERYKEY: intToNum(QUERYTYPE_IDS_ALL_PRUNE)};
	}
	else {
		NSLog(@"DataUpdateManager Error, unable to obtain RestKit request for %@", resourcePath);
	}
}

// This scans the core data entity looking for "stale" objects, ones that were deleted on the server database
- (void)pruneModel:(NSString *)className forUpstreamIDs:(NSArray *)upstreamIDs
{
	Class entityClass = NSClassFromString(className);

	if (!entityClass || ![[TexLegeCoreDataUtils registeredDataModels] containsObject:className])
		return;			// What do we do for WnomAggregateObj ???

	RKObjectManager* objectManager = [RKObjectManager sharedManager];

	BOOL changed = NO;
	
	NSSet *existingSet = [NSSet setWithArray:[TexLegeCoreDataUtils allPrimaryKeyIDsInEntityNamed:className]];	
	NSSet *newSet = [NSSet setWithArray:upstreamIDs];
	
	// Determine which items were removed
	NSMutableSet *removedItems = [NSMutableSet setWithSet:existingSet];
	[removedItems minusSet:newSet];
	
	for (NSNumber *staleObjID in removedItems)
    {
		NSLog(@"DataUpdateManager: PRUNING OBJECT FROM %@: ID = %@", className, staleObjID);
		[TexLegeCoreDataUtils deleteObjectInEntityNamed:className withPrimaryKeyValue:staleObjID];			
		changed = YES;
	}

	if (changed)
    {
		[objectManager.objectStore save];

		NSString *notification = [NSString stringWithFormat:@"RESTKIT_LOADED_%@", className.uppercaseString];
		[[NSNotificationCenter defaultCenter] postNotificationName:notification object:nil];
	}
}

#pragma mark RKRequestQueueDelegate methods

- (void)requestQueue:(RKRequestQueue *)queue didSendRequest:(RKRequest *)request
{
    NSLog(@"Queue %@ is current loading %d of %d requests", queue, (int)queue.loadingCount, (int)queue.count);
}

- (void)requestQueueDidBeginLoading:(RKRequestQueue *)queue
{
    NSLog(@"Queue %@ was initiated", queue);
}

- (void)requestQueueDidFinishLoading:(RKRequestQueue *)queue
{
    NSUInteger remainingCount = self.requestQueue.count;
	if (remainingCount > 0)
    {
#ifdef DEBUG
        for (RKRequest *request in self.requestQueue.requests)
        {
            NSLog(@"Still remaining: %@", request.URL);
        }
#endif
        return;
    }

    NSLog(@"Queue %@ finished loading.  No more pending requests.", queue);
#warning  GREG why isn't this working??
    SLToastType type = (self.updateErrors.count ==  0) ? SLToastTypeSuccess : SLToastTypeWarning;
    SLToastManager *toastMgr = [SLToastManager txlSharedManager];
    [toastMgr addToastWithIdentifier:@"TXLFinishedUpdates"
                                type:type
                               title:NSLocalizedString(@"Data Update", @"")
                            subtitle:NSLocalizedStringFromTable(@"Update Completed", @"DataTableUI", nil)
                               image:nil
                            duration:2];
}

#pragma mark - RKRequestDelegate methods

- (void)request:(RKRequest*)request didFailLoadWithError:(NSError*)error
{
    NSLog(@"Error loading data model query from %@: %@", [request description], [error localizedDescription]);

    NSString *entityName = [[request.URL lastPathComponent] stringByDeletingPathExtension];
    NSString *title = [NSLocalizedStringFromTable(@"Error During Update", @"AppAlerts", nil) stringByAppendingFormat:@": %@", entityName];

    SLToastManager *toastMgr = [SLToastManager txlSharedManager];

    if (error)
        [self.updateErrors addObject:error];

    [toastMgr addToastWithIdentifier:@"TXLUpdateError"
                                type:SLToastTypeError
                               title:title
                            subtitle:[error localizedDescription]
                               image:nil
                            duration:-1];
}

- (void)request:(RKRequest*)request didLoadResponse:(RKResponse*)response
{
    if (!request.isGET || ![response isOK])
        return;

    if (!request.userData)
        return; // We've got no user data, can't do anything...


#if 0
    NSString *objectTypeName = [request userData][TXLUPDMGR_CLASSKEY];
//  NSInteger queryType = numToInt((request.userData)[TXLUPDMGR_QUERYKEY]);
    if (NO == queryIsComplete(queryType))  // we're only working with an array of IDs
    {
        NSError *error = nil;
        NSArray *resultIDs = [NSJSONSerialization JSONObjectWithData:response.body options:NSJSONReadingMutableLeaves | NSJSONReadingMutableContainers error:&error];

        if (resultIDs && resultIDs.count)
        {
            if (queryType == QUERYTYPE_IDS_NEW)
            {
                // DO SOMETHING
            }
            else if (queryType == QUERYTYPE_IDS_ALL_PRUNE)
            {
                [self pruneModel:className forUpstreamIDs:resultIDs];
            }
        }
    }
#endif
}

#pragma mark -
#pragma mark RKObjectLoaderDelegate methods

- (void)objectLoaderDidLoadUnexpectedResponse:(RKObjectLoader *)objectLoader
{
    NSString *className = NSStringFromClass(objectLoader.objectMapping.objectClass);
    if (!className)
    {
        className = objectLoader.userData[TXLUPDMGR_CLASSKEY];
    }
    RKResponse *response = objectLoader.response;
    if (response.isFailure || response.isError)
        return;

    BOOL isAcceptable = NO;
    NSInteger statusCode = response.statusCode;
    BOOL isSuccessful = response.isSuccessful;
    BOOL shouldBeAcceptable = isAcceptable;
    BOOL hasData = (response.body != nil);

    if (isSuccessful)
    {
        shouldBeAcceptable = ([response isJSON]);
        if (!shouldBeAcceptable)
            shouldBeAcceptable = [response.MIMEType hasSuffix:@"json"];
        if (!shouldBeAcceptable)
            shouldBeAcceptable = ([response.MIMEType isEqualToString:@"text/plain"]
                                  && [response.URL.pathExtension isEqualToString:@"json"]);
    }

    NSLog(@"Unexpected response for %@ -- %d: %d  (data: %d; success: %d; should be: %d;)",
          objectLoader.URL.absoluteString,
          (int)isAcceptable,
          (int)statusCode,
          (int)hasData,
          (int)isSuccessful,
          (int)shouldBeAcceptable);
}

- (void)objectLoader:(RKObjectLoader*)objectLoader didLoadObjects:(NSArray*)objects
{
    NSString *className = NSStringFromClass(objectLoader.objectMapping.objectClass);
    if (!className)
        className = objectLoader.userData[TXLUPDMGR_CLASSKEY];
    if (!className)
        return;

	@try {
        [self.activeUpdates removeObject:className];

        if (objects && objects.count)
        {
            NSString *notification = [NSString stringWithFormat:@"RESTKIT_LOADED_%@", className.uppercaseString];
            debug_NSLog(@"%@ %lu objects", notification, (unsigned long)[objects count]);

            NSString *statusString = [NSString stringWithFormat:NSLocalizedStringFromTable(@"Updated %@", @"DataTableUI", nil), self.labelsForEntities[className]];
            SLToastManager *infoManager = [SLToastManager txlSharedManager];
            if (infoManager)
            {
                NSString *identifier = [@"TXLUpdates-" stringByAppendingString:className];
                SLToast *infoItem = [[SLToast alloc] initWithIdentifier:identifier
                                                                           type:SLToastTypeActivity
                                                                          title:NSLocalizedString(@"Data Update", @"")
                                                                       subtitle:statusString
                                                                          image:nil
                                                                       duration:2];

                [infoManager addToast:infoItem];

            }

            // We shouldn't do a costly reset if there's another reset headed our way in a few seconds.
            NSString *districtMapName = NSStringFromClass([DistrictMapObj class]);
            NSString *legislatorName = NSStringFromClass([LegislatorObj class]);
            if (
                ([className isEqualToString:districtMapName]
                 && ![self.activeUpdates containsObject:legislatorName])
                || ([className isEqualToString:legislatorName]
                    && ![self.activeUpdates containsObject:districtMapName]))
            {
                for (DistrictMapObj *map in [DistrictMapObj allObjects])
                {
                    [map resetRelationship:self];
                }
            }
            [[RKObjectManager sharedManager].objectStore save];
            [[NSNotificationCenter defaultCenter] postNotificationName:notification object:nil];
        }

//        [self queryIDsForModel:className];	// THIS TRIGGERS A PRUNING
    }			
	@catch (NSException * e) {
		NSLog(@"RestKit Load Error %@: %@", className, e.description);
	}	
}

- (void)objectLoader:(RKObjectLoader*)objectLoader didFailWithError:(NSError*)error
{
	[[LocalyticsSession sharedLocalyticsSession] tagEvent:@"RESTKIT_DATA_ERROR"];

    SLToastManager *infoManager = [SLToastManager txlSharedManager];
    if (infoManager)
    {
        [infoManager addToastWithIdentifier:@"TXLUpdatesError"
                                       type:SLToastTypeError
                                      title:NSLocalizedString(@"Data Update", @"")
                                   subtitle:NSLocalizedStringFromTable(@"Error During Update", @"AppAlerts", nil)
                                      image:nil
                                   duration:-1];
    }

    NSString *className = NSStringFromClass(objectLoader.objectMapping.objectClass);
    if (!className)
        className = objectLoader.userData[TXLUPDMGR_CLASSKEY];

	if (className)
		[self.activeUpdates removeObject:className];

	NSLog(@"RestKit Data error loading %@: %@", className, error.localizedDescription);
}

#pragma mark - Efficient Updates

- (NSString *)localDataTimestampForModel:(NSString *)classString
{
    if (!classString)
        return nil;

    Class modelClass = NSClassFromString(classString);
	if (modelClass)
    {
		NSFetchRequest *request = [modelClass fetchRequest];
		NSSortDescriptor *desc = [[NSSortDescriptor alloc] initWithKey:TXLUPDMGR_UPDATEDPROP ascending:NO];	// the most recent update will be the first item in the array (descending)
		request.sortDescriptors = @[desc];

        // This is necessary to limit it to specific properties during the fetch
        request.resultType = NSDictionaryResultType;
		request.propertiesToFetch = @[TXLUPDMGR_UPDATEDPROP];

        NSManagedObject *object = [modelClass objectWithFetchRequest:request];
        if (!object)
            return nil;

        // this relies on objectWithFetchRequest returning the object at index 0
		return [object valueForKey:TXLUPDMGR_UPDATEDPROP];
	}
	else if ([classString isEqualToString:@"WnomAggregateObj"])
    {
#if WNOMAGGREGATES_UPDATING
		NSError *error = nil;
		NSString *path = [[UtilityMethods applicationDocumentsDirectory] stringByAppendingPathComponent:@"WnomAggregateObj.json"];
		NSString *json = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
		if (!error && json)
        {
			NSArray *aggregates = [json objectFromJSONString];
			NSString *timestamp = [self localDataTimestampForArray:aggregates];
		}
		else
        {
			NSLog(@"DataModelUpdateManager:timestampForModel - error loading aggregates json - %@", path);
		}
#endif
	}
	
	return nil;
}

#if WNOMAGGREGATES_UPDATING
- (NSString *) localDataTimestampForArray:(NSArray *)entityArray
{
	if (!entityArray || ![entityArray count])
		return [[NSDate date] timestampString];
	
	NSMutableArray *tempSorted = [[NSMutableArray alloc] initWithArray:entityArray];
	NSSortDescriptor *desc = [[NSSortDescriptor alloc] initWithKey:JSONDATA_TIMESTAMPKEY ascending:NO];	// the most recent update will be the first item in the array (descending)
	[tempSorted sortUsingDescriptors:desc];
	[desc release];

	NSString *timestamp = nil;
	id object = [[tempSorted objectAtIndex:0] objectForKey:JSONDATA_TIMESTAMPKEY];
	if (!object)
    {
		NSLog(@"DataModelUpdateManager:timestampForArray - no 'updated' timestamp key found.");
	}
	else if ([object isKindOfClass:[NSString class]])
		timestamp = object;
	else if ([object isKindOfClass:[NSDate class]])
		timestamp = [object timestampString];
	else
    {
		NSLog(@"DataModelUpdateManager:timestampForArray - Unexpected type in dictionary, wanted timestamp string, %@", [object description]);
	}

	[tempSorted release];
	return timestamp;
}
#endif

@end
