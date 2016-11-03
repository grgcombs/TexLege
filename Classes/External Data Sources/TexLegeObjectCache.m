//
//  TexLegeObjectCache.m
//  Created by Gregory Combs on 3/21/11.
//
//  StatesLege by Sunlight Foundation, based on work at https://github.com/sunlightlabs/StatesLege
//
//  This work is licensed under the Creative Commons Attribution-NonCommercial 3.0 Unported License. 
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc/3.0/
//  or send a letter to Creative Commons, 444 Castro Street, Suite 900, Mountain View, California, 94041, USA.
//
//

#import "TexLegeObjectCache.h"

#import "LegislatorObj.h"
#import "CommitteeObj.h"
#import "CommitteePositionObj.h"
#import "DistrictMapObj.h"
#import "DistrictOfficeObj.h"
#import "StafferObj.h"
#import "WnomObj.h"
#import "LinkObj.h"
#import "NSDate+Helper.h"
#import "UtilityMethods.h"

@implementation TexLegeObjectCache


- (NSArray*)fetchRequestsForResourcePath:(NSString*)resourcePath {
	
	//BOOL onlyID = NO;
	if (YES == [resourcePath hasPrefix:@"/rest_ids.php"]) {	//??????
		//resourcePath = [resourcePath substringFromIndex:[@"/rest_ids.php/" length]];
		//onlyID = YES;
		return nil;			/// ???????????
	}
	else
		resourcePath = [resourcePath substringFromIndex:(@"/rest.php/").length];		
					
	NSArray* components = [resourcePath componentsSeparatedByString:@"/"];
	NSInteger count = components.count;
	NSString *modelString = components[0];
	Class modelClass = NSClassFromString(modelString);
	if (!modelClass)
		return nil;
	
	NSString *primaryKey = [modelClass primaryKeyProperty];

	if (count > 1) {
		NSString *params = components[1];
		if ([params hasPrefix:@"?"]) {
			NSDictionary *paramsDict = [UtilityMethods parametersOfQuery:params];	// chop off the ?

			if ([paramsDict.allKeys containsObject:@"updated_since"]) {
				NSString* updatedString = [paramsDict[@"updated_since"] stringByReplacingPercentEscapesUsingEncoding:NSASCIIStringEncoding];
				NSDate *updatedDate = [NSDate dateFromString:updatedString];
				NSFetchRequest* request = [modelClass fetchRequest];
				NSPredicate* predicate = [NSPredicate predicateWithFormat:@"updatedDate >= %@", updatedDate, nil];
				request.predicate = predicate;
				NSSortDescriptor* sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:primaryKey ascending:YES];
				request.sortDescriptors = @[sortDescriptor];
				return @[request];
			}
		}
		else {
			NSNumber* ID = @(params.intValue);
			NSFetchRequest* request = [modelClass fetchRequest];
			NSPredicate* predicate = [NSPredicate predicateWithFormat:@"%@ = %@", primaryKey, ID, nil];
			request.predicate = predicate;
			NSSortDescriptor *one = [NSSortDescriptor sortDescriptorWithKey:primaryKey ascending:YES] ;
			request.sortDescriptors = @[one];
			return @[request];
			
		}

	}	
	return nil;
}

@end
