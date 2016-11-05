//
//  DirectoryDetailCell.h
//  Created by Gregory S. Combs on 5/31/09.
//
//  StatesLege by Sunlight Foundation, based on work at https://github.com/sunlightlabs/StatesLege
//
//  This work is licensed under the Creative Commons Attribution-NonCommercial 3.0 Unported License. 
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc/3.0/
//  or send a letter to Creative Commons, 444 Castro Street, Suite 900, Mountain View, California, 94041, USA.
//
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(UInt32, DirectoryType) {
    DirectoryTypeNone = 0,
    DirectoryTypeNotes,
    DirectoryTypeIndex,
    DirectoryTypeCommittee,
    DirectoryTypeContributions,
    DirectoryTypeBills,

    // URL types go below here
    kDirectoryTypeIsURLHandler,
    DirectoryTypeOfficeMap,
    DirectoryTypeWeb,
    DirectoryTypeTwitter,
    kDirectoryTypeIsExternalHandler,
    DirectoryTypeMap,
    DirectoryTypeMail,
    DirectoryTypePhone,
    DirectoryTypeSMS,
};


@interface TableCellDataObject : NSObject

@property (nonatomic, strong) id entryValue;
@property (nonatomic) BOOL isClickable;
@property (nonatomic) NSInteger entryType;
@property (nonatomic, strong) id action;
@property (nonatomic, strong) id parameter;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *subtitle;
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSURL *generateURL;

- (instancetype)initWithDictionary:(NSDictionary *)aDictionary;


@end
