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
#import "PartyPartisanshipObj.h"
#import <SLFRestKit/SLFRestKit.h>
@import SLToastKit;
#import <SLToastKit/SLToastKit.h>

@interface PartisanIndexStats ()
@property (NS_NONATOMIC_IOSONLY, copy) NSDictionary *partisanIndexAggregates;
@property (NS_NONATOMIC_IOSONLY, copy) NSArray *partyPartisanship;
@property (NS_NONATOMIC_IOSONLY, copy) NSDate *updated;
@end

@implementation PartisanIndexStats

+ (PartisanIndexStats*)sharedPartisanIndexStats
{
	static dispatch_once_t pred;
	static PartisanIndexStats *foo = nil;
	
	dispatch_once(&pred, ^{ foo = [[self alloc] init]; });
	return foo;
}

- (instancetype)init
{
	if ((self = [super init]))
    {
		_updated = nil;
		_fresh = NO;
		_loading = NO;
		_partisanIndexAggregates = nil;
		_partyPartisanship = nil;
		
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(resetData:) name:@"RESTKIT_LOADED_LEGISLATOROBJ" object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(resetData:) name:@"RESTKIT_LOADED_WNOMOBJ" object:nil];

		[self loadPartisanIndex];
		
		// initialize these
		[self partisanIndexAggregates];
		
	}
	return self;
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[[RKClient sharedClient].requestQueue cancelRequestsWithDelegate:self];
	_updated = nil;
	_partyPartisanship = nil;
	_partisanIndexAggregates = nil;
}

- (void)resetData:(NSNotification *)notification
{
    _partisanIndexAggregates = nil;
	[self partisanIndexAggregates];
}

#pragma mark -
#pragma mark Statistics for Partisan Sliders

- (void)setPartyPartisanship:(NSArray *)partyPartisanship
{
    if (partyPartisanship.count)
    {
        NSSortDescriptor *sortBySession = [NSSortDescriptor sortDescriptorWithKey:PartyPartisanshipKeys.session ascending:YES];
        NSSortDescriptor *sortByChamber = [NSSortDescriptor sortDescriptorWithKey:PartyPartisanshipKeys.chamber ascending:YES];
        NSSortDescriptor *sortByParty = [NSSortDescriptor sortDescriptorWithKey:PartyPartisanshipKeys.party ascending:YES];

        partyPartisanship = [partyPartisanship sortedArrayUsingDescriptors:@[sortBySession,sortByChamber,sortByParty]];
    }
    _partyPartisanship = partyPartisanship;
}

/* This collects the calculations of partisanship across members in each chamber and party, then caches the results*/
- (NSDictionary *)partisanIndexAggregates
{
    if (!_partisanIndexAggregates || !_partisanIndexAggregates.count)
    {
        NSMutableDictionary *tempAggregates = [NSMutableDictionary dictionaryWithCapacity:4];

		for (TXLChamberType chamber = HOUSE; chamber <= SENATE; chamber++)
        {
			for (TXLPartyType party = BOTH_PARTIES; party <= REPUBLICAN; party++)
            {
				NSArray *aggregatesArray = [self aggregatePartisanIndexForChamber:chamber andPartyID:party];
				if (aggregatesArray && aggregatesArray.count == 3)
                {
					NSNumber *avgIndex = aggregatesArray[0];
					if (avgIndex)
						tempAggregates[[NSString stringWithFormat:@"AvgC%d+P%d", chamber, party]] = avgIndex;
					
					NSNumber *maxIndex = aggregatesArray[1];
					if (maxIndex)
						tempAggregates[[NSString stringWithFormat:@"MaxC%d+P%d", chamber, party]] = maxIndex;
					
					NSNumber *minIndex = aggregatesArray[2];
					if (minIndex)
						tempAggregates[[NSString stringWithFormat:@"MinC%d+P%d", chamber, party]] = minIndex;
				}
				else
					NSLog(@"PartisanIndexStates: Error processing aggregate partisanship dictionary.  Expected three aggregated score calculations for (chamber=%d; party=%d): %@", chamber, party, aggregatesArray);
			}
		}
		_partisanIndexAggregates = [tempAggregates copy];
	}

	return _partisanIndexAggregates;
}

- (BOOL)hasData
{
    return self.partisanIndexAggregates.count > 0;
}

