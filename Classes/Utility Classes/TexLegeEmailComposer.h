//
//  TexLegeEmailComposer.h
//  Created by Gregory Combs on 8/10/10.
//
//  StatesLege by Sunlight Foundation, based on work at https://github.com/sunlightlabs/StatesLege
//
//  This work is licensed under the Creative Commons Attribution-NonCommercial 3.0 Unported License. 
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc/3.0/
//  or send a letter to Creative Commons, 444 Castro Street, Suite 900, Mountain View, California, 94041, USA.
//
//

#import <Foundation/Foundation.h>
#import <MessageUI/MessageUI.h>

@interface TexLegeEmailComposer : NSObject <MFMailComposeViewControllerDelegate,UIAlertViewDelegate>
{

}
@property (nonatomic, strong) IBOutlet UIViewController *currentCommander;
@property (nonatomic, strong) IBOutlet MFMailComposeViewController *mailComposerVC;
@property (nonatomic, strong) IBOutlet UIAlertView *currentAlert;
@property (nonatomic) BOOL isComposingMail;

+ (TexLegeEmailComposer *)sharedTexLegeEmailComposer;
- (void)presentMailComposerTo:(NSString*)recipient subject:(NSString*)subject body:(NSString*)body commander:(UIViewController *)commander;


@end
