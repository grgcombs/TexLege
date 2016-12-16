//
//  SLFInfoView.m
//  OpenStates iOS
//
//  Created by Gregory Combs on 7/10/16 for the Sunlight Foundation.
//  Based in part on MTInfoPanel from Matthias Tretter.
//

#import "SLFInfoView.h"
#import <QuartzCore/QuartzCore.h>
#import "SLFTypeCheck.h"
#import "UIColor+SLFUtils.h"

@interface SLFInfoView ()

@property (nonatomic, strong, nullable) SLFInfoItem *infoItem;
@property (nonatomic, assign) SLFInfoType infoType;
@property (nonatomic, strong) UIColor *gradientStartColor;
@property (nonatomic, strong) UIColor *gradientEndColor;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *detailLabel;
@property (nonatomic, strong) UIImageView *thumbImage;
@property (nonatomic, strong) UIView *backgroundGradient;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;
@property (nonatomic, copy) SLFInfoViewCompletion onCompletion;
@property (nonatomic, strong) NSArray<NSLayoutConstraint *> *infoConstraints;

@end

@implementation SLFInfoView

+ (instancetype)showInfoInView:(UIView *)parentView
                      infoItem:(SLFInfoItem *)infoItem
                    completion:(nullable SLFInfoViewCompletion)completion
{
    if (!parentView || !infoItem)
        return nil;

    SLFInfoView *infoView = [self staticInfoViewWithFrame:parentView.bounds infoItem:infoItem];
    if (!infoView)
        return nil;

    infoView.onCompletion = completion;

    [parentView addSubview:infoView];

    NSTimeInterval duration = infoItem.duration;
    if (duration > 0)
    {
        __weak SLFInfoView *wView = infoView;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(duration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            __strong SLFInfoView *sView = wView;
            if (!sView)
                return;
            if (!infoItem || ![sView.infoItem isEqual:infoItem] || infoItem.status == SLFInfoStatusFinished)
                return;  // The info item has changed since we posted it, so this execution won't fit the desired duration
            [sView hideInfoView];
        });
    }

    return infoView;
}

+ (instancetype)showInfoInWindow:(UIWindow*)window
                        infoItem:(SLFInfoItem *)infoItem
                      completion:(nullable SLFInfoViewCompletion)completion
{
    SLFInfoView *infoView = [self showInfoInView:window infoItem:infoItem completion:completion];
    if (!infoView)
        return nil;

    if (![UIApplication sharedApplication].statusBarHidden)
    {
        CGRect frame = infoView.frame;
        frame.origin.y += CGRectGetHeight([UIApplication sharedApplication].statusBarFrame);
        infoView.frame = frame;
    }

    return infoView;
}

- (BOOL)showInfoItem:(SLFInfoItem *)infoItem completion:(nullable SLFInfoViewCompletion)completion

{
    UIView *parentView = self.superview;
    
    if (!parentView || !infoItem)
        return NO;
    
    self.infoItem = infoItem;
    infoItem.status = SLFInfoStatusShowing;

    NSTimeInterval duration = infoItem.duration;
    if (duration > 0)
    {
        __weak SLFInfoView *wView = self;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(duration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            __strong SLFInfoView *sView = wView;
            if (!sView)
                return;
            if (!infoItem || ![sView.infoItem isEqual:infoItem] || infoItem.status == SLFInfoStatusFinished)
                return;  // The info item has changed since we posted it, so this execution won't fit the desired duration
            [sView hideInfoView];
        });
    }

    return YES;
}

+ (instancetype)showInfoInView:(UIView *)view
                          type:(SLFInfoType)type
                         title:(nullable NSString *)title
                      subtitle:(nullable NSString *)subtitle
                         image:(nullable UIImage *)image
                     hideAfter:(NSTimeInterval)interval
{
    if (!view)
        return nil;
    if (!title)
        title = @"";
    if (!subtitle)
        subtitle = @"";
    if (!image)
        image = (UIImage *)[NSNull null];

    NSString *compositeId = [NSString stringWithFormat:@"|type=%@|title=%@|subtitle=%@|", @(type),title,subtitle];
    SLFInfoItem *item = [[SLFInfoItem alloc] initWithIdentifier:compositeId type:type title:title subtitle:subtitle image:image duration:interval];
    if (!item)
        return nil;

    return [self showInfoInView:view infoItem:item completion:nil];
}

