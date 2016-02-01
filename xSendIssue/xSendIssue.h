//
//  xSendIssue.h
//  xSendIssue
//
//  Created by Ken Luke.
//  Copyright (c) 2016 hungri-yeti. All rights reserved.
//

#import <AppKit/AppKit.h>
#import "HYIssueViewGithub.h"


@class xSendIssue;

static xSendIssue *sharedPlugin;

@interface xSendIssue : NSObject <NSMenuDelegate>

+ (instancetype)sharedPlugin;
- (id)initWithBundle:(NSBundle *)plugin;

@property (nonatomic, strong, readonly) NSBundle* bundle;
@end