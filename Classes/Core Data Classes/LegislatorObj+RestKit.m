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
#import <SLFRestKit/SLFRestKit.h>
#import "CommitteePositionObj+RestKit.h"
#import "WnomObj+RestKit.h"
#import "UtilityMethods.h"

static RKManagedObjectMapping *legislatorAttributesMapping = nil;

@implementation LegislatorObj (RestKit)

+ (NSString*)primaryKeyProperty
{
    return @"legislatorID";
}

+ (RKManagedObjectMapping *)attributeMapping
{
    if (legislatorAttributesMapping)
        return legislatorAttributesMapping;

    RKManagedObjectMapping *mapping = [RKManagedObjectMapping mappingForClass:[self class] inManagedObjectStore:[RKObjectManager sharedManager].objectStore];
    mapping.primaryKeyAttribute = @"legislatorID";
    [mapping mapAttributesFromArray:@[
                                      @"legislatorID",
                                      @"firstname",
                                      @"middlename",
                                      @"lastname",
                                      @"suffix",
                                      @"nickname",
                                      @"preferredname",
                                      @"stateID",
                                      @"district",
                                      @"legtype",
                                      @"legtype_name",
                                      @"photo_name",
                                      @"photo_url",
                                      @"party_id",
                                      @"party_name",
                                      @"tenure",
                                      @"nextElection",
                                      @"bio_url",
                                      @"twitter",
                                      @"cap_office",
                                      @"cap_phone",
                                      @"cap_phone2",
                                      @"cap_phone2_name",
                                      @"cap_fax",
                                      @"email",
                                      @"partisan_index",
                                      @"notes",
                                      @"txlonline_id",
                                      @"openstatesID",
                                      @"nimsp_id",
                                      @"transDataContributorID",
                                      @"votesmartDistrictID",
                                      @"votesmartID",
                                      @"votesmartOfficeID",
                                      ]];
    [mapping mapKeyPath:@"updated" toAttribute:@"updatedDate"];

    //[mapping connectRelationship:@"state" withObjectForPrimaryKeyAttribute:@"stateID"];
    
    //[mapping hasMany:@"committeePositions" withMapping:committeePositionMapping];
    //[mapping hasMany:@"staffers" withMapping:stafferMapping];

    legislatorAttributesMapping = mapping;

    return mapping;
}

- (NSComparisonResult)compareMembersByName:(LegislatorObj *)p
{
    if (!p || ![p isKindOfClass:self.class])
        return NSOrderedAscending;
    
	return [[self fullNameLastFirst] compare: [p fullNameLastFirst]];	
}

- (NSString *)lastnameInitial
{
	[self willAccessValueForKey:@"lastnameInitial"];
	NSString * initial = [self.lastname substringToIndex:1];
	[self didAccessValueForKey:@"lastnameInitial"];
	return initial;
}

- (void)setLastnameInitial:(NSString *)newName
{
	// ignore this
}

- (NSString *)partyShortName
{
	return stringForParty((self.party_id).integerValue, TLReturnInitial);
}

- (NSString *)legTypeShortName
{
	return abbreviateString(self.legtype_name);
/*	if ([self.legtype_name isEqualToString:NSLocalizedStringFromTable(@"Speaker", @"DataTableUI", @"The speaker of the house")])
		return NSLocalizedStringFromTable(@"Spk.", @"DataTableUI", @"Abbreviation for the Speaker");
	else
		return [[self.legtype_name substringToIndex:3] stringByAppendingString:@"."];
*/
}

- (NSString *)legProperName
{
	NSMutableString *name = [@"" mutableCopy];
	if (self.firstname.length > 0)
		[name appendString:self.firstname];
	else if (self.middlename.length > 0)
		[name appendString:self.firstname];
	if (self.lastname.length > 0)
        [name appendFormat:@" %@", self.lastname];
	if (self.suffix.length > 0)
		[name appendFormat:@", %@", self.suffix];

	return name;
}

- (NSString *)districtPartyString
{
	return [NSString stringWithFormat: @"(%@-%ld)", self.partyShortName, (long)(self.district).integerValue];
}

