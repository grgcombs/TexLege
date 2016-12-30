//
//  TexLegeCoreDataUtils.m
//  Created by Gregory Combs on 8/31/10.
//
//  StatesLege by Sunlight Foundation, based on work at https://github.com/sunlightlabs/StatesLege
//
//  This work is licensed under the Creative Commons Attribution-NonCommercial 3.0 Unported License. 
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc/3.0/
//  or send a letter to Creative Commons, 444 Castro Street, Suite 900, Mountain View, California, 94041, USA.
//
//

#import "TexLegeCoreDataUtils.h"

#import "LegislatorObj+RestKit.h"
#import "CommitteeObj+RestKit.h"
#import "CommitteePositionObj+RestKit.h"
#import "DistrictMapObj+RestKit.h"
#import "DistrictOfficeObj+RestKit.h"
#import "StafferObj+RestKit.h"
#import "WnomObj+RestKit.h"
#import "LinkObj+RestKit.h"

#import "TexLegeAppDelegate.h"
#import "NSDate+Helper.h"
#import "LocalyticsSession.h"
//#import "TexLegeObjectCache.h"
#import "UtilityMethods.h"

#import <SLFRestKit/NSManagedObject+RestKit.h>

#import "NSInvocation+CWVariableArguments.h"

//#define VERIFYCOMMITTEES 1
#ifdef VERIFYCOMMITTEES
#import "JSONDataImporter.h"
#endif

#define SEED_DB_NAME @"TexLegeSeed.sqlite"
//#define SEED_DB_NAME nil
#define APP_DB_NAME @"TexLege.sqlite"
//#define APP_DB_NAME @"TexLege-2.8.sqlite"

@implementation TexLegeCoreDataUtils

+ (instancetype)sharedInstance
{
    static TexLegeCoreDataUtils * instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[TexLegeCoreDataUtils alloc] init];
    });
    return instance;
}

+ (id)fetchCalculation:(NSString *)calc ofProperty:(NSString *)prop withType:(NSAttributeType)resultType onEntity:(NSString *)entityName
{
	Class modelClass = NSClassFromString(entityName);
	if (!modelClass || NO == [modelClass isSubclassOfClass:[NSManagedObject class]])
		return nil;

	NSFetchRequest *request = [modelClass rkFetchRequest];
    request.resultType = NSDictionaryResultType;

	// must do this for each value you want to retrieve
	NSExpression *attributeToFetch = [NSExpression expressionForKeyPath:prop];
	NSExpression *functionToPerformOnAttribute = [NSExpression expressionForFunction:calc arguments:@[attributeToFetch]];

    NSString * const calculatedPropertyKey = @"myFetchedValue";

	NSExpressionDescription *propertyToFetch = [[NSExpressionDescription alloc] init];
	propertyToFetch.name = calculatedPropertyKey;
	propertyToFetch.expression = functionToPerformOnAttribute;
	propertyToFetch.expressionResultType = resultType;

	request.propertiesToFetch = @[propertyToFetch];
	
	NSArray *results = [modelClass objectsWithFetchRequest:request];
	
	id fetchedVal = nil;
	if (!IsEmpty(results))
    {
        NSDictionary *resultDictionary = results[0];
        fetchedVal = resultDictionary[calculatedPropertyKey];
		fetchedVal = [results[0] valueForKey:calculatedPropertyKey];
    }
	else
		NSLog(@"CoreData Error while fetching calc (%@) of property (%@) on entity (%@).", calc, prop, entityName);
	
	return fetchedVal;
}
		
+ (DistrictMapObj *)districtMapForDistrict:(NSNumber*)district andChamber:(NSNumber*)chamber
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"self.district == %@ AND self.chamber == %@", district, chamber];
    return [TexLegeCoreDataUtils dataObjectWithPredicate:predicate entityName:NSStringFromClass([DistrictMapObj class])];
}

