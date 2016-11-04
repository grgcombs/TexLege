//
//  TexLegeReachability.m
//  Created by Gregory Combs on 9/27/10.
//
//  StatesLege by Sunlight Foundation, based on work at https://github.com/sunlightlabs/StatesLege
//
//  This work is licensed under the Creative Commons Attribution-NonCommercial 3.0 Unported License. 
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc/3.0/
//  or send a letter to Creative Commons, 444 Castro Street, Suite 900, Mountain View, California, 94041, USA.
//
//

#import "TexLegeReachability.h"
#import "UtilityMethods.h"
#import "OpenLegislativeAPIs.h"
#import "Reachability.h"
#import "TexLegeAppDelegate.h"

#define ALLOW_SLOW_DNS_LOOKUPS	0

@interface TexLegeReachability()

@property (NS_NONATOMIC_IOSONLY, assign) ReachabilityStatus remoteHostStatus;
@property (NS_NONATOMIC_IOSONLY, assign) ReachabilityStatus internetConnectionStatus;
@property (NS_NONATOMIC_IOSONLY, assign) ReachabilityStatus localWiFiConnectionStatus;
@property (NS_NONATOMIC_IOSONLY, assign) ReachabilityStatus texlegeConnectionStatus;
@property (NS_NONATOMIC_IOSONLY, assign) ReachabilityStatus openstatesConnectionStatus;
@property (NS_NONATOMIC_IOSONLY, assign) ReachabilityStatus tloConnectionStatus;
@property (NS_NONATOMIC_IOSONLY, assign) ReachabilityStatus googleConnectionStatus;

@property (NS_NONATOMIC_IOSONLY, retain) Reachability *hostReach;
@property (NS_NONATOMIC_IOSONLY, retain) Reachability *internetReach;
@property (NS_NONATOMIC_IOSONLY, retain) Reachability *wifiReach;
@property (NS_NONATOMIC_IOSONLY, retain) Reachability *openstatesReach;
@property (NS_NONATOMIC_IOSONLY, retain) Reachability *texlegeReach;
@property (NS_NONATOMIC_IOSONLY, retain) Reachability *tloReach;
@property (NS_NONATOMIC_IOSONLY, retain) Reachability *googleReach;

@end

@implementation TexLegeReachability

+ (TexLegeReachability*)sharedTexLegeReachability
{
    static TexLegeReachability *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });

    return instance;
}

#pragma mark - 
#pragma mark Reachability

/*
 Remote Host Reachable
 Not reachable | Reachable via EDGE | Reachable via WiFi
 
 Connection to Internet
 Not available | Available via EDGE | Available via WiFi
 
 Connection to Local Network.
 Not available | Available via WiFi
 */

- (void)dealloc
{
    self.delegate = nil;
    self.hostReach = nil;
    self.openstatesReach = nil;
    self.texlegeReach = nil;
    self.tloReach = nil;
    self.googleReach = nil;
    self.internetReach = nil;
    self.wifiReach = nil;

    [super dealloc];
}

- (void)startCheckingReachability:(id<TexLegeReachabilityDelegate>)delegate
{
    self.delegate = delegate;

	// Observe the kNetworkReachabilityChangedNotification. When that notification is posted, the
    // method "reachabilityChanged" will be called. 
    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(reachabilityChanged:) name: kReachabilityChangedNotification object: nil];

    if (_hostReach)
        [_hostReach release];
	_hostReach = [[Reachability reachabilityWithHostName: @"www.apple.com"] retain];
	[_hostReach startNotifier];
	[self updateStatusWithReachability: _hostReach];
	
    if (_openstatesReach)
        [_openstatesReach release];
	_openstatesReach = [[Reachability reachabilityWithHostName:osApiHost] retain];
	[_openstatesReach startNotifier];
	[self updateStatusWithReachability: _openstatesReach];

    if (_googleReach)
        [_googleReach release];
	_googleReach = [[Reachability reachabilityWithHostName:@"maps.google.com"] retain];
	[_googleReach startNotifier];
	[self updateStatusWithReachability: _googleReach];
	
    if (_texlegeReach)
        [_texlegeReach release];
	_texlegeReach = [[Reachability reachabilityWithHostName:RESTKIT_HOST] retain];
	[_texlegeReach startNotifier];
	[self updateStatusWithReachability: _texlegeReach];
	
    if (_tloReach)
        [_tloReach release];
	_tloReach = [[Reachability reachabilityWithHostName:tloApiHost] retain];
	[_tloReach startNotifier];
	[self updateStatusWithReachability: _tloReach];
	
    if (_internetReach)
        [_internetReach release];
	_internetReach = [[Reachability reachabilityForInternetConnection] retain];
	[_internetReach startNotifier];
	[self updateStatusWithReachability: _internetReach];
	
    if (_wifiReach)
        [_wifiReach release];
    _wifiReach = [[Reachability reachabilityForLocalWiFi] retain];
	[_wifiReach startNotifier];
	[self updateStatusWithReachability: _wifiReach];
}

- (void)reachabilityChanged:(NSNotification *)note
{
	Reachability* curReach = note.object;
	NSParameterAssert([curReach isKindOfClass: [Reachability class]]);
	[self updateStatusWithReachability: curReach];
}

