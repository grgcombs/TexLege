//
//  TexLegePinAnnotationView.m
//  Created by Gregory Combs on 9/13/10.
//
//  StatesLege by Sunlight Foundation, based on work at https://github.com/sunlightlabs/StatesLege
//
//  This work is licensed under the Creative Commons Attribution-NonCommercial 3.0 Unported License. 
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc/3.0/
//  or send a letter to Creative Commons, 444 Castro Street, Suite 900, Mountain View, California, 94041, USA.
//
//

#import "DistrictPinAnnotationView.h"
#import "DistrictMapObj+MapKit.h"
#import "DistrictOfficeObj+MapKit.h"
#import <SLToastKit/SLTypeCheck.h>

@implementation DistrictPinAnnotationView

- (instancetype)initWithAnnotation:(id <MKAnnotation>)annotation reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithAnnotation:annotation reuseIdentifier:reuseIdentifier];
	if (self)
    {
		self.animatesDrop = YES;
		self.opaque = NO;
		self.draggable = NO;
		self.canShowCallout = YES;
				
		UIButton *rightButton = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
		self.rightCalloutAccessoryView = rightButton;
		
		[self resetPinColorWithAnnotation:annotation];
	}
	return self;
}

- (void)resetPinColorWithAnnotation:(id <MKAnnotation>)anAnnotation
{
    DistrictMapObj *asBoundary = SLValueIfClass(DistrictMapObj,anAnnotation);
    DistrictOfficeObj *asOffice = SLValueIfClass(DistrictOfficeObj,anAnnotation);
    
    UIImage *image = nil;
    UIColor *tintColor = nil;
    if (asBoundary)
    {
        tintColor = asBoundary.pinTintColor;
        image = asBoundary.image;
    }
    if (asOffice)
    {
        tintColor = asOffice.pinTintColor;
        image = asOffice.image;
    }
    
    if (tintColor)
        self.pinTintColor = tintColor;
    
	if (image)
    {
		UIImageView *iconView = [[UIImageView alloc] initWithImage:image];
		self.leftCalloutAccessoryView = iconView;
	}
}

// MKPinAnnotationView+ZIndexFix
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event 
{
	[self.superview bringSubviewToFront:self];
	[super touchesBegan:touches withEvent:event];
}

@end
