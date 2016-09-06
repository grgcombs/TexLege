//
//  DistrictMapSearchOperation.h
//  Created by Gregory Combs on 9/1/10.
//
//  StatesLege by Sunlight Foundation, based on work at https://github.com/sunlightlabs/StatesLege
//
//  This work is licensed under the Creative Commons Attribution-NonCommercial 3.0 Unported License. 
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc/3.0/
//  or send a letter to Creative Commons, 444 Castro Street, Suite 900, Mountain View, California, 94041, USA.
//
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

typedef NS_ENUM(NSUInteger, DistrictMapSearchOperationFailOption) {
    DistrictMapSearchOperationFailOptionLog,
    DistrictMapSearchOperationShowAlert,

    DistrictMapSearchOperationFailOptionCount,
};

@class DistrictMapSearchOperation;

@protocol DistrictMapSearchOperationDelegate
- (void)districtMapSearchOperationDidFinishSuccessfully:(DistrictMapSearchOperation *)op;
- (void)districtMapSearchOperationDidFail:(DistrictMapSearchOperation *)op 
							 errorMessage:(NSString *)errorMessage 
								   option:(DistrictMapSearchOperationFailOption)failOption;
@end

@interface DistrictMapSearchOperation : NSOperation 

@property (nonatomic,unsafe_unretained) NSObject <DistrictMapSearchOperationDelegate> *delegate;
@property (nonatomic,assign) CLLocationCoordinate2D searchCoordinate;
@property (nonatomic,copy) NSArray *searchIDs;
@property (nonatomic,copy) NSMutableArray *foundIDs;

- (instancetype) initWithDelegate:(NSObject <DistrictMapSearchOperationDelegate> *)newDelegate
                       coordinate:(CLLocationCoordinate2D)aCoordinate searchDistricts:(NSArray *)districtIDs;

@end
