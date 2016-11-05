//
//  TexLegeReachability.h
//  Created by Gregory Combs on 9/27/10.
//
//  StatesLege by Sunlight Foundation, based on work at https://github.com/sunlightlabs/StatesLege
//
//  This work is licensed under the Creative Commons Attribution-NonCommercial 3.0 Unported License. 
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc/3.0/
//  or send a letter to Creative Commons, 444 Castro Street, Suite 900, Mountain View, California, 94041, USA.
//
//

#import <Foundation/Foundation.h>
#import "Reachability.h"

@class TexLegeReachability;

@protocol TexLegeReachabilityDelegate <NSObject>
- (void)reachabilityDidChange:(TexLegeReachability *)reachability;
@end

@interface TexLegeReachability : NSObject

@property (NS_NONATOMIC_IOSONLY, readonly) ReachabilityStatus remoteHostStatus;
@property (NS_NONATOMIC_IOSONLY, readonly) ReachabilityStatus internetConnectionStatus;
@property (NS_NONATOMIC_IOSONLY, readonly) ReachabilityStatus localWiFiConnectionStatus;
@property (NS_NONATOMIC_IOSONLY, readonly) ReachabilityStatus texlegeConnectionStatus;
@property (NS_NONATOMIC_IOSONLY, readonly) ReachabilityStatus openstatesConnectionStatus;
@property (NS_NONATOMIC_IOSONLY, readonly) ReachabilityStatus tloConnectionStatus;
@property (NS_NONATOMIC_IOSONLY, readonly) ReachabilityStatus googleConnectionStatus;
@property (NS_NONATOMIC_IOSONLY, weak) id<TexLegeReachabilityDelegate> delegate;
@property (NS_NONATOMIC_IOSONLY, getter=isNetworkReachable, readonly) BOOL networkReachable;
@property (NS_NONATOMIC_IOSONLY, getter=isNetworkReachableViaWiFi, readonly) BOOL networkReachableViaWiFi;

- (void)startCheckingReachability:(id<TexLegeReachabilityDelegate>)delegate;

+ (TexLegeReachability *)sharedTexLegeReachability;
+ (BOOL)texlegeReachable;
+ (BOOL)openstatesReachable;

+ (BOOL) canReachHostWithURL:(NSURL *)url alert:(BOOL)doAlert;
+ (BOOL) canReachHostWithURL:(NSURL *)url;
+ (void) noInternetAlert;
+ (void) noHostAlert;
@end
