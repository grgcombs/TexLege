//
//  CommitteeDetailViewController.m
//  Created by Gregory Combs on 6/29/10.
//
//  StatesLege by Sunlight Foundation, based on work at https://github.com/sunlightlabs/StatesLege
//
//  This work is licensed under the Creative Commons Attribution-NonCommercial 3.0 Unported License. 
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc/3.0/
//  or send a letter to Creative Commons, 444 Castro Street, Suite 900, Mountain View, California, 94041, USA.
//
//

#import "TableDataSourceProtocol.h"
#import "CommitteeDetailViewController.h"
#import "CommitteeMasterViewController.h"
#import "TexLegeCoreDataUtils.h"

#import "UtilityMethods.h"
#import "CapitolMapsDetailViewController.h"
#import "LegislatorDetailViewController.h"
#import "SVWebViewController.h"
#import "TexLegeAppDelegate.h"
#import "TexLegeTheme.h"
#import "LegislatorMasterCell.h"
#import "CommitteeMemberCell.h"
#import "CommitteeMemberCellView.h"
#import "TexLegeStandardGroupCell.h"
#import "PartisanScaleView.h"
#import "PartisanIndexStats.h"
#import "TexLegeEmailComposer.h"
#import "LocalyticsSession.h"
#import "LegislatorObj+RestKit.h"
#import "CommitteePositionObj+RestKit.h"
#import "CommitteeObj+RestKit.h"
#import <SLToastKit/SLTypeCheck.h>
#import <SafariServices/SFSafariViewController.h>

@implementation CommitteeDetailViewController

@synthesize dataObject = _dataObject;

typedef NS_ENUM(UInt16, TXLCommitteeSections) {
    //kHeaderSection = 0,
    TXLCommitteeInfoSection = 0,
    TXLCommitteeChairSection,
    TXLCommitteeViceChairSection,
    TXLCommitteeMembersSection,
};
UInt16 const TXLCommitteeSectionMax = (TXLCommitteeMembersSection + 1);

typedef NS_ENUM(NSInteger, CommitteeInfoRow) {
    CommitteeInfoRowName = 0,
    CommitteeInfoRowClerk,
    CommitteeInfoRowPhone,
    CommitteeInfoRowLocation,
    CommitteeInfoRowWebsite,
    COMMITTEE_INFO_ROW_COUNT
};

CGFloat quartzRowHeight = 73.f;

NSString * const TXLCommitteeClickableInfoCellReuse = @"CommitteeInfo";
NSString * const TXLCommitteeUnclickableInfoCellReuse = @"Committee-NoDisclosure";
NSString * const TXLCommitteeMemberCellReuse = @"CommitteeMember";

- (NSString *)nibName
{
	if ([UtilityMethods isIPadDevice])
		return @"CommitteeDetailViewController~ipad";
	else
		return @"CommitteeDetailViewController~iphone";	
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self.tableView registerClass:[TXLClickableSubtitleCell class] forCellReuseIdentifier:TXLCommitteeClickableInfoCellReuse];
    [self.tableView registerClass:[TXLUnclickableSubtitleCell class] forCellReuseIdentifier:TXLCommitteeUnclickableInfoCellReuse];

    if ([UtilityMethods isIPadDevice])
        [self.tableView registerClass:[CommitteeMemberCell class] forCellReuseIdentifier:TXLCommitteeMemberCellReuse];
    else
        [self.tableView registerClass:[LegislatorMasterCell class] forCellReuseIdentifier:TXLCommitteeMemberCellReuse];

	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(resetTableData:) name:@"RESTKIT_LOADED_LEGISLATOROBJ" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(resetTableData:) name:@"RESTKIT_LOADED_COMMITTEEOBJ" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(resetTableData:) name:@"RESTKIT_LOADED_COMMITTEEPOSITIONOBJ" object:nil];
	
	self.clearsSelectionOnViewWillAppear = NO;
}

