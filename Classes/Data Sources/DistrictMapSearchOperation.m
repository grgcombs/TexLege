//
//  DistrictMapSearchOperation.m
//  Created by Gregory Combs on 9/1/10.
//
//  StatesLege by Sunlight Foundation, based on work at https://github.com/sunlightlabs/StatesLege
//
//  This work is licensed under the Creative Commons Attribution-NonCommercial 3.0 Unported License. 
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc/3.0/
//  or send a letter to Creative Commons, 444 Castro Street, Suite 900, Mountain View, California, 94041, USA.
//
//

#import "DistrictMapSearchOperation.h"
#import "NSInvocation+CWVariableArguments.h"
#import "TexLegeAppDelegate.h"
#import "DistrictMapObj+MapKit.h"
#import "TexLegeCoreDataUtils.h"

@interface DistrictMapSearchOperation()
- (void)informDelegateOfFailureWithMessage:(NSString *)message failOption:(DistrictMapSearchOperationFailOption)failOption;
- (void)informDelegateOfSuccess;
@end

@implementation DistrictMapSearchOperation

- (instancetype) initWithDelegate:(NSObject <DistrictMapSearchOperationDelegate> *)newDelegate
                       coordinate:(CLLocationCoordinate2D)aCoordinate searchDistricts:(NSArray *)districtIDs
{
	if ((self = [super init]))
    {
		
		if (newDelegate)
			_delegate = newDelegate;
		_searchCoordinate = aCoordinate;
		
		if (districtIDs)
			_searchIDs = [districtIDs copy];
	}
	return self;
}

- (void) dealloc
{
	self.delegate = nil;
}

- (void)informDelegateOfFailureWithMessage:(NSString *)message failOption:(DistrictMapSearchOperationFailOption)failOption;
{
    if ([self.delegate respondsToSelector:@selector(districtMapSearchOperationDidFail:errorMessage:option:)])
    {
        NSInvocation *invocation = [NSInvocation invocationWithTarget:self.delegate
                                                             selector:@selector(districtMapSearchOperationDidFail:errorMessage:option:)
                                                      retainArguments:YES, self, message, failOption];
        [invocation invokeOnMainThreadWaitUntilDone:YES];
    } 
}

- (void)informDelegateOfSuccess
{
    if ([self.delegate respondsToSelector:@selector(districtMapSearchOperationDidFinishSuccessfully:)])
    {
        [self.delegate performSelectorOnMainThread:@selector(districtMapSearchOperationDidFinishSuccessfully:)
                                   withObject:self 
                                waitUntilDone:NO];
    }
}

#pragma mark -
- (void)main 
{	
	BOOL success = NO;
	
    @autoreleasepool {

        @try
        {
            _foundIDs = [[NSMutableArray alloc] init];

            CLLocationCoordinate2D searchCoord = _searchCoordinate;

            for (NSNumber *distID in _searchIDs)
            {

                DistrictMapObj * map = [DistrictMapObj objectWithPrimaryKeyValue:distID];
                if ([map districtContainsCoordinate:searchCoord])
                {
                    if (map.districtMapID.intValue == 41
                        || map.district.intValue == 83)
                    {
                        DistrictMapObj * holeDist = [DistrictMapObj objectWithPrimaryKeyValue:@40];	// dist 84
                        if (NO == [holeDist districtContainsCoordinate:_searchCoordinate])
                        {
                            [_foundIDs addObject:distID];
                            success = YES;
                        }
                        [map.managedObjectContext refreshObject:map mergeChanges:NO];
                    }
                    else
                    {
                        [_foundIDs addObject:distID];
                        success = YES;
                    }
                }
                // this frees up memory and re-faults the unneeded objects
                [map.managedObjectContext refreshObject:map mergeChanges:NO];
            }
        }
        @catch (NSException * e)
        {
            debug_NSLog(@"Exception: %@", e);
        }
    }

	if (success)
		[self informDelegateOfSuccess];
	else
		[self informDelegateOfFailureWithMessage:@"Could not find a district map with those coordinates." failOption:DistrictMapSearchOperationFailOptionLog];
}	

@end
