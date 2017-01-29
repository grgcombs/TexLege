//
//  BillsMenuDataSource.m
//  Created by Gregory Combs on 2/16/11.
//
//  StatesLege by Sunlight Foundation, based on work at https://github.com/sunlightlabs/StatesLege
//
//  This work is licensed under the Creative Commons Attribution-NonCommercial 3.0 Unported License. 
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc/3.0/
//  or send a letter to Creative Commons, 444 Castro Street, Suite 900, Mountain View, California, 94041, USA.
//
//

#import "BillsMenuDataSource.h"
#import "TexLegeAppDelegate.h"
#import "TexLegeTheme.h"
#import "TexLegeStandardGroupCell.h"
#import "TexLegeAppDelegate.h"

@implementation BillsMenuDataSource

@synthesize menuItems = _menuItems/*, searchDisplayController*/;

enum _menuOrder {
	kMenuFavorites = 0,
	kMenuKeyBills,
	kMenuRecent,
	kMenuCategories,
	kMenuLASTITEM
};

// TableDataSourceProtocol methods

// return the data used by the navigation controller and tab bar item
- (NSString *)name
{ return NSLocalizedStringFromTable(@"Bills", @"StandardUI", @"Short name for bills (legislative documents, pre-law) tab"); }

- (NSString *)navigationBarName 
{ return self.name; }

- (UIImage *)tabBarImage 
{ return [UIImage imageNamed:@"gavel-inv.png"]; }

- (BOOL)showDisclosureIcon
{ return YES; }

- (BOOL)usesCoreData
{ return NO; }

- (BOOL)canEdit
{ return NO; }

// displayed in a plain style tableview
- (UITableViewStyle)tableViewStyle {
	return UITableViewStylePlain;
}

- (instancetype)init {
	if ((self = [super init])) {
	}
	return self;
}



/* Build a list of files */
- (NSArray *)menuItems {
	if (!_menuItems) {
			
		NSString *thePath = [[NSBundle mainBundle]  pathForResource:@"TexLegeStrings" ofType:@"plist"];
		NSDictionary *textDict = [NSDictionary dictionaryWithContentsOfFile:thePath];
		_menuItems = textDict[@"BillMenuItems"];
		
		if (!_menuItems)
			_menuItems = [[NSArray alloc] init];
	}
	return _menuItems;
}


// return the map at the index in the array
- (id) dataObjectForIndexPath:(NSIndexPath *)indexPath {
    if (self.menuItems.count <= indexPath.row)
        return nil;
	return (self.menuItems)[indexPath.row];
}

- (NSIndexPath *)indexPathForDataObject:(id)dataObject {	
	NSIndexPath *path = [NSIndexPath indexPathForRow:0 inSection:0];

	if (dataObject) {
		NSString *theClass = nil;
		if ([dataObject isKindOfClass:[NSDictionary class]])
			theClass = dataObject[@"class"];
		else if ([dataObject isKindOfClass:[NSString class]])
			theClass = dataObject;
		
		NSInteger row = 0;
		for (NSDictionary *object in self.menuItems) {
			if ([theClass isEqualToString:object[@"class"]])
				path = [NSIndexPath indexPathForRow:row inSection:0];
			row++;
		}		
	}
	return path;
}

#pragma mark -
#pragma mark UITableViewDataSource methods

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{		
	NSString *CellIdentifier = [TXLClickableSubtitleCell cellIdentifier];
	
	/* Look up cell in the table queue */
    TXLClickableSubtitleCell *cell = (TXLClickableSubtitleCell*)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	
	/* Not found in queue, create a new cell object */
    if (cell == nil) {
        cell = [[TXLClickableSubtitleCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
		cell.textLabel.textColor =	[TexLegeTheme textDark];
		cell.textLabel.font = [TexLegeTheme boldFifteen];				
    }
	BOOL useDark = (indexPath.row % 2 == 0);
	
	cell.backgroundColor = useDark ? [TexLegeTheme backgroundDark] : [TexLegeTheme backgroundLight];
	
	NSDictionary *dataObject = [self dataObjectForIndexPath:indexPath];
    if (dataObject)
    {
        cell.detailTextLabel.text = dataObject[@"title"];
        cell.imageView.image = [UIImage imageNamed:dataObject[@"icon"]];
    }
	return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView  numberOfRowsInSection:(NSInteger)section 
{		
	return (self.menuItems).count;
}

@end
