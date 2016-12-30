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

@interface StateMetaLoader ()

@property (NS_NONATOMIC_IOSONLY,copy) NSMutableDictionary *metadata;
@property (NS_NONATOMIC_IOSONLY,copy) NSDictionary *stateMetadata;
@property (NS_NONATOMIC_IOSONLY,copy) NSMutableArray *loadingStates;

@end

@implementation StateMetaLoader

+ (id)sharedStateMeta
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
		NSDictionary *stateMeta = [[StateMetaLoader sharedStateMeta] stateMetadata];
		if (NO == IsEmpty(stateMeta)) {
			if (chamber == SENATE)
				name = stateMeta[kMetaUpperChamberNameKey];
			else {
				name = stateMeta[kMetaLowerChamberNameKey];
			}
			if (NO == IsEmpty(name)) {
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
		NSString *tempState = [[NSUserDefaults standardUserDefaults] objectForKey:kMetaSelectedStateKey];
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

		[[NSUserDefaults standardUserDefaults] setObject:stateID forKey:kMetaSelectedStateKey];
		[[NSUserDefaults standardUserDefaults] synchronize];
		
		[self loadMetadataForState:stateID];
	}
}

- (NSDictionary *)metadataFromCache
{
    self.metadata = nil;

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
	[_loadingStates addObject:stateID];	// add it to our list of active loads
	
	RKClient *osApiClient = [OpenLegislativeAPIs sharedOpenLegislativeAPIs].osApiClient;
	NSDictionary *queryParams = [NSMutableDictionary dictionaryWithObjectsAndKeys:SUNLIGHT_APIKEY, @"apikey",nil];
	NSString *method = [NSString stringWithFormat:@"/metadata/%@", stateID];
	request = [osApiClient get:method queryParams:queryParams delegate:self];	
	if (request) {
		request.userData = @{kMetaSelectedStateKey: stateID};
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

- (NSString *)currentSession
{
	if (NO == IsEmpty(_currentSession) || !self.selectedState)
		return _currentSession;
	NSDictionary *stateMeta = self.metadata[self.selectedState];
	
	NSMutableArray *terms = [[NSMutableArray alloc] initWithArray:stateMeta[kMetaSessionsAltKey]];
	NSSortDescriptor *sortDesc = [NSSortDescriptor sortDescriptorWithKey:@"start_year" ascending:NO];
	[terms sortUsingDescriptors:@[sortDesc]];
			
	NSInteger maxyear = -1;
	NSString *foundSession = nil;
	
	for (NSDictionary *term in terms)
    {
		NSNumber *startYear = term[@"start_year"];
		//NSNumber *endYear = [term objectForKey:@"end_year"];
		NSInteger thisYear = [[NSDate date] year];
		if (startYear) {
			NSInteger startInt = startYear.integerValue;
			if (startInt > thisYear) {
				continue;
			}
			else if (startInt > maxyear) {
				maxyear = startInt;
				NSArray *sessions = term[@"sessions"];
				if (!IsEmpty(sessions)) {
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
		
		NSString *wantedStateID = nil;
		if (request.userData) {	// try getting our new state id from our initial query info
			wantedStateID = (request.userData)[kMetaSelectedStateKey];
			if (!IsEmpty(wantedStateID) && [_loadingStates containsObject:wantedStateID]) {
				[_loadingStates removeObject:wantedStateID];
			}			
		}
		
		NSString *gotStateID = stateMeta[kMetaStateAbbrevKey];
				
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
