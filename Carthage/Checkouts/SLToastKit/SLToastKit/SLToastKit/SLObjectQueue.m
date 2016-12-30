//
//  SLObjectQueue.m
//  Sleestacks
//
//  Created by Gregory Combs on 7/10/16.
//  Copyright (C) 2016 Gregory Combs [gcombs at gmail]
//  See LICENSE.txt for details.
//

#import "SLObjectQueue.h"

#define SLQueueStoreType NSMutableOrderedSet // Should coalesce objects with the same hash

@interface SLObjectQueue<__covariant QueueItemType:NSObject<NSCopying> *> ()

@property (nonatomic,copy) SLQueueStoreType<QueueItemType> *store;

@end

@implementation SLObjectQueue

- (instancetype)initWithName:(nonnull NSString *)name
{
    self = [super init];
    if (self)
    {
        _store = [[SLQueueStoreType<NSObject<NSCopying> *> alloc] init];
        _name = [name copy];
    }
    return self;
}

- (instancetype)init
{
    self = [self initWithName:@"__no_name__"];
    return self;
}

- (instancetype)copyWithZone:(NSZone *)zone
{
    SLObjectQueue *other = [[SLObjectQueue<NSObject<NSCopying> *> alloc] init];

    [_store enumerateObjectsUsingBlock:^(id<NSObject,NSCopying> _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj conformsToProtocol:@protocol(NSCopying)]
            && [obj respondsToSelector:@selector(copyWithZone:)])
        {
            id<NSObject,NSCopying> objectCopy = [obj copyWithZone:zone];
            if (objectCopy)
            {
                [other push:objectCopy];
                return;
            }
        }

        [other push:obj]; // Does this make sense?
    }];

    return other;
}

- (nullable id)pop
{
    SLQueueStoreType *store = _store;
    if (!store.count)
        return nil;
    id object = nil;
    @synchronized (store) {
        object = [store firstObject];
        [store removeObjectAtIndex:0];
    }
    return object;
}

- (void)push:(nonnull id)object
{
    if (!object)
        return;
    [_store addObject:object];
}

- (nullable id)peekNext
{
    SLQueueStoreType *store = _store;
    if (!store.count)
        return nil;
    return [store firstObject];
}

- (nullable id)objectAtIndex:(NSUInteger)index
{
    if (_store.count > index)
        return _store[index];
    return nil;
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(__unsafe_unretained id  _Nonnull *)buffer count:(NSUInteger)len
{
    return [_store countByEnumeratingWithState:state objects:buffer count:len];
}

- (void)enumerateObjectsWithOptions:(NSEnumerationOptions)opts usingBlock:(void (^)(NSObject<NSCopying> * _Nonnull, NSUInteger, BOOL * _Nonnull))block
{
    if (!block)
        return;
    [_store enumerateObjectsWithOptions:opts usingBlock:block];
}

- (void)enumerateObjectsUsingBlock:(void (^)(NSObject<NSCopying> * _Nonnull, NSUInteger, BOOL * _Nonnull))block
{
    if (!block)
        return;
    [_store enumerateObjectsUsingBlock:block];
}

- (NSUInteger)count
{
    return _store.count;
}

- (BOOL)containsObject:(nonnull id)object
{
    return [_store containsObject:object];
}

- (NSUInteger)indexOfObject:(nonnull id)object
{
    if (!object)
        return NSNotFound;
    return [_store indexOfObject:object];
}

- (BOOL)removeObject:(nonnull id)object
{
    NSUInteger index = [self indexOfObject:object];
    if (index == NSNotFound || index > self.count)
        return NO;
    [_store removeObjectAtIndex:index];
    return YES;
}

@end
