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
#import "LegislatorObj.h"
#import "LegislatorObj+RestKit.h"

@implementation CommitteeObj (RestKit)

#pragma mark RKObjectMappable methods

+ (NSDictionary*)elementToPropertyMappings {
	return [NSDictionary dictionaryWithKeysAndObjects:
			@"committeeId", @"committeeId",
			@"clerk", @"clerk",
			@"clerk_email", @"clerk_email",
			@"committeeName", @"committeeName",
			@"committeeType", @"committeeType",
			@"office", @"office",
			@"openstatesID", @"openstatesID",
			@"parentId", @"parentId",
			@"phone", @"phone",
			@"txlonline_id", @"txlonline_id",
			@"url", @"url",
			@"votesmartID", @"votesmartID",
			@"updated", @"updated",
			nil];
}

+ (NSString*)primaryKeyProperty {
	return @"committeeId";
}

#pragma mark Property Accessor Issues
/* These methods are the exact same thing (or at least *should* be the same) as the default core data object methods
 However, for whatever reason, sometimes the default returns an NSNumber instead of an NSString ... this makes sure */
- (NSString *)updated {
	[self willAccessValueForKey:@"updated"];
	NSString *outValue = [self primitiveValueForKey:@"updated"];
	[self didAccessValueForKey:@"updated"];
	return outValue;
}

- (void)setUpdated:(NSString *)inValue {
	[self willChangeValueForKey:@"updated"];
	[self setPrimitiveValue:inValue forKey:@"updated"];
	[self didChangeValueForKey:@"updated"];
}

#pragma mark Custom Accessors

- (NSString *) committeeNameInitial {
	[self willAccessValueForKey:@"committeeNameInitial"];
	NSString * initial = [[self committeeName] substringToIndex:1];
	[self didAccessValueForKey:@"committeeNameInitial"];
	return initial;
}

- (NSString*)typeString {
	return stringForChamber([self.committeeType integerValue], TLReturnFull);
}

- (NSString*)description {
	NSString  *typeName = [NSString stringWithFormat: @"%@ (%@)", [self committeeName], [self typeString]];
	return typeName;
}

- (LegislatorObj *)chair
{
	for (CommitteePositionObj *position in [self committeePositions]) {
		if (position.legislator && [[position position] integerValue] == POS_CHAIR)
			return position.legislator;
	}
	 return nil;
}
				 
- (LegislatorObj *)vicechair
{
	for (CommitteePositionObj *position in [self committeePositions]) {
		if (position.legislator && [[position position] integerValue] == POS_VICE)
			return position.legislator;
	}
	return nil;
}

- (NSArray *)sortedMembers
{
	NSMutableArray *memberArray = [[[NSMutableArray alloc] init] autorelease];
	for (CommitteePositionObj *position in [self committeePositions]) {
		if (position.legislator && [[position position] integerValue] == POS_MEMBER)
			[memberArray addObject:position.legislator];
	}
	[memberArray sortUsingSelector:@selector(compareMembersByName:)];

	return memberArray;
}

@end
