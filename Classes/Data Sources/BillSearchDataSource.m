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
@property (NS_NONATOMIC_IOSONLY, copy) NSMutableArray *rows;
@property (NS_NONATOMIC_IOSONLY, copy) NSMutableDictionary *sections;
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
        _rows = [[NSMutableArray alloc] init];
        _sections = [[NSMutableDictionary alloc] init];

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
	[[RKClient sharedClient].requestQueue cancelRequestsWithDelegate:self];
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
    NSString *key = [self billTypes][indexPath.section];
    if (!key)
        return nil;

    NSArray *billSection = self.sections[key];
    if (!billSection
        || ![billSection respondsToSelector:@selector(objectAtIndex:)]
        || ![billSection respondsToSelector:@selector(count)])
    {
        return nil;
    }

    if (billSection.count <= indexPath.row)
        return nil;

    NSDictionary *bill = billSection[indexPath.row];
	return bill;
}

- (NSIndexPath *)indexPathForDataObject:(id)dataObject
{
    if (!dataObject || ![dataObject isKindOfClass:[NSDictionary class]])
        return nil;

    NSString *billID = dataObject[@"bill_id"];
    if (!billID || ![billID isKindOfClass:[NSString class]])
        return nil;

    NSString *typeString = billTypeStringFromBillID(billID);
    if (IsEmpty(typeString))
        return nil;

    NSArray *sectionRow = _sections[typeString];
    if (IsEmpty(sectionRow))
        return nil;

    NSArray *sortedSections = [self billTypes];
    if (IsEmpty(sortedSections))
        return nil;

    NSInteger section = [sortedSections indexOfObject:typeString];
    NSInteger row = [sectionRow indexOfObject:dataObject];
    if (section == NSNotFound || row == NSNotFound)
        return nil;

    return [NSIndexPath indexPathForRow:row inSection:section];
}

- (void)generateSections
{
    _sections = [[NSMutableDictionary alloc] init];

    [_rows enumerateObjectsUsingBlock:^(NSDictionary *bill, NSUInteger idx, BOOL * stop)
    {
        if (![bill isKindOfClass:[NSDictionary class]])
            return;

        NSString *billType = billTypeStringFromBillID(bill[@"bill_id"]);
        if (!billType || ![billType isKindOfClass:[NSString class]] || IsEmpty(billType))
            return;

        NSMutableArray *bills = self.sections[billType];
        if (!bills)
        {
            bills = [NSMutableArray array];
            _sections[billType] = bills;
        }

        [bills addObject:bill];
    }];

	[_sections enumerateKeysAndObjectsUsingBlock:^(NSString *billType, NSMutableArray *bills, BOOL * stop) {
        [bills sortUsingComparator:^NSComparisonResult(NSDictionary *bill1, NSDictionary *bill2) {
            NSString *bill_id1 = bill1[@"bill_id"];
            NSString *bill_id2 = bill2[@"bill_id"];
            return [bill_id1 compare:bill_id2 options:NSNumericSearch];
        }];
    }];
}

#pragma mark UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	if (IsEmpty(self.sections))
		return 1;
	return self.sections.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSArray *sortedSectionTitles = [self billTypes];
	if (IsEmpty(sortedSectionTitles))
		return @"";
    if (sortedSectionTitles.count <= section)
        return @"";

	NSString *billType = sortedSectionTitles[section];
    if (![billType isKindOfClass:[NSString class]])
        return @"";

    NSArray *typesMetadata = [BillMetadataLoader sharedBillMetadataLoader].metadata[@"types"];
    NSDictionary *metadata = [typesMetadata findWhereKeyPath:@"title" equals:billType];

	NSString *title = metadata[@"titleLong"];
    if (![title isKindOfClass:[NSString class]] || IsEmpty(title))
        return @"";
    return title;
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
    NSArray *sortedSectionTitles = [self billTypes];
	if (IsEmpty(sortedSectionTitles))
		return nil;
    return sortedSectionTitles;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSArray *sortedSectionTitles = [self billTypes];
    if (sortedSectionTitles.count <= section)
        return 0;

    NSString *sectionTitle = sortedSectionTitles[section];
    if (![sectionTitle isKindOfClass:[NSString class]])
        return 0;

    NSArray *bills = self.sections[sectionTitle];
    if (!bills || ![bills isKindOfClass:[NSArray class]])
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
	if (IsEmpty(meta.selectedState) || IsEmpty(meta.currentSession))
		return;

    NSArray *typesMetadata = [BillMetadataLoader sharedBillMetadataLoader].metadata[kBillMetadataTypesKey];
	for (NSDictionary *typeMetadata in typesMetadata)
    {
		NSString *billType = typeMetadata[kBillMetadataTitleKey];
	 
		if (billType && [searchString hasPrefix:billType])
        {
			NSString *tail = [searchString substringFromIndex:billType.length];
			if (tail)
            {
				tail = [tail stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
				
				if (tail.integerValue > 0)
                {
					isBillID = YES;

					NSNumber *billNumber = @(tail.integerValue);		// we specifically convolute this to ensure we're grabbing only the numerical of the string
					[queryString appendFormat:@"/%@/%@/%@%%20%@", meta.selectedState, meta.currentSession, billType, billNumber];
					
					break;
				}
			}			
		}
	}
	
	NSMutableDictionary *queryParams = [NSMutableDictionary dictionaryWithObjectsAndKeys:
										@"session", @"search_window",
										meta.selectedState, @"state",
										SUNLIGHT_APIKEY, @"apikey",
										nil];
	
	NSString *chamberString = stringForChamber(chamber, TLReturnOpenStates);
	if (!IsEmpty(chamberString))
    {
		queryParams[@"chamber"] = chamberString;
	}
	if (IsEmpty(searchString))
		searchString = @"";
	
	if (!isBillID){
		queryParams[@"q"] = searchString;
	}
	
	[self startSearchWithQueryString:queryString params:queryParams];
		
}

