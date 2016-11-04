//
//  CustomAnnotation.h
//  Created by Gregory Combs on 7/27/10.
//
//  StatesLege by Sunlight Foundation, based on work at https://github.com/sunlightlabs/StatesLege
//
//  This work is licensed under the Creative Commons Attribution-NonCommercial 3.0 Unported License. 
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc/3.0/
//  or send a letter to Creative Commons, 444 Castro Street, Suite 900, Mountain View, California, 94041, USA.
//
//

@import MapKit;
@import CoreLocation;

@protocol UserPinAnnotationDelegate <NSObject>
- (void)annotationCoordinateChanged:(id)sender;
@end


@interface UserPinAnnotation : MKPointAnnotation

- (instancetype)initWithPlacemark:(CLPlacemark *)placemark;

@property (nonatomic, copy) NSNumber *pinColorIndex;
@property (nonatomic, copy) NSString *imageName;
@property (nonatomic, copy) CLPlacemark *placemark;
@property (nonatomic, readonly) NSDictionary *addressDictionary;
@property (nonatomic, unsafe_unretained) id <UserPinAnnotationDelegate>	coordinateChangedDelegate;

@property (NS_NONATOMIC_IOSONLY, readonly, strong) UIImage *image;

@end

extern NSString * const kUserPinAnnotationAddressChangeKey;

