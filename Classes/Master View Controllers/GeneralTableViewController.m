//
//  GeneralTableViewController.m
//  Created by Gregory Combs on 7/10/09.
//
//  StatesLege by Sunlight Foundation, based on work at https://github.com/sunlightlabs/StatesLege
//
//  This work is licensed under the Creative Commons Attribution-NonCommercial 3.0 Unported License. 
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc/3.0/
//  or send a letter to Creative Commons, 444 Castro Street, Suite 900, Mountain View, California, 94041, USA.
//
//

#import "UtilityMethods.h"

#import "GeneralTableViewController.h"

#import "TexLegeAppDelegate.h"
#import "TableDataSourceProtocol.h"
#import "BillsMenuDataSource.h"
#import "TexLegeTheme.h"
#import "TexLegeReachability.h"
#import "TXLDetailProtocol.h"
#import <SLFRestKit/NSManagedObject+RestKit.h>

@implementation GeneralTableViewController

- (NSString *)reachabilityStatusKey
{
	return nil;
}

- (instancetype) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
	if ((self=[super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
		_controllerEnabled = @YES;
		
		NSString *statusKey = [self reachabilityStatusKey];
		if (!IsEmpty(statusKey)) {
			[[TexLegeReachability sharedTexLegeReachability] addObserver:self 
															  forKeyPath:statusKey 
																 options:(NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld) 
																 context:nil];			
		}
	}
	return self;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if (!IsEmpty(keyPath)
        && [self reachabilityStatusKey]
        && [keyPath isEqualToString:[self reachabilityStatusKey]])
    {
		BOOL shouldEnable = (self.controllerEnabled).boolValue;
		
		id newVal = [change valueForKey:NSKeyValueChangeNewKey];
		if (newVal && [newVal isKindOfClass:[NSNumber class]])
        {
			shouldEnable = [newVal intValue] > NotReachable;
		}
		self.controllerEnabled = @(shouldEnable);
	}
	/*if (!IsEmpty(keyPath) && [keyPath isEqualToString:@"frame"]) {
		NSLog(@"Class=%@ w=%f h=%f", NSStringFromClass([self class]), self.tableView.frame.size.width, self.tableView.frame.size.height);
	}*/	
}

- (Class)dataSourceClass {
	return [NSObject class];
}

- (id<TableDataSource>)dataSource
{
    if (_dataSource)
        return _dataSource;
    Class class = [self dataSourceClass];
    if (!class)
        return nil;
    _dataSource = [[class alloc] init];
	return _dataSource;
}

- (BOOL)shouldPreselectRowOnAppear
{
    if ([UtilityMethods isIPadDevice]
        && self.detailViewController)
    {
        if (![UtilityMethods isLandscapeOrientation])
            return NO;
    }
    return YES;
}

- (void)configure
{
	[self dataSource];
	
    if (![self shouldPreselectRowOnAppear])
        return;
    
	if ((self.dataSource).usesCoreData) {
		id objectID = [[TexLegeAppDelegate appDelegate] savedTableSelectionForKey:NSStringFromClass([self class])];
		if (objectID && [objectID isKindOfClass:[NSNumber class]]) {
			@try {
				if ([self.dataSource respondsToSelector:@selector(dataClass)])
					self.initialObjectToSelect = [[self.dataSource dataClass] objectWithPrimaryKeyValue:objectID];	
			}
			@catch (NSException * e) {
			}
		}			
	}
	else { // Let's just do this for maps, and meetings, ... we'll handle them like integer row selections
		id object = [[TexLegeAppDelegate appDelegate] savedTableSelectionForKey:NSStringFromClass([self class])];
		if (!object)
			return;
		
		if ([object isKindOfClass:[NSIndexPath class]] && NO == [self.dataSource isKindOfClass:[BillsMenuDataSource class]]) {
			self.initialObjectToSelect = [self.dataSource dataObjectForIndexPath:object];
		}
	}
	
	if (self.initialObjectToSelect && self.detailViewController && [UtilityMethods isIPadDevice]) {
		NSLog(@"Presetting a detail view's dataObject in %@!", self.description);
		if ([self.detailViewController respondsToSelector:@selector(setDataObject:)]) {
			@try {
				[self.detailViewController performSelector:@selector(setDataObject:) withObject:self.initialObjectToSelect];
			}
			@catch (NSException * e) {
				self.initialObjectToSelect = nil;
				//self.initialObjectToSelect = [self.dataSource dataObjectForIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
			}
		}
	}
	
}

- (void)dealloc {
	[[TexLegeReachability sharedTexLegeReachability] removeObserver:self forKeyPath:[self reachabilityStatusKey]];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:@"TABLEUPDATE_START" object:self.dataSource];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:@"TABLEUPDATE_END" object:self.dataSource];

	//self.tableView = nil;
}

