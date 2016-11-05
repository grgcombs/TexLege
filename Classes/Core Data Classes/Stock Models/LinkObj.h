//
//  LinkObj.h
//  Created by Gregory Combs on 1/22/11.
//
//  StatesLege by Sunlight Foundation, based on work at https://github.com/sunlightlabs/StatesLege
//
//  This work is licensed under the Creative Commons Attribution-NonCommercial 3.0 Unported License. 
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc/3.0/
//  or send a letter to Creative Commons, 444 Castro Street, Suite 900, Mountain View, California, 94041, USA.
//
//

#import "TexLege.h"
#import <RestKit/RestKit.h>
#import <RestKit/CoreData.h>


@interface LinkObj :  RKManagedObject  
{
}

@property (nonatomic, strong) NSString * label;
@property (nonatomic, strong) NSNumber * section;
@property (nonatomic, strong) NSNumber * sortOrder;
@property (nonatomic, strong) NSString * url;
@property (nonatomic, strong) NSString * updatedDate;

@end



