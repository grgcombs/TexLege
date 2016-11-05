//
//  TXLDetailProtocol.h
//  TexLege
//
//  Created by Gregory Combs on 5/10/15.
//  Copyright (c) 2015 Gregory S. Combs. All rights reserved.
//

#import "TexLege.h"

@protocol TXLDetailProtocol <NSObject>

@required

    @property (NS_NONATOMIC_IOSONLY, strong) id dataObject;

@optional

    - (IBAction)resetTableData:(id)sender;

    @property (NS_NONATOMIC_IOSONLY,strong) UIPopoverController *masterPopover;

@end
