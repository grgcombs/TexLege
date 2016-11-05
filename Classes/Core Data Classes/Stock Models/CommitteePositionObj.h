//
//  CommitteePositionObj.h
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

@class CommitteeObj;
@class LegislatorObj;

@interface CommitteePositionObj :  RKManagedObject  
{
}

@property (nonatomic, strong) NSString * updatedDate;
@property (nonatomic, strong) NSNumber * position;
@property (nonatomic, strong) NSNumber * legislatorID;
@property (nonatomic, strong) NSNumber * committeePositionID;
@property (nonatomic, strong) NSNumber * committeeId;
@property (nonatomic, strong) CommitteeObj * committee;
@property (nonatomic, strong) LegislatorObj * legislator;

@end



