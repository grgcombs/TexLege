//
//  CustomAnnotationView.m
//  Created by Gregory Combs on 9/7/10.
//
//  StatesLege by Sunlight Foundation, based on work at https://github.com/sunlightlabs/StatesLege
//
//  This work is licensed under the Creative Commons Attribution-NonCommercial 3.0 Unported License. 
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc/3.0/
//  or send a letter to Creative Commons, 444 Castro Street, Suite 900, Mountain View, California, 94041, USA.
//
//

#import "UserPinAnnotationView.h"
#import "UserPinAnnotation.h"
#import "TexLegeMapPins.h"
#import <SLToastKit/SLTypeCheck.h>

@implementation UserPinAnnotationView

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)initWithAnnotation:(id <MKAnnotation>)annotation reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithAnnotation:annotation reuseIdentifier:reuseIdentifier];
    
	if (self)
    {
		self.animatesDrop = YES;
		self.opaque = NO;
		self.draggable = YES;
		
        UserPinAnnotation *pinAnnoatation = SLValueIfClass(UserPinAnnotation, annotation);
        if (!pinAnnoatation)
            return self;
		
		self.canShowCallout = YES;

        TexLegePinAnnotationColor pinColorIndex = pinAnnoatation.pinColorIndex.unsignedIntegerValue;
        self.pinTintColor = pinTintColorForColorIndex(pinColorIndex);

		UIImage *image = [pinAnnoatation image];
		if (image)
        {
			UIImageView *iconView = [[UIImageView alloc] initWithImage:image];
			self.leftCalloutAccessoryView = iconView;
		}			
	
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(annotationChanged_:) name:kUserPinAnnotationAddressChangeKey object:annotation];
        }];
	}
	return self;
}

- (void)annotationChanged_:(NSNotification *)notification
{
	[self setNeedsDisplay];
}
	
// MKPinAnnotationView+ZIndexFix
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event 
{
	[self.superview bringSubviewToFront:self];
	[super touchesBegan:touches withEvent:event];
}

@end
