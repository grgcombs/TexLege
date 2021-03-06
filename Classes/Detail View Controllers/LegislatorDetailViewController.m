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
#import <SLToastKit/SLTypeCheck.h>
#import <SafariServices/SFSafariViewController.h>

@implementation LegislatorDetailViewController

@synthesize dataSource = _dataSource;
@synthesize dataObject = _dataObject;

- (NSString *)nibName
{
	if ([UtilityMethods isIPadDevice])
		return @"LegislatorDetailViewController~ipad";
	else
		return @"LegislatorDetailViewController~iphone";
}

- (void)viewDidLoad
{
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
    self.votingDataSource = votingDS;
	[votingDS prepareVotingRecordView:self.chartView];

    LegislatorObj *legislator = self.legislator;
    if (legislator)
        [self configureWithLegislator:legislator];
}

- (void)viewDidUnload
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	self.votingDataSource = nil;
	[super viewDidUnload];
}

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
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (NSString *)chamberPartyAbbrev
{
	LegislatorObj *member = self.legislator;
	NSString *partyName = stringForParty((member.party_id).integerValue, TLReturnAbbrevPlural);
	
	return [NSString stringWithFormat:@"%@ %@", [member chamberName], partyName];
}

- (NSString *)partisanRankStringForLegislator
{
	LegislatorObj *member = self.legislator;
	if (IsEmpty(member.wnomScores))
		return @"";

	NSArray *legislators = [TexLegeCoreDataUtils allLegislatorsSortedByPartisanshipFromChamber:(member.legtype).integerValue 
																					andPartyID:(member.party_id).integerValue];
	if (legislators)
    {
		NSInteger rankIndex = [legislators indexOfObject:member] + 1;
		NSInteger count = legislators.count;
		NSString *partyShortName = stringForParty((member.party_id).integerValue, TLReturnAbbrevPlural);
		
		NSString *ordinalRank = [UtilityMethods ordinalNumberFormat:rankIndex];
		return [NSString stringWithFormat:NSLocalizedStringFromTable(@"%@ most partisan (out of %d %@)", @"DataTableUI", @"Partisan ranking, ie. 32nd most partisan out of 55 Democrats"), 
				ordinalRank, count, partyShortName];	
	}
	else
    {
		return @"";
	}
}

- (void)setupHeader
{
	LegislatorObj *member = self.legislator;
	
	NSString *legName = [NSString stringWithFormat:@"%@ %@",  [member legTypeShortName], [member legProperName]];
	self.leg_nameLab.text = legName;
	self.navigationItem.title = legName;

    [self.leg_photoView sd_setImageWithURL:[NSURL URLWithString:member.photo_url] placeholderImage:[UIImage imageNamed:@"placeholder"]];
	self.leg_partyLab.text = member.party_name;
	self.leg_districtLab.text = [NSString stringWithFormat:NSLocalizedStringFromTable(@"District %@", @"DataTableUI", @"District number"), 
								 member.district];
	self.leg_tenureLab.text = [member tenureString];
	if (member.nextElection)
    {
		self.leg_reelection.text = [NSString stringWithFormat:NSLocalizedStringFromTable(@"Reelection: %@", @"DataTableUI", @"Year of person's next reelection"), member.nextElection];
	}
	
	PartisanIndexStats *indexStats = [PartisanIndexStats sharedPartisanIndexStats];

	if (self.leg_indexTitleLab)
		self.leg_indexTitleLab.text = [NSString stringWithFormat:@"%@ %@", 
									   [member legTypeShortName], member.lastname];

	if (self.leg_rankLab)
		self.leg_rankLab.text = [self partisanRankStringForLegislator];
	
	if (self.leg_chamberPartyLab)
    {
		self.leg_chamberPartyLab.text = [self chamberPartyAbbrev];
		self.leg_chamberLab.text = [[member chamberName] stringByAppendingFormat:@" %@", NSLocalizedStringFromTable(@"Avg.", @"DataTableUI", @"Abbreviation for 'average'")];				
	}

    TXLChamberType chamber = member.legtype.intValue;
    TXLPartyType party = member.party_id.intValue;
	double minSlider = [indexStats minPartisanIndexUsingChamber:chamber];
	double maxSlider = [indexStats maxPartisanIndexUsingChamber:chamber];
	
	if (self.indivSlider)
    {
		self.indivSlider.sliderMin = minSlider;
		self.indivSlider.sliderMax = maxSlider;
		self.indivSlider.sliderValue = member.latestWnomFloat;
	}	
	if (self.partySlider)
    {
		self.partySlider.sliderMin = minSlider;
		self.partySlider.sliderMax = maxSlider;
		self.partySlider.sliderValue = [indexStats partyPartisanIndexUsingChamber:chamber andPartyID:party];
	}	
	if (self.allSlider)
    {
		self.allSlider.sliderMin = minSlider;
		self.allSlider.sliderMax = maxSlider;
		self.allSlider.sliderValue = [indexStats overallPartisanIndexUsingChamber:chamber];
	}	
	
	BOOL hasScores = !IsEmpty(member.wnomScores);
	self.freshmanPlotLab.hidden = hasScores;
	self.chartView.hidden = !hasScores;
}

