//
//  CapitolMap.m
//  Created by Gregory Combs on 7/11/10.
//
//  StatesLege by Sunlight Foundation, based on work at https://github.com/sunlightlabs/StatesLege
//
//  This work is licensed under the Creative Commons Attribution-NonCommercial 3.0 Unported License. 
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc/3.0/
//  or send a letter to Creative Commons, 444 Castro Street, Suite 900, Mountain View, California, 94041, USA.
//
//

#import "CapitolMap.h"


@implementation CapitolMap
@synthesize name = m_name, file = m_file, type = m_type, order = m_order;

+ (CapitolMap *) mapFromOfficeString:(NSString *)office {
	NSString *fileString = nil;
	NSString *thePath = [[NSBundle mainBundle] pathForResource:@"CapitolMaps" ofType:@"plist"];
	NSArray *mapSectionsPlist = [NSArray arrayWithContentsOfFile:thePath];	
	NSArray *searchArray = mapSectionsPlist[0];
	CapitolMap *foundMap = nil;
	
	if ([office hasPrefix:@"4"])
		fileString = @"Map.Floor4.pdf";
	else if ([office hasPrefix:@"3"])
		fileString = @"Map.Floor3.pdf";
	else if ([office hasPrefix:@"2"])
		fileString = @"Map.Floor2.pdf";
	else if ([office hasPrefix:@"1"])
		fileString = @"Map.Floor1.pdf";
	else if ([office hasPrefix:@"G"])
		fileString = @"Map.FloorG.pdf";
	else if ([office hasPrefix:@"E1."])
		fileString = @"Map.FloorE1.pdf";
	else if ([office hasPrefix:@"E2."])
		fileString = @"Map.FloorE2.pdf";
	else if ([office hasPrefix:@"SHB"]) {
		fileString = @"Map.SamHoustonLoc.pdf";
		searchArray = mapSectionsPlist[1];
	}
	
	for (NSDictionary * mapEntry in searchArray)
	{
		if ([fileString isEqualToString:[mapEntry valueForKey:@"file"]]) {
			foundMap = [[CapitolMap alloc] init];
			[foundMap importFromDictionary:mapEntry];
			break;
		}
	}
	return foundMap;
}


- (void)importFromDictionary:(NSDictionary *)dictionary
{				
	if (dictionary) {
		self.name = dictionary[@"name"];
		self.file = dictionary[@"file"];
		self.type = dictionary[@"type"];
		self.order = dictionary[@"order"];
	}
}


- (NSDictionary *)exportToDictionary {
	NSDictionary *tempDict = @{@"name": self.name,
							  @"file": self.file,
							  @"type": self.type,
							  @"order": self.order};
	return tempDict;
}
/*
- (id)proxyForJson {
    return [self exportToDictionary];
}
*/

- (NSURL *)url
{
    return [[NSBundle mainBundle] URLForResource:(self.file).stringByDeletingPathExtension
                                   withExtension:(self.file).pathExtension];
}

@end
