//
//  TexLegeCoreDataUtils.h
//  Created by Gregory Combs on 8/31/10.
//
//  StatesLege by Sunlight Foundation, based on work at https://github.com/sunlightlabs/StatesLege
//
//  This work is licensed under the Creative Commons Attribution-NonCommercial 3.0 Unported License. 
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc/3.0/
//  or send a letter to Creative Commons, 444 Castro Street, Suite 900, Mountain View, California, 94041, USA.
//
//

#import "TexLege.h"
#import <MapKit/MapKit.h>
#import <CoreData/CoreData.h>
#import <SLFRestKit/SLFRestKit.h>

//@class TexLegeDataMaintenance;

@class LegislatorObj, CommitteeObj, DistrictMapObj;

@interface TexLegeCoreDataUtils : NSObject<RKManagedObjectStoreDelegate>

+ (id) fetchCalculation:(NSString *)calc ofProperty:(NSString *)prop withType:(NSAttributeType)retType onEntity:(NSString *)entityName;

+ (id)dataObjectWithPredicate:(NSPredicate *)predicate entityName:(NSString*)entityName;
+ (LegislatorObj*)legislatorForDistrict:(NSNumber*)district andChamber:(NSNumber*)chamber;
+ (DistrictMapObj*)districtMapForDistrict:(NSNumber*)district andChamber:(NSNumber*)chamber;

+ (NSArray *) allLegislatorsSortedByPartisanshipFromChamber:(NSInteger)chamber andPartyID:(NSInteger)party;
+ (NSArray *) allDistrictMapIDsWithBoundingBoxesContaining:(CLLocationCoordinate2D)coordinate;
+ (NSArray*) allPrimaryKeyIDsInEntityNamed:(NSString*)entityName;

#if 0 // can't get custom objects while using propertiesToFetch: anymore
+ (NSArray *) allDistrictMapsLight;
#endif

+ (void) deleteObjectInEntityNamed:(NSString *)entityName withPrimaryKeyValue:(id)keyValue;
+ (void) deleteAllObjectsInEntityNamed:(NSString*)entityName;

//+ (void)loadDataFromRest:(NSString *)entityName delegate:(id)delegate;
+ (void)initRestKitObjects;
+ (void)resetSavedDatabase;
+ (NSArray *)registeredDataModels;

@end

/*
typedef enum {
    TexLegeDataMaintenanceFailOptionLog,
    TexLegeDataMaintenanceFailShowAlert,
    
	TexLegeDataMaintenanceFailOptionCount
} TexLegeDataMaintenanceFailOption;

@protocol TexLegeDataMaintenanceDelegate
- (void)dataMaintenanceDidFinishSuccessfully:(TexLegeDataMaintenance *)op;
- (void)dataMaintenanceDidFail:(TexLegeDataMaintenance *)op 
							 errorMessage:(NSString *)errorMessage 
								   option:(TexLegeDataMaintenanceFailOption)failOption;
@end

@interface TexLegeDataMaintenance : NSOperation 
{
    __weak  NSObject <TexLegeDataMaintenanceDelegate> *delegate;
}
@property (assign) NSObject <TexLegeDataMaintenanceDelegate> *delegate;

- (id) initWithDelegate:(id<TexLegeDataMaintenanceDelegate>)newDelegate;

@end
 */
