//
//  LegislatorDetailDataSource.m
//  Created by Gregory Combs on 8/29/10.
//
//  StatesLege by Sunlight Foundation, based on work at https://github.com/sunlightlabs/StatesLege
//
//  This work is licensed under the Creative Commons Attribution-NonCommercial 3.0 Unported License. 
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc/3.0/
//  or send a letter to Creative Commons, 444 Castro Street, Suite 900, Mountain View, California, 94041, USA.
//
//

#import "LegislatorDetailDataSource.h"
#import "TexLegeCoreDataUtils.h"

#import "LegislatorObj+RestKit.h"
#import "TexLegeTheme.h"
#import "DistrictMapObj+RestKit.h"

#import "StafferObj.h"
#import "DistrictOfficeObj+MapKit.h"
#import "CommitteeObj+RestKit.h"
#import "CommitteePositionObj+RestKit.h"
#import "WnomObj+RestKit.h"

#import "UtilityMethods.h"
#import "TableCellDataObject.h"
#import "TexLegeAppDelegate.h"

#import "PartisanIndexStats.h"
#import "UIImage+ResolutionIndependent.h"

#import "TexLegeStandardGroupCell.h"
#import "TexLegeGroupCellProtocol.h"
#import "CapitolMap.h"
#import "NotesViewController.h"

@interface LegislatorDetailDataSource (Private)
- (void) createSectionList;
@end


@implementation LegislatorDetailDataSource
@synthesize dataObjectID, sectionArray;

- (id)initWithLegislator:(LegislatorObj *)newObject {
	if ((self = [super init])) {
		if (newObject) 
			[self setLegislator:newObject];
	}
	return self;
}

