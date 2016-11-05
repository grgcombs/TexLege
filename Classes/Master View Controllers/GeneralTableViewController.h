//
//  GeneralTableViewController.h
//  Created by Gregory Combs on 7/10/09.
//
//  StatesLege by Sunlight Foundation, based on work at https://github.com/sunlightlabs/StatesLege
//
//  This work is licensed under the Creative Commons Attribution-NonCommercial 3.0 Unported License. 
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc/3.0/
//  or send a letter to Creative Commons, 444 Castro Street, Suite 900, Mountain View, California, 94041, USA.
//
//


#import "TableDataSourceProtocol.h"
#import "TXLDetailProtocol.h"

@interface GeneralTableViewController : UITableViewController <UITableViewDelegate>

@property (nonatomic,strong) IBOutlet id<TableDataSource> dataSource;
@property (nonatomic,strong) IBOutlet UIViewController<TXLDetailProtocol> *detailViewController;
@property (nonatomic,strong) id initialObjectToSelect;
@property (nonatomic,strong) NSNumber *controllerEnabled;

@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSString *reachabilityStatusKey;

- (void)configure;
- (void)runLoadView;
@property (NS_NONATOMIC_IOSONLY, readonly, weak) Class dataSourceClass;
- (IBAction)selectDefaultObject:(id)sender;
@property (NS_NONATOMIC_IOSONLY, readonly, strong) id firstDataObject;
- (void)reapplyFiltersAndSort;
- (void)beginUpdates:(NSNotification *)aNotification;
- (void)endUpdates:(NSNotification *)aNotification;

@end
