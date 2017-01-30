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
#import <SLToastKit/SLTypeCheck.h>

@implementation CapitolMapsDetailViewController

- (void)viewDidLoad
{
	[super viewDidLoad];
	self.hidesBottomBarWhenPushed = YES;
	
	self.webView.backgroundColor = [UIColor darkGrayColor];
    self.webView.opaque = YES;
	self.view.backgroundColor = [UIColor darkGrayColor];
	
    CapitolMap *map = self.map;
	if (map)
    {
		self.navigationItem.title = map.name;
        NSURL *url = map.url;
        if (url)
            [self.webView loadRequest:[NSURLRequest requestWithURL:url]];
	}
	else
    {
		self.navigationItem.title = NSLocalizedStringFromTable(@"Capitol Maps", @"StandardUI", @"The short title for buttons and tabs related to maps of the building");
	}
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	if ([UtilityMethods isIPadDevice] && !self.map && ![UtilityMethods isLandscapeOrientation])
    {
		TexLegeAppDelegate *appDelegate = [TexLegeAppDelegate appDelegate];
		self.map = appDelegate.capitolMapsMasterVC.initialObjectToSelect;
	}
    
    if (self.splitViewController.displayMode == UISplitViewControllerDisplayModePrimaryHidden)
    {
        UIBarButtonItem *button = self.splitViewController.displayModeButtonItem;
        [self.navigationItem setRightBarButtonItem:button animated:animated];
    }
}

- (void)splitViewController:(UISplitViewController *)svc willChangeToDisplayMode:(UISplitViewControllerDisplayMode)displayMode
{
    if (svc.displayMode == UISplitViewControllerDisplayModePrimaryHidden)
    {
        UIBarButtonItem *button = svc.displayModeButtonItem;
        [self.navigationItem setRightBarButtonItem:button animated:YES];
    }
}

- (BOOL)shouldAutorotate
{
    return YES;
}

- (void)dealloc
{
	self.map = nil;
}

- (id)dataObject
{
	return self.map;
}

- (void)setDataObject:(id)newObj
{
	self.map = newObj;
}

- (void)setMap:(CapitolMap *)newObj
{
    _map = SLValueIfClass(CapitolMap, newObj);
    if (!_map)
        return;
    self.navigationItem.title = newObj.name;
    NSURL *url = newObj.url;
    if (!url)
        return;
    [self.webView loadRequest:[NSURLRequest requestWithURL:url]];
    [self.view setNeedsDisplay];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
	[self.webView reload];
}

@end
