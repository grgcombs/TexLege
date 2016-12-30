//
//  SLToastManager+TexLege.m
//  TexLege
//
//  Created by Gregory Combs on 12/26/16.
//  Copyright © 2016 Gregory S. Combs. All rights reserved.
//

#import "SLToastManager+TexLege.h"

static SLToastManager *_txlSharedToastManager;

@implementation SLToastManager (TexLege)

+ (instancetype)txlSharedManager
{
    return _txlSharedToastManager;
}

+ (void)txlSetSharedManager:(SLToastManager *)manager
{
    _txlSharedToastManager = manager;
}

@end
