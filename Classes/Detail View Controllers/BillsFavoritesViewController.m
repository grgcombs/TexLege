//
//  BillsFavoritesViewController.m
//  Created by Gregory Combs on 2/25/11.
//
//  StatesLege by Sunlight Foundation, based on work at https://github.com/sunlightlabs/StatesLege
//
//  This work is licensed under the Creative Commons Attribution-NonCommercial 3.0 Unported License. 
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc/3.0/
//  or send a letter to Creative Commons, 444 Castro Street, Suite 900, Mountain View, California, 94041, USA.
//
//

#import "TexLegeAppDelegate.h"
#import "BillsFavoritesViewController.h"
#import "BillsDetailViewController.h"
#import "UtilityMethods.h"
#import "TexLegeTheme.h"
#import "DisclosureQuartzView.h"
#import "OpenLegislativeAPIs.h"
#import "TexLegeStandardGroupCell.h"
#import "SLToastManager+TexLege.h"

@interface BillsFavoritesViewController ()
- (void)configureCell:(TexLegeStandardGroupCell *)cell atIndexPath:(NSIndexPath *)indexPath;
- (IBAction)save:(id)sender;
@property (nonatomic,copy) NSArray *watchList;
@property (nonatomic,copy) NSDictionary *cachedBills;
@end

@implementation BillsFavoritesViewController


#pragma mark -
#pragma mark View lifecycle
- (instancetype)initWithStyle:(UITableViewStyle)style
{
	if ((self=[super initWithStyle:style])) {
		_cachedBills = [[NSDictionary alloc] init];
	}
	return self;	
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return YES;
}

- (void)didReceiveMemoryWarning {	
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}


- (void)dealloc {	
	[[RKClient sharedClient].requestQueue cancelRequestsWithDelegate:self];
    
}

- (void)viewDidLoad {
	[super viewDidLoad];
		
    [self.tableView registerClass:[TXLClickableSubtitleCell class] forCellReuseIdentifier:[TXLClickableSubtitleCell cellIdentifier]];
    
	NSString *myClass = NSStringFromClass([self class]);
	NSArray *menuArray = [UtilityMethods texLegeStringWithKeyPath:@"BillMenuItems"];
	NSDictionary *menuItem = [menuArray findWhereKeyPath:@"class" equals:myClass];
	
	if (menuItem)
		self.title = menuItem[@"title"];
	[self.navigationItem setRightBarButtonItem:self.editButtonItem animated:YES];
	
	self.tableView.separatorColor = [TexLegeTheme separator];
	self.tableView.backgroundColor = [TexLegeTheme tableBackground];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
	self.navigationController.navigationBar.tintColor = [TexLegeTheme navbar];
	
	NSString *thePath = [[UtilityMethods applicationDocumentsDirectory] stringByAppendingPathComponent:kBillFavoritesStorageFile];
	NSFileManager *fileManager = [NSFileManager defaultManager];
	if (![fileManager fileExistsAtPath:thePath]) {
		NSArray *tempArray = [[NSArray alloc] init];
		[tempArray writeToFile:thePath atomically:YES];
	}
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	self.navigationController.navigationBar.tintColor = [TexLegeTheme navbar];

    self.watchList = nil;

	NSString *thePath = [[UtilityMethods applicationDocumentsDirectory] stringByAppendingPathComponent:kBillFavoritesStorageFile];
	NSArray *watchlist = [[NSArray alloc] initWithContentsOfFile:thePath];
	if (!watchlist)
		watchlist = @[];
	
	NSSortDescriptor *sortByOrder = [[NSSortDescriptor alloc] initWithKey:@"displayOrder" ascending:YES];
    watchlist = [watchlist sortedArrayUsingDescriptors:@[sortByOrder]];
    self.watchList = watchlist;
    
	if (!watchlist.count)
    {
        NSString *title = NSLocalizedStringFromTable(@"No Watched Bills, Yet", @"AppAlerts", nil);
        NSString *message = NSLocalizedStringFromTable(@"To add a bill to this watch list, first search for one, open it, and then tap the star button in it's header.", @"AppAlerts", nil);
        
        [[SLToastManager txlSharedManager] addToastWithIdentifier:@"TXLBillsNoneWatched"
                                                             type:SLToastTypeInfo
                                                            title:title
                                                         subtitle:message
                                                            image:nil
                                                         duration:1.5];
	}
	[self.tableView reloadData];
}