/* These are convenience methods for accessing our aggregate calculations from cache */
- (double)minPartisanIndexUsingChamber:(TXLChamberType)chamber
{
    NSDictionary *aggregates = self.partisanIndexAggregates;
    if (!aggregates)
        return 0;
	return [aggregates[[NSString stringWithFormat:@"MinC%d+P0", chamber]] doubleValue];
};

- (double)maxPartisanIndexUsingChamber:(TXLChamberType)chamber
{
    NSDictionary *aggregates = self.partisanIndexAggregates;
    if (!aggregates)
        return 0;
	return [aggregates[[NSString stringWithFormat:@"MaxC%d+P0", chamber]] doubleValue];
};

- (double) overallPartisanIndexUsingChamber:(TXLChamberType)chamber
{
    NSDictionary *aggregates = self.partisanIndexAggregates;
    if (!aggregates)
        return 0;
	return [aggregates[[NSString stringWithFormat:@"AvgC%d+P0", chamber]] doubleValue];
};


- (double)partyPartisanIndexUsingChamber:(TXLChamberType)chamber andPartyID:(TXLPartyType)party
{
    NSDictionary *aggregates = self.partisanIndexAggregates;
    if (!aggregates)
        return 0;
	return [aggregates[[NSString stringWithFormat:@"AvgC%d+P%d", chamber, party]] doubleValue];
};


- (NSNumber *)maxWnomSession
{
    NSNumber *value = [TexLegeCoreDataUtils fetchCalculation:@"max:"
                                                  ofProperty:@"session"
                                                    withType:NSInteger32AttributeType
                                                    onEntity:@"WnomObj"];
    if (!value || value.intValue == 0)
        return nil;
    return value;
}

/* This queries the partisan index from each legislator and calculates aggregate statistics */
- (NSArray *)aggregatePartisanIndexForChamber:(TXLChamberType)chamber andPartyID:(TXLPartyType)party
{
	if (chamber == BOTH_CHAMBERS)
    {
		debug_NSLog(@"aggregatePartisanIndexForChamber: ... cannot be BOTH chambers");
		return nil;
	}

	NSNumber *tempNum = [self maxWnomSession];
	NSInteger maxWnomSession = WNOM_DEFAULT_LATEST_SESSION;
	if (tempNum)
		maxWnomSession = tempNum.integerValue;
	
	NSMutableString *predicateString = [NSMutableString stringWithFormat:@"self.legislator != nil AND self.legislator.legtype == %d AND self.session == %d", chamber, (UInt16)maxWnomSession];
	
	if (party > BOTH_PARTIES)
		[predicateString appendFormat:@" AND self.legislator.party_id == %d", party];

	if (maxWnomSession == 81)	// let's try some special cases for the party switchers Pena and Hopson and Ritter
		[predicateString appendString:@" AND self.legislator.legislatorID != 50000 AND self.legislator.legislatorID != 49745 AND self.legislator.legislatorID != 25363"];
	
	NSPredicate *predicate = [NSPredicate predicateWithFormat:predicateString]; 
    NSArray *allResults = nil;

#if 0

	NSExpression *ex = [NSExpression expressionForFunction:@"average:" arguments:
						@[[NSExpression expressionForKeyPath:@"wnomAdj"]]];
	NSExpressionDescription *edAvg = [[NSExpressionDescription alloc] init];
	edAvg.name = @"averagePartisanIndex";
	edAvg.expression = ex;
	edAvg.expressionResultType = NSDoubleAttributeType;
	
	ex = [NSExpression expressionForFunction:@"max:" arguments:
		  @[[NSExpression expressionForKeyPath:@"wnomAdj"]]];
	NSExpressionDescription *edMax = [[NSExpressionDescription alloc] init];
	edMax.name = @"maxPartisanIndex";
	edMax.expression = ex;
	edMax.expressionResultType = NSDoubleAttributeType;
	
	ex = [NSExpression expressionForFunction:@"min:" arguments:
		  @[[NSExpression expressionForKeyPath:@"wnomAdj"]]];
	NSExpressionDescription *edMin = [[NSExpressionDescription alloc] init];
	edMin.name = @"minPartisanIndex";
	edMin.expression = ex;
	edMin.expressionResultType = NSDoubleAttributeType;


    /*_____________________*/

    NSFetchRequest *request = [WnomObj rkFetchRequest];
    request.predicate = predicate;
    request.propertiesToFetch = @[edAvg, edMax, edMin, @"legislator"];
    request.resultType = NSDictionaryResultType;
    request.relationshipKeyPathsForPrefetching = @[@"legislator"];
    request.includesSubentities = YES;
    request.includesPropertyValues = YES;
    request.includesPendingChanges = YES;
    request.returnsObjectsAsFaults = NO;

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
        if (avgPartisanIndex && maxPartisanIndex && minPartisanIndex)
            allResults = @[avgPartisanIndex, maxPartisanIndex, minPartisanIndex];
        else
            allResults = nil;
    }

    if (!allResults)
    {
        request.predicate = nil;
        request.propertiesToFetch = nil;
        request.resultType = NSManagedObjectResultType;
        //objects = [WnomObj allObjects];
        objects = [WnomObj objectsWithFetchRequest:request];

        for (NSManagedObject *obj in objects)
        {
            WnomObj *wnom = ([obj isKindOfClass:[WnomObj class]]) ? (WnomObj *)obj : nil;
            if (!wnom)
                break;
        }
    }
    
