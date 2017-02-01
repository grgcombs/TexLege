//
//  StateMetadataLoader.m
//  Created by Gregory Combs on 6/10/11.
//
//  StatesLege by Sunlight Foundation, based on work at https://github.com/sunlightlabs/StatesLege
//
//  This work is licensed under the Creative Commons Attribution-NonCommercial 3.0 Unported License. 
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc/3.0/
//  or send a letter to Creative Commons, 444 Castro Street, Suite 900, Mountain View, California, 94041, USA.
//
//

#import "StateMetaLoader.h"
#import "UtilityMethods.h"
#import "TexLegeReachability.h"
#import "OpenLegislativeAPIs.h"
#import "TexLegeLibrary.h"
#import "NSDate+Helper.h"

const struct StateMetadataKeys StateMetadataKeys = {
    .selectedState = @"selected_state",
    .abbreviation = @"abbreviation",
    .name = @"name",
    .timezone = @"capitol_timezone",
    .chambers = {
        .metaLookup = @"chambers",
        .lower = {
            .metaLookup = @"lower",
            .name = @"name",
            .title = @"title",
//            .name = @"lower_chamber_name" ,
//            .title = @"lower_chamber_title",
//            .termLength = @"lower_chamber_term",
        },
        .upper = {
            .metaLookup = @"upper",
            .name = @"name",
            .title = @"title",
            //.name = @"upper_chamber_name" ,
            //.title = @"upper_chamber_title",
            //.termLength = @"upper_chamber_term",
        }
    },
    .features = {
        .metaLookup = @"feature_flags",
        .events = @"events",
        .subjects = @"subjects",
    },
    .terms = {
        .metaLookup = @"terms",
        .name = @"name",
        .sessions = @"sessions",
        .startYear = @"start_year",
        .endYear = @"end_year",
    },
    .sessionDetails = {
        .metaLookup = @"session_details",
        .name = @"display_name",
        .type = @"type",
        .startDate = @"start_date",
        .endDate = @"end_date",
    }
};

const struct StateMetadataSessionTypeKeys StateMetadataSessionTypeKeys = {
    .primary = @"primary",
    .special = @"special",
};

@interface StateMetaLoader ()

@property (NS_NONATOMIC_IOSONLY,copy) NSMutableDictionary *metadata;
@property (NS_NONATOMIC_IOSONLY,copy) NSDictionary *stateMetadata;
@property (NS_NONATOMIC_IOSONLY,copy) NSMutableArray *loadingStates;

@end

@implementation StateMetaLoader

+ (instancetype)instance
{
	static dispatch_once_t pred;
	static StateMetaLoader *foo = nil;
	
	dispatch_once(&pred, ^{ foo = [[self alloc] init]; });
	return foo;
}

+ (NSString *)nameForChamber:(NSInteger)chamber
{
	NSString *name = nil;
	// prepare to make some assumptions
	if (chamber == HOUSE || chamber == SENATE)
    {
		NSDictionary *stateMeta = [[StateMetaLoader instance] stateMetadata];
		if (NO == IsEmpty(stateMeta))
        {
            struct StateMetadataKeys keys = StateMetadataKeys;
            struct StateMetadataChamberDetailKeys chamberKeys = (chamber == SENATE) ? keys.chambers.upper : keys.chambers.lower;
            NSDictionary *chambers = stateMeta[keys.chambers.metaLookup];
            name = chambers[chamberKeys.metaLookup][chamberKeys.name];

            if (NO == IsEmpty(name))
            {
				NSArray *words = [name componentsSeparatedByString:@" "];
				if (words.count > 1 && [words[0] length] > 4) { // just to make sure we have a decent, single name
					name = words[0];
				}
			}
		}
	}
	return name;
}

- (instancetype)init
{
	if ((self=[super init]))
    {
		_updated = nil;
		_fresh = NO;
		_currentSession = nil;
		_selectedState = nil;
		_loadingStates = [[NSMutableArray alloc] init];
		
		[[NSUserDefaults standardUserDefaults] synchronize];
		NSString *tempState = [[NSUserDefaults standardUserDefaults] stringForKey:StateMetadataKeys.selectedState];
		if (tempState) {
			_selectedState = [tempState copy];
		}
		
		[self metadataFromCache];
	}
	return self;
}