- (LegislatorDetailDataSource *)dataSourceWithLegislator:(LegislatorObj *)legislator
{
    legislator = SLValueIfClass(LegislatorObj, legislator);
    LegislatorDetailDataSource *dataSource = _dataSource;

    if (dataSource
        && legislator
        && [dataSource.legislator isEqual:legislator])
    {
        return dataSource;
    }

    dataSource = (legislator) ? [[LegislatorDetailDataSource alloc] initWithLegislator:legislator] : nil;
    self.dataSource = dataSource;

    return dataSource;
}

- (LegislatorObj *)legislator
{
    LegislatorObj *legislator = SLValueIfClass(LegislatorObj, self.dataObject);
    if (legislator)
        return legislator;

    NSNumber *objectId = self.dataObjectID;
    if (!objectId)
        return nil;

    @try {
        legislator = SLValueIfClass(LegislatorObj, [LegislatorObj objectWithPrimaryKeyValue:objectId]);
    }
    @catch (NSException * e) {
        debug_NSLog(@"Exception while fetching legislator (ID = %@) from Core Data: %@", objectId, e);
    }
    return legislator;
}

- (void)setDataObject:(id)newObj
{
    LegislatorObj *existingData = SLValueIfClass(LegislatorObj, _dataObject);
    LegislatorObj *newData = SLValueIfClass(LegislatorObj, newObj);

    _dataObject = newData;
    self.dataObjectID = (newData) ? newData.legislatorID : nil;
    self.votingDataSource.legislator = newData;

    if (!newData)
    {
        self.dataSource = nil;
    }

    if (!self.isViewLoaded)
        return;

    if (existingData == newData || [newData isEqual:existingData])
        return;

    [self configureWithLegislator:newData];
}

- (void)setLegislator:(LegislatorObj *)legislator
{
    [self setDataObject:legislator];
}

- (void)configureWithLegislator:(LegislatorObj *)legislator
{
    if (!self.isViewLoaded)
        return;

    LegislatorDetailDataSource *dataSource = [self dataSourceWithLegislator:legislator];
    if (dataSource)
        [dataSource createSectionList];
    self.tableView.dataSource = dataSource;

    self.votingDataSource.legislator = legislator;

    [self setupHeader];

    [self.tableView reloadData];
    [self.chartView reloadData];
}