- (void)setInfoItem:(SLFInfoItem *)infoItem
{
    _infoItem = infoItem;
    if (!infoItem)
        return;
    [self setType:infoItem.type title:infoItem.title subtitle:infoItem.subtitle];

    if (SLFTypeImageOrNil(infoItem.image))
        self.thumbImage.image = infoItem.image;

    [self invalidateIntrinsicContentSize];
    [self setNeedsUpdateConstraints];
    [self setNeedsLayout];
}

+ (instancetype)staticInfoViewWithFrame:(CGRect)frame infoItem:(SLFInfoItem *)infoItem
{
    SLFInfoView *infoView = [SLFInfoView infoViewWithFrame:frame infoItem:infoItem];
    return infoView;
}

+ (instancetype)staticInfoViewWithFrame:(CGRect)frame
                                   type:(SLFInfoType)type
                                  title:(nullable NSString *)title
                               subtitle:(nullable NSString *)subtitle
                                  image:(nullable UIImage *)image
{
    NSString *compositeId = [NSString stringWithFormat:@"|type=%@|title=%@|subtitle=%@|", @(type),title,subtitle];
    SLFInfoItem *item = [[SLFInfoItem alloc] initWithIdentifier:compositeId type:type title:title subtitle:subtitle image:image duration:-1];
    if (!item)
        return nil;

    return [self staticInfoViewWithFrame:frame infoItem:item];
}

+ (instancetype)showInfoInWindow:(UIWindow *)window
                             type:(SLFInfoType)type
                            title:(nullable NSString *)title
                         subtitle:(nullable NSString *)subtitle
{
    return [self showInfoInWindow:window type:type title:title subtitle:subtitle hideAfter:-1];
}

+ (instancetype)showInfoInWindow:(UIWindow *)window
                             type:(SLFInfoType)type
                            title:(nullable NSString *)title
                         subtitle:(nullable NSString *)subtitle
                        hideAfter:(NSTimeInterval)interval
{
    return [self showInfoInWindow:window type:type title:title subtitle:subtitle image:nil hideAfter:interval];
}

+ (instancetype)showInfoInWindow:(UIWindow*)window
                             type:(SLFInfoType)type
                            title:(nullable NSString *)title
                         subtitle:(nullable NSString *)subtitle
                            image:(nullable UIImage *)image
{
    return [self showInfoInWindow:window type:type title:title subtitle:subtitle image:image hideAfter:-1.];
}

+ (instancetype)showInfoInWindow:(UIWindow*)window
                            type:(SLFInfoType)type
                           title:(nullable NSString *)title
                        subtitle:(nullable NSString *)subtitle
                           image:(nullable UIImage *)image
                       hideAfter:(NSTimeInterval)interval
{
    SLFInfoView *infoView = [self showInfoInView:window type:type title:title subtitle:subtitle image:image hideAfter:interval];

    if (![UIApplication sharedApplication].statusBarHidden)
    {
        CGRect frame = infoView.frame;
        frame.origin.y += CGRectGetHeight([UIApplication sharedApplication].statusBarFrame);
        infoView.frame = frame;
    }

    return infoView;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:frame]))
    {
        [self setup];
    }

    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if ((self = [super initWithCoder:aDecoder]))
    {
        [self setup];
    }

    return self;
}

////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark UIView
////////////////////////////////////////////////////////////////////////

- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];

    // update width of layers to allow rotation to landscape
    for (CALayer *layer in self.backgroundGradient.layer.sublayers)
    {
        if ([layer isKindOfClass:[CAGradientLayer class]])
        {
            CGRect layerFrame = layer.frame;
            layerFrame.size.width = CGRectGetWidth(frame);
            layer.frame = layerFrame;
        }
    }
}

////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Setter/Getter
////////////////////////////////////////////////////////////////////////