+ (LegislatorObj*)legislatorForDistrict:(NSNumber*)district andChamber:(NSNumber*)chamber
{
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"self.district == %@ AND self.legtype == %@", district, chamber];
	return [LegislatorObj objectWithPredicate:predicate];
}

+ (NSArray *)allLegislatorsSortedByPartisanshipFromChamber:(NSInteger)chamber andPartyID:(NSInteger)party
{
	if (chamber == BOTH_CHAMBERS)
    {
		debug_NSLog(@"allMembersByChamber: ... cannot be BOTH chambers");
		return nil;
	}
	
	NSFetchRequest *fetchRequest = [LegislatorObj rkFetchRequest];
	NSString *predicateString = nil;
	if (party > kUnknownParty)
		predicateString = [NSString stringWithFormat:@"legtype == %ld AND party_id == %ld", (long)chamber, (long)party];
	else
		predicateString = [NSString stringWithFormat:@"legtype == %ld", (long)chamber];
	
	NSPredicate *predicate = [NSPredicate predicateWithFormat:predicateString]; 
	fetchRequest.predicate = predicate;

	NSMutableArray *results = [[NSMutableArray alloc] initWithArray:[LegislatorObj objectsWithFetchRequest:fetchRequest]];
	BOOL ascending = (party != REPUBLICAN);
	
	if (ascending)
    {
		[results sortUsingComparator:^(LegislatorObj *item1, LegislatorObj *item2) {
			NSNumber *latestWnomFloat1 = @(item1.latestWnomFloat);
			NSNumber *latestWnomFloat2 = @(item2.latestWnomFloat);
			return [latestWnomFloat1 compare:latestWnomFloat2];
		}];
	}
	else {
		[results sortUsingComparator:^(LegislatorObj *item1, LegislatorObj *item2) {
			NSNumber *latestWnomFloat1 = @(item1.latestWnomFloat);
			NSNumber *latestWnomFloat2 = @(item2.latestWnomFloat);
			return [latestWnomFloat2 compare:latestWnomFloat1];
		}];
	}
	return results;	
}

+ (id)dataObjectWithPredicate:(NSPredicate *)predicate entityName:(NSString*)entityName
{
	if (!predicate || !entityName || !NSClassFromString(entityName))
		return nil;

	NSFetchRequest *request = [NSClassFromString(entityName) rkFetchRequest];
	request.predicate = predicate;
	
	return [NSClassFromString(entityName) objectWithFetchRequest:request];
}

+ (NSArray*)allObjectIDsInEntityNamed:(NSString*)entityName
{
	if (entityName && NSClassFromString(entityName))
	{	
		NSFetchRequest *request = [NSClassFromString(entityName) rkFetchRequest];
		request.resultType = NSManagedObjectIDResultType;	// only return object IDs
		return [NSClassFromString(entityName) objectsWithFetchRequest:request];	
	}
	return nil;
}

+ (NSArray*)allPrimaryKeyIDsInEntityNamed:(NSString*)entityName
{
	Class entityClass = NSClassFromString(entityName);
	if (entityName && entityClass)
	{	
		NSFetchRequest *request = [entityClass rkFetchRequest];
		
		// only return primary key IDs
		request.resultType = NSDictionaryResultType;	
		request.propertiesToFetch = @[[entityClass primaryKeyProperty]];
		
		return [[entityClass objectsWithFetchRequest:request] valueForKeyPath:[entityClass primaryKeyProperty]];
	}
	return nil;
}

+ (NSArray *)allDistrictMapIDsWithBoundingBoxesContaining:(CLLocationCoordinate2D)coordinate
{		
	NSNumber *lat = @(coordinate.latitude);
	NSNumber *lon = @(coordinate.longitude);
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"maxLat >= %@ AND minLat <= %@ AND maxLon >=%@ AND minLon <= %@", lat, lat, lon, lon];
	
	NSFetchRequest * request = [DistrictMapObj rkFetchRequest];
	request.propertiesToFetch = @[@"districtMapID"];
	request.resultType = NSDictionaryResultType;	// only return object IDs
	request.predicate = predicate;
	NSArray *results = [DistrictMapObj objectsWithFetchRequest:request];
	if (results && results.count) {
		NSMutableArray *list = [NSMutableArray arrayWithCapacity:results.count];
		for (NSDictionary *result in results) {
			[list addObject:result[@"districtMapID"]];
		}
		return list;
	}
	return nil;
}

