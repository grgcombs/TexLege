//
//  OpenLegislativeAPIs.m
//  Created by Gregory Combs on 3/21/11.
//
//  StatesLege by Sunlight Foundation, based on work at https://github.com/sunlightlabs/StatesLege
//
//  This work is licensed under the Creative Commons Attribution-NonCommercial 3.0 Unported License. 
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc/3.0/
//  or send a letter to Creative Commons, 444 Castro Street, Suite 900, Mountain View, California, 94041, USA.
//
//

#import "OpenLegislativeAPIs.h"
#import "UtilityMethods.h"
#import "NSDate+Helper.h"
#import "StateMetaLoader.h"


NSString * const osApiHost = @"openstates.org";
NSString * const osApiBaseURL = @"http://openstates.org/api/v1";
NSString * const transApiBaseURL = @"http://transparencydata.com/api/1.0";
NSString * const vsApiBaseURL = @"http://api.votesmart.org";
NSString * const tloApiHost = @"www.legis.state.tx.us";
NSString * const tloApiBaseURL = @"http://www.legis.state.tx.us";
NSString * const followTheMoneyApiHost = @"api.followthemoney.org";
NSString * const followTheMoneyApiBaseURL = @"http://api.followthemoney.org";

@implementation OpenLegislativeAPIs

+ (OpenLegislativeAPIs*)sharedOpenLegislativeAPIs
{
	static dispatch_once_t pred;
	static OpenLegislativeAPIs *foo = nil;
	
	dispatch_once(&pred, ^{ foo = [[self alloc] init]; });
	return foo;
}


- (instancetype)init
{
	if ((self=[super init]))
    {
		_osApiClient = [RKClient clientWithBaseURL:[NSURL URLWithString:osApiBaseURL]];
        _transApiClient = [RKClient clientWithBaseURL: [NSURL URLWithString:transApiBaseURL]];
		_vsApiClient = [RKClient clientWithBaseURL:[NSURL URLWithString:vsApiBaseURL]];
		_tloApiClient = [RKClient clientWithBaseURL:[NSURL URLWithString:tloApiBaseURL]];
        _followTheMoneyApiClient = [RKClient clientWithBaseURL:[NSURL URLWithString:followTheMoneyApiBaseURL]];
	}
	return self;
}

- (void)dealloc
{
    [[_osApiClient requestQueue] cancelRequestsWithDelegate:self];
    [[_transApiClient requestQueue] cancelRequestsWithDelegate:self];
    [[_vsApiClient requestQueue] cancelRequestsWithDelegate:self];
    [[_tloApiClient requestQueue] cancelRequestsWithDelegate:self];
    [[_followTheMoneyApiClient requestQueue] cancelRequestsWithDelegate:self];
	[[[RKClient sharedClient] requestQueue] cancelRequestsWithDelegate:self];
}

- (void)queryOpenStatesBillWithID:(NSString *)billID session:(NSString *)session delegate:(id)sender {
	StateMetaLoader *meta = [StateMetaLoader instance];

	if (!session && !IsEmpty(meta.currentSession)) {
		session = meta.currentSession;
	}
	
	if (IsEmpty(billID) || IsEmpty(session) || !sender || !self.osApiClient)
		return;
	NSDictionary *queryParams = @{@"apikey": SUNLIGHT_APIKEY};
	NSString *queryString = [NSString stringWithFormat:@"/bills/%@/%@/%@", meta.selectedState, session, [billID stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
	[self.osApiClient get:queryString queryParams:queryParams delegate:sender];
}

@end
