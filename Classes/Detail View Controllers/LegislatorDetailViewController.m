//
//  LegislatorDetailViewController.m
//  Created by Gregory Combs on 6/28/10.
//
//  StatesLege by Sunlight Foundation, based on work at https://github.com/sunlightlabs/StatesLege
//
//  This work is licensed under the Creative Commons Attribution-NonCommercial 3.0 Unported License. 
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc/3.0/
//  or send a letter to Creative Commons, 444 Castro Street, Suite 900, Mountain View, California, 94041, USA.
//
//

#import "TableDataSourceProtocol.h"
#import "LegislatorDetailViewController.h"
#import "LegislatorDetailDataSource.h"
#import "LegislatorContributionsViewController.h"

#import "LegislatorMasterViewController.h"
#import "LegislatorObj+RestKit.h"
#import "DistrictOfficeObj+MapKit.h"
#import "DistrictMapObj+RestKit.h"
#import "DistrictMapObj+MapKit.h"
#import "CommitteeObj.h"
#import "CommitteePositionObj.h"
#import "WnomObj+RestKit.h"
#import "TexLegeCoreDataUtils.h"
#import "UtilityMethods.h"
#import "TableDataSourceProtocol.h"
#import "TableCellDataObject.h"
#import "NotesViewController.h"
#import "TexLegeAppDelegate.h"

#import "BillSearchDataSource.h"
#import "BillsListViewController.h"
#import "CommitteeDetailViewController.h"
#import "DistrictOfficeMasterViewController.h"

#import "MapMiniDetailViewController.h"
#import "SVWebViewController.h"
#import "CapitolMapsDetailViewController.h"

#import "PartisanIndexStats.h"
#import <SDWebImage/UIImageView+WebCache.h>

#import "TexLegeEmailComposer.h"
#import "PartisanScaleView.h"
#import "LocalyticsSession.h"

#import "VotingRecordDataSource.h"

#import "OpenLegislativeAPIs.h"
#import "TexLegeTheme.h"

#import <SafariServices/SFSafariViewController.h>

@interface LegislatorDetailViewController (Private)
- (void) setupHeader;
@end


@implementation LegislatorDetailViewController
@synthesize dataObjectID;
@synthesize dataSource;
@synthesize headerView, miniBackgroundView;

@synthesize leg_indexTitleLab, leg_rankLab, leg_chamberPartyLab, leg_chamberLab, leg_reelection;
@synthesize leg_photoView, leg_partyLab, leg_districtLab, leg_tenureLab, leg_nameLab, freshmanPlotLab;
@synthesize indivSlider, partySlider, allSlider;
@synthesize notesPopover, masterPopover;
@synthesize chartView, votingDataSource;

#pragma mark -
#pragma mark View lifecycle

- (NSString *)nibName {
	if ([UtilityMethods isIPadDevice])
		return @"LegislatorDetailViewController~ipad";
	else
		return @"LegislatorDetailViewController~iphone";
}

- (void)viewDidLoad {
    [super viewDidLoad];
		
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(resetTableData:) name:@"RESTKIT_LOADED_LEGISLATOROBJ" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(resetTableData:) name:@"RESTKIT_LOADED_STAFFEROBJ" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(resetTableData:) name:@"RESTKIT_LOADED_DISTRICTOFFICEOBJ" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(resetTableData:) name:@"RESTKIT_LOADED_DISTRICTMAPOBJ" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(resetTableData:) name:@"RESTKIT_LOADED_COMMITTEEOBJ" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(resetTableData:) name:@"RESTKIT_LOADED_COMMITTEEPOSITIONOBJ" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(resetTableData:) name:@"RESTKIT_LOADED_WNOMOBJ" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(resetTableData:) name:kPartisanIndexNotifyLoaded object:nil];
	
	self.tableView.backgroundColor = [UIColor groupTableViewBackgroundColor];
	self.clearsSelectionOnViewWillAppear = NO;
				
	VotingRecordDataSource *votingDS = [[VotingRecordDataSource alloc] init];
	[votingDS prepareVotingRecordView:self.chartView];
	self.votingDataSource = votingDS;
	[votingDS release];
}

- (void)viewDidUnload {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	self.votingDataSource = nil;
	[super viewDidUnload];
}

