//
//  LegislatorAnnotation.h
//  TexLege
//
//  Created by Gregory Combs on 5/12/15.
//  Copyright (c) 2015 Gregory S. Combs. All rights reserved.
//

#import <Foundation/Foundation.h>

@class LegislatorObj;

@protocol LegislatorAnnotation <NSObject>
@property (NS_NONATOMIC_IOSONLY, readonly, strong) LegislatorObj *legislator;
@end