- (void)setType:(SLFInfoType)type
          title:(NSString *)title
       subtitle:(NSString *)subtitle
{
#if 0
    CGRect frame = self.frame;

    // view height when no subtitle set
    CGFloat viewHeight = 50.f;

    self.infoType = type;
    self.titleLabel.text = title;
    subtitle = [subtitle stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

    if (subtitle.length > 0)
    {
        self.detailLabel.text = subtitle;
        [self.detailLabel sizeToFit];
        self.detailLabel.hidden = NO;

        viewHeight = MAX(CGRectGetMaxY(self.thumbImage.frame), CGRectGetMaxY(self.detailLabel.frame));
        // padding at bottom
        viewHeight += 7.f;
    }
    else
    {
        self.detailLabel.hidden = YES;
        self.thumbImage.frame = CGRectMake(15, 5, 35, 35);
        self.titleLabel.frame = CGRectMake(57, 12, 240, 21);
    }
    //    if (image != nil) {
    //        self.thumbImage.image = image;
    //    }

    self.frame = CGRectMake(frame.origin.x, frame.origin.y, frame.size.width, viewHeight);
    [self setBackgroundGradientFrom:self.gradientStartColor to:self.gradientEndColor];

#endif

    self.infoType = type;
    self.titleLabel.text = SLFTypeNonEmptyStringOrNil(title);
    subtitle = SLFTypeNonEmptyStringOrNil([subtitle stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]);
    self.detailLabel.text = subtitle;

    //self.frame = CGRectMake(frame.origin.x, frame.origin.y, frame.size.width, viewHeight);

    [self invalidateIntrinsicContentSize];
    [self setNeedsUpdateConstraints];
    [self setNeedsLayout];
}

- (void)setInfoType:(SLFInfoType)infoType
{
    _infoType = infoType;

    UIColor *titleColor = [UIColor whiteColor];
    UIColor *startColor = nil;
    UIColor *endColor = nil;
    UIColor *detailColor = nil;
    UIImage *image = nil;

    switch (infoType) {
        case SLFInfoTypeActivity:
        {
            startColor = SLFColorWithRGBA(117,177,165,1.0);  //SLFColorWithRGBA(91, 134, 206, 1.0);
            endColor = SLFColorWithRGBA(91,138,129,1.0);     //SLFColorWithRGBA(69, 106, 177, 1.0);
            detailColor = SLFColorWithRGBA(245,245,237,1.0); //SLFColorWithRGBA(210, 210, 235, 1.0);
            titleColor = detailColor;
            _activityIndicator.color = detailColor;
            image = nil;
            break;
        }

        case SLFInfoTypeInfo:
        {
            startColor = SLFColorWithRGBA(117,177,165,1.0);  //SLFColorWithRGBA(91, 134, 206, 1.0);
            endColor = SLFColorWithRGBA(91,138,129,1.0);     //SLFColorWithRGBA(69, 106, 177, 1.0);
            detailColor = SLFColorWithRGBA(245,245,237,1.0); //SLFColorWithRGBA(210, 210, 235, 1.0);
            titleColor = detailColor;
            image = [UIImage imageNamed:@"info"];
            break;
        }

        case SLFInfoTypeNotice:
        {
            startColor = SLFColorWithRGBA(118, 119, 120, 1.0);
            endColor = SLFColorWithRGBA(63, 65, 67, 1.0);
            detailColor = SLFColorWithRGBA(210, 210, 235, 1.0);
            image = [UIImage imageNamed:@"notice"];
            break;
        }

        case SLFInfoTypeSuccess:
        {
            startColor = SLFColorWithRGBA(127, 191, 34, 1.0);
            endColor = SLFColorWithRGBA(136, 159, 86, 1.0);
            detailColor = SLFColorWithRGBA(59, 69, 39, 1.0);
            image = [UIImage imageNamed:@"checkmark"];
            break;
        }


        case SLFInfoTypeWarning:
        {
            startColor = SLFColorWithRGBA(253, 178, 77, 1.0);
            endColor = SLFColorWithRGBA(196, 123, 20, 1.0);
            detailColor = SLFColorWithRGBA(97, 61, 24, 1.0);
            image = [UIImage imageNamed:@"warning"];
            break;
        }

        case SLFInfoTypeError:
        default:
        {
            startColor = SLFColorWithRGBA(200, 36, 0, 1.0);
            endColor = SLFColorWithRGBA(150, 24, 0, 1.0);
            detailColor = SLFColorWithRGBA(255, 166, 166, 1.0);
            image = [UIImage imageNamed:@"warning"];
            break;
        }
    }

    image = SLFTypeImageOrNil(image);
    _thumbImage.image = image;
    _thumbImage.hidden = (!image);

    _gradientStartColor = startColor;
    _gradientEndColor = endColor;

    _titleLabel.textColor = titleColor;
    _titleLabel.font = [UIFont boldSystemFontOfSize:14];

    _detailLabel.textColor = detailColor;
    _detailLabel.font = [UIFont systemFontOfSize:14];

    if (infoType == SLFInfoTypeActivity)
        [_activityIndicator startAnimating];
    else
        [_activityIndicator stopAnimating];
}

- (void)setBackgroundGradientFrom:(UIColor *)fromColor to:(UIColor *)toColor
{
    if (!fromColor || !toColor)
        return;

    CAGradientLayer *gradient = [CAGradientLayer layer];
    CGFloat lineHeight = 1.f;
    UIColor *lightColor = [self changeColor:fromColor withFactor:1.2];
    UIColor *darkColor = [self changeColor:toColor withFactor:0.25];

    UIView *gradientView = self.backgroundGradient;
    CGRect gradientRect = gradientView.bounds;
    CGFloat gradientWidth = CGRectGetWidth(gradientRect);
    CGFloat gradientHeight = CGRectGetHeight(gradientRect);
    gradient.frame = gradientRect;
    gradient.colors = @[(id)[fromColor CGColor], (id)[toColor CGColor]];

    CAGradientLayer *darkTopLine = [CAGradientLayer layer];
    darkTopLine.frame = CGRectMake(0, 0, gradientWidth, lineHeight);
    darkTopLine.colors = @[(id)[darkColor CGColor], (id)[darkColor CGColor]];

    CAGradientLayer *lightTopLine = [CAGradientLayer layer];
    lightTopLine.frame = CGRectMake(0, 1, gradientWidth, lineHeight);
    lightTopLine.colors = @[(id)[lightColor CGColor], (id)[lightColor CGColor]];

    CAGradientLayer *darkEndLine = [CAGradientLayer layer];
    darkEndLine.frame = CGRectMake(0, gradientHeight - lineHeight, gradientWidth, lineHeight);
    darkEndLine.colors = @[(id)[darkColor CGColor], (id)[darkColor CGColor]];

    NSArray *sublayers = [gradientView.layer.sublayers copy];
    for (CALayer *layer in sublayers)
    {
        [layer removeFromSuperlayer];
    }
    [gradientView.layer insertSublayer:gradient atIndex:0];
    [gradientView.layer insertSublayer:darkTopLine atIndex:1];
    [gradientView.layer insertSublayer:lightTopLine atIndex:2];
    [gradientView.layer insertSublayer:darkEndLine atIndex:3];
}

- (UIColor *)changeColor:(UIColor *)sourceColor withFactor:(CGFloat)factor
{
    // oldComponents is the array INSIDE the original color. Changing these mutates the source color, so we copy it
    CGFloat *oldComponents = (CGFloat *)CGColorGetComponents([sourceColor CGColor]);
    size_t numComponents = CGColorGetNumberOfComponents([sourceColor CGColor]);
    CGFloat newComponents[4] = {0.f,0.f,0.f,0.f};

    switch (numComponents) {
        case 2: {
            //grayscale
            newComponents[0] = oldComponents[0]*factor;
            newComponents[1] = oldComponents[0]*factor;
            newComponents[2] = oldComponents[0]*factor;
            newComponents[3] = oldComponents[1];
            break;
        }

        case 4: {
            //RGBA
            newComponents[0] = oldComponents[0]*factor;
            newComponents[1] = oldComponents[1]*factor;
            newComponents[2] = oldComponents[2]*factor;
            newComponents[3] = oldComponents[3];
            break;
        }
    }

    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGColorRef newColor = CGColorCreate(colorSpace, newComponents);
    CGColorSpaceRelease(colorSpace);

    UIColor *retColor = [UIColor colorWithCGColor:newColor];
    CGColorRelease(newColor);

    return retColor;
}

#if 0

-(void)hideInfoView
{
    //   [NSObject cancelPreviousPerformRequestsWithTarget:self];

    CATransition *transition = [CATransition animation];
    transition.duration = 0.25;
    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    transition.type = kCATransitionPush;
    transition.subtype = kCATransitionFromTop;
    [self.layer addAnimation:transition forKey:nil];

    self.frame = CGRectMake(0, -self.frame.size.height, self.frame.size.width, self.frame.size.height);

    [self performSelector:@selector(finish)
               withObject:nil
               afterDelay:transition.duration];
}

#else

-(void)hideInfoView
{
    //   [NSObject cancelPreviousPerformRequestsWithTarget:self];

    SLFInfoPanelManager *manager = self.infoManager;
    if (manager)
    {
        SLFInfoItem *nextItem = [manager pullNextItem];
        if (nextItem)
        {
            if (self.infoItem && ![self.infoItem isEqual:nextItem])
            {
                self.infoItem.status = SLFInfoStatusFinished;
            }
            [self showInfoItem:nextItem completion:self.onCompletion];
            return;
        }
    }

    NSTimeInterval duration = 0.25;
    CGRect oldRect = self.frame;
    CGRect newRect = oldRect;
    newRect.origin =  CGPointMake(0,-CGRectGetHeight(oldRect));

    UIViewAnimationOptions options = (UIViewAnimationOptionCurveEaseInOut |
                                      UIViewAnimationOptionLayoutSubviews |
                                      UIViewAnimationOptionAllowAnimatedContent |
                                      UIViewAnimationOptionShowHideTransitionViews);

    __weak typeof(self) wSelf = self;
    [UIView animateWithDuration:duration delay:0 options:options animations:^{
        __strong typeof(wSelf) sSelf = wSelf;
        if (!sSelf)
            return;
        sSelf.frame = newRect;
    } completion:^(BOOL finished) {
        __strong typeof(wSelf) sSelf = wSelf;
        if (!sSelf)
            return;
        [sSelf finish];
    }];
}

#endif

- (void)finish
{
    SLFInfoStatus status = SLFInfoStatusFinished;
    SLFInfoItem *item = self.infoItem;
    if (item)
        item.status = status;
    if (self.onCompletion)
    {
        self.onCompletion(status, item);
    }

    [self removeFromSuperview];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self hideInfoView];
}