#else

    NSArray<WnomObj *> *scores = [WnomObj objectsWithPredicate:predicate];

    double count = (double)scores.count;
    double total = 0;
    double minimum = 100;
    double maximum = -100;

    for (WnomObj *score in scores)
    {
        NSNumber *value = SLTypeNumberOrNil(SLValueIfClass(WnomObj, score).wnomAdj);
        if (!value)
        {
            count--;
            continue;
        }

        double adjWnom = value.doubleValue;
        minimum = MIN(minimum, adjWnom);
        maximum = MAX(maximum, adjWnom);
        total += adjWnom;
    }

    double average = (count > 0 && total != 0) ? (total / count) : 0;
    allResults = @[@(average), @(maximum), @(minimum)];
#endif

    return allResults;
}

#pragma mark -
#pragma mark Statistics for Historical Chart

/* This gathers our pre-calculated overall aggregate scores for parties and chambers, from JSON		
	We use this for our red/blue lines in our historical partisanship chart.*/
- (NSArray *)historyForParty:(TXLPartyType)party chamber:(TXLChamberType)chamber
{
    if (IsEmpty(_partyPartisanship) || !self.isFresh || !_updated ||
		([[NSDate date] timeIntervalSinceDate:_updated] > (3600*24*2)))
	{	// if we're over 2 days old, let's refresh
		if (!self.isLoading)
        {
			[self loadPartisanIndex];
		}
	}

	if (_partyPartisanship.count)
	{
        struct PartyPartisanshipKeys keys = PartyPartisanshipKeys;
		NSArray *chamberArray = [_partyPartisanship findAllWhereKeyPath:keys.chamber equals:@(chamber)];
		if (chamberArray) {
			NSArray *partyArray = [chamberArray findAllWhereKeyPath:keys.party equals:@(party)];
			return partyArray;
		}
	}
		
	return nil;
}

#pragma mark -
#pragma mark Chart Generation

