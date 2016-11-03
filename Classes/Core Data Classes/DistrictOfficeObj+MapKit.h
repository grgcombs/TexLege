//
//  DistrictOfficeObj.h
//  Created by Gregory Combs on 8/21/10.
//
//  StatesLege by Sunlight Foundation, based on work at https://github.com/sunlightlabs/StatesLege
//
//  This work is licensed under the Creative Commons Attribution-NonCommercial 3.0 Unported License. 
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc/3.0/
//  or send a letter to Creative Commons, 444 Castro Street, Suite 900, Mountain View, California, 94041, USA.
//
//

#import <RestKit/RestKit.h>
#import <RestKit/CoreData.h>
#import <MapKit/MapKit.h>

#import "DistrictOfficeObj.h"

@interface DistrictOfficeObj (MapKit)

// MKAnnotation protocol
@property (nonatomic, readonly) MKCoordinateRegion		region;
@property (nonatomic, readonly) MKCoordinateSpan		span;

@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSString *title;
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSString *subtitle;
@property (NS_NONATOMIC_IOSONLY, readonly, strong) UIImage *image;
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSString *cellAddress;
@end



