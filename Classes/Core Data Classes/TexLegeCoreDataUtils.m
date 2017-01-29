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
@import os.log;

#import "LegislatorObj+RestKit.h"
#import "CommitteeObj+RestKit.h"
#import "CommitteePositionObj+RestKit.h"
#import "DistrictMapObj+RestKit.h"
#import "DistrictOfficeObj+RestKit.h"
#import "StafferObj+RestKit.h"
#import "WnomObj+RestKit.h"
#import "LinkObj+RestKit.h"
#import "PartyPartisanshipObj.h"

#import "TexLegeAppDelegate.h"
#import "NSDate+Helper.h"
#import "LocalyticsSession.h"
#import "TexLegeObjectCache.h"
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

static os_log_t txlCoreDataUtilsLog;

@implementation TexLegeCoreDataUtils

+ (void)initialize {
    // We want to use a custom logging component for our model, so we need to set it up before its first use.
    txlCoreDataUtilsLog = os_log_create("com.texlege.texlege", "TexLegeCoreDataUtils");
}

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
    }
	else
    {
        os_log_error(txlCoreDataUtilsLog, "Error while performing a CoreData fetched calculation: Calc = %{public}s; Property = %{public}s; Entity = %{public}s", calc, prop, entityName);
    }
	
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
        os_log_debug(txlCoreDataUtilsLog, "allMembersByChamber: ... cannot determine aggregate partisanship when the chamber setting is 'BOTH_CHAMBERS'");
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
	if (object == nil)
    {
        SInt32 primaryKey = -1;
        if ([keyValue respondsToSelector:@selector(intValue)])
            primaryKey = [keyValue intValue];
        os_log_debug(txlCoreDataUtilsLog, "Can't delete Core Data object: There's no (Entity = %{public}s) objects matching this primary key: %d", entityName, primaryKey);
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

    os_log_debug(txlCoreDataUtilsLog, "DELETING ALL OBJECTS where Entity = %{public}s", entityName);

	NSArray *fetchedObjects = [entityClass allObjects];
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

+ (void)registerObjectMappingWithProvider:(RKObjectMappingProvider *)provider
{
    NSString *abbreviation = ([[NSDate date] isDaylightSavingTime]) ? @"CDT" : @"CST";
    NSTimeZone *centralTime = [NSTimeZone timeZoneWithAbbreviation:abbreviation];

    NSArray<NSString *> *formats = @[
                                     @"yyyy-MM-dd HH:mm:ss",
                                     @"E MMM d HH:mm:ss Z y",
                                     @"yyyy-MM-dd",
                                     @"HH:mm:ss",
                                     ];

    for (NSString *format in formats)
    {
        NSDateFormatter *formatter = [NSDateFormatter dateFormatterWithID:format format:format];
        NSAssert(formatter != nil, @"Should have a date formatter for %@", format);
        formatter.timeZone = centralTime;
        [RKManagedObjectMapping addDefaultDateFormatter:formatter];
    }

    RKManagedObjectMapping *committeeMap = [CommitteeObj attributeMapping];
    RKManagedObjectMapping *legislatorMap = [LegislatorObj attributeMapping];
    RKManagedObjectMapping *positionMap = [CommitteePositionObj attributeMapping];
    RKManagedObjectMapping *mapMap = [DistrictMapObj attributeMapping];
    RKManagedObjectMapping *officeMap = [DistrictOfficeObj attributeMapping];
    RKManagedObjectMapping *stafferMap = [StafferObj attributeMapping];
    RKManagedObjectMapping *wnomMap = [WnomObj attributeMapping];
    RKManagedObjectMapping *linkMap = [LinkObj attributeMapping];
    RKObjectMapping *aggregateMap = [PartyPartisanshipObj attributeMapping];

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
    [provider addObjectMapping:aggregateMap];

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

    RKManagedObjectStore *objectStore = [[self sharedInstance] attemptLoadObjectStoreAndFlushIfNeeded];
    TexLegeObjectCache *objectCache = [[TexLegeObjectCache alloc] init];
    objectStore.managedObjectCache = objectCache;
    objectManager.objectStore = objectStore;

    RKObjectMappingProvider *provider = [objectManager mappingProvider];
    [self registerObjectMappingWithProvider:provider];

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
        os_log_fault(txlCoreDataUtilsLog, "Exception while attempting to load/build the Core Data store file: %{public}s", exception.description);
    }
    return objectStore;
}

- (RKManagedObjectStore *)attemptLoadObjectStoreAndFlushIfNeeded
{
    RKManagedObjectStore *objectStore = [self attemptLoadObjectStore];
    if (!objectStore)
    {
        debug_NSLog(@"Attempting to delete and recreate the Core Data store file.");
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
            os_log_fault(txlCoreDataUtilsLog, "An exception ocurred while attempting to delete the Core Data store file (%{public}s): %{public}s", storeFilePath, exception.description);
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
    os_log_error(txlCoreDataUtilsLog, "Failed to create persistent store coordinator: %{public}s", error.description);
}

- (void)managedObjectStore:(RKManagedObjectStore *)objectStore didFailToDeletePersistentStore:(NSString *)pathToStoreFile error:(NSError *)error
{
    os_log_error(txlCoreDataUtilsLog, "Failed to delete persistent store at %{public}s: %{public}s", pathToStoreFile, error.description);
}

- (void)managedObjectStore:(RKManagedObjectStore *)objectStore didFailToCopySeedDatabase:(NSString *)seedDatabase error:(NSError *)error
{
    os_log_error(txlCoreDataUtilsLog, "Failed to copy seed database %{public}s: %{public}s", seedDatabase, error.description);
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
            os_log_error(txlCoreDataUtilsLog, "Couldn't save even after deleting corrupt legislator and wnomScores: %{public}s: %{public}s", newError.description);
        }
        @catch (NSException *exception) {
            os_log_error(txlCoreDataUtilsLog, "Couldn't save even after deleting corrupt legislator and wnomScores: %{public}s -- Error: %{public}s; Exception: %{public}s;", exception.description);
        }
    }

    os_log_error(txlCoreDataUtilsLog, "Failed to save context: Error: %{public}s; Exception: %{public}s", error.description, exception.description);

    NSString *path = objectStore.pathToStoreFile;
    if (!path.length)
        return;
    if (![[NSFileManager defaultManager] removeItemAtPath:path error:&error])
    {
        os_log_error(txlCoreDataUtilsLog, "Could not delete the persistent store file %{public}s:  %{public}s", path, error.description);
    }
}

@end
