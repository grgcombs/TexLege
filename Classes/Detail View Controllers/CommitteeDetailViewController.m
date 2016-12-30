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
#import <SafariServices/SFSafariViewController.h>

@implementation CommitteeDetailViewController

//@synthesize dataObjectID, masterPopover;
//@synthesize partisanSlider, membershipLab, infoSectionArray;

enum Sections {
    //kHeaderSection = 0,
	kInfoSection = 0,
    kChairSection,
    kViceChairSection,
	kMembersSection,
    NUM_SECTIONS
};

typedef NS_ENUM(NSInteger, CommitteeInfoRow) {
    CommitteeInfoRowName = 0,
    CommitteeInfoRowClerk,
    CommitteeInfoRowPhone,
    CommitteeInfoRowLocation,
    CommitteeInfoRowWebsite,
    COMMITTEE_INFO_ROW_COUNT
};

CGFloat quartzRowHeight = 73.f;

- (NSString *)nibName
{
	if ([UtilityMethods isIPadDevice])
		return @"CommitteeDetailViewController~ipad";
	else
		return @"CommitteeDetailViewController~iphone";	
}

#pragma mark -
#pragma mark View lifecycle

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
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
    // Relinquish ownership any cached data, images, etc that aren't in use.
}

/*
 - (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
 [self showPopoverMenus:UIDeviceOrientationIsPortrait(toInterfaceOrientation)];
 }
 */

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
	//[self showPopoverMenus:UIDeviceOrientationIsPortrait(toInterfaceOrientation)];
	//[[TexLegeAppDelegate appDelegate] resetPopoverMenus];
	
	NSArray *visibleCells = self.tableView.visibleCells;
	for (id<LegislatorCellProtocol> cell in visibleCells)
    {
		if ([cell conformsToProtocol:@protocol(LegislatorCellProtocol)])
        {
            [cell redisplay];
        }
	}
	
}

// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

#pragma mark -
#pragma mark Data Objects

- (id)dataObject
{
	return self.committee;
}

- (void)setDataObject:(id)newObj
{
	self.committee = newObj;
}

- (void)resetTableData:(NSNotification *)notification
{
	if (self.dataObject)
    {
		self.dataObject = self.dataObject;
	}
}

- (CommitteeObj *)committee
{
	CommitteeObj *anObject = nil;
	if (self.dataObjectID)
    {
		@try {
			anObject = [CommitteeObj objectWithPrimaryKeyValue:self.dataObjectID];
		}
		@catch (NSException * e) {
		}
	}
	return anObject;
}

- (void)setCommittee:(CommitteeObj *)newObj
{
	self.dataObjectID = nil;
	if (newObj)
    {
        if (!self.isViewLoaded)
            [self loadView];

		if (self.masterPopover)
			[self.masterPopover dismissPopoverAnimated:YES];

		self.dataObjectID = newObj.committeeId;
		
		[self buildInfoSectionArray];
		self.navigationItem.title = newObj.committeeName;
		
		[self calcCommitteePartisanship];
		
		[self.tableView reloadData];
		[self.view setNeedsDisplay];
	}
}

#pragma mark -
#pragma mark Popover Support

- (void)splitViewController: (UISplitViewController*)svc willHideViewController:(UIViewController *)aViewController withBarButtonItem:(UIBarButtonItem*)barButtonItem forPopoverController: (UIPopoverController*)pc
{
	//debug_NSLog(@"Entering portrait, showing the button: %@", [aViewController class]);
    barButtonItem.title = @"Committees";
    [self.navigationItem setRightBarButtonItem:barButtonItem animated:YES];
    self.masterPopover = pc;
}


// Called when the view is shown again in the split view, invalidating the button and popover controller.
- (void)splitViewController: (UISplitViewController*)svc willShowViewController:(UIViewController *)aViewController invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem
{
	//debug_NSLog(@"Entering landscape, hiding the button: %@", [aViewController class]);
    [self.navigationItem setRightBarButtonItem:nil animated:YES];
    self.masterPopover = nil;
}

