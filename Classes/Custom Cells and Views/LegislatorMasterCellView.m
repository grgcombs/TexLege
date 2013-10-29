//
//	LegislatorMasterCellView.m
//  Created by Gregory Combs on 8/29/10.
//
//  StatesLege by Sunlight Foundation, based on work at https://github.com/sunlightlabs/StatesLege
//
//  This work is licensed under the Creative Commons Attribution-NonCommercial 3.0 Unported License. 
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc/3.0/
//  or send a letter to Creative Commons, 444 Castro Street, Suite 900, Mountain View, California, 94041, USA.
//
//

#import "LegislatorMasterCellView.h"
#import "LegislatorObj+RestKit.h"
#import "TexLegeTheme.h"
#import "PartisanIndexStats.h"

const CGFloat kLegislatorMasterCellViewWidth = 234.0f;
const CGFloat kLegislatorMasterCellViewHeight = 73.0f;

@implementation LegislatorMasterCellView

@synthesize title;
@synthesize name;
@synthesize tenure;
@synthesize sliderValue, sliderMin, sliderMax, partisan_index;
@synthesize useDarkBackground;
@synthesize highlighted, questionImage;

- (id)initWithFrame:(CGRect)frame
{
	self = [super initWithFrame:frame];
	if (self) {
		title = [@"Representative - (D-23)" retain];
		name = [@"Rafael Anchía" retain];
		tenure = [@"4 Years" retain];
		sliderValue = 0.0f, partisan_index = 0.0f;
		sliderMin = -1.5f;
		sliderMax = 1.5f;
		questionImage = nil;
		
		[self setOpaque:YES];
	}
	return self;
}

- (id)initWithCoder:(NSCoder *)coder
{
	self = [super initWithCoder:coder];
	if (self) {
		title = [@"Representative - (D-23)" retain];
		name = [@"Rafael Anchía" retain];
		tenure = [@"4 Years" retain];
		sliderValue = 0.0f, partisan_index = 0.0f;
		sliderMin = -1.5f;
		sliderMax = 1.5f;
		questionImage = nil;

		[self setOpaque:YES];
	}
	return self;
}

- (void) awakeFromNib {
	[super awakeFromNib];
	
	title = [@"Representative - (D-23)" retain];
	name = [@"Rafael Anchía" retain];
	tenure = [@"4 Years" retain];
	sliderValue = 0.0f, partisan_index = 0.0f;
	sliderMin = -1.5f;
	sliderMax = 1.5f;
	questionImage = nil;
	
	[self setOpaque:YES];
	
}

- (void)dealloc
{
	nice_release(questionImage);
	nice_release(title);
	nice_release(name);
	nice_release(tenure);
	[super dealloc];
}

- (void)setSliderValue:(CGFloat)value
{
	sliderValue = value;
		
	if (sliderValue == 0.0f) {	// this gives us the center, in cases of no roll call scores
		sliderValue = (sliderMin + sliderMin)/2;
	}
	
	if (sliderMax > (-sliderMin))
		sliderMin = (-sliderMax);
	else
		sliderMax = (-sliderMin);
		
#define	kStarAtDemoc 0.5f
#define kStarAtRepub 162.0f
#define	kStarAtHalf 81.5f
#define kStarMagnifierBase (kStarAtRepub - kStarAtDemoc)
	
	CGFloat magicNumber = (kStarMagnifierBase / (sliderMax - sliderMin));
	CGFloat offset = kStarAtHalf;
		
	sliderValue = sliderValue * magicNumber + offset;
	
	//[self setNeedsDisplay];
}


- (CGSize)sizeThatFits:(CGSize)size
{
	return CGSizeMake(kLegislatorMasterCellViewWidth, kLegislatorMasterCellViewHeight);
}

- (void)setUseDarkBackground:(BOOL)flag
{
	if (self.highlighted)
		return;
	
	useDarkBackground = flag;
	
	UIColor *labelBGColor = (useDarkBackground) ? [TexLegeTheme backgroundDark] : [TexLegeTheme backgroundLight];
	self.backgroundColor = labelBGColor;
	[self setNeedsDisplay];
}

- (BOOL)highlighted{
	return highlighted;
}

- (void)setHighlighted:(BOOL)flag
{
	if (highlighted == flag)
		return;
	highlighted = flag;
	
	[self setNeedsDisplay];
}

