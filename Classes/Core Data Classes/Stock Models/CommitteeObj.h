//
//  CommitteeObj.h
//  Created by Gregory Combs on 1/22/11.
//
//  StatesLege by Sunlight Foundation, based on work at https://github.com/sunlightlabs/StatesLege
//
//  This work is licensed under the Creative Commons Attribution-NonCommercial 3.0 Unported License. 
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc/3.0/
//  or send a letter to Creative Commons, 444 Castro Street, Suite 900, Mountain View, California, 94041, USA.
//
//

#import <CoreData/CoreData.h>

@class CommitteePositionObj;

@interface CommitteeObj :  NSManagedObject  

@property (nonatomic, strong) NSString * clerk_email;
@property (nonatomic, strong) NSString * phone;
@property (nonatomic, strong) NSNumber * committeeType;
@property (nonatomic, strong) NSString * updatedDate;
@property (nonatomic, strong) NSNumber * committeeId;
@property (nonatomic, strong) NSNumber * votesmartID;
@property (nonatomic, strong) NSString * url;
@property (nonatomic, strong) NSString * office;
@property (nonatomic, strong) NSString * clerk;
@property (nonatomic, strong) NSString * committeeName;
@property (nonatomic, strong) NSString * openstatesID;
@property (nonatomic, strong) NSString * txlonline_id;
@property (nonatomic, strong) NSString * committeeNameInitial;
@property (nonatomic, strong) NSNumber * parentId;
@property (nonatomic, strong) NSSet* committeePositions;

@end


@interface CommitteeObj (CoreDataGeneratedAccessors)

- (void)addCommitteePositionsObject:(CommitteePositionObj *)value;
- (void)removeCommitteePositionsObject:(CommitteePositionObj *)value;
- (void)addCommitteePositions:(NSSet *)value;
- (void)removeCommitteePositions:(NSSet *)value;

@end

