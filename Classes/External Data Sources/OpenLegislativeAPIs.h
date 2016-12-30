/*
 *  OpenLegislativeAPIs.h
 *  TexLege
 *
 *  Created by Gregory Combs on 3/18/11.
 *  Copyright 2011 Gregory S. Combs. All rights reserved.
 *
 */

#import <SLFRestKit/SLFRestKit.h>

extern NSString * const osApiHost;
extern NSString * const tloApiHost;
extern NSString * const followTheMoneyApiHost;
extern NSString * const osApiBaseURL;
extern NSString * const transApiBaseURL;
extern NSString * const vsApiBaseURL;
extern NSString * const tloApiBaseURL;
extern NSString * const followTheMoneyApiBaseURL;

@interface OpenLegislativeAPIs : NSObject <RKRequestDelegate>

+ (OpenLegislativeAPIs *)sharedOpenLegislativeAPIs;

@property (nonatomic, strong) RKClient *osApiClient;
@property (nonatomic, strong) RKClient *transApiClient;
@property (nonatomic, strong) RKClient *vsApiClient;
@property (nonatomic, strong) RKClient *tloApiClient;
@property (nonatomic, strong) RKClient *followTheMoneyApiClient;

- (void)queryOpenStatesBillWithID:(NSString *)billID session:(NSString *)session delegate:(id)sender;

@end
