//
//  BillSearchViewController.m
//  Created by Gregory Combs on 2/20/11.
//
//  StatesLege by Sunlight Foundation, based on work at https://github.com/sunlightlabs/StatesLege
//
//  This work is licensed under the Creative Commons Attribution-NonCommercial 3.0 Unported License. 
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc/3.0/
//  or send a letter to Creative Commons, 444 Castro Street, Suite 900, Mountain View, California, 94041, USA.
//
//

#import "BillSearchDataSource.h"
#import "TexLegeReachability.h"
#import "TexLegeTheme.h"
#import "TexLegeStandardGroupCell.h"
#import "BillMetadataLoader.h"
#import "OpenLegislativeAPIs.h"
#import "TexLegeLibrary.h"
#import "UtilityMethods.h"
#import "OpenLegislativeAPIs.h"
#import "LocalyticsSession.h"
#import "LoadingCell.h"
#import "StateMetaLoader.h"
#import "SLToastManager+TexLege.h"

@interface BillSearchDataSource ()
@property (NS_NONATOMIC_IOSONLY, copy) NSArray *rows;
@property (NS_NONATOMIC_IOSONLY, copy) NSDictionary *sections;
@property (NS_NONATOMIC_IOSONLY, assign) NSInteger loadingStatus;
@property (NS_NONATOMIC_IOSONLY, strong) IBOutlet UISearchDisplayController *searchDisplayController;
@property (NS_NONATOMIC_IOSONLY, strong) IBOutlet UITableViewController *delegateTVC;
@end

@implementation BillSearchDataSource

- (instancetype)init
{
    self = [super init];
	if (self)
    {
		_loadingStatus = LOADING_IDLE;
		_useLoadingDataCell = NO;
        _rows = @[];
        _sections = @{};

		[OpenLegislativeAPIs sharedOpenLegislativeAPIs];
	}
	return self;
}

- (instancetype)initWithSearchDisplayController:(UISearchDisplayController *)newController
{
    self = [super init];
    if (self)
    {
        if ([newController isKindOfClass:[UISearchDisplayController class]])
        {
            _searchDisplayController = newController;
            newController.searchResultsDataSource = self;
        }
	}
	return self;
}

- (instancetype)initWithTableViewController:(UITableViewController *)newDelegate
{
    self = [super init];
    if (self)
    {
        _delegateTVC = newDelegate;
	}
	return self;
}

- (void)dealloc
{
	[[RKRequestQueue sharedQueue] cancelRequestsWithDelegate:self];
    _delegateTVC = nil;
}

