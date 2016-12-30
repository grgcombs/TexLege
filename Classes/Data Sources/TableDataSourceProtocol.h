//
//  TableDataSourceProtocol.h
//  Created by Gregory Combs on 7/22/09.
//
//  StatesLege by Sunlight Foundation, based on work at https://github.com/sunlightlabs/StatesLege
//
//  This work is licensed under the Creative Commons Attribution-NonCommercial 3.0 Unported License. 
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc/3.0/
//  or send a letter to Creative Commons, 444 Castro Street, Suite 900, Mountain View, California, 94041, USA.
//
//

#import "LegislatorObj.h"
#import "CommitteeObj.h"
#import "CapitolMap.h"
#import "LinkObj.h"
#import "ChamberCalendarObj.h"

@protocol TableDataSource <UITableViewDataSource, NSFetchedResultsControllerDelegate>
 
@required

// these properties are used by the view controller
// for the navigation and tab bar
@property (NS_NONATOMIC_IOSONLY,readonly) NSString *name;
@property (NS_NONATOMIC_IOSONLY,readonly) NSString *navigationBarName;
@property (NS_NONATOMIC_IOSONLY,readonly) UIImage *tabBarImage;

// this property determines the style of table view displayed
@property (NS_NONATOMIC_IOSONLY,readonly) UITableViewStyle tableViewStyle;
@property (NS_NONATOMIC_IOSONLY,readonly) BOOL usesCoreData;
@property (NS_NONATOMIC_IOSONLY,readonly) BOOL canEdit;

@property (NS_NONATOMIC_IOSONLY, readonly) BOOL showDisclosureIcon;

@optional
@property (NS_NONATOMIC_IOSONLY, readonly) Class dataClass;

@property (NS_NONATOMIC_IOSONLY, readonly) BOOL hasFilter;
- (void) setFilterByString:(NSString *)filter;
- (void) removeFilter;

@property (NS_NONATOMIC_IOSONLY, assign) NSInteger filterChamber;		// 0 means don't filter
@property (NS_NONATOMIC_IOSONLY, strong) UISearchDisplayController *searchDisplayController;
@property (NS_NONATOMIC_IOSONLY, strong) NSFetchedResultsController *fetchedResultsController;

- (void)initializeDatabase;

// this optional protocol allows us to send the datasource this message, since it has the 
// required information
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section;

- (id)dataObjectForIndexPath:(NSIndexPath*)indexPath;
- (NSIndexPath *)indexPathForDataObject:(id)dataObject;

// implement these for editing...
- (void)setEditing:(BOOL)isEditing animated:(BOOL)animated;
- (NSIndexPath *)tableView:(UITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath;
- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath;

// set this on when you don't want to see the index, ala keyboard active
@property (NS_NONATOMIC_IOSONLY,assign) BOOL hideTableIndex;

- (void)resetData:(NSNotification *)notification;

@end