- (void) splitViewController:(UISplitViewController *)svc popoverController: (UIPopoverController *)pc
   willPresentViewController: (UIViewController *)aViewController
{
	if ([UtilityMethods isLandscapeOrientation])
    {
		[[LocalyticsSession sharedLocalyticsSession] tagEvent:@"ERR_POPOVER_IN_LANDSCAPE"];
	}		 
}	

#pragma mark -
#pragma mark View Setup

- (void)buildInfoSectionArray
{
	BOOL clickable = NO;
	
	NSMutableArray *tempArray = [[NSMutableArray alloc] initWithCapacity:12]; // arbitrary
	NSDictionary *infoDict = nil;
	TableCellDataObject *cellInfo = nil;
//case CommitteeInfoRowName:
	infoDict = [[NSDictionary alloc] initWithObjectsAndKeys:
				NSLocalizedStringFromTable(@"Committee", @"DataTableUI", @"Cell title listing a legislative committee"), @"subtitle",
				self.committee.committeeName, @"title",
				@NO, @"isClickable",
				nil, @"entryValue",
				nil];
	cellInfo = [[TableCellDataObject alloc] initWithDictionary:infoDict];
	[tempArray addObject:cellInfo];

//case CommitteeInfoRowClerk:
	NSString *text = self.committee.clerk;
	id val = self.committee.clerk_email;
	clickable = (text && text.length && val && [val length]);
	if (!text)
		text = @"";
	if (!val)
		val = @"";
	infoDict = [[NSDictionary alloc] initWithObjectsAndKeys:
				NSLocalizedStringFromTable(@"Clerk", @"DataTableUI", @"Cell title listing a committee's assigned clerk"), @"subtitle",
				text, @"title",
				@(clickable), @"isClickable",
				val, @"entryValue",
				nil];
	cellInfo = [[TableCellDataObject alloc] initWithDictionary:infoDict];
	[tempArray addObject:cellInfo];
	
//case CommitteeInfoRowPhone:	// dial the number
	text = self.committee.phone;
	clickable = (text && text.length && [UtilityMethods canMakePhoneCalls]);
	if (!text)
		text = @"";
	if (clickable)
		val = [NSURL URLWithString:[NSString stringWithFormat:@"tel:%@",text]];
	else
		val = @"";
	infoDict = [[NSDictionary alloc] initWithObjectsAndKeys:
				NSLocalizedStringFromTable(@"Phone", @"DataTableUI", @"Cell title listing a phone number"), @"subtitle",
				text, @"title",
				@(clickable), @"isClickable",
				val, @"entryValue",
				nil];
	cellInfo = [[TableCellDataObject alloc] initWithDictionary:infoDict];
	[tempArray addObject:cellInfo];
	
	//case CommitteeInfoRowLocation: // open the office map
	text = self.committee.office;
	clickable = (text && text.length);
	if (!text)
		text = @"";
	if (clickable)
		val = [CapitolMap mapFromOfficeString:self.committee.office];
	else
		val = @"";
	
	infoDict = [[NSDictionary alloc] initWithObjectsAndKeys:
				NSLocalizedStringFromTable(@"Location", @"DataTableUI", @"Cell title listing an office location (office number or stree address)"), @"subtitle",
				text, @"title",
				@(clickable), @"isClickable",
				val, @"entryValue",
				nil];
	cellInfo = [[TableCellDataObject alloc] initWithDictionary:infoDict];
	[tempArray addObject:cellInfo];
	
//case CommitteeInfoRowWebsite:	 // open the web page
	clickable = (text && text.length);
	if (clickable)
		val = [UtilityMethods safeWebUrlFromString:self.committee.url];
	else
		val = @"";
	infoDict = [[NSDictionary alloc] initWithObjectsAndKeys:
				NSLocalizedStringFromTable(@"Web", @"DataTableUI", @"Cell title listing a web address"), @"subtitle",
				NSLocalizedStringFromTable(@"Website & Meetings", @"DataTableUI", @"Cell title for a website link detailing committee meetings"), @"title",
				@(clickable), @"isClickable",
				val, @"entryValue",
				nil];
	cellInfo = [[TableCellDataObject alloc] initWithDictionary:infoDict];
	[tempArray addObject:cellInfo];
	
	if (self.infoSectionArray)
		self.infoSectionArray = nil;
	self.infoSectionArray = tempArray;
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

#pragma mark -
#pragma mark Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return NUM_SECTIONS;
}

