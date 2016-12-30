// 
//  LinkObj.m
//  Created by Gregory Combs on 7/10/09.
//
//  StatesLege by Sunlight Foundation, based on work at https://github.com/sunlightlabs/StatesLege
//
//  This work is licensed under the Creative Commons Attribution-NonCommercial 3.0 Unported License. 
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc/3.0/
//  or send a letter to Creative Commons, 444 Castro Street, Suite 900, Mountain View, California, 94041, USA.
//
//

#import "LinkObj+RestKit.h"
#import "UtilityMethods.h"
#import <SLFRestKit/SLFRestKit.h>

static RKManagedObjectMapping *linkAttributesMapping = nil;

@implementation LinkObj (RestKit)

+ (NSString*)primaryKeyProperty
{
	return @"sortOrder";
}

+ (RKManagedObjectMapping *)attributeMapping
{
    if (linkAttributesMapping)
        return linkAttributesMapping;

    RKManagedObjectMapping *mapping = [RKManagedObjectMapping mappingForClass:[self class] inManagedObjectStore:[RKObjectManager sharedManager].objectStore];
    mapping.primaryKeyAttribute = @"sortOrder";
    [mapping mapAttributesFromArray:@[
                                    @"label",
                                      @"section",
                                      @"sortOrder",
                                      @"url",
                                      ]];
    [mapping mapKeyPath:@"updated" toAttribute:@"updatedDate"];

    linkAttributesMapping = mapping;

    return mapping;
}

- (NSURL *)actualURL
{
	NSURL * actualURL = nil;
	NSString *followTheMoney = [UtilityMethods texLegeStringWithKeyPath:@"ExternalURLs.nimspWeb"];

	if ([self.url isEqualToString:@"aboutView"])
    {
		NSString *file = nil;

		if ([UtilityMethods isIPadDevice])
			file = @"TexLegeInfo~ipad.htm";
		else
			file = @"TexLegeInfo~iphone.htm";
		
		NSURL *baseURL = [UtilityMethods urlToMainBundle];
		actualURL = [NSURL URLWithString:file relativeToURL:baseURL];
	}
	else if ([self.url hasPrefix:followTheMoney])
    {
		actualURL = [NSURL URLWithString:followTheMoney];
	}
	else if ([self.url hasPrefix:@"mailto:"])
    {
		actualURL = nil;
	}
	else if (self.url)
    {
		actualURL = [NSURL URLWithString:self.url];
	}
	
	return actualURL;	
}

@end