- (void)updateStatusWithReachability:(Reachability*)curReach
{
	NetworkStatus currentStatus = [curReach currentReachabilityStatus];
	
	if (curReach == self.hostReach)
	{
        self.remoteHostStatus = (ReachabilityStatus)currentStatus;
        BOOL connectionRequired = [curReach isConnectionRequired];
		if (self.remoteHostStatus != ReachableViaWWAN)
        {
			if(connectionRequired)
            {
				NSLog(@"Cellular data network is available.\n  Internet traffic will be routed through it after a connection is established.");
            }
			else
            {
				NSLog(@"Cellular data network is active.\n  Internet traffic will be routed through it.");
            }
		}
	}
	else if (curReach == self.internetReach)
	{	
		self.internetConnectionStatus = (ReachabilityStatus)currentStatus;
	}
	else if (curReach == self.wifiReach)
	{	
		self.localWiFiConnectionStatus = (ReachabilityStatus)currentStatus;
	}
	else
    {
		if (curReach == self.googleReach)
			self.googleConnectionStatus = (ReachabilityStatus)currentStatus;
		if (curReach == self.texlegeReach)
			self.texlegeConnectionStatus = (ReachabilityStatus)currentStatus;
		if (curReach == self.openstatesReach)
			self.openstatesConnectionStatus = (ReachabilityStatus)currentStatus;
		if (curReach == self.tloReach)
			self.tloConnectionStatus = (ReachabilityStatus)currentStatus;

        if (self.delegate)
            [self.delegate reachabilityDidChange:self];
	}
}

#pragma mark -
#pragma mark Alerts and Convenience Methods

+ (BOOL)texlegeReachable
{
	return [TexLegeReachability sharedTexLegeReachability].texlegeConnectionStatus > NotReachable;
}

+ (BOOL)openstatesReachable
{
	return [TexLegeReachability sharedTexLegeReachability].openstatesConnectionStatus > NotReachable;
}

+ (void)noInternetAlert
{
	UIAlertView *noInternetAlert = [[ UIAlertView alloc ] 
									 initWithTitle:NSLocalizedStringFromTable(@"Internet Unavailable", @"AppAlerts", @"Alert title, network access is unavailable.")
									 message:NSLocalizedStringFromTable(@"This feature requires an Internet connection, and a connection is unavailable.  Your device may be in 'Airplane' mode or is suffering poor network coverage.", @"AppAlerts", @"") 
									 delegate:nil // we're static, so don't do "self"
									 cancelButtonTitle:NSLocalizedStringFromTable(@"Cancel", @"StandardUI", @"Cancelling some activity")
									 otherButtonTitles:nil];
	[ noInternetAlert show ];	
	[ noInternetAlert release ];
}

+ (void)noHostAlert
{
	UIAlertView *alert = [[ UIAlertView alloc ] 
			 initWithTitle:NSLocalizedStringFromTable(@"Host Unreachable", @"AppAlerts", @"Internet host is down")
			 message:NSLocalizedStringFromTable(@"There was a problem contacting the specified host, the URL may have changed or may contain typographical errors. Perhaps try the connection again later.", @"AppAlerts", @"")
			 delegate:nil // we're static, so don't do "self"
			 cancelButtonTitle:NSLocalizedStringFromTable(@"Cancel", @"StandardUI", @"Cancelling some activity") 
			 otherButtonTitles:nil];
	[ alert show ];	
	[ alert release ];
}

- (BOOL)isNetworkReachable
{
	BOOL reachable = YES;
	
	reachable = (self.internetConnectionStatus != NotReachable);
	
	return reachable;
}

- (BOOL)isNetworkReachableViaWiFi
{
	BOOL reachable = (self.internetConnectionStatus == ReachableViaWiFi);

	return reachable;
}

+ (BOOL)isHostReachable:(NSString *)host
{
	BOOL reachable = YES;
	
	if ([host isEqualToString:RESTKIT_HOST])
		reachable = [TexLegeReachability sharedTexLegeReachability].texlegeConnectionStatus > NotReachable;
	else if ([host isEqualToString:tloApiHost])
		reachable = [TexLegeReachability sharedTexLegeReachability].tloConnectionStatus > NotReachable;
	else if ([host isEqualToString:osApiHost])
		reachable = [TexLegeReachability sharedTexLegeReachability].openstatesConnectionStatus > NotReachable;
	else
    {
#if ALLOW_SLOW_DNS_LOOKUPS
		Reachability *curReach = [Reachability reachabilityWithHostName:host];
		if (curReach)
        {
			NetworkStatus status = [curReach currentReachabilityStatus];
			reachable = status > NotReachable;
		}
#else
		reachable = [[TexLegeReachability sharedTexLegeReachability] isNetworkReachable];
#endif
	}
	return reachable;
}

+ (BOOL)canReachHostWithURL:(NSURL *)url alert:(BOOL)doAlert
{
	BOOL reachableHost = NO;
	if (!url)
		return NO;

    if (url.fileURL)
		return YES;

    if (![[TexLegeReachability sharedTexLegeReachability] isNetworkReachable])
    {
		if (doAlert)
			[TexLegeReachability noInternetAlert];
	}
	else if ([url.scheme isEqualToString:@"twitter"] && 
			 [[UIApplication sharedApplication] canOpenURL:url])
    {
		reachableHost = YES;
	}
	else if (![TexLegeReachability isHostReachable:url.host])
    {
		if (doAlert)
			[TexLegeReachability noHostAlert];
	}
	else
    {
		reachableHost = YES;
	}
	
	return reachableHost;	
}

// throw up some appropriate errors while you're at it...
+ (BOOL) canReachHostWithURL:(NSURL *)url
{
	return [TexLegeReachability canReachHostWithURL:url alert:YES];
}

@end
