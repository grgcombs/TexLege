//
//  BillsKeyViewController.m
//  Created by Gregory Combs on 3/14/11.
//
//  StatesLege by Sunlight Foundation, based on work at https://github.com/sunlightlabs/StatesLege
//
//  This work is licensed under the Creative Commons Attribution-NonCommercial 3.0 Unported License. 
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc/3.0/
//  or send a letter to Creative Commons, 444 Castro Street, Suite 900, Mountain View, California, 94041, USA.
//
//

#import "BillsKeyViewController.h"
#import "TexLegeAppDelegate.h"
#import "BillsDetailViewController.h"
#import "UtilityMethods.h"
#import "TexLegeTheme.h"
#import "DisclosureQuartzView.h"
#import "BillSearchDataSource.h"
#import "OpenLegislativeAPIs.h"
#import "TexLegeStandardGroupCell.h"
#import "NSDate+Helper.h"
#import "TexLegeCoreDataUtils.h"
#import "LoadingCell.h"

@interface BillsKeyViewController()
@property (nonatomic,copy) NSMutableArray *keyBills;
@property (nonatomic,assign) NSInteger loadingStatus;
@end

@implementation BillsKeyViewController

#pragma mark -
#pragma mark View lifecycle

- (instancetype)initWithStyle:(UITableViewStyle)style
{
	if ((self = [super initWithStyle:style]))
    {
		_loadingStatus = LOADING_IDLE;
		_keyBills = [[NSMutableArray alloc] init];
	}
	return self;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
	if ([UtilityMethods isIPadDevice] && UIInterfaceOrientationIsLandscape(toInterfaceOrientation))
    {
		if ([[TexLegeAppDelegate appDelegate].masterNavigationController.topViewController isKindOfClass:[BillsKeyViewController class]])
			if ([self.navigationController isEqual:[TexLegeAppDelegate appDelegate].detailNavigationController])
				[self.navigationController popToRootViewControllerAnimated:YES];
	}	
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)dealloc
{
	[[RKRequestQueue sharedQueue] cancelRequestsWithDelegate:self];
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	NSString *thePath = [[NSBundle mainBundle]  pathForResource:@"TexLegeStrings" ofType:@"plist"];
	NSDictionary *textDict = [NSDictionary dictionaryWithContentsOfFile:thePath];
	NSString *myClass = NSStringFromClass([self class]);
	NSDictionary *menuItem = [textDict[@"BillMenuItems"] findWhereKeyPath:@"class" equals:myClass];
	
	if (menuItem)
		self.title = menuItem[@"title"];
	
	self.tableView.delegate = self;
	self.tableView.dataSource = self;
	self.tableView.separatorColor = [TexLegeTheme separator];
	self.tableView.backgroundColor = [TexLegeTheme tableBackground];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
	self.navigationController.navigationBar.tintColor = [TexLegeTheme navbar];	
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	self.navigationController.navigationBar.tintColor = [TexLegeTheme navbar];

	[self startSearchForKeyBills];
}

- (void)viewDidUnload
{
	[super viewDidUnload];
}


#pragma mark -
#pragma mark Table view data source

- (void)tableView:(UITableView *)aTableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
	BOOL useDark = (indexPath.row % 2 == 0);
	cell.backgroundColor = useDark ? [TexLegeTheme backgroundDark] : [TexLegeTheme backgroundLight];
}

