//
//  BillsListViewController.m
//  Created by Gregory Combs on 3/14/11.
//
//  StatesLege by Sunlight Foundation, based on work at https://github.com/sunlightlabs/StatesLege
//
//  This work is licensed under the Creative Commons Attribution-NonCommercial 3.0 Unported License. 
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc/3.0/
//  or send a letter to Creative Commons, 444 Castro Street, Suite 900, Mountain View, California, 94041, USA.
//
//

#import "BillsListViewController.h"
#import "TexLegeAppDelegate.h"
#import "BillsDetailViewController.h"
#import "UtilityMethods.h"
#import "TexLegeTheme.h"
#import "DisclosureQuartzView.h"
#import "BillSearchDataSource.h"
#import "OpenLegislativeAPIs.h"
#import "TexLegeStandardGroupCell.h"
#import <SLToastKit/SLTypeCheck.h>

@interface BillsListViewController (Private)
- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath;
@end

@implementation BillsListViewController

- (instancetype)initWithStyle:(UITableViewStyle)style
{
	if ((self = [super initWithStyle:style]))
    {
		self.dataSource = [[BillSearchDataSource alloc] initWithTableViewController:self];
		
		// This will tell the data source to produce a "loading" cell for the table whenever it's searching.
		self.dataSource.useLoadingDataCell = YES;
		
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(reloadData:) name:kBillSearchNotifyDataError object:self.dataSource];
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(reloadData:) name:kBillSearchNotifyDataLoaded object:self.dataSource];
	}
	return self;
}

- (BOOL)shouldAutorotate
{
    return YES;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
	if ([UtilityMethods isIPadDevice] && UIInterfaceOrientationIsLandscape(toInterfaceOrientation))
    {
		if ([[TexLegeAppDelegate appDelegate].masterNavigationController.topViewController isKindOfClass:[BillsListViewController class]])
			if ([self.navigationController isEqual:[TexLegeAppDelegate appDelegate].detailNavigationController])
				[self.navigationController popToRootViewControllerAnimated:YES];
	}	
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	
    [self.tableView registerClass:[TXLClickableSubtitleCell class] forCellReuseIdentifier:[TXLClickableSubtitleCell cellIdentifier]];
	self.tableView.delegate = self;
	self.tableView.dataSource = self.dataSource;
	self.tableView.separatorColor = [TexLegeTheme separator];
	self.tableView.backgroundColor = [TexLegeTheme tableBackground];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
	self.navigationController.navigationBar.tintColor = [TexLegeTheme navbar];	
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	self.navigationController.navigationBar.tintColor = [TexLegeTheme navbar];
}

- (void)reloadData:(NSNotification *)notification
{
	[self.tableView reloadData];
}

- (void)tableView:(UITableView *)aTableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
	BOOL useDark = (indexPath.row % 2 == 0);
	cell.backgroundColor = useDark ? [TexLegeTheme backgroundDark] : [TexLegeTheme backgroundLight];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (![UtilityMethods isIPadDevice])
		[tableView deselectRowAtIndexPath:indexPath animated:YES];
	
	NSDictionary *bill = [self.dataSource dataObjectForIndexPath:indexPath];
	if (!SLTypeDictionaryOrNil(bill))
        return;
    NSString *billID = SLTypeStringOrNil(bill[@"bill_id"]);
    if (!billID)
        return;

    BOOL changingViews = NO;
    BOOL needsPushVC = (NO == [UtilityMethods isIPadDevice]);
    UINavigationController *detailNav = [[TexLegeAppDelegate appDelegate] detailNavigationController];

    BillsDetailViewController *detailView = nil;
    if ([UtilityMethods isIPadDevice])
    {
        id aDetail = detailNav.visibleViewController;
        if ([aDetail isKindOfClass:[BillsDetailViewController class]])
            detailView = aDetail;
        else if ([aDetail isKindOfClass:[BillsListViewController class]])
            needsPushVC = YES;
    }

    if (!detailView)
    {
        detailView = [[BillsDetailViewController alloc] initWithNibName:@"BillsDetailViewController" bundle:nil];
        changingViews = YES;
    }

    detailView.dataObject = bill;
    [[OpenLegislativeAPIs sharedOpenLegislativeAPIs] queryOpenStatesBillWithID:billID
                                                                       session:SLTypeStringOrNil(bill[@"session"])
                                                                      delegate:detailView];
    if (needsPushVC)
        [self.navigationController pushViewController:detailView animated:YES];
    else if (changingViews && detailView)
        //[detailNav pushViewController:detailView animated:YES];
        [detailNav setViewControllers:@[detailView] animated:NO];
}

@end
