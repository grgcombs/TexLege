//
//	PartisanScaleView.h
//  Created by Gregory Combs on 8/29/10.
//
//  StatesLege by Sunlight Foundation, based on work at https://github.com/sunlightlabs/StatesLege
//
//  This work is licensed under the Creative Commons Attribution-NonCommercial 3.0 Unported License. 
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc/3.0/
//  or send a letter to Creative Commons, 444 Castro Street, Suite 900, Mountain View, California, 94041, USA.
//
//

#import <UIKit/UIKit.h>

extern const CGFloat kPartisanScaleViewWidth;
extern const CGFloat kPartisanScaleViewHeight;

@interface PartisanScaleView : UIView

@property (nonatomic,assign,getter=isHighlighted) BOOL highlighted;
@property (nonatomic,assign) BOOL showUnknown;
@property (nonatomic,assign) CGFloat sliderValue;
@property (nonatomic,assign) CGFloat sliderMin;
@property (nonatomic,assign) CGFloat sliderMax;
@property (nonatomic,retain) UIImage *questionImage;


@end
