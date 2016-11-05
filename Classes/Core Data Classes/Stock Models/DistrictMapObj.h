//
//  DistrictMapObj.h
//  Created by Gregory Combs on 1/22/11.
//
//  StatesLege by Sunlight Foundation, based on work at https://github.com/sunlightlabs/StatesLege
//
//  This work is licensed under the Creative Commons Attribution-NonCommercial 3.0 Unported License. 
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc/3.0/
//  or send a letter to Creative Commons, 444 Castro Street, Suite 900, Mountain View, California, 94041, USA.
//
//

#import "TexLege.h"
#import <RestKit/RestKit.h>
#import <RestKit/CoreData.h>
#import <MapKit/MapKit.h>
#import "LegislatorAnnotation.h"

@class LegislatorObj;

@interface DistrictMapObj :  RKManagedObject  <MKAnnotation, LegislatorAnnotation>

@property (nonatomic, strong) NSNumber * chamber;
@property (nonatomic, strong) NSNumber * centerLon;
@property (nonatomic, strong) NSNumber * spanLat;
@property (nonatomic, strong) NSNumber * districtMapID;
@property (nonatomic, strong) NSNumber * lineWidth;
@property (nonatomic, strong) NSString * updatedDate;
@property (nonatomic, strong) NSData * coordinatesData;
@property (nonatomic, strong) NSNumber * pinColorIndex;
@property (nonatomic, strong) NSNumber * numberOfCoords;
@property (nonatomic, strong) NSNumber * maxLat;
@property (nonatomic, strong) NSNumber * minLat;
@property (nonatomic, strong) NSNumber * spanLon;
@property (nonatomic, strong) NSString * coordinatesBase64;
@property (nonatomic, strong) NSNumber * maxLon;
@property (nonatomic, strong) NSNumber * district;
@property (nonatomic, strong) id lineColor;
@property (nonatomic, strong) NSNumber * minLon;
@property (nonatomic, strong) NSNumber * centerLat;
@property (nonatomic, strong) LegislatorObj * legislator;
@property (weak, nonatomic, readonly) NSString * boundaryID;

@end



