//
//  CapitolMap.h
//  Created by Gregory Combs on 7/11/10.
//
//  StatesLege by Sunlight Foundation, based on work at https://github.com/sunlightlabs/StatesLege
//
//  This work is licensed under the Creative Commons Attribution-NonCommercial 3.0 Unported License. 
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc/3.0/
//  or send a letter to Creative Commons, 444 Castro Street, Suite 900, Mountain View, California, 94041, USA.
//
//

#import <Foundation/Foundation.h>


@interface CapitolMap : NSObject
{
	NSString *m_name;
	NSString *m_file;
	NSNumber *m_type;
	NSNumber *m_order;
}

@property (nonatomic,strong) NSString *name;
@property (nonatomic,strong) NSString *file;
@property (nonatomic,strong) NSNumber *type;
@property (nonatomic,strong) NSNumber *order;
@property (weak, nonatomic,readonly) NSURL *url;

+ (CapitolMap *)	mapFromOfficeString:(NSString *)office;
- (void)			importFromDictionary:(NSDictionary *)dictionary;
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSDictionary *exportToDictionary;
	
@end

