// 
//  CommitteeObj.m
//  Created by Gregory Combs on 7/11/09.
//
//  StatesLege by Sunlight Foundation, based on work at https://github.com/sunlightlabs/StatesLege
//
//  This work is licensed under the Creative Commons Attribution-NonCommercial 3.0 Unported License. 
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc/3.0/
//  or send a letter to Creative Commons, 444 Castro Street, Suite 900, Mountain View, California, 94041, USA.
//
//

#import "CommitteeObj+RestKit.h"
#import "CommitteePositionObj.h"
#import "LegislatorObj+RestKit.h"
#import <SLFRestKit/SLFRestKit.h>
#import "TexLegeLibrary.h"

static RKManagedObjectMapping *committeeAttributesMapping = nil;

@implementation CommitteeObj (RestKit)

+ (NSString*)primaryKeyProperty
{
    return @"committeeId";
}

+ (RKManagedObjectMapping *)attributeMapping
{
    if (committeeAttributesMapping)
        return committeeAttributesMapping;

    RKManagedObjectMapping *mapping = [RKManagedObjectMapping mappingForClass:[self class] inManagedObjectStore:[RKObjectManager sharedManager].objectStore];
    mapping.primaryKeyAttribute = @"committeeId";
    [mapping mapAttributesFromArray:@[
                                      @"committeeId",
                                      @"committeeName",
                                      @"committeeType",
                                      @"openstatesID",
                                      @"txlonline_id",
                                      @"parentId",
                                      @"votesmartID",
                                      @"clerk",
                                      @"clerk_email",
                                      @"office",
                                      @"phone",
                                      @"url",
                                      ]];
    [mapping mapKeyPath:@"updated" toAttribute:@"updatedDate"];

    //[mapping connectRelationship:@"state" withObjectForPrimaryKeyAttribute:@"stateID"];
    //[mapping hasMany:@"committeePositions" withMapping:committeePositionMapping];

    committeeAttributesMapping = mapping;

    return mapping;
}

#pragma mark Custom Accessors

- (NSString *)committeeNameInitial
{
	[self willAccessValueForKey:@"committeeNameInitial"];
	NSString * initial = [self.committeeName substringToIndex:1];
	[self didAccessValueForKey:@"committeeNameInitial"];
	return initial;
}

- (NSString*)typeString
{
	return stringForChamber((self.committeeType).integerValue, TLReturnFull);
}

- (NSString*)description
{
	NSString  *typeName = [NSString stringWithFormat: @"%@ (%@)", self.committeeName, [self typeString]];
	return typeName;
}

- (LegislatorObj *)chair
{
	for (CommitteePositionObj *position in self.committeePositions)
    {
		if (position.legislator && position.position.integerValue == POS_CHAIR)
			return position.legislator;
	}
	 return nil;
}
				 
- (LegislatorObj *)vicechair
{
	for (CommitteePositionObj *position in self.committeePositions)
    {
		if (position.legislator && position.position.integerValue == POS_VICE)
			return position.legislator;
	}
	return nil;
}

- (NSArray<LegislatorObj *> *)sortedMembers
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"legislator != nil AND position == %@", @(POS_MEMBER)];
    NSSet *filteredPositions = [self.committeePositions filteredSetUsingPredicate:predicate];

    NSMutableArray *members = [[NSMutableArray alloc] init];
    for (CommitteePositionObj *position in filteredPositions)
    {
        LegislatorObj *legislator = position.legislator;
        if (!legislator)
            continue;
        [members addObject:legislator];
    }

    NSSortDescriptor *sortByLast = [NSSortDescriptor sortDescriptorWithKey:@"lastname" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)];
    NSSortDescriptor *sortByFirst = [NSSortDescriptor sortDescriptorWithKey:@"firstname" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)];
    //NSSortDescriptor *sortLastNameFirst = [NSSortDescriptor sortDescriptorWithKey:@"fullNameLastFirst" ascending:YES];
    [members sortUsingDescriptors:@[sortByLast,sortByFirst]];

    return [members copy];
}

@end