#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
	UINavigationController *nav = self.navigationController;
	if (nav && (nav.viewControllers).count>3)
		[nav popToRootViewControllerAnimated:YES];
		
    [super didReceiveMemoryWarning];
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	self.indivSlider = nil;
	self.partySlider = nil;
	self.allSlider = nil;
	self.dataSource = nil;
	self.headerView = nil;
	self.leg_photoView = nil;
	self.leg_reelection = nil;
	self.miniBackgroundView = nil;
	self.leg_partyLab = self.leg_districtLab = self.leg_tenureLab = self.leg_nameLab = self.freshmanPlotLab = nil;
	self.notesPopover = nil;
	self.masterPopover = nil;
	self.dataObjectID = nil;
	self.chartView = nil;
	self.votingDataSource = nil;

	[super dealloc];
}

- (id)dataObject {
	return self.legislator;
}

- (void)setDataObject:(id)newObj {
	self.legislator = newObj;
}

- (NSString *)chamberPartyAbbrev {
	LegislatorObj *member = self.legislator;
	NSString *partyName = stringForParty((member.party_id).integerValue, TLReturnAbbrevPlural);
	
	return [NSString stringWithFormat:@"%@ %@", [member chamberName], partyName];
}

- (NSString *) partisanRankStringForLegislator {
	LegislatorObj *member = self.legislator;
	if (IsEmpty(member.wnomScores))
		return @"";

	NSArray *legislators = [TexLegeCoreDataUtils allLegislatorsSortedByPartisanshipFromChamber:(member.legtype).integerValue 
																					andPartyID:(member.party_id).integerValue];
	if (legislators) {
		NSInteger rankIndex = [legislators indexOfObject:member] + 1;
		NSInteger count = legislators.count;
		NSString *partyShortName = stringForParty((member.party_id).integerValue, TLReturnAbbrevPlural);
		
		NSString *ordinalRank = [UtilityMethods ordinalNumberFormat:rankIndex];
		return [NSString stringWithFormat:NSLocalizedStringFromTable(@"%@ most partisan (out of %d %@)", @"DataTableUI", @"Partisan ranking, ie. 32nd most partisan out of 55 Democrats"), 
				ordinalRank, count, partyShortName];	
	}
	else {
		return @"";
	}
}

- (void)setupHeader {
	LegislatorObj *member = self.legislator;
	
	NSString *legName = [NSString stringWithFormat:@"%@ %@",  [member legTypeShortName], [member legProperName]];
	self.leg_nameLab.text = legName;
	self.navigationItem.title = legName;

    [self.leg_photoView setImageWithURL:[NSURL URLWithString:member.photo_url] placeholderImage:[UIImage imageNamed:@"placeholder"]];
	self.leg_partyLab.text = member.party_name;
	self.leg_districtLab.text = [NSString stringWithFormat:NSLocalizedStringFromTable(@"District %@", @"DataTableUI", @"District number"), 
								 member.district];
	self.leg_tenureLab.text = [member tenureString];
	if (member.nextElection) {
		
		self.leg_reelection.text = [NSString stringWithFormat:NSLocalizedStringFromTable(@"Reelection: %@", @"DataTableUI", @"Year of person's next reelection"), 
									member.nextElection];
	}
	
	PartisanIndexStats *indexStats = [PartisanIndexStats sharedPartisanIndexStats];

	if (self.leg_indexTitleLab)
		self.leg_indexTitleLab.text = [NSString stringWithFormat:@"%@ %@", 
									   [member legTypeShortName], member.lastname];

	if (self.leg_rankLab)
		self.leg_rankLab.text = [self partisanRankStringForLegislator];
	
	if (self.leg_chamberPartyLab) {
		self.leg_chamberPartyLab.text = [self chamberPartyAbbrev];
		self.leg_chamberLab.text = [[member chamberName] stringByAppendingFormat:@" %@", NSLocalizedStringFromTable(@"Avg.", @"DataTableUI", @"Abbreviation for 'average'")];				
	}
	
	CGFloat minSlider = [indexStats minPartisanIndexUsingChamber:(member.legtype).integerValue];
	CGFloat maxSlider = [indexStats maxPartisanIndexUsingChamber:(member.legtype).integerValue];
	
	if (self.indivSlider) {
		self.indivSlider.sliderMin = minSlider;
		self.indivSlider.sliderMax = maxSlider;
		self.indivSlider.sliderValue = member.latestWnomFloat;
	}	
	if (self.partySlider) {
		self.partySlider.sliderMin = minSlider;
		self.partySlider.sliderMax = maxSlider;
		self.partySlider.sliderValue = [indexStats partyPartisanIndexUsingChamber:(member.legtype).integerValue andPartyID:(member.party_id).integerValue];
	}	
	if (self.allSlider) {
		self.allSlider.sliderMin = minSlider;
		self.allSlider.sliderMax = maxSlider;
		self.allSlider.sliderValue = [indexStats overallPartisanIndexUsingChamber:(member.legtype).integerValue];
	}	
	
	BOOL hasScores = !IsEmpty(member.wnomScores);
	self.freshmanPlotLab.hidden = hasScores;
	self.chartView.hidden = !hasScores;

}


