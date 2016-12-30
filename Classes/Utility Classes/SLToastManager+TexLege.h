//
//  SLToastManager+TexLege.h
//  TexLege
//
//  Created by Gregory Combs on 12/26/16.
//  Copyright © 2016 Gregory S. Combs. All rights reserved.
//

#import <SLToastKit/SLToastKit.h>

@interface SLToastManager (TexLege)

+ (nullable instancetype)txlSharedManager;
+ (void)txlSetSharedManager:(nullable SLToastManager *)manager;

@end
