//
//  DistrictMapDataSource.m
//  Created by Gregory Combs on 8/23/10.
//
//  StatesLege by Sunlight Foundation, based on work at https://github.com/sunlightlabs/StatesLege
//
//  This work is licensed under the Creative Commons Attribution-NonCommercial 3.0 Unported License. 
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc/3.0/
//  or send a letter to Creative Commons, 444 Castro Street, Suite 900, Mountain View, California, 94041, USA.
//
//

#import "DistrictMapDataSource.h"
#import "TexLegeTheme.h"
#import "DistrictMapObj+RestKit.h"
#import "DisclosureQuartzView.h"
#import "TexLegeCoreDataUtils.h"
#import "TexLegeAppDelegate.h"
#import "LegislatorObj+RestKit.h"
#import "TexLegeStandardGroupCell.h"
#import <SLToastKit/SLTypeCheck.h>

#if NEEDS_TO_PARSE_KMLMAPS == 1
#import "DistrictOfficeObj.h"
#import "DistrictOfficeDataSource.h"
#import "DistrictMap.h"
#import "DistrictMapImporter.h"
#import "TexLegeMapPins.h"
#endif

@interface DistrictMapDataSource()
@property (nonatomic, readonly) NSArray *sortDescriptors;
@end


@implementation DistrictMapDataSource
@synthesize hideTableIndex = _hideTableIndex;
@synthesize hasFilter = _hasFilter;
@synthesize filterChamber = _filterChamber;
@synthesize searchDisplayController = _searchDisplayController;

- (Class)dataClass
{
	return [DistrictMapObj class];
}

- (instancetype)init
{
	if ((self = [super init]))
    {
		_filterChamber = 0;
		_filterString = @"";
		_fetchedResultsController = nil;
		
#if NEEDS_TO_PARSE_KMLMAPS == 1

		DistrictOfficeDataSource *tempDistOff = [[[DistrictOfficeDataSource alloc] init] autorelease];
///#warning hacky place to put this, but we need to initialize district offices i guess? ....
		
		mapCount = 0;
		_importer = [[[DistrictMapImporter alloc] initWithChamber:SENATE dataSource:self] autorelease];
		
		_byDistrict = NO;
#endif
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(dataSourceReceivedMemoryWarning:)
													 name:UIApplicationDidReceiveMemoryWarningNotification object:nil];				
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(resetCoreData:) name:@"RESTKIT_LOADED_DISTRICTMAPOBJ" object:nil];		
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(resetCoreData:) name:@"RESTKIT_LOADED_LEGISLATOROBJ" object:nil];		
		
	}
	return self;
}

- (void)resetCoreData:(NSNotification *)notification
{
    NSFetchedResultsController *frc = self.fetchedResultsController;

    // You've got to delete the cache, or disable caching before you modify the predicate...
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

- (void)dataSourceReceivedMemoryWarning:(id)sender
{
	// let's give this a swinging shot....	
	for (NSManagedObject *object in self.fetchedResultsController.fetchedObjects) {
        [object.managedObjectContext refreshObject:object mergeChanges:NO];
	}
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];

#if NEEDS_TO_PARSE_KMLMAPS == 1
	self.importer = nil;
#endif
}

// return the data used by the navigation controller and tab bar item
- (NSString *)name
{ return NSLocalizedStringFromTable(@"District Maps", @"StandardUI", @"Short name for district maps tab"); }

- (NSString *)navigationBarName 
{ return self.name; }

- (UIImage *)tabBarImage
{ return [UIImage imageNamed:@"73-radar-inv.png"]; }

- (BOOL)showDisclosureIcon
{ return YES; }

- (BOOL)usesCoreData
{ return YES; }

- (BOOL)canEdit
{ return NO; }


// atomic number is displayed in a plain style tableview
- (UITableViewStyle)tableViewStyle
{
	return UITableViewStylePlain;
}