- (NSDictionary *)partisanshipDataForLegislator:(LegislatorObj*)legislator
{
    if (!legislator || ![legislator isKindOfClass:[LegislatorObj class]])
        return nil;

    struct PartyPartisanshipKeys keys = PartyPartisanshipKeys;

    NSSortDescriptor *sortBySession = [[NSSortDescriptor alloc] initWithKey:keys.session ascending:YES];
    NSArray *descriptors = [[NSArray alloc] initWithObjects:sortBySession,nil];
    NSArray *scores = legislator.wnomScores.allObjects;

    NSArray *sortedScores = [scores sortedArrayUsingDescriptors:descriptors];
    NSInteger countOfScores = sortedScores.count;


    TXLChamberType chamber = (legislator.legtype).intValue;
    NSArray *democHistory = [self historyForParty:DEMOCRAT chamber:chamber];
    NSArray *repubHistory = [self historyForParty:REPUBLICAN chamber:chamber];

    NSUInteger i = 0;

    NSMutableDictionary *results = [NSMutableDictionary dictionaryWithCapacity:3];
    NSMutableArray *repubScores = [[NSMutableArray alloc] init];
    NSMutableArray *demScores = [[NSMutableArray alloc] init];
    NSMutableArray *memberScores = [[NSMutableArray alloc] init];
    NSMutableArray *dates = [[NSMutableArray alloc] init];

    NSString *aggregateScoreKey = @"wnom";
    if (democHistory.count)
    {
        id item = [democHistory firstObject];
        if ([item isKindOfClass:[PartyPartisanshipObj class]]) {
            aggregateScoreKey = keys.score;
        }
    }

    for ( i = 0; i < countOfScores ; i++)
    {
        WnomObj *wnomObj = sortedScores[i];
        NSDate *date = [NSDate dateFromString:[wnomObj year].stringValue withFormat:@"yyyy"];
        
        NSNumber *democY = ([democHistory findWhereKeyPath:keys.session equals:wnomObj.session])[aggregateScoreKey];
        NSNumber *repubY = ([repubHistory findWhereKeyPath:keys.session equals:wnomObj.session])[aggregateScoreKey];
        if (!democY)
            democY = @0.0f;
        if (!repubY)
            repubY = @0.0f;

        [repubScores addObject:repubY];
        [demScores addObject:democY];
        [dates addObject:date];

        double legVal = wnomObj.wnomAdj.doubleValue;
        if (legVal != 0.0f)
            [memberScores addObject:wnomObj.wnomAdj];
        else
            [memberScores addObject:@CGFLOAT_MIN];
    }
    
    results[@"repub"] = repubScores;
    results[@"democ"] = demScores;
    results[@"member"] = memberScores;
    results[@"time"] = dates;
    
    return results;
}

- (NSDictionary *)partisanshipDataForLegislatorID:(NSNumber*)legislatorID
{
	if (!legislatorID)
		return nil;
	
	LegislatorObj *legislator = [LegislatorObj objectWithPrimaryKeyValue:legislatorID];
	if (!legislator)
		return nil;
    return [self partisanshipDataForLegislator:legislator];
}

- (void)loadPartisanIndexFromBundle
{
    _partyPartisanship = nil;
    NSArray *aggregateObjects = nil;

    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *localPath = [[UtilityMethods applicationCachesDirectory] stringByAppendingPathComponent:@"PartyPartisanshipObj.plist"];
    BOOL isDirectory = NO;
    if ([fileManager fileExistsAtPath:localPath isDirectory:&isDirectory] && !isDirectory)
    {
        aggregateObjects = [NSKeyedUnarchiver unarchiveObjectWithFile:localPath];

        if (!aggregateObjects)
        {
            NSURL *fileURL = [NSURL fileURLWithPath:localPath isDirectory:NO];
            //NSAssert(fileURL != nil, @"Should have a URL to PartyPartisanshipObj.plist");

            aggregateObjects = [[NSArray alloc] initWithContentsOfURL:fileURL];
        }
    }

    if (!aggregateObjects.count)
    {
        NSError *jsonError = nil;
        NSString *bundledPath = [[NSBundle mainBundle] pathForResource:@"WnomAggregateObj" ofType:@"json"];
        //[fileManager copyItemAtPath:defaultPath toPath:localPath error:&jsonError];
        NSAssert(bundledPath != nil, @"Should have a bundled WnomAggregateObj.json");

        NSData *jsonData = [NSData dataWithContentsOfFile:bundledPath options:NSDataReadingMappedIfSafe error:&jsonError];
        NSArray<NSDictionary *> *jsonObjects = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingAllowFragments error:&jsonError];

        NSMutableArray *aggregates = [[NSMutableArray alloc] init];
        [jsonObjects enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (!SLTypeDictionaryOrNil(obj))
            {
                NSLog(@"Unable to map the aggregate object to PartyPartisanshipObj: %@", obj);
                return;
            }
            PartyPartisanshipObj *newObject = [[PartyPartisanshipObj alloc] initWithDictionary:obj];
            if (!newObject)
            {
                NSLog(@"Unable to map the aggregate object to PartyPartisanshipObj: %@", obj);
                return;
            }
            [aggregates addObject:newObject];
        }];

        if (aggregates.count)
            aggregateObjects = [aggregates copy];
    }

    if (aggregateObjects.count)
    {
        self.partyPartisanship = aggregateObjects;
    }

