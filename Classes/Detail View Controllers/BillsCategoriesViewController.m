//
//  BillsCategoriesViewController.m
//  Created by Gregory Combs on 2/25/11.
//
//  StatesLege by Sunlight Foundation, based on work at https://github.com/sunlightlabs/StatesLege
//
//  This work is licensed under the Creative Commons Attribution-NonCommercial 3.0 Unported License. 
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc/3.0/
//  or send a letter to Creative Commons, 444 Castro Street, Suite 900, Mountain View, California, 94041, USA.
//
//

#import "BillsCategoriesViewController.h"
#import "UtilityMethods.h"
#import "TexLegeTheme.h"
#import "DisclosureQuartzView.h"
#import "TexLegeReachability.h"
#import "BillsListViewController.h"
#import "BillSearchDataSource.h"
#import "TexLegeBadgeGroupCell.h"
#import "BillMetadataLoader.h"
#import "OpenLegislativeAPIs.h"
#import "LoadingCell.h"
#import "StateMetaLoader.h"

@interface BillsCategoriesViewController ()

- (void)configureCell:(TexLegeBadgeGroupCell *)cell atIndexPath:(NSIndexPath *)indexPath;
- (void)createChamberControl;
- (IBAction)filterChamber:(id)sender;
- (IBAction)loadCategoriesForChamber:(NSInteger)newChamber;

@property (nonatomic,copy) NSMutableDictionary *categories;
@property (nonatomic,strong) IBOutlet UISegmentedControl *chamberControl;
@property (nonatomic,getter=isFresh) BOOL fresh;
@property (nonatomic,strong) NSDate *updated;
@property (nonatomic,assign) NSInteger loadingStatus;

@end

@implementation BillsCategoriesViewController

#pragma mark -
#pragma mark View lifecycle

- (instancetype)initWithStyle:(UITableViewStyle)style {
	if ((self=[super initWithStyle:style])) {
		_loadingStatus = LOADING_IDLE;
		_categories = [[NSMutableDictionary alloc] init];
		_updated = nil;
		_fresh = NO;
	}
	return self;
}

- (void)dealloc
{
	[[RKRequestQueue sharedQueue] cancelRequestsWithDelegate:self];

}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return YES;
}

- (void)didReceiveMemoryWarning {	
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}


- (void)viewDidLoad {
	[super viewDidLoad];
	
	NSString *thePath = [[NSBundle mainBundle]  pathForResource:@"TexLegeStrings" ofType:@"plist"];
	NSDictionary *textDict = [NSDictionary dictionaryWithContentsOfFile:thePath];
	NSString *myClass = NSStringFromClass([self class]);
	NSDictionary *menuItem = [textDict[@"BillMenuItems"] findWhereKeyPath:@"class" equals:myClass];
	
	if (menuItem) {
		self.title = menuItem[@"title"];
	}
	
	self.tableView.separatorColor = [TexLegeTheme separator];
	self.tableView.backgroundColor = [TexLegeTheme tableBackground];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
	self.navigationController.navigationBar.tintColor = [TexLegeTheme navbar];

	[self createChamberControl];
	
	self.chamberControl.tintColor = [TexLegeTheme accent];
	self.navigationItem.titleView = self.chamberControl;
	
	UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.tableView.bounds.size.width, 28)];
	label.backgroundColor = [TexLegeTheme accent];
	label.font = [TexLegeTheme boldFifteen];
	//label.shadowColor = [UIColor colorWithWhite:0.0 alpha:0.8];
	label.textAlignment = NSTextAlignmentCenter;
	label.textColor = [TexLegeTheme backgroundLight];
	label.lineBreakMode = NSLineBreakByTruncatingTail;
	//label.numberOfLines =
	label.text = NSLocalizedStringFromTable(@"Large subjects download slowly.", @"DataTableUI", @"Tells the user that downloading a long list of bills for a given subject will take some time."); 
	self.tableView.tableHeaderView = label;
	
	[self chamberCategories];	// load them from the network, if necessary
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
	self.navigationController.navigationBar.tintColor = [TexLegeTheme navbar];

	NSDictionary *segPrefs = [[NSUserDefaults standardUserDefaults] objectForKey:kSegmentControlPrefKey];
	if (segPrefs) {
		NSNumber *segIndex = segPrefs[NSStringFromClass([self class])];
		if (segIndex)
			self.chamberControl.selectedSegmentIndex = segIndex.integerValue;
	}
}

