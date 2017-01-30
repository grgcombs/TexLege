//
//  LegislatorContributionsDataSource.h
//  Created by Gregory Combs on 9/16/10.
//
//  StatesLege by Sunlight Foundation, based on work at https://github.com/sunlightlabs/StatesLege
//
//  This work is licensed under the Creative Commons Attribution-NonCommercial 3.0 Unported License. 
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc/3.0/
//  or send a letter to Creative Commons, 444 Castro Street, Suite 900, Mountain View, California, 94041, USA.
//
//

#import <UIKit/UIKit.h>
#import <SLFRestKit/SLFRestKit.h>

typedef NS_ENUM(uint16_t, ContributionQueryType) {
	kContributionQueryElectionYear = 0,
    kContributionQueryTopDonations,
	kContributionQueryDonor,
	kContributionQueryIndividual,
	kContributionQueryTop10Recipients,
	kContributionQueryTop10RecipientsIndiv,
	kContributionQueryEntitySearch,
};

#define kContributionsDataNotifyLoaded	@"ContributionsDataChangedKey"
#define kContributionsDataNotifyError	@"ContributionsDataErrorKey"

@interface LegislatorContributionsDataSource : NSObject <RKRequestDelegate, UITableViewDataSource>

- (id)dataObjectForIndexPath:(NSIndexPath *)indexPath;
- (NSIndexPath *) indexPathForDataObject:(id)dataObject;
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSString *title;

- (void)initiateQueryWithQueryID:(NSString *)aQuery type:(NSNumber *)type cycle:(NSString *)cycleOrNil parameter:(NSString *)parameterOrNil;

@end

#define FOLLOW_THE_MONEY_API 1
#define TRANSPARENCY_DATA_API 2
#define CONTRIBUTIONS_API   FOLLOW_THE_MONEY_API
