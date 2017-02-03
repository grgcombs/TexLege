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
#import "TexLegeLibrary.h"

#define kStateMetaFile				@"StateMetadata.json"
#define kStateMetaPath				@"StateMetadata"
#define kStateMetaNotifyError		@"STATE_METADATA_ERROR"
#define kStateMetaNotifyLoaded		@"STATE_METADATA_LOADED"


@interface StateMetaLoader : NSObject <RKRequestDelegate>

+ (instancetype)instance;	// Singleton

// Oftentimes, we just need a quick and dirty answer from our singleton
+ (NSString *)nameForChamber:(TXLChamberType)chamber;

- (void)loadMetadataForState:(NSString *)stateID;

@property (NS_NONATOMIC_IOSONLY,getter=isFresh) BOOL fresh;
@property (NS_NONATOMIC_IOSONLY,copy) NSDate *updated;
@property (NS_NONATOMIC_IOSONLY,copy) NSString *selectedState;
@property (NS_NONATOMIC_IOSONLY,copy) NSString *currentSession;
@property (NS_NONATOMIC_IOSONLY,copy,readonly) NSDictionary *stateMetadata;
@property (NS_NONATOMIC_IOSONLY,copy,readonly) NSArray *loadingStates;
- (NSArray<NSDictionary *> *)sortedTerms;

@end

struct StateMetadataChamberDetailKeys {
    __unsafe_unretained NSString *metaLookup;
    __unsafe_unretained NSString *name;
    __unsafe_unretained NSString *title;
    __unsafe_unretained NSString *termLength;
};

struct StateMetadataChamberKeys {
    __unsafe_unretained NSString *metaLookup;
    const struct StateMetadataChamberDetailKeys upper;
    const struct StateMetadataChamberDetailKeys lower;
};

struct StateMetadataSessionDetailKeys {
    __unsafe_unretained NSString *metaLookup;
    __unsafe_unretained NSString *name;
    __unsafe_unretained NSString *type;
    __unsafe_unretained NSString *startDate;
    __unsafe_unretained NSString *endDate;
};

struct StateMetadataTermKeys {
    __unsafe_unretained NSString *metaLookup;
    __unsafe_unretained NSString *name;
    __unsafe_unretained NSString *sessions;
    __unsafe_unretained NSString *startYear;
    __unsafe_unretained NSString *endYear;
};

struct StateMetadataFeatureKeys {
    __unsafe_unretained NSString *metaLookup;
    __unsafe_unretained NSString *events;
    __unsafe_unretained NSString *subjects;
};

extern const struct StateMetadataSessionTypeKeys {
    __unsafe_unretained NSString *primary;
    __unsafe_unretained NSString *special;
} StateMetadataSessionTypeKeys;

extern const struct StateMetadataKeys {
    __unsafe_unretained NSString * selectedState;
    __unsafe_unretained NSString * abbreviation;
    __unsafe_unretained NSString * name;
    __unsafe_unretained NSString * timezone;
    const struct StateMetadataChamberKeys chambers;
    const struct StateMetadataFeatureKeys features;
    const struct StateMetadataTermKeys terms;
    const struct StateMetadataSessionDetailKeys sessionDetails;
} StateMetadataKeys;
