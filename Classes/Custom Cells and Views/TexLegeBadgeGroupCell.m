//
//  DDBadgeViewCell.m
//  DDBadgeViewCell
//
//  Created by digdog on 1/23/10.
//  Copyright 2010 Ching-Lan 'digdog' HUANG. http://digdog.tumblr.com
//
//  Permission is hereby granted, free of charge, to any person obtaining
//  a copy of this software and associated documentation files (the
//  "Software"), to deal in the Software without restriction, including
//  without limitation the rights to use, copy, modify, merge, publish,
//  distribute, sublicense, and/or sell copies of the Software, and to
//  permit persons to whom the Software is furnished to do so, subject to
//  the following conditions:
//   
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//   
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
//  MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
//  LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
//  OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
//  WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import <QuartzCore/QuartzCore.h>
#import "TexLegeBadgeGroupCell.h"
#import "TableCellDataObject.h"
#import "TexLegeTheme.h"

#pragma mark -
#pragma mark DDBadgeView declaration

@interface DDBadgeView : UIView

@property (nonatomic, assign) TexLegeBadgeGroupCell *cell;

- (instancetype)initWithFrame:(CGRect)frame cell:(TexLegeBadgeGroupCell *)newCell NS_DESIGNATED_INITIALIZER;
@end

#pragma mark -
#pragma mark DDBadgeView implementation

@implementation DDBadgeView 

#pragma mark -
#pragma mark init

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [self initWithFrame:frame cell:nil];
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [self initWithFrame:CGRectZero cell:nil];
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame cell:(TexLegeBadgeGroupCell *)newCell
{	
	if ((self = [super initWithFrame:frame]))
    {
		_cell = newCell;
		
		self.backgroundColor = [UIColor clearColor];
		self.layer.masksToBounds = YES;
	}
	return self;
}

#pragma mark -
#pragma mark redraw

- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];

	CGContextRef context = UIGraphicsGetCurrentContext();
	
    UIColor *currentSummaryColor = [TexLegeTheme textDark];
    //UIColor *currentDetailColor = [UIColor grayColor];
    UIColor *currentBadgeColor = self.cell.badgeColor;
    if (!currentBadgeColor)
    {
        currentBadgeColor = [TexLegeTheme accentGreener]; //[UIColor colorWithRed:0.53 green:0.6 blue:0.738 alpha:1.];
    }
    
	if (self.cell && self.cell.isClickable && (self.cell.isHighlighted || self.cell.isSelected)) {
        currentSummaryColor = [UIColor whiteColor];
        //currentDetailColor = [UIColor whiteColor];
		currentBadgeColor = self.cell.badgeHighlightedColor;
		if (!currentBadgeColor)
        {
			currentBadgeColor = [UIColor whiteColor];
		}
	} 
	
	if (self.cell && self.cell.isEditing)
    {
		[currentSummaryColor set];
		[self.cell.summary drawAtPoint:CGPointMake(10, 10) forWidth:rect.size.width withFont:[TexLegeTheme boldFifteen] lineBreakMode:NSLineBreakByTruncatingTail];
		
		//[currentDetailColor set];
		//[self.cell.detail drawAtPoint:CGPointMake(10, 32) forWidth:rect.size.width withFont:[TexLegeTheme boldTwelve] lineBreakMode:NSLineBreakByTruncatingTail];		
	}
    else
    {
		CGSize badgeTextSize = [self.cell.badgeText sizeWithFont:[TexLegeTheme boldTwelve]];
		CGRect badgeViewFrame = CGRectIntegral(CGRectMake(rect.size.width - badgeTextSize.width - 24, (rect.size.height - badgeTextSize.height - 4) / 2, badgeTextSize.width + 14, badgeTextSize.height + 4));
		
		CGContextSaveGState(context);	
		CGContextSetFillColorWithColor(context, currentBadgeColor.CGColor);
		CGMutablePathRef path = CGPathCreateMutable();
		CGPathAddArc(path, NULL, badgeViewFrame.origin.x + badgeViewFrame.size.width - badgeViewFrame.size.height / 2, badgeViewFrame.origin.y + badgeViewFrame.size.height / 2, badgeViewFrame.size.height / 2, M_PI / 2, M_PI * 3 / 2, YES);
		CGPathAddArc(path, NULL, badgeViewFrame.origin.x + badgeViewFrame.size.height / 2, badgeViewFrame.origin.y + badgeViewFrame.size.height / 2, badgeViewFrame.size.height / 2, M_PI * 3 / 2, M_PI / 2, YES);
		CGContextAddPath(context, path);
		CGContextDrawPath(context, kCGPathFill);
		CFRelease(path);
		CGContextRestoreGState(context);
		
		CGContextSaveGState(context);	
		CGContextSetBlendMode(context, kCGBlendModeClear);
		[self.cell.badgeText drawInRect:CGRectInset(badgeViewFrame, 7, 2) withFont:[TexLegeTheme boldTwelve]];
		CGContextRestoreGState(context);
		
		[currentSummaryColor set];
		[self.cell.summary drawAtPoint:CGPointMake(10, 10) forWidth:(rect.size.width - badgeViewFrame.size.width - 24) withFont:[TexLegeTheme boldFifteen] lineBreakMode:NSLineBreakByTruncatingTail];
		
		//[currentDetailColor set];
		//[self.cell.detail drawAtPoint:CGPointMake(10, 32) forWidth:(rect.size.width - badgeViewFrame.size.width - 24) withFont:[TexLegeTheme boldTwelve] lineBreakMode:NSLineBreakByTruncatingTail];		
	}
}

