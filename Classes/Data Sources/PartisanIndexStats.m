//
//  PartisanIndexStats.m
//  Created by Gregory Combs on 7/9/10.
//
//  StatesLege by Sunlight Foundation, based on work at https://github.com/sunlightlabs/StatesLege
//
//  This work is licensed under the Creative Commons Attribution-NonCommercial 3.0 Unported License. 
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc/3.0/
//  or send a letter to Creative Commons, 444 Castro Street, Suite 900, Mountain View, California, 94041, USA.
//
//

#import "PartisanIndexStats.h"
#import "LegislatorObj.h"
#import "WnomObj+RestKit.h"
#import "UtilityMethods.h"
#import "TexLegeCoreDataUtils.h"
#import "NSDate+Helper.h"
#import "DataModelUpdateManager.h"
#import "TexLegeAppDelegate.h"

@interface PartisanIndexStats (Private)
- (NSArray *) aggregatePartisanIndexForChamber:(NSInteger)chamber andPartyID:(NSInteger)party;
@end

@implementation PartisanIndexStats
@synthesize isFresh;

+ (PartisanIndexStats*)sharedPartisanIndexStats
{
	static dispatch_once_t pred;
	static PartisanIndexStats *foo = nil;
	
	dispatch_once(&pred, ^{ foo = [[self alloc] init]; });
	return foo;
}

- (instancetype)init {
	if ((self = [super init])) {
		updated = nil;
		isFresh = NO;
		isLoading = NO;
		m_partisanIndexAggregates = nil;
		m_rawPartisanIndexAggregates = nil;
		
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(resetData:) name:@"RESTKIT_LOADED_LEGISLATOROBJ" object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(resetData:) name:@"RESTKIT_LOADED_WNOMOBJ" object:nil];

		[self loadPartisanIndex:nil];
		
		// initialize these
		[self partisanIndexAggregates];
		
	}
	return self;
}



- (void)dealloc {	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[[RKRequestQueue sharedQueue] cancelRequestsWithDelegate:self];
	if (updated)
		[updated release], updated = nil;
		
	if (m_rawPartisanIndexAggregates) [m_rawPartisanIndexAggregates release], m_rawPartisanIndexAggregates = nil;
	if (m_partisanIndexAggregates) [m_partisanIndexAggregates release], m_partisanIndexAggregates = nil;
	
    [super dealloc];
}

- (void)resetData:(NSNotification *)notification
{
	nice_release(m_partisanIndexAggregates);
	[self partisanIndexAggregates];
}

#pragma mark -
#pragma mark Statistics for Partisan Sliders

/* This collects the calculations of partisanship across members in each chamber and party, then caches the results*/
- (NSDictionary *)partisanIndexAggregates {
	if (m_partisanIndexAggregates == nil) {
		NSMutableDictionary *tempAggregates = [NSMutableDictionary dictionaryWithCapacity:4];
		NSInteger chamber, party;
		for (chamber = HOUSE; chamber <= SENATE; chamber++) {
			for (party = kUnknownParty; party <= REPUBLICAN; party++) {
				NSArray *aggregatesArray = [self aggregatePartisanIndexForChamber:chamber andPartyID:party];
				if (aggregatesArray && aggregatesArray.count) {
					NSNumber *avgIndex = aggregatesArray[0];
					if (avgIndex)
						tempAggregates[[NSString stringWithFormat:@"AvgC%ld+P%ld", (long)chamber, (long)party]] = avgIndex;
					
					NSNumber *maxIndex = aggregatesArray[1];
					if (maxIndex)
						tempAggregates[[NSString stringWithFormat:@"MaxC%ld+P%ld", (long)chamber, (long)party]] = maxIndex;
					
					NSNumber *minIndex = aggregatesArray[2];
					if (minIndex)
						tempAggregates[[NSString stringWithFormat:@"MinC%ld+P%ld", (long)chamber, (long)party]] = minIndex;
				}
				else
					NSLog(@"PartisanIndexStates: Error pulling aggregate dictionary.");
			}
		}
		m_partisanIndexAggregates = [[NSDictionary dictionaryWithDictionary:tempAggregates] retain];
	}
	
	return m_partisanIndexAggregates;
}

- (BOOL)hasData
{
    return self.partisanIndexAggregates.count > 0;
}

/* These are convenience methods for accessing our aggregate calculations from cache */
- (CGFloat) minPartisanIndexUsingChamber:(NSInteger)chamber {
	return [(self.partisanIndexAggregates)[[NSString stringWithFormat:@"MinC%ld+P0", (long)chamber]] floatValue];
};

