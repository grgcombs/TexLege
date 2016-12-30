// 
//  StafferObj+RestKit.m
//  Created by Gregory Combs on 1/22/11.
//
//  StatesLege by Sunlight Foundation, based on work at https://github.com/sunlightlabs/StatesLege
//
//  This work is licensed under the Creative Commons Attribution-NonCommercial 3.0 Unported License. 
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc/3.0/
//  or send a letter to Creative Commons, 444 Castro Street, Suite 900, Mountain View, California, 94041, USA.
//
//

#import "StafferObj+RestKit.h"

static RKManagedObjectMapping *stafferAttributeMapping = nil;

@implementation StafferObj (RestKit)

+ (NSString*)primaryKeyProperty
{
	return @"stafferID";
}

+ (RKManagedObjectMapping *)attributeMapping
{
    if (stafferAttributeMapping)
        return stafferAttributeMapping;

    RKManagedObjectMapping *mapping = [RKManagedObjectMapping mappingForClass:[self class] inManagedObjectStore:[RKObjectManager sharedManager].objectStore];
    mapping.primaryKeyAttribute = @"stafferID";
    [mapping mapAttributesFromArray:@[
                                      @"phone",
                                      @"stafferID",
                                      @"legislatorID",
                                      @"name",
                                      @"email",
                                      @"title",
                                      ]];
    [mapping mapKeyPath:@"updated" toAttribute:@"updatedDate"];
    [mapping connectRelationship:@"legislator" withObjectForPrimaryKeyAttribute:@"legislatorID"];

    stafferAttributeMapping = mapping;

    return mapping;
}

@end
