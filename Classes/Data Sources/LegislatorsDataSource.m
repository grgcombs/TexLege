//
//  LegislatorsDataSource.m
//  Created by Gregory S. Combs on 5/31/09.
//
//  StatesLege by Sunlight Foundation, based on work at https://github.com/sunlightlabs/StatesLege
//
//  This work is licensed under the Creative Commons Attribution-NonCommercial 3.0 Unported License. 
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc/3.0/
//  or send a letter to Creative Commons, 444 Castro Street, Suite 900, Mountain View, California, 94041, USA.
//
//

#import "LegislatorsDataSource.h"
#import "TexLegeCoreDataUtils.h"
#import "LegislatorObj.h"
#import "WnomObj.h"
#import "UtilityMethods.h"
#import "TexLegeTheme.h"
#import "LegislatorMasterCell.h"
#import "UIDevice-Hardware.h"
#import "TexLegeAppDelegate.h"

@interface LegislatorsDataSource ()
@property (nonatomic,copy) NSMutableString *filterString;
@end


@implementation LegislatorsDataSource
@synthesize filterChamber = _filterChamber;
@synthesize hideTableIndex = _hideTableIndex;
@synthesize fetchedResultsController = _fetchedResultsController;
@synthesize searchDisplayController = _searchDisplayController;

- (Class)dataClass
{
	return [LegislatorObj class];
}

- (instancetype)init
{
	if ((self = [super init]))
    {
		_filterChamber = 0;
		_filterString = [NSMutableString stringWithString:@""];

		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(dataSourceReceivedMemoryWarning:)
													 name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
		
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(resetCoreData:) name:@"RESTKIT_LOADED_LEGISLATOROBJ" object:nil];
	}
	return self;
}

- (void)resetCoreData:(NSNotification *)notification
{
    // You've got to delete the cache, or disable caching before you modify the predicate...
    NSFetchedResultsController *frc = self.fetchedResultsController;
    [NSFetchedResultsController deleteCacheWithName:frc.cacheName];
    NSFetchRequest *fetchRequest = frc.fetchRequest;
    fetchRequest.predicate = [self getFilterPredicate];
    fetchRequest.sortDescriptors = [self sortDescriptors];

    NSError *error = nil;
    if (![frc performFetch:&error]) {
        // Handle error
        debug_NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
    }
}

- (void)dealloc {	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)dataSourceReceivedMemoryWarning:(id)sender
{
	// let's give this a swinging shot....	
	for (NSManagedObject *object in self.fetchedResultsController.fetchedObjects)
    {
		[object.managedObjectContext refreshObject:object mergeChanges:NO];
	}
}

#pragma mark -
#pragma mark TableDataSourceProtocol methods
// return the data used by the navigation controller and tab bar item

- (NSString *)name 
{ return NSLocalizedStringFromTable(@"Legislators", @"StandardUI", @"The short title for buttons and tabs related to legislators"); }

- (NSString *)navigationBarName 
{ return NSLocalizedStringFromTable(@"Legislator Directory", @"StandardUI", @"The long title for buttons and tabs related to legislators"); }

- (UIImage *)tabBarImage 
{ return [UIImage imageNamed:@"123-id-card-inv.png"]; }

- (BOOL)showDisclosureIcon
{ return YES; }

- (BOOL)usesCoreData
{ return YES; }

- (BOOL)canEdit
{ return NO; }

#pragma mark -
#pragma mark UITableViewDataSource methods

// legislator name is displayed in a plain style tableview

- (UITableViewStyle)tableViewStyle {
	return UITableViewStylePlain;
};

- (id)safeObjectForIndexPath:(NSIndexPath *)indexPath
{
    NSFetchedResultsController *frc = self.fetchedResultsController;
    LegislatorObj *object = nil;
    NSArray *sections = frc.sections;
    if (sections.count > indexPath.section)
    {
        id<NSFetchedResultsSectionInfo> section = sections[indexPath.section];
        if ([section numberOfObjects] > indexPath.row)
        {
            object = [frc objectAtIndexPath:indexPath];
        }
    }
    return object;
}

