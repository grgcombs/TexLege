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
#import "DistrictMapObj+RestKit.h"
#import <SLFRestKit/SLFRestKit.h>
#import "LegislatorObj.h"
#import "TexLegeCoreDataUtils.h"

static RKManagedObjectMapping *districtAttributeMapping = nil;

@implementation DistrictMapObj (RestKit)

+ (NSString*)primaryKeyProperty
{
    return @"districtMapID";
}

+ (RKManagedObjectMapping *)attributeMapping
{
    if (districtAttributeMapping)
        return districtAttributeMapping;

    RKManagedObjectMapping *mapping = [RKManagedObjectMapping mappingForClass:[self class] inManagedObjectStore:[RKObjectManager sharedManager].objectStore];
    mapping.primaryKeyAttribute = @"districtMapID";
    [mapping mapAttributesFromArray:@[
                                      @"districtMapID",
                                      @"chamber",
                                      @"district",
                                      @"centerLat",
                                      @"centerLon",
                                      @"maxLat",
                                      @"maxLon",
                                      @"minLat",
                                      @"minLon",
                                      @"spanLat",
                                      @"spanLon",
                                      @"pinColorIndex",
                                      @"lineColor",
                                      @"lineWidth",
                                      @"coordinatesBase64",
                                      @"numberOfCoords",
                                      @"coordinatesData",
                                      ]];
    [mapping mapKeyPath:@"updated" toAttribute:@"updatedDate"];
    //[mapping connectRelationship:@"legislator" withObjectForPrimaryKeyAttribute:@"legislatorID"];

    districtAttributeMapping = mapping;

    return mapping;
}

- (void)resetRelationship:(id)sender
{
	LegislatorObj * aLegislator = [TexLegeCoreDataUtils legislatorForDistrict:self.district andChamber:self.chamber];
	self.legislator = aLegislator;
}

- (void)setCoordinatesBase64:(NSString *)newCoords
{
	NSString *key = @"coordinatesBase64";

    NSData *coordinatesData = nil;
    if (newCoords && newCoords.length)
        coordinatesData = [[NSData alloc] initWithBase64EncodedString:newCoords options:NSDataBase64DecodingIgnoreUnknownCharacters];
    self.coordinatesData = coordinatesData;

	[self willChangeValueForKey:key];
	[self setPrimitiveValue:nil forKey:key];
	[self didChangeValueForKey:key];
}

#if 0

- (void) importFromDictionary: (NSDictionary *)dictionary
{				
	if (dictionary) {
		for (NSString *key in [dictionary allKeys]) {
			if ([key isEqualToString:@"coordinatesData"]) {				
				id data = [dictionary objectForKey:@"coordinatesData"];
				
				if ([data isKindOfClass:[NSString class]]) {   
					self.coordinatesData = [NSData dataWithBase64EncodedString:data];
				}
				else if ([data isKindOfClass:[NSArray class]]) {
					
					NSInteger numberOfPairs = [self.numberOfCoords integerValue];
					CLLocationCoordinate2D *coordinatesCArray = calloc(numberOfPairs, sizeof(CLLocationCoordinate2D));
					NSInteger count = 0;
					if (coordinatesCArray) {
						for (NSArray *spot in data) {
							
							NSNumber *longitude = [spot objectAtIndex:0];
							NSNumber *latitude = [spot objectAtIndex:1];
							
							if (longitude && latitude) {
								double lng = [longitude doubleValue];
								double lat = [latitude doubleValue];
								coordinatesCArray[count++] = CLLocationCoordinate2DMake(lat,lng);
							}
						}
						
						self.coordinatesData = [NSData dataWithBytes:(const void *)coordinatesCArray 
															  length:numberOfPairs*sizeof(CLLocationCoordinate2D)];
						
						free(coordinatesCArray);
					}
				}
				else if ([data isKindOfClass:[NSData class]])
					self.coordinatesData = [data copy];				
			}
			else {
				NSArray *myKeys = [[[self class] elementToPropertyMappings] allKeys];
				if ([myKeys containsObject:key])
					[self setValue:[dictionary objectForKey:key] forKey:key];
			}
		}				
	}
}

- (id) initWithCoder: (NSCoder *)coder
{
	if (self = [super init])
	{
		for (NSString *key in [[[self class] elementToPropertyMappings] allKeys]) {
			if ([key isEqualToString:@"coordinatesData"]) {
				self.coordinatesData = [[coder decodeObjectForKey:@"coordinatesData"] copy];
			}
			else {
				[self setValue:[coder decodeObjectForKey:key] forKey:key];
			}
		}
	}
	return self;
}

- (NSDictionary *)exportToDictionary {
	NSDictionary *tempDict = [self dictionaryWithValuesForKeys:[[[self class] elementToPropertyMappings] allKeys]];	
	return tempDict;
}

- (void)encodeWithCoder:(NSCoder *)coder;
{
	NSDictionary *tempDict = [self exportToDictionary];
	for (NSString *key in [[[self class] elementToPropertyMappings] allKeys]) {
		id object = [tempDict objectForKey:key];
		[coder encodeObject:object];	
	}
}

#endif

@end