- (void)dealloc
{
    [[RKClient sharedClient].requestQueue cancelRequestsWithDelegate:self];
    self.selectedState = nil;
}

- (void)setSelectedState:(NSString *)stateID
{
    self.currentSession = nil;
    _selectedState = nil;

	if (NO == IsEmpty(stateID))
    {
		_selectedState= [stateID copy];

		[[NSUserDefaults standardUserDefaults] setObject:stateID forKey:StateMetadataKeys.selectedState];
		[[NSUserDefaults standardUserDefaults] synchronize];
		
		[self loadMetadataForState:stateID];
	}
}

- (NSDictionary *)metadataFromCache
{
    _metadata = nil;

	NSString *localPath = [[UtilityMethods applicationCachesDirectory] stringByAppendingPathComponent:kStateMetaFile];
	NSFileManager *fileManager = [NSFileManager defaultManager];
	if (![fileManager fileExistsAtPath:localPath])
        return @{};

    NSData *jsonFile = [NSData dataWithContentsOfFile:localPath];
    NSError *error = nil;
    self.metadata = [NSJSONSerialization JSONObjectWithData:jsonFile options:NSJSONReadingMutableLeaves | NSJSONReadingMutableContainers error:&error];
	return _metadata;
}
		
- (void)loadMetadataForState:(NSString *)stateID
{
	RKRequest *request = nil;
	
	if (IsEmpty(stateID) || [_loadingStates containsObject:stateID])	// we're already working on it
		return;
	
	self.fresh = NO;
    if (stateID)
        [_loadingStates addObject:stateID];	// add it to our list of active loads
	
	RKClient *osApiClient = [OpenLegislativeAPIs sharedOpenLegislativeAPIs].osApiClient;
	NSDictionary *queryParams = [NSMutableDictionary dictionaryWithObjectsAndKeys:SUNLIGHT_APIKEY, @"apikey",nil];
	NSString *method = [NSString stringWithFormat:@"/metadata/%@", stateID];
	request = [osApiClient get:method queryParams:queryParams delegate:self];	
	if (request && stateID) {
		request.userData = @{StateMetadataKeys.selectedState: stateID};
	}
	else {
		[self request:nil didFailLoadWithError:nil];
	}
}

- (NSDictionary *)stateMetadata
{
    NSString *stateId = _selectedState;

    if (IsEmpty(stateId))
        return nil;

    NSDictionary *stateMeta = self.metadata[stateId];

    if (!stateMeta ||
        !self.isFresh ||
        !self.updated ||
        ([[NSDate date] timeIntervalSinceDate:self.updated] > (3600*24)))
    {	// if we're over a day old, let's refresh
        self.fresh = NO;

        if (!IsEmpty(stateId) && ![self.loadingStates containsObject:stateId])
        {
            debug_NSLog(@"StateMetadata is stale, need to refresh");
            [self loadMetadataForState:stateId];
        }
    }
	return stateMeta;
}

- (NSArray<NSDictionary *> *)sortedTerms
{
    struct StateMetadataKeys keys = StateMetadataKeys;

    NSString *selectedState = self.selectedState;
    if (!selectedState)
        return nil;
    NSDictionary *stateMeta = self.metadata[selectedState];
    if (!stateMeta)
        return nil;

    struct StateMetadataTermKeys termKeys = keys.terms;
    NSArray *terms = stateMeta[termKeys.metaLookup];
    if (!terms || ![terms isKindOfClass:[NSArray class]])
        return nil;
    NSSortDescriptor *sortByDescendingYear = [NSSortDescriptor sortDescriptorWithKey:termKeys.startYear ascending:NO];
    terms = [terms sortedArrayUsingDescriptors:@[sortByDescendingYear]];
    return terms;
}

