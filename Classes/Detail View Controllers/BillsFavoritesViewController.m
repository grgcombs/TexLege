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

@interface BillsFavoritesViewController (Private)
- (void)configureCell:(TexLegeStandardGroupCell *)cell atIndexPath:(NSIndexPath *)indexPath;
- (IBAction)save:(id)sender;
@end

@implementation BillsFavoritesViewController


#pragma mark -
#pragma mark View lifecycle
- (instancetype)initWithStyle:(UITableViewStyle)style {
	if ((self=[super initWithStyle:style])) {
		_cachedBills = [[NSMutableDictionary alloc] init];
	}
	return self;	
}

/*
- (void)didReceiveMemoryWarning {
	[_cachedBills release];
	_cachedBills = nil;	
}*/

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return YES;
}

- (void)didReceiveMemoryWarning {	
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}


- (void)dealloc {	
	[[RKRequestQueue sharedQueue] cancelRequestsWithDelegate:self];
	nice_release(_watchList);
	nice_release(_cachedBills);
	
	[super dealloc];
}

- (void)viewDidLoad {
	[super viewDidLoad];
		
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
		[tempArray release];
	}
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	self.navigationController.navigationBar.tintColor = [TexLegeTheme navbar];

	nice_release(_watchList);

	NSString *thePath = [[UtilityMethods applicationDocumentsDirectory] stringByAppendingPathComponent:kBillFavoritesStorageFile];
	_watchList = [[NSMutableArray alloc] initWithContentsOfFile:thePath];
	if (!_watchList) {
		_watchList = [[NSMutableArray alloc] init];
	}
	
	NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"displayOrder" ascending:YES];
	[_watchList sortUsingDescriptors:@[sortDescriptor]];
	[sortDescriptor release];	
	
	if (!_watchList.count) {
		UIAlertView *noWatchedBills = [[ UIAlertView alloc ] 
										 initWithTitle:NSLocalizedStringFromTable(@"No Watched Bills, Yet", @"AppAlerts", @"Alert box title")
										 message:NSLocalizedStringFromTable(@"To add a bill to this watch list, first search for one, open it, and then tap the star button in it's header.", @"AppAlerts", @"") 
										 delegate:nil // we're static, so don't do "self"
										 cancelButtonTitle:NSLocalizedStringFromTable(@"Cancel", @"StandardUI", @"Button to cancel something") 
										 otherButtonTitles:nil];
		[ noWatchedBills show ];	
		[ noWatchedBills release ];
		
	}
	[self.tableView reloadData];
	
}

/*- (void)viewWillDisappear:(BOOL)animated {
//	[self save:nil];
	[super viewWillDisappear:animated];
}*/

- (IBAction)loadBills:(id)sender {
	/*
	for (NSDictionary *item in _watchList) {
		[[OpenLegislativeAPIs sharedOpenLegislativeAPIs] queryOpenStatesBillWithID:[item objectForKey:@"bill_id"] 
																		   session:[item objectForKey:@"session"] 
																		  delegate:self];
	}*/	
}

- (IBAction)save:(id)sender {
	if (_watchList) {
		NSString *thePath = [[UtilityMethods applicationDocumentsDirectory] stringByAppendingPathComponent:kBillFavoritesStorageFile];
		[_watchList writeToFile:thePath atomically:YES];		
	}
}

- (void)viewDidUnload {
	[super viewDidUnload];
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	if (!IsEmpty(_watchList))
		return _watchList.count;
	else
		return 0;
}

- (void)configureCell:(TexLegeStandardGroupCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
	BOOL useDark = (indexPath.row % 2 == 0);
	cell.backgroundColor = useDark ? [TexLegeTheme backgroundDark] : [TexLegeTheme backgroundLight];
	
	NSString *bill_title = _watchList[indexPath.row][@"title"];
	bill_title = [bill_title chopPrefix:@"Relating to " capitalizingFirst:YES];

	cell.textLabel.text = _watchList[indexPath.row][@"bill_id"];
	cell.detailTextLabel.text = bill_title;		
}

- (void)tableView:(UITableView *)aTableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
	BOOL useDark = (indexPath.row % 2 == 0);
	cell.backgroundColor = useDark ? [TexLegeTheme backgroundDark] : [TexLegeTheme backgroundLight];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSString *CellIdentifier = @"CellOff";
