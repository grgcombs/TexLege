//
//  SLFInfoPanelManager.m
//  OpenStates
//
//  Created by Gregory Combs on 7/8/16.
//  Copyright © 2016 Sunlight Foundation. All rights reserved.
//

#import "SLFInfoPanelManager.h"
#import "SLFObjectQueue.h"
#import "SLFInfoItem.h"
#import "SLFTypeCheck.h"
#import "SLFInfoView.h"

@interface SLFInfoPanelManager()
@property (nonatomic,copy) SLFObjectQueue <SLFInfoItem *> *infoQueue;
@property (nonatomic,copy,nonnull) NSString *managerId;
@property (nonatomic,strong) SLFInfoView *infoView;
@end

static SLFInfoPanelManager* _internalSharedManager = nil;

@implementation SLFInfoPanelManager

+ (void)setSharedInfoManager:(SLFInfoPanelManager *)manager
{
    _internalSharedManager = manager;
}

+ (SLFInfoPanelManager*)sharedInfoManager
{
    return _internalSharedManager;
}

- (instancetype)initWithManagerId:(NSString *)managerId parentView:(UIView *)parentView
{
    self = [super init];
    if (self)
    {
        if (!SLFTypeNonEmptyStringOrNil(managerId))
            managerId = @"DefaultInfoPanelManager";
        _managerId = [managerId copy];
        _parentView = parentView;

        NSString *queueName = [managerId stringByAppendingString:@"-Queue"];
        _infoQueue = [[SLFObjectQueue alloc] initWithName:queueName];
    }
    return self;
}

- (instancetype)init
{
    self = [self initWithManagerId:@"" parentView:nil];
    return self;
}

- (void)dealloc
{
    SLFInfoView *infoView = _infoView;
    if (infoView)
        infoView.infoManager = nil;

    // In case consumers need to check the status of their retained info items
    for (SLFInfoItem *item in self.infoQueue)
    {
        if (item.status != SLFInfoStatusQueued
            && item.status != SLFInfoStatusFinished)
        {
            item.status = SLFInfoStatusUnknown;
        }
    }
}

- (NSUInteger)infoItemCount
{
    return self.infoQueue.count;
}

- (NSUInteger)activeItemCount
{
    NSUInteger itemCount = 0;
    for (SLFInfoItem *item in self.infoQueue)
    {
        switch (item.status) {
            case SLFInfoStatusQueued:
            case SLFInfoStatusShowing:
                itemCount++;
                break;
            case SLFInfoStatusUnknown:
            case SLFInfoStatusFinished:
                break;
        }
        if (item.status != SLFInfoStatusQueued
            && item.status != SLFInfoStatusFinished)
        {
            item.status = SLFInfoStatusUnknown;
        }
    }
    return itemCount;
}

- (nullable SLFInfoItem *)currentInfoItem
{
    SLFInfoItem *viewItem = self.infoView.infoItem;
    if (viewItem)
    {
        if (viewItem.status == SLFInfoStatusShowing
            || viewItem.status == SLFInfoStatusQueued)
        {
            return viewItem;
        }
    }

    SLFInfoItem *foundItem = nil;
    for (SLFInfoItem *item in self.infoQueue)
    {
        if (item.status == SLFInfoStatusShowing)
        {
            foundItem = item;
            break;
        }
    }
    return foundItem;
}

- (void)setParentView:(UIView *)parentView
{
    UIView *oldView = _parentView;
    _parentView = parentView;
    if (!parentView)
        return;
    if (oldView && [oldView isEqual:parentView])
        return;
    if (self.activeItemCount == 0)
        return;
    [self showInfoViewIfPossible];
}

- (BOOL)addInfoItem:(nonnull SLFInfoItem *)item
{
    if (!SLFValueIfClass(SLFInfoItem, item) || ![item isValid])
        return NO;

    [self.infoQueue push:item];
    item.status = SLFInfoStatusQueued;
    BOOL success = YES;

    UIView *parentView = self.parentView;
    if (!parentView)
        return success; // we've queued it and will show once we have a parentView

    success = [self showInfoViewIfPossible];

    return success;
}

- (BOOL)removeInfoItem:(nonnull SLFInfoItem *)item
{
    if (!SLFValueIfClass(SLFInfoItem, item))
        return NO;
    BOOL success = [self.infoQueue removeObject:item];
    if (item.status == SLFInfoStatusQueued)
        item.status = SLFInfoStatusUnknown;
    return success;
}

- (nullable SLFInfoItem *)pullNextItem
{
    // do something with status?
    return [self.infoQueue pop];
}

- (BOOL)showInfoViewIfPossible
{
    if (!self.activeItemCount)
        return NO;

    SLFInfoView *infoView = self.infoView;
    if (infoView
        && infoView.superview
        && infoView.infoItem
        && infoView.infoItem.status == SLFInfoStatusShowing)
    {
        if (!infoView.infoManager)
            infoView.infoManager = self;
        return YES;
    }

    UIView *parentView = self.parentView;
    if (!parentView)
        return NO; // At least, *not yet*. We've already queued it and will show once we have a parentView

    SLFInfoItem *infoItem = [self pullNextItem];
    if (!infoItem)
        return NO; // should we log an error or exception? This should be impossible.

    SLFInfoViewCompletion onCompletion = ^(SLFInfoStatus status, SLFInfoItem * _Nonnull item) {
        // is this block useful?  It would only return the most recent item shown (i.e. a 'tapped' item in the middle of the queue).
    };
    if (!infoView)
    {
        infoView = [SLFInfoView showInfoInView:parentView infoItem:infoItem completion:onCompletion];
        if (infoView)
        {
            infoView.infoManager = self;
            self.infoView = infoView;
            return YES;
        }
    }
    if (!infoView.infoManager)
        infoView.infoManager = self;
    return [infoView showInfoItem:infoItem completion:onCompletion];
}

@end
