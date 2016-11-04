//
//  TexLegeAppDelegate.m
//  Created by Gregory Combs on 7/22/09.
//
//  StatesLege by Sunlight Foundation, based on work at https://github.com/sunlightlabs/StatesLege
//
//  This work is licensed under the Creative Commons Attribution-NonCommercial 3.0 Unported License. 
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc/3.0/
//  or send a letter to Creative Commons, 444 Castro Street, Suite 900, Mountain View, California, 94041, USA.
//
//

#import <RestKit/RestKit.h>

#import "TexLegeAppDelegate.h"
#import "TexLegeCoreDataUtils.h"
#import "UtilityMethods.h"
#import "PartisanIndexStats.h"

#import "TexLegeReachability.h"
#import "TexLegeTheme.h"

#import "GeneralTableViewController.h"
#import "TableDataSourceProtocol.h"

#import "AnalyticsOptInAlertController.h"
#import "LocalyticsSession.h"

#import "LegislatorObj.h"
#import "DistrictMapObj.h"
#import "DataModelUpdateManager.h"
#import "BillMetadataLoader.h"
#import "CalendarEventsLoader.h"

#import "StateMetaLoader.h"

@interface TexLegeAppDelegate ()

- (void)runOnEveryAppStart;
- (void)runOnAppQuit;
- (void)restoreArchivableSavedTableSelection;
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSData *archivableSavedTableSelection;
- (void)resetSavedTableSelection:(id)sender;
@property (NS_NONATOMIC_IOSONLY, getter=isDatabaseResetNeeded, readonly) BOOL databaseResetNeeded;

@property (nonatomic,retain) DataModelUpdateManager *dataUpdater;
@property (nonatomic,copy) NSMutableDictionary *savedTableSelection;
@property (nonatomic,getter=isAppQuitting,assign) BOOL appQuitting;
@property (nonatomic,retain) AnalyticsOptInAlertController *analyticsOptInController;

@end

// user default dictionary keys
NSString * const kSavedTabOrderKey = @"SavedTabOrderVersion2";
NSString * const kRestoreSelectionKey = @"RestoreSelection";
NSString * const kAnalyticsAskedForOptInKey = @"HasAskedForOptIn";
NSString * const kAnalyticsSettingsSwitch = @"PermitUseOfAnalytics";
NSString * const kShowedSplashScreenKey = @"HasShownSplashScreen";
NSString * const kSegmentControlPrefKey = @"SegmentControlPrefs";
NSString * const kResetSavedDatabaseKey = @"ResetSavedDatabase";
NSString * const kSupportEmailKey = @"supportEmail";

NSUInteger kNumMaxTabs = 11;
NSInteger kNoSelection = -1;

@implementation TexLegeAppDelegate
@synthesize window = _window;

+ (TexLegeAppDelegate *)appDelegate
{
	return (TexLegeAppDelegate *)[UIApplication sharedApplication].delegate;
}

- (UIWindow *)mainWindow
{
    return self.window;
}

- (instancetype)init
{
	if ((self = [super init]))
    {
		// initialize  to nil
		_appQuitting = NO;
		_savedTableSelection = [[NSMutableDictionary alloc] init];
		_dataUpdater = [[DataModelUpdateManager alloc] init];
		_analyticsOptInController = nil;
    }
	return self;
}

- (void)dealloc
{
    self.analyticsOptInController = nil;
	
	self.savedTableSelection = nil;
	self.tabBarController = nil;

	self.capitolMapsMasterVC = nil;
	self.linksMasterVC = nil; 
	self.calendarMasterVC = nil;
	self.legislatorMasterVC = nil;
	self.committeeMasterVC = nil;
	self.districtMapMasterVC = nil;
	self.billsMasterVC = nil;

	self.dataUpdater = nil;
    [super dealloc];
}

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application
{
	[[LocalyticsSession sharedLocalyticsSession] tagEvent:@"LOW_MEMORY_WARNING"];
}


#pragma mark -
#pragma mark Data Sources and Main View Controllers

////// IPAD ONLY
- (UISplitViewController *) splitViewController
{
	if ([UtilityMethods isIPadDevice])
    {
		if (![self.tabBarController.selectedViewController isKindOfClass:[UISplitViewController class]])
        {
			debug_NSLog(@"Unexpected navigation controller class in tab bar controller hierarchy, check nib.");
			return nil;
		}
		return (UISplitViewController *)self.tabBarController.selectedViewController;
	}
	return nil;
}


