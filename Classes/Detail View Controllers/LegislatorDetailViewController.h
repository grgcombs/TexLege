//
//  LegislatorDetailViewController.h
//  Created by Gregory Combs on 6/28/10.
//
//  StatesLege by Sunlight Foundation, based on work at https://github.com/sunlightlabs/StatesLege
//
//  This work is licensed under the Creative Commons Attribution-NonCommercial 3.0 Unported License. 
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc/3.0/
//  or send a letter to Creative Commons, 444 Castro Street, Suite 900, Mountain View, California, 94041, USA.
//
//

#import <UIKit/UIKit.h>
#import "S7GraphView.h"
#import "TXLDetailProtocol.h"

@class LegislatorObj;
@class PartisanScaleView;
@class TableCellDataObject;
@class LegislatorDetailDataSource;
@class VotingRecordDataSource;

@interface LegislatorDetailViewController : UITableViewController <UISplitViewControllerDelegate, 
													UIPopoverControllerDelegate, TXLDetailProtocol>

//@property (nonatomic,strong) id dataObject;
@property (nonatomic,strong) NSNumber *dataObjectID;

@property (nonatomic,strong) IBOutlet S7GraphView *chartView;
@property (nonatomic,strong) VotingRecordDataSource *votingDataSource;

@property (nonatomic,strong) IBOutlet UIView *miniBackgroundView;
@property (nonatomic,strong) IBOutlet UIView *headerView;
@property (nonatomic,strong) IBOutlet UIImageView *leg_photoView;
@property (nonatomic,strong) IBOutlet UILabel *leg_indexTitleLab, *leg_rankLab, *leg_chamberPartyLab, *leg_chamberLab;
@property (nonatomic,strong) IBOutlet UILabel *leg_partyLab, *leg_districtLab, *leg_tenureLab, *leg_nameLab, *freshmanPlotLab;
@property (nonatomic,strong) IBOutlet UILabel *leg_reelection;
@property (nonatomic,strong) IBOutlet PartisanScaleView *indivSlider, *partySlider, *allSlider;

@property (nonatomic,strong) UIPopoverController *notesPopover;
@property (nonatomic,assign) LegislatorObj *legislator;
@property (nonatomic,strong) LegislatorDetailDataSource *dataSource;

@end
