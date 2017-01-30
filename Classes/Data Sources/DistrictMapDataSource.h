//
//  DistrictMapDataSource.h
//  Created by Gregory Combs on 8/23/10.
//
//  StatesLege by Sunlight Foundation, based on work at https://github.com/sunlightlabs/StatesLege
//
//  This work is licensed under the Creative Commons Attribution-NonCommercial 3.0 Unported License. 
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc/3.0/
//  or send a letter to Creative Commons, 444 Castro Street, Suite 900, Mountain View, California, 94041, USA.
//
//

#import "TableDataSourceProtocol.h"

#if NEEDS_TO_PARSE_KMLMAPS == 1
@class DistrictMapImporter;
#endif

@interface DistrictMapDataSource : NSObject <TableDataSource>

@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;

@property (nonatomic,copy) NSString *filterString;	// nil or empty means don't filter
@property (nonatomic,assign) BOOL byDistrict;

- (void)removeFilter;
- (IBAction)sortByType:(id)sender;

#if NEEDS_TO_PARSE_KMLMAPS == 1
- (void)insertDistrictMaps:(NSArray *)districtMaps;
@property (nonatomic, strong) DistrictMapImporter *importer;
@property (nonatomic, assign) SInt16 mapCount;
#endif

@end