- (NSInteger)tableView:(UITableView *)tableView  numberOfRowsInSection:(NSInteger)section
{
    CommitteeObj *committee = self.committee;

	NSInteger rows = 0;	
	switch (section)
    {
		case kChairSection:
			if ([committee chair] != nil)
				rows = 1;
			break;
		case kViceChairSection:
			if ([committee vicechair] != nil)
				rows = 1;
			break;
		case kMembersSection:
			rows = committee.sortedMembers.count ;
			break;
		case kInfoSection:
			rows = COMMITTEE_INFO_ROW_COUNT;
			break;
		default:
			rows = 0;
			break;
	}
	
	return rows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSInteger row = indexPath.row;
	NSInteger section = indexPath.section;


	NSInteger InfoSectionEnd = ([UtilityMethods canMakePhoneCalls]) ? CommitteeInfoRowClerk : CommitteeInfoRowPhone;
	
    NSString *CellIdentifier = nil;
	if (section > kInfoSection)
		CellIdentifier = @"CommitteeMember";
	else if (row > InfoSectionEnd)
		CellIdentifier = @"CommitteeInfo";
	else // the non-clickable / no disclosure items
		CellIdentifier = @"Committee-NoDisclosure";
	
	UITableViewCellStyle style = section > kInfoSection ? UITableViewCellStyleSubtitle : UITableViewCellStyleValue2;
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];

	if (cell == nil)
    {
		if ([CellIdentifier isEqualToString:@"CommitteeMember"])
        {
			if (![UtilityMethods isIPadDevice])
            {
				LegislatorMasterCell *newcell = [[LegislatorMasterCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
				newcell.frame = CGRectMake(0.0, 0.0, 234.0, quartzRowHeight);		
				newcell.cellView.useDarkBackground = NO;
				newcell.accessoryView.hidden = NO;
				cell = newcell;
			}
			else
            {
				CommitteeMemberCell *newcell = [[CommitteeMemberCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
				newcell.frame = CGRectMake(0.0, 0.0, kCommitteeMemberCellViewWidth, quartzRowHeight);		
				newcell.accessoryView.hidden = NO;
				cell = newcell;
			}
		}
		else
        {
			cell = (UITableViewCell *)[[TexLegeStandardGroupCell alloc] initWithStyle:style reuseIdentifier:CellIdentifier];			
		}

		cell.backgroundColor = [TexLegeTheme backgroundLight];
		
	}    

    CommitteeObj *committee = self.committee;
	LegislatorObj *legislator = nil;
	
	switch (section)
    {
		case kChairSection:
			legislator = [committee chair];
			break;

		case kViceChairSection:
			legislator = [committee vicechair];
			break;

		case kMembersSection:
        {
			NSArray * memberList = [committee sortedMembers];
			if (memberList.count > row)
				legislator = memberList[row];
            break;
        }

        case kInfoSection:
        {
            NSArray *rows = self.infoSectionArray;
			if (rows.count > row)
            {
				NSDictionary *cellInfo = rows[row];
				if ([cell respondsToSelector:@selector(setCellInfo:)])
					[cell performSelector:@selector(setCellInfo:) withObject:cellInfo];
			}
            break;
		}

		default:
			cell.autoresizingMask = UIViewAutoresizingFlexibleHeight;
			cell.hidden = YES;
			cell.frame  = CGRectMake(cell.frame.origin.x, cell.frame.origin.y, 0.01f, 0.01f);
			cell.tag = 999; //EMPTY
			[cell sizeToFit];
			cell.selectionStyle = UITableViewCellSelectionStyleNone;
			return cell;
			break;
	}
	
	if (legislator && [cell respondsToSelector:@selector(setLegislator:)])
    {
        [cell performSelector:@selector(setLegislator:) withObject:legislator];
	}	
	
	return cell;
}


- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}



#pragma mark -
#pragma mark Table view delegate

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	NSString * sectionName;
	
	switch (section)
    {
		case kChairSection:
        {
			if ((self.committee.committeeType).integerValue == JOINT)
				sectionName = NSLocalizedStringFromTable(@"Co-Chair", @"DataTableUI", @"For joint committees, House and Senate leaders are co-chair persons");
			else
				sectionName = NSLocalizedStringFromTable(@"Chair", @"DataTableUI", @"Cell title for a person who leads a given committee, an abbreviation for Chairperson");
            break;
		}

		case kViceChairSection:
        {
			if ((self.committee.committeeType).integerValue == JOINT)
				sectionName = NSLocalizedStringFromTable(@"Co-Chair", @"DataTableUI", @"For joint committees, House and Senate leaders are co-chair persons");
			else
				sectionName = NSLocalizedStringFromTable(@"Vice Chair", @"DataTableUI", @"Cell title for a person who is second in command of a given committee, behind the Chairperson");
            break;
		}
		case kMembersSection:
			sectionName = @"Members";
			break;

		case kInfoSection:
		default:
			if (self.committee.parentId.integerValue == -1) 
				sectionName = [NSString stringWithFormat:NSLocalizedStringFromTable(@"%@ Committee Info",@"DataTableUI", @"Information for a given legislative committee"),
							   [self.committee typeString]];
			else
				sectionName = [NSString stringWithFormat:NSLocalizedStringFromTable(@"%@ Subcommittee Info",@"DataTableUI", @"Information for a given legislative subcommittee"),
							   [self.committee typeString]];			
			break;
	}
	return sectionName;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (indexPath.section > kInfoSection)
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
	if ([TexLegeReachability canReachHostWithURL:url])
    {
		NSString *urlString = url.absoluteString;
		
        NSURL *url = [NSURL URLWithString:urlString];
        if (!url)
            return;
        
        UIViewController *webController = nil;
        
        if ([url.scheme hasPrefix:@"http"])
            webController = [[SFSafariViewController alloc] initWithURL:url];
        else // can't use anything except http: or https: with SFSafariViewControllers
            webController = [[SVWebViewController alloc] initWithAddress:urlString];
        
        webController.modalPresentationStyle = UIModalPresentationPageSheet;
        [self presentViewController:webController animated:YES completion:nil];
	}
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)newIndexPath
{
    [tableView deselectRowAtIndexPath:newIndexPath animated:YES];

    NSInteger row = newIndexPath.row;
	NSInteger section = newIndexPath.section;
    CommitteeObj *committee = self.committee;

	if (section == kInfoSection)
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
				[[TexLegeEmailComposer sharedTexLegeEmailComposer] presentMailComposerTo:cellInfo.entryValue 
																				 subject:@""
                                                                                    body:@""
                                                                               commander:self];
				break;
			case CommitteeInfoRowPhone:
            {
				if ([UtilityMethods canMakePhoneCalls])
                {
					NSURL *myURL = cellInfo.entryValue;
					[UtilityMethods openURLWithoutTrepidation:myURL];
				}
                break;
			}
            case CommitteeInfoRowLocation:
            {
				CapitolMap *capMap = cellInfo.entryValue;
				[self pushMapViewWithMap:capMap];
                break;
			}
			case CommitteeInfoRowWebsite:
            {
				NSURL *myURL = cellInfo.entryValue;
				[self pushInternalBrowserWithURL:myURL];
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
			case kChairSection:
				subDetailController.legislator = [committee chair];
				break;
			case kViceChairSection:
				subDetailController.legislator = [committee vicechair];
				break;
			case kMembersSection:
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
