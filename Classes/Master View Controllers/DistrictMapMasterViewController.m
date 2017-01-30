//
//  DistrictOfficeMasterViewController.m
//  Created by Gregory Combs on 8/23/10.
//
//  StatesLege by Sunlight Foundation, based on work at https://github.com/sunlightlabs/StatesLege
//
//  This work is licensed under the Creative Commons Attribution-NonCommercial 3.0 Unported License. 
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc/3.0/
//  or send a letter to Creative Commons, 444 Castro Street, Suite 900, Mountain View, California, 94041, USA.
//
//

#import "DistrictMapMasterViewController.h"
#import "DistrictMapDataSource.h"
#import "DistrictMapObj+MapKit.h"
#import "MapViewController.h"
#import "UtilityMethods.h"
#import "TexLegeAppDelegate.h"
#import "TexLegeTheme.h"
#import "DistrictMapObj.h"
#import "TexLegeCoreDataUtils.h"
#import "SLToastManager+TexLege.h"
#import "TexLegeStandardGroupCell.h"

@interface DistrictMapMasterViewController (Private)
- (void)searchBarCancelButtonClicked:(UISearchBar *) searchBar;
@end


@implementation DistrictMapMasterViewController

// Set this to non-nil whenever you want to automatically enable/disable the view controller based on network/host reachability
- (NSString *)reachabilityStatusKey {
	return @"googleConnectionStatus";
}

#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    // Relinquish ownership any cached data, images, etc that aren't in use.
}

#pragma mark -
#pragma mark Initialization

- (NSString *)nibName
{
	return NSStringFromClass([self class]);
}

- (Class)dataSourceClass {
	return [DistrictMapDataSource class];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    UITableView *tableView = self.tableView;
	tableView.rowHeight = 44.0f;
    [tableView registerClass:[TXLClickableSubtitleCell class] forCellReuseIdentifier:[TXLClickableSubtitleCell cellIdentifier]];
	
	if ([UtilityMethods isIPadDevice])
	    self.preferredContentSize = CGSizeMake(320.0, 600.0);

    UISearchDisplayController *searchController = self.searchDisplayController;
	searchController.delegate = self;
	searchController.searchResultsDelegate = self;
    searchController.searchBar.tintColor = [TexLegeTheme accent];
	//self.dataSource.searchDisplayController = self.searchDisplayController;
	//self.searchDisplayController.searchResultsDataSource = self.dataSource;
	
    self.navigationItem.titleView = self.filterControls;
    self.sortControl.tintColor = [TexLegeTheme accent];
    UISegmentedControl *chamberControl = self.chamberControl;
	chamberControl.tintColor = [TexLegeTheme accent];
	
	[chamberControl setTitle:stringForChamber(BOTH_CHAMBERS, TLReturnFull) forSegmentAtIndex:0];
	[chamberControl setTitle:stringForChamber(HOUSE, TLReturnFull) forSegmentAtIndex:1];
	[chamberControl setTitle:stringForChamber(SENATE, TLReturnFull) forSegmentAtIndex:2];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

	NSDictionary *segPrefs = [[NSUserDefaults standardUserDefaults] objectForKey:kSegmentControlPrefKey];
	if (segPrefs)
    {
		NSNumber *segIndex = segPrefs[@"DistrictMapChamberKey"];
		if (segIndex)
			self.chamberControl.selectedSegmentIndex = segIndex.integerValue;
		segIndex = segPrefs[@"DistrictMapSortTypeKey"];
		if (segIndex)
			self.sortControl.selectedSegmentIndex = segIndex.integerValue;
		
	}
    [self reapplyFiltersAndSort];
}

- (void)reapplyFiltersAndSort
{
    if (!self.isViewLoaded)
        return;
    [self filterContentForSearchText:self.searchDisplayController.searchBar.text
                               scope:self.chamberControl.selectedSegmentIndex];

    BOOL byDistrict = (self.sortControl.selectedSegmentIndex == 1);
    ((DistrictMapDataSource *) self.dataSource).byDistrict = byDistrict;
    [(DistrictMapDataSource *) self.dataSource sortByType:self.sortControl];

    [super reapplyFiltersAndSort];
}


#pragma mark -
#pragma mark Table view delegate

