//
//  BillsRecentViewController.m
//  Created by Gregory Combs on 3/14/11.
//
//  StatesLege by Sunlight Foundation, based on work at https://github.com/sunlightlabs/StatesLege
//
//  This work is licensed under the Creative Commons Attribution-NonCommercial 3.0 Unported License. 
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc/3.0/
//  or send a letter to Creative Commons, 444 Castro Street, Suite 900, Mountain View, California, 94041, USA.
//
//

#import "BillsRecentViewController.h"
#import "OpenLegislativeAPIs.h"
#import "UtilityMethods.h"
#import "BillSearchDataSource.h"
#import "NSDate+Helper.h"
#import "StateMetaLoader.h"
#import "TexLegeTheme.h"

@implementation BillsRecentViewController

#pragma mark -
#pragma mark View lifecycle

- (instancetype)initWithStyle:(UITableViewStyle)style {
	if ((self = [super initWithStyle:style])) {
		self.dataSource.useLoadingDataCell = YES;
	}
	return self;
}


- (void)viewDidLoad {
	[super viewDidLoad];
	
	NSString *thePath = [[NSBundle mainBundle]  pathForResource:@"TexLegeStrings" ofType:@"plist"];
	NSDictionary *textDict = [NSDictionary dictionaryWithContentsOfFile:thePath];
	NSString *myClass = NSStringFromClass([self class]);
	NSDictionary *menuItem = [textDict[@"BillMenuItems"] findWhereKeyPath:@"class" equals:myClass];
	
	if (menuItem)
		self.title = menuItem[@"title"];	
}

- (void)viewDidUnload {
	[super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	self.navigationController.navigationBar.tintColor = [TexLegeTheme navbar];

	StateMetaLoader *meta = [StateMetaLoader instance];
	if (IsEmpty(meta.selectedState))
		return;
	
	NSDate *daysAgo = [[NSDate date] dateByAddingDays:-5];
	if (!daysAgo) {
		// we had issues calculating last week's date, so just do it by hand
		daysAgo = [[NSDate alloc] initWithTimeIntervalSinceNow:-(60*60*24*5)];	
	}
	NSString *dateString = [daysAgo stringWithFormat:[NSDate dateFormatString]];
	
	NSDictionary *queryParams = @{@"updated_since": dateString,
								 @"state": meta.selectedState,
								 @"apikey": SUNLIGHT_APIKEY};
	
	[self.dataSource startSearchWithQueryString:@"/bills" params:queryParams];
}

@end