- (void)viewDidUnload
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated 
{
    [super viewWillAppear:animated];
	
	if ([UtilityMethods isIPadDevice] == NO)
		return;
	
	// we don't have a legislator selected and yet we're appearing in portrait view ... got to have something here !!! 
	if (self.committee == nil && ![UtilityMethods isLandscapeOrientation])
    {
		self.committee = [TexLegeAppDelegate appDelegate].committeeMasterVC.initialObjectToSelect;		
	}

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

- (void)willTransitionToTraitCollection:(UITraitCollection *)newCollection withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [self willTransitionToTraitCollection:newCollection withTransitionCoordinator:coordinator];

    [coordinator notifyWhenInteractionChangesUsingBlock:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        if ([context percentComplete] >= 1.0)
        {
            NSArray *visibleCells = self.tableView.visibleCells;
            for (id<LegislatorCellProtocol> cell in visibleCells)
            {
                if ([cell conformsToProtocol:@protocol(LegislatorCellProtocol)])
                {
                    [cell redisplay];
                }
            }
        }
    }];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
	UINavigationController *nav = self.navigationController;
	if (nav && (nav.viewControllers).count > 3)
		[nav popToRootViewControllerAnimated:YES];
	
    [super didReceiveMemoryWarning];
}

- (CommitteeObj *)committee
{
    CommitteeObj *committee = SLValueIfClass(CommitteeObj, self.dataObject);
    if (committee)
        return committee;

    NSNumber *objectId = self.dataObjectID;
    if (!objectId)
        return nil;

    @try {
        committee = SLValueIfClass(CommitteeObj, [CommitteeObj objectWithPrimaryKeyValue:objectId]);
    }
    @catch (NSException * e) {
        debug_NSLog(@"Exception while fetching committee (ID = %@) from Core Data: %@", objectId, e);
    }
    return committee;
}

- (void)setDataObject:(id)newObj
{
    CommitteeObj *existingData = SLValueIfClass(CommitteeObj, _dataObject);
    CommitteeObj *newData = SLValueIfClass(CommitteeObj, newObj);

    _dataObject = newData;
    self.dataObjectID = (newData) ? newData.committeeId : nil;

    if (!self.isViewLoaded)
        return;

    if (existingData == newData || [newData isEqual:existingData])
        return;

    [self configureWithCommittee:newData];
}

- (void)setCommittee:(CommitteeObj *)committee
{
    [self setDataObject:committee];
}

- (void)configureWithCommittee:(CommitteeObj *)committee
{
    if (!self.isViewLoaded)
        return;

    [self buildInfoSectionArray];
    self.navigationItem.title = committee.committeeName;

    [self calcCommitteePartisanship];

    [self.tableView reloadData];
}

- (IBAction)resetTableData:(id)sender
{
    CommitteeObj *committee = self.committee;
    [self configureWithCommittee:committee];
}