- (IBAction)filterChamber:(id)sender {
	NSDictionary *segPrefs = [[NSUserDefaults standardUserDefaults] objectForKey:kSegmentControlPrefKey];
	if (segPrefs) {
		NSString *segIndex = [NSString stringWithFormat:@"%ld",(long)self.chamberControl.selectedSegmentIndex];
		NSMutableDictionary *newDict = [segPrefs mutableCopy];
		newDict[NSStringFromClass([self class])] = segIndex;
		[[NSUserDefaults standardUserDefaults] setObject:newDict forKey:kSegmentControlPrefKey];
		[[NSUserDefaults standardUserDefaults] synchronize];
	}
	
	[self.tableView reloadData];
}

- (NSString *)chamber {
	NSInteger theChamber = BOTH_CHAMBERS;
	if (self.chamberControl)
		theChamber = self.chamberControl.selectedSegmentIndex;
	return [NSString stringWithFormat:@"%ld", (long)theChamber];
}

- (void)viewDidUnload {
	self.chamberControl = nil;
	[super viewDidUnload];
}

- (void)configureCell:(TexLegeBadgeGroupCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    NSString *chamber = self.chamber;
	if (!chamber)
		return;
    NSArray *categoryRows = self.categories[chamber];
    if (categoryRows.count <= indexPath.row)
        return;
    NSDictionary *categoryRow = categoryRows[indexPath.row];
    if (![categoryRow isKindOfClass:[NSDictionary class]])
        return;

	BOOL useDark = (indexPath.row % 2 == 0);
	cell.backgroundColor = useDark ? [TexLegeTheme backgroundDark] : [TexLegeTheme backgroundLight];

	BOOL clickable = [categoryRow[kBillCategoriesCountKey] integerValue] > 0;
	NSDictionary *cellDict = @{@"entryValue": categoryRow[kBillCategoriesCountKey],
							  @"isClickable": @(clickable),
							  @"title": categoryRow[kBillCategoriesTitleKey]};
	TableCellDataObject *cellInfo = [[TableCellDataObject alloc] initWithDictionary:cellDict];
	cell.cellInfo = cellInfo;
}

#pragma mark -
#pragma mark Table view data source

- (void)tableView:(UITableView *)aTableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
	BOOL useDark = (indexPath.row % 2 == 0);
	cell.backgroundColor = useDark ? [TexLegeTheme backgroundDark] : [TexLegeTheme backgroundLight];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	if (!IsEmpty(self.categories[self.chamber]))
		return [self.categories[self.chamber] count];
	else if (self.loadingStatus > LOADING_IDLE)
		return 1;
	else
		return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (self.loadingStatus > LOADING_IDLE) {
		if (indexPath.row == 0) {
			return [LoadingCell loadingCellWithStatus:self.loadingStatus tableView:tableView];
		}
		else {	// to make things work with our upcoming configureCell:, we need to trick this a little
			indexPath = [NSIndexPath indexPathForRow:(indexPath.row-1) inSection:indexPath.section];
		}
	}
	
	NSString *CellIdentifier = [TexLegeBadgeGroupCell cellIdentifier];
		
	TexLegeBadgeGroupCell *cell = (TexLegeBadgeGroupCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (cell == nil)
	{
		cell = [[TexLegeBadgeGroupCell alloc] initWithStyle:UITableViewCellStyleSubtitle 
									   reuseIdentifier:CellIdentifier];		
    }
	
	[self configureCell:cell atIndexPath:indexPath];		
	return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[tableView deselectRowAtIndexPath:indexPath animated:YES];

    NSDictionary *categories = self.categories;
    if (!categories)
        return;
    NSArray *chamberCategories = categories[self.chamber];
    if (chamberCategories.count <= indexPath.row)
        return;
    NSDictionary *category = chamberCategories[indexPath.row];
	if (category && category[kBillCategoriesTitleKey]) {
		NSString *cat = category[kBillCategoriesTitleKey];
		NSInteger count = [category[kBillCategoriesCountKey] integerValue];
		if (cat && count) {
			BillsListViewController *catResultsView = [[BillsListViewController alloc] initWithStyle:UITableViewStylePlain];
			BillSearchDataSource *dataSource = [catResultsView valueForKey:@"dataSource"];
			catResultsView.title = cat;
			[dataSource startSearchForSubject:cat chamber:(self.chamber).integerValue];
			
			[self.navigationController pushViewController:catResultsView animated:YES];
		}			
	}	
}

