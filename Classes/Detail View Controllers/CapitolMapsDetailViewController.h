//
//  CapitolMapsDetailViewController.h
//  Created by Gregory S. Combs on 5/31/09.
//
//  StatesLege by Sunlight Foundation, based on work at https://github.com/sunlightlabs/StatesLege
//
//  This work is licensed under the Creative Commons Attribution-NonCommercial 3.0 Unported License. 
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc/3.0/
//  or send a letter to Creative Commons, 444 Castro Street, Suite 900, Mountain View, California, 94041, USA.
//
//

#import "TexLege.h"
#import "CapitolMap.h"
#import "TXLDetailProtocol.h"

@interface CapitolMapsDetailViewController : UIViewController <UISplitViewControllerDelegate, TXLDetailProtocol> {
}
@property (nonatomic,retain) id dataObject;

@property (nonatomic,retain) CapitolMap *map;
@property (nonatomic,retain) IBOutlet UIWebView *webView;
@property (nonatomic,retain) UIPopoverController *masterPopover;
@end