- (id)dataObjectForIndexPath:(NSIndexPath *)indexPath
{
    NSFetchedResultsController *frc = self.fetchedResultsController;
    NSArray<id <NSFetchedResultsSectionInfo>> *sections = frc.sections;
    
    id dataObject = nil;
    if (sections.count > indexPath.section)
    {
        id <NSFetchedResultsSectionInfo> section = sections[indexPath.section];
        if ([section numberOfObjects] > indexPath.row)
        {
            dataObject = [frc objectAtIndexPath:indexPath];
        }
    }
    if (dataObject)
        return dataObject;
    
    // possibly the predicate is filtering out what we need?
    [self removeFilter];

    @try {
        dataObject = SLValueIfClass(DistrictMapObj, [frc objectAtIndexPath:indexPath]);
    }
    @catch (NSException *exception) {
        return nil;
    }

    return dataObject;
}

- (NSIndexPath *)indexPathForDataObject:(id)dataObject
{
    if (!dataObject)
        return nil;
	NSIndexPath *indexPath = nil;
	@try {
		indexPath = [self.fetchedResultsController indexPathForObject:dataObject];
	}
	@catch (NSException * e) {
        indexPath = nil;
	}
	
	return indexPath;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	BOOL useDark = (indexPath.row % 2 == 0);
    NSString *reuseId = [TXLClickableSubtitleCell cellIdentifier];
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseId];
	if (cell == nil)
		cell = [[TXLClickableSubtitleCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseId];
    
	DistrictMapObj *tempEntry = [self dataObjectForIndexPath:indexPath];
	
	if (tempEntry == nil)
    {
		debug_NSLog(@"Busted in DistrictMapDataSource.m: cellForRowAtIndexPath -> Couldn't get object data for row.");
		return cell;
	}
	
	// let's override some of the datasource's settings ... specifically, the background color.
	cell.backgroundColor = useDark ? [TexLegeTheme backgroundDark] : [TexLegeTheme backgroundLight];
	
	NSString *localDist = NSLocalizedStringFromTable(@"District", @"StandardUI", @"The title for a legislative district, as in District 1");
	NSString *localAbbrev = abbreviateString(@"District");
	if (self.byDistrict)
		cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ %@ (%@)", localDist, 
									 [tempEntry valueForKey:@"district"], 
									 [tempEntry valueForKeyPath:@"legislator.lastname"]];
	else
		cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ (%@ %@)", 
									 [[tempEntry valueForKey:@"legislator"] legProperName], localAbbrev,
									 [tempEntry valueForKey:@"district"]];
	
	cell.textLabel.text = stringForChamber([[tempEntry valueForKey:@"chamber"] integerValue], TLReturnFull);
	
	
	cell.accessoryView.hidden = (tableView == self.searchDisplayController.searchResultsTableView);
	
	return cell;
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	NSInteger count = self.fetchedResultsController.sections.count;
	if (count > 0
        && !self.hasFilter
        && !self.byDistrict)
    {
		return count; 
	}
	return 1;	
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
	return nil;
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index
{
	return index;
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
	
	NSInteger count = tableView.numberOfSections;
    NSArray *sections = self.fetchedResultsController.sections;
    if (count > 0 &&
        sections.count > section &&
        !self.hasFilter &&
        !self.byDistrict)
    {
		id <NSFetchedResultsSectionInfo> sectionInfo = sections[section];
		return sectionInfo.indexTitle; // or [sectionInfo name];
	}
	return @"";
}

