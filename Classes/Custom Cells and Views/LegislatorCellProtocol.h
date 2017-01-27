//
//  LegislatorCellProtocol.h
//  TexLege
//
//  Created by Gregory Combs on 10/29/13.
//  Copyright (c) 2013 Gregory S. Combs. All rights reserved.
//

#import "TexLege.h"

@class LegislatorObj;

@protocol LegislatorCellProtocol <NSObject>
@property (nonatomic,strong) LegislatorObj *legislator;
- (void)redisplay;
@end