- (UINavigationController *) masterNavigationController
{
	if ([UtilityMethods isIPadDevice])
    {
		UISplitViewController *split = self.splitViewController;
		if (split && split.viewControllers && (split.viewControllers).count)
			return (split.viewControllers)[0];
	}
	else
    {
		if (![self.tabBarController.selectedViewController isKindOfClass:[UINavigationController class]])
        {
			debug_NSLog(@"Unexpected view/navigation controller class in tab bar controller hierarchy, check nib.");
		}
		
		UINavigationController *nav = (UINavigationController *)self.tabBarController.selectedViewController;
		return nav;
	}
	return nil;
}

- (UINavigationController *) detailNavigationController
{
	if ([UtilityMethods isIPadDevice])
    {
		UISplitViewController *split = self.splitViewController;
		if (split && split.viewControllers && (split.viewControllers).count>1)
			return (split.viewControllers)[1];
	}
	else
		return self.masterNavigationController;
	
	return nil;
}

/* Probably works, but ugly and we don't need it.
- (UIViewController *) currentDetailViewController {	
	UINavigationController *nav = [self detailNavigationController];
	NSInteger numVCs = 0;
	if (nav && nav.viewControllers) {
		numVCs = [nav.viewControllers count];
		if ([UtilityMethods isIPadDevice])
			return numVCs ? [nav.viewControllers objectAtIndex:0] : nil;
		else if (numVCs >= 2)	// we're on an iPhone
			return [nav.viewControllers objectAtIndex:1];		// this will give us the second vc in the chain, typicaly a detail vc
	}

	return nil;
}
*/

- (UIViewController *)currentMasterViewController
{
	UINavigationController *nav = self.masterNavigationController;
	if (nav && nav.viewControllers && (nav.viewControllers).count)
		return (nav.viewControllers)[0];
	return nil;
}

- (BOOL)tabBarController:(UITabBarController *)tbc shouldSelectViewController:(UIViewController *)viewController
{
	if (!viewController.tabBarItem.enabled)
		return NO;
	
	if (/*![UtilityMethods isIPadDevice]*/1) {
		if (![viewController isEqual:tbc.selectedViewController]) {
			//debug_NSLog(@"About to switch tabs, popping to root view controller.");
			UINavigationController *nav = self.detailNavigationController;
			if (nav && (nav.viewControllers).count>1)
				[nav popToRootViewControllerAnimated:YES];
		}
	}
	
	return YES;
}

- (void)tabBarController:(UITabBarController *)theTabBarController didSelectViewController:(UIViewController *)viewController {
    if (viewController == theTabBarController.moreNavigationController)
    {
        theTabBarController.moreNavigationController.delegate = self;
    }
	else {
		NSString *vcTitle = nil;
		id masterVC = self.currentMasterViewController;
		if (masterVC)
			vcTitle = NSStringFromClass([masterVC class]);
		if (!vcTitle)
			vcTitle = viewController.tabBarItem.title;
		
		NSDictionary *tabSelectionDict = @{@"Feature": vcTitle};
		[[LocalyticsSession sharedLocalyticsSession] tagEvent:@"SELECTTAB" attributes:tabSelectionDict];		
	}

	[[NSUserDefaults standardUserDefaults] setObject:[self archivableSavedTableSelection] forKey:kRestoreSelectionKey];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    if (navigationController == self.tabBarController.moreNavigationController)
    {
		NSString *vcTitle = NSStringFromClass([viewController class]);
		if (NO == [vcTitle hasPrefix:@"UIMore"]) {		
			NSDictionary *tabSelectionDict = @{@"Feature": vcTitle};
			[[LocalyticsSession sharedLocalyticsSession] tagEvent:@"SELECTTAB" attributes:tabSelectionDict];
		}
    }
}

