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
#import "PartyPartisanshipObj.h"
#import "PartisanIndexStats.h"
#import "TexLegePrivateStrings.h"

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

@interface DataModelUpdateManager()
@property (nonatomic,copy) NSDictionary *labelsForEntities;

@property (nonatomic,copy) NSCountedSet *activeUpdates;
@property (nonatomic,strong) NSMutableOrderedSet *updateErrors;
@property (nonatomic,strong) RKRequestQueue *requestQueue;
@property (nonatomic,assign) BOOL didPostCompletionToast;

@end

@implementation DataModelUpdateManager

- (instancetype) init
{
    self = [super init];
	if (self)
    {
		_requestQueue = [[RKRequestQueue alloc] init];
        _requestQueue.delegate = self;
		_requestQueue.concurrentRequestsLimit = 1;
        _requestQueue.showsNetworkActivityIndicatorWhenBusy = YES;

        _updateErrors = [[NSMutableOrderedSet alloc] init];

        NSString *file = @"DataTableUI";
        _labelsForEntities = @{
                               @"PartyPartisanshipObj": NSLocalizedStringFromTable(@"Party Scores", file, nil),
                               @"LegislatorObj": NSLocalizedStringFromTable(@"Legislators", file, nil),
                               @"WnomObj": NSLocalizedStringFromTable(@"Partisanship Scores", file, nil),
                               @"StafferObj": NSLocalizedStringFromTable(@"Staffers", file, nil),
                               @"CommitteeObj": NSLocalizedStringFromTable(@"Committees", file,nil),
                               @"CommitteePositionObj": NSLocalizedStringFromTable(@"Committee Positions", file, nil),
                               @"DistrictOfficeObj": NSLocalizedStringFromTable(@"District Offices", file, nil),
                               @"LinkObj": NSLocalizedStringFromTable(@"Resources", file, nil),
                               @"DistrictMapObj": NSLocalizedStringFromTable(@"District Maps", file, nil),
                               };
	}
	return self;
}

- (void)dealloc {
	[[RKClient sharedClient].requestQueue cancelRequestsWithDelegate:self];
	[_requestQueue cancelRequestsWithDelegate:self];
}

- (void)addUpdateActivity:(NSString *)updateName
{
    if (!updateName)
        return;
    NSCountedSet *activeUpdates = self.activeUpdates;
    if (!activeUpdates)
    {
        activeUpdates = [[NSCountedSet alloc] init];
        self.activeUpdates = activeUpdates;
    }
    [activeUpdates addObject:updateName];
}

- (void)removeUpdateActivity:(NSString *)updateName
{
    if (!updateName)
        return;
    NSCountedSet *activeUpdates = self.activeUpdates;
    if (!activeUpdates)
        return;
    [activeUpdates removeObject:updateName];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self didChangeUpdateActivity];
    });
}

- (void)resetUpdateActivity
{
    self.activeUpdates = nil;
    self.updateErrors = [[NSMutableOrderedSet alloc] init];
}

- (UInt8)activeUpdateCount
{
    NSCountedSet *activeUpdates = self.activeUpdates;
    if (!activeUpdates)
        return 0;
    return activeUpdates.count;
}

- (BOOL)hasUpdateActivityFor:(NSString *)updateName
{
    if (!updateName)
        return NO;
    return [self.activeUpdates containsObject:updateName];
}

#pragma mark - Check & Perform Updates

