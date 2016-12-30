//
//  StafferObj.h
//  Created by Gregory Combs on 1/22/11.
//
//  StatesLege by Sunlight Foundation, based on work at https://github.com/sunlightlabs/StatesLege
//
//  This work is licensed under the Creative Commons Attribution-NonCommercial 3.0 Unported License. 
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc/3.0/
//  or send a letter to Creative Commons, 444 Castro Street, Suite 900, Mountain View, California, 94041, USA.
//
//

#import <SLFRestKit/SLFRestKit.h>

@class LegislatorObj;

@interface StafferObj :  NSManagedObject

@property (nonatomic, strong) NSNumber *stafferID;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *phone;
@property (nonatomic, strong) NSString *email;
@property (nonatomic, strong) NSString *updatedDate;
@property (nonatomic, strong) NSNumber *legislatorID;
@property (nonatomic, strong) LegislatorObj *legislator;

@end



