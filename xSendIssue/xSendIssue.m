//
//  xSendIssue.m
//  xSendIssue
//
//  Created by Ken Luke.
//  Copyright (c) 2016 hungri-yeti. All rights reserved.
//

#import "xSendIssue.h"
#import "HYPrefs.h"


#import <IDEKit/IDEWorkspaceWindowController.h>
#import <IDEKit/IDEEditorArea.h>
static Class IDEWorkspaceWindowControllerClass;

id objc_getClass(const char* name);

@interface xSendIssue()
{
	BOOL docIsOpen;
}

@property (nonatomic, strong, readwrite) NSBundle *bundle;
@property (nonatomic, strong) id ideWorkspaceWindow;
@property (strong) HYIssueViewGithub* issueWindowGithub;

@property (nonatomic, strong) NSMutableSet *notificationSet;

@property (strong) HYPrefs* prefsWindow;
@property (strong) NSURLSession* session;



@end

@implementation xSendIssue




#pragma mark - menu
- (void)doMenuAction
{
	NSURL *activeDocumentURL = [self activeDocument];

	if (!activeDocumentURL)
	{
		NSAlert *alert = [[NSAlert alloc] init];
		alert.alertStyle = NSCriticalAlertStyle;
		[alert setMessageText:@"Unable to find Xcode document."];
		[alert runModal];

		return;
	}


	NSString *activeDocumentDirectoryPath = [[activeDocumentURL URLByDeletingLastPathComponent] path];
	NSString *repoPath = [self gitRepoPathForDirectory:activeDocumentDirectoryPath];
	NSWindow *mainWindow=[[NSApplication sharedApplication] mainWindow];


	// verify host:
	if( repoPath != nil ) {
		// debug:
		NSLog(@"repoPath: %@", repoPath);

		NSString* errMsg;
		BOOL presentPrefs = false;
		
		// try to get corresponding username from prefs:
		NSDictionary* defaults = [[NSUserDefaults standardUserDefaults] persistentDomainForName:@"com.hungri-yeti.xSendIssue"];
		
		NSURL* repoUrl = [NSURL URLWithString:repoPath];
		NSString* host = [repoUrl host];
		NSString* repoUserName = [defaults objectForKey:host];
		
		BOOL passwordFound = [self passInKeychainWithAccountName:repoUserName url:repoPath];
		
		if ([repoUserName length] == 0) {
			presentPrefs = true;
			errMsg = [[NSString alloc] initWithFormat:@"Unable to determine git username for this repository (remote: %@). Please fill in settings.", host];
			NSAlert *alert = [[NSAlert alloc] init];
			alert.messageText = errMsg;
			[alert beginSheetModalForWindow:mainWindow completionHandler:nil];
		}
		else if (!passwordFound) {
			presentPrefs = true;
			errMsg = [[NSString alloc] initWithFormat:@"Unable to find password in keychain (remote: %@). Please fill in settings.", host];
			NSAlert *alert = [[NSAlert alloc] init];
			alert.messageText = errMsg;
			[alert beginSheetModalForWindow:mainWindow completionHandler:nil];
		}
		
		
		if( presentPrefs ) {
			NSLog(@"doMenuAction: presentPrefs");

			_prefsWindow = [[HYPrefs alloc] initWithUrl:repoUrl];
			[mainWindow beginSheet:_prefsWindow.window  completionHandler:^(NSModalResponse returnCode) {
				NSLog(@"prefs sheet closed");

				switch (returnCode) {
					case NSModalResponseOK:
						NSLog(@"Save button tapped in Prefs Sheet");
						[self openGithubIssue:repoUrl repoPath:repoPath];

						break;
					case NSModalResponseCancel:
						NSLog(@"Cancel button tapped in Prefs Sheet");
						break;

					default:
						break;
				}
			}];
		}
		else {
			NSLog(@"username: %@ and corresponding password from keychain found", repoUserName );

			[self openGithubIssue:repoUrl repoPath:repoPath];
		}
	}
	else {
		NSLog(@"Error: doMenuAction: Unable to determine host from git.");

		NSString* msg = [[NSString alloc] initWithFormat:@"Unable to determine repository host from local repository."];
		NSAlert *alert = [[NSAlert alloc] init];
		alert.messageText = msg;
		[alert beginSheetModalForWindow:mainWindow completionHandler:nil];
	}
}



// We only want the menu activated when the current Xcode project is hosted remotely:
- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
	return docIsOpen;
}