+ (void)deleteObjectInEntityNamed:(NSString *)entityName withPrimaryKeyValue:(id)keyValue {
    Class entityClass = (entityName != nil) ? NSClassFromString(entityName) : nil;
	if (!entityClass)
		return;
	
	NSManagedObject *object = [entityClass objectWithPrimaryKeyValue:keyValue];
	if (object == nil) {
		debug_NSLog(@"Can't Delete: There's no %@ objects matching ID: %@", entityName, keyValue);
	}
	else {
		[[entityClass rkManagedObjectContext] deleteObject:object];
	}
}

+ (void)deleteAllObjectsInEntityNamed:(NSString*)entityName
{
    Class entityClass = (entityName != nil) ? NSClassFromString(entityName) : nil;
    if (!entityClass)
        return;

	debug_NSLog(@"I HOPE YOU REALLY WANT TO DO THIS ... DELETING ALL OBJECTS IN %@", entityName);
	debug_NSLog(@"----------------------------------------------------------------------");

	NSArray *fetchedObjects = [entityClass allObjects];
	if (fetchedObjects == nil) {
		debug_NSLog(@"There's no objects to delete ???");
	}
	for (NSManagedObject *object in fetchedObjects) {
		[[entityClass rkManagedObjectContext] deleteObject:object];
	}
}

+ (NSString *)userAgent
{
    static NSString *userAgent = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSDictionary *bundleInfo = [NSBundle mainBundle].infoDictionary;
        NSString *appName = (bundleInfo[@"CFBundleName"]) ?: @"TexLege";
        NSString *version = bundleInfo[@"CFBundleShortVersionString"];
        if (!version)
            version = @"master";
        else
        {
            NSRange range = [version rangeOfString:@"-" options:0];
            if (range.location != NSNotFound && range.length > 0)
                version = [version substringToIndex:range.location];
        }
        UIDevice *deviceInfo = [UIDevice currentDevice];
        NSString *systemVersion = [deviceInfo.systemVersion stringByReplacingOccurrencesOfString:@"." withString:@"_"];
        userAgent = [NSString stringWithFormat:@"%@/%@ (%@; CPU OS %@ like Mac OS X)", appName, version, deviceInfo.model, systemVersion];
    });
    return userAgent;
}

+ (BOOL)isDaylightSavingTime
{
    NSCalendar *calendar = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian];
    NSCalendarUnit units = NSCalendarUnitEra | NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond;;

    NSDate *now = [NSDate date];
    NSDateComponents *nowComponents = [calendar components:units fromDate:now];

    NSDateComponents *beginComponents = [nowComponents copy];
    beginComponents.month = 3; // second Sunday of March
    beginComponents.hour = 2;
    beginComponents.minute = 0;

    NSDateComponents *endComponents = [nowComponents copy];
    endComponents.month = 11; // first Sunday of November
    endComponents.hour = 2;
    endComponents.minute = 0;

    NSInteger year = nowComponents.year;
    switch (year) {
        case 2016:
            beginComponents.day = 13;
            endComponents.day = 6;
            break;
        case 2017:
            beginComponents.day = 12;
            endComponents.day = 5;
            break;
        case 2018:
            beginComponents.day = 11;
            endComponents.day = 4;
            break;
        case 2019:
            beginComponents.day = 10;
            endComponents.day = 3;
            break;
        case 2020:
            beginComponents.day = 8; // leap year?
            endComponents.day = 1;
            break;
        case 2021:
            beginComponents.day = 14;
            endComponents.day = 7;
            break;
        case 2022:
            beginComponents.day = 13;
            endComponents.day = 6;
            break;
        case 2023:
            beginComponents.day = 12;
            endComponents.day = 5;
            break;
        case 2024:
            beginComponents.day = 11;
            endComponents.day = 4;
            break;
        case 2025:
            beginComponents.day = 10;
            endComponents.day = 3;
            break;
        default:
            NSAssert(NO, @"Make adjustments for a new year");
            break;
    }

    NSComparisonResult beginToNow = [[beginComponents date] compare:now];
    NSComparisonResult nowToEnd = [now compare:[endComponents date]];
    BOOL onOrAfterStart = (beginToNow == NSOrderedSame || beginToNow == NSOrderedAscending);
    BOOL onOrBeforeEnd = (nowToEnd == NSOrderedSame || nowToEnd == NSOrderedAscending);
    return (onOrAfterStart && onOrBeforeEnd);
}

