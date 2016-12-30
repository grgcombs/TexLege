//
//  CapitolMapsDataSource.m
//  Created by Gregory Combs on 7/22/09.
//
//  StatesLege by Sunlight Foundation, based on work at https://github.com/sunlightlabs/StatesLege
//
//  This work is licensed under the Creative Commons Attribution-NonCommercial 3.0 Unported License. 
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc/3.0/
//  or send a letter to Creative Commons, 444 Castro Street, Suite 900, Mountain View, California, 94041, USA.
//
//

#import "CapitolMapsDataSource.h"
#import "TexLegeAppDelegate.h"
#import "TexLegeTheme.h"
#import "TexLegeStandardGroupCell.h"

@interface CapitolMapsDataSource()
@end

@implementation CapitolMapsDataSource

// TableDataSourceProtocol methods

- (NSString *)name 
{ return NSLocalizedStringFromTable(@"Capitol Maps", @"StandardUI", @"The short title for buttons and tabs related to maps of the building"); }

- (NSString *)navigationBarName 
{ return self.name; }

- (UIImage *)tabBarImage 
{ return [UIImage imageNamed:@"103-map-inv.png"]; }

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

- (instancetype)init
{
	if ((self = [super init]))
    {
		[self createSectionList];
	}
	return self;
}

/* Build a list of files */
- (void)createSectionList
{
    NSMutableArray *sectionList = [[NSMutableArray alloc] init];

    @autoreleasepool {
        NSString *thePath = [[NSBundle mainBundle] pathForResource:@"CapitolMaps" ofType:@"plist"];
        NSArray *mapSectionsPlist = [[NSArray alloc] initWithContentsOfFile:thePath];

        for (NSArray * section in mapSectionsPlist)
        {
            NSMutableArray *tempSection = [[NSMutableArray alloc] initWithCapacity:section.count];

            for (NSDictionary * mapEntry in section)
            {
                CapitolMap *newMap = [[CapitolMap alloc] init];
                [newMap importFromDictionary:mapEntry];
                [tempSection addObject:newMap];
            }
            [sectionList addObject:tempSection];
        }
        
    }
    _sectionList = sectionList;
}


// return the map at the index in the array
- (id) dataObjectForIndexPath:(NSIndexPath *)indexPath
{
    NSArray *sectionList = self.sectionList;
    if (sectionList.count <= indexPath.section)
        return nil;
	NSArray *thisSection = sectionList[indexPath.section];
	if (thisSection && thisSection.count > indexPath.row)
		return thisSection[indexPath.row];
	
	return nil;
}

- (NSIndexPath *)indexPathForDataObject:(id)dataObject
{
    NSArray *sectionList = self.sectionList;
	NSInteger section = 0;
	NSInteger row = 0;
	
	if (dataObject && [dataObject isKindOfClass:[CapitolMap class]])
    {
		section = [[dataObject valueForKey:@"type"] integerValue];
        if (sectionList.count <= section)
            return nil;
		NSArray *thisSection = sectionList[section];
        row = [thisSection indexOfObject:dataObject];
        if (row == NSNotFound)
            row = 0;
	}
	return [NSIndexPath indexPathForRow:row inSection:section];
}

#pragma mark -
#pragma mark UITableViewDataSource methods

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{		
	static NSString *CellIdentifier = @"Cell";
	
	/* Look up cell in the table queue */
    TexLegeStandardGroupCell *cell = (TexLegeStandardGroupCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	
	/* Not found in queue, create a new cell object */
    if (cell == nil) {
        cell = [[TexLegeStandardGroupCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
		cell.textLabel.textColor =	[TexLegeTheme textDark];
		cell.textLabel.font = [TexLegeTheme boldFifteen];
    }
	BOOL useDark = (indexPath.row % 2 == 0);

	cell.backgroundColor = useDark ? [TexLegeTheme backgroundDark] : [TexLegeTheme backgroundLight];

    CapitolMap *map = [self dataObjectForIndexPath:indexPath];
    if (map)
        cell.textLabel.text = map.name;
				 
	return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	// Three sections
	return (self.sectionList).count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
    NSArray *sections = self.sectionList;
    if (sections.count <= section)
        return 0;
	return [sections[section] count];
}

 - (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {	
	if (section == 0)
		return NSLocalizedStringFromTable(@"Interior Maps", @"DataTableUI", @"Cell title for interor maps of a building (office locations)");
	else //if (section == 1)
		return NSLocalizedStringFromTable(@"Exterior Maps", @"DataTableUI", @"Cell title for outside maps of a building (outdoor locations)");
}

@end