- (void)dealloc {
	self.sectionArray = nil;
	self.dataObjectID = nil;
	
    [super dealloc];
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

- (void)setLegislator:(LegislatorObj *)newLegislator {
	self.dataObjectID = nil;
	if (newLegislator) {
		self.dataObjectID = newLegislator.legislatorID;
		
		[self createSectionList];		
	}
}

- (void) createSectionList {	
	NSInteger numberOfSections = 4 + [self.legislator numberOfDistrictOffices];
	
	NSString *tempString = nil;
	BOOL isPhone = [UtilityMethods canMakePhoneCalls];
	TableCellDataObject *cellInfo = nil;
	
	// create an array of sections, with arrays of DirectoryDetailInfo entries as contents
	self.sectionArray = nil;	// this calls removeAllObjects and release automatically
	self.sectionArray = [NSMutableArray arrayWithCapacity:numberOfSections];
	
	NSInteger i;
	for (i=0; i < numberOfSections; i++) {
		[self.sectionArray addObject:[NSMutableArray arrayWithCapacity:30]]; // just an arbitrary maximum
	}
	
	/*	Section 0: Personal Information */		
	NSInteger sectionIndex = 0;	
	
	NSDictionary *entryDict = [[NSDictionary alloc] initWithObjectsAndKeys:
							   NSLocalizedStringFromTable(@"Name", @"DataTableUI", @"Title for cell"), @"subtitle",
							   [self.legislator fullName], @"entryValue",
							   [self.legislator fullName], @"title",
							   [NSNumber numberWithBool:NO], @"isClickable",
							   [NSNumber numberWithInteger:DirectoryTypeNone], @"entryType",
							   nil];
	cellInfo = [[TableCellDataObject alloc] initWithDictionary:entryDict];
	[entryDict release];
    if (self.sectionArray.count > sectionIndex)
        [[self.sectionArray objectAtIndex:sectionIndex] addObject:cellInfo];
	[cellInfo release], cellInfo = nil;
	
	
	entryDict = [[NSDictionary alloc] initWithObjectsAndKeys:
				 NSLocalizedStringFromTable(@"Map", @"DataTableUI", @"Title for cell"), @"subtitle",
				 self.legislator.districtMap, @"entryValue",
				 NSLocalizedStringFromTable(@"District Map", @"DataTableUI", @"Title for cell"), @"title",
				 [NSNumber numberWithBool:YES], @"isClickable",
				 [NSNumber numberWithInteger:DirectoryTypeMap], @"entryType",
				 nil];
	cellInfo = [[TableCellDataObject alloc] initWithDictionary:entryDict];
	[entryDict release];
    if (self.sectionArray.count > sectionIndex)
        [[self.sectionArray objectAtIndex:sectionIndex] addObject:cellInfo];
	[cellInfo release], cellInfo = nil;
	
	
	if (self.legislator && self.legislator.transDataContributorID) {
		entryDict = [[NSDictionary alloc] initWithObjectsAndKeys:
					 NSLocalizedStringFromTable(@"Finances", @"DataTableUI", @"Title for Cell"), @"subtitle",
					 self.legislator.transDataContributorID, @"entryValue",
					 NSLocalizedStringFromTable(@"Campaign Contributions", @"DataTableUI", @"title for cell"), @"title",
					 [NSNumber numberWithBool:YES], @"isClickable",
					 [NSNumber numberWithInteger:DirectoryTypeContributions], @"entryType",
					 nil];
		cellInfo = [[TableCellDataObject alloc] initWithDictionary:entryDict];
		[entryDict release];
        if (self.sectionArray.count > sectionIndex)
            [[self.sectionArray objectAtIndex:sectionIndex] addObject:cellInfo];
		[cellInfo release], cellInfo = nil;
		
	}
	
	entryDict = [[NSDictionary alloc] initWithObjectsAndKeys:
				 NSLocalizedStringFromTable(@"Email", @"DataTableUI", @"Title for Cell"), @"subtitle",
				 self.legislator.email, @"entryValue",
				 self.legislator.email, @"title",
				 [NSNumber numberWithBool:YES], @"isClickable",
				 [NSNumber numberWithInteger:DirectoryTypeMail], @"entryType",
				 nil];
	cellInfo = [[TableCellDataObject alloc] initWithDictionary:entryDict];
	[entryDict release];
    if (self.sectionArray.count > sectionIndex)
        [[self.sectionArray objectAtIndex:sectionIndex] addObject:cellInfo];
	[cellInfo release], cellInfo = nil;
	
	
	
	if (self.legislator && self.legislator.twitter && [self.legislator.twitter length]) {
		tempString = ([self.legislator.twitter hasPrefix:@"@"]) ? self.legislator.twitter : [[[NSString alloc] initWithFormat:@"@%@", self.legislator.twitter] autorelease];
		entryDict = [[NSDictionary alloc] initWithObjectsAndKeys:
					 NSLocalizedStringFromTable(@"Twitter", @"DataTableUI", @"Title for Cell"), @"subtitle",
					 tempString, @"entryValue",
					 tempString, @"title",
					 [NSNumber numberWithBool:YES], @"isClickable",
					 [NSNumber numberWithInteger:DirectoryTypeTwitter], @"entryType",
					 nil];
		cellInfo = [[TableCellDataObject alloc] initWithDictionary:entryDict];
		[entryDict release];
        if (self.sectionArray.count > sectionIndex)
            [[self.sectionArray objectAtIndex:sectionIndex] addObject:cellInfo];
		[cellInfo release], cellInfo = nil;
		
	}
	
	entryDict = [[NSDictionary alloc] initWithObjectsAndKeys:
				 NSLocalizedStringFromTable(@"Web", @"DataTableUI", @"Title for Cell, As in, a web address"), @"subtitle",
				 self.legislator.website, @"entryValue",
				 NSLocalizedStringFromTable(@"Official Website", @"DataTableUI", @"Title for Cell"), @"title",
				 [NSNumber numberWithBool:YES], @"isClickable",
				 [NSNumber numberWithInteger:DirectoryTypeWeb], @"entryType",
				 nil];
	cellInfo = [[TableCellDataObject alloc] initWithDictionary:entryDict];
	[entryDict release];
    if (self.sectionArray.count > sectionIndex)
        [[self.sectionArray objectAtIndex:sectionIndex] addObject:cellInfo];
	[cellInfo release], cellInfo = nil;
	
		
		
	entryDict = [[NSDictionary alloc] initWithObjectsAndKeys:
				 NSLocalizedStringFromTable(@"Web", @"DataTableUI", @"Title for cell, As in, a web adress"), @"subtitle",
				 self.legislator.bio_url, @"entryValue",
				 NSLocalizedStringFromTable(@"Votesmart Bio", @"DataTableUI", @"Title for cell, Biographical information available at VoteSmart.org"), @"title",
				 [NSNumber numberWithBool:YES], @"isClickable",
				 [NSNumber numberWithInteger:DirectoryTypeWeb], @"entryType",
				 nil];
	cellInfo = [[TableCellDataObject alloc] initWithDictionary:entryDict];
	[entryDict release];
    if (self.sectionArray.count > sectionIndex)
        [[self.sectionArray objectAtIndex:sectionIndex] addObject:cellInfo];
	[cellInfo release], cellInfo = nil;
	
	entryDict = [[NSDictionary alloc] initWithObjectsAndKeys:
				 NSLocalizedStringFromTable(@"Legislation", @"DataTableUI", @"Title for cell, Bills and resolutions this person has authored"), @"subtitle",
				 self.legislator.openstatesID, @"entryValue",
				 NSLocalizedStringFromTable(@"Authored Bills", @"DataTableUI", @"Title for cell, Bills and resolutions this person has authored"), @"title",
				 [NSNumber numberWithBool:YES], @"isClickable",
				 [NSNumber numberWithInteger:DirectoryTypeBills], @"entryType",
				 nil];
	cellInfo = [[TableCellDataObject alloc] initWithDictionary:entryDict];
	[entryDict release];
    if (self.sectionArray.count > sectionIndex)
        [[self.sectionArray objectAtIndex:sectionIndex] addObject:cellInfo];
	[cellInfo release], cellInfo = nil;
	
	tempString = nil;
	[[NSUserDefaults standardUserDefaults] synchronize];	
	NSDictionary *storedNotesDict = [[NSUserDefaults standardUserDefaults] valueForKey:@"LEGE_NOTES"];
	if (storedNotesDict) {
		tempString = [storedNotesDict valueForKey:[self.legislator.legislatorID stringValue]];
	}
	if (IsEmpty(tempString)) {
		tempString = kStaticNotes;
	}
	entryDict = [[NSDictionary alloc] initWithObjectsAndKeys:
				 NSLocalizedStringFromTable(@"Notes", @"DataTableUI", @"Title for the cell indicating custom notes option"), @"subtitle",
				 tempString, @"entryValue",
				 tempString, @"title",
				 [NSNumber numberWithBool:YES], @"isClickable",
				 [NSNumber numberWithInteger:DirectoryTypeNotes], @"entryType",
				 nil];
	cellInfo = [[TableCellDataObject alloc] initWithDictionary:entryDict];
	[entryDict release];
    if (self.sectionArray.count > sectionIndex)
        [[self.sectionArray objectAtIndex:sectionIndex] addObject:cellInfo];
	[cellInfo release], cellInfo = nil;
	
	
	/* after that section's done... DO COMMITTEES */
	sectionIndex++;
	for (CommitteePositionObj *position in [self.legislator sortedCommitteePositions]) {
		entryDict = [[NSDictionary alloc] initWithObjectsAndKeys:
					 [position positionString], @"subtitle",
					 [position committee], @"entryValue",
					 [position.committee committeeName], @"title",
					 [NSNumber numberWithBool:YES], @"isClickable",
					 [NSNumber numberWithInteger:DirectoryTypeCommittee], @"entryType",
					 nil];
		cellInfo = [[TableCellDataObject alloc] initWithDictionary:entryDict];
		[entryDict release];
        if (self.sectionArray.count > sectionIndex)
            [[self.sectionArray objectAtIndex:sectionIndex] addObject:cellInfo];
		[cellInfo release], cellInfo = nil;
	}
	
	/* Now we handle all the office locations ... */
	sectionIndex++;
	/*	Section 1: Staffers */
	
	if ([self.legislator numberOfStaffers] > 0) {
		for (StafferObj *staffer in [self.legislator sortedStaffers]) {
			entryDict = [[NSDictionary alloc] initWithObjectsAndKeys:
						 staffer.title, @"subtitle",
						 staffer.email, @"entryValue",
						 staffer.name, @"title",
						 [NSNumber numberWithBool:YES], @"isClickable",
						 [NSNumber numberWithInteger:DirectoryTypeMail], @"entryType",
						 nil];
			cellInfo = [[TableCellDataObject alloc] initWithDictionary:entryDict];
			[entryDict release];
            if (self.sectionArray.count > sectionIndex)
                [[self.sectionArray objectAtIndex:sectionIndex] addObject:cellInfo];
			[cellInfo release], cellInfo = nil;
		}
	}
	else {
		entryDict = [[NSDictionary alloc] initWithObjectsAndKeys:
					 NSLocalizedStringFromTable(@"Staff", @"DataTableUI", @"Office employees"), @"subtitle",
					 @"NoneListed", @"entryValue",
					 NSLocalizedStringFromTable(@"No Staff Listed", @"DataTableUI", @"Title for cell indicating this person hasn't publish a list of office employees"), 
							@"title", [NSNumber numberWithBool:NO], @"isClickable",
					 [NSNumber numberWithInteger:DirectoryTypeNone], @"entryType",
					 nil];
		cellInfo = [[TableCellDataObject alloc] initWithDictionary:entryDict];
		[entryDict release];
        if (self.sectionArray.count > sectionIndex)
            [[self.sectionArray objectAtIndex:sectionIndex] addObject:cellInfo];
		[cellInfo release], cellInfo = nil;
	}
		
	/* Now we handle all the office locations ... */
	sectionIndex++;
	/*	Section 2: Capitol Office */		
		
	if (self.legislator && self.legislator.cap_office && [self.legislator.cap_office length]) {
		entryDict = [[NSDictionary alloc] initWithObjectsAndKeys:
					 NSLocalizedStringFromTable(@"Office", @"DataTableUI", @"The person's office number, indicating the location inside the building"), @"subtitle",
					 [CapitolMap mapFromOfficeString:self.legislator.cap_office], @"entryValue",
					 self.legislator.cap_office, @"title",
					 [NSNumber numberWithBool:YES], @"isClickable",
					 [NSNumber numberWithInteger:DirectoryTypeOfficeMap], @"entryType",
					 nil];
		cellInfo = [[TableCellDataObject alloc] initWithDictionary:entryDict];
		[entryDict release];
        if (self.sectionArray.count > sectionIndex)
            [[self.sectionArray objectAtIndex:sectionIndex] addObject:cellInfo];
		[cellInfo release], cellInfo = nil;
	} 
	if (self.legislator && self.legislator.cap_phone && [self.legislator.cap_phone length]) {
		entryDict = [[NSDictionary alloc] initWithObjectsAndKeys:
					 NSLocalizedStringFromTable(@"Phone", @"DataTableUI", @"Cell title listing a phone number"), @"subtitle",
					 self.legislator.cap_phone, @"entryValue",
					 self.legislator.cap_phone, @"title",
					 [NSNumber numberWithBool:isPhone], @"isClickable",
					 [NSNumber numberWithInteger:DirectoryTypePhone], @"entryType",
					 nil];
		cellInfo = [[TableCellDataObject alloc] initWithDictionary:entryDict];
		[entryDict release];
        if (self.sectionArray.count > sectionIndex)
            [[self.sectionArray objectAtIndex:sectionIndex] addObject:cellInfo];
		[cellInfo release], cellInfo = nil;
	} 
	if (self.legislator && self.legislator.cap_fax && [self.legislator.cap_fax length]) {
		entryDict = [[NSDictionary alloc] initWithObjectsAndKeys:
					 NSLocalizedStringFromTable(@"Fax", @"DataTableUI", @"Cell title listing a fax number"), @"subtitle",
					 self.legislator.cap_fax, @"entryValue",
					 self.legislator.cap_fax, @"title",
					 [NSNumber numberWithBool:NO], @"isClickable",
					 [NSNumber numberWithInteger:DirectoryTypeNone], @"entryType",
					 nil];
		cellInfo = [[TableCellDataObject alloc] initWithDictionary:entryDict];
		[entryDict release];
        if (self.sectionArray.count > sectionIndex)
            [[self.sectionArray objectAtIndex:sectionIndex] addObject:cellInfo];
		[cellInfo release], cellInfo = nil;
	}
	if (self.legislator && self.legislator.cap_phone2 && [self.legislator.cap_phone2 length]) {
		tempString = (self.legislator.cap_phone2_name.length > 0) ? self.legislator.cap_phone2_name : NSLocalizedStringFromTable(@"Phone #2", @"DataTableUI", @"Second phone number");
		entryDict = [[NSDictionary alloc] initWithObjectsAndKeys:
					 tempString, @"subtitle",
					 self.legislator.cap_phone2, @"entryValue",
					 self.legislator.cap_phone2, @"title",
					 [NSNumber numberWithBool:isPhone], @"isClickable",
					 [NSNumber numberWithInteger:DirectoryTypePhone], @"entryType",
					 nil];
		cellInfo = [[TableCellDataObject alloc] initWithDictionary:entryDict];
		[entryDict release];
        if (self.sectionArray.count > sectionIndex)
            [[self.sectionArray objectAtIndex:sectionIndex] addObject:cellInfo];
		[cellInfo release], cellInfo = nil;
	} 
	
	/* after that section's done... */
	/*	Section 3+: District Offices */		
	
	for (DistrictOfficeObj *office in self.legislator.districtOffices) {
		sectionIndex++;
		if (office.phone && [office.phone length]) {
			entryDict = [[NSDictionary alloc] initWithObjectsAndKeys:
						 NSLocalizedStringFromTable(@"Phone", @"DataTableUI", @"Cell title listing a phone number"), @"subtitle",
						 office.phone, @"entryValue",
						 office.phone, @"title",
						 [NSNumber numberWithBool:isPhone], @"isClickable",
						 [NSNumber numberWithInteger:DirectoryTypePhone], @"entryType",
						 nil];
			cellInfo = [[TableCellDataObject alloc] initWithDictionary:entryDict];
			[entryDict release];
            if (self.sectionArray.count > sectionIndex)
                [[self.sectionArray objectAtIndex:sectionIndex] addObject:cellInfo];
			[cellInfo release], cellInfo = nil;
		}			
		if (office.fax && [office.fax length]) {
			entryDict = [[NSDictionary alloc] initWithObjectsAndKeys:
						 NSLocalizedStringFromTable(@"Fax", @"DataTableUI", @"Cell title listing a fax number"), @"subtitle",
						 office.fax, @"entryValue",
						 office.fax, @"title",
						 [NSNumber numberWithBool:NO], @"isClickable",
						 [NSNumber numberWithInteger:DirectoryTypeNone], @"entryType",
						 nil];
			cellInfo = [[TableCellDataObject alloc] initWithDictionary:entryDict];
			[entryDict release];
            if (self.sectionArray.count > sectionIndex)
                [[self.sectionArray objectAtIndex:sectionIndex] addObject:cellInfo];
			[cellInfo release], cellInfo = nil;
		}			
		if (office.address && [office.address length]) {
			
			entryDict = [[NSDictionary alloc] initWithObjectsAndKeys:
						 NSLocalizedStringFromTable(@"Address", @"DataTableUI", @"Cell title listing a street address"), @"subtitle",
						 office, @"entryValue",
						 [office cellAddress], @"title",
						 [NSNumber numberWithBool:YES], @"isClickable",
						 [NSNumber numberWithInteger:DirectoryTypeMap], @"entryType",
						 nil];
			cellInfo = [[TableCellDataObject alloc] initWithDictionary:entryDict];
			[entryDict release];
            if (self.sectionArray.count > sectionIndex)
                [[self.sectionArray objectAtIndex:sectionIndex] addObject:cellInfo];
			[cellInfo release], cellInfo = nil;
		} 
		
	}
}	

#pragma mark -
#pragma mark Data Object Methods

- (id) dataObjectForIndexPath:(NSIndexPath *)indexPath {
	if (!indexPath)
		return nil;
	
	id tempEntry = nil;
    if (self.sectionArray.count <= indexPath.section)
        return nil;
	NSArray *group = self.sectionArray[indexPath.section];
	if (group && [group count] > indexPath.row)
		tempEntry = [group objectAtIndex:indexPath.row];
	return tempEntry;
}

- (NSIndexPath *)indexPathForDataObject:(id)dataObject {
	if (!dataObject)
		return nil;
	
	NSInteger section = 0, row = 0;
	for (NSArray *group in self.sectionArray) {
		for (id object in group) {
			if ([object isEqual:dataObject])
				return [NSIndexPath indexPathForRow:row inSection:section];
			row++;
		}
		section++;
	}
	return nil;
}



#pragma mark -
#pragma mark Indexing / Sections


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {	
	return [self.sectionArray count];	
}

// This is for the little index along the right side of the table ... use nil if you don't want it.
- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
	return  nil ;
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index {
	return index; // index ..........
}

- (NSInteger)tableView:(UITableView *)tableView  numberOfRowsInSection:(NSInteger)section {
    NSArray *sections = self.sectionArray;
    if (sections.count <= section)
        return 0;
	NSArray *group = [sections objectAtIndex:section];
	if (group)
		return [group count];

	return 0;
}

- (NSString *)tableView:(UITableView *)aTableView titleForHeaderInSection:(NSInteger)section {	
	NSString *title = nil;
	
	switch (section) {
		case 0:
			title = NSLocalizedStringFromTable(@"Legislator Information", @"DataTableUI", @"Cell title");
			break;
		case 1:
			title = NSLocalizedStringFromTable(@"Committee Assignments", @"DataTableUI", @"Cell title");;
			break;
		case 2:
			title = NSLocalizedStringFromTable(@"Staff Members", @"DataTableUI", @"Cell title");
			break;
		case 3:
			title = NSLocalizedStringFromTable(@"Capitol Office", @"DataTableUI", @"Cell title");
			break;
		case 4:
			title = NSLocalizedStringFromTable(@"District Office #1", @"DataTableUI", @"Cell title");
			break;
		case 5:
			title = NSLocalizedStringFromTable(@"District Office #2", @"DataTableUI", @"Cell title");
			break;
		case 6:
			title = NSLocalizedStringFromTable(@"District Office #3", @"DataTableUI", @"Cell title");
			break;
		case 7:
		default:
			title = NSLocalizedStringFromTable(@"District Office #4", @"DataTableUI", @"Cell title");
			break;
	}
	return title;
}


- (NSString *)chamberPartyAbbrev {
	NSString *partyName = stringForParty([self.legislator.party_id integerValue], TLReturnAbbrev);
	
	return [NSString stringWithFormat:@"%@ %@ %@", [self.legislator chamberName], partyName, 
			 NSLocalizedStringFromTable(@"Avg.", @"DataTableUI", @"Abbreviation for the word average.")];
}

#pragma mark -
#pragma mark Custom Slider

/* This determines the appropriate size for the custom slider view, given its superview */
- (CGRect) preshrinkSliderViewFromView:(UIView *)aView {
	CGFloat sliderHeight = 24.0f;
	CGFloat sliderInset = 18.0f;
	
	CGRect rect = aView.bounds;
	CGFloat sliderWidth = aView.bounds.size.width - (sliderInset * 2);
	
	rect.origin.y = aView.center.y - (sliderHeight / 2);
	rect.size.height = sliderHeight;
	rect.origin.x = sliderInset; //aView.center.x - (sliderWidth / 2);
	rect.size.width = sliderWidth;
	
	return rect;
}

#pragma mark -
#pragma mark UITableViewDataSource methods


- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{		
		
	TableCellDataObject *cellInfo = [self dataObjectForIndexPath:indexPath];
		
	NSString *stdCellID = [TexLegeStandardGroupCell cellIdentifier];
	if (cellInfo && cellInfo.entryType == DirectoryTypeNotes)
		stdCellID = @"TexLegeNotesGroupCell";
		
	NSString *cellIdentifier = [NSString stringWithFormat:@"%@-%d", stdCellID, cellInfo.isClickable];
	
	/* Look up cell in the table queue */
	UITableViewCell *cell = [aTableView dequeueReusableCellWithIdentifier:cellIdentifier];
	
	/* Not found in queue, create a new cell object */
    if (cell == nil) {
		cell = [[[TexLegeStandardGroupCell alloc] initWithStyle:[TexLegeStandardGroupCell cellStyle] reuseIdentifier:cellIdentifier] autorelease];
    }

    if (cellInfo == nil) {
        debug_NSLog(@"LegislatorDetailDataSource:cellForRow: error finding table entry for section:%ld row:%ld", (long)indexPath.section, (long)indexPath.row);
        return cell;
    }

	if ([cell conformsToProtocol:@protocol(TexLegeGroupCellProtocol)])
		 [cell performSelector:@selector(setCellInfo:) withObject:cellInfo];
		
	if (cellInfo.entryType == DirectoryTypeNotes) {
		if (![cellInfo.entryValue isEqualToString:kStaticNotes])
			cell.detailTextLabel.textColor = [UIColor blackColor];
		else
			cell.detailTextLabel.textColor = [UIColor grayColor];
	}
	else if (cellInfo.entryType == DirectoryTypeMap) {
			cell.detailTextLabel.lineBreakMode = NSLineBreakByWordWrapping;
			cell.detailTextLabel.numberOfLines = 4;
	}			
	
	[cell sizeToFit];
	[cell setNeedsDisplay];
	
	return cell;
	
}

@end
