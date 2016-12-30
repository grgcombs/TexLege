// 
//  DistrictMapObj.m
//  Created by Gregory Combs on 8/21/10.
//
//  StatesLege by Sunlight Foundation, based on work at https://github.com/sunlightlabs/StatesLege
//
//  This work is licensed under the Creative Commons Attribution-NonCommercial 3.0 Unported License. 
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc/3.0/
//  or send a letter to Creative Commons, 444 Castro Street, Suite 900, Mountain View, California, 94041, USA.
//
//
#import "DistrictMapObj+MapKit.h"

#import "LegislatorObj+RestKit.h"
#import "PolygonMath.h"
#import "TexLegeCoreDataUtils.h"
#import "TexLegeMapPins.h"

@implementation DistrictMapObj (MapKit)

- (NSString *)title
{
	NSString *chamberString = stringForChamber(self.chamber.integerValue, TLReturnFull);
    return [NSString stringWithFormat:NSLocalizedStringFromTable(@"%@ District %@", @"DataTableUI", @"As in 'House District 32'"), 
			chamberString, self.district];
}

- (UIImage *)image
{
    NSNumber *partyID = self.legislator.party_id;
    if (partyID)
    {
        if (partyID.integerValue == DEMOCRAT)
            return [UIImage imageNamed:@"bluestar.png"];
        if (partyID.integerValue == REPUBLICAN)
            return [UIImage imageNamed:@"redstar.png"];
    }
    return [UIImage imageNamed:@"silverstar.png"];
}

- (NSString *)subtitle
{
	return [NSString stringWithFormat:@"%@ %@ (%@)",
                                        [self.legislator legTypeShortName],
                                        [self.legislator legProperName],
                                        [self.legislator partyShortName]];
}

- (CLLocationCoordinate2D)center
{
	return self.coordinate;
}

- (MKCoordinateRegion)region
{
	return MKCoordinateRegionMake(self.center, self.span);
}

- (MKCoordinateSpan) span
{
	return MKCoordinateSpanMake(self.spanLat.doubleValue, self.spanLon.doubleValue);
}

- (MKPolyline *)polyline
{
    CLLocationCoordinate2D * coordinateBytes = (CLLocationCoordinate2D *)self.coordinatesData.bytes;
    NSUInteger coordinateCount = self.numberOfCoords.unsignedIntegerValue;
	MKPolyline *polyLine = [MKPolyline polylineWithCoordinates:coordinateBytes count:coordinateCount];
	polyLine.title = self.title;
	polyLine.subtitle = self.subtitle;
	return polyLine;
}

- (MKPolygon *)polygon
{
    NSArray *interiorPolygons = nil;

    if (self.district && (self.district).integerValue == 83) // special case, at least until the next redistricting)
    {
		DistrictMapObj *interiorDistrict = [TexLegeCoreDataUtils districtMapForDistrict:@84 andChamber:self.chamber];
		if (interiorDistrict)
        {
			MKPolygon *interiorPolygon = [interiorDistrict polygon];
			if (interiorPolygon)
				interiorPolygons = @[interiorPolygon];
		}
	}

    CLLocationCoordinate2D * coordinateBytes = (CLLocationCoordinate2D *)self.coordinatesData.bytes;
    NSUInteger coordinateCount = self.numberOfCoords.unsignedIntegerValue;
    MKPolygon *polygon = nil;
    if (interiorPolygons)
        polygon = [MKPolygon polygonWithCoordinates:coordinateBytes count:coordinateCount interiorPolygons:interiorPolygons];
	else
        polygon = [MKPolygon polygonWithCoordinates:coordinateBytes count:coordinateCount];

    if (!polygon)
        return nil;

	polygon.title = self.title;
	polygon.subtitle = self.subtitle;

	return polygon;
}

- (BOOL)boundingBoxContainsCoordinate:(CLLocationCoordinate2D)aCoordinate
{
	return (aCoordinate.latitude <= self.maxLat.doubleValue &&
			aCoordinate.latitude >= self.minLat.doubleValue &&
			aCoordinate.longitude <= self.maxLon.doubleValue &&
			aCoordinate.longitude >= self.minLon.doubleValue);
}

- (BOOL)districtContainsCoordinate:(CLLocationCoordinate2D)aCoordinate
{
	//if (![self boundingBoxContainsCoordinate:aCoordinate])  // why am I not using this optimization???
	//	return NO;

    NSData *data = self.coordinatesData; // [self valueForKey:@"coordinatesData"]
    if (!data || !data.length)
        return NO;
    NSUInteger coordinateCount = self.numberOfCoords.unsignedIntegerValue; // [[self valueForKey:@"numberOfCoords"] integerValue]
    CLLocationCoordinate2D *coordinates = (CLLocationCoordinate2D *)[data bytes];

	return [PolygonMath insidePolygon:coordinates count:coordinateCount point:aCoordinate];
}

@end