- (void)didReceiveMemoryWarning {
			
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
}

- (void)runLoadView {	
	[super loadView];
	
	// create a new table using the full application frame
	// we'll ask the datasource which type of table to use (plain or grouped)
	CGRect tempFrame = [UIScreen mainScreen].applicationFrame;
	
	if (self.navigationController) {
		tempFrame = self.navigationController.view.bounds;
	}
	
	self.tableView = [[UITableView alloc] initWithFrame:tempFrame style:(self.dataSource).tableViewStyle];
	
	// set the cell separator to a single straight line.
	//self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
	//self.tableView.separatorColor = [UIColor lightGrayColor];
		
	self.tableView.sectionIndexMinimumDisplayRowCount=15;
	
	// set the tableview as the controller view
	self.view = self.tableView;
	
}

-(void)viewDidLoad
{
	[super viewDidLoad];
    UITableView *tableView = self.tableView;

	//[self.navigationController.view addObserver:self forKeyPath:@"frame" options:(NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld) context:nil];
	
	tableView.autoresizingMask = (UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight);
	tableView.autoresizesSubviews = YES;

	// set the long name shown in the navigation bar
	//self.navigationItem.title=[dataSource navigationBarName];
	
	// FETCH CORE DATA
    id<TableDataSource> dataSource = self.dataSource;
    self.title = [dataSource name];
	if (dataSource.usesCoreData)
	{
        NSFetchedResultsController *frc = [dataSource fetchedResultsController];

		NSError *error = nil;
		// You've got to delete the cache, or disable caching before you modify the predicate...
        [NSFetchedResultsController deleteCacheWithName:frc.cacheName];

		if (![frc performFetch:&error]) {
			// Handle the error...
		}					
	}
	tableView.dataSource = dataSource;
    UISearchDisplayController *searchController = self.searchDisplayController;
	if (searchController)
    {
		searchController.searchResultsDataSource = dataSource;
		if ([dataSource respondsToSelector:@selector(setSearchDisplayController:)])
			[dataSource performSelector:@selector(setSearchDisplayController:) withObject:searchController];
	}
	
	// set the tableview delegate to this object and the datasource to the datasource which has already been set
	tableView.delegate = self;
	//self.tableView.dataSource = self.dataSource;
	
	self.clearsSelectionOnViewWillAppear = NO;
	tableView.separatorColor = [TexLegeTheme separator];
	tableView.backgroundColor = [TexLegeTheme tableBackground];
    tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
	self.navigationController.navigationBar.tintColor = [TexLegeTheme navbar];
	//self.searchDisplayController.searchBar.tintColor = [TexLegeTheme accent];
	//self.navigationItem.titleView = self.chamberControl;
	
	if ([UtilityMethods isIPadDevice])
    {
		NSUInteger sectionCount = tableView.numberOfSections;
		CGFloat tableHeight = 0;
		NSInteger section = 0;
		for (section=0; section < sectionCount; section++)
        {
			tableHeight += [tableView rectForSection:section].size.height;
		}
		self.preferredContentSize = CGSizeMake(320.0, tableHeight);
	}
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(beginUpdates:) name:@"TABLEUPDATE_START" object:self.dataSource];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(endUpdates:) name:@"TABLEUPDATE_END" object:self.dataSource];
}
	