+ (instancetype)infoViewWithFrame:(CGRect)frame infoItem:(SLFInfoItem *)infoItem;
{
    SLFInfoView *infoView =  [[SLFInfoView alloc] initWithFrame:frame];

    CATransition *transition = [CATransition animation];
    transition.duration = 0.25;
    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    transition.type = kCATransitionPush;
    transition.subtype = kCATransitionFromBottom;
    [infoView.layer addAnimation:transition forKey:nil];

    if (infoItem)
    {
        infoView.infoItem = infoItem;

        CGSize fittingSize = (CGSize){CGRectGetWidth(frame),UILayoutFittingCompressedSize.height};
        CGSize size = [infoView systemLayoutSizeFittingSize:fittingSize
                              withHorizontalFittingPriority:UILayoutPriorityRequired
                                    verticalFittingPriority:UILayoutPriorityDefaultHigh + 50];
        frame.size = size;
        infoView.frame = frame;
    }

    return infoView;
}

#if 0
UIKIT_EXTERN const CGSize UILayoutFittingCompressedSize NS_AVAILABLE_IOS(6_0);
UIKIT_EXTERN const CGSize UILayoutFittingExpandedSize NS_AVAILABLE_IOS(6_0);

/* The size fitting most closely to targetSize in which the receiver's subtree can be laid out while optimally satisfying the constraints. If you want the smallest possible size, pass UILayoutFittingCompressedSize; for the largest possible size, pass UILayoutFittingExpandedSize.
 Also see the comment for UILayoutPriorityFittingSizeLevel.
 */
