//
//  HYPrefs.m
//  xSendIssue
//
//  Created by Ken Luke on 9/17/15.
//  Copyright © 2016 hungri-yeti. All rights reserved.
//

#import "HYPrefs.h"

@interface HYPrefs ()
@property (weak) IBOutlet NSButton *btnSave;

@property NSString* loginName;
@property NSString* userPass;
@property NSString* hostName;
@property NSString* path;
@property (unsafe_unretained) IBOutlet NSTextView *infoText;
@end









@implementation HYPrefs
#pragma mark - ui actions
- (IBAction)showPopover:(id)sender {
	NSString* infoString = @"Any changes made here are only applied to the local keychain, they are not  written to the github server.";
	[self.infoText insertText:infoString];
	[[self popover] showRelativeToRect:[sender bounds] ofView:sender preferredEdge:NSMaxYEdge];
	self.popover.behavior = NSPopoverBehaviorTransient;
}



- (void)setShowPassword:(BOOL)showPassword
{
	_showPassword = showPassword;

	[self.passwordField setShowsText:self.showPassword];
}



#pragma mark - buttons
- (IBAction)didClickCancel:(id)sender {
	[self.window.sheetParent endSheet:self.window returnCode:NSModalResponseCancel];
}



- (IBAction)didClickSave:(id)sender {
	// debug:
	NSLog(@"HYPrefs:didClickSave");

	
	// update prefs:
	NSUserDefaults *defaults = [[NSUserDefaults alloc] init];
	// get existing prefs (if any):
	NSDictionary* preferences = [[NSUserDefaults standardUserDefaults]
								 persistentDomainForName:@"com.hungri-yeti.xSendIssue"];
	NSMutableDictionary* mutablePreferences = [NSMutableDictionary
											   dictionaryWithDictionary:preferences];
	
	// modify & persist:
	[mutablePreferences setObject:self.loginName forKey:self.hostName];
	[[NSUserDefaults standardUserDefaults] setPersistentDomain:mutablePreferences
													   forName:@"com.hungri-yeti.xSendIssue"];
	[defaults synchronize];
	
	
	// update keychain:
	[self addKeychainItem];
	
	[self.window.sheetParent endSheet:self.window returnCode:NSModalResponseOK];
}



#pragma mark - keychain
- (void)addKeychainItem {
	// see if the item already exists:
	SecKeychainItemRef keychainItem;
	UInt32 returnpasswordLength = 0;
	char *passwordData;
	OSStatus keychainResult = noErr;
	keychainResult = SecKeychainFindInternetPassword(NULL,
													 (UInt32)self.hostName.length,
													 [self.hostName cStringUsingEncoding:NSASCIIStringEncoding],
													 0,
													 NULL,
													 (UInt32)self.loginName.length,
													 [self.loginName cStringUsingEncoding:NSASCIIStringEncoding],
													 0,
													 NULL,
													 0,
													 kSecProtocolTypeHTTPS,
													 kSecAuthenticationTypeDefault,
													 &returnpasswordLength,
													 (void *)&passwordData,
													 NULL);

	if (noErr == keychainResult) {
		// debug:
		NSLog(@"updating keychain...");

		// just update the existing keychain item:
		SecKeychainAttribute accountAttribute;
		accountAttribute.tag = kSecAccountItemAttr;
		accountAttribute.length = (UInt32)self.loginName.length;
		accountAttribute.data = [self.loginName cStringUsingEncoding:NSASCIIStringEncoding];
		SecKeychainAttributeList attributes;
		attributes.count = 1;
		attributes.attr = &accountAttribute;
		keychainResult = SecKeychainItemModifyAttributesAndData(keychainItem, &attributes, (UInt32)self.userPass.length, passwordData);
		if (noErr != keychainResult) {
			NSLog(@"error updating keychain item: %@", SecCopyErrorMessageString(keychainResult, NULL));
		}
		CFRelease(keychainItem);
	}
	else {
		// debug:
		NSLog(@"inserting keychain");


		
		// add a new item to the keychain:
		// TODO: also use path to differentiate multiple logins on the same host
		keychainResult = SecKeychainAddInternetPassword(NULL,
													   (UInt32)self.hostName.length,
													   [self.hostName cStringUsingEncoding:NSASCIIStringEncoding],
														0,
														nil,
													   (UInt32)self.loginName.length,
													   [self.loginName cStringUsingEncoding:NSASCIIStringEncoding],
														0,
														nil,
														0,
														kSecProtocolTypeHTTPS,
														kSecAuthenticationTypeDefault,
													   (UInt32)_passwordField.stringValue.length,
													   [_passwordField.stringValue cStringUsingEncoding:NSASCIIStringEncoding],
													   NULL);
		if (noErr != keychainResult) {
			NSLog(@"error writing to keychain: %@", SecCopyErrorMessageString(keychainResult, NULL));
		}
	}
}



#pragma mark - editing
- (void)updateSaveBtnState {

	// debug:
	//NSLog(@"loginName.length: %lu, userPass.length: %lu, hostName.length: %lu", (unsigned long)self.loginName.length, (unsigned long)_passwordField.stringValue.length, (unsigned long)self.hostName.length );


	if( (self.loginName.length > 0) && (self.hostName.length > 0) ) {
		self.btnSave.enabled = true;
	}
}



- (void)controlTextDidChange:(NSNotification *)obj {
	[self updateSaveBtnState];
}



#pragma mark - lifecycle
- (id)initWithUrl:(NSURL*)repoUrl {
	self = [super initWithWindowNibName:@"HYPrefs" owner:self];
	
	
	// try to get corresponding username from prefs
	NSDictionary* defaults = [[NSUserDefaults standardUserDefaults] persistentDomainForName:@"com.hungri-yeti.xSendIssue"];
	self.loginName = [defaults objectForKey:[repoUrl description]];
	self.hostName = [repoUrl host];
	self.path = [repoUrl path];
	
	NSLog(@"hyprefs: initwithurl: loginName: %@, hostname: %@, path: %@", self.loginName, self.hostName, self.path );
	
	return self;
}



- (id)init {
	self = [super initWithWindowNibName:@"HYPrefs" owner:self];

	return self;
}



- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.

	// disable the save btn until all fields are filled in:
	[self updateSaveBtnState];
}

@end
















