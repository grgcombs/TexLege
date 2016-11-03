// 
//  LegislatorObj.m
//  Created by Gregory Combs on 7/10/09.
//
//  StatesLege by Sunlight Foundation, based on work at https://github.com/sunlightlabs/StatesLege
//
//  This work is licensed under the Creative Commons Attribution-NonCommercial 3.0 Unported License. 
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc/3.0/
//  or send a letter to Creative Commons, 444 Castro Street, Suite 900, Mountain View, California, 94041, USA.
//
//

#import "LegislatorObj+RestKit.h"
#import "CommitteePositionObj.h"
#import "WnomObj.h"
#import "UtilityMethods.h"
#import "CommitteePositionObj+RestKit.h"

@implementation LegislatorObj (RestKit)

#pragma mark RKObjectMappable methods

+ (NSDictionary*)elementToPropertyMappings {	
	return [NSDictionary dictionaryWithKeysAndObjects:
			@"partisan_index", @"partisan_index",
			@"bio_url", @"bio_url",
			@"cap_fax", @"cap_fax",
			@"cap_office", @"cap_office",
			@"cap_phone", @"cap_phone",
			@"cap_phone2", @"cap_phone2",
			@"cap_phone2_name", @"cap_phone2_name",
			@"district", @"district",
			@"email", @"email",
			@"firstname", @"firstname",
			@"lastname", @"lastname",
			@"legislatorID", @"legislatorID",
			@"legtype", @"legtype",
			@"legtype_name", @"legtype_name",
			@"middlename", @"middlename",
			@"nextElection", @"nextElection",
			@"nickname", @"nickname",
			@"nimsp_id", @"nimsp_id",
			@"notes", @"notes",
			@"openstatesID", @"openstatesID",
			@"party_id", @"party_id",
			@"party_name", @"party_name",
			@"photo_name", @"photo_name",
			@"photo_url", @"photo_url",
			@"preferredname", @"preferredname",
			@"stateID", @"stateID",
			@"suffix", @"suffix",
			@"tenure", @"tenure",
			@"transDataContributorID", @"transDataContributorID",
			@"twitter", @"twitter",
			@"txlonline_id", @"txlonline_id",
			@"votesmartDistrictID", @"votesmartDistrictID",
			@"votesmartID", @"votesmartID",
			@"votesmartOfficeID", @"votesmartOfficeID",
			@"updated",@"updatedDate",
			nil];
}

+ (NSString*)primaryKeyProperty {
	return @"legislatorID";
}


#pragma mark Custom Accessors

- (NSComparisonResult)compareMembersByName:(LegislatorObj *)p
{	
	return [[self fullNameLastFirst] compare: [p fullNameLastFirst]];	
}

- (NSString *) lastnameInitial {
	[self willAccessValueForKey:@"lastnameInitial"];
	NSString * initial = [self.lastname substringToIndex:1];
	[self didAccessValueForKey:@"lastnameInitial"];
	return initial;
}

- (void) setLastnameInitial:(NSString *)newName {
	// ignore this
}

- (NSString *)partyShortName {
	return stringForParty((self.party_id).integerValue, TLReturnInitial);
}

- (NSString *)legTypeShortName {
	return abbreviateString(self.legtype_name);
/*	if ([self.legtype_name isEqualToString:NSLocalizedStringFromTable(@"Speaker", @"DataTableUI", @"The speaker of the house")])
		return NSLocalizedStringFromTable(@"Spk.", @"DataTableUI", @"Abbreviation for the Speaker");
	else
		return [[self.legtype_name substringToIndex:3] stringByAppendingString:@"."];
*/
}

- (NSString *)legProperName {
	NSMutableString *name = [NSMutableString stringWithCapacity:128];
	if ((self.firstname).length > 0)
		[name appendString:self.firstname];
	else if ((self.middlename).length > 0)
		[name appendString:self.firstname];
	
	[name appendFormat:@" %@", self.lastname];
	
	if ((self.suffix).length > 0)
		[name appendFormat:@", %@", self.suffix];

	return name;
}

- (NSString *)districtPartyString {
	NSString *string = [NSString stringWithFormat: @"(%@-%ld)", self.partyShortName, (long)(self.district).integerValue];
	return string;
}

- (NSString *)fullName {
	NSMutableString *name = [NSMutableString stringWithCapacity:128];

	if ((self.firstname).length > 0)
		[name appendString:self.firstname];
	if ((self.middlename).length > 0)
		[name appendFormat:@" %@", self.middlename];
	if ((self.nickname).length > 0)
		[name appendFormat:@" \"%@\"", self.nickname];
	if ((self.lastname).length > 0)
		[name appendFormat:@" %@", self.lastname];
	if ((self.suffix).length > 0)
		[name appendFormat:@", %@", self.suffix];

	return name;
}

