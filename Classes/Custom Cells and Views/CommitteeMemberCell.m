//
//  CommitteeMemberCell.m
//  Created by Gregory Combs on 8/9/10.
//
//  StatesLege by Sunlight Foundation, based on work at https://github.com/sunlightlabs/StatesLege
//
//  This work is licensed under the Creative Commons Attribution-NonCommercial 3.0 Unported License. 
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc/3.0/
//  or send a letter to Creative Commons, 444 Castro Street, Suite 900, Mountain View, California, 94041, USA.
//
//

#import "CommitteeMemberCell.h"
#import "CommitteeMemberCellView.h"
#import "LegislatorObj.h"
#import "DisclosureQuartzView.h"
#import <SDWebImage/UIImageView+WebCache.h>

@implementation CommitteeMemberCell
@synthesize cellView;


- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
	
	if ((self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier])) {
		
		// Create a time zone view and add it as a subview of self's contentView.

		//UIImage *tempImage = [UIImage imageNamed:@"anchia.png"];
		//self.imageView.image = tempImage;
		
		DisclosureQuartzView *qv = [[DisclosureQuartzView alloc] initWithFrame:CGRectMake(0.f, 0.f, 28.f, 28.f)];
		//UIImageView *iv = [[UIImageView alloc] initWithImage:[qv imageFromUIView]];
		self.accessoryView = qv;
		//[iv release];
		
		CGFloat endX = self.contentView.bounds.size.width - 53.f;
		CGRect tzvFrame = CGRectMake(53.f, 0.0, endX, self.contentView.bounds.size.height);
		cellView = [[CommitteeMemberCellView alloc] initWithFrame:tzvFrame];
		cellView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		[self.contentView addSubview:cellView];
	}
	return self;
}

 - (void)setHighlighted:(BOOL)val animated:(BOOL)animated {               // animate between regular and highlighted state
	[super setHighlighted:val animated:animated];

	self.cellView.highlighted = val;
}

- (void)setSelected:(BOOL)val animated:(BOOL)animated {               // animate between regular and highlighted state
	[super setHighlighted:val animated:animated];
	
	self.cellView.highlighted = val;
}

- (void)setLegislator:(LegislatorObj *)value
{
    NSURL *photoURL = nil;
    if (value && value.photo_url)
    {
        photoURL = [NSURL URLWithString:value.photo_url];
    }
    [self.imageView setImageWithURL:photoURL placeholderImage:[UIImage imageNamed:@"placeholder"]];
	[self.cellView setLegislator:value];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    CGRect imageRect = CGRectZero;
    CGRect contentRect = CGRectZero;
    CGRectDivide(self.contentView.bounds, &imageRect, &contentRect, 53, CGRectMinXEdge);

    self.imageView.frame = imageRect;
    self.cellView.frame = contentRect;
}

- (void)redisplay {
	[cellView setNeedsDisplay];
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    [self setLegislator:nil];
}

- (void)dealloc {
	if (cellView)
		cellView = nil;
	
}

@end
