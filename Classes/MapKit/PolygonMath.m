//
//  PolygonMath.m
//  Created by Gregory Combs on 7/27/10.
//
//  StatesLege by Sunlight Foundation, based on work at https://github.com/sunlightlabs/StatesLege
//
//  This work is licensed under the Creative Commons Attribution-NonCommercial 3.0 Unported License. 
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc/3.0/
//  or send a letter to Creative Commons, 444 Castro Street, Suite 900, Mountain View, California, 94041, USA.
//
//

#import "PolygonMath.h"

BOOL const INSIDE = YES;
BOOL const OUTSIDE = NO;

@implementation PolygonMath

//The following C function returns INSIDE or OUTSIDE indicating the status of a point P with respect to a polygon with N points.

/* This will supposedly work when there's holes ... but it'll have to go in the view controller, not in here.... ?
 
 CLLocationCoordinate2D mapCoordinate = ...; //user location or annot coord
 
 MKMapPoint mapPoint = MKMapPointForCoordinate(mapCoordinate);
 
 MKPolygonView *polygonView = 
 (MKPolygonView *)[mapView viewForOverlay:polygonOverlay];
 
 CGPoint polygonViewPoint = [polygonView pointForMapPoint:mapPoint];
 
 BOOL mapCoordinateIsInPolygon = 
 CGPathContainsPoint(polygonView.path, NULL, polygonViewPoint, NO);
 
 */

+ (BOOL)insidePolygon:(CLLocationCoordinate2D *)polygon count:(UInt64)count point:(CLLocationCoordinate2D) point
{
	UInt64 counter = 0;
	UInt64 i = 0;
	double intersection = 0;
    CLLocationCoordinate2D p1 = kCLLocationCoordinate2DInvalid;
    CLLocationCoordinate2D p2 = kCLLocationCoordinate2DInvalid;
    if (!polygon)
        return NO;
	p1 = polygon[0];
	for (i=1;i<=count;i++)
    {
		p2 = polygon[(i % count)];
		if (point.longitude > MIN(p1.longitude,p2.longitude))
        {
			if (point.longitude <= MAX(p1.longitude,p2.longitude))
            {
				if (point.latitude <= MAX(p1.latitude,p2.latitude))
                {
					if (p1.longitude != p2.longitude)
                    {
						intersection = (point.longitude-p1.longitude)*(p2.latitude-p1.latitude)/(p2.longitude-p1.longitude)+p1.latitude;
						if (p1.latitude == p2.latitude || point.latitude <= intersection)
							counter++;
					}
				}
			}
		}
		p1 = p2;
	}
	
	//debug_NSLog(@"Ending insidePolygon: %@", [NSDate date]);

	if (counter % 2 == 0)
		return(OUTSIDE);
	else
		return(INSIDE);
}

//The following code is by Randolph Franklin, it returns 1 for interior points and 0 for exterior points.
+ (BOOL)pnpoly:(double *)xp yp:(double *)yp count:(UInt64)count x:(double)x y:(double)y
{
    UInt64 i = 0;
    UInt64 j = 0;
	BOOL foundInside = NO;
	for (i = 0, j = count-1; i < count; j = i++)
    {
        if ((((yp[i] <= y) && (y < yp[j])) ||
             ((yp[j] <= y) && (y < yp[i]))) &&
            (x < (xp[j] - xp[i]) * (y - yp[i]) / (yp[j] - yp[i]) + xp[i]))
			foundInside = !foundInside;
	}
	
	return foundInside;
}

@end
