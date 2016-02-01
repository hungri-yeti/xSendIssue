//
//  HYPrefs.h
//  xSendIssue
//
//  Created by Ken Luke on 9/17/15.
//  Copyright © 2016 hungri-yeti. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "KSPasswordField.h"


@interface HYPrefs : NSWindowController <NSTextFieldDelegate>

+ (NSString*) getPassForHostUser:(NSString*)host user:(NSString*)user;

- (id)initWithUrl:(NSURL*)repoUrl;

@property (nonatomic, assign) BOOL showPassword;
@property (weak) IBOutlet KSPasswordField *passwordField;

@property (assign) IBOutlet NSPopover *popover;
- (IBAction)showPopover:(id)sender;

@end