- (void)buildInfoSectionArray
{
	BOOL isClickable = NO;

    CommitteeObj *committee = self.committee;

    NSMutableArray *tempArray = [@[] mutableCopy];
	NSDictionary *infoDict = nil;
	TableCellDataObject *cellInfo = nil;

//case CommitteeInfoRowName:
    NSString *text = SLTypeStringOrNil(committee.committeeName);
    if (!text)
        text = @"";

    infoDict = @{
                 @"title": text,
                 @"subtitle": NSLocalizedStringFromTable(@"Committee", @"DataTableUI", @"Cell title listing a legislative committee"),
                 @"isClickable": @NO,
                 @"entryValue": [NSNull null],
                 };
    cellInfo = [[TableCellDataObject alloc] initWithDictionary:infoDict];
    if (cellInfo)
        [tempArray addObject:cellInfo];

//case CommitteeInfoRowClerk:
	text = SLTypeStringOrNil(committee.clerk);
    if (!text)
        text = @"";
	NSString *email = SLTypeStringOrNil(committee.clerk_email);
    if (!email)
        email = @"";
	isClickable = (text.length && email.length);

    infoDict = @{
                 @"title": text,
                 @"subtitle": NSLocalizedStringFromTable(@"Clerk", @"DataTableUI", @"Cell title listing a committee's assigned clerk"),
                 @"isClickable": @(isClickable),
                 @"entryValue": email,
                 };
	cellInfo = [[TableCellDataObject alloc] initWithDictionary:infoDict];
    if (cellInfo)
        [tempArray addObject:cellInfo];
	
//case CommitteeInfoRowPhone:	// dial the number
	text = SLTypeStringOrNil(committee.phone);
    if (!text)
        text = @"";
	isClickable = (text.length && [UtilityMethods canMakePhoneCalls]);
    NSURL *url = (isClickable) ? [NSURL URLWithString:[@"tel:" stringByAppendingString:text]] : nil;

    infoDict = @{
                 @"title": text,
                 @"subtitle": NSLocalizedStringFromTable(@"Phone", @"DataTableUI", @"Cell title listing a phone number"),
                 @"isClickable": @(isClickable && url),
                 @"entryValue": (url) ? url : [NSNull null],
                 };

	cellInfo = [[TableCellDataObject alloc] initWithDictionary:infoDict];
    if (cellInfo)
        [tempArray addObject:cellInfo];
	
	//case CommitteeInfoRowLocation: // open the office map
	text = SLTypeStringOrNil(committee.office);
    if (!text)
        text = @"";

	isClickable = (text.length);
    CapitolMap *map = (isClickable) ? [CapitolMap mapFromOfficeString:text] : nil;

    infoDict = @{
                 @"title": text,
                 @"subtitle": NSLocalizedStringFromTable(@"Location", @"DataTableUI", @"Cell title listing an office location (office number or stree address)"),
                 @"isClickable": @(isClickable && map),
                 @"entryValue": (map) ? map : [NSNull null],
                 };

	cellInfo = [[TableCellDataObject alloc] initWithDictionary:infoDict];
    if (cellInfo)
        [tempArray addObject:cellInfo];
	
//case CommitteeInfoRowWebsite:	 // open the web page
    NSString *website = SLTypeStringOrNil(committee.url);
    if (!website)
        website = @"";
	isClickable = (website.length);
    url = (isClickable) ? [UtilityMethods safeWebUrlFromString:website] : nil;

    infoDict = @{
                 @"title": NSLocalizedStringFromTable(@"Website & Meetings", @"DataTableUI", @"Cell title for a website link detailing committee meetings"),
                 @"subtitle": NSLocalizedStringFromTable(@"Web", @"DataTableUI", @"Cell title listing a web address"),
                 @"isClickable": @(isClickable && url),
                 @"entryValue": (url) ? url : [NSNull null],
                 };
	cellInfo = [[TableCellDataObject alloc] initWithDictionary:infoDict];
    if (cellInfo)
        [tempArray addObject:cellInfo];
	
	self.infoSectionArray = [tempArray copy];
}

