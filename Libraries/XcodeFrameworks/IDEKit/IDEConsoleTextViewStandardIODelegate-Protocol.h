/*
 *     Generated by class-dump 3.3.4 (64 bit).
 *
 *     class-dump is Copyright (C) 1997-1998, 2000-2001, 2004-2011 by Steve Nygard.
 */

#import "NSObject-Protocol.h"

@protocol IDEConsoleTextViewStandardIODelegate <NSObject>
- (void)consoleView:(id)arg1 didEndText:(id)arg2 forDebugger:(BOOL)arg3;
- (void)showNextCommandFromHistory:(id)arg1;
- (void)showPreviousCommandFromHistory:(id)arg1 currentStringAfterPrompt:(id)arg2;
@property(readonly) BOOL tracksInputHistoryForDebugger;
@end