+ (void)registerObjectMappingWithProvider:(RKObjectMappingProvider *)provider
{
    NSString *abbreviation = ([self isDaylightSavingTime]) ? @"CDT" : @"CST";
    NSTimeZone *centralTime = [NSTimeZone timeZoneWithAbbreviation:abbreviation];

    [RKManagedObjectMapping addDefaultDateFormatterForString:@"yyyy-MM-dd HH:mm:ss" inTimeZone:centralTime];
    [RKManagedObjectMapping addDefaultDateFormatterForString:@"E MMM d HH:mm:ss Z y" inTimeZone:centralTime];
    [RKManagedObjectMapping addDefaultDateFormatterForString:@"yyyy-MM-dd" inTimeZone:centralTime];
    [RKManagedObjectMapping addDefaultDateFormatterForString:@"HH:mm:ss" inTimeZone:centralTime];

    RKManagedObjectMapping *committeeMap = [CommitteeObj attributeMapping];
    RKManagedObjectMapping *legislatorMap = [LegislatorObj attributeMapping];
    RKManagedObjectMapping *positionMap = [CommitteePositionObj attributeMapping];
    RKManagedObjectMapping *mapMap = [DistrictMapObj attributeMapping];
    RKManagedObjectMapping *officeMap = [DistrictOfficeObj attributeMapping];
    RKManagedObjectMapping *stafferMap = [StafferObj attributeMapping];
    RKManagedObjectMapping *wnomMap = [WnomObj attributeMapping];
    RKManagedObjectMapping *linkMap = [LinkObj attributeMapping];

    [positionMap hasOne:@"committee" withMapping:committeeMap];
    [positionMap hasOne:@"legislator" withMapping:legislatorMap];

    [committeeMap hasMany:@"committeePositions" withMapping:positionMap];

    [mapMap hasOne:@"legislator" withMapping:legislatorMap];

    [stafferMap hasOne:@"legislator" withMapping:legislatorMap];
    [wnomMap hasOne:@"legislator" withMapping:legislatorMap];

    [legislatorMap hasOne:@"districtMap" withMapping:mapMap];
    [legislatorMap hasMany:@"committeePositions" withMapping:positionMap];
    [legislatorMap hasMany:@"staffers" withMapping:stafferMap];
    [legislatorMap hasMany:@"districtOffices" withMapping:officeMap];
    [legislatorMap hasMany:@"wnomScores" withMapping:wnomMap];

    [positionMap connectRelationship:@"legislator" withObjectForPrimaryKeyAttribute:@"legislatorID"];
    [positionMap connectRelationship:@"committee" withObjectForPrimaryKeyAttribute:@"committeeId"];

    [provider addObjectMapping:committeeMap];
    [provider addObjectMapping:legislatorMap];
    [provider addObjectMapping:positionMap];
    [provider addObjectMapping:mapMap];
    [provider addObjectMapping:officeMap];
    [provider addObjectMapping:stafferMap];
    [provider addObjectMapping:wnomMap];
    [provider addObjectMapping:linkMap];
}

