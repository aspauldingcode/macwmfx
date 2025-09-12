#import <AppKit/AppKit.h>

@interface ContextualMenuButton : NSButton
@property (retain) NSMenu *associatedMenu;
- (void)displayAssociatedMenu:(id)sender;
@end