@end

#pragma mark -
#pragma mark TexLegeBadgeGroupCell private

@interface TexLegeBadgeGroupCell ()
@property (nonatomic, retain) DDBadgeView *	badgeView;
@end

#pragma mark -
#pragma mark TexLegeBadgeGroupCell implementation

@implementation TexLegeBadgeGroupCell
@synthesize cellInfo = _cellInfo;

+ (NSString *)cellIdentifier
{
	return @"TexLegeBadgeGroupCell";
}

+ (UITableViewCellStyle)cellStyle
{
	return UITableViewCellStyleDefault;
	//return UITableViewCellStyleSubtitle;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
	
    if ((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])) {
		// Initialization code
		/*
		 self.selectionStyle = UITableViewCellSelectionStyleBlue;
		self.autoresizingMask = UIViewAutoresizingFlexibleWidth;		
		*/
		
		self.backgroundColor = [TexLegeTheme backgroundLight];
		_clickable = YES;
		_badgeView = [[DDBadgeView alloc] initWithFrame:self.contentView.bounds cell:self];
        _badgeView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _badgeView.contentMode = UIViewContentModeRedraw;
		_badgeView.contentStretch = CGRectMake(1., 0., 0., 0.);
        [self.contentView addSubview:_badgeView];
    }
    return self;
}

#pragma mark -
#pragma mark init & dealloc

- (void)dealloc
{
	[_badgeView release], _badgeView = nil;
	
    [_summary release], _summary = nil;
    //[detail_ release], detail_ = nil;
	[_badgeText release], _badgeText = nil;
	[_badgeColor release], _badgeColor = nil;
	[_badgeHighlightedColor release], _badgeHighlightedColor = nil;
	self.cellInfo = nil;

    [super dealloc];
}

- (void)setCellInfo:(TableCellDataObject *)newCellInfo
{
	if (_cellInfo)
		[_cellInfo release], _cellInfo = nil;
	if (!newCellInfo)
        return;

    _cellInfo = [newCellInfo retain];
		
    self.summary = newCellInfo.title;
    //self.detail = newCellInfo.subtitle;
    self.badgeText = [NSString stringWithFormat:NSLocalizedStringFromTable(@"%@ Bills", @"DataTableUI", @"Lists the number of bills for a givensubject"),
                      newCellInfo.entryValue];
    _clickable = newCellInfo.isClickable;

    if (!newCellInfo.isClickable)
    {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
    }
}

#pragma mark -
#pragma mark accessors

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
	
	[self.badgeView setNeedsDisplay];
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated
{
	[super setHighlighted:highlighted animated:animated];
	
	[self.badgeView setNeedsDisplay];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
	[super setEditing:editing animated:animated];
	
	[self.badgeView setNeedsDisplay];
}

@end