+ (void)initRestKitObjects
{
    NSURL *url = [NSURL URLWithString:RESTKIT_BASE_URL];
	RKObjectManager* objectManager = [RKObjectManager objectManagerWithBaseURL:url];
    RKClient *client = objectManager.client;
    NSString *userAgent = [self userAgent];
    if (client && userAgent)
        client.HTTPHeaders[@"User-Agent"] = userAgent;

	//objectManager.client.username = RESTKIT_USERNAME;
	//objectManager.client.password = RESTKIT_PASSWORD;
    
	[RKClient sharedClient].requestQueue.showsNetworkActivityIndicatorWhenBusy = YES;

//GREG here was registerObjectMapping

	// Database seeding is configured as a copied target of the main application. There are only two differences
    // between the main application target and the 'Generate Seed Database' target:
    //  1) RESTKIT_GENERATE_SEED_DB is defined in the 'Preprocessor Macros' section of the build setting for the target
    //      This is what triggers the conditional compilation to cause the seed database to be built
    //  2) Source JSON files are added to the 'Generate Seed Database' target to be copied into the bundle. This is required
    //      so that the object seeder can find the files when run in the simulator.

#if 0
#if defined(RESTKIT_GENERATE_SEED_DB) && RESTKIT_GENERATE_SEED_DB == 1
    NSString *modelPath = [[NSBundle mainBundle] pathForResource:@"TexLege" ofType:@"momd"];
    NSURL *momURL = [NSURL fileURLWithPath:modelPath];
    NSManagedObjectModel *mom = [[NSManagedObjectModel alloc] initWithContentsOfURL:momURL];

    objectManager.objectStore = [RKManagedObjectStore objectStoreWithStoreFilename:SEED_DB_NAME
                                                                       inDirectory:[self applicationCacheDirectory] usingSeedDatabaseName:nil managedObjectModel:mom delegate:self
                                                             usingSeedDatabaseName:nil /// this is stupid ... we can't supply it yet.
                                                                managedObjectModel:mom];

    RKManagedObjectSeeder* seeder = [RKManagedObjectSeeder objectSeederWithObjectManager:objectManager];
    [seeder seedObjectsFromFile:@"LegislatorObj.json" toClass:[LegislatorObj class] keyPath:nil];
    [seeder seedObjectsFromFile:@"DistrictMapObj.json" toClass:[DistrictMapObj class] keyPath:nil];
    [seeder seedObjectsFromFile:@"CommitteeObj.json" toClass:[CommitteeObj class] keyPath:nil];
    [seeder seedObjectsFromFile:@"CommitteePositionObj.json" toClass:[CommitteePositionObj class] keyPath:nil];
    [seeder seedObjectsFromFile:@"DistrictOfficeObj.json" toClass:[DistrictOfficeObj class] keyPath:nil];
    [seeder seedObjectsFromFile:@"StafferObj.json" toClass:[StafferObj class] keyPath:nil];
    [seeder seedObjectsFromFile:@"WnomObj.json" toClass:[WnomObj class] keyPath:nil];
    [seeder seedObjectsFromFile:@"LinkObj.json" toClass:[LinkObj class] keyPath:nil];
    
	for (DistrictMapObj *map in [DistrictMapObj allObjects])
		[map resetRelationship:self];

    // Finalize the seeding operation and output a helpful informational message
    [seeder finalizeSeedingAndExit];
    
    // NOTE: If all of your mapped objects use element -> class registration, you can perform seeding in one line of code:
    // [RKManagedObjectSeeder generateSeedDatabaseWithObjectManager:objectManager fromFiles:@"users.json", nil];
#endif
#endif

    objectManager.objectStore = [[self sharedInstance] attemptLoadObjectStoreAndFlushIfNeeded];

    RKObjectMappingProvider *provider = [objectManager mappingProvider];
    [self registerObjectMappingWithProvider:provider];

	//objectManager.objectStore.managedObjectCache = [[TexLegeObjectCache new] autorelease];
	
#ifdef VERIFYCOMMITTEES
	JSONDataImporter *importer = [[JSONDataImporter alloc] init];
	[importer verifyCommitteeAssignmentsByChamber:HOUSE];
	[importer verifyCommitteeAssignmentsByChamber:SENATE];
	[importer verifyCommitteeAssignmentsByChamber:JOINT];
	[importer release];
	
#endif
}

