//
//  RestKit.h
//  RestKit
//
//  Created by Gregory Combs on 12/27/16.
//  Copyright © 2016 RestKit. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface NSManagedObject(RestKit)

+ (NSManagedObjectContext *)rkManagedObjectContext;
+ (NSString *)primaryKeyProperty;
- (id)primaryKeyValue;
+ (instancetype)objectWithPrimaryKeyValue:(id)value;

@end