- (IBAction)loadBills:(id)sender
{
#if 0
    OpenLegislativeAPIs *openStates = [OpenLegislativeAPIs sharedOpenLegislativeAPIs];
	for (NSDictionary *bill in self.watchList)
    {
        if (!SLTypeDictionaryOrNil(bill))
            continue;
        NSString *billID = SLTypeStringOrNil(bill[@"bill_id"]);
        NSString *session = SLTypeStringOrNil(bill[@"session"]);
        if (!billID || !session)
            continue;
		[openStates queryOpenStatesBillWithID:billID session:session delegate:self];
	}
#endif
}

- (IBAction)save:(id)sender
{
    NSArray<NSDictionary *> *watchList = self.watchList;
	if (!watchList.count)
        return;
    NSString *thePath = [[UtilityMethods applicationDocumentsDirectory] stringByAppendingPathComponent:kBillFavoritesStorageFile];
    [watchList writeToFile:thePath atomically:YES];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [SLTypeNonEmptyArrayOrNil(self.watchList) count];
}

- (void)configureCell:(TexLegeStandardGroupCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
	BOOL useDark = (indexPath.row % 2 == 0);
	cell.backgroundColor = useDark ? [TexLegeTheme backgroundDark] : [TexLegeTheme backgroundLight];
	
    NSDictionary *bill = nil;
    if (_watchList.count > indexPath.row)
        bill = SLTypeDictionaryOrNil(_watchList[indexPath.row]);
    
	NSString *title = SLTypeStringOrNil(bill[@"title"]);
	title = [title chopPrefix:@"Relating to " capitalizingFirst:YES];

	cell.textLabel.text = SLTypeStringOrNil(bill[@"bill_id"]);
	cell.detailTextLabel.text = title;
}

