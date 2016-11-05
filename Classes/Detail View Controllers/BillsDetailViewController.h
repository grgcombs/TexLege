//
//  BillsDetailViewController.h
//  Created by Gregory Combs on 2/20/11.
//
//  StatesLege by Sunlight Foundation, based on work at https://github.com/sunlightlabs/StatesLege
//
//  This work is licensed under the Creative Commons Attribution-NonCommercial 3.0 Unported License. 
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc/3.0/
//  or send a letter to Creative Commons, 444 Castro Street, Suite 900, Mountain View, California, 94041, USA.
//
//

#import <UIKit/UIKit.h>
#import <RestKit/RestKit.h>
#import "TXLDetailProtocol.h"

@class TableCellDataObject;
@class DDActionHeaderView;
@class BillVotesDataSource;
@class AppendingFlowView;

@interface BillsDetailViewController : UITableViewController <RKRequestDelegate, UISplitViewControllerDelegate, UIPopoverControllerDelegate, TXLDetailProtocol>

@property (nonatomic,strong) IBOutlet UIView *headerView;
@property (nonatomic,strong) IBOutlet UIView *descriptionView;
@property (nonatomic,strong) IBOutlet AppendingFlowView *statusView;
@property (nonatomic,strong) IBOutlet UITextView *lab_description;
@property (nonatomic,strong) IBOutlet UIButton *starButton;
@property (nonatomic,strong) IBOutlet DDActionHeaderView *actionHeader;

@property (nonatomic,strong) NSDictionary *bill;
@property (nonatomic,strong) BillVotesDataSource *voteDataSource;

- (IBAction)starButtonToggle:(id)sender;

@end
