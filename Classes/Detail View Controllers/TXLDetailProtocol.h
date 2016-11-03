//
//  TXLDetailProtocol.h
//  TexLege
//
//  Created by Gregory Combs on 5/10/15.
//  Copyright (c) 2015 Gregory S. Combs. All rights reserved.
//

#import "TexLege.h"

@protocol TXLDetailProtocol <NSObject>

@property (NS_NONATOMIC_IOSONLY, retain) id dataObject;

@optional

- (IBAction)resetTableData:(id)sender;

@property (nonatomic,retain) UIPopoverController *masterPopover;

@end
