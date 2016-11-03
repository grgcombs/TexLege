//
//  RKReachabilityObserver.h
//  RestKit
//
//  Created by Blake Watters on 9/14/10.
//  Copyright 2010 RestKit. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SystemConfiguration/SystemConfiguration.h>

/**
 * Posted when the network state has changed
 */
extern NSString* const RKReachabilityStateChangedNotification;

typedef NS_ENUM(unsigned int, RKReachabilityNetworkStatus) {
	RKReachabilityIndeterminate,
	RKReachabilityNotReachable,
	RKReachabilityReachableViaWiFi,
	RKReachabilityReachableViaWWAN
};

/**
 * Provides a notification based interface for monitoring changes
 * to network status8
 *
 * Portions of this software are derived from the Apple Reachability
 * code sample: http://developer.apple.com/library/ios/#samplecode/Reachability/Listings/Classes_Reachability_m.html
 */
@interface RKReachabilityObserver : NSObject {
	SCNetworkReachabilityRef _reachabilityRef;	
}

/**
 * Create a new reachability observer against a given hostname. The observer
 * will monitor the ability to reach the specified hostname and emit notifications
 * when its reachability status changes. 
 *
 * Note that the observer will be scheduled in the current run loop.
 */
+ (RKReachabilityObserver*)reachabilityObserverWithHostName:(NSString*)hostName;

/**
 * Returns the current network status
 */
@property (NS_NONATOMIC_IOSONLY, readonly) RKReachabilityNetworkStatus networkStatus;

/**
 * Returns YES when the Internet is reachable (via WiFi or WWAN)
 */
@property (NS_NONATOMIC_IOSONLY, getter=isNetworkReachable, readonly) BOOL networkReachable;

/**
 * Returns YES when WWAN may be available, but not active until a connection has been established.
 */
@property (NS_NONATOMIC_IOSONLY, getter=isConnectionRequired, readonly) BOOL connectionRequired;

@end
