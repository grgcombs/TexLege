//
//  CommitteeDetailViewController.h
//  Created by Gregory Combs on 6/29/10.
//
//  StatesLege by Sunlight Foundation, based on work at https://github.com/sunlightlabs/StatesLege
//
//  This work is licensed under the Creative Commons Attribution-NonCommercial 3.0 Unported License. 
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc/3.0/
//  or send a letter to Creative Commons, 444 Castro Street, Suite 900, Mountain View, California, 94041, USA.
//
//

#import <UIKit/UIKit.h>
#import "TXLDetailProtocol.h"

@class CommitteeObj;
@class PartisanScaleView;
@interface CommitteeDetailViewController : UITableViewController <UISplitViewControllerDelegate, TXLDetailProtocol>

@property (nonatomic, strong) NSNumber *dataObjectID;
@property (nonatomic, strong) CommitteeObj *committee;
@property (nonatomic, strong) UIPopoverController *masterPopover;
@property (nonatomic, strong) IBOutlet UILabel *membershipLab;
@property (nonatomic, strong) IBOutlet PartisanScaleView *partisanSlider;
@property (nonatomic, strong) NSArray *infoSectionArray;
@end