- (CGFloat) maxPartisanIndexUsingChamber:(NSInteger)chamber {
	return [(self.partisanIndexAggregates)[[NSString stringWithFormat:@"MaxC%ld+P0", (long)chamber]] floatValue];
};

- (CGFloat) overallPartisanIndexUsingChamber:(NSInteger)chamber {
	return [(self.partisanIndexAggregates)[[NSString stringWithFormat:@"AvgC%ld+P0", (long)chamber]] floatValue];
};


- (CGFloat) partyPartisanIndexUsingChamber:(NSInteger)chamber andPartyID:(NSInteger)party {
	return [(self.partisanIndexAggregates)[[NSString stringWithFormat:@"AvgC%ld+P%ld", (long)chamber, (long)party]] floatValue];
};


- (NSNumber *) maxWnomSession {
	return [TexLegeCoreDataUtils fetchCalculation:@"max:" 
									   ofProperty:@"session" 
										 withType:NSInteger32AttributeType 
										 onEntity:@"WnomObj"];
}

/* This queries the partisan index from each legislator and calculates aggregate statistics */
- (NSArray *) aggregatePartisanIndexForChamber:(NSInteger)chamber andPartyID:(NSInteger)party {
	if (chamber == BOTH_CHAMBERS) {
		debug_NSLog(@"aggregatePartisanIndexForChamber: ... cannot be BOTH chambers");
		return nil;
	}
	
	NSNumber *tempNum = [self maxWnomSession];
	NSInteger maxWnomSession = WNOM_DEFAULT_LATEST_SESSION;
	if (tempNum)
		maxWnomSession = tempNum.integerValue;
	
	NSMutableString *predicateString = [NSMutableString stringWithFormat:@"self.legislator.legtype == %ld AND self.session == %ld", (long)chamber, (long)maxWnomSession];
	
	if (party > kUnknownParty)
		[predicateString appendFormat:@" AND self.legislator.party_id == %ld", (long)party];

	if (maxWnomSession == 81)	// let's try some special cases for the party switchers Pena and Hopson and Ritter
		[predicateString appendString:@" AND self.legislator.legislatorID != 50000 AND self.legislator.legislatorID != 49745 AND self.legislator.legislatorID != 25363"];
	
	NSPredicate *predicate = [NSPredicate predicateWithFormat:predicateString]; 
	/*_____________________*/
	
	NSExpression *ex = [NSExpression expressionForFunction:@"average:" arguments:
						@[[NSExpression expressionForKeyPath:@"wnomAdj"]]];
	NSExpressionDescription *edAvg = [[NSExpressionDescription alloc] init];
	edAvg.name = @"averagePartisanIndex";
	edAvg.expression = ex;
	edAvg.expressionResultType = NSFloatAttributeType;
	
	ex = [NSExpression expressionForFunction:@"max:" arguments:
		  @[[NSExpression expressionForKeyPath:@"wnomAdj"]]];
	NSExpressionDescription *edMax = [[NSExpressionDescription alloc] init];
	edMax.name = @"maxPartisanIndex";
	edMax.expression = ex;
	edMax.expressionResultType = NSFloatAttributeType;
	
	ex = [NSExpression expressionForFunction:@"min:" arguments:
		  @[[NSExpression expressionForKeyPath:@"wnomAdj"]]];
	NSExpressionDescription *edMin = [[NSExpressionDescription alloc] init];
	edMin.name = @"minPartisanIndex";
	edMin.expression = ex;
	edMin.expressionResultType = NSFloatAttributeType;
	
	/*_____________________*/
	
	NSFetchRequest *request = [WnomObj fetchRequest];
	request.predicate = predicate;
	request.propertiesToFetch = @[edAvg, edMax, edMin];
	request.resultType = NSDictionaryResultType;

    NSArray *allResults = nil;
	NSArray *objects = [WnomObj objectsWithFetchRequest:request];
	if (IsEmpty(objects)) {
		debug_NSLog(@"PartisanIndexStats Error while fetching Legislators");
	}
	else {
        NSDictionary *first = objects.firstObject;
		NSNumber *avgPartisanIndex = [first valueForKey:@"averagePartisanIndex"];
		NSNumber *maxPartisanIndex = [first valueForKey:@"maxPartisanIndex"];
		NSNumber *minPartisanIndex = [first valueForKey:@"minPartisanIndex"];

/*		debug_NSLog(@"Partisanship for Chamber (%d) Party (%d): min=%@ max=%@ avg=%@", 
					chamber, party, minPartisanIndex, maxPartisanIndex, avgPartisanIndex);
*/
		allResults = @[avgPartisanIndex, maxPartisanIndex, minPartisanIndex];
	}
	
    [edAvg release], [edMax release], [edMin release];
	return allResults;
}