#pragma mark - invoke windows
- (void)openGithubIssue:(NSURL *)repoUrl repoPath:(NSString *)repoPath
{
	if ([self isGitHubRepo:repoPath] )
	{
		[self showGitHubView:repoUrl];
	}
	else
	{
		NSAlert *alert = [[NSAlert alloc] init];
		[alert setMessageText:@"I can't figure out where this repo is hosted, currently only repositories on github.com are supported."];
		[alert runModal];
	}
}



// present as doc window sheet:
- (void) showGitHubView:(NSURL *)repoURL
{
	NSWindow *mainWindow=[[NSApplication sharedApplication] mainWindow];
	if(!mainWindow)
	{
		NSLog(@"Can't find IDE text view - no main window.\n");
		return;
	}


	self.issueWindowGithub = [[HYIssueViewGithub alloc] initWithRepo:repoURL];
	[mainWindow beginSheet:self.issueWindowGithub.window  completionHandler:^(NSModalResponse returnCode) {
		NSLog(@"Sheet closed");

		switch (returnCode) {
			case NSModalResponseOK:
				NSLog(@"Done button tapped in Custom Sheet");
				break;
			case NSModalResponseCancel:
				NSLog(@"Cancel button tapped in Custom Sheet");
				break;

			default:
				break;
		}

		self.issueWindowGithub = nil;
	}];

}



#pragma mark - repo server determination
- (BOOL)isGitHubRepo:(NSString *)repo
{
	NSArray *servers = @[@"github", @"github"];
	for (NSString *server in servers)
	{
		NSRange rangeOfRepo = [[repo lowercaseString] rangeOfString:server];
		if (rangeOfRepo.location != NSNotFound)
		{
			return YES;
		}
	}

	return NO;
}



#pragma mark - Helpers
// Given username and hostname, see if there is a corresponding password in the keychain.
// username is the web context, accountname is the keychain context, they are the same value.
- (BOOL)passInKeychainWithAccountName:(NSString*)accountName url:(NSString*)url  {
	BOOL retVal = false;
	
	// extract server & path from url:
	NSURL* repoUrl = [NSURL URLWithString:url];
	NSString* serverName = [repoUrl host];
	
	// debug:
	NSLog(@"serverName: %@, accountName: %@", serverName, accountName );
	
	
	// this doesn't work as we need, it is doing an exact match but there may be some variablility?
	// see if the item already exists:
	UInt32 returnpasswordLength = 0;
	char *passwordData;
	OSStatus keychainResult = noErr;
	keychainResult = SecKeychainFindInternetPassword(NULL,
													 (UInt32)serverName.length,
													 [serverName cStringUsingEncoding:NSASCIIStringEncoding],
													 0,
													 NULL,
													 (UInt32)accountName.length,
													 [accountName cStringUsingEncoding:NSASCIIStringEncoding],
													 0,
													 NULL,
													 0,
													 kSecProtocolTypeAny,
													 kSecAuthenticationTypeDefault,
													 &returnpasswordLength,
													 (void *)&passwordData,
													 NULL);

	if (noErr == keychainResult)
		retVal = true;
	else
		NSLog(@"keychainResult: %@\n", SecCopyErrorMessageString(keychainResult, NULL));

	return retVal;
}



- (NSURL *)activeDocument
{
	NSArray *windows = [IDEWorkspaceWindowControllerClass workspaceWindowControllers];
	for (id workspaceWindowController in windows)
	{
		if ([workspaceWindowController workspaceWindow] == self.ideWorkspaceWindow || windows.count == 1)
		{
			id document = [[workspaceWindowController editorArea] primaryEditorDocument];
			return [document fileURL];
		}
	}

	return nil;
}



- (NSString *)outputGitWithArguments:(NSArray *)args inPath:(NSString *)path
{
	if (path.length == 0)
	{
		NSLog(@"Invalid path for git working directory.");
		return nil;
	}

	NSTask *task = [[NSTask alloc] init];
	task.launchPath = @"/usr/bin/xcrun";
	task.currentDirectoryPath = path;
	task.arguments = [@[@"git", @"--no-pager"] arrayByAddingObjectsFromArray:args];
	task.standardOutput = [NSPipe pipe];
	NSFileHandle *file = [task.standardOutput fileHandleForReading];

	[task launch];

	// For some reason [task waitUntilExit]; does not return sometimes. Therefore this rather hackish solution:
	int count = 0;
	while (task.isRunning && (count < 10))
	{
		[NSThread sleepForTimeInterval:0.1];
		count++;
	}

	NSString *output = [[NSString alloc] initWithData:[file readDataToEndOfFile] encoding:NSUTF8StringEncoding];

	return output;
}