#if 0
	// We had trouble loading the metadata online, so pull it up from the one in the documents folder (or the app bundle)
	NSError *newError = nil;
	//NSString *jsonPath = [[UtilityMethods applicationCachesDirectory] stringByAppendingPathComponent:@"WnomAggregateObj.json"];

	if (![fileManager fileExistsAtPath:localPath])
    {
		NSString *defaultPath = [[NSBundle mainBundle] pathForResource:@"WnomAggregateObj" ofType:@"json"];
		[fileManager copyItemAtPath:defaultPath toPath:localPath error:&newError];
		debug_NSLog(@"PartisanIndex: copied metadata from the app bundle's original.");
	}
	else
    {
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
        if (_partyPartisanship)
        {
            _partyPartisanship = nil;
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
                self.partyPartisanship = [aggregates copy];
            }
        } @catch (NSException *exception) {
            NSLog(@"Exception while attempting to parse and consume aggregate partisan scores from the bundled JSON: %@", exception);
        }
    }
#endif

	if (_partyPartisanship.count)
    {
		//[self resetData:nil];
		[[NSNotificationCenter defaultCenter] postNotificationName:kPartisanIndexNotifyLoaded object:nil];
	}
}

- (void)loadPartisanIndex
{
	if ([TexLegeReachability texlegeReachable])
    {
		if (IsEmpty(_partyPartisanship))
        {
			[self loadPartisanIndexFromBundle];		// we do this automatically if we're not reachable
		}
		
		_loading = YES;

		//[[RKClient sharedClient] get:[NSString stringWithFormat:@"/%@", @"WnomAggregateObj.json"] delegate:self];
	}
	else
    {
		[self request:nil didFailLoadWithError:nil];
	}
}

#pragma mark -
#pragma mark RestKit:RKObjectLoaderDelegate

- (void)request:(RKRequest*)request didFailLoadWithError:(NSError*)error
{
	_loading = NO;
	
	if (error && request)
    {
		debug_NSLog(@"Error loading partisan index from %@: %@", [request description], [error localizedDescription]);
		[[NSNotificationCenter defaultCenter] postNotificationName:kPartisanIndexNotifyError object:nil];
	}
	
	[self loadPartisanIndexFromBundle];
}

#if 0

- (void)request:(RKRequest*)request didLoadResponse:(RKResponse*)response
{
	_loading = NO;

    if (!request || ![request isGET] || ![response isOK])
        return;

    // Success! Let's take a look at the data
    __partyPartisanship = nil;

    NSError *error = nil;

    NSMutableArray *aggregates = [NSJSONSerialization JSONObjectWithData:response.body options:NSJSONReadingMutableContainers | NSJSONReadingMutableLeaves error:&error];
    if (error)
    {
        debug_NSLog(@"Error while attempting to parse aggregate partisan scores from the bundled JSON: %@", error);
    }

    if (!aggregates || ![aggregates isKindOfClass:[NSArray class]] || !aggregates.count)
    {
        [self request:request didFailLoadWithError:nil];
        return;
    }

    self.partyPartisanship = aggregates;
    _updated = [NSDate date];
    
    NSString *localPath = [[UtilityMethods applicationCachesDirectory] stringByAppendingPathComponent:@"WnomAggregateObj.json"];
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:_partyPartisanship options:NSJSONWritingPrettyPrinted error:&error];
    if (![jsonData writeToFile:localPath atomically:YES])
    {
        NSLog(@"PartisanIndex: error writing cache to file: %@", localPath);
    }
    _fresh = YES;
    [self resetData:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:kPartisanIndexNotifyLoaded object:nil];
    debug_NSLog(@"PartisanIndex network download successful, archiving for others.");
}

#endif

- (void)didUpdatePartyPartisanship:(NSArray<PartyPartisanshipObj *> *)partyPartisanship
{
    if (!partyPartisanship || !partyPartisanship.count)
        return;

    _loading = NO;
    _updated = [NSDate date];
    _fresh = YES;

    NSString *localPath = [[UtilityMethods applicationCachesDirectory] stringByAppendingPathComponent:@"PartyPartisanshipObj.plist"];

    if (![NSKeyedArchiver archiveRootObject:partyPartisanship toFile:localPath])
    {
        NSLog(@"Could not write the PartyPartisanshipObj to %@", localPath);
    }

    self.partyPartisanship = partyPartisanship;

    [[NSNotificationCenter defaultCenter] postNotificationName:kPartisanIndexNotifyLoaded object:nil];
}

@end
