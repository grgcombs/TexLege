//
//  BillsDetailViewController.m
//  Created by Gregory Combs on 2/20/11.
//
//  StatesLege by Sunlight Foundation, based on work at https://github.com/sunlightlabs/StatesLege
//
//  This work is licensed under the Creative Commons Attribution-NonCommercial 3.0 Unported License. 
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc/3.0/
//  or send a letter to Creative Commons, 444 Castro Street, Suite 900, Mountain View, California, 94041, USA.
//
//

#import "BillsDetailViewController.h"
#import "BillsFavoritesViewController.h"
#import "BillSearchDataSource.h"
#import "BillsListViewController.h"
#import "LegislatorDetailViewController.h"
#import "TableDataSourceProtocol.h"
#import "TexLegeCoreDataUtils.h"
#import "UtilityMethods.h"
#import "TableCellDataObject.h"
#import "TexLegeAppDelegate.h"
#import "SVWebViewController.h"
#import "LocalyticsSession.h"
#import "NSDate+Helper.h"
#import "BillMetadataLoader.h"
#import "DDActionHeaderView.h"
#import "TexLegeTheme.h"
#import "TexLegeStandardGroupCell.h"
#import "BillVotesDataSource.h"
#import "OpenLegislativeAPIs.h"
#import "LocalyticsSession.h"
#import "AppendingFlowView.h"
#import "BillActionParser.h"
#import <SafariServices/SafariServices.h>

@interface BillsDetailViewController (Private)
- (void)setupHeader;
- (void)showLegislatorDetailsWithOpenStatesID:(id)legeID;
- (void)starButtonSetState:(BOOL)isOn;
@end

typedef NS_ENUM(NSUInteger, BillDetailSection) {
    BillDetailSectionSubjects = 0,
    BillDetailSectionVersions,
    BillDetailSectionVotes,
    BillDetailSectionSponsors,
    BillDetailSectionActions,               // LAST ITEM vvvvvvvvvvvv
};
const NSUInteger BillDetailSection_LAST_ITEM = BillDetailSectionActions + 1;

@implementation BillsDetailViewController

@synthesize masterPopover = _masterPopover;

- (NSString *)nibName
{
	if ([UtilityMethods isIPadDevice])
		return @"BillsDetailViewController~ipad";
	else
		return @"BillsDetailViewController~iphone";
}

#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
	UINavigationController *nav = self.navigationController;
	if (nav && (nav.viewControllers).count>3)
		[nav popToRootViewControllerAnimated:YES];
	
    [super didReceiveMemoryWarning];
}


- (void)dealloc
{
	[[RKClient sharedClient].requestQueue cancelRequestsWithDelegate:self];
    self.bill = nil;
}

#pragma mark -
#pragma mark View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self.tableView registerClass:[TXLClickableSubtitleCell class] forCellReuseIdentifier:[TXLClickableSubtitleCell cellIdentifier]];
    [self.tableView registerClass:[TXLUnclickableSubtitleCell class] forCellReuseIdentifier:[TXLUnclickableSubtitleCell cellIdentifier]];
    
	self.voteDataSource = nil;

	//self.tableView.backgroundColor = [UIColor groupTableViewBackgroundColor];
	self.clearsSelectionOnViewWillAppear = NO;

	self.starButton = [UIButton buttonWithType:UIButtonTypeCustom];
//	[starButton addTarget:self action:@selector(itemAction:) forControlEvents:UIControlEventTouchUpInside];
    [_starButton addTarget:self action:@selector(starButtonToggle:) forControlEvents:UIControlEventTouchDown];
	[self starButtonSetState:NO];
    _starButton.frame = CGRectMake(0.0f, 0.0f, 66.0f, 66.0f);
    _starButton.center = CGPointMake(25.0f, 25.0f);
	self.actionHeader.items = @[_starButton];

	NSString *thePath = [[UtilityMethods applicationDocumentsDirectory] stringByAppendingPathComponent:kBillFavoritesStorageFile];
	NSFileManager *fileManager = [NSFileManager defaultManager];
	if (![fileManager fileExistsAtPath:thePath])
    {
		NSArray *tempArray = [[NSArray alloc] init];
		[tempArray writeToFile:thePath atomically:YES];
	}	
}

