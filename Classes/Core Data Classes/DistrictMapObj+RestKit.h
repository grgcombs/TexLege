//
//  DistrictMapObj.h
//  Created by Gregory Combs on 8/21/10.
//
//  StatesLege by Sunlight Foundation, based on work at https://github.com/sunlightlabs/StatesLege
//
//  This work is licensed under the Creative Commons Attribution-NonCommercial 3.0 Unported License. 
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc/3.0/
//  or send a letter to Creative Commons, 444 Castro Street, Suite 900, Mountain View, California, 94041, USA.
//
//

#import "DistrictMapObj.h"

@interface DistrictMapObj (RestKit)
{
}

- (void)resetRelationship:(id)sender;

#if 0 // this doesn't work like it used to -- can't get real objects with propertiesToFetch: anymore.
+ (NSArray *)lightPropertiesToFetch;
#endif

//- (id) initWithCoder: (NSCoder *)coder;
//- (void)encodeWithCoder:(NSCoder *)coder;	

@end



