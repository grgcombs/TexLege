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

- (instancetype)initWithLegislator:(LegislatorObj *)newObject {
	if ((self = [super init])) {
		if (newObject) 
			self.legislator = newObject;
	}
	return self;
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
	
    NSDictionary *entryDict = @{@"subtitle": NSLocalizedStringFromTable(@"Name", @"DataTableUI", @"Title for cell"),
							    @"entryValue": [self.legislator fullName],
							    @"title": [self.legislator fullName],
							    @"isClickable": @NO,
                                @"entryType": @(DirectoryTypeNone)};
	cellInfo = [[TableCellDataObject alloc] initWithDictionary:entryDict];
    if (self.sectionArray.count > sectionIndex)
        [(self.sectionArray)[sectionIndex] addObject:cellInfo];
	cellInfo = nil;
	
	
    entryDict = @{@"subtitle": NSLocalizedStringFromTable(@"Map", @"DataTableUI", @"Title for cell"),
                  @"entryValue": self.legislator.districtMap,
                  @"title": NSLocalizedStringFromTable(@"District Map", @"DataTableUI", @"Title for cell"),
                  @"isClickable": @YES,
                  @"entryType": @(DirectoryTypeMap)};
	cellInfo = [[TableCellDataObject alloc] initWithDictionary:entryDict];
    if (self.sectionArray.count > sectionIndex)
        [(self.sectionArray)[sectionIndex] addObject:cellInfo];
	cellInfo = nil;
	
	
	if (self.legislator && self.legislator.nimsp_id) {
        entryDict = @{@"subtitle": NSLocalizedStringFromTable(@"Finances", @"DataTableUI", @"Title for Cell"),
                      @"entryValue": self.legislator.nimsp_id,
                      @"title": NSLocalizedStringFromTable(@"Campaign Contributions", @"DataTableUI", @"title for cell"),
                      @"isClickable": @YES,
                      @"entryType": @(DirectoryTypeContributions)};
		cellInfo = [[TableCellDataObject alloc] initWithDictionary:entryDict];
        if (self.sectionArray.count > sectionIndex)
            [(self.sectionArray)[sectionIndex] addObject:cellInfo];
		cellInfo = nil;
		
	}
	
    entryDict = @{@"subtitle": NSLocalizedStringFromTable(@"Email", @"DataTableUI", @"Title for Cell"),
				  @"entryValue": self.legislator.email,
				  @"title": self.legislator.email,
                  @"isClickable": @YES,
                  @"entryType": @(DirectoryTypeMail)};
	cellInfo = [[TableCellDataObject alloc] initWithDictionary:entryDict];
    if (self.sectionArray.count > sectionIndex)
        [(self.sectionArray)[sectionIndex] addObject:cellInfo];
	cellInfo = nil;
	
	
	
	if (self.legislator && self.legislator.twitter && (self.legislator.twitter).length) {
		tempString = ([self.legislator.twitter hasPrefix:@"@"]) ? self.legislator.twitter : [[NSString alloc] initWithFormat:@"@%@", self.legislator.twitter];
        entryDict = @{@"subtitle": NSLocalizedStringFromTable(@"Twitter", @"DataTableUI", @"Title for Cell"),
                      @"entryValue": tempString,
                      @"title": tempString,
                      @"isClickable": @YES,
                      @"entryType": @(DirectoryTypeTwitter)};
		cellInfo = [[TableCellDataObject alloc] initWithDictionary:entryDict];
        if (self.sectionArray.count > sectionIndex)
            [(self.sectionArray)[sectionIndex] addObject:cellInfo];
		cellInfo = nil;
		
	}
	
    entryDict = @{@"subtitle": NSLocalizedStringFromTable(@"Web", @"DataTableUI", @"Title for Cell, As in, a web address"),
                  @"entryValue": self.legislator.website,
                  @"title": NSLocalizedStringFromTable(@"Official Website", @"DataTableUI", @"Title for Cell"),
                  @"isClickable": @YES,
                  @"entryType": @(DirectoryTypeWeb)};
	cellInfo = [[TableCellDataObject alloc] initWithDictionary:entryDict];
    if (self.sectionArray.count > sectionIndex)
        [(self.sectionArray)[sectionIndex] addObject:cellInfo];
	cellInfo = nil;

    entryDict = @{
                  @"subtitle": NSLocalizedStringFromTable(@"Web", @"DataTableUI", @"Title for cell, As in, a web adress"),
                  @"entryValue": self.legislator.bio_url,
                  @"title": NSLocalizedStringFromTable(@"Votesmart Bio", @"DataTableUI", @"Title for cell, Biographical information available at VoteSmart.org"),
                  @"isClickable": @YES,
                  @"entryType": @(DirectoryTypeWeb),
                  };
	cellInfo = [[TableCellDataObject alloc] initWithDictionary:entryDict];
    if (self.sectionArray.count > sectionIndex)
        [(self.sectionArray)[sectionIndex] addObject:cellInfo];
	cellInfo = nil;
	
    entryDict = @{
                  @"subtitle": NSLocalizedStringFromTable(@"Legislation", @"DataTableUI", @"Title for cell, Bills and resolutions this person has authored"),
                  @"entryValue": self.legislator.openstatesID,
                  @"title": NSLocalizedStringFromTable(@"Authored Bills", @"DataTableUI", @"Title for cell, Bills and resolutions this person has authored"),
                  @"isClickable": @YES,
                  @"entryType": @(DirectoryTypeBills),
                  };
	cellInfo = [[TableCellDataObject alloc] initWithDictionary:entryDict];
    if (self.sectionArray.count > sectionIndex)
        [(self.sectionArray)[sectionIndex] addObject:cellInfo];
	cellInfo = nil;
	
	tempString = nil;
	[[NSUserDefaults standardUserDefaults] synchronize];	
	NSDictionary *storedNotesDict = [[NSUserDefaults standardUserDefaults] valueForKey:@"LEGE_NOTES"];
	if (storedNotesDict) {
		tempString = [storedNotesDict valueForKey:(self.legislator.legislatorID).stringValue];
	}
	if (IsEmpty(tempString)) {
		tempString = kStaticNotes;
	}
    entryDict = @{@"subtitle": NSLocalizedStringFromTable(@"Notes", @"DataTableUI", @"Title for the cell indicating custom notes option"),
                  @"entryValue": tempString,
                  @"title": tempString,
                  @"isClickable": @YES,
                  @"entryType": @(DirectoryTypeNotes),
                  };
	cellInfo = [[TableCellDataObject alloc] initWithDictionary:entryDict];
    if (self.sectionArray.count > sectionIndex)
        [(self.sectionArray)[sectionIndex] addObject:cellInfo];
	cellInfo = nil;
	
	
	/* after that section's done... DO COMMITTEES */
	sectionIndex++;
	for (CommitteePositionObj *position in [self.legislator sortedCommitteePositions]) {
        entryDict = @{@"subtitle": [position positionString],
                      @"entryValue": position.committee,
                      @"title": (position.committee).committeeName,
                      @"isClickable": @YES,
                      @"entryType": @(DirectoryTypeCommittee),
                      };
		cellInfo = [[TableCellDataObject alloc] initWithDictionary:entryDict];
        if (self.sectionArray.count > sectionIndex)
            [(self.sectionArray)[sectionIndex] addObject:cellInfo];
		cellInfo = nil;
	}
	
	/* Now we handle all the office locations ... */
	sectionIndex++;
	/*	Section 1: Staffers */
	
	if ([self.legislator numberOfStaffers] > 0) {
		for (StafferObj *staffer in [self.legislator sortedStaffers]) {
            entryDict = @{
                          @"subtitle": staffer.title,
                          @"entryValue": staffer.email,
                          @"title": staffer.name,
                          @"isClickable": @YES,
                          @"entryType": @(DirectoryTypeMail),
                          };
			cellInfo = [[TableCellDataObject alloc] initWithDictionary:entryDict];
            if (self.sectionArray.count > sectionIndex)
                [(self.sectionArray)[sectionIndex] addObject:cellInfo];
			cellInfo = nil;
		}
	}
	else {
        entryDict = @{@"subtitle": NSLocalizedStringFromTable(@"Staff", @"DataTableUI", @"Office employees"),
                      @"entryValue": @"NoneListed",
                      @"title": NSLocalizedStringFromTable(@"No Staff Listed", @"DataTableUI", @"Title for cell indicating this person hasn't publish a list of office employees"),
                      @"isClickable": @NO,
                      @"entryType": @(DirectoryTypeNone),
                      };
		cellInfo = [[TableCellDataObject alloc] initWithDictionary:entryDict];
        if (self.sectionArray.count > sectionIndex)
            [(self.sectionArray)[sectionIndex] addObject:cellInfo];
		cellInfo = nil;
	}
		
	/* Now we handle all the office locations ... */
	sectionIndex++;
	/*	Section 2: Capitol Office */		
		
	if (self.legislator && self.legislator.cap_office && (self.legislator.cap_office).length) {
        entryDict = @{@"subtitle": NSLocalizedStringFromTable(@"Office", @"DataTableUI", @"The person's office number, indicating the location inside the building"),
                      @"entryValue": [CapitolMap mapFromOfficeString:self.legislator.cap_office],
                      @"title": self.legislator.cap_office,
                      @"isClickable": @YES,
                      @"entryType": @(DirectoryTypeOfficeMap),
                     };
		cellInfo = [[TableCellDataObject alloc] initWithDictionary:entryDict];
        if (self.sectionArray.count > sectionIndex)
            [(self.sectionArray)[sectionIndex] addObject:cellInfo];
		cellInfo = nil;
	} 
	if (self.legislator && self.legislator.cap_phone && (self.legislator.cap_phone).length) {
        entryDict = @{
					 @"subtitle": NSLocalizedStringFromTable(@"Phone", @"DataTableUI", @"Cell title listing a phone number"),
					 @"entryValue": self.legislator.cap_phone,
					 @"title": self.legislator.cap_phone,
					 @"isClickable": @(isPhone),
					 @"entryType": @(DirectoryTypePhone),
                     };
		cellInfo = [[TableCellDataObject alloc] initWithDictionary:entryDict];
        if (self.sectionArray.count > sectionIndex)
            [(self.sectionArray)[sectionIndex] addObject:cellInfo];
		cellInfo = nil;
	} 
	if (self.legislator && self.legislator.cap_fax && (self.legislator.cap_fax).length) {
        entryDict = @{@"subtitle": NSLocalizedStringFromTable(@"Fax", @"DataTableUI", @"Cell title listing a fax number"),
					  @"entryValue": self.legislator.cap_fax,
					  @"title": self.legislator.cap_fax,
					  @"isClickable": @NO,
					  @"entryType": @(DirectoryTypeNone)
                      };
		cellInfo = [[TableCellDataObject alloc] initWithDictionary:entryDict];
        if (self.sectionArray.count > sectionIndex)
            [(self.sectionArray)[sectionIndex] addObject:cellInfo];
		cellInfo = nil;
	}
	if (self.legislator && self.legislator.cap_phone2 && (self.legislator.cap_phone2).length) {
		tempString = (self.legislator.cap_phone2_name.length > 0) ? self.legislator.cap_phone2_name : NSLocalizedStringFromTable(@"Phone #2", @"DataTableUI", @"Second phone number");
        entryDict = @{@"subtitle":tempString,
					  @"entryValue": self.legislator.cap_phone2,
					  @"title": self.legislator.cap_phone2,
					  @"isClickable": @(isPhone),
					  @"entryType": @(DirectoryTypePhone),
                      };
		cellInfo = [[TableCellDataObject alloc] initWithDictionary:entryDict];
        if (self.sectionArray.count > sectionIndex)
            [(self.sectionArray)[sectionIndex] addObject:cellInfo];
		cellInfo = nil;
	} 
	
	/* after that section's done... */
	/*	Section 3+: District Offices */		
	
	for (DistrictOfficeObj *office in self.legislator.districtOffices) {
		sectionIndex++;
		if (office.phone && (office.phone).length) {
            entryDict = @{
                          @"subtitle": NSLocalizedStringFromTable(@"Phone", @"DataTableUI", @"Cell title listing a phone number"),
                          @"entryValue": office.phone,
                          @"title": office.phone,
                          @"isClickable": @(isPhone),
                          @"entryType": @(DirectoryTypePhone),
                          };
			cellInfo = [[TableCellDataObject alloc] initWithDictionary:entryDict];
            if (self.sectionArray.count > sectionIndex)
                [(self.sectionArray)[sectionIndex] addObject:cellInfo];
			cellInfo = nil;
		}			
		if (office.fax && (office.fax).length) {
            entryDict = @{
						 @"subtitle": NSLocalizedStringFromTable(@"Fax", @"DataTableUI", @"Cell title listing a fax number"),
						 @"entryValue": office.fax,
						 @"title": office.fax,
						 @"isClickable": @NO,
						 @"entryType": @(DirectoryTypeNone),
                         };
			cellInfo = [[TableCellDataObject alloc] initWithDictionary:entryDict];
            if (self.sectionArray.count > sectionIndex)
                [(self.sectionArray)[sectionIndex] addObject:cellInfo];
			cellInfo = nil;
		}			
		if (office.address && (office.address).length) {
			
            entryDict = @{
                          @"subtitle": NSLocalizedStringFromTable(@"Address", @"DataTableUI", @"Cell title listing a street address"),
                          @"entryValue": office,
                          @"title": [office cellAddress],
                          @"isClickable": @YES,
                          @"entryType": @(DirectoryTypeMap),
                          };
			cellInfo = [[TableCellDataObject alloc] initWithDictionary:entryDict];
            if (self.sectionArray.count > sectionIndex)
                [(self.sectionArray)[sectionIndex] addObject:cellInfo];
			cellInfo = nil;
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
	if (group && group.count > indexPath.row)
		tempEntry = group[indexPath.row];
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
	return (self.sectionArray).count;	
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
	NSArray *group = sections[section];
	if (group)
		return group.count;

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
	NSString *partyName = stringForParty((self.legislator.party_id).integerValue, TLReturnAbbrev);
	
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
		cell = [[TexLegeStandardGroupCell alloc] initWithStyle:[TexLegeStandardGroupCell cellStyle] reuseIdentifier:cellIdentifier];
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