- (void)viewDidUnload
{
	[[RKRequestQueue sharedQueue] cancelRequestsWithDelegate:self];

    // Relinquish ownership of anything that can be recreated in viewDidLoad or on demand.	
	self.starButton = nil;
    self.voteDataSource = nil;

	[super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

	self.navigationController.navigationBar.tintColor = [TexLegeTheme navbar];

	if (NO == [UtilityMethods isLandscapeOrientation]
        && [UtilityMethods isIPadDevice]
        && !self.bill)
    {
		[[OpenLegislativeAPIs sharedOpenLegislativeAPIs] queryOpenStatesBillWithID:@"HB 1" 
																		   session:nil			// defaults to current session
																		  delegate:self];
	}
	
	if (self.starButton)
		self.starButton.enabled = (self.bill != nil);

    if (self.splitViewController.displayMode == UISplitViewControllerDisplayModePrimaryHidden)
    {
        UIBarButtonItem *button = self.splitViewController.displayModeButtonItem;
        [self.navigationItem setRightBarButtonItem:button animated:animated];
    }
}

- (BOOL)shouldAutorotate
{
    return YES;
}

- (void)splitViewController:(UISplitViewController *)svc willChangeToDisplayMode:(UISplitViewControllerDisplayMode)displayMode
{
    if (svc.displayMode == UISplitViewControllerDisplayModePrimaryHidden)
    {
        UIBarButtonItem *button = svc.displayModeButtonItem;
        [self.navigationItem setRightBarButtonItem:button animated:YES];
    }
}

#pragma mark - Data Objects

- (id)dataObject
{
	return self.bill;
}

- (void)setDataObject:(id)newObj
{
    if (!newObj || ![newObj isKindOfClass:[NSDictionary class]])
        newObj = nil;
	self.bill = newObj;
}

- (BOOL)isFavorite
{
    NSDictionary *foundItem = nil;

	if (self.bill)
	{
		NSString *thePath = [[UtilityMethods applicationDocumentsDirectory] stringByAppendingPathComponent:kBillFavoritesStorageFile];
		NSArray *watchList = [[NSArray alloc] initWithContentsOfFile:thePath];
		if (watchList)
        {
            NSString *watchID = watchIDForBill(self.bill);
            foundItem = [watchList findWhereKeyPath:@"watchID" equals:watchID];
        }
	}

    if (foundItem)
        return YES;
	return NO;
}

- (void)setFavorite:(BOOL)newValue
{
	if (self.bill)
	{
		NSString *thePath = [[UtilityMethods applicationDocumentsDirectory] stringByAppendingPathComponent:kBillFavoritesStorageFile];
		NSMutableArray *watchList = [[NSMutableArray alloc] initWithContentsOfFile:thePath];
		
		NSString *watchID = watchIDForBill(self.bill);
        if (!watchID)
            return;

        NSMutableDictionary *foundItem = [watchList findWhereKeyPath:@"watchID" equals:watchID];
		if (!foundItem && newValue == YES)
        {
            foundItem = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                          watchID, @"watchID",
                          _bill[@"bill_id"], @"bill_id",
                          _bill[@"session"], @"session",
                          _bill[@"title"], @"title",
                          nil];

			if (newValue == YES)
            {
				NSNumber *count = @(watchList.count);
				foundItem[@"displayOrder"] = count;
				[watchList addObject:foundItem];
				
				NSDictionary *tagBill = @{@"bill": watchID};
				[[LocalyticsSession sharedLocalyticsSession] tagEvent:@"BILL_FAVORITE" attributes:tagBill];
			}
		}
		else if (foundItem && newValue == NO)
        {
			[watchList removeObject:foundItem];
        }
		[watchList writeToFile:thePath atomically:YES];
	}
}

- (void)showLegislatorDetailsWithOpenStatesID:(id)legeID
{
	if (!legeID)
		return;
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"self.openstatesID == %@", legeID];
	LegislatorObj *legislator = [LegislatorObj objectWithPredicate:predicate];
	if (legislator)
    {
		LegislatorDetailViewController *legVC = [[LegislatorDetailViewController alloc] initWithNibName:@"LegislatorDetailViewController" bundle:nil];
		legVC.legislator = legislator;	
		[self.navigationController pushViewController:legVC animated:YES];
	}
}