- (NSString *)gitRepoPathForDirectory:(NSString *)dir
{
	if (dir.length == 0)
	{
		NSLog(@"Invalid git repository path.");
		return nil;
	}

	// Get github username and repo name
	__block NSString *githubURLComponent = nil;
	NSArray *args = @[@"remote", @"--verbose"];
	NSString *output = [self outputGitWithArguments:args inPath:dir];
	NSArray *remotes = [output componentsSeparatedByString:@"\n"];
	NSLog(@"GIT remotes: %@", remotes);

	NSMutableSet *remotePaths = [NSMutableSet setWithCapacity:1];

	for (NSString *remote in remotes)
	{
		// Check for SSH protocol
		NSRange begin = [remote rangeOfString:@"git@"];

		if (begin.location == NSNotFound)
		{
			// SSH protocol not found, check for GIT protocol
			begin = [remote rangeOfString:@"git://"];
		}
		if (begin.location == NSNotFound)
		{
			// HTTPS protocol check
			begin = [remote rangeOfString:@"https://"];
		}
		if (begin.location == NSNotFound)
		{
			// HTTP protocol check
			begin = [remote rangeOfString:@"http://"];
		}

		NSRange end = [remote rangeOfString:@".git (fetch)"];

		if (end.location == NSNotFound)
		{
			// Alternate remote url end
			end = [remote rangeOfString:@" (fetch)"];
		}

		if ((begin.location != NSNotFound) &&
			 (end.location != NSNotFound))
		{
			// we want the scheme included in the URL path we return:
			NSUInteger githubURLBegin = begin.location;
			NSUInteger githubURLLength = end.location - githubURLBegin;
			githubURLComponent = [remote substringWithRange:NSMakeRange(githubURLBegin, githubURLLength)];

			[remotePaths addObject:githubURLComponent];
		}
	}


	if (remotePaths.count > 1)
	{
		NSArray *sortedRemotePaths = remotePaths.allObjects;

		// Ask the user which remote to use, limited to first three entries only because otherwise the alert will look ridiculous:
		NSWindow *mainWindow=[[NSApplication sharedApplication] mainWindow];
		NSAlert* alert = [[NSAlert alloc] init];
		[alert setMessageText:[NSString stringWithFormat:@"This repository has %lu remotes configured. Which one do you want to open?", (unsigned long)remotePaths.count]];
		[alert addButtonWithTitle: [sortedRemotePaths objectAtIndex:0]];
		[alert addButtonWithTitle: [sortedRemotePaths objectAtIndex:1]];
		sortedRemotePaths.count > 2 ? [alert addButtonWithTitle: [sortedRemotePaths objectAtIndex:1]] : nil;
	
		[alert beginSheetModalForWindow:mainWindow completionHandler:^(NSModalResponse returnCode) {
			if (returnCode == NSAlertFirstButtonReturn) {
				githubURLComponent = [sortedRemotePaths objectAtIndex:0];
				return;
			}
			else if( returnCode == NSAlertSecondButtonReturn ) {
				githubURLComponent = [sortedRemotePaths objectAtIndex:1];
				return;
			}
			else if (sortedRemotePaths.count > 2) {
				githubURLComponent = [sortedRemotePaths objectAtIndex:2];
				return;
			}
		}];
	}



	if (githubURLComponent.length == 0)
	{
		[self showGitError:@"Unable to find github remote URL." gitArgs:args output:output];
		return nil;
	}

	return githubURLComponent;
}



- (void)createErrorReportForGitArgs:(NSArray *)gitArgs withOutput:(NSString *)gitOutput
{
	NSString *gitVersion = [self outputGitWithArguments:@[@"--version"] inPath:@"~"];
	NSString *body = [NSString stringWithFormat:
							@"!!! ATTENTION: Please redact any private information below !!!\n\n"
							"Call:\ngit %@\n\nOutput:\n%@\n\nVersion:\n%@",
							[gitArgs componentsJoinedByString:@" "], gitOutput, gitVersion];
	NSString *mailString = [NSString stringWithFormat:
									@"mailto:?to=larsxschneider+showingithub@gmail.com&subject=ShowInGithub-Error-Report&body=%@",
									[body stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding]];
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:mailString]];
}



