
//
//  TexLegeAnnotation.h
//  Created by Gregory Combs on 7/27/10.
//
//  StatesLege by Sunlight Foundation, based on work at https://github.com/sunlightlabs/StatesLege
//
//  This work is licensed under the Creative Commons Attribution-NonCommercial 3.0 Unported License. 
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc/3.0/
//  or send a letter to Creative Commons, 444 Castro Street, Suite 900, Mountain View, California, 94041, USA.
//
//

#import "UserPinAnnotation.h"
#import "TexLegeAppDelegate.h"
#import <AddressBookUI/ABAddressFormatting.h>
#import "UtilityMethods.h"
#import "MapViewController.h"

NSString * const kUserPinAnnotationAddressChangeKey = @"UserPinAnnotationAddressChangeNotification";

@implementation UserPinAnnotation

- (instancetype)initWithPlacemark:(CLPlacemark *)placemark
{
    self = [super init];
    if (self)
    {
        if (placemark)
        {
            _placemark = [placemark copy];
            self.coordinate = placemark.location.coordinate;
        }

        _pinColorIndex = [@(MKPinAnnotationColorPurple) copy];
        
        [self reloadTitle];

    }
    return self;
}

- (NSDictionary *)addressDictionary;
{
    CLPlacemark *placemark = self.placemark;
    if (!placemark)
        return nil;
    return placemark.addressDictionary;
}

- (NSString*)debugDescription
{
    CLLocationCoordinate2D coordinate = self.coordinate;
    NSDictionary *address = self.addressDictionary;
    if (!address)
        address = @{};
    NSDictionary *values = @{
                             @"address": address,
                             @"coordinate": @{
                                     @"latitude": @(coordinate.latitude),
                                     @"longitude": @(coordinate.longitude)
                                     }
                             };
    
    return [values description];
}

- (void)setCoordinate:(CLLocationCoordinate2D)newCoordinate
{
    super.coordinate = newCoordinate;
    
    self.title = [[NSString alloc] initWithFormat:@"%f %f", newCoordinate.latitude, newCoordinate.longitude];
    
    if (self.coordinateChangedDelegate
        && [self.coordinateChangedDelegate respondsToSelector:@selector(annotationCoordinateChanged:)])
    {
        [self.coordinateChangedDelegate annotationCoordinateChanged:self];
    }
}

- (void)dealloc
{
    nice_release(_imageName);
    nice_release(_pinColorIndex);
    nice_release(_placemark);

    self.coordinateChangedDelegate = nil;

	[super dealloc];
}

- (void)reloadTitle
{
	NSMutableString *formattedAddress = [[NSMutableString alloc] init];

    NSDictionary *addressDict = self.addressDictionary;
	if (addressDict)
    {
		NSString *street = addressDict[(NSString*)kABPersonAddressStreetKey];
		NSString *city = addressDict[(NSString*)kABPersonAddressCityKey];
		NSString *state = addressDict[(NSString*)kABPersonAddressStateKey];
		
		if (NO == IsEmpty(street)) {
			[formattedAddress appendFormat:@"%@, ", street];
		}
		if (NO == IsEmpty(city) && NO == IsEmpty(state)) {
			[formattedAddress appendFormat:@"%@, %@", city, state];
		}		
	}
    
	if (!formattedAddress.length)
    {
        CLLocationCoordinate2D coordinate = self.coordinate;
		[formattedAddress appendFormat:@"%f %f", coordinate.latitude, coordinate.longitude];
	}
    
	self.title = formattedAddress;
    
    nice_release(formattedAddress);
}

#pragma mark -
#pragma mark MKAnnotation properties

- (UIImage *)image
{
    NSString *imageName = self.imageName;
	if (IsEmpty(imageName))
    {
		return [UIImage imageNamed:@"silverstar.png"];
	}
    return [UIImage imageNamed:imageName];
}

- (NSString *)subtitle
{
    NSString *subtitle = [super subtitle];
	if (IsEmpty(subtitle))
    {
        return NSLocalizedStringFromTable(@"Tap & hold to move pin", @"StandardUI", @"Instructions for moving a location pin on the map");
    }
    return subtitle;
}

@end