- (void)setTabOrderIfSaved {
	[[NSUserDefaults standardUserDefaults] synchronize];	

	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSArray *savedOrder = [defaults arrayForKey:kSavedTabOrderKey];
	NSMutableArray *orderedTabs = [NSMutableArray arrayWithCapacity:(self.tabBarController.viewControllers).count];
	NSInteger foundVCs = 0;
	if (savedOrder && savedOrder.count > 0 )
    {
		for (NSInteger i = 0; i < savedOrder.count; i++)
        {
			for (UIViewController *aController in self.tabBarController.viewControllers)
            {
				if ([aController.tabBarItem.title isEqualToString:savedOrder[i]])
                {
					[orderedTabs addObject:aController];
					foundVCs++;
				}
			}
		}
		if (foundVCs < (self.tabBarController.viewControllers).count) // we've got more now than we used to
			[defaults removeObjectForKey:kSavedTabOrderKey];
		else
			self.tabBarController.viewControllers = orderedTabs;
	}
}

- (void) setupViewControllerHierarchy
{
	NSArray *nibObjects = nil;
	if ([UtilityMethods isIPadDevice]) 
		nibObjects = [[NSBundle mainBundle] loadNibNamed:@"iPadTabBarController" owner:self options:nil];
	else
		nibObjects = [[NSBundle mainBundle] loadNibNamed:@"iPhoneTabBarController" owner:self options:nil];
	
	if (IsEmpty(nibObjects))
    {
		debug_NSLog(@"Error loading user interface NIB components! Can't find the nib file and can't continue this charade.");
		exit(0);
	}
	
	NSArray *VCs = [[NSArray alloc] initWithObjects:self.legislatorMasterVC, self.committeeMasterVC, self.districtMapMasterVC,
					self.calendarMasterVC, self.billsMasterVC, self.capitolMapsMasterVC, self.linksMasterVC, nil];
	
	NSString * tempVCKey = (self.savedTableSelection)[@"viewController"];
	NSInteger savedTabSelectionIndex = -1;
	NSInteger loopIndex = 0;
	for (GeneralTableViewController *masterVC in VCs)
    {
		[masterVC configure];
		
		// If we have a preferred VC and we've found it in our array, save it
		if (savedTabSelectionIndex < 0 && tempVCKey && [tempVCKey isEqualToString:NSStringFromClass([masterVC class])]) // we have a saved view controller in mind
			savedTabSelectionIndex = loopIndex;
		loopIndex++;
	}
	if (savedTabSelectionIndex < 0 || savedTabSelectionIndex > VCs.count)
		savedTabSelectionIndex = 0;
	
	if ([UtilityMethods isIPadDevice])
    {
		NSMutableArray *splitViewControllers = [[NSMutableArray alloc] initWithCapacity:VCs.count];
		NSInteger index = 0;
		for (GeneralTableViewController * controller in VCs)
        {
			UISplitViewController * split = controller.splitViewController;
			if (split) {
				// THIS SETS UP THE TAB BAR ITEMS/IMAGES AND SET THE TAG FOR TABBAR_ITEM_TAGS
				split.title = controller.dataSource.name;
				split.tabBarItem = [[[UITabBarItem alloc] initWithTitle:
									controller.dataSource.name image:controller.dataSource.tabBarImage tag:index] autorelease];
				[splitViewControllers addObject:split];
			}
			index++;
		}
		(self.tabBarController).viewControllers = splitViewControllers;
	}
	
	UIViewController * savedTabController = (self.tabBarController.viewControllers)[savedTabSelectionIndex];
	if (!savedTabController || !savedTabController.tabBarItem.enabled) {
		debug_NSLog (@"Couldn't find a view/navigation controller at index: %ld", (long)savedTabSelectionIndex);
		savedTabController = (self.tabBarController.viewControllers)[0];
	}
	else if (self.tabBarController.moreNavigationController) {
		self.tabBarController.moreNavigationController.navigationBar.tintColor = [TexLegeTheme navbar];
	}
	[self setTabOrderIfSaved];
	
	(self.tabBarController).selectedViewController = savedTabController;
	self.mainWindow.rootViewController = self.tabBarController;
}

- (void)reachabilityDidChange:(TexLegeReachability *)reachability
{
	if (!self.tabBarController)
        return;
    if (!reachability)
        reachability = [TexLegeReachability sharedTexLegeReachability];

    for (UITabBarItem *item in [self.tabBarController valueForKeyPath:@"viewControllers.tabBarItem"])
    {
        if (item.tag == TAB_BILL || item.tag == TAB_CALENDAR)
            item.enabled = reachability.openstatesConnectionStatus > NotReachable;
        else if (item.tag == TAB_DISTRICTMAP)
            item.enabled = reachability.googleConnectionStatus > NotReachable;
	}
}