- (void)calcCommitteePartisanship
{
	NSSet *positions = self.committee.committeePositions;
	if (!positions.count)
		return;
	
	double avg = 0;
	double totalNum = 0;
	NSInteger totalLege = 0;
	for (CommitteePositionObj *position in positions)
    {
		double legePart = position.legislator.latestWnomFloat;
		if (legePart != 0)
        {
			totalNum += legePart;
			totalLege++;
		}
	}
	if (totalLege != 0)
    {
		avg = (totalNum / totalLege);
	}
	
	NSInteger democCount = 0, repubCount = 0;
	NSArray *repubs = [positions.allObjects findAllWhereKeyPath:@"legislator.party_id" equals:@(REPUBLICAN)];
	if (repubs.count)
    {
		repubCount = repubs.count;
        democCount = positions.count - repubCount;
    }
	
	NSString *repubString = stringForParty(REPUBLICAN, TLReturnAbbrevPlural);
	NSString *democString = stringForParty(DEMOCRAT, TLReturnAbbrevPlural);
	if (repubCount == 1)
		repubString = stringForParty(REPUBLICAN, TLReturnAbbrev);
	if (democCount == 1)
		democString = stringForParty(DEMOCRAT, TLReturnAbbrev);
	
	self.membershipLab.text = [NSString stringWithFormat:NSLocalizedStringFromTable(@"%d %@ and %d %@", @"DataTableUI", @"As in, 43 Republicans and 1 Democrat"), repubCount, repubString, democCount, democString];
	
    NSInteger chamber = self.committee.committeeType.integerValue;
	if (!IsEmpty(positions) && (chamber == HOUSE || chamber == SENATE))
    {
        PartisanIndexStats *indexStats = [PartisanIndexStats sharedPartisanIndexStats];
			
        CGFloat minSlider = [indexStats minPartisanIndexUsingChamber:chamber];
        CGFloat maxSlider = [indexStats maxPartisanIndexUsingChamber:chamber];

        self.partisanSlider.sliderMin = minSlider;
        self.partisanSlider.sliderMax = maxSlider;
        self.partisanSlider.hidden = NO;
	}
    else
    {
        // This would give inacurate results in joint committees, at least until we're in a common dimensional space
        self.partisanSlider.hidden = YES;
    }
	
	self.partisanSlider.sliderValue = avg;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    CommitteeObj *committee = self.committee;
    if (!committee)
        return 0;

    UInt16 sectionCount = 0;

    for (TXLCommitteeSections section = TXLCommitteeInfoSection; section < TXLCommitteeSectionMax; section++)
    {
        switch (section) {
            case TXLCommitteeInfoSection:
                if (self.infoSectionArray.count > 0)
                    sectionCount++;
                break;

            case TXLCommitteeChairSection:
                if (committee.chair)
                    sectionCount++;
                break;

            case TXLCommitteeViceChairSection:
                if (committee.vicechair)
                    sectionCount++;
                break;

            case TXLCommitteeMembersSection:
                if (committee.sortedMembers.count > 0)
                    sectionCount++;
                break;
        }
    }

    return sectionCount;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    CommitteeObj *committee = self.committee;
	UInt16 rows = 0;
	switch (section)
    {
        case TXLCommitteeInfoSection:
            rows = self.infoSectionArray.count;
            break;

		case TXLCommitteeChairSection:
			if (committee.chair)
				rows = 1;
			break;

		case TXLCommitteeViceChairSection:
			if (committee.vicechair)
				rows = 1;
			break;

		case TXLCommitteeMembersSection:
			rows = committee.sortedMembers.count;
			break;
	}
	
	return rows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSInteger row = indexPath.row;
	UInt16 section = indexPath.section;
    NSParameterAssert(section >= 0 || section < TXLCommitteeSectionMax);

    TXLCommitteeSections detailSection = section;

    NSString *reuseIdentifier = nil;
    UITableViewCellStyle style = UITableViewCellStyleValue2;
    CommitteeObj *committee = self.committee;
    LegislatorObj *legislator = nil;
    TableCellDataObject *infoObject = nil;

    switch (detailSection)
    {
        case TXLCommitteeChairSection:
            reuseIdentifier = TXLCommitteeMemberCellReuse;
            //style = UITableViewCellStyleSubtitle;
            legislator = [committee chair];
            break;

        case TXLCommitteeViceChairSection:
            reuseIdentifier = TXLCommitteeMemberCellReuse;
            //style = UITableViewCellStyleSubtitle;
            legislator = [committee vicechair];
            break;

        case TXLCommitteeMembersSection:
        {
            reuseIdentifier = TXLCommitteeMemberCellReuse;
            //style = UITableViewCellStyleSubtitle;
            NSArray * memberList = [committee sortedMembers];
            legislator = (memberList.count > row) ? memberList[row] : nil;
            break;
        }

        case TXLCommitteeInfoSection:
        {
            NSArray *rows = self.infoSectionArray;
            infoObject = (rows.count > row) ? [[TableCellDataObject alloc] initWithDictionary:rows[row]] : nil;
            if (infoObject.isClickable)
                reuseIdentifier = TXLCommitteeClickableInfoCellReuse;
            else
                reuseIdentifier = TXLCommitteeUnclickableInfoCellReuse;
            break;
        }
    }

	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier forIndexPath:indexPath];
    
    UITableViewCell<LegislatorCellProtocol> *legislatorCell = nil;
    if ([cell conformsToProtocol:@protocol(LegislatorCellProtocol)] && [cell respondsToSelector:@selector(setLegislator:)])
        legislatorCell = (UITableViewCell<LegislatorCellProtocol> *)cell;

    UITableViewCell<TexLegeGroupCellProtocol> *infoCell = nil;
    if ([cell conformsToProtocol:@protocol(TexLegeGroupCellProtocol)] && [cell respondsToSelector:@selector(setCellInfo:)])
        infoCell = (UITableViewCell<TexLegeGroupCellProtocol> *)cell;