- (void)viewDidUnload
{
	//NSLog(@"--------------Unloading %@", NSStringFromClass([self class]));
	
	[[NSNotificationCenter defaultCenter] removeObserver:self name:@"TABLEUPDATE_START" object:self.dataSource];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:@"TABLEUPDATE_END" object:self.dataSource];

	//self.dataSource = nil;
	self.initialObjectToSelect = nil;
	[super viewDidUnload];
}

- (IBAction)selectDefaultObject:(id)sender
{
	NSIndexPath *selectFirst = [NSIndexPath indexPathForRow:0 inSection:0];
    UITableView *tableView = self.tableView;
	[tableView selectRowAtIndexPath:selectFirst animated:NO scrollPosition:UITableViewScrollPositionNone];
	[self tableView:tableView didSelectRowAtIndexPath:selectFirst];
}

- (id)firstDataObject
{
	NSIndexPath *currentIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
	id detailObject = [self.dataSource dataObjectForIndexPath:currentIndexPath];			
	return detailObject;
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];

    UITableView *tableView = self.tableView;

	if ([self shouldPreselectRowOnAppear] && self.initialObjectToSelect)  {	
		NSIndexPath *selectedPath = nil;
		
		//if (![self.dataSource.name isEqualToString:@"Resources"])
		@try {
			selectedPath = [self.dataSource indexPathForDataObject:self.initialObjectToSelect];
		}
		@catch (NSException * e) {
		}
		@finally {
			//if (!selectedPath)
			//	selectedPath = [NSIndexPath indexPathForRow:0 inSection:0];
		}
				
		if (selectedPath) {
			[tableView selectRowAtIndexPath:selectedPath animated:animated scrollPosition:UITableViewScrollPositionNone];
			[self tableView:tableView didSelectRowAtIndexPath:selectedPath];
		}
		self.initialObjectToSelect = nil;
	}

	// We're on an iphone, without a splitview or popovers, so if we get here, let's stop traversing our replay breadcrumbs
	if (![UtilityMethods isIPadDevice]) {
		[[TexLegeAppDelegate appDelegate] setSavedTableSelection:nil forKey:NSStringFromClass([self class])];
	}
}

- (void)reapplyFiltersAndSort
{
    if (!self.isViewLoaded || !self.tableView)
        return;
    [self.tableView reloadData];
}

#pragma -
#pragma UITableViewDelegate

- (void)beginUpdates:(NSNotification *)aNotification {
//	[self.tableView beginUpdates];
}

- (void)endUpdates:(NSNotification *)aNotification {
//	[self.tableView endUpdates];
	[self.tableView reloadData];
}

- (void)tableView:(UITableView *)aTableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
	BOOL useDark = (indexPath.row % 2 == 0);
	cell.backgroundColor = useDark ? [TexLegeTheme backgroundDark] : [TexLegeTheme backgroundLight];
}


// the user selected a row in the table.
- (void)tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)newIndexPath withAnimation:(BOOL)animated {
	return ; // just a placeholder for children
}

// the *user* selected a row in the table, so turn on animations and save their selection.
- (void)tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)newIndexPath {
	
	[self tableView:aTableView didSelectRowAtIndexPath:newIndexPath withAnimation:YES];
	
	// if we have a stack of view controllers and someone selected a new cell from our master list, 
	//	lets go all the way back to accomodate their selection.
	if ([UtilityMethods isIPadDevice])
    {
		UINavigationController *detailNav = nil;
        UIViewController *detailController = self.detailViewController;

		if ([detailController respondsToSelector:@selector(navigationController)])
			detailNav = [detailController performSelector:@selector(navigationController)];
		
		if (!self.initialObjectToSelect)
        {	// otherwise we pop whenever we're automatically selecting stuff ... right?
			if (detailNav && detailNav.viewControllers && (detailNav.viewControllers).count > 1) { 
				[detailNav popToRootViewControllerAnimated:YES];
				
				if ([detailController respondsToSelector:@selector(tableView)])
                {
					UITableView *detailTable = [detailController performSelector:@selector(tableView)];
					if (detailTable) {
						CGRect guessTop = CGRectMake(0, 0, 10.0f, 10.0f);
						[detailTable scrollRectToVisible:guessTop animated:YES];
					}
				}
			}
		}
	}
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}


@end
