//
//  CalendarDetailViewController.m
//  Created by Gregory Combs on 7/29/10.
//
//  StatesLege by Sunlight Foundation, based on work at https://github.com/sunlightlabs/StatesLege
//
//  This work is licensed under the Creative Commons Attribution-NonCommercial 3.0 Unported License. 
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc/3.0/
//  or send a letter to Creative Commons, 444 Castro Street, Suite 900, Mountain View, California, 94041, USA.
//
//
#import "CalendarDetailViewController.h"
#import "CalendarMasterViewController.h"
#import "UtilityMethods.h"
#import "SVWebViewController.h"
#import "TexLegeAppDelegate.h"
#import "ChamberCalendarObj.h"
#import "TexLegeTheme.h"
#import "LocalyticsSession.h"
#import <EventKit/EventKit.h>
#import <EventKitUI/EventKitUI.h>
#import "CalendarEventsLoader.h"
#import <SafariServices/SFSafariViewController.h>

@interface CalendarDetailViewController (Private) 
	
@end

@implementation CalendarDetailViewController
@synthesize chamberCalendar;
@synthesize webView;
@synthesize masterPopover;
@synthesize selectedRowRect;
@synthesize eventPopover;

+ (NSString *)nibName {
	if ([UtilityMethods isIPadDevice])
		return @"CalendarDetailViewController~ipad";
	else
		return @"CalendarDetailViewController~iphone";	
}

- (NSString *)nibName {
	return [CalendarDetailViewController nibName];	
}

- (void)finalizeUI {
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(reloadEvents:) name:kCalendarEventsNotifyLoaded object:nil];	

	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(reloadEvents:) name:kCalendarEventsNotifyError object:nil];	

	self.selectedRowRect = CGRectZero;
	
	
	//self.navigationItem.title = @"Upcoming Committee Meetings";

	self.navigationController.navigationBar.tintColor = [TexLegeTheme navbar];
	self.searchDisplayController.searchBar.tintColor = [TexLegeTheme navbar];
    if ([UtilityMethods isIPadDevice])
    {
        self.navigationItem.titleView = self.searchDisplayController.searchBar;
    }
    else
    {
        self.searchDisplayController.displaysSearchBarInNavigationBar = YES;
    }
}

- (void)awakeFromNib {
	[super awakeFromNib];
	if (!self.webView && [UtilityMethods isIPadDevice]) {
		[[NSBundle mainBundle] loadNibNamed:self.nibName owner:self options:nil];
	}
	
	[self finalizeUI];
}	

- (void)viewDidLoad {
	[super viewDidLoad];
	
	[self finalizeUI];
}

- (void)viewDidUnload {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[super viewDidUnload];
}

- (void)didReceiveMemoryWarning {	
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];

	self.chamberCalendar = nil;
	self.webView = nil;
	self.masterPopover = nil;
	self.eventPopover = nil;
    [super dealloc];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	self.navigationController.navigationBar.tintColor = [TexLegeTheme navbar];

	[[CalendarEventsLoader sharedCalendarEventsLoader] events];
	
	if ([UtilityMethods isIPadDevice] && !self.chamberCalendar && ![UtilityMethods isLandscapeOrientation])  {
		TexLegeAppDelegate *appDelegate = [TexLegeAppDelegate appDelegate];
		
		self.chamberCalendar = appDelegate.calendarMasterVC.selectObjectOnAppear;		
	}
	
	if (self.chamberCalendar)
		self.searchDisplayController.searchBar.placeholder = self.chamberCalendar.title;
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	if ([UtilityMethods isIPadDevice])
		return YES;
	else
		return UIInterfaceOrientationIsPortrait(interfaceOrientation);
}

#pragma mark -
#pragma mark Data Objects

- (void)reloadEvents:(NSNotification*)notification {
	[self reloadData];
}

- (id)dataObject {
	return self.chamberCalendar;
}

- (void)setDataObject:(id)newObj {
	self.chamberCalendar = newObj;
}

- (void)setChamberCalendar:(ChamberCalendarObj *)newObj {
    if (self.isViewLoaded)
    {
        if (chamberCalendar && newObj && self.webView) {
            if (![[chamberCalendar valueForKey:@"title"] isEqualToString:[newObj valueForKey:@"title"]])
                [self.webView loadHTMLString:@"<html></html>" baseURL:nil];
        }
    }
	
	if (chamberCalendar) [chamberCalendar release], chamberCalendar = nil;
	if (newObj) {
		if (masterPopover)
			[masterPopover dismissPopoverAnimated:YES];
		
		chamberCalendar = [newObj retain];

        if (!self.isViewLoaded)
            [self loadView];
		
		self.delegate = self;
		self.dataSource = chamberCalendar;
		(self.searchDisplayController).searchResultsDataSource = chamberCalendar;
				
		[self showAndSelectDate:[NSDate date]];
	}
}

#pragma mark -
#pragma mark Popover Support


- (void)splitViewController: (UISplitViewController*)svc willHideViewController:(UIViewController *)aViewController withBarButtonItem:(UIBarButtonItem*)barButtonItem forPopoverController: (UIPopoverController*)pc {
	//debug_NSLog(@"Entering portrait, showing the button: %@", [aViewController class]);
    barButtonItem.title =  NSLocalizedStringFromTable(@"Meetings", @"StandardUI", @"The short title for buttons and tabs related to committee meetings (or calendar events)");
    [self.navigationItem setRightBarButtonItem:barButtonItem animated:YES];
    self.masterPopover = pc;
}