// do we want to do a proper whichFilter sort of thing?
- (BOOL)hasFilter
{
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
        [predString appendFormat:@"(chamber = %@)", @(self.filterChamber)];
    NSString *filterString = self.filterString;
    if (filterString.length > 0) {		// do some string filtering
        if (predString.length > 0)	// we already have some predicate action, insert "AND"
            [predString appendString:@" AND "];
        [predString appendFormat:@"((legislator.lastname CONTAINS[cd] '%@') OR (legislator.firstname CONTAINS[cd] '%@')", filterString, filterString];
        [predString appendFormat:@" OR (legislator.middlename CONTAINS[cd] '%@') OR (legislator.nickname CONTAINS[cd] '%@')", filterString, filterString];
        [predString appendFormat:@" OR (district CONTAINS[cd] '%@') OR (ANY legislator.districtOffices.formattedAddress CONTAINS [cd] '%@'))", filterString, filterString];
    }
    NSPredicate *predicate = (predString.length > 0) ? [NSPredicate predicateWithFormat:predString] : nil;
    return predicate;
}

- (void) updateFilterPredicate
{
    [self resetCoreData:nil];
}

- (void)setFilterByString:(NSString *)filter
{
    _filterString = [SLTypeNonEmptyStringOrNil(filter) copy];
	[self updateFilterPredicate];
}

- (void)removeFilter
{
    self.filterString = nil;
}

- (IBAction)sortByType:(id)sender
{
    [self resetCoreData:nil];
}

#if NEEDS_TO_PARSE_KMLMAPS == 1
#warning PARSE KML IS TURNED ON!!! MAKE SURE TO INCLUDE KMLs

- (void)checkDistrictMaps {
	
	for (DistrictMapObj *map in [TexLegeCoreDataUtils allDistrictMapsLight]) {
		if (!map.legislator) {
			debug_NSLog(@"district without a legislator!");
			assert(map.legislator);
			return;
		}
		
		if (![map boundingBoxContainsCoordinate:map.coordinate] || ![map districtContainsCoordinate:map.coordinate]) {
			//debug_NSLog(@"District %@ center is outside the district, finding appropriate district office...", map.district);
			
			BOOL foundOne = NO;
			for (DistrictOfficeObj *office in map.legislator.districtOffices) {
				if ([map boundingBoxContainsCoordinate:office.coordinate] && [map districtContainsCoordinate:office.coordinate]) {
					//debug_NSLog(@"Found one at %@", office.address);
					map.centerLat = office.latitude;
					map.centerLon = office.longitude;
					foundOne = YES;
					break;
				}
			}
            if (!foundOne) {
				debug_NSLog(@"District had no suitable offices inside the boundaries, district=%@ chamber=%@ legislator=%@", 
							map.district, map.chamber, map.legislator.lastname);
            }
		}
		
	}	 
 	// Save the context.
	NSError *error;
	if (![[DistrictMapObj rkManagedObjectContext] save:&error]) {
		// Handle the error...
	}
	
}