// return the legislator at the index in the sorted by symbol array
- (id)dataObjectForIndexPath:(NSIndexPath *)indexPath
{
    LegislatorObj *object = [self safeObjectForIndexPath:indexPath];
    if (!object)
    {
		// Perhaps we're returning from a search and we've got a wacked out indexPath.  Let's reset the search and see what happens.
		debug_NSLog(@"DirectoryDataSource.m -- legislatorDataForIndexPath:  indexPath must be out of bounds.  %@", [indexPath description]); 
		[self removeFilter];
        object = [self safeObjectForIndexPath:indexPath];
	}
	return object;
}

- (NSIndexPath *)indexPathForDataObject:(id)dataObject
{
    if (!dataObject)
        return nil;

	NSIndexPath *tempIndex = nil;
	@try {
		tempIndex = [self.fetchedResultsController indexPathForObject:dataObject];
	}
	@catch (NSException * e) {
	}
	
	return tempIndex;
}

// UITableViewDataSource methods

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	LegislatorObj *dataObj = [self dataObjectForIndexPath:indexPath];

    static NSString *leg_cell_ID = @"LegislatorQuartz";
		
	LegislatorMasterCell *cell = (LegislatorMasterCell *)[tableView dequeueReusableCellWithIdentifier:leg_cell_ID];
	
	if (cell == nil) {
		cell = [[LegislatorMasterCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:leg_cell_ID];
		//cell.frame = CGRectMake(0.0, 0.0, 320.0, 73.0);
		cell.frame = CGRectMake(0.0, 0.0, 320.0, 73.0);
	}

    if (dataObj == nil) {
        debug_NSLog(@"Busted in DirectoryDataSource.m: cellForRowAtIndexPath -> Couldn't get legislator data for row.");
        return cell;
    }

	[cell setLegislator:dataObj];
	cell.cellView.useDarkBackground = (indexPath.row % 2 == 0);
	cell.accessoryView.hidden = (![self showDisclosureIcon] || tableView == self.searchDisplayController.searchResultsTableView);
	
	return cell;	
}

#pragma mark -
#pragma mark Indexing / Sections


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {	
	return self.fetchedResultsController.sections.count;
}

// This is for the little index along the right side of the table ... use nil if you don't want it.
- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
	return  _hideTableIndex ? nil : self.fetchedResultsController.sectionIndexTitles ;
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index {
	return index; // index ..........
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // eventually (soon) we'll need to create a new fetchedResultsController to filter for chamber selection
    NSInteger count = tableView.numberOfSections;
    NSArray *sections = self.fetchedResultsController.sections;
    if (sections.count <= section ||
        count == 0)
    {
        return 0;
    }
    id <NSFetchedResultsSectionInfo> sectionInfo = sections[section];
    if (!sectionInfo)
        return 0;
    return sectionInfo.numberOfObjects;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	// this table has multiple sections. One for each unique character that an element begins with
	// [A,B,C,D,E,F,G,H,I,K,L,M,N,O,P,R,S,T,U,V,X,Y,Z]
	// return the letter that represents the requested section
	
	NSString *headerTitle = nil;
	NSInteger count = tableView.numberOfSections;
    NSArray *sections = (self.fetchedResultsController).sections;
    if (count > 0 &&
        sections.count > section)
    {
		id <NSFetchedResultsSectionInfo> sectionInfo = sections[section];
        if (sectionInfo) {
            headerTitle = sectionInfo.indexTitle;
            if (!headerTitle)
                headerTitle = sectionInfo.name;
        }
	}
	if (!headerTitle)
		headerTitle = @"";

	return headerTitle;
}

#pragma mark -
#pragma mark Filtering Functions

// do we want to do a proper whichFilter sort of thing?
- (BOOL)hasFilter {
	return (self.filterString.length > 0 || self.filterChamber > 0);
}