#pragma mark Properties

//http://openstates.sunlightlabs.com/api/v1/subject_counts/tx/82/upper/?apikey=xxxxxxxxxxxxxxxx
//We now get subject frequency counts, filtered by state, session and originating chamber.

- (IBAction)loadCategoriesForChamber:(NSInteger)newChamber {
	if ([TexLegeReachability openstatesReachable]) {
		self.loadingStatus = LOADING_ACTIVE;
		OpenLegislativeAPIs *api = [OpenLegislativeAPIs sharedOpenLegislativeAPIs];
		StateMetaLoader *meta = [StateMetaLoader instance];
		if (IsEmpty(meta.selectedState) || IsEmpty(meta.currentSession))
			return;
		
		NSDictionary *queryParams = @{@"apikey": SUNLIGHT_APIKEY};
		NSMutableString *resourcePath = [NSMutableString stringWithFormat:@"/subject_counts/%@/%@/", meta.selectedState, meta.currentSession];
		if (newChamber > BOTH_CHAMBERS)
			[resourcePath appendFormat:@"%@/", stringForChamber(newChamber, TLReturnOpenStates)];
			
		[api.osApiClient get:resourcePath queryParams:queryParams delegate:self];
	}
	else {
		self.loadingStatus = LOADING_NO_NET;
	}
}

- (NSMutableDictionary*)chamberCategories {
	if (!self.categories ||
		(!self.isFresh && !self.categories[self.chamber]) ||
		!self.updated ||
		([[NSDate date] timeIntervalSinceDate:self.updated] > 3600*24)) {	// if we're over a day old, let's refresh
		self.fresh = NO;
		debug_NSLog(@"BillCategories is stale, need to refresh");
		
		[self loadCategoriesForChamber:BOTH_CHAMBERS];	// let's get everything
	}
	return self.categories;
}


#pragma mark -
#pragma mark Chamber Control

- (void)createChamberControl {	
	UISegmentedControl *ctl = [[UISegmentedControl alloc] initWithItems:@[stringForChamber(BOTH_CHAMBERS, TLReturnFull), 
																		stringForChamber(HOUSE, TLReturnFull), 
																		 stringForChamber(SENATE, TLReturnFull)]];
	ctl.frame = CGRectMake(0.0, 0.0, 163.0, 30.0);
	ctl.autoresizesSubviews = YES;
	ctl.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
	ctl.clipsToBounds = NO;
	ctl.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
	ctl.contentMode = UIViewContentModeScaleToFill;
	ctl.contentVerticalAlignment = UIControlContentVerticalAlignmentTop;
	ctl.enabled = YES;
	ctl.opaque = NO;
	ctl.selectedSegmentIndex = 0;
	ctl.userInteractionEnabled = YES;
	self.chamberControl = ctl;
	[self.chamberControl addTarget:self action:@selector(filterChamber:) forControlEvents:UIControlEventValueChanged];
}

#pragma mark -
#pragma mark RestKit:RKObjectLoaderDelegate