// This is just a short cut, we wind up using this array several times.  Perhaps we should remember it instead of recreating?
- (NSArray *)billTypes
{
    return [self.sections.allKeys sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
}

// return the map at the index in the array
- (id)dataObjectForIndexPath:(NSIndexPath *)indexPath
{
    NSArray *types = [self billTypes];
    if (!types)
        return nil;
    NSString *type = (types.count > indexPath.section) ? types[indexPath.section] : nil;
    if (!type)
        return nil;

    NSArray *billsForType = SLTypeArrayOrNil(self.sections[type]);
    if (!billsForType)
        return nil;

    NSDictionary *bill = (billsForType.count > indexPath.row) ? billsForType[indexPath.row] : nil;
	return SLTypeDictionaryOrNil(bill);
}

- (NSIndexPath *)indexPathForDataObject:(id)dataObject
{
    if (!SLTypeDictionaryOrNil(dataObject))
        return nil;

    NSString *billID = SLTypeStringOrNil(dataObject[@"bill_id"]);
    if (!billID)
        return nil;

    NSString *typeString = SLTypeNonEmptyStringOrNil(billTypeStringFromBillID(billID));
    if (!typeString)
        return nil;

    NSArray *billsForType = SLTypeNonEmptyArrayOrNil(_sections[typeString]);
    if (IsEmpty(billsForType))
        return nil;

    NSArray *sortedSections = [self billTypes];
    if (IsEmpty(sortedSections))
        return nil;

    NSInteger section = [sortedSections indexOfObject:typeString];
    NSInteger row = [billsForType indexOfObject:dataObject];
    if (section == NSNotFound || row == NSNotFound)
        return nil;

    return [NSIndexPath indexPathForRow:row inSection:section];
}

- (void)generateSectionsWithRows:(NSArray *)rows
{
    rows = SLTypeNonEmptyArrayOrNil(rows);
    NSMutableDictionary *sections = [[NSMutableDictionary alloc] init];

    [rows enumerateObjectsUsingBlock:^(NSDictionary *bill, NSUInteger idx, BOOL * stop)
    {
        if (!SLTypeDictionaryOrNil(bill))
            return;

        NSString *billID = SLTypeStringOrNil(bill[@"bill_id"]);
        NSString *billType = SLTypeNonEmptyStringOrNil(billTypeStringFromBillID(billID));
        if (!billType)
            return;

        NSMutableArray *bills = sections[billType];
        if (!bills)
        {
            bills = [@[] mutableCopy];
            sections[billType] = bills;
        }

        [bills addObject:bill];
    }];

    NSMutableDictionary *destination = [@{} mutableCopy];
	[sections enumerateKeysAndObjectsUsingBlock:^(NSString *billType, NSMutableArray *bills, BOOL * stop) {
        [bills sortUsingComparator:^NSComparisonResult(NSDictionary *bill1, NSDictionary *bill2) {
            NSString *bill_id1 = SLTypeStringOrNil(bill1[@"bill_id"]);
            NSString *bill_id2 = SLTypeStringOrNil(bill2[@"bill_id"]);
            return [bill_id1 compare:bill_id2 options:NSNumericSearch];
        }];
        destination[billType] = [bills copy];
    }];
    self.sections = [destination copy];
}

#pragma mark UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    NSDictionary *sections = self.sections;
	if (IsEmpty(sections))
		return 1;
	return sections.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSArray *sortedSectionTitles = [self billTypes];
	if (IsEmpty(sortedSectionTitles))
		return nil;
    if (sortedSectionTitles.count <= section)
        return nil;

	NSString *billType = SLTypeStringOrNil(sortedSectionTitles[section]);
    if (!billType)
        return nil;

    NSArray *typesMetadata = SLTypeArrayOrNil([BillMetadataLoader sharedBillMetadataLoader].metadata[@"types"]);
    NSDictionary *metadata = SLTypeDictionaryOrNil([typesMetadata findWhereKeyPath:@"title" equals:billType]);
	NSString *title = SLTypeNonEmptyStringOrNil(metadata[@"titleLong"]);
    return title;
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
    return SLTypeNonEmptyArrayOrNil([self billTypes]);
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSArray *sortedSectionTitles = [self billTypes];
    if (sortedSectionTitles.count <= section)
        return 0;

    NSString *sectionTitle = SLTypeStringOrNil(sortedSectionTitles[section]);
    if (!sectionTitle)
        return 0;

    NSArray *bills = SLTypeArrayOrNil(self.sections[sectionTitle]);
    if (!bills)
        return 0;
    if (IsEmpty(bills))
    {
        if (self.useLoadingDataCell && self.loadingStatus > LOADING_IDLE)
            return 1;
        return 0;
    }
    return bills.count;
}

