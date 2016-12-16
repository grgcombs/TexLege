//
//  SLFObjectQueue.h
//  
//
//  Created by Gregory Combs on 7/8/16.
//
//

@import Foundation;

NS_ASSUME_NONNULL_BEGIN

@interface SLFObjectQueue<__covariant QueueItemType:NSObject<NSCopying> *> : NSObject <NSCopying, NSFastEnumeration>

- (instancetype)initWithName:(NSString *)name NS_DESIGNATED_INITIALIZER;
- (nullable QueueItemType)objectAtIndex:(NSUInteger)index;
- (nullable QueueItemType)pop;
- (void)push:(QueueItemType)object;
- (nullable QueueItemType)peekNext;
- (BOOL)removeObject:(QueueItemType)object;
- (BOOL)containsObject:(QueueItemType)object;
- (void)enumerateObjectsUsingBlock:(void (NS_NOESCAPE ^)(QueueItemType item, NSUInteger idx, BOOL *stop))block;
- (void)enumerateObjectsWithOptions:(NSEnumerationOptions)opts usingBlock:(void (NS_NOESCAPE ^)(QueueItemType item, NSUInteger idx, BOOL *stop))block;

@property (readonly) NSUInteger count;
@property (copy,readonly) NSString *name;

@end

NS_ASSUME_NONNULL_END