//START:code.split.delegate
- (void)tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)newIndexPath withAnimation:(BOOL)animated
{
	TexLegeAppDelegate *appDelegate = [TexLegeAppDelegate appDelegate];
    [aTableView deselectRowAtIndexPath:newIndexPath animated:YES];
		
	DistrictMapObj *map = SLValueIfClass(DistrictMapObj, [self.dataSource dataObjectForIndexPath:newIndexPath]);
    if (!map)
        return;
    
	[appDelegate setSavedTableSelection:nil forKey:NSStringFromClass([self class])];
	
    MapViewController *detailController = SLValueIfClass(MapViewController,self.detailViewController);
	if (!detailController)
    {
		detailController = [[MapViewController alloc] init];
		self.detailViewController = detailController;
	}
    detailController.detailAnnotation = map;
    
    if (aTableView == self.searchDisplayController.searchResultsTableView)
        [self searchBarCancelButtonClicked:nil];
    
    if (![UtilityMethods isIPadDevice])
    {
        // push the detail view controller onto the navigation stack to display it
        [self.navigationController pushViewController:detailController animated:YES];
        self.detailViewController = nil;
    }
    [map.managedObjectContext refreshObject:map mergeChanges:YES];
}

- (void)filterContentForSearchText:(NSString*)searchText scope:(NSInteger)scope
{
    DistrictMapDataSource *dataSource = SLValueIfClass(DistrictMapDataSource, self.dataSource);
    if (!dataSource)
        return;
    dataSource.filterChamber = scope;
	
	if (searchText.length > 0)
        dataSource.filterString = searchText;
	else
        [dataSource removeFilter];
}

- (IBAction) filterChamber:(id)sender
{
    UISegmentedControl *chamberControl = self.chamberControl;
    if (sender != chamberControl)
        return;

    NSDictionary *segPrefs = [[NSUserDefaults standardUserDefaults] objectForKey:kSegmentControlPrefKey];
    if (segPrefs)
    {
        NSNumber *segIndex = @(chamberControl.selectedSegmentIndex);
        NSMutableDictionary *newDict = [segPrefs mutableCopy];
        newDict[@"DistrictMapChamberKey"] = segIndex;
        [[NSUserDefaults standardUserDefaults] setObject:newDict forKey:kSegmentControlPrefKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    [self reapplyFiltersAndSort];
}

- (IBAction)sortType:(id)sender
{
    UISegmentedControl *sortControl = self.sortControl;
	if (sender != sortControl)
        return;

    NSDictionary *segPrefs = [[NSUserDefaults standardUserDefaults] objectForKey:kSegmentControlPrefKey];
    if (segPrefs) {
        NSNumber *segIndex = @(sortControl.selectedSegmentIndex);
        NSMutableDictionary *newDict = [segPrefs mutableCopy];
        newDict[@"DistrictMapSortTypeKey"] = segIndex;
        [[NSUserDefaults standardUserDefaults] setObject:newDict forKey:kSegmentControlPrefKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    [self reapplyFiltersAndSort];
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
    [self filterContentForSearchText:searchString scope:self.chamberControl.selectedSegmentIndex];
    
	// Return YES to cause the search result table view to be reloaded.
    return YES;
}

- (void)searchBarCancelButtonClicked:(UISearchBar *) searchBar
{
    UISearchDisplayController *searchController = self.searchDisplayController;
	searchController.searchBar.text = @"";
	[self.dataSource removeFilter];
	
	[searchController setActive:NO animated:YES];
}

- (void)searchDisplayControllerWillBeginSearch:(UISearchDisplayController *)controller
{
	[self.dataSource setHideTableIndex:YES];	
	// for some reason, these get zeroed out after we restart searching.
    UITableView *searchView = controller.searchResultsTableView;
	searchView.rowHeight = self.tableView.rowHeight;
	searchView.backgroundColor = self.tableView.backgroundColor;
	searchView.sectionIndexMinimumDisplayRowCount = self.tableView.sectionIndexMinimumDisplayRowCount;
	
}

- (void)searchDisplayControllerWillEndSearch:(UISearchDisplayController *)controller {
	[self.dataSource setHideTableIndex:NO];	
}

@end