- (void)insertDistrictMaps:(NSArray *)districtMaps
{	
	NSManagedObjectContext *moc = [DistrictMapObj rkManagedObjectContext];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"DistrictMapObj" 
											  inManagedObjectContext:moc];
	
	
	// iterate over the values in the raw  dictionary
	for (DistrictMap * map in districtMaps)
	{
		// create an legislator instance for each
		DistrictMapObj *newObject = [NSEntityDescription insertNewObjectForEntityForName:
										 [entity name] inManagedObjectContext:moc];
		
//		CLLocationCoordinate2D *coordinatesCArray;
//		UIColor					*lineColor;

//		@property (nonatomic, retain) id lineColor;
		
		newObject.district = map.district;
		newObject.chamber = map.chamber;
		newObject.lineWidth = map.lineWidth;
				
		
		// regionDict
		newObject.centerLat = [NSNumber numberWithDouble:map.region.center.latitude];
		newObject.centerLon = [NSNumber numberWithDouble:map.region.center.longitude];
		newObject.spanLat = [NSNumber numberWithDouble:map.region.span.latitudeDelta];
		newObject.spanLon = [NSNumber numberWithDouble:map.region.span.longitudeDelta];
		
		// bounding box
		newObject.maxLat = [map.boundingBox valueForKey:@"maxLat"];
		newObject.minLat = [map.boundingBox valueForKey:@"minLat"];
		newObject.maxLon = [map.boundingBox valueForKey:@"maxLon"];
		newObject.minLon = [map.boundingBox valueForKey:@"minLon"];
		
		newObject.numberOfCoords = map.numberOfCoords;
		newObject.coordinatesData = [map.coordinatesData copy];
		
		LegislatorObj *legislatorObject = [TexLegeCoreDataUtils legislatorForDistrict:map.district andChamber:map.chamber withContext:context];
		if (legislatorObject) {
			newObject.legislator = legislatorObject;
			newObject.pinColorIndex = ([legislatorObject.party_id integerValue] == REPUBLICAN) ? [NSNumber numberWithInteger:TexLegePinAnnotationColorRed] : [NSNumber numberWithInteger:TexLegePinAnnotationColorBlue];
		}
		else {
			newObject.pinColorIndex = [NSNumber numberWithInteger:TexLegePinAnnotationColorGreen];
			debug_NSLog(@"No Legislator Found for chamber=%@ district=%@", map.chamber, map.district); 
		}

		
		mapCount++;
		
	}
	// Save the context.
	NSError *error;
	if (![moc save:&error]) {
		// Handle the error...
	}
	
	if (mapCount ==31) {
		self.importer = nil;
		self.importer = [[[DistrictMapImporter alloc] initWithChamber:HOUSE dataSource:self] autorelease];
	}
	
	if (mapCount == 181) {
		[self checkDistrictMaps];
	}
}

#endif

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
	[[NSNotificationCenter defaultCenter] postNotificationName:@"TABLEUPDATE_START" object:self];
	//    [self.tableView beginUpdates];
}
- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
	[[NSNotificationCenter defaultCenter] postNotificationName:@"TABLEUPDATE_END" object:self];
	//    [self.tableView endUpdates];
}

/*
 Set up the fetched results controller.
 */
- (NSArray *)sortDescriptors
{
	NSArray *descriptors = nil;
	if (self.byDistrict) {
		NSSortDescriptor *sort1 = [[NSSortDescriptor alloc] initWithKey:@"district" ascending:YES] ;
		NSSortDescriptor *sort2 = [[NSSortDescriptor alloc] initWithKey:@"chamber" ascending:NO] ;
		descriptors = @[sort1, sort2];
	}
	else {
		NSSortDescriptor *sort1 = [[NSSortDescriptor alloc] initWithKey:@"legislator.lastname" ascending:YES] ;
		NSSortDescriptor *sort2 = [[NSSortDescriptor alloc] initWithKey:@"legislator.firstname" ascending:YES] ;
		descriptors = @[sort1, sort2];
	}
	return descriptors;
}

- (NSFetchedResultsController *)fetchedResultsController {
    if (_fetchedResultsController != nil) {
        return _fetchedResultsController;
    }
	NSFetchRequest *fetchRequest = [DistrictMapObj rkFetchRequest];
	
	/* In reality, the light properties thing doesn't actually work without a DictionaryResultType
		However, you can't use a dictionary result in conjunction with change notification in the FRC.
		and we need change notification in order to make updating work ... so now we just have to rely
		on some judicious use of refreshObject: to clear the memory footprint
	 */
//	[fetchRequest setPropertiesToFetch:[DistrictMapObj lightPropertiesToFetch]];
//	[fetchRequest setResultType:NSDictionaryResultType];
	fetchRequest.sortDescriptors = [self sortDescriptors];

    NSString *cacheName = nil; // @"DistrictMaps"
	_fetchedResultsController = [[NSFetchedResultsController alloc]
															 initWithFetchRequest:fetchRequest 
															 managedObjectContext:[DistrictMapObj rkManagedObjectContext] 
															 sectionNameKeyPath:nil cacheName:cacheName];
	
    _fetchedResultsController.delegate = self;
	return _fetchedResultsController;
}    

@end