- (RKManagedObjectStore *)attemptLoadObjectStore
{
    RKManagedObjectStore *objectStore = nil;
    @try {
        NSString *modelPath = [[NSBundle mainBundle] pathForResource:@"TexLege" ofType:@"momd"];
        NSURL *momURL = [NSURL fileURLWithPath:modelPath];
        NSManagedObjectModel *mom = [[NSManagedObjectModel alloc] initWithContentsOfURL:momURL];

        NSString *seedDatabase = nil; // SEED_DB_NAME;
        objectStore = [RKManagedObjectStore objectStoreWithStoreFilename:APP_DB_NAME
                                                             inDirectory:[self applicationCacheDirectory]
                                                   usingSeedDatabaseName:seedDatabase
                                                      managedObjectModel:mom
                                                                delegate:self];
    }
    @catch (NSException *exception) {
        RKLogError(@"An exception ocurred while attempting to load/build the Core Data store file: %@", exception);
    }
    return objectStore;
}

- (RKManagedObjectStore *)attemptLoadObjectStoreAndFlushIfNeeded
{
    RKManagedObjectStore *objectStore = [self attemptLoadObjectStore];
    if (!objectStore)
    {
        RKLogWarning(@"Attempting to delete and recreate the Core Data store file.");
        NSString *basePath = [self applicationCacheDirectory];
        NSString *storeFilePath = [basePath stringByAppendingPathComponent:APP_DB_NAME];
        NSURL* storeUrl = [NSURL fileURLWithPath:storeFilePath];
        NSError* error = nil;
        @try {
            if (![[NSFileManager defaultManager] removeItemAtPath:storeUrl.path error:&error]) {
                [self managedObjectStore:objectStore didFailToDeletePersistentStore:storeFilePath error:error];
            }
        }
        @catch (NSException *exception) {
            RKLogError(@"An exception ocurred while attempting to delete the Core Data store file: %@", exception);
        }
        objectStore = [self attemptLoadObjectStore];
    }
    return objectStore;
}

- (NSString *)applicationCacheDirectory {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *basePath = (paths.count > 0) ? paths[0] : nil;
    return basePath;
}

+ (NSArray *)registeredDataModels {
	return [RKObjectManager sharedManager].objectStore.managedObjectModel.entitiesByName.allKeys;
}

+ (void)resetSavedDatabase
{
	[[LocalyticsSession sharedLocalyticsSession] tagEvent:@"DATABASE_RESET"];
	[[RKObjectManager sharedManager].objectStore deletePersistantStoreUsingSeedDatabaseName:SEED_DB_NAME];
	
	//exit(0);

	for (DistrictMapObj *map in [DistrictMapObj allObjects])
		[map resetRelationship:self];
	[[RKObjectManager sharedManager].objectStore save];

	for (NSString *className in [TexLegeCoreDataUtils registeredDataModels])
    {
		NSString *notification = [NSString stringWithFormat:@"RESTKIT_LOADED_%@", className.uppercaseString];
		[[NSNotificationCenter defaultCenter] postNotificationName:notification object:nil];
	}
}

#pragma mark - RKManagedObjectStoreDelegate

- (void)managedObjectStore:(RKManagedObjectStore *)objectStore didFailToCreatePersistentStoreCoordinatorWithError:(NSError *)error
{
    NSLog(@"Failed to create persistent store coordinator: %@", error);
}

- (void)managedObjectStore:(RKManagedObjectStore *)objectStore didFailToDeletePersistentStore:(NSString *)pathToStoreFile error:(NSError *)error
{
    NSLog(@"Failed to delete persistent store at '%@': %@", pathToStoreFile, error);
}