- (void)showGitError:(NSString *)message gitArgs:(NSArray *)gitArgs output:(NSString *)gitOutput
{
	NSWindow *mainWindow=[[NSApplication sharedApplication] mainWindow];
	NSAlert *alert = [[NSAlert alloc] init];
	[alert setMessageText:@"Git Error"];
	[alert setInformativeText:message];
	[alert addButtonWithTitle:@"OK"];
	[alert addButtonWithTitle:@"Create error report"];
	[alert setAlertStyle:NSWarningAlertStyle];
	
	[alert beginSheetModalForWindow:mainWindow completionHandler:^(NSModalResponse returnCode) {
		if (returnCode == NSAlertSecondButtonReturn) {
			[self createErrorReportForGitArgs:gitArgs withOutput:gitOutput];
			return;
		}
	}];
}



#pragma mark - Notifications
- (void)fetchActiveIDEWorkspaceWindow:(NSNotification *)notification
{
	id window = [notification object];
	if ([window isKindOfClass:[NSWindow class]] && [window isMainWindow])
	{
		self.ideWorkspaceWindow = window;
	}
}



#pragma mark - lifecycle
+ (instancetype)sharedPlugin
{
	return sharedPlugin;
}



+ (void)pluginDidLoad:(NSBundle *)plugin
{
	IDEWorkspaceWindowControllerClass = objc_getClass("IDEWorkspaceWindowController");

	static dispatch_once_t onceToken;
	NSString *currentApplicationName = [[NSBundle mainBundle] infoDictionary][@"CFBundleName"];
	if ([currentApplicationName isEqual:@"Xcode"])
	{
		dispatch_once(&onceToken, ^{
			sharedPlugin = [[xSendIssue alloc] initWithBundle:plugin];
		});
	}
}



- (id)initWithBundle:(NSBundle *)plugin
{
	if (self = [super init]) {

		// debug: setup to log all Xcode notifications (Note: verbose & slow)
		//	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleNotification:) name:nil object:nil];
		//	self.notificationSet = [NSMutableSet new];


		// reference to plugin's bundle, for resource access
		self.bundle = plugin;
		// setup the notifications we need:
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(didApplicationFinishLaunchingNotification:)
													 name:NSApplicationDidFinishLaunchingNotification
												   object:nil];

		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(didDocumentOpenNotification:)
													 name:@"PBXProjectDidOpenNotification"
												   object:nil];

		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(didDocumentCloseNotification:)
													 name:@"PBXProjectDidCloseNotification"
												   object:nil];

		// Just the PBXProjectDidOpenNotification alone is insufficient, if the .xcodeproj is passed in as part of the startup args
		// e.g. dbl-click from finder or as args in Xcdoe scheme, then PBXProjectDidOpenNotification isn't fired off
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(didDocumentOpenNotification:)
													 name:@"IDEEditorDocumentDidChangeNotification"
												   object:nil];
	}
	return self;
}



// debug:
//- (void)handleNotification:(NSNotification *)notification {
//	if (![self.notificationSet containsObject:notification.name]) {
//		NSLog(@"%@, %@", notification.name, [notification.object class]);
//		[self.notificationSet addObject:notification.name];
//	}
//}



// These two control whether or not the menu pick is active
- (void)didDocumentCloseNotification:(NSNotification*)noti {
	docIsOpen = false;
}



- (void)didDocumentOpenNotification:(NSNotification*)noti {
	docIsOpen = true;
}



- (void)didApplicationFinishLaunchingNotification:(NSNotification*)noti
{
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSApplicationDidFinishLaunchingNotification object:nil];

	// Create menu items, initialize UI, etc.
	NSMenuItem *menuItem = [[NSApp mainMenu] itemWithTitle:@"Source Control"];
	if (menuItem) {
		[[menuItem submenu] addItem:[NSMenuItem separatorItem]];
		NSMenuItem *actionMenuItem = [[NSMenuItem alloc] initWithTitle:@"Create Issue" action:@selector(doMenuAction) keyEquivalent:@""];
		//[actionMenuItem setKeyEquivalentModifierMask:NSAlphaShiftKeyMask | NSControlKeyMask];
		[actionMenuItem setTarget:self];
		[[menuItem submenu] addItem:actionMenuItem];
	}
	
	// menu item will disabled until xcodeproj is opened:
	docIsOpen = false;

	// Listen to application did finish launching notification to hook in the menu.
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];

	[nc addObserver:self
		   selector:@selector(fetchActiveIDEWorkspaceWindow:)
			   name:NSWindowDidUpdateNotification
			 object:nil];
}



- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
























