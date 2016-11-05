//
//  NotesViewController.m
//  Created by Gregory Combs on 7/22/09.
//
//  StatesLege by Sunlight Foundation, based on work at https://github.com/sunlightlabs/StatesLege
//
//  This work is licensed under the Creative Commons Attribution-NonCommercial 3.0 Unported License. 
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc/3.0/
//  or send a letter to Creative Commons, 444 Castro Street, Suite 900, Mountain View, California, 94041, USA.
//
//

#import "NotesViewController.h"
#import "LegislatorObj+RestKit.h"
#import "UtilityMethods.h"
#import "TexLegeTheme.h"
#import "LocalyticsSession.h"
#import "TexLegeCoreDataUtils.h"
#import "TexLegeAppDelegate.h"
#import "TXLDetailProtocol.h"

@implementation NotesViewController

@synthesize notesText, nameLabel, dataObjectID;

- (void)viewDidLoad
{
	[super viewDidLoad];
	if ([UtilityMethods isIPadDevice])
    {
		self.navBar.tintColor = [TexLegeTheme accent];
		self.navTitle.rightBarButtonItem = self.editButtonItem;
		self.preferredContentSize = CGSizeMake(320.f, 320.f);
	}
	else
    {
		self.navigationItem.title = NSLocalizedStringFromTable(@"Notes", @"DataTableUI", @"Title for the cell indicating custom notes option");
		self.navigationItem.rightBarButtonItem = self.editButtonItem;
	}
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	NSString *notesString = nil;
	
	[[NSUserDefaults standardUserDefaults] synchronize];
	NSDictionary *storedNotesDict = [[NSUserDefaults standardUserDefaults] valueForKey:@"LEGE_NOTES"];

    LegislatorObj *legislator = self.legislator;
    if (!legislator)
        return;
    
	if (storedNotesDict)
    {
		NSString *temp = [storedNotesDict valueForKey:(legislator.legislatorID).stringValue];
		if (temp && temp.length)
			notesString = temp;
	}
	if (!notesString)
		notesString = legislator.notes;
	
    // Update the views appropriately
    self.nameLabel.text = [legislator shortNameForButtons];
	if (!notesString || notesString.length == 0) {
		self.notesText.text = kStaticNotes;
	}
	else
		self.notesText.text = notesString;    
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Support all orientations except upside-down
    return YES;
}

#pragma mark -
#pragma mark Data Objects

- (LegislatorObj *)legislator
{
	LegislatorObj *anObject = nil;
	if (self.dataObjectID) {
		anObject = [LegislatorObj objectWithPrimaryKeyValue:self.dataObjectID];
	}
	return anObject;
}

- (void)setLegislator:(LegislatorObj *)anObject
{
	self.dataObjectID = nil;
	if (anObject)
    {
		self.dataObjectID = anObject.legislatorID;
	}
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];

    self.notesText.editable = editing;
	[self.navigationItem setHidesBackButton:editing animated:YES];

	[[LocalyticsSession sharedLocalyticsSession] tagEvent:@"EDITING_NOTES"];
	
	if (editing)
        return;

    /*
     If editing is finished, update the recipe's instructions and save the managed object context.
     */

    LegislatorObj *legislator = self.legislator;
    if (!legislator)
        return;

    if (![self.notesText.text isEqualToString:kStaticNotes])
    {
        [[NSUserDefaults standardUserDefaults] synchronize];
        NSDictionary *storedNotesDict = [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"LEGE_NOTES"];
        NSMutableDictionary *newDictionary = nil;

        if (!storedNotesDict) {
            newDictionary = [NSMutableDictionary dictionary];
        }
        else {
            newDictionary = [NSMutableDictionary dictionaryWithDictionary:storedNotesDict];
        }

        newDictionary[(legislator.legislatorID).stringValue] = self.notesText.text;
        [[NSUserDefaults standardUserDefaults] setObject:newDictionary forKey:@"LEGE_NOTES"];
        [[NSUserDefaults standardUserDefaults] synchronize];

        legislator.notes = self.notesText.text;
    }

    NSError *error = nil;
    if (![legislator.managedObjectContext save:&error])
    {
        // Handle error
        debug_NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
    }

    UITableViewController *backViewController = self.backViewController;
    if (!backViewController)
        return;

    if ([backViewController respondsToSelector:@selector(resetTableData:)])
        [backViewController performSelector:@selector(resetTableData:) withObject:self];

}

@end
