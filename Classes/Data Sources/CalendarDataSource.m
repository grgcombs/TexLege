//
//  CalendarDataSource.m
//  Created by Gregory Combs on 7/27/10.
//  Copyright (c) 2010 Gregory S. Combs. All rights reserved.
//

#import "CalendarDataSource.h"
#import "UtilityMethods.h"
#import "TexLegeTheme.h"
#import "ChamberCalendarObj.h"
#import "DisclosureQuartzView.h"
#import "TexLegeAppDelegate.h"
#import "CalendarEventsLoader.h"
#import <SLToastKit/SLTypeCheck.h>

@interface CalendarDataSource()
@property (nonatomic,copy) NSArray<NSNumber *> *orderedChamberIDs;
@property (nonatomic,strong) NSDictionary<NSNumber *,ChamberCalendarObj *> *chamberCalendars;
@end

@implementation CalendarDataSource


- (NSString *)name
{
    return NSLocalizedStringFromTable(@"Meetings", @"StandardUI", @"The short title for buttons and tabs related to committee meetings (or calendar events)");
}

- (NSString *)navigationBarName 
{
    return NSLocalizedStringFromTable(@"Upcoming Meetings", @"StandardUI", @"The long title for buttons and tabs related to committee meetings (or calendar events)");
}

- (UIImage *)tabBarImage 
{
    return [UIImage imageNamed:@"83-calendar-inv.png"];
}

- (BOOL)showDisclosureIcon
{
    return YES;
}

- (BOOL)usesCoreData
{
    return NO;
}

- (BOOL)canEdit
{
    return NO;
}

- (UITableViewStyle)tableViewStyle
{
	return UITableViewStylePlain;
}

- (instancetype)init
{
	if ((self = [super init]))
    {
		[self loadChamberCalendars];
	}
	return self;
}

- (void)loadChamberCalendars
{
    NSArray<NSNumber *> *orderedChamberIDs = @[@(BOTH_CHAMBERS),
                                               @(HOUSE),
                                               @(SENATE),
                                               @(JOINT)];
    _orderedChamberIDs = orderedChamberIDs;

    NSCalendar *calendar = [NSCalendar autoupdatingCurrentCalendar];
    NSMutableDictionary<NSNumber *,ChamberCalendarObj *> *chamberCalendars = [[NSMutableDictionary alloc] init];

    for (NSNumber *chamberNumber in orderedChamberIDs)
    {
        TXLChamberType chamber = chamberNumber.unsignedIntValue;
        NSString *chamberName = stringForChamber(chamber, TLReturnFull);
        NSAssert1(chamberName != NULL, @"Should have a name for chamber (chamber = %d)", chamber);
        NSString *localizedString = [NSString stringWithFormat:NSLocalizedStringFromTable(@"%@ Upcoming Meetings", @"DataTableUI", nil), chamberName];
        NSDictionary *dictionary = @{@"title": localizedString, @"chamber": chamberNumber};
        ChamberCalendarObj *meetingsContainer = [[ChamberCalendarObj alloc] initWithDictionary:dictionary calendar:calendar];
        if (!meetingsContainer)
            continue;
        chamberCalendars[chamberNumber] = meetingsContainer;
    }
    _chamberCalendars = [chamberCalendars copy];

    [[CalendarEventsLoader sharedCalendarEventsLoader] loadEvents:self];
}

- (id)dataObjectForIndexPath:(NSIndexPath *)indexPath
{
    NSArray *chamberIDs = self.orderedChamberIDs;
    if (chamberIDs.count > indexPath.row)
    {
        NSNumber *chamberID = chamberIDs[indexPath.row];
        return self.chamberCalendars[chamberID];
    }
    return nil;
}

- (NSIndexPath *)indexPathForDataObject:(id)dataObject
{
    ChamberCalendarObj *chamberObject = SLValueIfClass(ChamberCalendarObj, dataObject);
    if (!chamberObject)
        return nil;
    __block NSUInteger row = NSNotFound;
    [self.orderedChamberIDs enumerateObjectsUsingBlock:^(NSNumber *chamberID, NSUInteger idx, BOOL * stop) {
        ChamberCalendarObj *item = self.chamberCalendars[chamberID];
        if (item && [item isEqual:chamberObject])
        {
            row = idx;
            *stop = YES;
        }
    }];

    if (row == NSNotFound)
        return nil;
    return [NSIndexPath indexPathForRow:row inSection:0];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{		
	static NSString *CellIdentifier = @"Cell";

	/* Look up cell in the table queue */
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	
	/* Not found in queue, create a new cell object */
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
		cell.textLabel.textColor =	[TexLegeTheme textDark];
		cell.textLabel.textAlignment = NSTextAlignmentLeft;

        static UIFont *bold15 = nil;
        if (!bold15)
            bold15 = [UIFont boldSystemFontOfSize:15];
		cell.textLabel.font = bold15;
		
		cell.selectionStyle = UITableViewCellSelectionStyleBlue;
		cell.textLabel.adjustsFontSizeToFitWidth = YES;
        cell.textLabel.minimumScaleFactor = (12.0 / bold15.pointSize);
		DisclosureQuartzView *qv = [[DisclosureQuartzView alloc] initWithFrame:CGRectMake(0.f, 0.f, 28.f, 28.f)];
		cell.accessoryView = qv;

    }

	BOOL useDark = (indexPath.row % 2 == 0);
	cell.backgroundColor = useDark ? [TexLegeTheme backgroundDark] : [TexLegeTheme backgroundLight];

	ChamberCalendarObj *calendar = [self dataObjectForIndexPath:indexPath];
	if (calendar)
        cell.textLabel.text = calendar.title;
		
	return cell;
}


- (NSInteger)tableView:(UITableView *)tableView  numberOfRowsInSection:(NSInteger)section 
{
    if (section > 0)
        return 0;
	return self.chamberCalendars.count;
}

@end
