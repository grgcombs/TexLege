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
#import <SLFRestKit/NSManagedObject+RestKit.h>

@implementation NotesViewController

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
		self.navigationItem.title = NSLocalizedStringFromTable(@"Notes", @"DataTableUI", nil);
		self.navigationItem.rightBarButtonItem = self.editButtonItem;
	}
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];

    LegislatorObj *legislator = self.legislator;
    if (!legislator)
        return;
    self.nameLabel.text = [legislator shortNameForButtons];

    [[NSUserDefaults standardUserDefaults] synchronize];
	NSDictionary *notesByLegislator = [[NSUserDefaults standardUserDefaults] valueForKey:@"LEGE_NOTES"];
    NSString *text = legislator.notes;
    NSString *lookup = legislator.legislatorID.stringValue;
	if (lookup && [notesByLegislator isKindOfClass:[NSDictionary class]])
    {
		NSString *storedNotes = notesByLegislator[lookup];
		if (storedNotes && [storedNotes isKindOfClass:[NSString class]])
			text = storedNotes;
    }

	if (!text || !text.length)
		self.notesText.text = kStaticNotes;
	else
		self.notesText.text = text;    
}


- (BOOL)shouldAutorotate
{
    return YES;
}

- (LegislatorObj *)legislator
{
	LegislatorObj *legislator = nil;
	if (self.dataObjectID)
		legislator = [LegislatorObj objectWithPrimaryKeyValue:self.dataObjectID];
	return legislator;
}

- (void)setLegislator:(LegislatorObj *)legislator
{
	if ([legislator isKindOfClass:[LegislatorObj class]])
		self.dataObjectID = legislator.legislatorID;
    else
        self.dataObjectID = nil;
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];

    self.notesText.editable = editing;
	[self.navigationItem setHidesBackButton:editing animated:YES];

	[[LocalyticsSession sharedLocalyticsSession] tagEvent:@"EDITING_NOTES"];
	
	if (editing)
        return;

    LegislatorObj *legislator = self.legislator;
    if (!legislator)
        return;
    NSString *notesText = self.notesText.text;

    if (![kStaticNotes isEqualToString:notesText])
    {
        legislator.notes = notesText;

        NSError *error = nil;
        if (legislator.hasChanges)
        {
            if (![legislator.managedObjectContext save:&error])
            {
                debug_NSLog(@"Unable to save changes for legislator notes: %@", [error localizedDescription]);
            }
        }

        NSString *lookup = legislator.legislatorID.stringValue;
        if (lookup)
        {
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            NSDictionary *notesDict = [defaults dictionaryForKey:@"LEGE_NOTES"];
            NSMutableDictionary *mutableNotesDict = [NSMutableDictionary dictionaryWithDictionary:notesDict];
            mutableNotesDict[lookup] = notesText;
            [defaults setObject:mutableNotesDict forKey:@"LEGE_NOTES"];
        }
    }

    UITableViewController *backViewController = self.backViewController;
    if (!backViewController)
        return;

    if ([backViewController respondsToSelector:@selector(resetTableData:)])
        [backViewController performSelector:@selector(resetTableData:) withObject:self];
}

@end