- (void)setupHeader
{
    NSDictionary *bill = self.bill;
	if (!bill)
		return;
	
	NSString *session = bill[@"session"];
	NSString *billTitle = [NSString stringWithFormat:@"(%@) %@", session, bill[@"bill_id"]];
	self.navigationItem.title = billTitle;
	
	@try {
		NSArray *idComponents = [bill[@"bill_id"] componentsSeparatedByString:@" "];
		
		NSString *longTitle = [[BillMetadataLoader sharedBillMetadataLoader].metadata[@"types"] 
							   findWhereKeyPath:@"title" 
							   equals:idComponents[0]][@"titleLong"];
		billTitle = [NSString stringWithFormat:@"(%@) %@ %@", 
					 session, longTitle, idComponents.lastObject];
		
	}
	@catch (NSException * e) {
	}

	self.actionHeader.titleLabel.text = billTitle;
	[self.actionHeader setNeedsDisplay];

    NSArray *actions = bill[@"actions"];
    if (IsEmpty(actions))
    {
        return;
    }
	
	NSDictionary *currentAction = [actions lastObject];
	NSDate *currentActionDate = [NSDate dateFromString:currentAction[@"date"]];
	NSString *actionDateString = [NSDate stringForDisplayFromDate:currentActionDate];
	
	NSMutableString *descText = [NSMutableString stringWithString:NSLocalizedStringFromTable(@"Activity: ", @"DataTableUI", @"Section header to list latest bill activity")];
	[descText appendFormat:@"%@ (%@)\r", currentAction[@"action"], actionDateString];
	[descText appendString:bill[@"title"]];	// the summary of the bill
	self.lab_description.text = descText;
	
	AppendingFlowView *statV = self.statusView;
	statV.uniformWidth = NO;
	if ([UtilityMethods isIPadDevice])
    {
		statV.preferredBoxSize = CGSizeMake(80.f, 43.f);	
		statV.connectorSize = CGSizeMake(25.f, 6.f);
	}
	else
    {
		statV.preferredBoxSize = CGSizeMake(75.f, 40.f);	
		statV.connectorSize = CGSizeMake(7.f, 6.f);	
		statV.font = [TexLegeTheme boldTwelve];
		statV.insetMargin = CGSizeMake(13.f, 10.f);
	}

	BillActionParser *parser = [[BillActionParser alloc] init];
	NSArray *tempList = [parser parseStagesForBill:bill].allValues;
	
	if (NO == IsEmpty(tempList))
    {
		NSSortDescriptor *sortDesc = [NSSortDescriptor sortDescriptorWithKey:@"stageNumber" ascending:YES];
		tempList = [tempList sortedArrayUsingDescriptors:@[sortDesc]];
		self.statusView.stages = tempList;
	}		
}

- (void)setBill:(NSMutableDictionary *)bill
{
	if (self.starButton)
		self.starButton.enabled = (bill != nil);

    _bill = bill;
    if (!bill)
        return;

    self.tableView.dataSource = self;

    [self setupHeader];

    if (self.starButton)
        [self starButtonSetState:[self isFavorite]];

    if (self.masterPopover != nil)
    {
        [self.masterPopover dismissPopoverAnimated:YES];
    }

    [self.tableView reloadData];
}

#pragma mark -
#pragma mark Managing the popover

- (IBAction)resetTableData:(id)sender
{
	// this will force our datasource to renew everything
	[self.tableView reloadData];	
}

// Called on the delegate when the user has taken action to dismiss the popover. This is not called when -dismissPopoverAnimated: is called directly.
- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
	[self.tableView reloadData];
}

- (void)starButtonSetState:(BOOL)isOn
{
    if (!self.starButton)
        return;

	_starButton.tag = isOn;
	if (isOn)
    {
		[_starButton setImage:[UIImage imageNamed:@"starButtonLargeOff"] forState:UIControlStateHighlighted];
		[_starButton setImage:[UIImage imageNamed:@"starButtonLargeOn"] forState:UIControlStateNormal];
	}
	else
    {
		[_starButton setImage:[UIImage imageNamed:@"starButtonLargeOff"] forState:UIControlStateNormal];
		[_starButton setImage:[UIImage imageNamed:@"starButtonLargeOn"] forState:UIControlStateHighlighted];
	}
}

- (IBAction)starButtonToggle:(id)sender
{
	if (!sender || ![sender isEqual:self.starButton])
        return;

    BOOL isFavorite = [self isFavorite];
    [self starButtonSetState:!isFavorite];
    [self setFavorite:!isFavorite];

	// We're turning this off for now, we don't need the extended action menu, yet.
	// Reset action picker
	//		[self.actionHeader shrinkActionPicker];
	
}

