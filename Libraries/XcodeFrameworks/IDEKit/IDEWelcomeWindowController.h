/*
 *     Generated by class-dump 3.3.4 (64 bit).
 *
 *     class-dump is Copyright (C) 1997-1998, 2000-2001, 2004-2011 by Steve Nygard.
 */

#import "NSWindowController.h"

#import "NSWindowRestoration-Protocol.h"

@class DVTTableView, IDEIgnoredImageView, IDEWelcomeWindowHighlightButton, NSArrayController, NSImageView, NSString, NSTableColumn, NSTextField;

@interface IDEWelcomeWindowController : NSWindowController <NSWindowRestoration>
{
    NSArrayController *_projectsArrayController;
    DVTTableView *_projectsTableView;
    NSTableColumn *_tableColumn;
    IDEWelcomeWindowHighlightButton *_newProjectAssistantButton;
    IDEWelcomeWindowHighlightButton *_sourceControlButton;
    IDEWelcomeWindowHighlightButton *_openToolsDocsButton;
    IDEWelcomeWindowHighlightButton *_openDevCenterDocsButton;
    NSTextField *_newProjectAssistantButtonTitle;
    NSTextField *_sourceControlButtonTitle;
    NSTextField *_openToolsDocsButtonTitle;
    NSTextField *_openDevCenterDocsButtonTitle;
    NSTextField *_newProjectAssistantButtonDescription;
    NSTextField *_sourceControlButtonDescription;
    NSTextField *_openToolsDocsButtonDescription;
    NSTextField *_openDevCenterDocsButtonDescription;
    IDEIgnoredImageView *_welcomeIconsView;
    IDEIgnoredImageView *_backgroundImageView;
    NSImageView *_welcomeToXcodeAccessibilityProxy;
}

+ (void)_addDocWindowNotificationObservers:(id)arg1;
+ (BOOL)_canCoexistWithWindow:(id)arg1;
+ (void)_docWindowWillClose:(id)arg1;
+ (void)_removeDocWindowNotificationObservers;
+ (void)_someOtherWindowWasOpened:(id)arg1;
+ (void)initialize;
+ (void)restoreWindowWithIdentifier:(id)arg1 state:(id)arg2 completionHandler:(id)arg3;
+ (id)sharedWelcomeWindowController;
- (void)_addWindowNotificationObservers;
- (void)_openWelcomeWindowWithAutoCloseEnabled:(BOOL)arg1;
- (void)_removeWindowNotificationObservers;
- (void)_windowDidBecomeKeyOrMain:(id)arg1;
- (void)closeWelcomeWindow:(id)arg1;
- (void)encodeRestorableStateWithCoder:(id)arg1;
- (void)openDevCenterDocs:(id)arg1;
- (void)openNewProjectAssistant:(id)arg1;
- (void)openSelected:(id)arg1;
- (void)openSourceControl:(id)arg1;
- (void)openToolsDocs:(id)arg1;
- (void)openWelcomeWindow:(id)arg1;
- (void)openWelcomeWindowIfAppropriate:(id)arg1;
@property NSArrayController *projectsArrayController; // @synthesize projectsArrayController=_projectsArrayController;
- (void)runOpenPanel:(id)arg1;
- (void)showWindow:(id)arg1;
- (void)windowDidLoad;
- (void)windowWillClose:(id)arg1;
- (void)windowWillLoad;
@property(readonly) NSString *xcodeVersion;

@end
