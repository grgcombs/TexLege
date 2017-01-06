//
//  PartyPartisanshipObj.m
//  TexLege
//
//  Created by Gregory Combs on 1/4/17.
//  Copyright © 2017 Gregory S. Combs. All rights reserved.
//

#import "PartyPartisanshipObj.h"
#import "NSDate+Helper.h"
#import <SLFRestKit/ObjectMapping.h>
#import <SLToastKit/SLTypeCheck.h>

NSString * const PartyPartisanshipDateFormat = @"yyyy-MM-dd HH:mm:ss";

const struct PartyPartisanshipKeys PartyPartisanshipKeys = {
    .identifier = @"identifier",
    .chamber = @"chamber",
    .party = @"party",
    .session = @"session",
    .updated = @"updated",
    .score = @"score",
};

@interface PartyPartisanshipObj ()
@property (NS_NONATOMIC_IOSONLY,copy) NSNumber *identifier;
@property (NS_NONATOMIC_IOSONLY,copy) NSNumber *chamber;
@property (NS_NONATOMIC_IOSONLY,copy) NSNumber *party;
@property (NS_NONATOMIC_IOSONLY,copy) NSNumber *session;
@property (NS_NONATOMIC_IOSONLY,copy) NSDate *updated;
@property (NS_NONATOMIC_IOSONLY,copy) NSNumber *score;
@end

@implementation PartyPartisanshipObj

+ (BOOL)supportsSecureCoding
{
    return YES;
}

+ (NSDictionary *)codableKeysAndClasses
{
    struct PartyPartisanshipKeys keys = PartyPartisanshipKeys;

    /* Normally you shouldn't add mutables here or you'll risk altering `-hash` while inside a collection (bad). */

    return @{keys.identifier: [NSNumber class],
             keys.chamber: [NSNumber class],
             keys.party: [NSNumber class],
             keys.session: [NSNumber class],
             keys.updated: [NSDate class],
             keys.score: [NSNumber class]};
}

- (void)setDictionaryRepresentation:(NSDictionary *)dictionary
{
    if (!SLTypeDictionaryOrNil(dictionary))
        return;

    struct PartyPartisanshipKeys keys = PartyPartisanshipKeys;

    self.identifier = SLTypeNumberOrNil(dictionary[keys.identifier]);
    self.chamber = SLTypeNumberOrNil(dictionary[keys.chamber]);
    self.party = SLTypeNumberOrNil(dictionary[keys.party]);
    self.session = SLTypeNumberOrNil(dictionary[keys.session]);
    self.updated = SLTypeDateOrNil(dictionary[keys.updated]);

    NSNumber *score = SLTypeNumberOrNil(dictionary[keys.score]);
    if (!score)
        score = SLTypeNumberOrNil(dictionary[@"wnom"]);
    self.score = score;
}

- (id)copyWithZone:(NSZone *)zone
{
    PartyPartisanshipObj *copy = [super copyWithZone:zone];
    if (!copy)
        return copy;

    NSNumber *number = nil;
    NSDate *date = nil;

    number = SLTypeNumberOrNil(self.identifier);
    if (number)
        copy.identifier = [number copyWithZone:zone];

    number = SLTypeNumberOrNil(self.chamber);
    if (number)
        copy.chamber = [number copyWithZone:zone];

    number = SLTypeNumberOrNil(self.party);
    if (number)
        copy.party = [number copyWithZone:zone];

    number = SLTypeNumberOrNil(self.session);
    if (number)
        copy.session = [number copyWithZone:zone];

    number = SLTypeNumberOrNil(self.score);
    if (number)
        copy.score = [number copyWithZone:zone];

    date = SLTypeDateOrNil(self.updated);
    if (date)
        copy.updated = [date copyWithZone:zone];

    return copy;
}

- (instancetype)initWithCoder:(NSCoder *)decoder
{
    self = [super initWithCoder:decoder];
    if (!self)
        return self;

    struct PartyPartisanshipKeys keys = PartyPartisanshipKeys;

    NSSet *allowedNumber = [NSSet setWithObjects:[NSNumber class], [NSNull class], nil];
    NSSet *allowedDate = [NSSet setWithObjects:[NSDate class], [NSNull class], nil];

    @try {
        if ([decoder containsValueForKey:keys.identifier])
            self.identifier = [decoder decodeObjectOfClasses:allowedNumber forKey:keys.identifier];

        if ([decoder containsValueForKey:keys.chamber])
            self.chamber = [decoder decodeObjectOfClasses:allowedNumber forKey:keys.chamber];

        if ([decoder containsValueForKey:keys.party])
            self.party = [decoder decodeObjectOfClasses:allowedNumber forKey:keys.party];

        if ([decoder containsValueForKey:keys.session])
            self.session = [decoder decodeObjectOfClasses:allowedNumber forKey:keys.session];

        if ([decoder containsValueForKey:keys.score])
            self.score = [decoder decodeObjectOfClasses:allowedNumber forKey:keys.score];

        if ([decoder containsValueForKey:keys.updated])
            self.updated = [decoder decodeObjectOfClasses:allowedDate forKey:keys.updated];
    }
    @catch (NSException *exception) {
        NSLog(@"Exception while decoding %@: %@", self.class, exception);
    }

    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    struct PartyPartisanshipKeys keys = PartyPartisanshipKeys;

    NSNumber *number = nil;
    NSDate *date = nil;

    number = SLTypeNumberOrNil(self.identifier);
    if (number)
        [encoder encodeObject:number forKey:keys.identifier];

    number = SLTypeNumberOrNil(self.chamber);
    if (number)
        [encoder encodeObject:number forKey:keys.chamber];

    number = SLTypeNumberOrNil(self.party);
    if (number)
        [encoder encodeObject:number forKey:keys.party];

    number = SLTypeNumberOrNil(self.session);
    if (number)
        [encoder encodeObject:number forKey:keys.session];

    number = SLTypeNumberOrNil(self.score);
    if (number)
        [encoder encodeObject:number forKey:keys.score];

    date = SLTypeDateOrNil(self.updated);
    if (date)
        [encoder encodeObject:date forKey:keys.updated];
}

- (id)objectForKeyedSubscript:(NSString *)key
{
    return [super objectForKeyedSubscript:key];
}

+ (NSString*)primaryKeyProperty
{
    return PartyPartisanshipKeys.identifier;
}

+ (RKObjectMapping *)attributeMapping
{
    struct PartyPartisanshipKeys keys = PartyPartisanshipKeys;

    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[self class]];
    //mapping.primaryKeyAttribute = [self primaryKeyProperty];
    [mapping mapAttributesFromArray:@[
                                      keys.chamber,
                                      keys.party,
                                      keys.session,
                                      keys.updated,
                                      ]];
    
    [mapping mapKeyPath:@"id" toAttribute:keys.identifier];
    [mapping mapKeyPath:@"wnom" toAttribute:keys.score];

    NSString *format =  PartyPartisanshipDateFormat;
    NSDateFormatter *formatter = [NSDateFormatter dateFormatterWithID:format format:format];
    mapping.preferredDateFormatter = formatter;

    return mapping;
}

@end