- (LegislatorDetailDataSource *)dataSource {
	LegislatorObj *member = self.legislator;
	if (!dataSource && member) {
		dataSource = [[LegislatorDetailDataSource alloc] initWithLegislator:member];
	}
	return dataSource;
}

- (void)setDataSource:(LegislatorDetailDataSource *)newObj {	
	if (newObj == dataSource)
		return;
	if (dataSource)
		[dataSource release], dataSource = nil;
	if (newObj)
		dataSource = [newObj retain];
}


- (LegislatorObj *)legislator {
	LegislatorObj *anObject = nil;
	if (self.dataObjectID) {
		@try {
			anObject = [LegislatorObj objectWithPrimaryKeyValue:self.dataObjectID];
		}
		@catch (NSException * e) {
		}
	}
	return anObject;
}

- (void)setLegislator:(LegislatorObj *)anObject {
	if (self.dataSource && anObject && self.dataObjectID && [anObject.legislatorID isEqual:self.dataObjectID])
		return;
	
	self.dataSource = nil;
	self.dataObjectID = nil;
	
	if (anObject) {
		self.dataObjectID = anObject.legislatorID;

		self.tableView.dataSource = self.dataSource;

		[self setupHeader];
		self.votingDataSource.legislatorID = anObject.legislatorID;

		if (masterPopover != nil) {
			[masterPopover dismissPopoverAnimated:YES];
		}		
		[self.tableView reloadData];
		[self.chartView reloadData];
		[self.view setNeedsDisplay];
	}
}
#pragma mark -
#pragma mark Managing the popover

- (IBAction)resetTableData:(id)sender {
	// this will force our datasource to renew everything
	self.dataSource.legislator = self.legislator;
	[self.tableView reloadData];	
	[self.chartView reloadData];
}

// Called on the delegate when the user has taken action to dismiss the popover. This is not called when -dismissPopoverAnimated: is called directly.
- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController {
	[self.tableView reloadData];
	if (self.notesPopover && [self.notesPopover isEqual:popoverController]) {
		self.notesPopover = nil;
	}
}
	
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

	BOOL ipad = [UtilityMethods isIPadDevice];
	BOOL portrait = (![UtilityMethods isLandscapeOrientation]);

	if (portrait && ipad && !self.legislator)
		self.legislator = [TexLegeAppDelegate appDelegate].legislatorMasterVC.selectObjectOnAppear;		
	
	if (self.legislator)
		[self setupHeader];
}

#pragma mark -
#pragma mark Split view support

- (void)splitViewController: (UISplitViewController*)svc 
	 willHideViewController:(UIViewController *)aViewController withBarButtonItem:(UIBarButtonItem*)barButtonItem 
	   forPopoverController: (UIPopoverController*)pc {
	//debug_NSLog(@"Entering portrait, showing the button: %@", [aViewController class]);
	barButtonItem.title = NSLocalizedStringFromTable(@"Legislators", @"StandardUI", @"The short title for buttons and tabs related to legislators");
	[self.navigationItem setRightBarButtonItem:barButtonItem animated:YES];
	self.masterPopover = pc;
}

// Called when the view is shown again in the split view, invalidating the button and popover controller.
- (void)splitViewController: (UISplitViewController*)svc 
	 willShowViewController:(UIViewController *)aViewController 
  invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem {
	//debug_NSLog(@"Entering landscape, hiding the button: %@", [aViewController class]);
	[self.navigationItem setRightBarButtonItem:nil animated:YES];
	self.masterPopover = nil;
}

- (void) splitViewController:(UISplitViewController *)svc popoverController: (UIPopoverController *)pc
   willPresentViewController: (UIViewController *)aViewController
{
	if ([UtilityMethods isLandscapeOrientation]) {
		[[LocalyticsSession sharedLocalyticsSession] tagEvent:@"ERR_POPOVER_IN_LANDSCAPE"];
	}
	if (self.notesPopover) {
		[self.notesPopover dismissPopoverAnimated:YES];
		self.notesPopover = nil;
	}
}

