//
//  CalendarDetailViewController.h
//  Created by Gregory Combs on 7/29/10.
//
//  StatesLege by Sunlight Foundation, based on work at https://github.com/sunlightlabs/StatesLege
//
//  This work is licensed under the Creative Commons Attribution-NonCommercial 3.0 Unported License. 
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc/3.0/
//  or send a letter to Creative Commons, 444 Castro Street, Suite 900, Mountain View, California, 94041, USA.
//
//
#import "Kal.h"
#import <EventKit/EventKit.h>
#import <EventKitUI/EventKitUI.h>
#import "TXLDetailProtocol.h"

@class ChamberCalendarObj;
@class TexLegeNavBar;

@interface CalendarDetailViewController : KalViewController <UISplitViewControllerDelegate,UISearchDisplayDelegate,UITableViewDelegate, UIPopoverControllerDelegate, EKEventViewDelegate, TXLDetailProtocol>

@property (nonatomic, strong) id dataObject;
@property (nonatomic, strong) UIPopoverController *masterPopover;
@property (nonatomic, strong) UIPopoverController *eventPopover;

@property (nonatomic, strong) IBOutlet UIWebView *webView;
@property (nonatomic, strong) ChamberCalendarObj *chamberCalendar;
@property (nonatomic, assign) CGRect selectedRowRect;

+ (NSString *)nibName;

- (void)presentEventEditorForEvent:(EKEvent *)event;
@end