- (void)startSearchForSubject:(NSString *)searchSubject chamber:(NSInteger)chamber
{
	StateMetaLoader *meta = [StateMetaLoader instance];
	if (IsEmpty(meta.selectedState))
		return;
	
	NSMutableDictionary *queryParams = [NSMutableDictionary dictionaryWithObjectsAndKeys:
								 @"session", @"search_window",
								 meta.selectedState, @"state",
								 SUNLIGHT_APIKEY, @"apikey",
								 nil];
	
	NSString *chamberString = stringForChamber(chamber, TLReturnOpenStates);
	if (!IsEmpty(chamberString)) {
		queryParams[@"chamber"] = chamberString;
	}
	if (IsEmpty(searchSubject))
		searchSubject = @"";
	else {
		NSDictionary *tagSubject = @{@"subject": searchSubject};
		[[LocalyticsSession sharedLocalyticsSession] tagEvent:@"BILL_SUBJECTS" attributes:tagSubject];	
	}
	queryParams[@"subject"] = searchSubject;
				
	[self startSearchWithQueryString:@"/bills" params:queryParams];
}

- (void)startSearchForBillsAuthoredBy:(NSString *)searchSponsorID
{
	if (NO == IsEmpty(searchSponsorID))
    {
		StateMetaLoader *meta = [StateMetaLoader instance];
		if (IsEmpty(meta.selectedState))
			return;
		
		NSDictionary *queryParams = @{@"sponsor_id": searchSponsorID,
									 @"state": meta.selectedState,
									 @"search_window": @"session",
									 @"apikey": SUNLIGHT_APIKEY,
									 // now for the fun part
									 @"fields": @"sponsors,bill_id,title,session,state,type,update_at,subjects"};

		RKRequest *request = [self startSearchWithQueryString:@"/bills" params:queryParams];
		if (request)
        {
			request.userData = @{@"sponsor_id": searchSponsorID};
		}
		
	}
}

- (BOOL)pruneBillsForAuthor:(NSString *)sponsorID
{
	// We must be requesting specific bills for a given sponsors

	if (IsEmpty(self.rows) || IsEmpty(sponsorID))
		return NO;

	debug_NSLog(@"Pruning the list of sought-after bills for a given sponsor...");

    NSMutableArray *authoredRows = [[NSMutableArray alloc] init];

    [self.rows enumerateObjectsWithOptions:0 usingBlock:^(NSDictionary *bill, NSUInteger billIndex, BOOL * billsStop) {
        if (![bill isKindOfClass:[NSDictionary class]])
            return;
        NSArray *sponsors = bill[@"sponsors"];
        if (!sponsors || ![sponsors isKindOfClass:[NSArray class]])
            return;

        [sponsors enumerateObjectsUsingBlock:^(NSDictionary *sponsor, NSUInteger sponsorIndex, BOOL * sponsorsStop) {
            if (![sponsor isKindOfClass:[NSDictionary class]])
                return;

            NSString *billSponsorID = sponsor[@"leg_id"];
            if (!billSponsorID || ![billSponsorID isKindOfClass:[NSString class]])
                return;
            if (![sponsorID isEqualToString:billSponsorID])
                return;
            NSString *sponsorshipType = sponsor[@"official_type"];
            if (!sponsorshipType || ![sponsorshipType isKindOfClass:[NSString class]])
            {
                sponsorshipType = sponsor[@"type"];
                if (!sponsorshipType || ![sponsorshipType isKindOfClass:[NSString class]])
                    return;
            }
            if ([sponsorshipType caseInsensitiveCompare:@"author"] == NSOrderedSame)
            {
                [authoredRows addObject:bill];
                *sponsorsStop = YES;
                return;
            }
        }];

//        if (!didAuthor)
//        {
//            [self.rows removeObjectAtIndex:billIndex];
//        }
    }];

//    if (tempRows)
//        [tempRows release];

    self.rows = authoredRows;

    return YES;
}


#pragma mark -
#pragma mark RestKit:RKObjectLoaderDelegate

- (void)request:(RKRequest*)request didFailLoadWithError:(NSError*)error {
	if (error && request) {
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

        _rows = [[NSMutableArray alloc] init];

        NSError *error = nil;
        id results= [NSJSONSerialization JSONObjectWithData:response.body options:NSJSONReadingMutableLeaves | NSJSONReadingMutableContainers error:&error];

		if ([results isKindOfClass:[NSArray class]])
			[_rows addObjectsFromArray:results];
		else if ([results isKindOfClass:[NSDictionary class]])
			[_rows addObject:results];

		// if we wanted blocks, we'd do this instead:
		[_rows sortUsingComparator:^(NSDictionary *item1, NSDictionary *item2) {
			NSString *bill_id1 = item1[@"bill_id"];
			NSString *bill_id2 = item2[@"bill_id"];
			return [bill_id1 compare:bill_id2 options:NSNumericSearch];
		}];

        [self generateSections];

		if (request.userData)
        {
			NSString *sponsorID = (request.userData)[@"sponsor_id"];
			if (NO == IsEmpty(sponsorID))
            {
				// We must be requesting specific bills for a given sponsors			
				if ([self pruneBillsForAuthor:sponsorID])
                    [self generateSections];
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
