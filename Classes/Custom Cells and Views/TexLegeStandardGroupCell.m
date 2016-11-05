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
@synthesize cellInfo;

+ (NSString *)cellIdentifier {
	return @"TexLegeStandardGroupCell";
}

+ (UITableViewCellStyle)cellStyle {
	return UITableViewCellStyleValue2;
	//return UITableViewCellStyleSubtitle;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if ((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])) {
        // Initialization code
		self.selectionStyle = UITableViewCellSelectionStyleBlue;
		self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;	

		self.detailTextLabel.font =			[TexLegeTheme boldTwelve];
		self.textLabel.font =				[TexLegeTheme boldTen];
		self.detailTextLabel.textColor = 	[TexLegeTheme textDark];
		self.textLabel.textColor =			[TexLegeTheme accent];

		self.textLabel.adjustsFontSizeToFitWidth =	YES;

		self.detailTextLabel.lineBreakMode = NSLineBreakByTruncatingTail;
		self.detailTextLabel.adjustsFontSizeToFitWidth = YES;
        self.detailTextLabel.minimumScaleFactor = (12.0 / self.detailTextLabel.font.pointSize); // 12.f = deprecated minimumFontSize

		//cell.accessoryView = [TexLegeTheme disclosureLabel:YES];
		//self.accessoryView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"disclosure"]] autorelease];
		DisclosureQuartzView *qv = [[DisclosureQuartzView alloc] initWithFrame:CGRectMake(0.f, 0.f, 28.f, 28.f)];
		//UIImageView *iv = [[UIImageView alloc] initWithImage:[qv imageFromUIView]];
		self.accessoryView = qv;
		//[iv release];
		
		self.backgroundColor = [TexLegeTheme backgroundLight];
		
    }
    return self;
}



- (void)setCellInfo:(TableCellDataObject *)newCellInfo {	
	if (cellInfo)
		cellInfo = nil;
	
	if (newCellInfo) {
		cellInfo = newCellInfo;
		self.detailTextLabel.text = cellInfo.title;
		self.textLabel.text = cellInfo.subtitle;
		if (!cellInfo.isClickable) {
			self.selectionStyle = UITableViewCellSelectionStyleNone;
			self.accessoryType = UITableViewCellAccessoryNone;
			self.accessoryView = nil;
		}
	}
		
}

@end
