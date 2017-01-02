//
//  StateMetadataLoader.h
//  Created by Gregory Combs on 6/10/11.
//
//  StatesLege by Sunlight Foundation, based on work at https://github.com/sunlightlabs/StatesLege
//
//  This work is licensed under the Creative Commons Attribution-NonCommercial 3.0 Unported License. 
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc/3.0/
//  or send a letter to Creative Commons, 444 Castro Street, Suite 900, Mountain View, California, 94041, USA.
//
//

#import <Foundation/Foundation.h>
#import <SLFRestKit/SLFRestKit.h>

#define kStateMetaFile				@"StateMetadata.json"
#define kStateMetaPath				@"StateMetadata"
#define kStateMetaNotifyError		@"STATE_METADATA_ERROR"
#define kStateMetaNotifyLoaded		@"STATE_METADATA_LOADED"


@interface StateMetaLoader : NSObject <RKRequestDelegate>

+ (id)sharedStateMeta;	// Singleton

// Oftentimes, we just need a quick and dirty answer from our singleton
+ (NSString *)nameForChamber:(NSInteger)chamber;

- (void)loadMetadataForState:(NSString *)stateID;

@property (NS_NONATOMIC_IOSONLY,getter=isFresh) BOOL fresh;
@property (NS_NONATOMIC_IOSONLY,copy) NSDate *updated;
@property (NS_NONATOMIC_IOSONLY,copy) NSString *selectedState;
@property (NS_NONATOMIC_IOSONLY,copy) NSString *currentSession;
@property (NS_NONATOMIC_IOSONLY,copy,readonly) NSDictionary *stateMetadata;
@property (NS_NONATOMIC_IOSONLY,copy,readonly) NSArray *loadingStates;

@end

#define kMetaSelectedStateKey		@"selected_state"

#define kMetaLowerChamberNameKey @"lower_chamber_name"			// House of Representatives
#define kMetaUpperChamberNameKey @"upper_chamber_name"			// Senate
#define kMetaLowerChamberTitleKey @"lower_chamber_title"		// Representative
#define kMetaUpperChamberTitleKey @"upper_chamber_title"		// Senator
#define kMetaSessionsKey @"session_details"						// "811":{"type": "special","start_date": "2009-07-01 00:00:00", "end_date": "2009-07-10 00:00:00"}
#define kMetaSessionsAltKey @"terms"		
#define kMetaStateAbbrevKey @"abbreviation"						// tx
#define kMetaStateNameKey @"name"								// Texas
#define kMetaLowerChamberElectionTermKey @"lower_chamber_term"	// 2	[years/integer]
#define kMetaUpperChamberElectionTermKey @"upper_chamber_term"	// 4	[years/integer] 