- (void)tableView:(UITableView *)aTableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
	BOOL useDark = (indexPath.row % 2 == 0);
	cell.backgroundColor = useDark ? [TexLegeTheme backgroundDark] : [TexLegeTheme backgroundLight];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSString *reuseId = [TXLClickableSubtitleCell cellIdentifier];

    TexLegeStandardGroupCell *cell = (TexLegeStandardGroupCell *)[tableView dequeueReusableCellWithIdentifier:reuseId];
	if (cell == nil)
	{
		cell = [[TXLClickableSubtitleCell alloc] initWithStyle:UITableViewCellStyleSubtitle
									   reuseIdentifier:reuseId];
    }
	
	if (self.watchList.count)
		[self configureCell:cell atIndexPath:indexPath];		
	
	return cell;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray<NSDictionary *> *watchList = self.watchList;
    NSDictionary *bill = nil;
    if (watchList.count > indexPath.row)
        bill = SLTypeDictionaryOrNil(watchList[indexPath.row]);
    if (!bill)
        return;
    
	if (editingStyle == UITableViewCellEditingStyleDelete)
	{
        NSDictionary<NSString *,NSDictionary *> *cachedBills = self.cachedBills;
        NSString *watchID = SLTypeStringOrNil(bill[@"watchID"]);
		if (cachedBills && watchID)
        {
            NSMutableDictionary<NSString *,NSDictionary *> *mutableCachedBills = [cachedBills mutableCopy];
            [mutableCachedBills removeObjectForKey:watchID];
            self.cachedBills = [mutableCachedBills copy];
        }
        
        NSMutableArray<NSDictionary *> *mutableWatchList = [watchList mutableCopy];
		[mutableWatchList removeObjectAtIndex:indexPath.row];
        watchList = [mutableWatchList copy];
        self.watchList = watchList;
        
		[self save:nil];		
		[self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:YES];
	}   
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
	return YES;
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath 
      toIndexPath:(NSIndexPath *)destinationIndexPath;
{
    NSArray<NSDictionary *> *watchList = self.watchList;
	if (!watchList || watchList.count <= sourceIndexPath.row)
		return;
	NSDictionary *billToMove = SLTypeDictionaryOrNil(watchList[sourceIndexPath.row]);
    if (!billToMove)
        return;
    NSMutableArray<NSDictionary *> *mutableList = [watchList mutableCopy];
	[mutableList removeObjectAtIndex:sourceIndexPath.row];
	[mutableList insertObject:billToMove atIndex:destinationIndexPath.row];
    watchList = [mutableList copy];
    
    mutableList = [@[] mutableCopy];
    [watchList enumerateObjectsUsingBlock:^(NSDictionary * bill, NSUInteger idx, BOOL * stop) {
        if (!SLTypeDictionaryOrNil(bill))
            return;
        NSMutableDictionary *mutableBill = [bill mutableCopy];
        mutableBill[@"displayOrder"] = @(idx);
        [mutableList addObject:[mutableBill copy]];
    }];
    watchList = [mutableList copy];
    self.watchList = watchList;
	[self save:nil];
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	
    NSArray<NSDictionary *> *watchList = self.watchList;
	if (!watchList || watchList.count <= indexPath.row)
		return;

	NSDictionary *bill = watchList[indexPath.row];
    //NSString *watchID = item[@"watchID"];
    //if (!watchID)
    //    return;
    //NSDictionary *bill = _cachedBills[watchID];

    UINavigationController *detailNav = [TexLegeAppDelegate appDelegate].detailNavigationController;

    BOOL changingViews = NO;

    BillsDetailViewController *detailController = nil;
    if ([UtilityMethods isIPadDevice])
    {
        detailController = SLValueIfClass(BillsDetailViewController, detailNav.visibleViewController);
    }
    if (!detailController) {
        detailController = [[BillsDetailViewController alloc]
                      initWithNibName:@"BillsDetailViewController" bundle:nil];
        changingViews = YES;
    }
    [[OpenLegislativeAPIs sharedOpenLegislativeAPIs] queryOpenStatesBillWithID:SLTypeStringOrNil(bill[@"bill_id"])
                                                                       session:SLTypeStringOrNil(bill[@"session"])
                                                                      delegate:detailController];

    detailController.dataObject = bill;
    if (![UtilityMethods isIPadDevice])
        [self.navigationController pushViewController:detailController animated:YES];
    else if (changingViews)
        [detailNav setViewControllers:@[detailController] animated:NO];
}

- (void)request:(RKRequest*)request didFailLoadWithError:(NSError*)error
{
	if (error && request)
    {
		debug_NSLog(@"BillFavorites - Error loading bill results from %@: %@", [request description], [error localizedDescription]);
	}
}


- (void)request:(RKRequest*)request didLoadResponse:(RKResponse*)response
{
	if (![request isGET] || ![response isOK])
        return;

    NSError *error = nil;
    NSDictionary *bill = [NSJSONSerialization JSONObjectWithData:response.body options:0 error:&error];
    if (!SLTypeDictionaryOrNil(bill))
        return;
    NSMutableDictionary<NSString *,NSDictionary *> *cachedBills = [NSMutableDictionary dictionaryWithDictionary:self.cachedBills];

    NSString *watchIDtoFind = watchIDForBill(bill);
    if (!watchIDtoFind)
        return;
    cachedBills[watchIDtoFind] = bill;
    self.cachedBills = [cachedBills copy];

    __block NSInteger row = NSNotFound;
    [self.watchList enumerateObjectsUsingBlock:^(NSDictionary *watchedBill, NSUInteger idx, BOOL * stop) {
        if (!SLTypeDictionaryOrNil(watchedBill))
            return;
        NSString *itemID = SLTypeStringOrNil(watchedBill[@"watchID"]);
        if ([watchIDtoFind isEqualToString:itemID])
        {
            row = idx;
            *stop = YES;
        }
    }];
    
    if (!self.isViewLoaded)
        return;
    
    if (self.watchList.count > row && row != NSNotFound)
    {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:0];
        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
    }
    else
        [self.tableView reloadData];
}

@end
