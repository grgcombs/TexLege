//
//  DistrictOfficeObj+RestKit.m
//  Created by Gregory Combs on 4/14/11.
//
//  StatesLege by Sunlight Foundation, based on work at https://github.com/sunlightlabs/StatesLege
//
//  This work is licensed under the Creative Commons Attribution-NonCommercial 3.0 Unported License. 
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc/3.0/
//  or send a letter to Creative Commons, 444 Castro Street, Suite 900, Mountain View, California, 94041, USA.
//
//

#import "DistrictOfficeObj+RestKit.h"
#import <SLFRestKit/SLFRestKit.h>

static RKManagedObjectMapping *officeMapping = nil;

@implementation DistrictOfficeObj (RestKit)

+ (NSString*)primaryKeyProperty
{
	return @"districtOfficeID";
}

+ (RKManagedObjectMapping *)attributeMapping
{
    if (officeMapping)
        return officeMapping;

    RKManagedObjectMapping *mapping = [RKManagedObjectMapping mappingForClass:[self class] inManagedObjectStore:[RKObjectManager sharedManager].objectStore];
    mapping.primaryKeyAttribute = @"districtOfficeID";
    [mapping mapAttributesFromArray:@[
                                      @"districtOfficeID",
                                      @"legislatorID",
                                      @"district",
                                      @"chamber",
                                      @"address",
                                      @"city",
                                      @"county",
                                      @"stateCode",
                                      @"zipCode",
                                      @"phone",
                                      @"fax",
                                      @"formattedAddress",
                                      @"latitude",
                                      @"longitude",
                                      @"spanLat",
                                      @"spanLon",
                                      @"pinColorIndex",
                                      ]];
    [mapping mapKeyPath:@"updated" toAttribute:@"updatedDate"];
    //[mapping connectRelationship:@"legislator" withObjectForPrimaryKeyAttribute:@"legislatorID"];

    officeMapping = mapping;

    return mapping;
}

@end
