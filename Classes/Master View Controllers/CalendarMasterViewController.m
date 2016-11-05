    //
//  CalendarMasterViewController.m
//  Created by Gregory Combs on 8/13/10.
//
//  StatesLege by Sunlight Foundation, based on work at https://github.com/sunlightlabs/StatesLege
//
//  This work is licensed under the Creative Commons Attribution-NonCommercial 3.0 Unported License. 
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc/3.0/
//  or send a letter to Creative Commons, 444 Castro Street, Suite 900, Mountain View, California, 94041, USA.
//
//

#import "CalendarMasterViewController.h"
#import "UtilityMethods.h"

#import "TexLegeAppDelegate.h"
#import "TableDataSourceProtocol.h"

#import "CalendarDataSource.h"
#import "CalendarDetailViewController.h"

#import "TexLegeTheme.h"
#import "TexLegeEmailComposer.h"

@implementation CalendarMasterViewController

// Set this to non-nil whenever you want to automatically enable/disable the view controller based on network/host reachability
- (NSString *)reachabilityStatusKey {
	return @"openstatesConnectionStatus";
}

- (void)loadView {
	[super runLoadView];
}

- (Class)dataSourceClass {
	return [CalendarDataSource class];
}

- (void)viewDidLoad {
	[super viewDidLoad];
	if (!self.initialObjectToSelect && [UtilityMethods isIPadDevice])
		self.initialObjectToSelect = [self firstDataObject];
}

- (void)viewDidUnload {
	[super viewDidUnload];
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    // Relinquish ownership any cached data, images, etc that aren't in use.
}

- (void)viewWillAppear:(BOOL)animated
{	
	[super viewWillAppear:animated];
		
	if ([UtilityMethods isIPadDevice] && self.initialObjectToSelect == nil) {
		id detailObject = self.detailViewController ? [self.detailViewController valueForKey:@"chamberCalendar"] : nil;
		
		if (!detailObject) {
			NSIndexPath *currentIndexPath = (self.tableView).indexPathForSelectedRow;
			if (!currentIndexPath) {			
				NSUInteger ints[2] = {0,0};	// just pick the first one then
				currentIndexPath = [NSIndexPath indexPathWithIndexes:ints length:2];
			}
			detailObject = [self.dataSource dataObjectForIndexPath:currentIndexPath];			
		}
		self.initialObjectToSelect = detailObject;
	}	
	if ([UtilityMethods isIPadDevice]) {
		if (self.navigationController)
			self.navigationController.navigationBar.tintColor = [TexLegeTheme navbar];
		[self.tableView reloadData]; // this "fixes" an issue where it's using cached (bogus) values for our vote index sliders
	}
}

#pragma -
#pragma UITableViewDelegate

// the user selected a row in the table.
- (void)tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)newIndexPath withAnimation:(BOOL)animated {
	TexLegeAppDelegate *appDelegate = [TexLegeAppDelegate appDelegate];
	
	if (![UtilityMethods isIPadDevice])
		[aTableView deselectRowAtIndexPath:newIndexPath animated:YES];
		
	id dataObject = [self.dataSource dataObjectForIndexPath:newIndexPath];
	// save off this item's selection to our AppDelegate

	[appDelegate setSavedTableSelection:newIndexPath forKey:NSStringFromClass([self class])];
	
	if (!self.detailViewController) {
		CalendarDetailViewController *temp = [[CalendarDetailViewController alloc] initWithNibName:[CalendarDetailViewController nibName] 
																							bundle:nil];
        temp.edgesForExtendedLayout = UIRectEdgeBottom;
//        temp.extendedLayoutIncludesOpaqueBars = YES;
		self.detailViewController = temp;
	}
	
	if (!dataObject || ![dataObject isKindOfClass:[ChamberCalendarObj class]])
		return;
	
	ChamberCalendarObj *calendar = dataObject;
	
	if ([self.detailViewController respondsToSelector:@selector(setChamberCalendar:)])
		[self.detailViewController setValue:calendar forKey:@"chamberCalendar"];
	
	if (![UtilityMethods isIPadDevice]) {
		// push the detail view controller onto the navigation stack to display it
		((UIViewController *)self.detailViewController).hidesBottomBarWhenPushed = YES;
		
		[self.navigationController pushViewController:self.detailViewController animated:YES];
		self.detailViewController = nil;
	}		
}

// the *user* selected a row in the table, so turn on animations and save their selection.
- (void)tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)newIndexPath {
	
	[super tableView:aTableView didSelectRowAtIndexPath:newIndexPath];
	
	// if we have a stack of view controllers and someone selected a new cell from our master list, 
	//	lets go all the way back to accomodate their selection, and scroll to the top.
	if ([UtilityMethods isIPadDevice]) {
		if ([self.detailViewController respondsToSelector:@selector(tableView)]) {
			UITableView *detailTable = [self.detailViewController performSelector:@selector(tableView)];
			[detailTable reloadData];		// don't we already do this in our own combo detail controller?
		}
	}
}

@end