- (NSString *)currentSession
{
	if (!IsEmpty(_currentSession))
		return _currentSession;

    NSArray *terms = [self sortedTerms];
    if (!terms.count)
        return _currentSession;

    struct StateMetadataKeys keys = StateMetadataKeys;
    struct StateMetadataTermKeys termKeys = keys.terms;

	NSInteger maxyear = -1;
	NSString *foundSession = nil;
	
	for (NSDictionary *term in terms)
    {
		NSNumber *startYear = term[termKeys.startYear];

        NSInteger thisYear = [[NSDate date] year];
		if (startYear)
        {
			NSInteger startInt = startYear.integerValue;
			if (startInt > thisYear)
				continue;
			else if (startInt > maxyear)
            {
				maxyear = startInt;
				NSArray *sessions = term[termKeys.sessions];
				if (!IsEmpty(sessions))
                {
					id latest = sessions.lastObject; 
					if ([latest isKindOfClass:[NSString class]])
						foundSession = latest;
					else if ([latest isKindOfClass:[NSNumber class]])
						foundSession = [latest stringValue];
				}
			}
		}
	}

	if (!IsEmpty(foundSession)) {
		_currentSession = [foundSession copy];	
	}

	return _currentSession;	
}

#pragma mark -
#pragma mark RestKit:RKObjectLoaderDelegate

- (void)request:(RKRequest*)request didFailLoadWithError:(NSError*)error
{
	self.fresh = NO;

	if (error && request) {
		debug_NSLog(@"Error loading state metadata from %@: %@", [request description], [error localizedDescription]);
		[[NSNotificationCenter defaultCenter] postNotificationName:kStateMetaNotifyError object:nil];
	}

	// We had trouble loading the metadata online, so pull it up from the one in the documents folder
	if (NO == IsEmpty([self metadataFromCache])) {
		[[NSNotificationCenter defaultCenter] postNotificationName:kStateMetaNotifyLoaded object:nil];
	}
}

- (void)request:(RKRequest*)request didLoadResponse:(RKResponse*)response {  
	if ([request isGET] && [response isOK])
    {
		// Success! Let's take a look at the data  

		if (NO == [request.resourcePath hasPrefix:@"/metadata"]) 
			return;

		NSError *error = nil;
        NSDictionary *stateMeta = [NSJSONSerialization JSONObjectWithData:response.body options:NSJSONReadingAllowFragments error:&error];

		if (IsEmpty(stateMeta)) {
			[self request:request didFailLoadWithError:nil];
			return;
		}

        struct StateMetadataKeys keys = StateMetadataKeys;

		NSString *wantedStateID = nil;
		if (request.userData) {	// try getting our new state id from our initial query info
			wantedStateID = (request.userData)[keys.selectedState];
			if (!IsEmpty(wantedStateID) && [_loadingStates containsObject:wantedStateID]) {
				[_loadingStates removeObject:wantedStateID];
			}			
		}
		
		NSString *gotStateID = stateMeta[keys.abbreviation];
				
		if (IsEmpty(wantedStateID) || IsEmpty(gotStateID) || NO == [wantedStateID isEqualToString:gotStateID]) {
			NSLog(@"StateMetaDataLoader: requested metadata for %@, but incoming data is for %@", wantedStateID, gotStateID);
			[self request:request didFailLoadWithError:nil];
		}

        self.updated = [NSDate date];

		if (NO == IsEmpty(gotStateID))
        {
            if (!_metadata || ![_metadata isKindOfClass:[NSMutableDictionary class]])
            {
                _metadata = [[NSMutableDictionary alloc] init];
            }
			_metadata[gotStateID] = stateMeta;
		
			if ([_loadingStates containsObject:gotStateID]) {
				[_loadingStates removeObject:gotStateID];
			}
			
			NSString *localPath = [[UtilityMethods applicationCachesDirectory] stringByAppendingPathComponent:kStateMetaFile];

            NSData *jsonData = [NSJSONSerialization dataWithJSONObject:self.metadata options:NSJSONWritingPrettyPrinted error:&error];
			if (![jsonData writeToFile:localPath atomically:YES])
				NSLog(@"StateMetadataLoader: error writing cache to file: %@", localPath);
			self.fresh = YES;
			[[NSNotificationCenter defaultCenter] postNotificationName:kStateMetaNotifyLoaded object:nil];
			debug_NSLog(@"StateMetadata network download successful, archiving.");
		}		
		else {
			[self request:request didFailLoadWithError:nil];
			return;
		}
	}
}

@end
