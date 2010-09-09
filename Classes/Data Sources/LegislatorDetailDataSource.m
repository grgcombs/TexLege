//
//  LegislatorDetailDataSource.m
//  TexLege
//
//  Created by Gregory Combs on 8/29/10.
//  Copyright 2010 Gregory S. Combs. All rights reserved.
//

#import "LegislatorDetailDataSource.h"

#import "LegislatorObj.h"
#import "TexLegeTheme.h"
#import "DistrictMapObj.h"

#import "DistrictOfficeObj.h"
#import "CommitteeObj.h"
#import "CommitteePositionObj.h"
#import "WnomObj.h"

#import "StaticGradientSliderView.h"
#import "UtilityMethods.h"
#import "DirectoryDetailInfo.h"
#import "TexLegeAppDelegate.h"

#import "PartisanIndexStats.h"
#import "UIImage+ResolutionIndependent.h"
#import "ImageCache.h"

#import "TexLegeStandardGroupCell.h"
#import "TexLegeGroupCellProtocol.h"

@interface LegislatorDetailDataSource (Private)
- (void) createSectionList;
@end


@implementation LegislatorDetailDataSource
@synthesize legislator, sectionArray;

- (id)initWithLegislator:(LegislatorObj *)newObject {
	if (self = [super init]) {
		if (newObject) 
			self.legislator = newObject;
		
	}
	return self;
}

- (void)dealloc {
	self.sectionArray = nil;
	self.legislator = nil;
	
    [super dealloc];
}

- (NSManagedObjectContext *)managedObjectContext {
	return [self.legislator managedObjectContext];
}

- (void)setLegislator:(LegislatorObj *)newLegislator {
	
	if (legislator) [legislator release], legislator = nil;
	if (newLegislator) {
		legislator = [newLegislator retain];
		
		[self createSectionList];		
	}
}

