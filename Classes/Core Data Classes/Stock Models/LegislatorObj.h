//
//  LegislatorObj.h
//  Created by Gregory Combs on 1/22/11.
//
//  StatesLege by Sunlight Foundation, based on work at https://github.com/sunlightlabs/StatesLege
//
//  This work is licensed under the Creative Commons Attribution-NonCommercial 3.0 Unported License. 
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc/3.0/
//  or send a letter to Creative Commons, 444 Castro Street, Suite 900, Mountain View, California, 94041, USA.
//
//

#import <CoreData/CoreData.h>

@class CommitteePositionObj;
@class DistrictMapObj;
@class DistrictOfficeObj;
@class StafferObj;
@class WnomObj;

@interface LegislatorObj :  NSManagedObject

@property (nonatomic, strong) NSString * transDataContributorID;
@property (nonatomic, strong) NSNumber * legislatorID;
@property (nonatomic, strong) NSString * lastnameInitial;
@property (nonatomic, strong) NSString * cap_office;
@property (nonatomic, strong) NSNumber * votesmartDistrictID;
@property (nonatomic, strong) NSNumber * tenure;
@property (nonatomic, strong) NSString * stateID;
@property (nonatomic, strong) NSString * cap_fax;
@property (nonatomic, strong) NSString * nickname;
@property (nonatomic, strong) NSNumber * party_id;
@property (nonatomic, strong) NSNumber * nimsp_id;
@property (nonatomic, strong) NSString * updatedDate;
@property (nonatomic, strong) NSString * twitter;
@property (nonatomic, strong) NSNumber * district;
@property (nonatomic, strong) NSString * cap_phone2;
@property (nonatomic, strong) NSString * searchName;
@property (nonatomic, strong) NSString * email;
@property (nonatomic, strong) NSString * party_name;
@property (nonatomic, strong) NSString * legtype_name;
@property (nonatomic, strong) NSString * txlonline_id;
@property (nonatomic, strong) NSString * suffix;
@property (nonatomic, strong) NSString * bio_url;
@property (nonatomic, strong) NSString * cap_phone2_name;
@property (nonatomic, strong) NSString * middlename;
@property (nonatomic, strong) NSString * cap_phone;
@property (nonatomic, strong) NSString * photo_name;
@property (nonatomic, strong) NSString * lastname;
@property (nonatomic, strong) NSString * photo_url;
@property (nonatomic, strong) NSString * firstname;
@property (nonatomic, strong) NSString * openstatesID;
@property (nonatomic, strong) NSString * preferredname;
@property (nonatomic, strong) NSNumber * votesmartOfficeID;
@property (nonatomic, strong) NSNumber * partisan_index;
@property (nonatomic, strong) NSString * notes;
@property (nonatomic, strong) NSNumber * nextElection;
@property (nonatomic, strong) NSNumber * legtype;
@property (nonatomic, strong) NSNumber * votesmartID;
@property (nonatomic, strong) NSSet* wnomScores;
@property (nonatomic, strong) NSSet* staffers;
@property (nonatomic, strong) NSSet* committeePositions;
@property (nonatomic, strong) NSSet* districtOffices;
@property (nonatomic, strong) DistrictMapObj * districtMap;

@end


@interface LegislatorObj (CoreDataGeneratedAccessors)

- (void)addDistrictOfficesObject:(DistrictOfficeObj *)value;
- (void)removeDistrictOfficesObject:(DistrictOfficeObj *)value;
- (void)addDistrictOffices:(NSSet *)value;
- (void)removeDistrictOffices:(NSSet *)value;

- (void)addWnomScoresObject:(WnomObj *)value;
- (void)removeWnomScoresObject:(WnomObj *)value;
- (void)addWnomScores:(NSSet *)value;
- (void)removeWnomScores:(NSSet *)value;

- (void)addStaffersObject:(StafferObj *)value;
- (void)removeStaffersObject:(StafferObj *)value;
- (void)addStaffers:(NSSet *)value;
- (void)removeStaffers:(NSSet *)value;

- (void)addCommitteePositionsObject:(CommitteePositionObj *)value;
- (void)removeCommitteePositionsObject:(CommitteePositionObj *)value;
- (void)addCommitteePositions:(NSSet *)value;
- (void)removeCommitteePositions:(NSSet *)value;

@end

