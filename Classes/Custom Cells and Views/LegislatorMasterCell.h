//
//  LegislatorMasterCell.h
//  Created by Gregory Combs on 8/9/10.
//
//  StatesLege by Sunlight Foundation, based on work at https://github.com/sunlightlabs/StatesLege
//
//  This work is licensed under the Creative Commons Attribution-NonCommercial 3.0 Unported License. 
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc/3.0/
//  or send a letter to Creative Commons, 444 Castro Street, Suite 900, Mountain View, California, 94041, USA.
//
//

#import "TexLege.h"
#import "LegislatorMasterCellView.h"
#import "LegislatorCellProtocol.h"

@interface LegislatorMasterCell : UITableViewCell <LegislatorCellProtocol>
@property (nonatomic,strong) IBOutlet LegislatorMasterCellView *cellView;
@end
