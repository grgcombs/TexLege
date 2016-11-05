//
//  NotesViewController.h
//  Created by Gregory Combs on 7/22/09.
//
//  StatesLege by Sunlight Foundation, based on work at https://github.com/sunlightlabs/StatesLege
//
//  This work is licensed under the Creative Commons Attribution-NonCommercial 3.0 Unported License. 
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc/3.0/
//  or send a letter to Creative Commons, 444 Castro Street, Suite 900, Mountain View, California, 94041, USA.
//
//

@import UIKit;

#define kStaticNotes NSLocalizedStringFromTable(@"Notes", @"DataTableUI", @"Default entry for a custom notes field.")

@class LegislatorObj;

@interface NotesViewController : UIViewController

@property (nonatomic, strong) NSNumber *dataObjectID;
@property (nonatomic, weak) LegislatorObj *legislator;
@property (nonatomic, strong) IBOutlet UITextView *notesText;
@property (nonatomic, strong) IBOutlet UILabel *nameLabel;
@property (nonatomic, strong) IBOutlet UINavigationItem *navTitle;
@property (nonatomic, strong) IBOutlet UINavigationBar *navBar;

@property (nonatomic, weak) UITableViewController *backViewController;

@end
