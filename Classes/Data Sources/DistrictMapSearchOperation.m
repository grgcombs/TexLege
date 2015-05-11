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
@synthesize delegate;
@synthesize searchCoordinate, searchIDs, foundIDs;

- (id) initWithDelegate:(NSObject <DistrictMapSearchOperationDelegate> *)newDelegate 
			 coordinate:(CLLocationCoordinate2D)aCoordinate searchDistricts:(NSArray *)districtIDs {
	if ((self = [super init])) {
		
		if (newDelegate)
			delegate = newDelegate;
		searchCoordinate = aCoordinate;
		
		if (districtIDs)
			searchIDs = [districtIDs retain];
	}
	return self;
}

- (void) dealloc {
	self.foundIDs = nil;
	self.searchIDs = nil;
	delegate = nil;
	[super dealloc];
}

- (void)informDelegateOfFailureWithMessage:(NSString *)message failOption:(DistrictMapSearchOperationFailOption)failOption;
{
    if ([delegate respondsToSelector:@selector(districtMapSearchOperationDidFail:errorMessage:option:)])
    {
        NSInvocation *invocation = [NSInvocation invocationWithTarget:delegate 
                                                             selector:@selector(districtMapSearchOperationDidFail:errorMessage:option:)
                                                      retainArguments:YES, self, message, failOption];
        [invocation invokeOnMainThreadWaitUntilDone:YES];
    } 
}

- (void)informDelegateOfSuccess
{
    if ([delegate respondsToSelector:@selector(districtMapSearchOperationDidFinishSuccessfully:)])
    {
        [delegate performSelectorOnMainThread:@selector(districtMapSearchOperationDidFinishSuccessfully:) 
                                   withObject:self 
                                waitUntilDone:NO];
    }
}

#pragma mark -
- (void)main 
{	
	BOOL success = NO;
	
    @try 
    {		
        // Operation task here
		
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		
		if (foundIDs)
			[foundIDs release];
		foundIDs = [[NSMutableArray alloc] init];
					
		for (NSNumber *distID in searchIDs) {

			DistrictMapObj * map = [DistrictMapObj objectWithPrimaryKeyValue:distID];
			if ([map districtContainsCoordinate:[self searchCoordinate]]) {

				if ([map.districtMapID integerValue] == 41 || [map.district integerValue] == 83) {
					DistrictMapObj * holeDist = [DistrictMapObj objectWithPrimaryKeyValue:[NSNumber numberWithInt:40]];	// dist 84
					if (NO == [holeDist districtContainsCoordinate:[self searchCoordinate]]) {
						[foundIDs addObject:distID];
						success = YES;
					}
					[[holeDist managedObjectContext] refreshObject:map mergeChanges:NO];
				}
				else {
					[foundIDs addObject:distID];
					success = YES;
				}
			}
			// this frees up memory and re-faults the unneeded objects
			[[map managedObjectContext] refreshObject:map mergeChanges:NO];
		}
		[pool drain];
    }
    @catch (NSException * e) 
    {
        debug_NSLog(@"Exception: %@", e);
    }
	
	if (success)
		[self informDelegateOfSuccess];
	else
		[self informDelegateOfFailureWithMessage:@"Could not find a district map with those coordinates." failOption:DistrictMapSearchOperationFailOptionLog];
	
}
	

@end