- (void)setLegislator:(LegislatorObj *)value {
	self.partisan_index = value.latestWnomFloat;
	self.title = [value.legtype_name stringByAppendingFormat:@" - %@", [value districtPartyString]];
	self.name = [value legProperName];
	self.tenure = [value tenureString];
		
	PartisanIndexStats *indexStats = [PartisanIndexStats sharedPartisanIndexStats];
	CGFloat minSlider = [indexStats minPartisanIndexUsingChamber:[value.legtype integerValue]];
	CGFloat maxSlider = [indexStats maxPartisanIndexUsingChamber:[value.legtype integerValue]];
	self.sliderMax = maxSlider;
	self.sliderMin = minSlider;	
	[self setSliderValue:self.partisan_index];
	
	[self setNeedsDisplay];	
}

- (void)drawRect:(CGRect)dirtyRect
{
	CGRect imageBounds = CGRectMake(0.0f, 0.0f, kLegislatorMasterCellViewWidth, kLegislatorMasterCellViewHeight);	
	CGRect bounds = [self bounds];

	CGContextRef context = UIGraphicsGetCurrentContext();
	CGFloat alignStroke;
	CGFloat resolution;
	CGMutablePathRef path;
	CGRect drawRect;
	UIFont *font;
	CGGradientRef gradient;
	NSMutableArray *colors;
	UIColor *color;
	CGColorSpaceRef space = CGColorSpaceCreateDeviceRGB();
	CGPoint point;
	CGPoint point2;
	CGFloat stroke;
	CGFloat locations[3];
	
	UIColor *nameColor = nil;
	UIColor *tenureColor = nil;
	UIColor *titleColor = nil;

	// Choose font color based on highlighted state.
	if (self.highlighted) {
		nameColor = tenureColor = titleColor = [TexLegeTheme backgroundLight];
	}
	else {
		nameColor = [TexLegeTheme textDark];
		tenureColor = [TexLegeTheme textLight];
		titleColor = [TexLegeTheme accent];
	}
	
	
	resolution = 0.5f * (bounds.size.width / imageBounds.size.width + bounds.size.height / imageBounds.size.height);
	
	CGContextSaveGState(context);
	CGContextTranslateCTM(context, bounds.origin.x, bounds.origin.y);
	CGContextScaleCTM(context, (bounds.size.width / imageBounds.size.width), (bounds.size.height / imageBounds.size.height));

	// Tenure
	
	drawRect = CGRectMake(189.5f, 52.0f, 45.5, 13.0f);
	drawRect.origin.x = roundf(resolution * drawRect.origin.x) / resolution;
	drawRect.origin.y = roundf(resolution * drawRect.origin.y) / resolution;
	drawRect.size.width = roundf(resolution * drawRect.size.width) / resolution;
	drawRect.size.height = roundf(resolution * drawRect.size.height) / resolution;
	font = [TexLegeTheme boldTen];
	[tenureColor set];
	[[self tenure] drawInRect:drawRect withFont:font lineBreakMode:NSLineBreakByTruncatingTail alignment:NSTextAlignmentRight];
	
	// Title
	
	drawRect = CGRectMake(8.5f, 0.0f, 240.0f, 18.0f);
	drawRect.origin.x = roundf(resolution * drawRect.origin.x) / resolution;
	drawRect.origin.y = roundf(resolution * drawRect.origin.y) / resolution;
	drawRect.size.width = roundf(resolution * drawRect.size.width) / resolution;
	drawRect.size.height = roundf(resolution * drawRect.size.height) / resolution;
	font = [TexLegeTheme boldTwelve];
	[titleColor set];
	[[self title] drawInRect:drawRect withFont:font];
	
	// Name
	
	drawRect = CGRectMake(8.5f, 17.0f, 240.0f, 21.0f);
	drawRect.origin.x = roundf(resolution * drawRect.origin.x) / resolution;
	drawRect.origin.y = roundf(resolution * drawRect.origin.y) / resolution;
	drawRect.size.width = roundf(resolution * drawRect.size.width) / resolution;
	drawRect.size.height = roundf(resolution * drawRect.size.height) / resolution;
	font = [TexLegeTheme boldFifteen];
	[nameColor set];
	[[self name] drawInRect:drawRect withFont:font];
	
	// GradientBar
	
	alignStroke = 0.0f;
	path = CGPathCreateMutable();
	drawRect = CGRectMake(8.5f, 53.0f, 173.0f, 13.0f);
	drawRect.origin.x = (roundf(resolution * drawRect.origin.x + alignStroke) - alignStroke) / resolution;
	drawRect.origin.y = (roundf(resolution * drawRect.origin.y + alignStroke) - alignStroke) / resolution;
	drawRect.size.width = roundf(resolution * drawRect.size.width) / resolution;
	drawRect.size.height = roundf(resolution * drawRect.size.height) / resolution;
	CGPathAddRect(path, NULL, drawRect);
	colors = [NSMutableArray arrayWithCapacity:3];
	[colors addObject:(id)[[TexLegeTheme texasBlue] CGColor]];
	locations[0] = 0.0f;
	[colors addObject:(id)[[TexLegeTheme texasRed] CGColor]];
	locations[1] = 1.0f;
	color = [UIColor colorWithRed:1.0f green:1.0f blue:1.0f alpha:1.0f];
	[colors addObject:(id)[color CGColor]];
	locations[2] = 0.499f;
	gradient = CGGradientCreateWithColors(space, (CFArrayRef)colors, locations);
	CGContextAddPath(context, path);
	CGContextSaveGState(context);
	CGContextEOClip(context);
	point = CGPointMake(29.5f, 59.0f);
	point2 = CGPointMake(162.5f, 59.0f);
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
	
	// we don't use sliderVal here because it's already been adjusted to compensate for minMax...
	if (self.partisan_index == 0.0f) {
		if (!self.questionImage) {
			NSString *imageString = /*(self.usesSmallStar) ? @"Slider_Question.png" :*/ @"Slider_Question_big.png";
			self.questionImage = [UIImage imageNamed:imageString];
		}
		drawRect = CGRectMake(81.f, 41.f, 35.f, 32.f);
		[self.questionImage drawInRect:drawRect blendMode:kCGBlendModeNormal alpha:0.6];
	}
	else {
		// StarGroup

		// Setup for Shadow Effect
		color = [UIColor colorWithRed:0.0f green:0.0f blue:0.0f alpha:0.5f];
		CGContextSaveGState(context);
		CGContextSetShadowWithColor(context, CGSizeMake(0.724f * resolution, 2.703f * resolution), 1.679f * resolution, [color CGColor]);
		CGContextBeginTransparencyLayer(context, NULL);
		
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
		
		
		/* BEGIN: DrawStar
		float starRadius = 15.f;	
		// Rearrange the coordinate system for the DrawStar routine then call it to draw the star.
		CGContextSaveGState(context);
		CGContextTranslateCTM(context, starCenter+13.f, 58.187f);
		CGContextScaleCTM(context, starRadius, starRadius);
		CGContextRotateCTM(context, 53.f * (M_PI / 180));
		//CGContextSetRGBFillColor(context, 1.0, 1.0, 1.0, 1.0);
		// this is the angle of the sides/points, not the overall tilt of the star
		const float starAngle = 2.0 * M_PI / 5.0;		
		
		// Begin a new path (any previous path is discarded)
		CGContextBeginPath(context);
		// The point (1,0) is equivalent to (cos(0), sin(0))
		CGContextMoveToPoint(context, 1, 0);	
		
		// nextPointIndex is used to find every other point
		short nextPointIndex = 2;	
		for(short pointCounter = 1; pointCounter < 5; pointCounter++) {
			CGContextAddLineToPoint(context, 
									cos( nextPointIndex * starAngle ), 
									sin( nextPointIndex * starAngle ));
			nextPointIndex = (nextPointIndex + 2) % 5;
		}
		
		CGContextClosePath(context);
		CGContextFillPath(context);
		CGContextRestoreGState(context);
		* END: DrawStar */

		
		CGFloat yShift = 40.5f;
		
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
		color = [UIColor colorWithRed:1.0f green:1.0f blue:1.0f alpha:1.0f];
		[colors addObject:(id)[color CGColor]];
		locations[0] = 0.0f;
		color = [UIColor colorWithRed:0.6f green:0.6f blue:0.6f alpha:1.0f];
		[colors addObject:(id)[color CGColor]];
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
		
		// Shadow Effect
		CGContextEndTransparencyLayer(context);
		CGContextRestoreGState(context);
	}
	CGContextRestoreGState(context);
	CGColorSpaceRelease(space);
}

@end
