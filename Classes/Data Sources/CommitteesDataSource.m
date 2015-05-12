//
//  CommitteesDataSource.m
//  Created by Gregory S. Combs on 5/31/09.
//
//  StatesLege by Sunlight Foundation, based on work at https://github.com/sunlightlabs/StatesLege
//
//  This work is licensed under the Creative Commons Attribution-NonCommercial 3.0 Unported License. 
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc/3.0/
//  or send a letter to Creative Commons, 444 Castro Street, Suite 900, Mountain View, California, 94041, USA.
//
//

#import "CommitteesDataSource.h"
#import "TexLegeTheme.h"
#import "DisclosureQuartzView.h"
#import "TexLegeCoreDataUtils.h"
#import "CommitteePositionObj+RestKit.h"
#import "CommitteeObj+RestKit.h"
#import "TexLegeAppDelegate.h"

@interface CommitteesDataSource (Private)
@end

@implementation CommitteesDataSource

@synthesize fetchedResultsController;

@synthesize hideTableIndex;
@synthesize filterChamber, filterString, searchDisplayController;

- (Class)dataClass {
	return [CommitteeObj class];
}

- (id)init {
	if ((self = [super init])) {
		self.filterChamber = 0;
		self.filterString = [NSMutableString stringWithString:@""];
		
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(dataSourceReceivedMemoryWarning:)
													 name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(resetCoreData:) name:@"RESTKIT_LOADED_COMMITTEEOBJ" object:nil];	
		
	}
	return self;
}

- (void)resetCoreData:(NSNotification *)notification
{
    // You've got to delete the cache, or disable caching before you modify the predicate...
    [NSFetchedResultsController deleteCacheWithName:[self.fetchedResultsController cacheName]];
    [self.fetchedResultsController.fetchRequest setPredicate:[self getFilterPredicate]];
    [self.fetchedResultsController.fetchRequest setSortDescriptors:[self sortDescriptors]];

    NSError *error = nil;
    if (![self.fetchedResultsController performFetch:&error]) {
        // Handle error
        debug_NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
    }
}


- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];

	self.fetchedResultsController = nil;
	self.searchDisplayController = nil;
	self.filterString = nil;
	
    [super dealloc];
}

-(void)dataSourceReceivedMemoryWarning:(id)sender {
	// let's give this a swinging shot....	
	for (NSManagedObject *object in self.fetchedResultsController.fetchedObjects) {
		[[CommitteeObj managedObjectContext] refreshObject:object mergeChanges:NO];
	}
}

#pragma mark -
#pragma mark TableDataSourceProtocol methods

// return the data used by the navigation controller and tab bar item
- (NSString *)name 
{ return NSLocalizedStringFromTable(@"Committees", @"StandardUI", @"The short title for buttons and tabs related to legislative committees"); }

- (NSString *)navigationBarName 
{ return NSLocalizedStringFromTable(@"Committee Information", @"StandardUI", @"The long title for buttons and tabs related to legislative committees"); }

- (UIImage *)tabBarImage
{ return [UIImage imageNamed:@"60-signpost-inv.png"]; }

- (BOOL)showDisclosureIcon
{ return YES; }

- (BOOL)usesCoreData
{ return YES; }

- (BOOL)canEdit
{ return NO; }


// atomic number is displayed in a plain style tableview
- (UITableViewStyle)tableViewStyle {
	return UITableViewStylePlain;
}


// return the committee at the index in the sorted by symbol array
- (id) dataObjectForIndexPath:(NSIndexPath *)indexPath {
	CommitteeObj *tempEntry = nil;
	@try {
		tempEntry = [self.fetchedResultsController objectAtIndexPath:indexPath];
	}
	@catch (NSException * e) {
		// Perhaps we're returning from a search and we've got a wacked out indexPath.  Let's reset the search and see what happens.
		debug_NSLog(@"CommitteeDataSource.m -- committeeDataForIndexPath:  indexPath must be out of bounds.  %@", [indexPath description]); 
		[self removeFilter];
		tempEntry = [self.fetchedResultsController objectAtIndexPath:indexPath];
	}
	return tempEntry;
}

