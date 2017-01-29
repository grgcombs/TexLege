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

@implementation LegislatorDetailDataSource
@synthesize legislator = _legislator;
@synthesize dataObjectID = _dataObjectID;

- (instancetype)initWithLegislator:(LegislatorObj *)newObject
{
	if ((self = [super init]))
    {
		if (newObject)
        {
			_legislator = newObject;
            if (newObject.legislatorID)
                _dataObjectID = newObject.legislatorID;
        }
	}
	return self;
}


- (LegislatorObj *)legislator
{
    if (_legislator)
        return _legislator;

	LegislatorObj *anObject = nil;
	if (_dataObjectID)
    {
		@try {
			anObject = [LegislatorObj objectWithPrimaryKeyValue:_dataObjectID];
		}
		@catch (NSException * e) {
		}
	}
	return anObject;
}

- (void)setLegislator:(LegislatorObj *)newLegislator
{
    _dataObjectID = nil;
    _legislator = newLegislator;
	if (newLegislator)
    {
        if (newLegislator.legislatorID)
            _dataObjectID = newLegislator.legislatorID;

		[self createSectionList];		
	}
}

- (void)createSectionList
{
    LegislatorObj *legislator = _legislator;

	NSInteger numberOfSections = 4 + [legislator numberOfDistrictOffices];
	
	NSString *tempString = nil;
	BOOL isPhone = [UtilityMethods canMakePhoneCalls];
	TableCellDataObject *cellInfo = nil;
	NSMutableArray *sectionArray = [NSMutableArray arrayWithCapacity:numberOfSections];
    self.sectionArray = sectionArray;
	
    NSInteger i = 0;
	for (i=0; i < numberOfSections; i++)
    {
		[sectionArray addObject:[NSMutableArray arrayWithCapacity:30]]; // just an arbitrary maximum
	}
	
    NSDictionary *entryDict = nil;
    NSInteger sectionIndex = 0;

    NSString *fullName = legislator.fullName;
    if (fullName && fullName.length)
    {
        NSDictionary *entryDict = @{@"subtitle": NSLocalizedStringFromTable(@"Name", @"DataTableUI", @"Title for cell"),
                                    @"entryValue": fullName,
                                    @"title": fullName,
                                    @"isClickable": @NO,
                                    @"entryType": @(DirectoryTypeNone)};
        cellInfo = [[TableCellDataObject alloc] initWithDictionary:entryDict];
        if (sectionArray.count > sectionIndex)
            [(sectionArray)[sectionIndex] addObject:cellInfo];
        cellInfo = nil;
    }

    DistrictMapObj *districtMap = legislator.districtMap;
    if (districtMap)
    {
        entryDict = @{@"subtitle": NSLocalizedStringFromTable(@"Map", @"DataTableUI", @"Title for cell"),
                      @"entryValue": districtMap,
                      @"title": NSLocalizedStringFromTable(@"District Map", @"DataTableUI", @"Title for cell"),
                      @"isClickable": @YES,
                      @"entryType": @(DirectoryTypeMap)};
        cellInfo = [[TableCellDataObject alloc] initWithDictionary:entryDict];
        if (sectionArray.count > sectionIndex)
            [(sectionArray)[sectionIndex] addObject:cellInfo];
        cellInfo = nil;
    }

    NSNumber *nimsp = legislator.nimsp_id;
	if (nimsp)
    {
        entryDict = @{@"subtitle": NSLocalizedStringFromTable(@"Finances", @"DataTableUI", @"Title for Cell"),
                      @"entryValue": nimsp,
                      @"title": NSLocalizedStringFromTable(@"Campaign Contributions", @"DataTableUI", @"title for cell"),
                      @"isClickable": @YES,
                      @"entryType": @(DirectoryTypeContributions)};
		cellInfo = [[TableCellDataObject alloc] initWithDictionary:entryDict];
        if (sectionArray.count > sectionIndex)
            [(sectionArray)[sectionIndex] addObject:cellInfo];
		cellInfo = nil;
	}

    NSString *email = legislator.email;
    if (email && email.length)
    {
        entryDict = @{@"subtitle": NSLocalizedStringFromTable(@"Email", @"DataTableUI", @"Title for Cell"),
                      @"entryValue": email,
                      @"title": email,
                      @"isClickable": @YES,
                      @"entryType": @(DirectoryTypeMail)};
        cellInfo = [[TableCellDataObject alloc] initWithDictionary:entryDict];
        if (sectionArray.count > sectionIndex)
            [(sectionArray)[sectionIndex] addObject:cellInfo];
        cellInfo = nil;
    }

    NSString *twitter = legislator.twitter;
	if (twitter && twitter.length)
    {
		tempString = ([twitter hasPrefix:@"@"]) ? twitter : [[NSString alloc] initWithFormat:@"@%@", twitter];
        entryDict = @{@"subtitle": NSLocalizedStringFromTable(@"Twitter", @"DataTableUI", @"Title for Cell"),
                      @"entryValue": tempString,
                      @"title": tempString,
                      @"isClickable": @YES,
                      @"entryType": @(DirectoryTypeTwitter)};
		cellInfo = [[TableCellDataObject alloc] initWithDictionary:entryDict];
        if (sectionArray.count > sectionIndex)
            [(sectionArray)[sectionIndex] addObject:cellInfo];
		cellInfo = nil;
		
	}

    NSString *website = legislator.website;
    if (website && website.length)
    {
        entryDict = @{@"subtitle": NSLocalizedStringFromTable(@"Web", @"DataTableUI", @"Title for Cell, As in, a web address"),
                      @"entryValue": website,
                      @"title": NSLocalizedStringFromTable(@"Official Website", @"DataTableUI", @"Title for Cell"),
                      @"isClickable": @YES,
                      @"entryType": @(DirectoryTypeWeb)};
        cellInfo = [[TableCellDataObject alloc] initWithDictionary:entryDict];
        if (sectionArray.count > sectionIndex)
            [(sectionArray)[sectionIndex] addObject:cellInfo];
        cellInfo = nil;
    }

    NSString *bio_url = legislator.bio_url;
    if (bio_url && bio_url.length)
    {
        entryDict = @{
                      @"subtitle": NSLocalizedStringFromTable(@"Web", @"DataTableUI", @"Title for cell, As in, a web adress"),
                      @"entryValue": bio_url,
                      @"title": NSLocalizedStringFromTable(@"Votesmart Bio", @"DataTableUI", @"Title for cell, Biographical information available at VoteSmart.org"),
                      @"isClickable": @YES,
                      @"entryType": @(DirectoryTypeWeb),
                      };
        cellInfo = [[TableCellDataObject alloc] initWithDictionary:entryDict];
        if (sectionArray.count > sectionIndex)
            [(sectionArray)[sectionIndex] addObject:cellInfo];
        cellInfo = nil;
    }

    NSString *openstatesID = legislator.openstatesID;
    if (openstatesID && openstatesID.length)
    {
        entryDict = @{
                      @"subtitle": NSLocalizedStringFromTable(@"Legislation", @"DataTableUI", @"Title for cell, Bills and resolutions this person has authored"),
                      @"entryValue": openstatesID,
                      @"title": NSLocalizedStringFromTable(@"Authored Bills", @"DataTableUI", @"Title for cell, Bills and resolutions this person has authored"),
                      @"isClickable": @YES,
                      @"entryType": @(DirectoryTypeBills),
                      };
        cellInfo = [[TableCellDataObject alloc] initWithDictionary:entryDict];
        if (sectionArray.count > sectionIndex)
            [(sectionArray)[sectionIndex] addObject:cellInfo];
        cellInfo = nil;
    }

	tempString = nil;
	[[NSUserDefaults standardUserDefaults] synchronize];	
	NSDictionary *storedNotesDict = [[NSUserDefaults standardUserDefaults] valueForKey:@"LEGE_NOTES"];
	if (storedNotesDict) {
		tempString = [storedNotesDict valueForKey:(legislator.legislatorID).stringValue];
	}
	if (IsEmpty(tempString) || !tempString) {
		tempString = kStaticNotes;
	}
    NSString *notes = NSLocalizedStringFromTable(@"Notes", @"DataTableUI", @"Title for the cell indicating custom notes option");
    if (!notes)
        notes = @"Notes";
    entryDict = @{@"subtitle": notes,
                  @"entryValue": tempString,
                  @"title": tempString,
                  @"isClickable": @YES,
                  @"entryType": @(DirectoryTypeNotes),
                  };
	cellInfo = [[TableCellDataObject alloc] initWithDictionary:entryDict];
    if (sectionArray.count > sectionIndex)
        [(sectionArray)[sectionIndex] addObject:cellInfo];
	cellInfo = nil;
	
	
	/* after that section's done... DO COMMITTEES */
	sectionIndex++;
	for (CommitteePositionObj *position in [legislator sortedCommitteePositions])
    {
        CommitteeObj *committee = position.committee;
        if (!committee)
            continue;
        NSString *title = committee.committeeName;
        if (!title)
            continue;
        NSString *subtitle = position.positionString;
        if (!subtitle)
            subtitle = @"";

        entryDict = @{@"subtitle": subtitle,
                      @"entryValue": committee,
                      @"title": title,
                      @"isClickable": @YES,
                      @"entryType": @(DirectoryTypeCommittee),
                      };
		cellInfo = [[TableCellDataObject alloc] initWithDictionary:entryDict];
        if (sectionArray.count > sectionIndex)
            [(sectionArray)[sectionIndex] addObject:cellInfo];
		cellInfo = nil;
	}
	
	/* Now we handle all the office locations ... */
	sectionIndex++;
	/*	Section 1: Staffers */
	
	if ([legislator numberOfStaffers] > 0)
    {
		for (StafferObj *staffer in [legislator sortedStaffers])
        {
            NSString *role = staffer.title;
            if (!role)
                role = @"";
            NSString *email = staffer.email;
            if (!email)
                email = @"";
            NSString *name = staffer.name;
            if (!name)
                continue;

            entryDict = @{
                          @"subtitle": role,
                          @"entryValue": email,
                          @"title": name,
                          @"isClickable": (email.length > 0) ? @YES : @NO,
                          @"entryType": @(DirectoryTypeMail),
                          };
			cellInfo = [[TableCellDataObject alloc] initWithDictionary:entryDict];
            if (sectionArray.count > sectionIndex)
                [(sectionArray)[sectionIndex] addObject:cellInfo];
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
        if (sectionArray.count > sectionIndex)
            [(sectionArray)[sectionIndex] addObject:cellInfo];
		cellInfo = nil;
	}
		
	/* Now we handle all the office locations ... */
	sectionIndex++;
	/*	Section 2: Capitol Office */		

    NSString * office = legislator.cap_office;
	if (office && office.length)
    {
        entryDict = @{@"subtitle": NSLocalizedStringFromTable(@"Office", @"DataTableUI", @"The person's office number, indicating the location inside the building"),
                      @"entryValue": [CapitolMap mapFromOfficeString:office],
                      @"title": office,
                      @"isClickable": @YES,
                      @"entryType": @(DirectoryTypeOfficeMap),
                     };
		cellInfo = [[TableCellDataObject alloc] initWithDictionary:entryDict];
        if (sectionArray.count > sectionIndex)
            [(sectionArray)[sectionIndex] addObject:cellInfo];
		cellInfo = nil;
	}


    NSString *phone = legislator.cap_phone;
	if (phone && phone.length)
    {
        entryDict = @{
					 @"subtitle": NSLocalizedStringFromTable(@"Phone", @"DataTableUI", @"Cell title listing a phone number"),
					 @"entryValue": phone,
					 @"title": phone,
					 @"isClickable": @(isPhone),
					 @"entryType": @(DirectoryTypePhone),
                     };
		cellInfo = [[TableCellDataObject alloc] initWithDictionary:entryDict];
        if (sectionArray.count > sectionIndex)
            [(sectionArray)[sectionIndex] addObject:cellInfo];
		cellInfo = nil;
	}

    NSString *fax = legislator.cap_fax;
	if (fax && fax.length)
    {
        entryDict = @{@"subtitle": NSLocalizedStringFromTable(@"Fax", @"DataTableUI", @"Cell title listing a fax number"),
					  @"entryValue": fax,
					  @"title": fax,
					  @"isClickable": @NO,
					  @"entryType": @(DirectoryTypeNone)
                      };
		cellInfo = [[TableCellDataObject alloc] initWithDictionary:entryDict];
        if (sectionArray.count > sectionIndex)
            [(sectionArray)[sectionIndex] addObject:cellInfo];
		cellInfo = nil;
	}

    NSString *phone2 = legislator.cap_phone2;
    NSString *phone2name = legislator.cap_phone2_name;

	if (phone2 && phone2.length)
    {
		tempString = (phone2name.length > 0) ? phone2name : NSLocalizedStringFromTable(@"Phone #2", @"DataTableUI", @"Second phone number");
        entryDict = @{@"subtitle":tempString,
					  @"entryValue": phone2name,
					  @"title": phone2name,
					  @"isClickable": @(isPhone),
					  @"entryType": @(DirectoryTypePhone),
                      };
		cellInfo = [[TableCellDataObject alloc] initWithDictionary:entryDict];
        if (sectionArray.count > sectionIndex)
            [(sectionArray)[sectionIndex] addObject:cellInfo];
		cellInfo = nil;
	} 
	
	/* after that section's done... */
	/*	Section 3+: District Offices */		
	
	for (DistrictOfficeObj *office in legislator.districtOffices)
    {
		sectionIndex++;
        phone = office.phone;
		if (phone && phone.length)
        {
            entryDict = @{
                          @"subtitle": NSLocalizedStringFromTable(@"Phone", @"DataTableUI", @"Cell title listing a phone number"),
                          @"entryValue": phone,
                          @"title": phone,
                          @"isClickable": @(isPhone),
                          @"entryType": @(DirectoryTypePhone),
                          };
			cellInfo = [[TableCellDataObject alloc] initWithDictionary:entryDict];
            if (sectionArray.count > sectionIndex)
                [(sectionArray)[sectionIndex] addObject:cellInfo];
			cellInfo = nil;
		}

        fax = office.fax;
		if (fax && fax.length)
        {
            entryDict = @{
						 @"subtitle": NSLocalizedStringFromTable(@"Fax", @"DataTableUI", @"Cell title listing a fax number"),
						 @"entryValue": fax,
						 @"title": fax,
						 @"isClickable": @NO,
						 @"entryType": @(DirectoryTypeNone),
                         };
			cellInfo = [[TableCellDataObject alloc] initWithDictionary:entryDict];
            if (sectionArray.count > sectionIndex)
                [(sectionArray)[sectionIndex] addObject:cellInfo];
			cellInfo = nil;
		}

        NSString *address = office.address;
		if (address && address.length)
            address = [office cellAddress];
        if (address && address.length)
        {
            entryDict = @{
                          @"subtitle": NSLocalizedStringFromTable(@"Address", @"DataTableUI", @"Cell title listing a street address"),
                          @"entryValue": office,
                          @"title": address,
                          @"isClickable": @YES,
                          @"entryType": @(DirectoryTypeMap),
                          };
			cellInfo = [[TableCellDataObject alloc] initWithDictionary:entryDict];
            if (sectionArray.count > sectionIndex)
                [(sectionArray)[sectionIndex] addObject:cellInfo];
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
    LegislatorObj *legislator = _legislator;
	NSString *partyName = stringForParty((legislator.party_id).integerValue, TLReturnAbbrev);
	
	return [NSString stringWithFormat:@"%@ %@ %@", [legislator chamberName], partyName, 
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