- (IBAction)resetTableData:(id)sender
{
    LegislatorObj *legislator = self.legislator;
    [self configureWithLegislator:legislator];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

	BOOL ipad = [UtilityMethods isIPadDevice];
	BOOL portrait = (![UtilityMethods isLandscapeOrientation]);

    LegislatorObj *legislator = self.legislator;
	if (portrait && ipad && !legislator)
    {
		legislator = [TexLegeAppDelegate appDelegate].legislatorMasterVC.initialObjectToSelect;
        self.legislator = legislator;
    }

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

- (void)willTransitionToTraitCollection:(UITraitCollection *)newCollection withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super willTransitionToTraitCollection:newCollection withTransitionCoordinator:coordinator];

    [coordinator notifyWhenInteractionChangesUsingBlock:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        if ([context percentComplete] >= 1.0)
        {
            [self.chartView reloadData];
        }
    }];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	
	TableCellDataObject *cellInfo = [self.dataSource dataObjectForIndexPath:indexPath];
	LegislatorObj *member = self.legislator;

	if (!cellInfo.isClickable)
		return;

    if (cellInfo.entryType == DirectoryTypeNotes)
    {
        BOOL isTablet = [UtilityMethods isIPadDevice];

        NotesViewController *notesController = nil;
        if (isTablet)
            notesController = [[NotesViewController alloc] initWithNibName:@"NotesView~ipad" bundle:nil];
        else
            notesController = [[NotesViewController alloc] initWithNibName:@"NotesView" bundle:nil];

        NSAssert(notesController != NULL, @"Unable to instanciate a Notes View Controller");
        if (!notesController)
            return;

        notesController.legislator = member;
        notesController.backViewController = self;

        if (isTablet)
        {
            notesController.modalPresentationStyle = UIModalPresentationPopover;
            CGRect cellRect = [tableView rectForRowAtIndexPath:indexPath];
            UIPopoverPresentationController *presenter = notesController.popoverPresentationController;
            presenter.delegate = self;
            presenter.sourceRect = cellRect;
            presenter.sourceView = tableView;
            presenter.permittedArrowDirections = UIPopoverArrowDirectionAny;
            [self presentViewController:notesController animated:YES completion:nil];
        }
        else
        {
            UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
            [self showViewController:notesController sender:cell];
            //[self.navigationController pushViewController:notesController animated:YES];
        }
    }
    else if (cellInfo.entryType == DirectoryTypeCommittee)
    {
        CommitteeDetailViewController *subDetailController = [[CommitteeDetailViewController alloc] initWithNibName:@"CommitteeDetailViewController" bundle:nil];
        subDetailController.committee = cellInfo.entryValue;
        [self.navigationController pushViewController:subDetailController animated:YES];
    }
    else if (cellInfo.entryType == DirectoryTypeContributions)
    {
#if CONTRIBUTIONS_API == TRANSPARENCY_DATA_API
        if ([TexLegeReachability canReachHostWithURL:[NSURL URLWithString:transApiBaseURL]])
        {
            LegislatorContributionsViewController *subDetailController = [[LegislatorContributionsViewController alloc] initWithStyle:UITableViewStyleGrouped];
            [subDetailController setQueryEntityID:cellInfo.entryValue type:@(kContributionQueryRecipient) cycle:@"-1"];
            [self.navigationController pushViewController:subDetailController animated:YES];
            [subDetailController release];
        }

#elif CONTRIBUTIONS_API == FOLLOW_THE_MONEY_API
        if ([TexLegeReachability canReachHostWithURL:[NSURL URLWithString:followTheMoneyApiBaseURL]])
        {
            LegislatorContributionsViewController *subDetailController = [[LegislatorContributionsViewController alloc] initWithStyle:UITableViewStyleGrouped];
            [subDetailController setQueryEntityID:cellInfo.entryValue type:@(kContributionQueryElectionYear) cycle:nil parameter:cellInfo.parameter];
            [self.navigationController pushViewController:subDetailController animated:YES];
        }
#endif
    }
    else if (cellInfo.entryType == DirectoryTypeBills)
    {
        if ([TexLegeReachability openstatesReachable])
        {
            BillsListViewController *subDetailController = [[BillsListViewController alloc] initWithStyle:UITableViewStylePlain];
            subDetailController.title = [NSString stringWithFormat:NSLocalizedStringFromTable(@"Bills Authored by %@", @"DataTableUI", @"Title for cell, the legislative bills authored by someone."), 
                                         [member shortNameForButtons]];
            [subDetailController.dataSource startSearchForBillsAuthoredBy:cellInfo.entryValue];
            [self.navigationController pushViewController:subDetailController animated:YES];
        }
    }
    else if (cellInfo.entryType == DirectoryTypeOfficeMap)
    {
        CapitolMap *capMap = cellInfo.entryValue;			
        CapitolMapsDetailViewController *detailController = [[CapitolMapsDetailViewController alloc] initWithNibName:@"CapitolMapsDetailViewController" bundle:nil];
        detailController.map = capMap;
        
        [self.navigationController pushViewController:detailController animated:YES];
    }
    else if (cellInfo.entryType == DirectoryTypeMail)
    {
        [[TexLegeEmailComposer sharedTexLegeEmailComposer] presentMailComposerTo:cellInfo.entryValue 
                                                                         subject:@"" body:@"" commander:self];			
    }
    // Switch to the appropriate application for this url...
    else if (cellInfo.entryType == DirectoryTypeMap)
    {
        if ([cellInfo.entryValue isKindOfClass:[DistrictOfficeObj class]]
            || [cellInfo.entryValue isKindOfClass:[DistrictMapObj class]])
        {		
            MapMiniDetailViewController *mapViewController = [[MapMiniDetailViewController alloc] init];
            [mapViewController loadView];
            
            DistrictOfficeObj *districtOffice = nil;
            if ([cellInfo.entryValue isKindOfClass:[DistrictOfficeObj class]])
                districtOffice = cellInfo.entryValue;
            
            [mapViewController resetMapViewWithAnimation:NO];
            BOOL isDistMap = NO;
            id<MKAnnotation> theAnnotation = nil;
            if (districtOffice)
            {
                theAnnotation = districtOffice;
                [mapViewController.mapView addAnnotation:theAnnotation];
                [mapViewController moveMapToAnnotation:theAnnotation];
            }
            else
            {
                theAnnotation = member.districtMap;
                [mapViewController.mapView addAnnotation:theAnnotation];
                [mapViewController moveMapToAnnotation:theAnnotation];
                [mapViewController addDistrictOverlay:member.districtMap.polygon];
                isDistMap = YES;
            }
            if (theAnnotation)
            {
                mapViewController.navigationItem.title = theAnnotation.title;
            }

            [self.navigationController pushViewController:mapViewController animated:YES];
            
            if (isDistMap)
            {
                [member.districtMap.managedObjectContext refreshObject:member.districtMap mergeChanges:NO];
            }
        }
    }
    else if (cellInfo.entryType > kDirectoryTypeIsURLHandler &&
             cellInfo.entryType < kDirectoryTypeIsExternalHandler)
    {
        NSURL *url = [cellInfo generateURL];
        if (!url)
            return;

        if ([TexLegeReachability canReachHostWithURL:url])
        {

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
            }
        }
    }
    else if (cellInfo.entryType > kDirectoryTypeIsExternalHandler)		// tell the device to open the url externally
    {
        NSURL *myURL = [cellInfo generateURL];			
        BOOL isPhone = ([UtilityMethods canMakePhoneCalls]);
        
        if ((cellInfo.entryType == DirectoryTypePhone) && (!isPhone))
        {
            debug_NSLog(@"Tried to make a phone call, but this isn't a phone: %@", myURL.description);
            [UtilityMethods alertNotAPhone];
            return;
        }
        
        [UtilityMethods openURLWithoutTrepidation:myURL];
    }
}

- (void)popoverPresentationControllerDidDismissPopover:(UIPopoverPresentationController *)popoverPresentationController
{
    if (!self.isViewLoaded)
        return;
    [self.tableView reloadData];
}

- (CGFloat)tableView:(UITableView *)aTableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	CGFloat height = 44.0f;
	TableCellDataObject *cellInfo = [self.dataSource dataObjectForIndexPath:indexPath];
	
	if (cellInfo == nil)
    {
		debug_NSLog(@"LegislatorDetailViewController:heightForRow: error finding table entry for index path: %@", indexPath);
		return height;
	}
	if (cellInfo.subtitle
        && [cellInfo.subtitle hasSubstring:NSLocalizedStringFromTable(@"Address", @"DataTableUI", @"Cell title listing a street address") caseInsensitive:YES])
    {
		height = 98.0f;
	}
	else if ([cellInfo.entryValue isKindOfClass:[NSString class]])
    {
		NSString *tempStr = cellInfo.entryValue;
		if (!tempStr || tempStr.length <= 0)
        {
			height = 0.0f;
		}
	}
	return height;
}

@end