- (void)performDataUpdatesIfAvailable:(id)sender
{
    if (![TexLegeReachability texlegeReachable])
        return;

    self.didPostCompletionToast = NO;

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

    [self resetUpdateActivity];

    RKObjectManager* objectManager = [RKObjectManager sharedManager];
    RKObjectMappingProvider *provider = objectManager.mappingProvider;

    for (NSString *objectType in knownObjectTypes)
    {
        [self addUpdateActivity:objectType];

        NSString *resourcePath = nil;

#if USE_PRIVATE_MYSQL_SERVER
        resourcePath = [NSString stringWithFormat:@"/rest.php/%@", objectType];
#else
        resourcePath = [NSString stringWithFormat:@"/%@.json", objectType];
#endif
        //NSString *resourcePath = [NSString stringWithFormat:@"/rest.php/%@/", entityName];
        //NSDictionary *queryParams = @{TXLUPDMGR_UPDATEDPARAM: localTS};

        RKObjectLoader *loader = nil;
        if ([objectType isEqualToString:NSStringFromClass([PartyPartisanshipObj class])])
        {
            #if USE_PRIVATE_MYSQL_SERVER
                resourcePath = @"/rest.php/WnomAggregateObj";
            #else
                resourcePath = @"/WnomAggregateObj.json";
            #endif

            loader = [RKObjectLoader loaderWithResourcePath:resourcePath objectManager:objectManager delegate:self];
            loader.cachePolicy = RKRequestCachePolicyDefault | RKRequestCachePolicyLoadIfOffline;
            loader.cacheTimeoutInterval = 60 * 60 * 3; // don't abuse the network for it since this isn't updated often
        }
        else
        {
            loader = [objectManager objectLoaderWithResourcePath:resourcePath delegate:self];
            loader.cachePolicy = RKRequestCachePolicyEtag;
        }
        loader.method = RKRequestMethodGET;
        loader.backgroundPolicy = RKRequestBackgroundPolicyContinue;
        loader.userData = @{TXLUPDMGR_CLASSKEY: objectType};

        Class entityClass = NSClassFromString(objectType);
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
                             TXLUPDMGR_QUERYKEY: @(QUERYTYPE_IDS_ALL_PRUNE)};
	}
	else {
		NSLog(@"DataUpdateManager Error, unable to obtain RestKit request for %@", resourcePath);
	}
}

#pragma mark RKRequestQueueDelegate methods

- (void)requestQueue:(RKRequestQueue *)queue didSendRequest:(RKRequest *)request
{
    NSLog(@"Queue %@ is currently loading %d of %d requests", queue, (int)queue.loadingCount, (int)queue.count);
}

- (void)requestQueueDidBeginLoading:(RKRequestQueue *)queue
{
    NSLog(@"Queue %@ was initiated with %d requests", queue, (int)queue.count);
}

- (void)didChangeUpdateActivity
{
    UInt8 remainingCount = [self activeUpdateCount];
	if (remainingCount > 0 || self.didPostCompletionToast)
        return;
    self.didPostCompletionToast = YES;

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

- (void)objectLoader:(RKObjectLoader*)objectLoader didLoadObjects:(NSArray*)objects
{
    NSString *className = NSStringFromClass(objectLoader.objectMapping.objectClass);
    if (!className)
        className = objectLoader.userData[TXLUPDMGR_CLASSKEY];
    if (!className)
        return;

    [self removeUpdateActivity:className];

	@try {

        if (objects && objects.count)
        {
            id firstObject = objects[0];
            if ([firstObject isKindOfClass:[PartyPartisanshipObj class]] || [className isEqualToString:NSStringFromClass([PartyPartisanshipObj class])])
            {

                [[PartisanIndexStats sharedPartisanIndexStats] didUpdatePartyPartisanship:objects];
            }

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
                                                                       duration:1];

                [infoManager addToast:infoItem];

            }

            // We shouldn't do a costly reset if there's another reset headed our way in a few seconds.
            NSString *districtMapName = NSStringFromClass([DistrictMapObj class]);
            NSString *legislatorName = NSStringFromClass([LegislatorObj class]);
            if (
                ([className isEqualToString:districtMapName] && ![self hasUpdateActivityFor:legislatorName])
                || ([className isEqualToString:legislatorName] && ![self hasUpdateActivityFor:districtMapName]))
            {
                for (DistrictMapObj *map in [DistrictMapObj allObjects])
                {
                    [map resetRelationship:self];
                }
            }
            [[RKObjectManager sharedManager].objectStore save];
            [[NSNotificationCenter defaultCenter] postNotificationName:notification object:nil];
        }
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

    [self removeUpdateActivity:className];

	NSLog(@"RestKit Data error loading %@: %@", className, error.localizedDescription);
}

@end