// Predicate Programming
// You want your search to be diacritic insensitive to match the 'é' in pensée and 'e' in pensee. 
// You get this by adding the [d] after the attribute; the [c] means case insensitive.
//
// We can also do: "(firstName beginswith 'G') AND (lastName like 'Combs')"
//    or: "group.name matches "'work.*'", "ALL children.age > 12", and "ANY children.age > 12"
//    or for operations: "@sum.items.price < 1000"
//
// The matches operator uses regex, so is not supported by Core Data’s SQL store— although 
//     it does work with in-memory filtering.
// *** The Core Data SQL store supports only one to-many operation per query; therefore in any predicate 
//      sent to the SQL store, there may be only one operator (and one instance of that operator) 
//      from ALL, ANY, and IN.
// You cannot necessarily translate “arbitrary” SQL queries into predicates.
//*

- (NSPredicate *)getFilterPredicate
{
    NSMutableString * predString = [NSMutableString stringWithString:@""];

    if (self.filterChamber > 0)	// do some chamber filtering
        [predString appendFormat:@"(legtype = %@)", @(self.filterChamber)];
    if (self.filterString.length > 0) {		// do some string filtering
        if (predString.length > 0)	// we already have some predicate action, insert "AND"
            [predString appendString:@" AND "];
        [predString appendFormat:@"((lastname CONTAINS[cd] '%@') OR (firstname CONTAINS[cd] '%@')", self.filterString, self.filterString];
        [predString appendFormat:@" OR (middlename CONTAINS[cd] '%@') OR (nickname CONTAINS[cd] '%@')", self.filterString, self.filterString];
        [predString appendFormat:@" OR (district CONTAINS[cd] '%@'))", self.filterString];
    }

    NSPredicate *predicate = (predString.length > 0) ? [NSPredicate predicateWithFormat:predString] : nil;
    return predicate;
}

- (void)updateFilterPredicate
{
    [self resetCoreData:nil];
}

// probably unnecessary, but we might as well validate the new info with our expectations...
- (void)setFilterByString:(NSString *)filter {
	if (!filter) filter = @"";
	
	self.filterString = [NSMutableString stringWithString:filter];

	// we also get called on toolbar chamber switches, with or without a search string, so update anyway...
	[self updateFilterPredicate];	
}

- (void)removeFilter {
	// do we want to tell it to clear out our chamber selection too? Not really, the ViewController sets it for us.
	// self.filterChamber = 0;
	[self setFilterByString:@""]; // we updateFilterPredicate automatically
	
}	

#pragma mark -
#pragma mark Core Data Methods

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
	[[NSNotificationCenter defaultCenter] postNotificationName:@"TABLEUPDATE_START" object:self];
//    [self.tableView beginUpdates];
}
- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
	[[NSNotificationCenter defaultCenter] postNotificationName:@"TABLEUPDATE_END" object:self];
//    [self.tableView endUpdates];
}

- (NSArray *)sortDescriptors
{
    NSSortDescriptor *last = [[NSSortDescriptor alloc] initWithKey:@"lastname" ascending:YES];
    NSSortDescriptor *first = [[NSSortDescriptor alloc] initWithKey:@"firstname"ascending:YES];
    return @[last, first];
}

- (NSFetchedResultsController *)fetchedResultsController
{
    if (_fetchedResultsController != nil) {
        return _fetchedResultsController;
    }    
	// Create the fetch request for the entity.
	NSFetchRequest *fetchRequest = [LegislatorObj rkFetchRequest];
    fetchRequest.sortDescriptors = [self sortDescriptors];
	
	NSString * sectionString = nil;

	// we don't want sections when searching, change to hasFilter if you don't want it for toolbarAction either...
    // nil for section name key path means "no sections".
	if (self.filterString.length == 0)
		sectionString = @"lastnameInitial";

    NSString *cacheName = nil; // @"Legislators"
	NSFetchedResultsController *frc = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:[LegislatorObj rkManagedObjectContext] sectionNameKeyPath:sectionString cacheName:cacheName];
    frc.delegate = self;
    _fetchedResultsController = frc;
	return frc;
}    

@end