- (CGSize)systemLayoutSizeFittingSize:(CGSize)targetSize NS_AVAILABLE_IOS(6_0); // Equivalent to sending -systemLayoutSizeFittingSize:withHorizontalFittingPriority:verticalFittingPriority: with UILayoutPriorityFittingSizeLevel for both priorities.
- (CGSize)systemLayoutSizeFittingSize:(CGSize)targetSize withHorizontalFittingPriority:(UILayoutPriority)horizontalFittingPriority verticalFittingPriority:(UILayoutPriority)verticalFittingPriority NS_AVAILABLE_IOS(8_0);


+ (instancetype)infoView
{
    return [self infoViewWithFrame:CGRectMake(0.f, 0.f, 320.f, 50.f) infoItem:nil];
}
#endif

- (void)updateConstraints
{
    [super updateConstraints];
    if (_infoConstraints.count)
        [NSLayoutConstraint deactivateConstraints:_infoConstraints];

    [self setContentHuggingPriority:900 forAxis:UILayoutConstraintAxisVertical];
    [self setContentCompressionResistancePriority:760 forAxis:UILayoutConstraintAxisVertical];

    NSMutableArray<NSLayoutConstraint *> *constraints = [[NSMutableArray alloc] init];

    NSLayoutConstraint *constraint = nil;
    NSLayoutAttribute attribute = NSLayoutAttributeNotAnAttribute;
    NSString *constraintGroupID = nil;

    constraintGroupID = @"SLFInfoView-MinSize";
    {
        attribute = NSLayoutAttributeHeight;
        constraint = [NSLayoutConstraint constraintWithItem:self attribute:attribute
                                                  relatedBy:NSLayoutRelationGreaterThanOrEqual
                                                     toItem:nil attribute:NSLayoutAttributeNotAnAttribute
                                                 multiplier:1 constant:50];
        constraint.identifier = constraintGroupID;
        [constraints addObject:constraint];
    }

    constraintGroupID = @"SLFInfoView-Background";
    {
        NSArray *attributes = @[@(NSLayoutAttributeTop),
                                @(NSLayoutAttributeLeading),
                                @(NSLayoutAttributeBottom),
                                @(NSLayoutAttributeTrailing)];

        for (NSNumber *attributeValue in attributes)
        {
            attribute = [attributeValue integerValue];
            constraint = [NSLayoutConstraint constraintWithItem:_backgroundGradient attribute:attribute
                                                      relatedBy:NSLayoutRelationEqual
                                                         toItem:self attribute:attribute
                                                     multiplier:1 constant:0];
            constraint.identifier = constraintGroupID;
            [constraints addObject:constraint];
        }
    }

    UIEdgeInsets marginInsets = UIEdgeInsetsMake(6, 10, 6, 10);

    constraintGroupID = @"SLFInfoView-Image";
    {
        //CGRectMake(9, 9, 37.f, 34.f)

        attribute = NSLayoutAttributeLeading;
        constraint = [NSLayoutConstraint constraintWithItem:_thumbImage attribute:attribute
                                                  relatedBy:NSLayoutRelationEqual
                                                     toItem:self attribute:attribute
                                                 multiplier:1 constant:marginInsets.left];
        constraint.identifier = constraintGroupID;
        [constraints addObject:constraint];

        attribute = NSLayoutAttributeCenterY;
        constraint = [NSLayoutConstraint constraintWithItem:_thumbImage attribute:attribute
                                                  relatedBy:NSLayoutRelationEqual
                                                     toItem:self attribute:attribute
                                                 multiplier:1 constant:0];
        constraint.identifier = constraintGroupID;
        [constraints addObject:constraint];

        attribute = NSLayoutAttributeWidth;
        constraint = [NSLayoutConstraint constraintWithItem:_thumbImage attribute:attribute
                                                  relatedBy:NSLayoutRelationEqual
                                                     toItem:nil attribute:NSLayoutAttributeNotAnAttribute
                                                 multiplier:1 constant:37];
        constraint.identifier = constraintGroupID;
        [constraints addObject:constraint];

        attribute = NSLayoutAttributeHeight;
        constraint = [NSLayoutConstraint constraintWithItem:_thumbImage attribute:attribute
                                                  relatedBy:NSLayoutRelationEqual
                                                     toItem:nil attribute:NSLayoutAttributeNotAnAttribute
                                                 multiplier:1 constant:37];
        constraint.identifier = constraintGroupID;
        [constraints addObject:constraint];
    }

    constraintGroupID = @"SLFInfoView-Activity";
    {
        attribute = NSLayoutAttributeCenterY;
        constraint = [NSLayoutConstraint constraintWithItem:_activityIndicator attribute:attribute
                                                  relatedBy:NSLayoutRelationEqual
                                                     toItem:_thumbImage attribute:attribute
                                                 multiplier:1 constant:0];
        constraint.identifier = constraintGroupID;
        [constraints addObject:constraint];

        attribute = NSLayoutAttributeCenterX;
        constraint = [NSLayoutConstraint constraintWithItem:_activityIndicator attribute:attribute
                                                  relatedBy:NSLayoutRelationEqual
                                                     toItem:_thumbImage attribute:attribute
                                                 multiplier:1 constant:0];
        constraint.identifier = constraintGroupID;
        [constraints addObject:constraint];
    }

    constraintGroupID = @"SLFInfoView-Title";
    {
        constraint = [NSLayoutConstraint constraintWithItem:_titleLabel attribute:NSLayoutAttributeLeading
                                                  relatedBy:NSLayoutRelationEqual
                                                     toItem:_thumbImage attribute:NSLayoutAttributeTrailing
                                                 multiplier:1 constant:marginInsets.left];
        constraint.identifier = constraintGroupID;
        [constraints addObject:constraint];

        constraint = [NSLayoutConstraint constraintWithItem:_titleLabel attribute:NSLayoutAttributeTrailing
                                                  relatedBy:NSLayoutRelationEqual
                                                     toItem:self attribute:NSLayoutAttributeTrailing
                                                 multiplier:1 constant:-(marginInsets.right)];
        constraint.identifier = constraintGroupID;
        [constraints addObject:constraint];

        constraint = [NSLayoutConstraint constraintWithItem:_titleLabel attribute:NSLayoutAttributeTop
                                                  relatedBy:NSLayoutRelationEqual
                                                     toItem:self attribute:NSLayoutAttributeTop
                                                 multiplier:1 constant:marginInsets.top];
        constraint.identifier = constraintGroupID;
        [constraints addObject:constraint];
    }

    constraintGroupID = @"SLFInfoView-Subtitle";
    {
        constraint = [NSLayoutConstraint constraintWithItem:_detailLabel attribute:NSLayoutAttributeLeading
                                                  relatedBy:NSLayoutRelationEqual
                                                     toItem:_thumbImage attribute:NSLayoutAttributeTrailing
                                                 multiplier:1 constant:marginInsets.left];
        constraint.identifier = constraintGroupID;
        [constraints addObject:constraint];

        constraint = [NSLayoutConstraint constraintWithItem:_detailLabel attribute:NSLayoutAttributeTrailing
                                                  relatedBy:NSLayoutRelationEqual
                                                     toItem:self attribute:NSLayoutAttributeTrailing
                                                 multiplier:1 constant:-(marginInsets.right)];
        constraint.identifier = constraintGroupID;
        [constraints addObject:constraint];

        constraint = [NSLayoutConstraint constraintWithItem:_detailLabel attribute:NSLayoutAttributeTop
                                                  relatedBy:NSLayoutRelationEqual
                                                     toItem:_titleLabel attribute:NSLayoutAttributeBottom
                                                 multiplier:1 constant:marginInsets.top];
        constraint.identifier = constraintGroupID;
        [constraints addObject:constraint];

        constraint = [NSLayoutConstraint constraintWithItem:_detailLabel attribute:NSLayoutAttributeBottom
                                                  relatedBy:NSLayoutRelationEqual
                                                     toItem:self attribute:NSLayoutAttributeBottom
                                                 multiplier:1 constant:-(marginInsets.bottom)];
        constraint.identifier = constraintGroupID;
        [constraints addObject:constraint];
    }

    _infoConstraints = constraints;
    [NSLayoutConstraint activateConstraints:constraints];
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    self.titleLabel.preferredMaxLayoutWidth = CGRectGetWidth(self.titleLabel.frame);
    self.detailLabel.preferredMaxLayoutWidth = CGRectGetWidth(self.detailLabel.frame);

    [self setBackgroundGradientFrom:self.gradientStartColor to:self.gradientEndColor];
}