#pragma mark -
#pragma mark Statistics for Historical Chart

#define	kPartisanIndexPath @"WnomAggregateObj"
#define kPartisanIndexFile @"WnomAggregateObj.json"

/* This gathers our pre-calculated overall aggregate scores for parties and chambers, from JSON		
	We use this for our red/blue lines in our historical partisanship chart.*/
- (NSArray *) historyForParty:(NSInteger)party chamber:(NSInteger)chamber {
	if (IsEmpty(m_rawPartisanIndexAggregates) || !isFresh || !updated || 
		([[NSDate date] timeIntervalSinceDate:updated] > (3600*24*2)))
	{	// if we're over 2 days old, let's refresh
		if (!isLoading) {
			[self loadPartisanIndex:nil];
		}
	}
	
	if (!IsEmpty(m_rawPartisanIndexAggregates))
	{
		NSArray *chamberArray = [m_rawPartisanIndexAggregates findAllWhereKeyPath:@"chamber" equals:@(chamber)];
		if (chamberArray) {
			NSArray *partyArray = [chamberArray findAllWhereKeyPath:@"party" equals:@(party)];
			return partyArray;
		}
	}
		
	return nil;
}

#pragma mark -
#pragma mark Chart Generation

- (NSDictionary *)partisanshipDataForLegislatorID:(NSNumber*)legislatorID {
	if (!legislatorID)
		return nil;
	
	LegislatorObj *legislator = [LegislatorObj objectWithPrimaryKeyValue:legislatorID];
	if (!legislator)
		return nil;
	
	NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"session" ascending:YES];
	NSArray *descriptors = [[NSArray alloc] initWithObjects:sortDescriptor,nil];
	NSArray *sortedScores = [(legislator.wnomScores).allObjects sortedArrayUsingDescriptors:descriptors];
	[sortDescriptor release];
	[descriptors release];
	NSInteger countOfScores = (legislator.wnomScores).count;
	
	
	NSInteger chamber = (legislator.legtype).integerValue;
	NSArray *democHistory = [self historyForParty:DEMOCRAT chamber:chamber];
	NSArray *repubHistory = [self historyForParty:REPUBLICAN chamber:chamber];
		
	NSUInteger i;
	
	NSMutableDictionary *results = [NSMutableDictionary dictionaryWithCapacity:3];
	NSMutableArray *repubScores = [[NSMutableArray alloc] init];
	NSMutableArray *demScores = [[NSMutableArray alloc] init];
	NSMutableArray *memberScores = [[NSMutableArray alloc] init];
	NSMutableArray *dates = [[NSMutableArray alloc] init];
	
	for ( i = 0; i < countOfScores ; i++) {
		
		WnomObj *wnomObj = sortedScores[i];
		NSDate *date = [NSDate dateFromString:[wnomObj year].stringValue withFormat:@"yyyy"];
		NSNumber *democY = [democHistory findWhereKeyPath:@"session" equals:wnomObj.session][@"wnom"];
		NSNumber *repubY = [repubHistory findWhereKeyPath:@"session" equals:wnomObj.session][@"wnom"];
		if (!democY)
			democY = @0.0f;
		if (!repubY)
			repubY = @0.0f;
		
		[repubScores addObject:repubY];
		[demScores addObject:democY];
		[dates addObject:date];

		CGFloat legVal = wnomObj.wnomAdj.floatValue;
		if (legVal != 0.0f)
			[memberScores addObject:wnomObj.wnomAdj];
		else
			[memberScores addObject:@CGFLOAT_MIN];
	}
		
	results[@"repub"] = repubScores;
	results[@"democ"] = demScores;
	results[@"member"] = memberScores;
	results[@"time"] = dates;
	[repubScores release];
	[demScores release];
	[memberScores release];
	[dates release];
	
	return results;
	
}

