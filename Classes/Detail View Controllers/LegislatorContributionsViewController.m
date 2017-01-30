//
//  LegislatorContributionsViewController.m
//  Created by Gregory Combs on 9/15/10.
//
//  StatesLege by Sunlight Foundation, based on work at https://github.com/sunlightlabs/StatesLege
//
//  This work is licensed under the Creative Commons Attribution-NonCommercial 3.0 Unported License. 
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc/3.0/
//  or send a letter to Creative Commons, 444 Castro Street, Suite 900, Mountain View, California, 94041, USA.
//
//

#import "LegislatorContributionsViewController.h"
#import "LegislatorContributionsDataSource.h"
#import "TableCellDataObject.h"
#import "UtilityMethods.h"
#import "LocalyticsSession.h"
#import "TexLegeTheme.h"

@interface LegislatorContributionsViewController ()
@end

@implementation LegislatorContributionsViewController

- (instancetype)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self)
    {
		if (!_dataSource)
			_dataSource = [[LegislatorContributionsDataSource alloc] init];
    }
    return self;
}


- (IBAction)contributionDataChanged:(id)sender
{
	[self.tableView reloadData];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    LegislatorContributionsDataSource *dataSource = self.dataSource;
	if (!dataSource)
    {
		dataSource = [[LegislatorContributionsDataSource alloc] init];
        self.dataSource = dataSource;
    }
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(contributionDataChanged:) name:kContributionsDataNotifyLoaded object:dataSource];
	self.tableView.dataSource = dataSource;
	
	UILabel *nimsp = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 320, 66)];
	nimsp.backgroundColor = [UIColor clearColor];
	nimsp.font = [TexLegeTheme boldFourteen];
	nimsp.shadowColor = [UIColor colorWithWhite:1.0 alpha:0.5];
	nimsp.textAlignment = NSTextAlignmentCenter;
	nimsp.textColor = [TexLegeTheme navbar];
	nimsp.lineBreakMode = NSLineBreakByWordWrapping;
	nimsp.numberOfLines = 3;
	nimsp.text = NSLocalizedStringFromTable(@"Data generously provided by the National Institute on Money in State Politics.", @"DataTableUI", @"Attribution for NIMSP");
	self.tableView.tableFooterView = nimsp;
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (self.splitViewController.displayMode == UISplitViewControllerDisplayModePrimaryHidden)
    {
        UIBarButtonItem *button = self.splitViewController.displayModeButtonItem;
        [self.navigationItem setRightBarButtonItem:button animated:animated];
    }
}

- (void)splitViewController:(UISplitViewController *)svc willChangeToDisplayMode:(UISplitViewControllerDisplayMode)displayMode
{
    if (svc.displayMode == UISplitViewControllerDisplayModePrimaryHidden)
    {
        UIBarButtonItem *button = svc.displayModeButtonItem;
        [self.navigationItem setRightBarButtonItem:button animated:YES];
    }
}

- (BOOL)shouldAutorotate
{
    return YES;
}

- (void)setQueryEntityID:(NSString *)newObj type:(NSNumber *)newType cycle:(NSString *)newCycle
{
    [self setQueryEntityID:newObj type:newType cycle:newCycle parameter:nil];
}

- (void)setQueryEntityID:(NSString *)newObj type:(NSNumber *)newType cycle:(NSString *)cycleOrNil parameter:(NSString *)parameterOrNil
{
    NSString *typeString = @"";
	switch (newType.integerValue) {
		case kContributionQueryDonor:
			typeString = @"DonorSummaryQuery";
			break;
		case kContributionQueryElectionYear:
			typeString = @"RecipientSummaryQuery";
			break;
		case kContributionQueryTopDonations:
			typeString = @"Top10DonorsQuery";
			break;
		case kContributionQueryTop10Recipients:
			typeString = @"Top10RecipientsQuery";
			break;
		case kContributionQueryEntitySearch:
			typeString = @"EntitySearchQuery";
			break;
		default:
			break;
	}
	NSDictionary *logDict = [[NSDictionary alloc] initWithObjectsAndKeys:typeString, @"queryType", nil];
	[[LocalyticsSession sharedLocalyticsSession] tagEvent:@"CONTRIBUTIONS_QUERY" attributes:logDict];

	[self.dataSource initiateQueryWithQueryID:newObj type:newType cycle:cycleOrNil parameter:parameterOrNil];
	self.navigationItem.title = [self.dataSource title];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	TableCellDataObject *dataObject = [self.dataSource dataObjectForIndexPath:indexPath];
	
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	
	if (dataObject && dataObject.isClickable)
    {
        NSString *parameter = dataObject.parameter;
        if ([parameter isKindOfClass:[NSString class]] && [parameter length])
        {

        }
        else
            parameter = nil;

        NSString *entryValue = dataObject.entryValue;
        if ([entryValue isKindOfClass:[NSString class]] && [entryValue length])
        {

        }
        else
            entryValue = nil;
        
        BOOL isValid = (parameter || entryValue);

        if (!isValid)
        {
			NSString *queryName = @"";
			if (dataObject.title)
				queryName = dataObject.title;
			
			NSDictionary *logDict = [[NSDictionary alloc] initWithObjectsAndKeys:queryName, @"queryName", nil];
			[[LocalyticsSession sharedLocalyticsSession] tagEvent:@"CONTRIBUTION_QUERY_ERROR" attributes:logDict];
			
			UIAlertView *dataAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedStringFromTable(@"Incomplete Records", @"AppAlerts", @"Title for alert indicating insufficient record data for the requested campaign contributor.")
																 message:NSLocalizedStringFromTable(@"The campaign finance data provider has incomplete information for this request.  You may visit followthemoney.org to perform a manual search.", @"AppAlerts", @"")
																delegate:self 
													   cancelButtonTitle:NSLocalizedStringFromTable(@"Cancel", @"StandardUI", @"Button title cancelling some action")
													   otherButtonTitles:NSLocalizedStringFromTable(@"Open Website", @"StandardUI", @"Button title"), nil];
			[dataAlert show];
			
			return;
		}

		LegislatorContributionsViewController *detail = [[LegislatorContributionsViewController alloc] initWithStyle:UITableViewStyleGrouped];

        [detail setQueryEntityID:dataObject.entryValue type:dataObject.action cycle:nil parameter:dataObject.parameter];
		[self.navigationController pushViewController:detail animated:YES];
	}
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
	if (buttonIndex == alertView.firstOtherButtonIndex) {
		NSURL *url = [NSURL URLWithString:[UtilityMethods texLegeStringWithKeyPath:@"ExternalURLs.nimspWeb"]];
		[UtilityMethods openURLWithTrepidation:url];
	}
}


@end

