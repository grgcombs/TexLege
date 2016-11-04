//
//	PartisanScaleView.m
//	
//  Created by Gregory Combs on 8/29/10.
//
//  StatesLege by Sunlight Foundation, based on work at https://github.com/sunlightlabs/StatesLege
//
//  This work is licensed under the Creative Commons Attribution-NonCommercial 3.0 Unported License. 
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc/3.0/
//  or send a letter to Creative Commons, 444 Castro Street, Suite 900, Mountain View, California, 94041, USA.
//
//

#import "PartisanScaleView.h"
#import "TexLegeTheme.h"
//#import "UIView+JMNoise.h"

const CGFloat kPartisanScaleViewWidth = 172.0f;
const CGFloat kPartisanScaleViewHeight = 32.0f;

@implementation PartisanScaleView

- (instancetype)initWithFrame:(CGRect)frame
{
	self = [super initWithFrame:frame];
	if (self)
    {
		_sliderValue = 0.0f;
		_sliderMin = -1.5f;
		_sliderMax = 1.5f;
		_questionImage = nil;
		_showUnknown = NO;
		
		[self setOpaque:NO];
	}
	return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
	self = [super initWithCoder:coder];
	if (self) {
		_sliderValue = 0.0f;
		_sliderMin = -1.5f;
		_sliderMax = 1.5f;
		_questionImage = nil;
		_showUnknown = NO;
		
		[self setOpaque:NO];
	}
	return self;
}

- (void)awakeFromNib
{
	[super awakeFromNib];

	_sliderValue = 0.0f;
	_sliderMin = -1.5f;
	_sliderMax = 1.5f;
	_questionImage = nil;
	_showUnknown = NO;
}

- (void)setSliderValue:(CGFloat)value
{
	_sliderValue = value;
	
	if (_sliderValue == 0.0f) {	// this gives us the center, in cases of no roll call scores
		_sliderValue = (_sliderMin + _sliderMin)/2;
		self.showUnknown = YES;
	}
	else
		self.showUnknown = NO;
	
	if (_sliderMax > (-_sliderMin))
		_sliderMin = (-_sliderMax);
	else
		_sliderMax = (-_sliderMin);
		
#define	kStarAtDemoc 0.5f
#define kStarAtRepub 144.5f
#define	kStarAtHalf 72.5f
#define kStarMagnifierBase (kStarAtRepub - kStarAtDemoc)
	
#ifdef JUSTTESTINGHERE
	sliderValue = (sliderValue < 0.f) ? -1.5f : +1.5f;
	sliderMin = -1.5;
	sliderMax = +1.5;
#endif
	
	CGFloat magicNumber = (kStarMagnifierBase / (_sliderMax - _sliderMin));
	CGFloat offset = kStarAtHalf;
		
	_sliderValue = _sliderValue * magicNumber + offset;

	[self setNeedsDisplay];
}


- (CGSize)sizeThatFits:(CGSize)size
{
	return CGSizeMake(kPartisanScaleViewWidth, kPartisanScaleViewHeight);
}

- (void)setHighlighted:(BOOL)flag
{
	if (_highlighted == flag)
		return;
	
	_highlighted = flag;
	[self setNeedsDisplay];
}

