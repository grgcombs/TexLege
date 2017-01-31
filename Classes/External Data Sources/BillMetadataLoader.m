//
//  BillMetadataLoader.m
//  Created by Gregory Combs on 3/16/11.
//
//  StatesLege by Sunlight Foundation, based on work at https://github.com/sunlightlabs/StatesLege
//
//  This work is licensed under the Creative Commons Attribution-NonCommercial 3.0 Unported License. 
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc/3.0/
//  or send a letter to Creative Commons, 444 Castro Street, Suite 900, Mountain View, California, 94041, USA.
//
//

#import "BillMetadataLoader.h"
#import "UtilityMethods.h"
#import "TexLegeReachability.h"
#import "OpenLegislativeAPIs.h"

NSString * const BillMetadataFile = @"BillMetadata.json";

@interface BillMetadataLoader()
@property (nonatomic,copy) NSDictionary *metadata;
@property (nonatomic,copy) NSDate *updated;
@property (nonatomic,getter=isFresh) BOOL fresh;
@property (nonatomic,getter=isLoading) BOOL loading;
@end

@implementation BillMetadataLoader

+ (BillMetadataLoader*)sharedBillMetadataLoader
{
	static dispatch_once_t pred;
	static BillMetadataLoader *foo = nil;
	
	dispatch_once(&pred, ^{ foo = [[self alloc] init]; });
	return foo;
}

- (instancetype)init
{
	if ((self=[super init]))
    {
		_loading = NO;
		_fresh = NO;
		_updated = nil;
		_metadata = nil;
	}
	return self;
}

- (void)dealloc
{
	[[RKClient sharedClient].requestQueue cancelRequestsWithDelegate:self];
}

- (void)loadMetadata:(id)sender {

	if (self.isLoading)	// we're already working on it
		return;
	
	self.fresh = NO;

	debug_NSLog(@"BillMetaData is stale, refreshing");

	if ([TexLegeReachability texlegeReachable]) {
		
		self.loading = YES;
		
		[[RKClient sharedClient] get:[NSString stringWithFormat:@"/%@", BillMetadataFile] delegate:self];
	}
	else {
		[self request:nil didFailLoadWithError:nil];
	}
}

- (NSDictionary *)metadata
{
	if (!_metadata || !self.isFresh || !self.updated || ([[NSDate date] timeIntervalSinceDate:self.updated] > (3600*24)))
    {	// if we're over a day old, let's refresh
		self.fresh = NO;
		
		[self loadMetadata:nil];
	}
	
	return _metadata;
}

- (void)request:(RKRequest*)request didFailLoadWithError:(NSError*)error
{
	self.loading = NO;
	
	if (error && request) {
		debug_NSLog(@"Error loading bill metadata from %@: %@", [request description], [error localizedDescription]);
		[[NSNotificationCenter defaultCenter] postNotificationName:kBillMetadataNotifyError object:nil];
	}

	// We had trouble loading the metadata online, so pull it up from the one in the documents folder (or the app bundle)
	NSError *newError = nil;
	NSString *localPath = [[UtilityMethods applicationCachesDirectory] stringByAppendingPathComponent:BillMetadataFile];
	NSFileManager *fileManager = [NSFileManager defaultManager];
	if ([fileManager fileExistsAtPath:localPath])
    {
        debug_NSLog(@"BillMetadata: using cached metadata in the documents folder.");
    }
    else
    {
        NSString *fileComponent = localPath.lastPathComponent;
        NSString *extension = [fileComponent pathExtension];
        NSString *fileName = [fileComponent stringByDeletingPathExtension];
		NSString *defaultPath = [[NSBundle mainBundle] pathForResource:fileName ofType:extension];
        if (defaultPath)
        {
            [fileManager copyItemAtPath:defaultPath toPath:localPath error:&newError];
            if (newError)
            {
                NSLog(@"BillMetadata: Error copying metadata from the app bundle's original: %@", newError);
            }
            else
            {
                debug_NSLog(@"BillMetadata: copied metadata from the app bundle's original.");
            }
        }
	}

	NSData *jsonData = [NSData dataWithContentsOfFile:localPath];
    self.metadata = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&newError];
    if (newError)
    {
        NSLog(@"BillMetadata: Error parsing BillMetadata from %@: %@", localPath, newError);
    }
	if (self.metadata) {
		[[NSNotificationCenter defaultCenter] postNotificationName:kBillMetadataNotifyLoaded object:nil];
	}
}

- (void)request:(RKRequest*)request didLoadResponse:(RKResponse*)response {  
	
	self.loading = NO;

	if ([request isGET] && [response isOK]) {  
		// Success! Let's take a look at the data
        self.metadata = nil;

        NSError *error = nil;
        self.metadata = [NSJSONSerialization JSONObjectWithData:response.body options:NSJSONReadingMutableLeaves | NSJSONReadingMutableContainers error:&error];

		if (self.metadata) {
			self.updated = [NSDate date];
			
			NSString *localPath = [[UtilityMethods applicationCachesDirectory] stringByAppendingPathComponent:BillMetadataFile];

            NSData *jsonData = [NSJSONSerialization dataWithJSONObject:_metadata options:NSJSONWritingPrettyPrinted error:&error];
			if (![jsonData writeToFile:localPath atomically:YES])
				NSLog(@"BillMetadataLoader: error writing cache to file: %@", localPath);
			self.fresh = YES;
			[[NSNotificationCenter defaultCenter] postNotificationName:kBillMetadataNotifyLoaded object:nil];
			debug_NSLog(@"BillMetadata network download successful, archiving for others.");
		}		
		else {
			[self request:request didFailLoadWithError:nil];
			return;
		}
	}
}		

@end
