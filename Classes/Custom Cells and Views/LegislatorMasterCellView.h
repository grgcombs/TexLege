//
//	LegislatorMasterCellView.h
//  Created by Gregory Combs on 8/29/10.
//
//  StatesLege by Sunlight Foundation, based on work at https://github.com/sunlightlabs/StatesLege
//
//  This work is licensed under the Creative Commons Attribution-NonCommercial 3.0 Unported License. 
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc/3.0/
//  or send a letter to Creative Commons, 444 Castro Street, Suite 900, Mountain View, California, 94041, USA.
//
//

#import "TexLege.h"

extern const CGFloat kLegislatorMasterCellViewWidth;
extern const CGFloat kLegislatorMasterCellViewHeight;

@class LegislatorObj;
@interface LegislatorMasterCellView : UIView

@property (copy, nonatomic) NSString *title;
@property (copy, nonatomic) NSString *name;
@property (copy, nonatomic) NSString *tenure;
@property (nonatomic) BOOL useDarkBackground;
@property (nonatomic) BOOL highlighted;
@property (nonatomic, retain) UIImage *questionImage;

@property (nonatomic) CGFloat sliderValue;
@property (nonatomic) CGFloat sliderMin;
@property (nonatomic) CGFloat sliderMax;
@property (nonatomic) CGFloat partisan_index;

- (void)setLegislator:(LegislatorObj *)value;

@end