// Called when the view is shown again in the split view, invalidating the button and popover controller.
- (void)splitViewController: (UISplitViewController*)svc willShowViewController:(UIViewController *)aViewController invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem {
	//debug_NSLog(@"Entering landscape, hiding the button: %@", [aViewController class]);
    [self.navigationItem setRightBarButtonItem:nil animated:YES];
    self.masterPopover = nil;
}

- (void) splitViewController:(UISplitViewController *)svc popoverController: (UIPopoverController *)pc
   willPresentViewController: (UIViewController *)aViewController
{
	if ([UtilityMethods isLandscapeOrientation]) {
		[[LocalyticsSession sharedLocalyticsSession] tagEvent:@"ERR_POPOVER_IN_LANDSCAPE"];
	}		 
}	

#pragma -
#pragma UITableViewDelegate


- (void)tableView:(UITableView *)tv accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
	NSDictionary *eventDict = [self.chamberCalendar eventForIndexPath:indexPath];
	if (eventDict) {
		
		self.selectedRowRect = [tv rectForRowAtIndexPath:indexPath];
		
		[[CalendarEventsLoader sharedCalendarEventsLoader] addEventToiCal:eventDict delegate:self];	
	}
}


- (void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

	[tv deselectRowAtIndexPath:indexPath animated:YES];
	
	self.selectedRowRect = [tv rectForRowAtIndexPath:indexPath];

	NSDictionary *eventDict = [self.chamberCalendar eventForIndexPath:indexPath];
	
	if (tv == self.searchDisplayController.searchResultsTableView) {
		[self.searchDisplayController setActive:NO animated:YES];
		[self showAndSelectDate:eventDict[kCalendarEventsLocalizedDateKey]];
	}

    if (IsEmpty(eventDict[kCalendarEventsAnnouncementURLKey])) {
        return;
    }
	NSURL *url = eventDict[kCalendarEventsAnnouncementURLKey];
	
	if ([TexLegeReachability canReachHostWithURL:url]) { // do we have a good URL/connection?
		if ([UtilityMethods isIPadDevice]) {	
			NSURLRequest *urlReq = [NSURLRequest requestWithURL:url 
													cachePolicy:NSURLRequestUseProtocolCachePolicy 
												timeoutInterval:60.0];
			if (urlReq) {
				[self.webView loadRequest:urlReq];	
			}
		}
		else {
			NSString *urlString = url.absoluteString;
            NSURL *url = [NSURL URLWithString:urlString];
            if (!url)
                return;
            
            UIViewController *webController = nil;
            
            if ([url.scheme hasPrefix:@"http"])
                webController = [[SFSafariViewController alloc] initWithURL:url];
            else // can't use anything except http: or https: with SFSafariViewControllers
                webController = [[SVWebViewController alloc] initWithAddress:urlString];

			webController.modalPresentationStyle = UIModalPresentationPageSheet;
            [self presentViewController:webController animated:YES completion:nil];
			[webController release];
		}		
	}
}

#pragma mark -
#pragma mark Search Results Delegate

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString {
	[self.chamberCalendar filterEventsByString:searchString];
	
	return YES; // or foundSomething?
}

- (void) presentEventEditorForEvent:(EKEvent *)event {
	[[LocalyticsSession sharedLocalyticsSession] tagEvent:@"iCAL_EVENT"];
	
	EKEventViewController *controller = [[EKEventViewController alloc] init];			
	controller.event = event;
	controller.allowsEditing = YES;
    controller.delegate = self;
	
	if (NO == [UtilityMethods isIPadDevice]) {
		//	Push eventViewController onto the navigation controller stack
		//	If the underlying event gets deleted, detailViewController will remove itself from
		//	the stack and clear its event property.
		[self.navigationController pushViewController:controller animated:YES];
	}
	else  {	
		/* This is a hacky way to do this, but since we aren't using a navigationController
		 we create a popover, but first we have to wrap the content in a new navigationController
		 in order to get the necessary button in a nav bar to edit the event.
		 */
		
		controller.modalInPopover = NO;
		
		UINavigationController *navC = [[UINavigationController alloc]initWithRootViewController:controller];
		navC.navigationBar.tintColor = [TexLegeTheme navbar];
		UIPopoverController* aPopover = [[UIPopoverController alloc]
										 initWithContentViewController:navC];
		self.eventPopover = aPopover;
		self.eventPopover.delegate = self;
		[self.eventPopover presentPopoverFromRect:self.selectedRowRect 
												inView:self.calendarView.tableView
							  permittedArrowDirections:UIPopoverArrowDirectionAny 
											  animated:YES];
		[navC release];
		[aPopover release];				
	}
	[controller release];
}

- (void)eventViewController:(EKEventViewController *)controller didCompleteWithAction:(EKEventViewAction)action {
    if (self.eventPopover) {
        [self.eventPopover dismissPopoverAnimated:YES];
        self.eventPopover = nil;
    }
}

- (BOOL)popoverControllerShouldDismissPopover:(UIPopoverController *)newPop {
	return YES;
}

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)newPop {
	if ([newPop isEqual:self.eventPopover]) {
		self.eventPopover = nil;
	}
}

@end
