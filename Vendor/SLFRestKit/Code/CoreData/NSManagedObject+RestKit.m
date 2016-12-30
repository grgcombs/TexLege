//
//  NSManagedObject+RestKit.m
//  RestKit
//
//  Created by Gregory Combs on 12/27/16.
//  Copyright © 2016 RestKit. All rights reserved.
//

#import "NSManagedObject+RestKit.h"
#import "RestKit.h"

@implementation NSManagedObject(RestKit)

+ (NSManagedObjectContext*)rkManagedObjectContext
{
    return [[[RKObjectManager sharedManager] objectStore] managedObjectContext];
}

- (id)primaryKeyValue
{
    NSString *key = [[self class] primaryKeyProperty];
    if (!key)
    {
        [self doesNotRecognizeSelector:_cmd];
        return nil;
    }
    NSEntityDescription *entity = [[self class] rkEntity];
    NSAttributeDescription *attribute = entity.attributesByName[key];
    if (!attribute)
    {
        [self doesNotRecognizeSelector:_cmd];
        return nil;
    }

    id value = [self valueForKey:key];

    switch (attribute.attributeType) {
        case NSUndefinedAttributeType:
            break;

        case NSInteger16AttributeType:
        case NSInteger32AttributeType:
        case NSInteger64AttributeType:
        case NSDecimalAttributeType:
        case NSDoubleAttributeType:
        case NSFloatAttributeType:
        case NSBooleanAttributeType:
        case NSObjectIDAttributeType:
        {
            value = ([value isKindOfClass:[NSNumber class]]) ? value : nil;
            break;
        }

        case NSStringAttributeType:
        {
            value = ([value isKindOfClass:[NSString class]]) ? value : nil;
            break;
        }

        case NSDateAttributeType:
        {
            value = ([value isKindOfClass:[NSDate class]]) ? value : nil;
            break;
        }

        case NSBinaryDataAttributeType:
        {
            value = ([value isKindOfClass:[NSData class]]) ? value : nil;
            break;
        }

        case NSTransformableAttributeType:
            break;

        default:
            value = nil;
            break;
    }
    
    return value;
}

+ (NSString *)primaryKeyProperty
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

+ (instancetype)objectWithPrimaryKeyValue:(id)value
{
    if (!value || [value isEqual:[NSNull null]])
        return nil;
    NSPredicate* predicate = [NSPredicate predicateWithFormat:@"%K = %@", [self primaryKeyProperty], value];
    return [self objectWithPredicate:predicate];
}

#if 0
+ (NSString*)primaryKeyElement
{
    NSString *primaryKeyProperty = [[self class] primaryKeyProperty];

    NSEntityDescription *entity = [[self class] entity];
    if (!entity || !primaryKeyProperty)
    {
        [self doesNotRecognizeSelector:_cmd];
        return nil;
    }
    NSAttributeDescription *attribute = entity.attributesByName[key];
    if (!attribute)
    {
        [self doesNotRecognizeSelector:_cmd];
        return nil;
    }
    NSDictionary* mappings = [[self class] elementToPropertyMappings];
    for (NSString* elementName in mappings)
    {
        NSString* propertyName = [mappings valueForKey:elementName];
        if ([propertyName isEqualToString:[self primaryKeyProperty]]) {
            return elementName;
        }
    }

    // Blow up if not found
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}
#endif

@end
