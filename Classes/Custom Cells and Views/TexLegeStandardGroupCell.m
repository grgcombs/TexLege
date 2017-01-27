//
//  TexLegeStandardGroupCell.m
//  Created by Gregory Combs on 8/29/10.
//
//  StatesLege by Sunlight Foundation, based on work at https://github.com/sunlightlabs/StatesLege
//
//  This work is licensed under the Creative Commons Attribution-NonCommercial 3.0 Unported License. 
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc/3.0/
//  or send a letter to Creative Commons, 444 Castro Street, Suite 900, Mountain View, California, 94041, USA.
//
//

#import "TexLegeStandardGroupCell.h"
#import "TableCellDataObject.h"
#import "TexLegeTheme.h"
#import "DisclosureQuartzView.h"

@implementation TexLegeStandardGroupCell
@synthesize cellInfo = _cellInfo;

+ (NSString *)cellIdentifier
{
	return NSStringFromClass([self class]);
}

+ (UITableViewCellStyle)cellStyle
{
    return [self preferredStyle];
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    style = [self.class preferredStyle];

    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self)
    {
		self.autoresizingMask = UIViewAutoresizingFlexibleWidth;

        UILabel *titleLabel = self.detailTextLabel;
        UIFont *titleFont = [TexLegeTheme boldTwelve];
		titleLabel.font = titleFont;
        titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        titleLabel.adjustsFontSizeToFitWidth = YES;
        titleLabel.minimumScaleFactor = (12.0 / titleFont.pointSize);
        titleLabel.textColor = [TexLegeTheme textDark];

        UILabel *subtitleLabel = self.textLabel;
        UIFont *subtitleFont = [TexLegeTheme boldTen];
        subtitleLabel.font = subtitleFont;
        subtitleLabel.textColor = [TexLegeTheme accent];
        subtitleLabel.adjustsFontSizeToFitWidth = YES;

        [self configure];
    }
    return self;
}

- (void)setCellInfo:(TableCellDataObject *)cellInfo
{
    if (![cellInfo isKindOfClass:[TableCellDataObject class]])
        cellInfo = nil;
    _cellInfo = cellInfo;

    self.detailTextLabel.text = cellInfo.title;
    self.textLabel.text = cellInfo.subtitle;
    if (!cellInfo.isClickable)
    {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.accessoryType = UITableViewCellAccessoryNone;
        self.accessoryView = nil;
    }
}

+ (BOOL)forceUnclickable
{
    return NO;
}

+ (UITableViewCellStyle)preferredStyle
{
    return UITableViewCellStyleValue2;
}

- (void)configure
{
    _cellInfo = nil;
    self.detailTextLabel.text = nil;
    self.textLabel.text = nil;

    if ([[self class] forceUnclickable])
    {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.accessoryType = UITableViewCellAccessoryNone;
        self.accessoryView = nil;
    }
    else
    {
        self.selectionStyle = UITableViewCellSelectionStyleBlue;
        self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        if (!self.accessoryView || ![self.accessoryView isKindOfClass:[DisclosureQuartzView class]])
        {
            DisclosureQuartzView *qv = [[DisclosureQuartzView alloc] initWithFrame:CGRectMake(0.f, 0.f, 28.f, 28.f)];
            self.accessoryView = qv;
        }
    }
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    [self configure];
}

@end

@implementation TXLUnclickableGroupCell

+ (BOOL)forceUnclickable
{
    return YES;
}

@end

@implementation TXLClickableGroupCell

+ (BOOL)forceUnclickable
{
    return NO;
}

@end

@implementation TXLUnclickableSubtitleCell

+ (UITableViewCellStyle)preferredStyle
{
    return UITableViewCellStyleSubtitle;
}

@end

@implementation TXLClickableSubtitleCell

+ (UITableViewCellStyle)preferredStyle
{
    return UITableViewCellStyleSubtitle;
}

@end
