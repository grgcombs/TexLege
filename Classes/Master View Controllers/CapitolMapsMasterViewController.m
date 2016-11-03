//
//  CapitolMapsMasterViewController.m
//  Created by Gregory Combs on 8/13/10.
//
//  StatesLege by Sunlight Foundation, based on work at https://github.com/sunlightlabs/StatesLege
//
//  This work is licensed under the Creative Commons Attribution-NonCommercial 3.0 Unported License. 
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc/3.0/
//  or send a letter to Creative Commons, 444 Castro Street, Suite 900, Mountain View, California, 94041, USA.
//
//

#import "CapitolMapsMasterViewController.h"

#import "UtilityMethods.h"

#import "CapitolMapsDataSource.h"

#import "CapitolMapsDetailViewController.h"
#import "TexLegeAppDelegate.h"
#import "TableDataSourceProtocol.h"

#import "TexLegeTheme.h"

@implementation CapitolMapsMasterViewController


- (void)loadView {	
	[super runLoadView];
}

- (void)viewDidLoad {
	[super viewDidLoad];
	if (!self.selectObjectOnAppear && [UtilityMethods isIPadDevice])
		self.selectObjectOnAppear = [self firstDataObject];
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    // Relinquish ownership any cached data, images, etc that aren't in use.
}

- (Class)dataSourceClass {
	return [CapitolMapsDataSource class];
}

- (void)viewWillAppear:(BOOL)animated
{	
	[super viewWillAppear:animated];
	
	//// ALL OF THE FOLLOWING MUST *NOT* RUN ON IPHONE (I.E. WHEN THERE'S NO SPLITVIEWCONTROLLER
	
	if ([UtilityMethods isIPadDevice] && self.selectObjectOnAppear == nil) {
		id detailObject = self.detailViewController ? [self.detailViewController valueForKey:@"map"] : nil;
		
		if (!detailObject) {
			NSIndexPath *currentIndexPath = (self.tableView).indexPathForSelectedRow;
			if (!currentIndexPath) {			
				NSUInteger ints[2] = {0,0};	// just pick the first one then
				currentIndexPath = [NSIndexPath indexPathWithIndexes:ints length:2];
			}
			detailObject = [self.dataSource dataObjectForIndexPath:currentIndexPath];			
		}
		self.selectObjectOnAppear = detailObject;
	}	
	if ([UtilityMethods isIPadDevice])
		[self.tableView reloadData]; // this "fixes" an issue where it's using cached (bogus) values for our vote index sliders
	
	// END: IPAD ONLY
}

#pragma -
#pragma UITableViewDelegate

// the user selected a row in the table.
- (void)tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)newIndexPath withAnimation:(BOOL)animated {
	TexLegeAppDelegate *appDelegate = [TexLegeAppDelegate appDelegate];
	
	if (![UtilityMethods isIPadDevice])
		[aTableView deselectRowAtIndexPath:newIndexPath animated:YES];
	
	BOOL isSplitViewDetail = ([UtilityMethods isIPadDevice]) && (self.splitViewController != nil);
	
	if (!isSplitViewDetail)
		self.navigationController.toolbarHidden = YES;
	
	id dataObject = [self.dataSource dataObjectForIndexPath:newIndexPath];
	// save off this item's selection to our AppDelegate
	[appDelegate setSavedTableSelection:newIndexPath forKey:NSStringFromClass([self class])];
	
	// create a CapitolMapsDetailViewController. This controller will display the full size tile for the element
	if (self.detailViewController == nil) {
		self.detailViewController = [[[CapitolMapsDetailViewController alloc] initWithNibName:@"CapitolMapsDetailViewController" bundle:nil] autorelease];
	}
	
	CapitolMap *capitolMap = dataObject;
	if (capitolMap) {
		((CapitolMapsDetailViewController*) self.detailViewController).map = capitolMap;
		if (isSplitViewDetail == NO) {
			// push the detail view controller onto the navigation stack to display it				
			[self.navigationController pushViewController:self.detailViewController animated:YES];
			self.detailViewController = nil;
		}
	}
}
@end
