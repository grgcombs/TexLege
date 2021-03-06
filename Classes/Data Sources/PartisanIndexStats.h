//
//  PartisanIndexStats.h
//  Created by Gregory Combs on 7/9/10.
//
//  StatesLege by Sunlight Foundation, based on work at https://github.com/sunlightlabs/StatesLege
//
//  This work is licensed under the Creative Commons Attribution-NonCommercial 3.0 Unported License. 
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc/3.0/
//  or send a letter to Creative Commons, 444 Castro Street, Suite 900, Mountain View, California, 94041, USA.
//
//

#import <SLFRestKit/SLFRestKit.h>
#import "TexLegeLibrary.h"

#define kPartisanIndexNotifyError	@"PARTISAN_INDEX_ERROR"
#define kPartisanIndexNotifyLoaded	@"PARTISAN_INDEX_LOADED"

@class LegislatorObj;
@class PartyPartisanshipObj;

@interface PartisanIndexStats : NSObject <RKRequestDelegate>

@property (NS_NONATOMIC_IOSONLY, copy, readonly) NSDictionary *partisanIndexAggregates;
@property (NS_NONATOMIC_IOSONLY, copy, readonly) NSDate *updated;
@property (NS_NONATOMIC_IOSONLY, readonly, getter=isFresh) BOOL fresh;
@property (NS_NONATOMIC_IOSONLY, readonly, getter=isLoading) BOOL loading;
@property (NS_NONATOMIC_IOSONLY, readonly) BOOL hasData;

+ (PartisanIndexStats *)sharedPartisanIndexStats;

- (double) minPartisanIndexUsingChamber:(TXLChamberType)chamber;
- (double) maxPartisanIndexUsingChamber:(TXLChamberType)chamber;
- (double) overallPartisanIndexUsingChamber:(TXLChamberType)chamber;
- (double) partyPartisanIndexUsingChamber:(TXLChamberType)chamber andPartyID:(TXLPartyType)party;
- (NSArray *) historyForParty:(TXLPartyType)party chamber:(TXLChamberType)chamber;
- (NSDictionary *)partisanshipDataForLegislatorID:(NSNumber*)legislatorID;
- (NSDictionary *)partisanshipDataForLegislator:(LegislatorObj*)legislator;

- (void)didUpdatePartyPartisanship:(NSArray<PartyPartisanshipObj *> *)partyPartisanship;

@end