#pragma mark -
#pragma mark Table view data source

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    BillDetailSection billSection = BillDetailSectionSubjects;
    if (section >= 0 && section < BillDetailSection_LAST_ITEM)
        billSection = (BillDetailSection)section;

	NSString *secTitle = nil;
	switch (billSection)
    {
		case BillDetailSectionSubjects:
			secTitle = NSLocalizedStringFromTable(@"Subject(s)", @"DataTableUI", @"Section title listing the subjects or categories of the bill");
			break;
		case BillDetailSectionSponsors:
			secTitle = NSLocalizedStringFromTable(@"Sponsor(s)", @"DataTableUI", @"Section title listing the legislators who sponsored the bill");
			break;
		case BillDetailSectionVersions:
			secTitle = NSLocalizedStringFromTable(@"Version(s)", @"DataTableUI", @"Section title listing the various versions of the bill text");
			break;
		case BillDetailSectionActions:
			secTitle = NSLocalizedStringFromTable(@"Action History", @"DataTableUI", @"Section title listing the latest actions for the bill");
			break;
		case BillDetailSectionVotes:
			secTitle = NSLocalizedStringFromTable(@"Votes", @"DataTableUI", @"Section title listing the available legislative votes on the bill");
			break;
	}
	return secTitle;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return BillDetailSection_LAST_ITEM;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    BillDetailSection billSection = BillDetailSectionSubjects;
    if (section >= 0 && section < BillDetailSection_LAST_ITEM)
        billSection = (BillDetailSection)section;

    NSInteger rows = 0;
    if (!self.bill)
        return rows;

    switch (billSection) {
        case BillDetailSectionSubjects:
            rows = [_bill[@"subjects"] count];
            break;
        case BillDetailSectionSponsors:
            rows = [_bill[@"sponsors"] count];
            break;
        case BillDetailSectionVersions:
            rows = [_bill[@"versions"] count];
            break;
        case BillDetailSectionActions:
            rows = [_bill[@"actions"] count];
            break;
        case BillDetailSectionVotes:
            rows = [_bill[@"votes"] count];
            break;
    }

    return rows;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    BillDetailSection billSection = BillDetailSectionSubjects;
    if (indexPath.section >= 0 && indexPath.section < BillDetailSection_LAST_ITEM)
        billSection = (BillDetailSection)indexPath.section;

	BOOL isClickable = (billSection != BillDetailSectionActions
                        && billSection != BillDetailSectionVotes);
	
    NSString *reuseId = (isClickable) ? [TXLClickableSubtitleCell cellIdentifier] : [TXLUnclickableSubtitleCell cellIdentifier];
    
    TexLegeStandardGroupCell *cell = (TexLegeStandardGroupCell *)[tableView dequeueReusableCellWithIdentifier:reuseId];
    if (cell == nil)
    {
        cell = [[TexLegeStandardGroupCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseId];
    }

    if (!self.bill)
        return cell;

    switch (billSection)
    {
        case BillDetailSectionSubjects:
        {
            NSString *subject = _bill[@"subjects"][indexPath.row];
            //cell.textLabel.text = subject;
            cell.detailTextLabel.text = subject;
            cell.textLabel.text = @"";
            break;
        }
        case BillDetailSectionSponsors:
        {
            NSDictionary *sponsor = _bill[@"sponsors"][indexPath.row];
            cell.detailTextLabel.text = sponsor[@"name"];
            cell.textLabel.text = [sponsor[@"type"] capitalizedString];
            break;
        }
        case BillDetailSectionVersions:
        {
            NSDictionary *version = _bill[@"versions"][indexPath.row];
            NSString *textName = nil;
            NSString *senateString = stringForChamber(SENATE, TLReturnFull);
            NSString *houseString = stringForChamber(HOUSE, TLReturnFull);
            NSString *comRep = NSLocalizedStringFromTable(@"%@ Committee Report", @"DataTableUI", @"Preceded by the legislative chamber");

            NSString *name = version[@"name"];
            if ([name hasSuffix:@"I"])
                textName = NSLocalizedStringFromTable(@"Introduced", @"DataTableUI", @"A bill activity stating the bill has been introduced");
            else if ([name hasSuffix:@"E"])
                textName = NSLocalizedStringFromTable(@"Engrossed", @"DataTableUI", @"A bill activity stating the bill has been engrossed (passed and sent to the other chamber)");
            else if ([name hasSuffix:@"S"])
                textName = [NSString stringWithFormat:comRep, senateString];
            else if ([name hasSuffix:@"H"])
                textName = [NSString stringWithFormat:comRep, houseString];
            else if ([name hasSuffix:@"A"])
                textName = NSLocalizedStringFromTable(@"Amendments Printing", @"DataTableUI", @"A bill activity saying that they legislature is printing amendments");
            else if ([name hasSuffix:@"F"])
                textName = NSLocalizedStringFromTable(@"Enrolled", @"DataTableUI", @"A bill activity stating that the bill has been enrolled (like a law)");
            else
                textName = name;
            cell.textLabel.text = @"";
            cell.detailTextLabel.text = textName;

            break;
        }
        case BillDetailSectionVotes:
        {
            NSDictionary *vote = _bill[@"votes"][indexPath.row];
            NSDate *voteDate = [NSDate dateFromString:vote[@"date"]];
            NSString *voteDateString = [NSDate stringForDisplayFromDate:voteDate];

            BOOL passed = [vote[@"passed"] boolValue];
            NSString *passedString = passed ? NSLocalizedStringFromTable(@"Passed", @"DataTableUI", @"Whether a bill passed/failed") : NSLocalizedStringFromTable(@"Failed", @"DataTableUI", @"Whether a bill passed/failed");
            NSInteger chamber = chamberFromOpenStatesString(vote[@"chamber"]);
            NSString *chamberString = stringForChamber(chamber, TLReturnFull);
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ - %@ (%@)",
                                         [vote[@"motion"] capitalizedString],
                                         chamberString, voteDateString];
            cell.textLabel.text = [NSString stringWithFormat:@"%@ (%@ - %@ - %@)", passedString,
                                   vote[@"yes_count"], vote[@"no_count"],
                                   vote[@"other_count"]];
            break;
        }
        case BillDetailSectionActions:
        {
            NSDictionary *currentAction = _bill[@"actions"][indexPath.row];
            if (!IsEmpty(currentAction[@"date"]))
            {
                NSDate *currentActionDate = [NSDate dateFromString:currentAction[@"date"]];
                NSString *actionDateString = [NSDate stringForDisplayFromDate:currentActionDate];
                cell.textLabel.text = actionDateString;
            }
            if (!IsEmpty(currentAction[@"action"]))
            {
                NSString *desc = nil;
                if (!IsEmpty(currentAction[@"actor"]))
                {
                    NSInteger chamberCode = chamberFromOpenStatesString(currentAction[@"actor"]);
                    if (chamberCode == HOUSE || chamberCode == SENATE) {
                        desc = [NSString stringWithFormat:@"(%@) %@", 
                                stringForChamber(chamberCode, TLReturnFull), 
                                currentAction[@"action"]];
                    }
                }
                if (!desc)
                    desc = currentAction[@"action"];
                cell.detailTextLabel.text = desc;
            }
            break;
        }
        default:
            break;
	}
    
    return cell;
}

