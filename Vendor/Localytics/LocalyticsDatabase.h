//
//  LocalyticsDatabase.h
//  LocalyticsDemo
//
//  Created by jkaufman on 5/26/11.
//  Copyright 2011 Localytics. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>

@interface LocalyticsDatabase : NSObject {
    sqlite3 *_databaseConnection;
    NSRecursiveLock *_dbLock;
    NSRecursiveLock *_transactionLock;
}

+ (LocalyticsDatabase *)sharedLocalyticsDatabase;

@property (NS_NONATOMIC_IOSONLY, readonly) NSUInteger databaseSize;
@property (NS_NONATOMIC_IOSONLY, readonly) int eventCount;
@property (NS_NONATOMIC_IOSONLY, readonly) NSTimeInterval createdTimestamp;

- (BOOL)beginTransaction:(NSString *)name;
- (BOOL)releaseTransaction:(NSString *)name;
- (BOOL)rollbackTransaction:(NSString *)name;

- (BOOL)incrementLastUploadNumber:(int *)uploadNumber;
- (BOOL)incrementLastSessionNumber:(int *)sessionNumber;

- (BOOL)addEventWithBlobString:(NSString *)blob;
- (BOOL)addCloseEventWithBlobString:(NSString *)blob;
- (BOOL)addFlowEventWithBlobString:(NSString *)blob;
@property (NS_NONATOMIC_IOSONLY, readonly) BOOL removeLastCloseAndFlowEvents;

- (BOOL)addHeaderWithSequenceNumber:(int)number blobString:(NSString *)blob rowId:(sqlite3_int64 *)insertedRowId;
@property (NS_NONATOMIC_IOSONLY, readonly) int unstagedEventCount;
- (BOOL)stageEventsForUpload:(sqlite3_int64)headerId;
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSString *uploadBlobString;
@property (NS_NONATOMIC_IOSONLY, readonly) BOOL deleteUploadData;

@property (NS_NONATOMIC_IOSONLY, readonly) NSTimeInterval lastSessionStartTimestamp;
- (BOOL)setLastsessionStartTimestamp:(NSTimeInterval)timestamp;

- (BOOL)isOptedOut;
- (BOOL)setOptedOut:(BOOL)optOut;
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSString *installId;

- (NSString *)customDimension:(int)dimension;
- (BOOL)setCustomDimension:(int)dimension value:(NSString *)value;

@end