- (void) createSectionList {
	NSInteger numberOfSections = 3 + [self.legislator numberOfDistrictOffices];	
	NSString *tempString = nil;
	BOOL isPhone = [UtilityMethods canMakePhoneCalls];
	DirectoryDetailInfo *cellInfo = nil;
	
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
							   @"Name", @"subtitle",
							   [self.legislator fullName], @"entryValue",
							   [self.legislator fullName], @"title",
							   [NSNumber numberWithBool:NO], @"isClickable",
							   [NSNumber numberWithInteger:DirectoryTypeNone], @"entryType",
							   nil];
	cellInfo = [[DirectoryDetailInfo alloc] initWithDictionary:entryDict];
	[entryDict release];
	[[self.sectionArray objectAtIndex:sectionIndex] addObject:cellInfo];
	[cellInfo release], cellInfo = nil;
	
	
	entryDict = [[NSDictionary alloc] initWithObjectsAndKeys:
				 @"Web", @"subtitle",
				 self.legislator.website, @"entryValue",
				 @"Official Website", @"title",
				 [NSNumber numberWithBool:YES], @"isClickable",
				 [NSNumber numberWithInteger:DirectoryTypeWeb], @"entryType",
				 nil];
	cellInfo = [[DirectoryDetailInfo alloc] initWithDictionary:entryDict];
	[entryDict release];
	[[self.sectionArray objectAtIndex:sectionIndex] addObject:cellInfo];
	[cellInfo release], cellInfo = nil;
	
	
	entryDict = [[NSDictionary alloc] initWithObjectsAndKeys:
				 @"Map", @"subtitle",
				 self.legislator.districtMap, @"entryValue",
				 @"District Map", @"title",
				 [NSNumber numberWithBool:YES], @"isClickable",
				 [NSNumber numberWithInteger:DirectoryTypeMap], @"entryType",
				 nil];
	cellInfo = [[DirectoryDetailInfo alloc] initWithDictionary:entryDict];
	[entryDict release];
	[[self.sectionArray objectAtIndex:sectionIndex] addObject:cellInfo];
	[cellInfo release], cellInfo = nil;
	
	
	
	entryDict = [[NSDictionary alloc] initWithObjectsAndKeys:
				 @"Web", @"subtitle",
				 self.legislator.bio_url, @"entryValue",
				 @"Votesmart Bio", @"title",
				 [NSNumber numberWithBool:YES], @"isClickable",
				 [NSNumber numberWithInteger:DirectoryTypeWeb], @"entryType",
				 nil];
	cellInfo = [[DirectoryDetailInfo alloc] initWithDictionary:entryDict];
	[entryDict release];
	[[self.sectionArray objectAtIndex:sectionIndex] addObject:cellInfo];
	[cellInfo release], cellInfo = nil;
	
	
	entryDict = [[NSDictionary alloc] initWithObjectsAndKeys:
				 @"Email", @"subtitle",
				 self.legislator.email, @"entryValue",
				 self.legislator.email, @"title",
				 [NSNumber numberWithBool:YES], @"isClickable",
				 [NSNumber numberWithInteger:DirectoryTypeMail], @"entryType",
				 nil];
	cellInfo = [[DirectoryDetailInfo alloc] initWithDictionary:entryDict];
	[entryDict release];
	[[self.sectionArray objectAtIndex:sectionIndex] addObject:cellInfo];
	[cellInfo release], cellInfo = nil;
	
	
	
	if (self.legislator && self.legislator.twitter && [self.legislator.twitter length]) {
		tempString = ([self.legislator.twitter hasPrefix:@"@"]) ? self.legislator.twitter : [[[NSString alloc] initWithFormat:@"@%@", self.legislator.twitter] autorelease];
		entryDict = [[NSDictionary alloc] initWithObjectsAndKeys:
					 @"Twitter", @"subtitle",
					 tempString, @"entryValue",
					 tempString, @"title",
					 [NSNumber numberWithBool:YES], @"isClickable",
					 [NSNumber numberWithInteger:DirectoryTypeTwitter], @"entryType",
					 nil];
		cellInfo = [[DirectoryDetailInfo alloc] initWithDictionary:entryDict];
		[entryDict release];
		[[self.sectionArray objectAtIndex:sectionIndex] addObject:cellInfo];
		[cellInfo release], cellInfo = nil;
		
	}
	/*
	
	if ([UtilityMethods isIPadDevice] == NO && [self.legislator.partisan_index floatValue] != 0.0f) {
		entryDict = [[NSDictionary alloc] initWithObjectsAndKeys:
					 @"", @"subtitle",
					 [self.legislator.partisan_index description], @"entryValue",
					 @"", @"title",
					 [NSNumber numberWithBool:NO], @"isClickable",
					 [NSNumber numberWithInteger:DirectoryTypeIndex], @"entryType",
					 nil];
		cellInfo = [[DirectoryDetailInfo alloc] initWithDictionary:entryDict];
		[entryDict release];
		[[self.sectionArray objectAtIndex:sectionIndex] addObject:cellInfo];
		[cellInfo release], cellInfo = nil;
	}
	*/
	if (self.legislator.notes.length > 0)
		tempString = self.legislator.notes;
	else
		tempString = @"Notes";
	
	entryDict = [[NSDictionary alloc] initWithObjectsAndKeys:
				 @"Notes", @"subtitle",
				 tempString, @"entryValue",
				 tempString, @"title",
				 [NSNumber numberWithBool:YES], @"isClickable",
				 [NSNumber numberWithInteger:DirectoryTypeNotes], @"entryType",
				 nil];
	cellInfo = [[DirectoryDetailInfo alloc] initWithDictionary:entryDict];
	[entryDict release];
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
		cellInfo = [[DirectoryDetailInfo alloc] initWithDictionary:entryDict];
		[entryDict release];
		[[self.sectionArray objectAtIndex:sectionIndex] addObject:cellInfo];
		[cellInfo release], cellInfo = nil;
	}
	
	/* Now we handle all the office locations ... */
	sectionIndex++;
	/*	Section 1: Capitol Office */		
	
	if (self.legislator && self.legislator.staff && [self.legislator.staff length]) {
		entryDict = [[NSDictionary alloc] initWithObjectsAndKeys:
					 @"Staff", @"subtitle",
					 self.legislator.staff, @"entryValue",
					 self.legislator.staff, @"title",
					 [NSNumber numberWithBool:NO], @"isClickable",
					 [NSNumber numberWithInteger:DirectoryTypeNone], @"entryType",
					 nil];
		cellInfo = [[DirectoryDetailInfo alloc] initWithDictionary:entryDict];
		[entryDict release];
		[[self.sectionArray objectAtIndex:sectionIndex] addObject:cellInfo];
		[cellInfo release], cellInfo = nil;
	}
	
	if (self.legislator && self.legislator.cap_office && [self.legislator.cap_office length]) {
		entryDict = [[NSDictionary alloc] initWithObjectsAndKeys:
					 @"Office", @"subtitle",
					 [UtilityMethods capitolMapFromOfficeString:self.legislator.cap_office], @"entryValue",
					 self.legislator.cap_office, @"title",
					 [NSNumber numberWithBool:YES], @"isClickable",
					 [NSNumber numberWithInteger:DirectoryTypeOfficeMap], @"entryType",
					 nil];
		cellInfo = [[DirectoryDetailInfo alloc] initWithDictionary:entryDict];
		[entryDict release];
		[[self.sectionArray objectAtIndex:sectionIndex] addObject:cellInfo];
		[cellInfo release], cellInfo = nil;
	} 
	if (self.legislator && self.legislator.chamber_desk && [self.legislator.chamber_desk length]) {
		entryDict = [[NSDictionary alloc] initWithObjectsAndKeys:
					 @"Desk #", @"subtitle",
					 [UtilityMethods capitolMapFromChamber:self.legislator.legtype.integerValue], @"entryValue",
					 self.legislator.chamber_desk, @"title",
					 [NSNumber numberWithBool:YES], @"isClickable",
					 [NSNumber numberWithInteger:DirectoryTypeChamberMap], @"entryType",
					 nil];
		cellInfo = [[DirectoryDetailInfo alloc] initWithDictionary:entryDict];
		[entryDict release];
		[[self.sectionArray objectAtIndex:sectionIndex] addObject:cellInfo];
		[cellInfo release], cellInfo = nil;
	}
	if (self.legislator && self.legislator.cap_phone && [self.legislator.cap_phone length]) {
		entryDict = [[NSDictionary alloc] initWithObjectsAndKeys:
					 @"Phone", @"subtitle",
					 self.legislator.cap_phone, @"entryValue",
					 self.legislator.cap_phone, @"title",
					 [NSNumber numberWithBool:isPhone], @"isClickable",
					 [NSNumber numberWithInteger:DirectoryTypePhone], @"entryType",
					 nil];
		cellInfo = [[DirectoryDetailInfo alloc] initWithDictionary:entryDict];
		[entryDict release];
		[[self.sectionArray objectAtIndex:sectionIndex] addObject:cellInfo];
		[cellInfo release], cellInfo = nil;
	} 
	if (self.legislator && self.legislator.cap_fax && [self.legislator.cap_fax length]) {
		entryDict = [[NSDictionary alloc] initWithObjectsAndKeys:
					 @"Fax", @"subtitle",
					 self.legislator.cap_fax, @"entryValue",
					 self.legislator.cap_fax, @"title",
					 [NSNumber numberWithBool:NO], @"isClickable",
					 [NSNumber numberWithInteger:DirectoryTypeNone], @"entryType",
					 nil];
		cellInfo = [[DirectoryDetailInfo alloc] initWithDictionary:entryDict];
		[entryDict release];
		[[self.sectionArray objectAtIndex:sectionIndex] addObject:cellInfo];
		[cellInfo release], cellInfo = nil;
	}
	if (self.legislator && self.legislator.cap_phone2 && [self.legislator.cap_phone2 length]) {
		tempString = (self.legislator.cap_phone2_name.length > 0) ? self.legislator.cap_phone2_name : @"Phone #2";
		entryDict = [[NSDictionary alloc] initWithObjectsAndKeys:
					 tempString, @"subtitle",
					 self.legislator.cap_phone2, @"entryValue",
					 self.legislator.cap_phone2, @"title",
					 [NSNumber numberWithBool:isPhone], @"isClickable",
					 [NSNumber numberWithInteger:DirectoryTypePhone], @"entryType",
					 nil];
		cellInfo = [[DirectoryDetailInfo alloc] initWithDictionary:entryDict];
		[entryDict release];
		[[self.sectionArray objectAtIndex:sectionIndex] addObject:cellInfo];
		[cellInfo release], cellInfo = nil;
	} 
	
	/* after that section's done... */
	
	for (DistrictOfficeObj *office in self.legislator.districtOffices) {
		sectionIndex++;
		if (office.phone && [office.phone length]) {
			entryDict = [[NSDictionary alloc] initWithObjectsAndKeys:
						 @"Phone", @"subtitle",
						 office.phone, @"entryValue",
						 office.phone, @"title",
						 [NSNumber numberWithBool:isPhone], @"isClickable",
						 [NSNumber numberWithInteger:DirectoryTypePhone], @"entryType",
						 nil];
			cellInfo = [[DirectoryDetailInfo alloc] initWithDictionary:entryDict];
			[entryDict release];
			[[self.sectionArray objectAtIndex:sectionIndex] addObject:cellInfo];
			[cellInfo release], cellInfo = nil;
		}			
		if (office.fax && [office.fax length]) {
			entryDict = [[NSDictionary alloc] initWithObjectsAndKeys:
						 @"Fax", @"subtitle",
						 office.fax, @"entryValue",
						 office.fax, @"title",
						 [NSNumber numberWithBool:NO], @"isClickable",
						 [NSNumber numberWithInteger:DirectoryTypeNone], @"entryType",
						 nil];
			cellInfo = [[DirectoryDetailInfo alloc] initWithDictionary:entryDict];
			[entryDict release];
			[[self.sectionArray objectAtIndex:sectionIndex] addObject:cellInfo];
			[cellInfo release], cellInfo = nil;
		}			
		if (office.address && [office.address length]) {
			
			entryDict = [[NSDictionary alloc] initWithObjectsAndKeys:
						 @"Address", @"subtitle",
						 office, @"entryValue",
						 [office cellAddress], @"title",
						 [NSNumber numberWithBool:YES], @"isClickable",
						 [NSNumber numberWithInteger:DirectoryTypeMap], @"entryType",
						 nil];
			cellInfo = [[DirectoryDetailInfo alloc] initWithDictionary:entryDict];
			[entryDict release];
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
	NSArray *group = [self.sectionArray objectAtIndex:indexPath.section];
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
	NSArray *group = [self.sectionArray objectAtIndex:section];
	if (group)
		return [group count];

	return 0;
}

- (NSString *)tableView:(UITableView *)aTableView titleForHeaderInSection:(NSInteger)section {	
	if (section == 0)
		return @"Legislator Information";
	else if (section == 1)
		return @"Committee Assignments";
	else if (section == 2)
		return @"Capitol Office";
	else if (section == 3)
		return @"District Office #1";
	else if (section == 4)
		return @"District Office #2";
	else if (section == 5)
		return @"District Office #3";
	else //if (section == 6)
		return @"District Office #4";
}



- (NSString *)chamberAbbrev {
	NSString *chamberName = nil;
	if ([self.legislator.legtype integerValue] == HOUSE) // Representative
		chamberName = @"House";
	else if ([self.legislator.legtype integerValue] == SENATE) // Senator
		chamberName = @"Senate";
	else // don't know the party?
		chamberName = @"";
	
	return chamberName;
}

- (NSString *)chamberPartyAbbrev {
	NSString *partyName = nil;
	if ([self.legislator.party_id integerValue] == DEMOCRAT) // Democrat
		partyName = @"Dem.";
	else if ([self.legislator.party_id integerValue] == REPUBLICAN) // Republican
		partyName = @"Rep.";
	else // don't know the party?
		partyName = @"Ind.";
	
	return [NSString stringWithFormat:@"%@ %@ Avg.", [self chamberAbbrev], partyName];
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
		
	DirectoryDetailInfo *cellInfo = [self dataObjectForIndexPath:indexPath];
		
	if (cellInfo == nil) {
		debug_NSLog(@"LegislatorDetailDataSource:cellForRow: error finding table entry for section:%d row:%d", indexPath.section, indexPath.row);
		return nil;
	}
	
	NSString *cellIdentifier = [NSString stringWithFormat:@"%@-%d", [TexLegeStandardGroupCell cellIdentifier], cellInfo.isClickable];
	
	/* Look up cell in the table queue */
	UITableViewCell *cell = [aTableView dequeueReusableCellWithIdentifier:cellIdentifier];
	
	/* Not found in queue, create a new cell object */
    if (cell == nil) {
		cell = [[[TexLegeStandardGroupCell alloc] initWithStyle:[TexLegeStandardGroupCell cellStyle] reuseIdentifier:cellIdentifier] autorelease];
    }
    
	if ([cell conformsToProtocol:@protocol(TexLegeGroupCellProtocol)])
		 [cell performSelector:@selector(setCellInfo:) withObject:cellInfo];
		
	if (cellInfo.entryType == DirectoryTypeNotes) {
		if (self.legislator.notes.length > 0)
			cell.detailTextLabel.textColor = [UIColor blackColor];
		else
			cell.detailTextLabel.textColor = [UIColor grayColor];
	}
	else if (cellInfo.entryType == DirectoryTypeMap) {
			cell.detailTextLabel.lineBreakMode = UILineBreakModeWordWrap;
			cell.detailTextLabel.numberOfLines = 4;
	}			
	
	[cell sizeToFit];
	[cell setNeedsDisplay];
	
	return cell;
	
}


@end