- (void)configureCell:(TexLegeStandardGroupCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
	if (IsEmpty(_keyBills))
		return;
		
	BOOL useDark = (indexPath.row % 2 == 0);
	cell.backgroundColor = useDark ? [TexLegeTheme backgroundDark] : [TexLegeTheme backgroundLight];
	NSDictionary *bill = _keyBills[indexPath.row];
	if (bill) {
		NSString *bill_title = bill[@"title"];
		bill_title = [bill_title chopPrefix:@"Relating to " capitalizingFirst:YES];

		cell.detailTextLabel.text = bill_title;
		NSMutableString *name = [NSMutableString stringWithString:bill[@"bill_id"]];
		if (!IsEmpty(bill[@"passFail"]))
			[name appendFormat:@" - %@", bill[@"passFail"]];
		
		cell.textLabel.text = [NSString stringWithFormat:@"(%@) %@", 
							   bill[@"session"],
							   name];
		//cell.textLabel.text = name;
	}	
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (self.loadingStatus > LOADING_IDLE)
    {
		if (indexPath.row == 0)
        {
			return [LoadingCell loadingCellWithStatus:self.loadingStatus tableView:tableView];
		}
		else
        {	// to make things work with our upcoming configureCell:, we need to trick this a little
			indexPath = [NSIndexPath indexPathForRow:(indexPath.row-1) inSection:indexPath.section];
		}
	}
	
	NSString *CellIdentifier = [TexLegeStandardGroupCell cellIdentifier];
	
	TexLegeStandardGroupCell *cell = (TexLegeStandardGroupCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (cell == nil)
	{
		cell = [[TexLegeStandardGroupCell alloc] initWithStyle:UITableViewCellStyleSubtitle 
												reuseIdentifier:CellIdentifier];		
		
		cell.textLabel.textColor = [TexLegeTheme textDark];
		cell.detailTextLabel.textColor = [TexLegeTheme indexText];
		cell.textLabel.font = [TexLegeTheme boldFourteen];
	}
	[self configureCell:cell atIndexPath:indexPath];		
	return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	if (!IsEmpty(_keyBills))
		return _keyBills.count;
	else if (self.loadingStatus > LOADING_IDLE)
		return 1;
	else
		return 0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (![UtilityMethods isIPadDevice])
		[tableView deselectRowAtIndexPath:indexPath animated:YES];
	
	if (IsEmpty(_keyBills) || _keyBills.count <= indexPath.row)
		return;
	
	NSDictionary *bill = _keyBills[indexPath.row];
    if (![bill isKindOfClass:[NSDictionary class]])
        return;
    NSString *billID = bill[@"bill_id"];
    if (![billID isKindOfClass:[NSString class]])
        return;

    BOOL changingViews = NO;
    UINavigationController *detailNav = [[TexLegeAppDelegate appDelegate] detailNavigationController];
    BillsDetailViewController *detailView = nil;
    if ([UtilityMethods isIPadDevice])
    {
        id aDetail = detailNav.visibleViewController;
        if ([aDetail isKindOfClass:[BillsDetailViewController class]])
            detailView = aDetail;
    }
    if (!detailView)
    {
        detailView = [[BillsDetailViewController alloc] initWithNibName:@"BillsDetailViewController" bundle:nil];
        changingViews = YES;
    }

    detailView.dataObject = bill;
    [[OpenLegislativeAPIs sharedOpenLegislativeAPIs] queryOpenStatesBillWithID:billID
                                                                       session:bill[@"session"] // nil defaults to current session
                                                                      delegate:detailView];

    if (![UtilityMethods isIPadDevice])
        [self.navigationController pushViewController:detailView animated:YES];
    else if (changingViews)
        [detailNav setViewControllers:@[detailView] animated:NO];
}

// http://api.votesmart.org/Votes.getBillsByYearState?key=5fb3b476c47fcb8a21dc2ec22ca92cbb&year=2011&stateId=TX&o=JSON

- (void)startSearchForKeyBills
{
	if ([TexLegeReachability texlegeReachable])
    {
		self.loadingStatus = LOADING_ACTIVE;
		RKRequest *request = [[RKClient sharedClient] get:@"/rest.php/KeyBills" delegate:self];
		if (!request)
        {
			NSLog(@"BillsKeyViewController: Error, unable to create RestKit request for KeyBills");
        }
	}
	else
    {
		self.loadingStatus = LOADING_NO_NET;
	}
}


#pragma mark -
#pragma mark RestKit:RKObjectLoaderDelegate

- (void)request:(RKRequest*)request didFailLoadWithError:(NSError*)error
{
    if (error && request)
    {
        debug_NSLog(@"BillDetail - Error loading search results from %@: %@", [request description], [error localizedDescription]);
    }

    NSString *title = NSLocalizedStringFromTable(@"Network Error", @"AppAlerts", @"Title for alert stating there's been an error when connecting to a server");
    NSString *message = NSLocalizedStringFromTable(@"There was an error while contacting the server for bill information.  Please check your network connectivity or try again.", @"AppAlerts", @"");

    UIAlertController *controller = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:nil style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {

    }];
    [controller addAction:cancel];
    controller.preferredAction = cancel;

    self.loadingStatus = LOADING_NO_NET;

    [self showViewController:controller sender:self];
}

- (void)request:(RKRequest*)request didLoadResponse:(RKResponse*)response
{
    if (!request || ![request isGET] || ![response isOK])
        return;

    // Success! Let's take a look at the data
    self.loadingStatus = LOADING_IDLE;

    [self.keyBills removeAllObjects];

    NSError *error = nil;
    NSArray *items = [NSJSONSerialization JSONObjectWithData:response.body options:0 error:&error];
    if ([items isKindOfClass:[NSArray class]] && items.count)
        [_keyBills addObjectsFromArray:items];

    // if we wanted blocks, we'd do this instead:
    [_keyBills sortUsingComparator:^(NSDictionary *item1, NSDictionary *item2) {
        NSString *bill_id1 = item1[@"bill_id"];
        NSString *bill_id2 = item2[@"bill_id"];
        return [bill_id1 compare:bill_id2 options:NSNumericSearch];
    }];

    [self.tableView reloadData];
}

@end