- (void)tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	// deselect the new row using animation
	[aTableView deselectRowAtIndexPath:indexPath animated:YES];

    BillDetailSection billSection = BillDetailSectionSubjects;
    if (indexPath.section >= 0 && indexPath.section < BillDetailSection_LAST_ITEM)
        billSection = (BillDetailSection)indexPath.section;

	switch (billSection)
    {
        case BillDetailSectionActions:
            break;

		case BillDetailSectionSubjects:
        {
            NSArray *subjects = self.bill[@"subjects"];
            if (!subjects ||
                ![subjects isKindOfClass:[NSArray class]]
                || subjects.count <= indexPath.row)
            {
                break;
            }

			NSString *subject = subjects[indexPath.row];
			BillsListViewController *catResultsView = nil;
            UINavigationController *masterNavigation = [[TexLegeAppDelegate appDelegate] masterNavigationController];

			BOOL preexisting = NO;
			if ([UtilityMethods isIPadDevice]
                && [UtilityMethods isLandscapeOrientation])
            {
				id tempView = masterNavigation.visibleViewController;
				if ([tempView isKindOfClass:[BillsListViewController class]])
                {
					catResultsView = (BillsListViewController *)tempView;
					preexisting = YES;
				}
			}
			if (!catResultsView) {
				catResultsView = [[BillsListViewController alloc] initWithStyle:UITableViewStylePlain];
			}
			catResultsView.title = subject;
			BillSearchDataSource *dataSource = [catResultsView valueForKey:@"dataSource"];
			[dataSource startSearchForSubject:subject chamber:[_bill[@"chamber"] integerValue]];
			if (!preexisting)
            {
				if ([UtilityMethods isIPadDevice]
                    && [UtilityMethods isLandscapeOrientation])
                {
					[masterNavigation pushViewController:catResultsView animated:YES];
                }
				else
					[self.navigationController pushViewController:catResultsView animated:YES];
			}
            break;
		}
		case BillDetailSectionSponsors:
        {
            NSArray *sponsors = self.bill[@"sponsors"];
            if (!sponsors ||
                ![sponsors isKindOfClass:[NSArray class]]
                || sponsors.count <= indexPath.row)
            {
                break;
            }
			NSDictionary *sponsor = sponsors[indexPath.row];
			[self showLegislatorDetailsWithOpenStatesID:sponsor[@"leg_id"]];
            break;
		}
		case BillDetailSectionVersions:
        {
            NSArray *versions = self.bill[@"versions"];
            if (!versions ||
                ![versions isKindOfClass:[NSArray class]]
                || versions.count <= indexPath.row)
            {
                break;
            }

			NSDictionary *version = versions[indexPath.row];
            NSString *urlString = version[@"url"];
            if (urlString && [urlString isKindOfClass:[NSString class]])
            {
                UIViewController *webController = nil;

                NSURL *url = [NSURL URLWithString:urlString];
                if (!url)
                    break;

                if ([url.scheme hasPrefix:@"http"])
                    webController = [[SFSafariViewController alloc] initWithURL:url];
                else // can't use anything except http: or https: with SFSafariViewControllers
                    webController = [[SVWebViewController alloc] initWithAddress:urlString];

                webController.modalPresentationStyle = UIModalPresentationPageSheet;
                [self presentViewController:webController animated:YES completion:nil];
            }
            break;
		}
		case BillDetailSectionVotes:
        {
            NSArray *votes = self.bill[@"votes"];
            if (!votes ||
                ![votes isKindOfClass:[NSArray class]]
                || votes.count <= indexPath.row)
            {
                break;
            }

			NSDictionary *vote = votes[indexPath.row];
            if (![vote isKindOfClass:[NSDictionary class]])
            {
                break;
            }

            BillVotesDataSource *voteDS = self.voteDataSource;
            if (!voteDS || NO == [voteDS.voteID isEqualToString:vote[@"vote_id"]])
            {
                voteDS = [[BillVotesDataSource alloc] initWithBillVotes:vote];
            }

            BillVotesViewController *voteViewController = [[BillVotesViewController alloc] initWithStyle:UITableViewStyleGrouped];
            voteViewController.tableView.dataSource = voteDS;
            voteViewController.tableView.delegate = voteDS;
            voteDS.viewController = voteViewController;
            [self.navigationController pushViewController:voteViewController animated:YES];

            NSString *billID = self.bill[@"bill_id"];
            NSString *motion = [vote[@"motion"] capitalizedString];

            voteViewController.navigationItem.title = [NSString stringWithFormat:NSLocalizedStringFromTable(@"%@ %@ Vote", @"DataTableUI", @"Example: HB-323 Final Passage Vote"), billID, motion];

            break;
		}
	}
}