- (void)request:(RKRequest*)request didFailLoadWithError:(NSError*)error
{
	if (error && request)
    {
		debug_NSLog(@"Error loading categories from %@: %@", [request description], [error localizedDescription]);
	}
	[[NSNotificationCenter defaultCenter] postNotificationName:kBillCategoriesNotifyError object:nil];
    self.loadingStatus = LOADING_IDLE;

	self.fresh = NO;
	
    self.categories = nil;
	
	// We had trouble loading the events online, so pull up the cache from the one in the documents folder, if possible
	NSString *thePath = [[UtilityMethods applicationCachesDirectory] stringByAppendingPathComponent:kBillCategoriesCacheFile];
	NSFileManager *fileManager = [NSFileManager defaultManager];
	if ([fileManager fileExistsAtPath:thePath]) {
		debug_NSLog(@"BillCategories: using cached categories in the documents folder.");
		NSData *json = [NSData dataWithContentsOfFile:thePath];
        NSError *error = nil;
		if (json)
            self.categories = [NSJSONSerialization JSONObjectWithData:json options:NSJSONReadingMutableLeaves | NSJSONReadingMutableContainers error:&error];
	}
	if (!self.categories) {
		_categories = [[NSMutableDictionary alloc] init];
        self.loadingStatus = LOADING_NO_NET;
	}
	
	[[NSNotificationCenter defaultCenter] postNotificationName:kBillCategoriesNotifyLoaded object:nil];
	
	[self.tableView reloadData];

}


- (void)request:(RKRequest*)request didLoadResponse:(RKResponse*)response
{
	if ([request isGET] && [response isOK])
    {
		// Success! Let's take a look at the data  
		
        NSError *error = nil;
        NSMutableDictionary *newCats = [NSJSONSerialization JSONObjectWithData:response.body options:NSJSONReadingMutableLeaves | NSJSONReadingMutableContainers error:&error];

		if (!newCats)
			return;
		
		NSMutableArray *newArray = [[NSMutableArray alloc] init];
		for (NSString *name in newCats.allKeys) {
			NSNumber *total = newCats[name];
			NSMutableDictionary *newEntry = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
											 name, kBillCategoriesTitleKey,
											 total, kBillCategoriesCountKey,
											 nil];
			[newArray addObject:newEntry];
		}
		NSSortDescriptor *desc = [NSSortDescriptor sortDescriptorWithKey:kBillCategoriesTitleKey ascending:YES];
		[newArray sortUsingDescriptors:@[desc]];
		
		NSInteger inChamber = BOTH_CHAMBERS;
		if ([request.resourcePath hasSubstring:@"/upper" caseInsensitive:NO])
			inChamber = SENATE;
		else if ([request.resourcePath hasSubstring:@"/lower" caseInsensitive:NO])
			inChamber = HOUSE;

		self.categories[[NSString stringWithFormat:@"%ld", (long)inChamber]] = newArray;
		
		if (inChamber < SENATE)
			[self loadCategoriesForChamber:inChamber+1];	// let's load the next chamber too
		
		if (self.categories.count == 3) { // once we have all three arrays ready to go, let's save it
			NSString *thePath = [[UtilityMethods applicationCachesDirectory] stringByAppendingPathComponent:kBillCategoriesCacheFile];
			NSError *error = nil;
            NSData *json = [NSJSONSerialization dataWithJSONObject:self.categories options:NSJSONWritingPrettyPrinted error:&error];

			if (![json writeToFile:thePath atomically:YES]) {
				NSLog(@"BillCategories: Error writing categories cache to file: %@ = %@", error.localizedDescription, thePath);
			}
		}
		
		self.fresh = YES;
        self.updated = [NSDate date];
		self.loadingStatus = LOADING_IDLE;

		[[NSNotificationCenter defaultCenter] postNotificationName:kBillCategoriesNotifyLoaded object:nil];
		
		[self.tableView reloadData];
	}
}

@end