/*	if (_watchList && [_watchList count] > indexPath.row) {
		NSString *watchID = [[_watchList objectAtIndex:indexPath.row] objectForKey:@"watchID"];
		if (_cachedBills && [[_cachedBills allKeys] containsObject:watchID])
			CellIdentifier = @"CellOn";
	}
*/	
	TexLegeStandardGroupCell *cell = (TexLegeStandardGroupCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (cell == nil)
	{
		cell = [[[TexLegeStandardGroupCell alloc] initWithStyle:UITableViewCellStyleSubtitle 
									   reuseIdentifier:CellIdentifier] autorelease];
		
		cell.textLabel.textColor = [TexLegeTheme textDark];
		cell.textLabel.font = [TexLegeTheme boldFifteen];
		cell.detailTextLabel.textColor = [TexLegeTheme indexText];
		
//		if ([CellIdentifier isEqualToString:@"CellOff"])
//			cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
	
	if (_watchList && _watchList.count)
		[self configureCell:cell atIndexPath:indexPath];		
	
	return cell;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (editingStyle == UITableViewCellEditingStyleDelete)
	{
		NSDictionary *toRemove = _watchList[indexPath.row];
		if (toRemove && _cachedBills) {
			NSString *watchID = toRemove[@"watchID"];
			if (watchID && [_cachedBills.allKeys containsObject:watchID])
				[_cachedBills removeObjectForKey:watchID];
		}
		[_watchList removeObjectAtIndex:indexPath.row];
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
	if (!_watchList)
		return;
	
	NSDictionary *item = [_watchList[sourceIndexPath.row] retain];	
	[_watchList removeObject:item];
	[_watchList insertObject:item atIndex:destinationIndexPath.row];	
	[item release];
	
	int i = 0;
	for (NSMutableDictionary *anItem in _watchList)
		[anItem setValue:@(i++) forKey:@"displayOrder"];
	
	[self save:nil];
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	
	if (!_watchList)
		return;
	
	NSDictionary *item = _watchList[indexPath.row];
	if (item && item[@"watchID"]) {		
		
		//NSMutableDictionary *bill = [_cachedBills objectForKey:[item objectForKey:@"watchID"]];
		BOOL changingViews = NO;
		
		BillsDetailViewController *detailView = nil;
		if ([UtilityMethods isIPadDevice]) {
			id aDetail = [TexLegeAppDelegate appDelegate].detailNavigationController.visibleViewController;
			if ([aDetail isKindOfClass:[BillsDetailViewController class]])
				detailView = aDetail;
		}
		if (!detailView) {
			detailView = [[[BillsDetailViewController alloc] 
												  initWithNibName:@"BillsDetailViewController" bundle:nil] autorelease];
			changingViews = YES;
		}
		[[OpenLegislativeAPIs sharedOpenLegislativeAPIs] queryOpenStatesBillWithID:item[@"bill_id"] 
																		   session:item[@"session"] 
																		  delegate:detailView];
		
		detailView.dataObject = item;
		if (![UtilityMethods isIPadDevice])
			[self.navigationController pushViewController:detailView animated:YES];
		else if (changingViews)
			[[TexLegeAppDelegate appDelegate].detailNavigationController setViewControllers:@[detailView] animated:NO];
		
	}			
}

#pragma mark -
#pragma mark RestKit:RKObjectLoaderDelegate

- (void)request:(RKRequest*)request didFailLoadWithError:(NSError*)error {
	if (error && request) {
		debug_NSLog(@"BillFavorites - Error loading bill results from %@: %@", [request description], [error localizedDescription]);
	}
}


- (void)request:(RKRequest*)request didLoadResponse:(RKResponse*)response {  
	if ([request isGET] && [response isOK]) {  
		// Success! Let's take a look at the data  

        NSError *error = nil;
        NSMutableDictionary *object = [NSJSONSerialization JSONObjectWithData:response.body options:NSJSONReadingMutableLeaves | NSJSONReadingMutableContainers error:&error];

		if (object && _cachedBills) {
			NSString *watchID = watchIDForBill(object);
			_cachedBills[watchID] = object;
			
			NSInteger row = 0;
			NSInteger index = 0;
			for (NSDictionary *search in _watchList) {
				if ([search[@"watchID"] isEqualToString:watchID]) {
					row = index;
					break;
				}
				index++;
			}
			NSIndexPath *rowPath = [NSIndexPath indexPathForRow:row inSection:0];
			//[self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:rowPath] withRowAnimation:UITableViewRowAnimationMiddle];
			if (row+1 > _watchList.count)
				[self.tableView reloadData];
			else
				[self.tableView reloadRowsAtIndexPaths:@[rowPath] withRowAnimation:UITableViewRowAnimationNone];
		}
	}
}


@end