#pragma mark -
#pragma mark RestKit:RKObjectLoaderDelegate

- (void)request:(RKRequest*)request didFailLoadWithError:(NSError*)error
{
	if (error && request)
    {
		debug_NSLog(@"BillDetail - Error loading bill results from %@: %@", [request description], [error localizedDescription]);
	}

    NSString *title = NSLocalizedStringFromTable(@"Network Error", @"AppAlerts", @"Title for alert stating there's been an error when connecting to a server");
    NSString *message = NSLocalizedStringFromTable(@"There was an error while contacting the server for bill information.  Please check your network connectivity or try again.", @"AppAlerts", @"");

    UIAlertController *controller = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:nil style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {

    }];
    [controller addAction:cancel];
    controller.preferredAction = cancel;

    [self showViewController:controller sender:self];
}

- (void)request:(RKRequest*)request didLoadResponse:(RKResponse*)response
{
	if ([request isGET] && [response isOK]) {  
		// Success! Let's take a look at the data
        NSError *error = nil;
        self.bill = [NSJSONSerialization JSONObjectWithData:response.body options:NSJSONReadingMutableContainers | NSJSONReadingMutableLeaves error:&error];

		NSDictionary *tagBill = @{@"bill": watchIDForBill(self.bill)};
		[[LocalyticsSession sharedLocalyticsSession] tagEvent:@"BILL_SELECT" attributes:tagBill];
	}
}

@end