- (void)runOnInitialAppStart:(id)sender
{	
	[[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];

	NSString *version = [NSBundle mainBundle].infoDictionary[@"CFBundleVersion"];
	
	[self restoreArchivableSavedTableSelection];
	
	[self setupViewControllerHierarchy];

	[self.mainWindow makeKeyAndVisible];

	// register our preference selection data to be archived
	NSDictionary *savedPrefsDict = @{kRestoreSelectionKey: [self archivableSavedTableSelection],
									kAnalyticsAskedForOptInKey: @NO,
									kAnalyticsSettingsSwitch: @YES,
									kShowedSplashScreenKey: @NO,
									kSegmentControlPrefKey: @{},
									kResetSavedDatabaseKey: @NO,
									kSupportEmailKey: @"support@texlege.com",
									@"CFBundleVersion": version};
	
	[[NSUserDefaults standardUserDefaults] registerDefaults:savedPrefsDict];
	
	[[NSUserDefaults standardUserDefaults] setObject:version forKey:@"CFBundleVersion"];
	[[NSUserDefaults standardUserDefaults] synchronize];
		
	[[LocalyticsSession sharedLocalyticsSession] startSession:LOCALITICS_APIKEY];
	
	[self runOnEveryAppStart];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{		
	NSLog(@"iOS Version: %@", [UIDevice currentDevice].systemVersion);
	
	[[TexLegeReachability sharedTexLegeReachability] startCheckingReachability:self];
	
	// initialize RestKit to handle our seed database and user database
	[TexLegeCoreDataUtils initRestKitObjects:self];	
	
    // Set up the mainWindow and content view
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];

	[self runOnInitialAppStart:nil];
		
	return YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{

}

- (void)applicationWillResignActive:(UIApplication *)application
{

}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
	[self runOnEveryAppStart];	
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
	[self runOnAppQuit];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
	[[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];

	[self runOnAppQuit];
}

- (void)runOnEveryAppStart
{
	self.appQuitting = NO;
	
	[[StateMetaLoader sharedStateMeta] setSelectedState:@"tx"];
	[PartisanIndexStats sharedPartisanIndexStats];
	[[BillMetadataLoader sharedBillMetadataLoader] loadMetadata:self];
	//[[CalendarEventsLoader sharedCalendarEventsLoader] loadEvents:self];
	
	if (![self isDatabaseResetNeeded])
    {
		self.analyticsOptInController = [[AnalyticsOptInAlertController alloc] init];
		if (![_analyticsOptInController presentAnalyticsOptInAlertIfNecessary])
			[_analyticsOptInController updateOptInFromSettings];
		
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (self.dataUpdater)
                [self.dataUpdater performDataUpdatesIfAvailable:nil];
        });
	}
	[[LocalyticsSession sharedLocalyticsSession] resume];
 	[[LocalyticsSession sharedLocalyticsSession] upload];
}

- (void)runOnAppQuit {
	//[[CalendarEventsLoader sharedCalendarEventsLoader] addAllEventsToiCal:self];		//testing
	
	if (self.isAppQuitting)
		return;
	self.appQuitting = YES;
		
	if (self.tabBarController)
    {
		// Smarten this up later for Core Data tab saving
		NSMutableArray *savedOrder = [NSMutableArray arrayWithCapacity:(self.tabBarController.viewControllers).count];
		NSArray *tabOrderToSave = self.tabBarController.viewControllers;
		
		for (UIViewController *aViewController in tabOrderToSave)
			[savedOrder addObject:aViewController.tabBarItem.title];
		
		[[NSUserDefaults standardUserDefaults] setObject:savedOrder forKey:kSavedTabOrderKey];
	}
	
    self.analyticsOptInController = nil;

	// save the drill-down hierarchy of selections to preferences
	[[NSUserDefaults standardUserDefaults] setObject:[self archivableSavedTableSelection] forKey:kRestoreSelectionKey];
	
	[[NSUserDefaults standardUserDefaults] synchronize];	
	
	[[LocalyticsSession sharedLocalyticsSession] close];
	[[LocalyticsSession sharedLocalyticsSession] upload];	
}