- (NSString *)fullNameLastFirst {
	NSMutableString *name = [NSMutableString stringWithCapacity:128];
	
	if ((self.lastname).length > 0)
		[name appendFormat:@"%@, ", self.lastname];
	if ((self.firstname).length > 0)
		[name appendString:self.firstname];
	if ((self.middlename).length > 0)
		[name appendFormat:@" %@", self.middlename];
	if ((self.suffix).length > 0)
		[name appendFormat:@" %@", self.suffix];
	
	return name;
}

- (NSString *)shortNameForButtons {
	NSString *string;
	string = [NSString stringWithFormat:@"%@ (%@)", [self legProperName], [self partyShortName]];
	return string;
}

- (NSString *)labelSubText {
	NSString *string;
	string = [NSString stringWithFormat: NSLocalizedStringFromTable(@"%@ - District %d", @"DataTableUI", @"The person and their district number"),
			self.legtype_name, (self.district).integerValue];
	return string;
}

- (NSString *)website {
	NSString *formatString = nil;
	if ((self.legtype).integerValue == HOUSE)
		formatString = [UtilityMethods texLegeStringWithKeyPath:@"OfficialURLs.houseWeb"];	// contains format placeholders
	else
		formatString = [UtilityMethods texLegeStringWithKeyPath:@"OfficialURLs.senateWeb"];	// contains format placeholders
	
	if (formatString)
		return [formatString stringByReplacingOccurrencesOfString:@"%@" withString:(self.district).stringValue];
	return nil;
}

- (NSString*)searchName {
	NSString * tempString;
	[self willAccessValueForKey:@"searchName"];
	tempString = [NSString stringWithFormat: @"%@ %@ %@", [self legTypeShortName], 
			[self legProperName], [self districtPartyString]];
	[self didAccessValueForKey:@"searchName"];
	return tempString;
}

 - (NSInteger)numberOfDistrictOffices {
	if (IsEmpty(self.districtOffices))
		return 0;
	else
		return (self.districtOffices).count;
}

- (NSInteger)numberOfStaffers {
	if (IsEmpty(self.staffers))
		return 0;
	else
		return (self.staffers).count;
}

- (NSString *)tenureString {
	NSString *stringVal = nil;
	NSInteger years = self.tenure.integerValue;
	
	switch (years) {
		case 0:
			stringVal = NSLocalizedStringFromTable(@"Freshman", @"DataTableUI", @"The title for a legislator who was recently elected for the first time");
			break;
		case 1:
			stringVal = [NSString stringWithFormat:NSLocalizedStringFromTable(@"%d Year", @"DataTableUI", @"Singular form of a year"),
						 years];
			break;
		default:
			stringVal = [NSString stringWithFormat:NSLocalizedStringFromTable(@"%d Years", @"DataTableUI", @"Plural form of a year"), 
						 years];
			break;
	}
	return stringVal;
}

- (NSArray *)sortedCommitteePositions
{
	return [(self.committeePositions).allObjects 
							sortedArrayUsingSelector:@selector(comparePositionAndCommittee:)];
}

- (NSArray *)sortedStaffers {
	NSSortDescriptor *sortDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"title" ascending:YES] autorelease];
	return [(self.staffers).allObjects 
			sortedArrayUsingDescriptors:@[sortDescriptor]];
}

- (NSString *)districtMapURL
{
	NSString *chamber = stringForChamber((self.legtype).integerValue, TLReturnFull);
	NSString *formatString = [UtilityMethods texLegeStringWithKeyPath:@"OfficialURLs.mapPdfUrl"];	// contains format placeholders
	if (chamber && formatString && self.district)
		return [NSString stringWithFormat:formatString, chamber, self.district];
	return nil;	
}

- (NSString *)chamberName {	
	return  stringForChamber((self.legtype).integerValue, TLReturnFull);
}

- (WnomObj *)latestWnomScore {
	NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"session"ascending:NO];
	NSArray *wnoms = [(self.wnomScores).allObjects sortedArrayUsingDescriptors:@[sortDescriptor]];
	
	if (!IsEmpty(wnoms))
		return wnoms[0];
	return nil;
}

- (CGFloat)latestWnomFloat {
	CGFloat retVal = 0.0f;
	WnomObj *latest = self.latestWnomScore;
	if (latest)
		retVal = (latest.wnomAdj).floatValue;
	return retVal;
}
@end
