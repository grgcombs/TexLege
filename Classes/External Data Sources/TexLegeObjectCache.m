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
#import "TexLegePrivateStrings.h"

@implementation TexLegeObjectCache

- (NSFetchRequest *)fetchRequestForResourcePath:(NSString*)resourcePath
{
    if (!resourcePath || ![resourcePath isKindOfClass:[NSString class]])
        return nil;

#if USE_PRIVATE_MYSQL_SERVER
    NSString *modelString = [resourcePath lastPathComponent];
#else
    if (![resourcePath hasSuffix:@".json"])
        return nil;

    NSString *filename = resourcePath.lastPathComponent;
    NSString *modelString = [filename stringByDeletingPathExtension];
#endif
    Class modelClass = NSClassFromString(modelString);
    if (!modelClass)
        return nil;

    NSFetchRequest* request = [modelClass fetchRequest];
    NSString *primaryKeyName = [modelClass primaryKeyProperty];
    //NSPredicate* predicate = [NSPredicate predicateWithFormat:@"%@ = %@", primaryKey, ID, nil];
    //request.predicate = predicate;
    NSSortDescriptor *sortByPrimaryKey = [NSSortDescriptor sortDescriptorWithKey:primaryKeyName ascending:YES] ;
    request.sortDescriptors = @[sortByPrimaryKey];
    return request;
}

@end
