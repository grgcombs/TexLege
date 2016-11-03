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

@interface LegislatorObj (RestKit)

@property (nonatomic, readonly) NSString * districtMapURL;
@property (nonatomic, readonly) WnomObj *latestWnomScore;
@property (nonatomic, readonly) CGFloat latestWnomFloat;

- (NSComparisonResult)compareMembersByName:(LegislatorObj *)p;
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSString *partyShortName;
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSString *legTypeShortName;
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSString *chamberName;
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSString *legProperName;
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSString *districtPartyString;
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSString *fullName;
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSString *fullNameLastFirst;
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSString *website;
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSString *shortNameForButtons;
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSString *labelSubText;
@property (NS_NONATOMIC_IOSONLY, readonly) NSInteger numberOfDistrictOffices;
@property (NS_NONATOMIC_IOSONLY, readonly) NSInteger numberOfStaffers;
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSString *tenureString;
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSArray *sortedCommitteePositions;
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSArray *sortedStaffers;
@end
