/*
 *     Generated by class-dump 3.3.4 (64 bit).
 *
 *     class-dump is Copyright (C) 1997-1998, 2000-2001, 2004-2011 by Steve Nygard.
 */

#import <IDEKit/IDEViewController.h>

@class NSString;

@interface IDEDebugArea : IDEViewController
{
}

+ (id)debuggerUIExtensionForLaunchSession:(id)arg1;
- (void)activateConsole;
- (BOOL)canActivateConsole;
- (BOOL)canClearConsole;
- (void)clearConsole;
@property(readonly) NSString *stateSavingIdentifier;

@end