#pragma mark -
#pragma mark Saving

- (id)savedTableSelectionForKey:(NSString *)vcKey
{
	id object = nil;
	@try {
		id savedVC = (self.savedTableSelection)[@"viewController"];
		if (vcKey && savedVC && [vcKey isEqualToString:savedVC])
			object = (self.savedTableSelection)[@"object"];
		
	}
	@catch (NSException * e) {
		[self resetSavedTableSelection:nil];
	}
	
	return object;
}

- (void)setSavedTableSelection:(id)object forKey:(NSString *)vcKey
{
    if (![_savedTableSelection isKindOfClass:[NSMutableDictionary class]])
    {
        if ([_savedTableSelection isKindOfClass:[NSDictionary class]])
        {
            NSMutableDictionary *copy = [_savedTableSelection mutableCopy];
            if (_savedTableSelection)
                [_savedTableSelection release];
            _savedTableSelection = copy;
        }
        else
        {
            _savedTableSelection = [[NSMutableDictionary alloc] init];
        }
    }
	if (!vcKey)
    {
		[_savedTableSelection removeAllObjects];
		return;
	}
	(_savedTableSelection)[@"viewController"] = vcKey;
	if (object)
		(_savedTableSelection)[@"object"] = object;
	else
		[_savedTableSelection removeObjectForKey:@"object"];
}

- (void)resetSavedTableSelection:(id)sender
{
	self.savedTableSelection = [NSMutableDictionary dictionary];
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:kRestoreSelectionKey];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)restoreArchivableSavedTableSelection
{
	@try
    {
		NSData *data = [[NSUserDefaults standardUserDefaults] objectForKey:kRestoreSelectionKey];
		if (data)
        {
			NSDictionary *tempDict = [NSKeyedUnarchiver unarchiveObjectWithData:data];
			if (tempDict)
            {
				self.savedTableSelection = [tempDict mutableCopy];
			}
		}		
	}
	@catch (NSException * e)
    {
		[self resetSavedTableSelection:nil];
	}

}

- (NSData *)archivableSavedTableSelection
{
	NSData *data = nil;
	
	@try {
		NSDictionary *tempDict = self.savedTableSelection;
        if (tempDict)
            data = [NSKeyedArchiver archivedDataWithRootObject:[tempDict mutableCopy]];
	}
	@catch (NSException * e) {
		[self resetSavedTableSelection:nil];
	}
	return data;
}

- (BOOL) isDatabaseResetNeeded
{
	[[NSUserDefaults standardUserDefaults] synchronize];
	BOOL needsReset = [[NSUserDefaults standardUserDefaults] boolForKey:kResetSavedDatabaseKey];
		
	if (needsReset)
    {
		UIAlertView *resetDB = [[UIAlertView alloc] initWithTitle:NSLocalizedStringFromTable(@"Settings: Reset Data to Factory?", @"AppAlerts", @"Confirmation to delete and reset the app's database.")
														  message:NSLocalizedStringFromTable(@"Are you sure you want to restore the factory database?  NOTE: The application may quit after this reset.  Data updates will be applied automatically via the Internet during the next app launch.", @"AppAlerts",@"") 
														 delegate:self cancelButtonTitle:NSLocalizedStringFromTable(@"Cancel",@"StandardUI",@"Cancelling some activity")
												otherButtonTitles:NSLocalizedStringFromTable(@"Reset", @"StandardUI", @"Reset application settings to defaults"),nil];
		resetDB.tag = 23452;
		[resetDB show];
		[resetDB release];
	}
	return needsReset;
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
	if (alertView.tag != 23452)
        return;

    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kResetSavedDatabaseKey];
    [[NSUserDefaults standardUserDefaults] synchronize];

    if (buttonIndex != alertView.firstOtherButtonIndex)
        return;

    [self resetSavedTableSelection:nil];
    [TexLegeCoreDataUtils resetSavedDatabase:nil];

    DataModelUpdateManager *updater = self.dataUpdater;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (updater)
            [updater performDataUpdatesIfAvailable:nil];
    });
}

@end