- (void)configureCell:(TexLegeStandardGroupCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
	BOOL useDark = (indexPath.row % 2 == 0);
	cell.backgroundColor = useDark ? [TexLegeTheme backgroundDark] : [TexLegeTheme backgroundLight];
		
	// Configure the cell.
	//NSDictionary *bill = [_rows objectAtIndex:indexPath.row];
	NSDictionary *bill = [self dataObjectForIndexPath:indexPath];
	if (!bill || [[NSNull null] isEqual:bill])
		return;  // ?????
	
	NSString *bill_id = SLTypeStringOrNil(bill[@"bill_id"]);
	NSString *title = SLTypeStringOrNil(bill[@"title"]);
    NSString *session = SLTypeStringOrNil(bill[@"session"]);
    if (!bill_id || !title || !session)
        return;
    
	title = [title chopPrefix:@"Relating to " capitalizingFirst:YES];
	cell.textLabel.text = [NSString stringWithFormat:@"(%@) %@", session, bill_id];
	cell.detailTextLabel.text = title;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (self.useLoadingDataCell && self.loadingStatus > LOADING_IDLE)
    {
		if (indexPath.row == 0)
        {
			return [LoadingCell loadingCellWithStatus:self.loadingStatus tableView:tableView];
		}
		else {	// to make things work with our upcoming configureCell:, we need to trick this a little
			indexPath = [NSIndexPath indexPathForRow:(indexPath.row-1) inSection:indexPath.section];
		}
	}
	
	NSString *cellReuse = [TXLClickableSubtitleCell cellIdentifier];
	
	TexLegeStandardGroupCell *cell = (TexLegeStandardGroupCell *)[tableView dequeueReusableCellWithIdentifier:cellReuse];
	if (cell == nil)
	{
		cell = [[TexLegeStandardGroupCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellReuse];
    }
    [self configureCell:cell atIndexPath:indexPath];

	return cell;
}

#pragma mark - Searching

// This is the standard search method ... fill in the search parameters and it'll handle the rest.
- (RKRequest *)startSearchWithQueryString:(NSString *)queryString params:(NSDictionary *)queryParams
{
	if (IsEmpty(queryParams) || IsEmpty(queryString))
		return nil;
		
	RKRequest *request = nil;
	
	if ([TexLegeReachability canReachHostWithURL:[NSURL URLWithString:osApiBaseURL] alert:NO])
	{		
		if (self.useLoadingDataCell)
			self.loadingStatus = LOADING_ACTIVE;
		
		OpenLegislativeAPIs *api = [OpenLegislativeAPIs sharedOpenLegislativeAPIs];
		request = [api.osApiClient get:queryString queryParams:queryParams delegate:self];
	}
	else if (self.useLoadingDataCell) {
		self.loadingStatus = LOADING_NO_NET;
	}
	
	return request;
}

- (void)startSearchForText:(NSString *)searchString chamber:(NSInteger)chamber
{
	searchString = searchString.uppercaseString;
	NSMutableString *queryString = [NSMutableString stringWithString:@"/bills"];
	
	BOOL isBillID = NO;
	StateMetaLoader *meta = [StateMetaLoader instance];
    NSString *state = SLTypeNonEmptyStringOrNil(meta.selectedState);
    NSString *session = SLTypeStringOrNil(meta.currentSession);
    
	if (!state || !session)
		return;
    
    NSCharacterSet *whitespace = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    NSArray *typesMetadata = [BillMetadataLoader sharedBillMetadataLoader].metadata[kBillMetadataTypesKey];
    for (NSDictionary *typeMetadata in typesMetadata)
    {
        if (!SLTypeDictionaryOrNil(typeMetadata))
            continue;
        NSString *billType = SLTypeStringOrNil(typeMetadata[kBillMetadataTitleKey]);
        
        if (!billType || ![searchString hasPrefix:billType])
            continue;
        
        NSString *tail = [searchString substringFromIndex:billType.length];
        if (!tail)
            continue;
        tail = [tail stringByTrimmingCharactersInSet:whitespace];
        if (tail.integerValue > 0)
        {
            isBillID = YES;
            
            NSNumber *billNumber = @(tail.integerValue);		// we specifically convolute this to ensure we're grabbing only the numerical of the string
            [queryString appendFormat:@"/%@/%@/%@%%20%@", state, session, billType, billNumber];
            
            break;
        }
    }
	
    NSMutableDictionary *queryParams = [@{
                                          @"search_window": @"session",
                                          @"state": state,
                                          @"apikey": SUNLIGHT_APIKEY,
                                          } mutableCopy];
	
	NSString *chamberString = stringForChamber(chamber, TLReturnOpenStates);
	if (!IsEmpty(chamberString))
		queryParams[@"chamber"] = chamberString;
	if (IsEmpty(searchString))
		searchString = @"";
	if (!isBillID)
		queryParams[@"q"] = searchString;
	
	[self startSearchWithQueryString:queryString params:queryParams];
}

- (void)startSearchForSubject:(NSString *)searchSubject chamber:(NSInteger)chamber
{
	StateMetaLoader *meta = [StateMetaLoader instance];
    NSString *state = SLTypeNonEmptyStringOrNil(meta.selectedState);
	if (!state)
		return;
	
    NSMutableDictionary *queryParams = [@{
                                          @"search_window": @"session",
                                          @"state": state,
                                          @"apikey": SUNLIGHT_APIKEY,
                                          } mutableCopy];
	
	NSString *chamberString = SLTypeNonEmptyStringOrNil(stringForChamber(chamber, TLReturnOpenStates));
	if (!chamberString)
		queryParams[@"chamber"] = chamberString;

	if (!SLTypeNonEmptyStringOrNil(searchSubject))
		searchSubject = @"";
	else
    {
		NSDictionary *tagSubject = @{@"subject": searchSubject};
		[[LocalyticsSession sharedLocalyticsSession] tagEvent:@"BILL_SUBJECTS" attributes:tagSubject];	
	}
	queryParams[@"subject"] = searchSubject;
				
	[self startSearchWithQueryString:@"/bills" params:queryParams];
}

- (void)startSearchForBillsAuthoredBy:(NSString *)searchSponsorID
{
	if (!SLTypeNonEmptyStringOrNil(searchSponsorID))
        return;

    StateMetaLoader *meta = [StateMetaLoader instance];
    NSString *state = SLTypeNonEmptyStringOrNil(meta.selectedState);
    if (!state)
        return;
    
    NSDictionary *queryParams = @{@"sponsor_id": searchSponsorID,
                                  @"state": state,
                                  @"search_window": @"session",
                                  @"apikey": SUNLIGHT_APIKEY,
                                  @"fields": @"sponsors,bill_id,title,session,state,type,update_at,subjects"};

    RKRequest *request = [self startSearchWithQueryString:@"/bills" params:queryParams];
    if (request)
    {
        request.userData = @{@"sponsor_id": searchSponsorID};
    }
}

- (NSArray *)billsForAuthor:(NSString *)sponsorID
{
    NSArray *rows = self.rows;
    if (!SLTypeNonEmptyStringOrNil(sponsorID) || !SLTypeNonEmptyArrayOrNil(rows))
        return nil;

	debug_NSLog(@"Pruning the list of sought-after bills for a given sponsor...");

    NSMutableArray *authoredRows = [[NSMutableArray alloc] init];

    [rows enumerateObjectsWithOptions:0 usingBlock:^(NSDictionary *bill, NSUInteger billIndex, BOOL * billsStop) {
        if (!SLTypeDictionaryOrNil(bill))
            return ;
        NSArray *sponsors = SLTypeNonEmptyArrayOrNil(bill[@"sponsors"]);
        if (!sponsors)
            return;

        [sponsors enumerateObjectsUsingBlock:^(NSDictionary *sponsor, NSUInteger sponsorIndex, BOOL * sponsorsStop) {
            if (!SLTypeDictionaryOrNil(sponsor))
                return;

            NSString *billSponsorID = SLTypeStringOrNil(sponsor[@"leg_id"]);
            if (!billSponsorID)
                return;
            if (![sponsorID isEqualToString:billSponsorID])
                return;
            NSString *sponsorshipType = SLTypeStringOrNil(sponsor[@"official_type"]);
            if (!sponsorshipType)
            {
                sponsorshipType = SLTypeStringOrNil(sponsor[@"type"]);
                if (!sponsorshipType)
                    return;
            }
            if ([sponsorshipType caseInsensitiveCompare:@"author"] == NSOrderedSame)
            {
                [authoredRows addObject:bill];
                *sponsorsStop = YES;
                return;
            }
        }];
    }];

    rows = [authoredRows copy];
    return rows;
}

- (void)request:(RKRequest*)request didFailLoadWithError:(NSError*)error
{
	if (error && request)
    {
		debug_NSLog(@"Error loading search results from %@: %@", [request description], [error localizedDescription]);
	}	
	
	if (self.useLoadingDataCell)
		self.loadingStatus = LOADING_NO_NET;

	[[NSNotificationCenter defaultCenter] postNotificationName:kBillSearchNotifyDataError object:self];

	if (!self.useLoadingDataCell)
    {
        // if we don't have some visual cue (loading cell) already, send up an alert
        NSString *title = NSLocalizedStringFromTable(@"Network Error", @"AppAlerts", nil);
        NSString *message = NSLocalizedStringFromTable(@"There was an error while contacting the server for bill information.  Please check your network connectivity or try again.", @"AppAlerts", nil);
        [[SLToastManager txlSharedManager] addToastWithIdentifier:@"BillSearchNetError"
                                                             type:SLToastTypeError
                                                            title:title
                                                         subtitle:message
                                                            image:nil
                                                         duration:4];
	}
}

// Handling GET /BillMetadata.json  
- (void)request:(RKRequest*)request didLoadResponse:(RKResponse*)response
{
	if (self.useLoadingDataCell)
		self.loadingStatus = LOADING_NO_NET;

	if ([request isGET] && [response isOK])
    {
		// Success! Let's take a look at the data  
		
		if (self.useLoadingDataCell)
			self.loadingStatus = LOADING_IDLE;

        NSError *error = nil;
        id results = [NSJSONSerialization JSONObjectWithData:response.body options:0 error:&error];
        NSArray *rows = SLTypeArrayOrNil(results);
        if (!rows)
        {
            NSDictionary *asDict = SLTypeDictionaryOrNil(results);
            if (asDict)
                rows = @[asDict];
        }
        
        rows = [rows sortedArrayUsingComparator:^(NSDictionary *item1, NSDictionary *item2) {
            NSString *bill_id1 = SLTypeStringOrNil(item1[@"bill_id"]);
            NSString *bill_id2 = SLTypeStringOrNil(item2[@"bill_id"]);
            return [bill_id1 compare:bill_id2 options:NSNumericSearch];
        }];
        self.rows = rows;
        [self generateSectionsWithRows:rows];

		if (request.userData)
        {
			NSString *sponsorID = SLTypeNonEmptyStringOrNil(request.userData[@"sponsor_id"]);
			if (sponsorID)
            {
				// We must be requesting specific bills for a given sponsors			
                NSArray *sponsoredBills = [self billsForAuthor:sponsorID];
                [self generateSectionsWithRows:sponsoredBills];
			}
		}

		if (self.searchDisplayController)
			[self.searchDisplayController.searchResultsTableView reloadData];
		else if (self.delegateTVC)
			[self.delegateTVC.tableView reloadData];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:kBillSearchNotifyDataLoaded object:self];
	}
}

@end