- (void)drawRect:(CGRect)dirtyRect
{
    [super drawRect:dirtyRect];

	CGRect imageBounds = CGRectMake(0.0f, 0.0f, kPartisanScaleViewWidth, kPartisanScaleViewHeight);
	CGRect bounds = self.bounds;
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGFloat alignStroke;
	CGFloat resolution;
	CGMutablePathRef path;
	CGRect drawRect;
	CGGradientRef gradient;
	NSMutableArray *colors;
	UIColor *color;
	CGColorSpaceRef space = CGColorSpaceCreateDeviceRGB();
	CGPoint point;
	CGPoint point2;
	CGFloat stroke;
	CGFloat locations[3];
	resolution = 0.5f * (bounds.size.width / imageBounds.size.width + bounds.size.height / imageBounds.size.height);
	
	CGContextSaveGState(context);
	CGContextTranslateCTM(context, bounds.origin.x, bounds.origin.y);
	CGContextScaleCTM(context, (bounds.size.width / imageBounds.size.width), (bounds.size.height / imageBounds.size.height));
	
	// GradientBar
	
	alignStroke = 0.0f;
	path = CGPathCreateMutable();
	drawRect = CGRectMake(11.0f, 11.0f, 150.0f, 13.0f);
	drawRect.origin.x = (roundf(resolution * drawRect.origin.x + alignStroke) - alignStroke) / resolution;
	drawRect.origin.y = (roundf(resolution * drawRect.origin.y + alignStroke) - alignStroke) / resolution;
	drawRect.size.width = roundf(resolution * drawRect.size.width) / resolution;
	drawRect.size.height = roundf(resolution * drawRect.size.height) / resolution;
	CGPathAddRect(path, NULL, drawRect);
	colors = [NSMutableArray arrayWithCapacity:3];
	[colors addObject:(id)[TexLegeTheme texasBlue].CGColor];
	locations[0] = 0.0f;
	[colors addObject:(id)[TexLegeTheme texasRed].CGColor];
	locations[1] = 1.0f;
	color = [UIColor colorWithRed:1.0f green:1.0f blue:1.0f alpha:1.0f];
	[colors addObject:(id)color.CGColor];
	locations[2] = 0.501f;
	gradient = CGGradientCreateWithColors(space, (CFArrayRef)colors, locations);
	CGContextAddPath(context, path);
	CGContextSaveGState(context);
	CGContextEOClip(context);
	point = CGPointMake(29.208f, 17.0f);
	point2 = CGPointMake(144.526f, 17.0f);
	CGContextDrawLinearGradient(context, gradient, point, point2, (kCGGradientDrawsBeforeStartLocation | kCGGradientDrawsAfterEndLocation));
	CGContextRestoreGState(context);
	CGGradientRelease(gradient);
	if (self.highlighted)
		color = [UIColor whiteColor];
	else 
		color = [UIColor blackColor];
	[color setStroke];
	stroke = 1.0f;
	stroke *= resolution;
	if (stroke < 1.0f) {
		stroke = ceilf(stroke);
	} else {
		stroke = roundf(stroke);
	}
	stroke /= resolution;
	stroke *= 2.0f;
	CGContextSetLineWidth(context, stroke);
	CGContextSaveGState(context);
	CGContextAddPath(context, path);
	CGContextEOClip(context);
	CGContextAddPath(context, path);
	CGContextStrokePath(context);
	CGContextRestoreGState(context);
	CGPathRelease(path);
	
	//[self drawCGNoiseWithOpacity:.08f];

	if (self.showUnknown) {
		if (!self.questionImage) {
			self.questionImage = [UIImage imageNamed:@"error"];
		}
		drawRect = CGRectMake(68.f, 0.f, 35.f, 32.f);
		[self.questionImage drawInRect:drawRect blendMode:kCGBlendModeNormal alpha:0.6];
	}
	else 
	{
		// StarGroup
		
		CGContextSaveGState(context);

		// Star
		
		stroke = 1.0f;
		stroke *= resolution;
		if (stroke < 1.0f) {
			stroke = ceilf(stroke);
		} else {
			stroke = roundf(stroke);
		}
		CGFloat starCenter = self.sliderValue;  // lets start at 86.5
		
		stroke /= resolution;
		alignStroke = fmodf(0.5f * stroke * resolution, 1.0f);
		
		CGFloat yShift = 0.0f;
		
		path = CGPathCreateMutable();
		point = CGPointMake(starCenter+5.157f, 28.0f+yShift);
		point.x = (roundf(resolution * point.x + alignStroke) - alignStroke) / resolution;
		point.y = (roundf(resolution * point.y + alignStroke) - alignStroke) / resolution;
		CGPathMoveToPoint(path, NULL, point.x, point.y);
		point = CGPointMake(starCenter+13.5f, 21.71f+yShift);
		point.x = (roundf(resolution * point.x + alignStroke) - alignStroke) / resolution;
		point.y = (roundf(resolution * point.y + alignStroke) - alignStroke) / resolution;
		CGPathAddLineToPoint(path, NULL, point.x, point.y);
		point = CGPointMake(starCenter+21.843f, 28.0f+yShift);
		point.x = (roundf(resolution * point.x + alignStroke) - alignStroke) / resolution;
		point.y = (roundf(resolution * point.y + alignStroke) - alignStroke) / resolution;
		CGPathAddLineToPoint(path, NULL, point.x, point.y);
		point = CGPointMake(starCenter+18.732f, 17.713f+yShift);
		point.x = (roundf(resolution * point.x + alignStroke) - alignStroke) / resolution;
		point.y = (roundf(resolution * point.y + alignStroke) - alignStroke) / resolution;
		CGPathAddLineToPoint(path, NULL, point.x, point.y);
		point = CGPointMake(starCenter+27.0f, 11.313f+yShift);
		point.x = (roundf(resolution * point.x + alignStroke) - alignStroke) / resolution;
		point.y = (roundf(resolution * point.y + alignStroke) - alignStroke) / resolution;
		CGPathAddLineToPoint(path, NULL, point.x, point.y);
		point = CGPointMake(starCenter+16.734f, 11.245f+yShift);
		point.x = (roundf(resolution * point.x + alignStroke) - alignStroke) / resolution;
		point.y = (roundf(resolution * point.y + alignStroke) - alignStroke) / resolution;
		CGPathAddLineToPoint(path, NULL, point.x, point.y);
		point = CGPointMake(starCenter+13.5f, 1.0f+yShift);
		point.x = (roundf(resolution * point.x + alignStroke) - alignStroke) / resolution;
		point.y = (roundf(resolution * point.y + alignStroke) - alignStroke) / resolution;
		CGPathAddLineToPoint(path, NULL, point.x, point.y);
		point = CGPointMake(starCenter+10.266f, 11.245f+yShift);
		point.x = (roundf(resolution * point.x + alignStroke) - alignStroke) / resolution;
		point.y = (roundf(resolution * point.y + alignStroke) - alignStroke) / resolution;
		CGPathAddLineToPoint(path, NULL, point.x, point.y);
		point = CGPointMake(starCenter+0.0f, 11.313f+yShift);				// top dead center
		point.x = (roundf(resolution * point.x + alignStroke) - alignStroke) / resolution;
		point.y = (roundf(resolution * point.y + alignStroke) - alignStroke) / resolution;
		CGPathAddLineToPoint(path, NULL, point.x, point.y);
		point = CGPointMake(starCenter+8.268f, 17.713f+yShift);
		point.x = (roundf(resolution * point.x + alignStroke) - alignStroke) / resolution;
		point.y = (roundf(resolution * point.y + alignStroke) - alignStroke) / resolution;
		CGPathAddLineToPoint(path, NULL, point.x, point.y);
		point = CGPointMake(starCenter+5.157f, 28.0f+yShift);
		point.x = (roundf(resolution * point.x + alignStroke) - alignStroke) / resolution;
		point.y = (roundf(resolution * point.y + alignStroke) - alignStroke) / resolution;
		CGPathAddLineToPoint(path, NULL, point.x, point.y);
		CGPathCloseSubpath(path);
		
		colors = [NSMutableArray arrayWithCapacity:2];
		color = [UIColor colorWithRed:0.9f green:0.9f blue:0.9f alpha:1.0f];
		[colors addObject:(id)color.CGColor];
		locations[0] = 0.0f;
		color = [UIColor colorWithRed:0.9f green:0.9f blue:0.9f alpha:1.0f];
		[colors addObject:(id)color.CGColor];
		locations[1] = 1.0f;
		gradient = CGGradientCreateWithColors(space, (CFArrayRef)colors, locations);
		CGContextAddPath(context, path);
		CGContextSaveGState(context);
		CGContextEOClip(context);
		point = CGPointMake(starCenter+14.0f, 11.5f+yShift);
		point2 = CGPointMake(starCenter+9.5f, 21.5f+yShift);
		CGContextDrawLinearGradient(context, gradient, point, point2, (kCGGradientDrawsBeforeStartLocation | kCGGradientDrawsAfterEndLocation));
		CGContextRestoreGState(context);
		CGGradientRelease(gradient);
		if (self.highlighted)
			color = [UIColor whiteColor];
		else 
			color = [UIColor blackColor];
		[color setStroke];
		CGContextSetLineWidth(context, stroke);
		CGContextSetLineCap(context, kCGLineCapRound);
		CGContextSetLineJoin(context, kCGLineJoinRound);
		CGContextAddPath(context, path);
		CGContextStrokePath(context);
		CGPathRelease(path);
		
		CGContextRestoreGState(context);
	}

	CGContextRestoreGState(context);
	CGColorSpaceRelease(space);
}

@end