- (void)managedObjectStore:(RKManagedObjectStore *)objectStore didFailToCopySeedDatabase:(NSString *)seedDatabase error:(NSError *)error
{
    NSLog(@"Failed to copy seed database '%@': %@", seedDatabase, error);
}

- (void)managedObjectStore:(RKManagedObjectStore *)objectStore didFailToSaveContext:(NSManagedObjectContext *)context error:(NSError *)error exception:(NSException *)exception
{
    NSDictionary *userInfo = [error.userInfo copy];
    if (userInfo &&
        userInfo[NSValidationObjectErrorKey] &&
        [userInfo[NSValidationObjectErrorKey] isKindOfClass:[LegislatorObj class]])
    {
        LegislatorObj *legislator = userInfo[NSValidationObjectErrorKey];
        NSSet *wnoms = legislator.wnomScores;

        for (WnomObj *wnom in wnoms)
        {
            [context deleteObject:wnom];
        }
        [context deleteObject:legislator];

        NSError *newError = nil;
        @try {
            if ([context save:&newError])
                return; // successful save
            NSLog(@"Couldn't save even after deleting corrupt legislator and wnomScores! %@", newError);
        }
        @catch (NSException *exception) {
            NSLog(@"Couldn't save even after deleting corrupt legislator and wnomScores! %@; exception=%@", newError, exception);
        }
    }

    NSLog(@"Failed to save context -- error: %@, exception: %@", error, exception);
    NSString *path = objectStore.pathToStoreFile;
    if (!path.length)
        return;
    if (![[NSFileManager defaultManager] removeItemAtPath:path error:&error])
    {
        NSLog(@"Could not delete the persistent store file '%@': %@", path, error);
    }
}

@end

/*

 @interface TexLegeDataMaintenance()
- (void)informDelegateOfFailureWithMessage:(NSString *)message failOption:(TexLegeDataMaintenanceFailOption)failOption;
- (void)informDelegateOfSuccess;
@end


@implementation TexLegeDataMaintenance

@synthesize delegate;

- (id) initWithDelegate:(id<TexLegeDataMaintenanceDelegate>)newDelegate {
	if (self = [super init]) {
		if (newDelegate)
			delegate = newDelegate;
	}
	return self;
}

- (void) dealloc {
	delegate = nil;
	[super dealloc];
}

- (void)informDelegateOfFailureWithMessage:(NSString *)message failOption:(TexLegeDataMaintenanceFailOption)failOption;
{
    if ([delegate respondsToSelector:@selector(dataMaintenanceDidFail:errorMessage:option:)])
    {
        NSInvocation *invocation = [NSInvocation invocationWithTarget:delegate 
                                                             selector:@selector(dataMaintenanceDidFail:errorMessage:option:) 
                                                      retainArguments:YES, self, message, failOption];
        [invocation invokeOnMainThreadWaitUntilDone:YES];
    } 
}

- (void)informDelegateOfSuccess
{
    if ([delegate respondsToSelector:@selector(dataMaintenanceDidFinishSuccessfully:)])
    {
        [delegate performSelectorOnMainThread:@selector(dataMaintenanceDidFinishSuccessfully:) 
                                   withObject:self 
                                waitUntilDone:NO];
    }
}

#pragma mark -
- (void)main 
{	
	BOOL success = NO;
    @try 
    {		
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		for (DistrictMapObj *map in [DistrictMapObj allObjects])
			[map resetRelationship:self];
		
		[[[RKObjectManager sharedManager] objectStore] save];
		success = YES;
		[pool drain];
    }
    @catch (NSException * e) 
    {
        debug_NSLog(@"Exception: %@", e);
    }
	if (success)
		[self informDelegateOfSuccess];
	else
		[self informDelegateOfFailureWithMessage:@"Could not reset core data relationships." failOption:TexLegeDataMaintenanceFailOptionLog];
}

@end
*/