#if 0
	if (cell == nil)
    {
		if ([reuseIdentifier isEqualToString:@"CommitteeMember"])
        {
			if (![UtilityMethods isIPadDevice])
            {
				LegislatorMasterCell *newcell = [[LegislatorMasterCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
				newcell.frame = CGRectMake(0.0, 0.0, 234.0, quartzRowHeight);		
				newcell.cellView.useDarkBackground = NO;
				newcell.accessoryView.hidden = NO;
                legislatorCell = newcell;
				cell = newcell;
			}
			else
            {
				CommitteeMemberCell *newcell = [[CommitteeMemberCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
				newcell.frame = CGRectMake(0.0, 0.0, kCommitteeMemberCellViewWidth, quartzRowHeight);		
				newcell.accessoryView.hidden = NO;
                legislatorCell = newcell;
				cell = newcell;
			}
		}
		else
        {
            infoCell = [[TexLegeStandardGroupCell alloc] initWithStyle:style reuseIdentifier:reuseIdentifier];
            cell = infoCell;
		}

		cell.backgroundColor = [TexLegeTheme backgroundLight];
	}    
#endif

    if (infoCell)
        [infoCell setCellInfo:infoObject];
	if (legislatorCell)
        [legislatorCell setLegislator:legislator];
	
	return cell;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	NSString * sectionName = nil;
    BOOL isJointCommittee = (self.committee.committeeType.integerValue == JOINT);
    NSString *committeeType = SLTypeStringOrNil(self.committee.typeString) ?: @"";

    NSParameterAssert(section >= 0 || section < TXLCommitteeSectionMax);
    TXLCommitteeSections detailSection = section;
	switch (detailSection)
    {
		case TXLCommitteeChairSection:
			if (isJointCommittee)
				sectionName = NSLocalizedStringFromTable(@"Co-Chair", @"DataTableUI", @"For joint committees, House and Senate leaders are co-chair persons");
			else
				sectionName = NSLocalizedStringFromTable(@"Chair", @"DataTableUI", @"Cell title for a person who leads a given committee, an abbreviation for Chairperson");
            break;

		case TXLCommitteeViceChairSection:
            if (isJointCommittee)
				sectionName = NSLocalizedStringFromTable(@"Co-Chair", @"DataTableUI", @"For joint committees, House and Senate leaders are co-chair persons");
			else
				sectionName = NSLocalizedStringFromTable(@"Vice Chair", @"DataTableUI", @"Cell title for a person who is second in command of a given committee, behind the Chairperson");
            break;

		case TXLCommitteeMembersSection:
			sectionName = NSLocalizedStringFromTable(@"Members", @"DataTableUI", nil);
			break;

		case TXLCommitteeInfoSection:
            sectionName = [NSString stringWithFormat:NSLocalizedStringFromTable(@"%@ Committee Info", @"DataTableUI", nil),
							   committeeType];
			break;
	}
	return sectionName;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (indexPath.section > TXLCommitteeInfoSection)
		return quartzRowHeight;
	
	return 44.0f;
}

- (void)pushMapViewWithMap:(CapitolMap *)capMap
{
	CapitolMapsDetailViewController *detailController = [[CapitolMapsDetailViewController alloc] initWithNibName:@"CapitolMapsDetailViewController" bundle:nil];
	detailController.map = capMap;
	[self.navigationController pushViewController:detailController animated:YES];
}

- (void)pushInternalBrowserWithURL:(NSURL *)url
{
	if (!SLTypeURLOrNil(url) || ![TexLegeReachability canReachHostWithURL:url])
        return;

    UIViewController *webController = nil;

    if ([url.scheme hasPrefix:@"http"])
        webController = [[SFSafariViewController alloc] initWithURL:url];
    else // can't use anything except http: or https: with SFSafariViewControllers
    {
        NSString *urlString = url.absoluteString;
        if (urlString.length)
            webController = [[SVWebViewController alloc] initWithAddress:urlString];
    }
    if (!webController)
        return;
    webController.modalPresentationStyle = UIModalPresentationPageSheet;
    [self presentViewController:webController animated:YES completion:nil];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)newIndexPath
{
    [tableView deselectRowAtIndexPath:newIndexPath animated:YES];

    NSInteger row = newIndexPath.row;
	NSInteger section = newIndexPath.section;
    CommitteeObj *committee = self.committee;

	if (section == TXLCommitteeInfoSection)
    {
        NSArray *rows = self.infoSectionArray;
        if (rows.count <= row)
            return;

        TableCellDataObject *cellInfo = rows[row];
		if (!cellInfo || !cellInfo.isClickable)
			return;
		
		switch (row)
        {
			case CommitteeInfoRowClerk:
            {
                NSString *email = SLTypeNonEmptyStringOrNil(cellInfo.entryValue);
                if (email)
                    [[TexLegeEmailComposer sharedTexLegeEmailComposer] presentMailComposerTo:email subject:@"" body:@"" commander:self];
				break;
            }
			case CommitteeInfoRowPhone:
            {
                NSURL *url = SLTypeURLOrNil(cellInfo.entryValue);
				if (url && [UtilityMethods canMakePhoneCalls])
                {
                    [UtilityMethods openURLWithoutTrepidation:url];
				}
                break;
			}
            case CommitteeInfoRowLocation:
            {
				CapitolMap *capMap = SLValueIfClass(CapitolMap, cellInfo.entryValue);
                if (capMap)
                    [self pushMapViewWithMap:capMap];
                break;
			}
			case CommitteeInfoRowWebsite:
            {
                NSURL *url = SLTypeURLOrNil(cellInfo.entryValue);
                if (url)
                    [self pushInternalBrowserWithURL:url];
                break;
			}
			default:
				break;
		}
		
	}
	else
    {
		LegislatorDetailViewController *subDetailController = [[LegislatorDetailViewController alloc] initWithNibName:@"LegislatorDetailViewController" bundle:nil];
		
		switch (section)
        {
			case TXLCommitteeChairSection:
				subDetailController.legislator = [committee chair];
				break;
			case TXLCommitteeViceChairSection:
				subDetailController.legislator = [committee vicechair];
				break;
			case TXLCommitteeMembersSection:
            {
                NSArray *members = committee.sortedMembers;
                if (members.count > row)
                    subDetailController.legislator = [committee sortedMembers][row];
                break;
            }
		}
		
		[self.navigationController pushViewController:subDetailController animated:YES];
    }
}

@end