- (NSString *)fullName
{
	NSMutableString *name = [@"" mutableCopy];

	if (self.firstname.length > 0)
		[name appendString:self.firstname];
	if (self.middlename.length > 0)
		[name appendFormat:@" %@", self.middlename];
	if (self.nickname.length > 0)
		[name appendFormat:@" \"%@\"", self.nickname];
	if (self.lastname.length > 0)
		[name appendFormat:@" %@", self.lastname];
	if (self.suffix.length > 0)
		[name appendFormat:@", %@", self.suffix];

	return name;
}

- (NSString *)fullNameLastFirst
{
    NSMutableString *name = [@"" mutableCopy];

    if (self.lastname.length > 0)
        [name appendFormat:@" %@", self.lastname];
    if (self.firstname.length > 0)
        [name appendString:self.firstname];
    if (self.middlename.length > 0)
        [name appendFormat:@" %@", self.middlename];
    if (self.suffix.length > 0)
        [name appendFormat:@", %@", self.suffix];

	return name;
}

- (NSString *)shortNameForButtons
{
	return [NSString stringWithFormat:@"%@ (%@)", [self legProperName], [self partyShortName]];
}

- (NSString *)labelSubText
{
	return [NSString stringWithFormat: NSLocalizedStringFromTable(@"%@ - District %d", @"DataTableUI", @"The person and their district number"),
			self.legtype_name, (self.district).integerValue];
}

- (NSString *)website
{
	NSString *formatString = nil;
	if (self.legtype.integerValue == HOUSE)
		formatString = [UtilityMethods texLegeStringWithKeyPath:@"OfficialURLs.houseWeb"];	// contains format placeholders
	else
		formatString = [UtilityMethods texLegeStringWithKeyPath:@"OfficialURLs.senateWeb"];	// contains format placeholders
	
	if (!formatString)
        return nil;
    return [formatString stringByReplacingOccurrencesOfString:@"%@" withString:self.district.stringValue];
}

- (NSString*)searchName
{
	NSString * tempString = nil;
	[self willAccessValueForKey:@"searchName"];
	tempString = [NSString stringWithFormat: @"%@ %@ %@", [self legTypeShortName], [self legProperName], [self districtPartyString]];
	[self didAccessValueForKey:@"searchName"];
	return tempString;
}

 - (NSInteger)numberOfDistrictOffices
{
    NSSet *offices = self.districtOffices;
	if (IsEmpty(offices))
		return 0;
	else
		return offices.count;
}

- (NSInteger)numberOfStaffers
{
    NSSet *staffers = self.staffers;
	if (IsEmpty(staffers))
		return 0;
	else
		return staffers.count;
}

- (NSString *)tenureString
{
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
    NSSet *positions = self.committeePositions;
	return [positions.allObjects sortedArrayUsingSelector:@selector(comparePositionAndCommittee:)];
}

- (NSArray *)sortedStaffers
{
	NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"title" ascending:YES];
    return [self.staffers sortedArrayUsingDescriptors:@[sortDescriptor]];
}

- (NSString *)districtMapURL
{
	NSString *chamber = stringForChamber((self.legtype).integerValue, TLReturnFull);
	NSString *formatString = [UtilityMethods texLegeStringWithKeyPath:@"OfficialURLs.mapPdfUrl"];	// contains format placeholders
	if (chamber && formatString && self.district)
		return [NSString stringWithFormat:formatString, chamber, self.district];
	return nil;	
}

- (NSString *)chamberName
{
	return  stringForChamber(self.legtype.integerValue, TLReturnFull);
}

- (WnomObj *)latestWnomScore
{
	NSSortDescriptor *sortBySession = [NSSortDescriptor sortDescriptorWithKey:@"session" ascending:NO];
    NSSet *scores = self.wnomScores;
	NSArray *wnoms = [scores sortedArrayUsingDescriptors:@[sortBySession]];
	if (!IsEmpty(wnoms))
		return wnoms[0];
	return nil;
}

- (double)latestWnomFloat
{
	WnomObj *latest = self.latestWnomScore;
    if (!latest)
        return 0;
    return latest.wnomAdj.doubleValue;
}

@end