- (void)loadPartisanIndexFromCache:(id)sender {
	// We had trouble loading the metadata online, so pull it up from the one in the documents folder (or the app bundle)
	NSError *newError = nil;
	NSString *localPath = [[UtilityMethods applicationCachesDirectory] stringByAppendingPathComponent:kPartisanIndexFile];
	NSFileManager *fileManager = [NSFileManager defaultManager];
	if (![fileManager fileExistsAtPath:localPath]) {
		NSString *defaultPath = [[NSBundle mainBundle] pathForResource:kPartisanIndexPath ofType:@"json"];
		[fileManager copyItemAtPath:defaultPath toPath:localPath error:&newError];
		debug_NSLog(@"PartisanIndex: copied metadata from the app bundle's original.");
	}
	else {
		debug_NSLog(@"PartisanIndex: using cached metadata in the documents folder.");
	}
	
	NSData *jsonFile = [NSData dataWithContentsOfFile:localPath options:NSDataReadingMappedIfSafe error:&newError];

    if (!jsonFile || !jsonFile.length)
    {
        if (newError)
        {
            debug_NSLog(@"Unable to read aggregate partisan scores from the bundled JSON: %@", newError);
        }
    }
    else
    {
        if (m_rawPartisanIndexAggregates)
        {
            [m_rawPartisanIndexAggregates release];
            m_rawPartisanIndexAggregates = nil;
        }

        @try {
            NSMutableArray *aggregates = [NSJSONSerialization JSONObjectWithData:jsonFile options:NSJSONReadingMutableContainers | NSJSONReadingMutableLeaves error:&newError];
            if (newError)
            {
                debug_NSLog(@"Error while attempting to parse aggregate partisan scores from the bundled JSON: %@", newError);
            }

            if (aggregates
                && [aggregates isKindOfClass:[NSArray class]]
                && aggregates.count)
            {
                m_rawPartisanIndexAggregates = [aggregates mutableCopy];
            }
        } @catch (NSException *exception) {
            NSLog(@"Exception while attempting to parse and consume aggregate partisan scores from the bundled JSON: %@", exception);
        }
    }

	if (m_rawPartisanIndexAggregates)
    {
		[self resetData:nil];
		[[NSNotificationCenter defaultCenter] postNotificationName:kPartisanIndexNotifyLoaded object:nil];
	}
}

- (void)loadPartisanIndex:(id)sender {	
	if ([TexLegeReachability texlegeReachable]) {
		if (IsEmpty(m_rawPartisanIndexAggregates)) {
			[self loadPartisanIndexFromCache:nil];		// we do this automatically if we're not reachable
		}
		
		isLoading = YES;
		[[RKClient sharedClient] get:[NSString stringWithFormat:@"/rest.php/%@", kPartisanIndexPath] delegate:self];  	
	}
	else {
		[self request:nil didFailLoadWithError:nil];
	}
}

#pragma mark -
#pragma mark RestKit:RKObjectLoaderDelegate

- (void)request:(RKRequest*)request didFailLoadWithError:(NSError*)error {
	isLoading = NO;
	
	if (error && request) {
		debug_NSLog(@"Error loading partisan index from %@: %@", [request description], [error localizedDescription]);
		[[NSNotificationCenter defaultCenter] postNotificationName:kPartisanIndexNotifyError object:nil];
	}
	
	[self loadPartisanIndexFromCache:nil];
}

- (void)request:(RKRequest*)request didLoadResponse:(RKResponse*)response {  
	isLoading = NO;
	
	if ([request isGET] && [response isOK]) {  
		// Success! Let's take a look at the data  
		if (m_rawPartisanIndexAggregates)
        {
			[m_rawPartisanIndexAggregates release];
            m_rawPartisanIndexAggregates = nil;
        }

        NSError *error = nil;

        NSMutableArray *aggregates = [NSJSONSerialization JSONObjectWithData:response.body options:NSJSONReadingMutableContainers | NSJSONReadingMutableLeaves error:&error];
        if (error)
        {
            debug_NSLog(@"Error while attempting to parse aggregate partisan scores from the bundled JSON: %@", error);
        }

        if (aggregates
            && [aggregates isKindOfClass:[NSArray class]]
            && aggregates.count)
        {
            m_rawPartisanIndexAggregates = [aggregates mutableCopy];

            if (updated)
				[updated release];
			updated = [[NSDate date] retain];
			NSString *localPath = [[UtilityMethods applicationCachesDirectory] stringByAppendingPathComponent:kPartisanIndexFile];
            NSData *jsonData = [NSJSONSerialization dataWithJSONObject:m_rawPartisanIndexAggregates options:NSJSONWritingPrettyPrinted error:&error];
			if (![jsonData writeToFile:localPath atomically:YES])
            {
				NSLog(@"PartisanIndex: error writing cache to file: %@", localPath);
            }
            isFresh = YES;
			[self resetData:nil];
			[[NSNotificationCenter defaultCenter] postNotificationName:kPartisanIndexNotifyLoaded object:nil];
			debug_NSLog(@"PartisanIndex network download successful, archiving for others.");
		}		
		else {
			[self request:request didFailLoadWithError:nil];
			return;
		}
	}
}		


@end
