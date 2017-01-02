// 
//  CommitteePositionObj.m
//  Created by Gregory Combs on 7/10/09.
//
//  StatesLege by Sunlight Foundation, based on work at https://github.com/sunlightlabs/StatesLege
//
//  This work is licensed under the Creative Commons Attribution-NonCommercial 3.0 Unported License. 
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc/3.0/
//  or send a letter to Creative Commons, 444 Castro Street, Suite 900, Mountain View, California, 94041, USA.
//
//

#import "CommitteePositionObj+RestKit.h"
#import "CommitteeObj+RestKit.h"
#import "LegislatorObj+RestKit.h"
#import "TexLegeCoreDataUtils.h"
#import <SLFRestKit/SLFRestKit.h>

static RKManagedObjectMapping *positionAttributesMapping = nil;

@implementation CommitteePositionObj (RestKit)

+ (NSString*)primaryKeyProperty
{
    return @"committeePositionID";
}

+ (RKManagedObjectMapping *)attributeMapping
{
    if (positionAttributesMapping)
        return positionAttributesMapping;

    RKManagedObjectMapping *mapping = [RKManagedObjectMapping mappingForClass:[self class] inManagedObjectStore:[RKObjectManager sharedManager].objectStore];
    mapping.primaryKeyAttribute = @"committeePositionID";
    [mapping mapAttributesFromArray:@[
                                      @"committeePositionID",
                                      @"legislatorID",
                                      @"committeeId",
                                      @"position",
                                      ]];

    [mapping mapKeyPath:@"updated" toAttribute:@"updatedDate"];
    //[mapping connectRelationship:@"legislator" withObjectForPrimaryKeyAttribute:@"legislatorID"];
    //[mapping connectRelationship:@"committee" withObjectForPrimaryKeyAttribute:@"committeeId"];

    positionAttributesMapping = mapping;

    return mapping;
}

- (NSString*)positionString
{
    NSNumber *position = self.position;
	if (position.integerValue == POS_CHAIR)
		return NSLocalizedStringFromTable(@"Chair", @"DataTableUI", @"Abbreviation / title for a person who is the committee chairperson");
	else if (position.integerValue == POS_VICE) 
		return NSLocalizedStringFromTable(@"Vice Chair", @"DataTableUI", @"Abbreviation / title for a person who is second to the committee chairperson");
	else
		return NSLocalizedStringFromTable(@"Member", @"DataTableUI", @"Title for a person who is a regular member of a committe (not chair/vice-chair)");
}

- (NSComparisonResult)comparePositionAndCommittee:(CommitteePositionObj *)p
{
    if (!p || ![p isKindOfClass:self.class])
        return NSOrderedDescending;

	NSInteger selfOrder = self.position.integerValue;
	NSInteger comparedToOrder = p.position.integerValue;
	NSComparisonResult result = NSOrderedSame;
	
	if (selfOrder < comparedToOrder) // reversed order, lower position id is higher
		result = NSOrderedDescending;
	else if (selfOrder > comparedToOrder)
		result = NSOrderedAscending;
	else { // they're both the same position (i.e. just a regular committee member)
		result = [self.committee.committeeName compare: p.committee.committeeName];
	}
	return result;	
}

@end
