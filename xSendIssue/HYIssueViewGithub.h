//
//  HYIssueWindow.h
//  xSendIssue
//
//  Created by Ken Luke on 7/11/15.
//  Copyright (c) 2016 hungri-yeti. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface HYIssueViewGithub : NSWindowController <NSTextViewDelegate>

@property (weak, nonatomic) IBOutlet NSView* windowView;
@property (nonatomic) IBOutlet NSTextView* descriptionTextView;
@property (weak, nonatomic) IBOutlet NSTextField* titleTextField;
@property (weak, nonatomic) IBOutlet NSButton* buttonSubmit;
@property (weak, nonatomic) IBOutlet NSButton* openUrl;



- (id)initWithRepo:(NSURL*)repo;

@end







