//
//  DistrictOfficeObj.h
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

@interface DistrictOfficeObj :  RKManagedObject  <MKAnnotation, LegislatorAnnotation>

@property (nonatomic, strong) NSNumber * chamber;
@property (nonatomic, strong) NSNumber * spanLat;
@property (nonatomic, strong) NSString * phone;
@property (nonatomic, strong) NSNumber * districtOfficeID;
@property (nonatomic, strong) NSNumber * pinColorIndex;
@property (nonatomic, strong) NSNumber * longitude;
@property (nonatomic, strong) NSString * stateCode;
@property (nonatomic, strong) NSNumber * latitude;
@property (nonatomic, strong) NSString * updatedDate;
@property (nonatomic, strong) NSString * fax;
@property (nonatomic, strong) NSString * formattedAddress;
@property (nonatomic, strong) NSString * address;
@property (nonatomic, strong) NSString * city;
@property (nonatomic, strong) NSString * county;
@property (nonatomic, strong) NSNumber * district;
@property (nonatomic, strong) NSNumber * spanLon;
@property (nonatomic, strong) NSString * zipCode;
@property (nonatomic, strong) NSNumber * legislatorID;
@property (nonatomic, strong) LegislatorObj * legislator;

@end



