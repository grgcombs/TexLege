//
//  ChamberCalendarObj.h
//  Created by Gregory Combs on 8/12/10.
//
//  StatesLege by Sunlight Foundation, based on work at https://github.com/sunlightlabs/StatesLege
//
//  This work is licensed under the Creative Commons Attribution-NonCommercial 3.0 Unported License. 
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc/3.0/
//  or send a letter to Creative Commons, 444 Castro Street, Suite 900, Mountain View, California, 94041, USA.
//
//

#import "Kal.h"

@interface ChamberCalendarObj : NSObject <KalDataSource> {	
	NSMutableArray *rows;
	BOOL hasPostedAlert;
}

@property (nonatomic,retain) NSString *title;
@property (nonatomic,retain) NSNumber *chamber;

- (NSDictionary *)eventForIndexPath:(NSIndexPath*)indexPath;
- (NSArray *)filterEventsByString:(NSString *)filterString;
- (instancetype)initWithDictionary:(NSDictionary *)calendarDict;

@end
