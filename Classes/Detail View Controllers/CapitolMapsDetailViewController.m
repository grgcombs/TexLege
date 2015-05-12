//
//  CapitolMapsDetailViewController.m
//  Created by Gregory S. Combs on 5/31/09.
//
//  StatesLege by Sunlight Foundation, based on work at https://github.com/sunlightlabs/StatesLege
//
//  This work is licensed under the Creative Commons Attribution-NonCommercial 3.0 Unported License. 
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc/3.0/
//  or send a letter to Creative Commons, 444 Castro Street, Suite 900, Mountain View, California, 94041, USA.
//
//

#import "CapitolMapsDetailViewController.h"
#import "CapitolMapsMasterViewController.h"
#import "CommitteeObj.h"
#import "UtilityMethods.h"
#import "TexLegeAppDelegate.h"
#import "LocalyticsSession.h"

@implementation CapitolMapsDetailViewController

@synthesize map, webView, masterPopover;


#pragma mark -
#pragma mark Intialization and Memory Management

- (void)viewDidLoad {
	[super viewDidLoad];
	self.hidesBottomBarWhenPushed = YES;
	
	[self.webView setBackgroundColor:[UIColor darkGrayColor]];
	[self.webView setOpaque:YES];
	self.view.backgroundColor = [UIColor darkGrayColor];
	
	if (self.map) {
		self.navigationItem.title = self.map.name;
		[self.webView loadRequest:[NSURLRequest requestWithURL:self.map.url]];
	}
	else {
		self.navigationItem.title = NSLocalizedStringFromTable(@"Capitol Maps", @"StandardUI", @"The short title for buttons and tabs related to maps of the building");
	}
}

- (void)viewDidUnload {
	[super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	
	if ([UtilityMethods isIPadDevice] && !self.map && ![UtilityMethods isLandscapeOrientation])  {
		TexLegeAppDelegate *appDelegate = [TexLegeAppDelegate appDelegate];
		
		self.map = [[appDelegate capitolMapsMasterVC] selectObjectOnAppear];		

	}	
}

- (void)dealloc {
	self.webView = nil;
	self.map = nil;
	self.masterPopover = nil;
	[super dealloc];
}

- (void)didReceiveMemoryWarning {
	UINavigationController *nav = [self navigationController];
	if (nav) {
		[nav popToRootViewControllerAnimated:YES];
	}
	
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
    // Release anything that's not essential, such as cached data
}

- (id)dataObject {
	return self.map;
}

- (void)setDataObject:(id)newObj {
	[self setMap:newObj];
}


- (void)setMap:(CapitolMap *)newObj {
	
	if (map) [map release], map = nil;
	if (newObj) {
		if (masterPopover) {
			[masterPopover dismissPopoverAnimated:YES];
		}
		
		map = [newObj retain];

		self.navigationItem.title = map.name;
		[self.webView loadRequest:[NSURLRequest requestWithURL:map.url]];
		[self.view setNeedsDisplay];
	}
}


#pragma mark -
#pragma mark Popover Support

- (void)splitViewController: (UISplitViewController*)svc willHideViewController:(UIViewController *)aViewController withBarButtonItem:(UIBarButtonItem*)barButtonItem forPopoverController: (UIPopoverController*)pc {
	//debug_NSLog(@"Entering portrait, showing the button: %@", [aViewController class]);
    barButtonItem.title = NSLocalizedStringFromTable(@"Capitol Maps", @"StandardUI", @"The short title for buttons and tabs related to maps of the building");
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

#pragma mark -
#pragma mark Orientation

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation { // Override to allow rotation. Default returns YES only for UIDeviceOrientationPortrait
	return YES;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
	[self.webView reload];
}


@end