- (void)setup
{
    self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
    self.opaque = NO;
    self.layer.shadowOffset = CGSizeMake(0.f, 2.f);
    self.layer.shadowRadius = 2.5f;
    self.layer.shadowOpacity = 0.7;

    CGRect bounds = self.bounds;
    if (!_backgroundGradient || !_backgroundGradient.superview)
    {
        _backgroundGradient = [[UIView alloc] initWithFrame:bounds];
        _backgroundGradient.translatesAutoresizingMaskIntoConstraints = NO;
        //_backgroundGradient.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _backgroundGradient.alpha = 0.88f;
        [self addSubview:_backgroundGradient];
    }

    if (!_titleLabel || !_titleLabel.superview)
    {
        _titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _titleLabel.backgroundColor = [UIColor clearColor];
        _titleLabel.font = [UIFont boldSystemFontOfSize:14];
        _titleLabel.numberOfLines = 1;
        _titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        _titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
        //_titleLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
        _titleLabel.layer.shadowOffset = CGSizeMake(0.f, -1.f);
        _titleLabel.layer.shadowColor = [UIColor blackColor].CGColor;
        _titleLabel.layer.shadowRadius = 1.f;
        _titleLabel.layer.shadowOpacity = 0.7;
        [_titleLabel setContentHuggingPriority:900 forAxis:UILayoutConstraintAxisVertical];
        [_titleLabel setContentCompressionResistancePriority:920 forAxis:UILayoutConstraintAxisVertical];

        [self addSubview:_titleLabel];
    }

    if (!_detailLabel || !_detailLabel.superview)
    {
        _detailLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _detailLabel.backgroundColor = [UIColor clearColor];
        _detailLabel.font = [UIFont systemFontOfSize:14];
        _detailLabel.numberOfLines = 2;
        _detailLabel.lineBreakMode = NSLineBreakByWordWrapping;
        _detailLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [_detailLabel setContentHuggingPriority:910 forAxis:UILayoutConstraintAxisVertical];
        [_detailLabel setContentCompressionResistancePriority:760 forAxis:UILayoutConstraintAxisVertical];
        [self addSubview:_detailLabel];
    }

    if (!_thumbImage || !_thumbImage.superview)
    {
        _thumbImage = [[UIImageView alloc] initWithFrame:CGRectZero];
        _thumbImage.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:_thumbImage];
    }

    if (!_activityIndicator || !_activityIndicator.superview)
    {
        _activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        _activityIndicator.translatesAutoresizingMaskIntoConstraints = NO;
        _activityIndicator.hidesWhenStopped = YES;
        _activityIndicator.layer.shadowOffset = CGSizeMake(0.f, -1.f);
        _activityIndicator.layer.shadowColor = [UIColor blackColor].CGColor;
        _activityIndicator.layer.shadowRadius = 1.f;
        _activityIndicator.layer.shadowOpacity = 0.7;
        [self addSubview:_activityIndicator];
    }

    [self setNeedsUpdateConstraints];
    [self setNeedsLayout];
}

