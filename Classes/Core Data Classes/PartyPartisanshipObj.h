//
//  PartyPartisanshipObj.h
//  TexLege
//
//  Created by Gregory Combs on 1/4/17.
//  Copyright © 2017 Gregory S. Combs. All rights reserved.
//

#import "SLAbstractCodableObject.h"

extern const struct PartyPartisanshipKeys {
    __unsafe_unretained NSString * const identifier;
    __unsafe_unretained NSString * const chamber;
    __unsafe_unretained NSString * const party;
    __unsafe_unretained NSString * const session;
    __unsafe_unretained NSString * const updated;
    __unsafe_unretained NSString * const score;
} PartyPartisanshipKeys;


@class RKObjectMapping;

@interface PartyPartisanshipObj : SLAbstractCodableObject<NSCopying,NSSecureCoding>

@property (NS_NONATOMIC_IOSONLY,copy,readonly) NSNumber *identifier;
@property (NS_NONATOMIC_IOSONLY,copy,readonly) NSNumber *chamber;
@property (NS_NONATOMIC_IOSONLY,copy,readonly) NSNumber *party;
@property (NS_NONATOMIC_IOSONLY,copy,readonly) NSNumber *session;
@property (NS_NONATOMIC_IOSONLY,copy,readonly) NSDate *updated;
@property (NS_NONATOMIC_IOSONLY,copy,readonly) NSNumber *score;

- (id)objectForKeyedSubscript:(NSString *)key;

+ (RKObjectMapping *)attributeMapping;
+ (NSString *)primaryKeyProperty;

@end
