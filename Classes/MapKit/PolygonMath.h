//
//  PolygonMath.h
//  Created by Gregory Combs on 7/27/10.
//
//  StatesLege by Sunlight Foundation, based on work at https://github.com/sunlightlabs/StatesLege
//
//  This work is licensed under the Creative Commons Attribution-NonCommercial 3.0 Unported License. 
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc/3.0/
//  or send a letter to Creative Commons, 444 Castro Street, Suite 900, Mountain View, California, 94041, USA.
//
//

@import Foundation;
@import CoreLocation;

typedef struct {
	double x,y;
} MapPoint;

@interface PolygonMath : NSObject

+ (BOOL)insidePolygon:(CLLocationCoordinate2D *)polygon count:(UInt64)count point:(CLLocationCoordinate2D)point;
+ (BOOL)pnpoly:(double *)xp yp:(double *)yp count:(UInt64)npol x:(double)x y:(double)y;

@end