- (NSIndexPath *)indexPathForDataObject:(id)dataObject {
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
	BOOL useDark = (indexPath.row % 2 == 0);

	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Committees"];
	if (cell == nil) {
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"Committees"] autorelease];

		cell.detailTextLabel.font = [TexLegeTheme boldFifteen];
		cell.textLabel.font =		[TexLegeTheme boldTwelve];
		cell.detailTextLabel.textColor = 	[TexLegeTheme textDark];
		cell.textLabel.textColor =	[TexLegeTheme accent];
		
		cell.selectionStyle = UITableViewCellSelectionStyleBlue;
		cell.detailTextLabel.lineBreakMode = NSLineBreakByTruncatingTail;
		cell.detailTextLabel.adjustsFontSizeToFitWidth = YES;
        cell.detailTextLabel.minimumScaleFactor = (12.0 / cell.detailTextLabel.font.pointSize); // 12.f = deprecated minimumFontSize
		//cell.accessoryView = [TexLegeTheme disclosureLabel:YES];
		//cell.accessoryView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"disclosure"]] autorelease];

		DisclosureQuartzView *qv = [[DisclosureQuartzView alloc] initWithFrame:CGRectMake(0.f, 0.f, 28.f, 28.f)];
		//UIImageView *iv = [[UIImageView alloc] initWithImage:[qv imageFromUIView]];
		cell.accessoryView = qv;
		[qv release];
		//[iv release];
		
	}
    
	CommitteeObj *tempEntry = [self dataObjectForIndexPath:indexPath];
	
	if (tempEntry == nil) {
		debug_NSLog(@"Busted in CommitteeDataSource.m: cellForRowAtIndexPath -> Couldn't get committee data for row.");
		return nil;
	}
	
	// let's override some of the datasource's settings ... specifically, the background color.
	cell.backgroundColor = useDark ? [TexLegeTheme backgroundDark] : [TexLegeTheme backgroundLight];
	
	cell.detailTextLabel.text = tempEntry.committeeName;
	cell.textLabel.text = [tempEntry typeString];

	/*
	 if (tableView == self.searchDisplayController.searchResultsTableView) {
		cell.accessoryType = UITableViewCellAccessoryNone;
	}
	 */
	cell.accessoryView.hidden = (tableView == self.searchDisplayController.searchResultsTableView);


	return cell;
}


#pragma mark -
#pragma mark Indexing / Sections

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {	
	return [[self.fetchedResultsController sections] count];		
}

    // This is for the little index along the right side of the table ... use nil if you don't want it.
- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
	return  hideTableIndex ? nil : [self.fetchedResultsController sectionIndexTitles] ;
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index {
	return index; // index ..........
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
        // eventually (soon) we'll need to create a new fetchedResultsController to filter for chamber selection
	NSInteger count = [tableView numberOfSections];		
	if (count > 0) {
		id <NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchedResultsController sections] objectAtIndex:section];
        if (sectionInfo)
            count = [sectionInfo numberOfObjects];
	}
	return count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	NSInteger count = [tableView numberOfSections];		
	if (count > 0)  {
		id <NSFetchedResultsSectionInfo> sectionInfo = [[fetchedResultsController sections] objectAtIndex:section];
		return [sectionInfo indexTitle]; // or [sectionInfo name];
	}
	return @"";
}

#pragma mark -
#pragma mark Filtering Functions

// do we want to do a proper whichFilter sort of thing?
- (BOOL) hasFilter {
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

    if (self.filterString.length > 0)	// do some string filtering
        [predString appendFormat:@"(committeeName contains[cd] '%@')", self.filterString];
    if (self.filterChamber > 0) {		// do some chamber filtering
        if (predString.length > 0)	// we already have some predicate action, insert "AND"
            [predString appendString:@" AND "];
        [predString appendFormat:@"((committeeType == %@) OR (committeeType == 3))", [NSNumber numberWithInteger:self.filterChamber]];

    }

    NSPredicate *predicate = (predString.length > 0) ? [NSPredicate predicateWithFormat:predString] : nil;
    return predicate;
}

- (void) updateFilterPredicate
{
    return [self resetCoreData:nil];
}

// probably unnecessary, but we might as well validate the new info with our expectations...
- (void) setFilterByString:(NSString *)filter {
	if (!filter) filter = @"";
	if (![self.filterString isEqualToString:filter]) {
		self.filterString = [NSMutableString stringWithString:filter];
	}
	// we also get called on toolbar chamber switches, with or without a search string, so update anyway...
	[self updateFilterPredicate];	
}

- (void) removeFilter {
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
    NSSortDescriptor *sort = [[[NSSortDescriptor alloc] initWithKey:@"committeeName" ascending:YES] autorelease];
    return [NSArray arrayWithObject:sort];
}
/*
 Set up the fetched results controller.
 */
- (NSFetchedResultsController *)fetchedResultsController {
    
    if (fetchedResultsController != nil) {
        return fetchedResultsController;
    }
    
	// Create the fetch request for the entity.
	NSFetchRequest *fetchRequest = [CommitteeObj fetchRequest];
			
	// Sort by committeeName.
	[fetchRequest setSortDescriptors:[self sortDescriptors]];
	
	NSString * sectionString;
	// we don't want sections when searching, change to hasFilter if you don't want it for toolbarAction either...
    // nil for section name key path means "no sections".
	if (self.filterString.length > 0) 
		sectionString = nil;
	else
		sectionString = @"committeeNameInitial";
	
	fetchedResultsController = [[NSFetchedResultsController alloc] 
															 initWithFetchRequest:fetchRequest 
															 managedObjectContext:[CommitteeObj managedObjectContext] 
															 sectionNameKeyPath:sectionString cacheName:@"Committees"];

    fetchedResultsController.delegate = self;

	return fetchedResultsController;
}    

@end
