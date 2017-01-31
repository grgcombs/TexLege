//
//  TexLegeLibrary.h
//  Created by Gregory Combs on 2/4/11.
//
//  StatesLege by Sunlight Foundation, based on work at https://github.com/sunlightlabs/StatesLege
//
//  This work is licensed under the Creative Commons Attribution-NonCommercial 3.0 Unported License. 
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc/3.0/
//  or send a letter to Creative Commons, 444 Castro Street, Suite 900, Mountain View, California, 94041, USA.
//
//

#import "TexLege.h"

#define OPENAPIS_DEFAULT_SESSION		@"85"
#define WNOM_DEFAULT_LATEST_SESSION		84

typedef NS_ENUM(UInt8, TXLChamberType) {
    BOTH_CHAMBERS = 0,
    HOUSE,
    SENATE,
    JOINT,
    EXECUTIVE	// Used in open states / bill actions
};

typedef NS_ENUM(UInt8, TXLPartyType) {
    BOTH_PARTIES = 0,
    DEMOCRAT,
    REPUBLICAN
};

typedef NS_ENUM(UInt8, TXLCommitteePositionType) {
    POS_MEMBER = 0,
    POS_VICE,
    POS_CHAIR
};

typedef NS_ENUM(UInt8, TLStringReturnType) {
    TLReturnFull = 0,		// Return the full string
    TLReturnAbbrev,			// Return an abbreviation
    TLReturnInitial,		// Return an initial
	TLReturnOpenStates,
	TLReturnAbbrevPlural,	// Like "Dems", "Repubs", etc.
	TLReturnTitle			// Return a member title like Senator or Representative
};

typedef NS_ENUM(UInt8, TexLegeBillStages) {
    BillStageUnknown = 0,
    BillStageFiled,
    BillStageOutOfCommittee,
    BillStageChamberVoted,
    BillStageOutOfOpposingCommittee,
    BillStageOpposingChamberVoted,
    BillStageSentToGovernor,
    BillStageBecomesLaw,
    BillStageVetoed = -1
};
										/*
										 1. Filed
										 2. Out of (current chamber) Committee
										 3. Voted on by (current chamber)
										 4. Out of (opposing chamber) Committee
										 5. Voted on by (opposing chamber)
										 6. Submitted to Governor
										 7. Bill Becomes Law
										 */

NSString *stringInitial(NSString *inString, BOOL parens);
NSString *abbreviateString(NSString *inString);

TXLChamberType chamberFromOpenStatesString(NSString *chamberString);
NSString *stringForChamber(TXLChamberType chamber, TLStringReturnType type);
NSString *stringForParty(NSInteger party, TLStringReturnType type);
NSString *billTypeStringFromBillID(NSString *billID);
BOOL billTypeRequiresGovernor(NSString *billType);
BOOL billTypeRequiresOpposingChamber(NSString *billType);
NSString * watchIDForBill(NSDictionary *aBill);

