//
//  TexLegeEmailComposer.m
//  Created by Gregory Combs on 8/10/10.
//
//  StatesLege by Sunlight Foundation, based on work at https://github.com/sunlightlabs/StatesLege
//
//  This work is licensed under the Creative Commons Attribution-NonCommercial 3.0 Unported License. 
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc/3.0/
//  or send a letter to Creative Commons, 444 Castro Street, Suite 900, Mountain View, California, 94041, USA.
//
//

#import "TexLegeEmailComposer.h"
#import "TexLegeAppDelegate.h"
#import "UtilityMethods.h"
#import "TexLegeTheme.h"

@interface TexLegeEmailComposer (Private)
- (void)presentMailFailureAlertViewWithTitle:(NSString*)failTitle message:(NSString *)failMessage;
@end

@implementation TexLegeEmailComposer

@synthesize mailComposerVC, isComposingMail, currentAlert, currentCommander;

+ (TexLegeEmailComposer*)sharedTexLegeEmailComposer
{
	static dispatch_once_t pred;
	static TexLegeEmailComposer *foo = nil;
	
	dispatch_once(&pred, ^{ foo = [[self alloc] init]; });
	return foo;
}

- (instancetype) init
{
    if ((self = [super init]))
    {
		self.isComposingMail = NO;
		self.mailComposerVC = nil;
		self.currentAlert = nil;
		self.currentCommander = nil;
    }
    return self;
}

- (void)dealloc {
	self.mailComposerVC = nil;
	self.currentAlert = nil;
	self.currentCommander = nil;
    [super dealloc];
}

- (void)presentMailComposerTo:(NSString*)recipient 
					  subject:(NSString*)subject 
						 body:(NSString*)body 
					commander:(UIViewController *)commander{
	if (!commander)
		return;
	
	self.currentCommander = commander;
	
	if (!body)
		body = @"";
	
	if ([MFMailComposeViewController canSendMail]) {
		MFMailComposeViewController *mc = [[MFMailComposeViewController alloc] init];
		self.mailComposerVC = mc;
		[mc release];
		self.mailComposerVC.mailComposeDelegate = self;
		[self.mailComposerVC setSubject:subject];
		[self.mailComposerVC setToRecipients:@[recipient]];
		[self.mailComposerVC setMessageBody:body isHTML:NO];
		(self.mailComposerVC).navigationBar.tintColor = [TexLegeTheme navbar];
		self.isComposingMail = YES;
				
		[self.currentCommander presentViewController:self.mailComposerVC animated:YES completion:nil];

	}
	else {   // Mail functions are unavailable
		NSMutableString *message = [NSMutableString stringWithFormat:@"mailto:%@", recipient];
		if (subject && subject.length)
			[message appendFormat:@"&subject=%@", subject];
		if (body && body.length)
			[message appendFormat:@"&body=%@", body];
		NSURL *mailto = [NSURL URLWithString:[message stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
		
		if (![UtilityMethods openURLWithTrepidation:mailto])
			[self presentMailFailureAlertViewWithTitle:NSLocalizedStringFromTable(@"Cannot Open Mail Composer", @"AppAlerts", @"Error on email attempt")
											   message:NSLocalizedStringFromTable(@"There was an error while attempting to open an email composer.  Please check your network settings and try again",
																				  @"AppAlerts", @"Error on email attempt")];
	}
}

#pragma mark -
#pragma mark Mail Composer Delegate

- (void)mailComposeController:(MFMailComposeViewController*)mailController 
		  didFinishWithResult:(MFMailComposeResult)result 
						error:(NSError*)error {
	
	if (result == MFMailComposeResultFailed) {
		[self presentMailFailureAlertViewWithTitle:NSLocalizedStringFromTable(@"Failure, Message Not Sent", @"AppAlerts", @"Error on email attempt.")
										   message:NSLocalizedStringFromTable(@"An error prevented successful transmission of your message. Check your email and network settings or try emailing manually.", @"AppAlerts", @"Error on email attempt")];
	}
	
	self.isComposingMail = NO;
	[self.currentCommander dismissViewControllerAnimated:YES completion:nil];
	self.mailComposerVC = nil;
	self.currentCommander = nil;
}

#pragma mark -
#pragma mark Alert View

- (void)presentMailFailureAlertViewWithTitle:(NSString*)failTitle message:(NSString *)failMessage {
	self.currentAlert = [[[UIAlertView alloc] 
						 initWithTitle:failTitle
						 message:failMessage 
						 delegate:self 
						  cancelButtonTitle:NSLocalizedStringFromTable(@"Cancel", @"StandardUI", @"Cancelling some activity") 
						  otherButtonTitles:nil] autorelease];
	[self.currentAlert show];
	
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
	if ([alertView isEqual:self.currentAlert]) {
		self.currentAlert = nil;		
	}
}


@end
