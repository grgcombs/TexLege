//
//  LegislatorObj.h
//  Created by Gregory Combs on 7/10/09.
//
//  StatesLege by Sunlight Foundation, based on work at https://github.com/sunlightlabs/StatesLege
//
//  This work is licensed under the Creative Commons Attribution-NonCommercial 3.0 Unported License. 
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc/3.0/
//  or send a letter to Creative Commons, 444 Castro Street, Suite 900, Mountain View, California, 94041, USA.
//
//

#import "LegislatorObj.h"

@class RKManagedObjectMapping;

@interface LegislatorObj (RestKit)

+ (NSString*)primaryKeyProperty;
+ (RKManagedObjectMapping *)attributeMapping;
- (NSComparisonResult)compareMembersByName:(LegislatorObj *)p;

@property (NS_NONATOMIC_IOSONLY, readonly) NSString * districtMapURL;
@property (NS_NONATOMIC_IOSONLY, readonly) WnomObj *latestWnomScore;
@property (NS_NONATOMIC_IOSONLY, readonly) double latestWnomFloat;
@property (NS_NONATOMIC_IOSONLY, readonly) NSString *partyShortName;
@property (NS_NONATOMIC_IOSONLY, readonly) NSString *legTypeShortName;
@property (NS_NONATOMIC_IOSONLY, readonly) NSString *chamberName;
@property (NS_NONATOMIC_IOSONLY, readonly) NSString *legProperName;
@property (NS_NONATOMIC_IOSONLY, readonly) NSString *districtPartyString;
@property (NS_NONATOMIC_IOSONLY, readonly) NSString *fullName;
@property (NS_NONATOMIC_IOSONLY, readonly) NSString *fullNameLastFirst;
@property (NS_NONATOMIC_IOSONLY, readonly) NSString *website;
@property (NS_NONATOMIC_IOSONLY, readonly) NSString *shortNameForButtons;
@property (NS_NONATOMIC_IOSONLY, readonly) NSString *labelSubText;
@property (NS_NONATOMIC_IOSONLY, readonly) NSInteger numberOfDistrictOffices;
@property (NS_NONATOMIC_IOSONLY, readonly) NSInteger numberOfStaffers;
@property (NS_NONATOMIC_IOSONLY, readonly) NSString *tenureString;
@property (NS_NONATOMIC_IOSONLY, readonly) NSArray<CommitteePositionObj *> *sortedCommitteePositions;
@property (NS_NONATOMIC_IOSONLY, readonly) NSArray<StafferObj *> *sortedStaffers;

@end