#pragma mark -
#pragma mark orientations

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Override to allow orientations other than the default portrait orientation.
    return YES;
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration 
{
	[self.chartView reloadData];	
}

#pragma mark -
#pragma mark Table View Delegate
// the user selected a row in the table.
- (void)tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)newIndexPath {
	
	// deselect the new row using animation
	[aTableView deselectRowAtIndexPath:newIndexPath animated:YES];	
	
	TableCellDataObject *cellInfo = [self.dataSource dataObjectForIndexPath:newIndexPath];
	LegislatorObj *member = self.legislator;

	if (!cellInfo.isClickable)
		return;
	
		if (cellInfo.entryType == DirectoryTypeNotes) { // We need to edit the notes thing...
			
			NotesViewController *nextViewController = nil;
			if ([UtilityMethods isIPadDevice])
				nextViewController = [[NotesViewController alloc] initWithNibName:@"NotesView~ipad" bundle:nil];
			else
				nextViewController = [[NotesViewController alloc] initWithNibName:@"NotesView" bundle:nil];
			
			// If we got a new view controller, push it .
			if (nextViewController) {
				nextViewController.legislator = member;
				nextViewController.backViewController = self;
				
				if ([UtilityMethods isIPadDevice]) {
					self.notesPopover = [[[UIPopoverController alloc] initWithContentViewController:nextViewController] autorelease];
					self.notesPopover.delegate = self;
					CGRect cellRect = [aTableView rectForRowAtIndexPath:newIndexPath];
					[self.notesPopover presentPopoverFromRect:cellRect inView:aTableView permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
				}
				else {
					[self.navigationController pushViewController:nextViewController animated:YES];
				}
				
				[nextViewController release];
			}
		}
		else if (cellInfo.entryType == DirectoryTypeCommittee) {
			CommitteeDetailViewController *subDetailController = [[CommitteeDetailViewController alloc] initWithNibName:@"CommitteeDetailViewController" bundle:nil];
			subDetailController.committee = cellInfo.entryValue;
			[self.navigationController pushViewController:subDetailController animated:YES];
			[subDetailController release];
		}
		else if (cellInfo.entryType == DirectoryTypeContributions) {
#if CONTRIBUTIONS_API == TRANSPARENCY_DATA_API
            if ([TexLegeReachability canReachHostWithURL:[NSURL URLWithString:transApiBaseURL]]) {
                LegislatorContributionsViewController *subDetailController = [[LegislatorContributionsViewController alloc] initWithStyle:UITableViewStyleGrouped];
                [subDetailController setQueryEntityID:cellInfo.entryValue type:@(kContributionQueryRecipient) cycle:@"-1"];
                [self.navigationController pushViewController:subDetailController animated:YES];
                [subDetailController release];
            }

#elif CONTRIBUTIONS_API == FOLLOW_THE_MONEY_API
            if ([TexLegeReachability canReachHostWithURL:[NSURL URLWithString:followTheMoneyApiBaseURL]]) {
                LegislatorContributionsViewController *subDetailController = [[LegislatorContributionsViewController alloc] initWithStyle:UITableViewStyleGrouped];
                [subDetailController setQueryEntityID:cellInfo.entryValue type:@(kContributionQueryRecipient) cycle:nil parameter:cellInfo.parameter];
                [self.navigationController pushViewController:subDetailController animated:YES];
                [subDetailController release];
            }
#endif
		}
		else if (cellInfo.entryType == DirectoryTypeBills) {
			if ([TexLegeReachability openstatesReachable]) { 
				BillsListViewController *subDetailController = [[BillsListViewController alloc] initWithStyle:UITableViewStylePlain];
				subDetailController.title = [NSString stringWithFormat:NSLocalizedStringFromTable(@"Bills Authored by %@", @"DataTableUI", @"Title for cell, the legislative bills authored by someone."), 
											 [member shortNameForButtons]];
				[subDetailController.dataSource startSearchForBillsAuthoredBy:cellInfo.entryValue];
				[self.navigationController pushViewController:subDetailController animated:YES];
				[subDetailController release];
			}
		}
		else if (cellInfo.entryType == DirectoryTypeOfficeMap) {
			CapitolMap *capMap = cellInfo.entryValue;			
			CapitolMapsDetailViewController *detailController = [[CapitolMapsDetailViewController alloc] initWithNibName:@"CapitolMapsDetailViewController" bundle:nil];
			detailController.map = capMap;
			
			[self.navigationController pushViewController:detailController animated:YES];
			[detailController release];
		}
		else if (cellInfo.entryType == DirectoryTypeMail) {
			[[TexLegeEmailComposer sharedTexLegeEmailComposer] presentMailComposerTo:cellInfo.entryValue 
																			 subject:@"" body:@"" commander:self];			
		}
		// Switch to the appropriate application for this url...
		else if (cellInfo.entryType == DirectoryTypeMap) {
			if ([cellInfo.entryValue isKindOfClass:[DistrictOfficeObj class]] || [cellInfo.entryValue isKindOfClass:[DistrictMapObj class]])
			{		
				MapMiniDetailViewController *mapViewController = [[MapMiniDetailViewController alloc] init];
				[mapViewController loadView];
				
				DistrictOfficeObj *districtOffice = nil;
				if ([cellInfo.entryValue isKindOfClass:[DistrictOfficeObj class]])
					districtOffice = cellInfo.entryValue;
				
				[mapViewController resetMapViewWithAnimation:NO];
				BOOL isDistMap = NO;
				id<MKAnnotation> theAnnotation = nil;
				if (districtOffice) {
					theAnnotation = districtOffice;
					[mapViewController.mapView addAnnotation:theAnnotation];
					[mapViewController moveMapToAnnotation:theAnnotation];
				}
				else {
					theAnnotation = member.districtMap;
					[mapViewController.mapView addAnnotation:theAnnotation];
					[mapViewController moveMapToAnnotation:theAnnotation];
                    [mapViewController addDistrictOverlay:member.districtMap.polygon];
					isDistMap = YES;
				}
				if (theAnnotation) {
					mapViewController.navigationItem.title = theAnnotation.title;
				}

				[self.navigationController pushViewController:mapViewController animated:YES];
				[mapViewController release];
				
				if (isDistMap) {
					[member.districtMap.managedObjectContext refreshObject:member.districtMap mergeChanges:NO];
				}
			}
		}
		else if (cellInfo.entryType > kDirectoryTypeIsURLHandler &&
				 cellInfo.entryType < kDirectoryTypeIsExternalHandler) {	// handle the URL ourselves in a webView
			NSURL *url = [cellInfo generateURL];
            if (!url)
                return;

			if ([TexLegeReachability canReachHostWithURL:url]) { // do we have a good URL/connection?

				if ([url.scheme isEqualToString:@"twitter"])
					[[UIApplication sharedApplication] openURL:url];
				else {
					NSString *urlString = url.absoluteString;
                    
                    UIViewController *webController = nil;
                    
                    if ([url.scheme hasPrefix:@"http"])
                        webController = [[SFSafariViewController alloc] initWithURL:url];
                    else // can't use anything except http: or https: with SFSafariViewControllers
                        webController = [[SVWebViewController alloc] initWithAddress:urlString];
                    
                    webController.modalPresentationStyle = UIModalPresentationPageSheet;
                    [self presentViewController:webController animated:YES completion:nil];
                    [webController release];
				}
			}
		}
		else if (cellInfo.entryType > kDirectoryTypeIsExternalHandler)		// tell the device to open the url externally
		{
			NSURL *myURL = [cellInfo generateURL];			
			BOOL isPhone = ([UtilityMethods canMakePhoneCalls]);
			
			if ((cellInfo.entryType == DirectoryTypePhone) && (!isPhone)) {
				debug_NSLog(@"Tried to make a phone call, but this isn't a phone: %@", myURL.description);
				[UtilityMethods alertNotAPhone];
				return;
			}
			
			[UtilityMethods openURLWithoutTrepidation:myURL];
		}
}

- (CGFloat)tableView:(UITableView *)aTableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	CGFloat height = 44.0f;
	TableCellDataObject *cellInfo = [self.dataSource dataObjectForIndexPath:indexPath];
	
	if (cellInfo == nil) {
		debug_NSLog(@"LegislatorDetailViewController:heightForRow: error finding table entry for index path: %@", indexPath);
		return height;
	}
	if (cellInfo.subtitle && [cellInfo.subtitle hasSubstring:NSLocalizedStringFromTable(@"Address", @"DataTableUI", @"Cell title listing a street address")
											 caseInsensitive:YES]) {
		height = 98.0f;
	}
	else if ([cellInfo.entryValue isKindOfClass:[NSString class]]) {
		NSString *tempStr = cellInfo.entryValue;
		if (!tempStr || tempStr.length <= 0) {
			height = 0.0f;
		}
	}
	return height;
}

@end