#if 0
- (void)setup
{
    CGRect bounds = self.bounds;

    self.opaque = NO;

    CGFloat yOffset = 9;
    CGRect imageRect = CGRectMake(yOffset, yOffset, 37.f, 34.f);

    self.layer.shadowOffset = CGSizeMake(0.f, 2.f);
    self.layer.shadowRadius = 2.5f;
    self.layer.shadowOpacity = 0.7;

    if (!_backgroundGradient || !_backgroundGradient.superview)
    {
        _backgroundGradient = [[UIView alloc] initWithFrame:bounds];
        _backgroundGradient.translatesAutoresizingMaskIntoConstraints = NO;
        //_backgroundGradient.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _backgroundGradient.alpha = 0.88f;
        [self addSubview:_backgroundGradient];
    }
    else
        _backgroundGradient.frame = bounds;

    UIFont *font = _titleLabel.font;
    if (!font)
        font = [UIFont systemFontOfSize:17];
    CGFloat labelHeight = ceilf(font.lineHeight) + 2;
    bounds.size.height = ceilf(yOffset * 2.f) + labelHeight;

    UIEdgeInsets labelInsets = UIEdgeInsetsMake(yOffset, 14 + CGRectGetMaxX(imageRect) , yOffset, 14);
    CGRect titleRect = UIEdgeInsetsInsetRect(bounds, labelInsets);  // CGRectMake(57.f,7.f,240.f,19.f)
    if (!_titleLabel || !_titleLabel.superview)
    {
        _titleLabel = [[UILabel alloc] initWithFrame:titleRect];
        _titleLabel.backgroundColor = [UIColor clearColor];
        _titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
        //_titleLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
        _titleLabel.layer.shadowOffset = CGSizeMake(0.f, -1.f);
        _titleLabel.layer.shadowColor = [UIColor blackColor].CGColor;
        _titleLabel.layer.shadowRadius = 1.f;
        _titleLabel.layer.shadowOpacity = 0.7;
        _titleLabel.numberOfLines = 1;
        [self addSubview:_titleLabel];
    }
    else {
        _titleLabel.frame = titleRect;
    }
    _titleLabel.preferredMaxLayoutWidth = CGRectGetWidth(titleRect);

    //CGRect subtitleRect = CGRectMake(57.f, 26.f, 251.f, 32.f);
    CGRect subtitleRect = titleRect;
    subtitleRect.origin.y = CGRectGetMaxY(titleRect) + yOffset;
    if (!_detailLabel || !_detailLabel.superview)
    {
        _detailLabel = [[UILabel alloc] initWithFrame:subtitleRect];
        _detailLabel.backgroundColor = [UIColor clearColor];
        _detailLabel.numberOfLines = 1;
        _detailLabel.translatesAutoresizingMaskIntoConstraints = NO;
        //_detailLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
        [self addSubview:_detailLabel];
    }
    else {
        _detailLabel.frame = subtitleRect;
    }
    _detailLabel.preferredMaxLayoutWidth = CGRectGetWidth(subtitleRect);

    if (!_thumbImage || !_thumbImage.superview)
    {
        _thumbImage = [[UIImageView alloc] initWithFrame:imageRect];
        [self addSubview:_thumbImage];
    }
    else
    {
        _thumbImage.frame = imageRect;
    }

    if (!_activityIndicator || !_activityIndicator.superview)
    {
        _activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        _activityIndicator.hidesWhenStopped = YES;
        _activityIndicator.layer.shadowOffset = CGSizeMake(0.f, -1.f);
        _activityIndicator.layer.shadowColor = [UIColor blackColor].CGColor;
        _activityIndicator.layer.shadowRadius = 1.f;
        _activityIndicator.layer.shadowOpacity = 0.7;
        [self addSubview:_activityIndicator];
    }
    else {
        _activityIndicator.center = _thumbImage.center;
    }


    self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
}
#endif

@end
