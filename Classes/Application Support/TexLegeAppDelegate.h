//
//  TexLegeAppDelegate.h
//  Created by Gregory Combs on 7/22/09.
//
//  StatesLege by Sunlight Foundation, based on work at https://github.com/sunlightlabs/StatesLege
//
//  This work is licensed under the Creative Commons Attribution-NonCommercial 3.0 Unported License. 
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc/3.0/
//  or send a letter to Creative Commons, 444 Castro Street, Suite 900, Mountain View, California, 94041, USA.
//
//

#import "TexLege.h"
#import "TexLegeReachability.h"

@class LegislatorMasterViewController;
@class CommitteeMasterViewController;
@class LinksMasterViewController;
@class CapitolMapsMasterViewController;
@class CalendarMasterViewController;
@class DistrictMapMasterViewController;
@class BillsMasterViewController;
@class DataModelUpdateManager;
@class AnalyticsOptInAlertController;

@interface TexLegeAppDelegate : NSObject  <UIApplicationDelegate, UIAlertViewDelegate, UINavigationControllerDelegate, TexLegeReachabilityDelegate>

@property (nonatomic, strong, readonly) DataModelUpdateManager *dataUpdater;
@property (nonatomic, strong, readonly) UIWindow *mainWindow;
@property (nonatomic, copy, readonly) NSDictionary *savedTableSelection;
@property (nonatomic, getter=isAppQuitting,readonly) BOOL appQuitting;

// For Functional View Controllers
@property (nonatomic, strong) IBOutlet LinksMasterViewController *linksMasterVC;
@property (nonatomic, strong) IBOutlet CapitolMapsMasterViewController *capitolMapsMasterVC;
@property (nonatomic, strong) IBOutlet CommitteeMasterViewController *committeeMasterVC;
@property (nonatomic, strong) IBOutlet LegislatorMasterViewController *legislatorMasterVC;
@property (nonatomic, strong) IBOutlet CalendarMasterViewController *calendarMasterVC;
@property (nonatomic, strong) IBOutlet DistrictMapMasterViewController *districtMapMasterVC;
@property (nonatomic, strong) IBOutlet BillsMasterViewController *billsMasterVC;

@property (nonatomic, strong) IBOutlet UITabBarController *tabBarController;

// For iPad Interface
@property (weak, nonatomic, readonly) UISplitViewController *splitViewController;
@property (weak, nonatomic, readonly) UIViewController *currentMasterViewController;
@property (weak, nonatomic, readonly) UINavigationController * masterNavigationController;
@property (weak, nonatomic, readonly) UINavigationController *detailNavigationController;

- (id) savedTableSelectionForKey:(NSString *)vcKey;
- (void)setSavedTableSelection:(id)object forKey:(NSString *)vcKey;

+ (TexLegeAppDelegate *)appDelegate;

@end
