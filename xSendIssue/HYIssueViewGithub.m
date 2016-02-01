//
//  HYIssueWindow.m
//  xSendIssue
//
//  Created by Ken Luke on 7/11/15.
//  Copyright (c) 2016 hungri-yeti. All rights reserved.
//

#import "HYIssueViewGithub.h"
#import "HYPrefs.h"



// TODO: hard-coding api.github.com will definitely cause problems later on when
// trying to implement complatability with self-hosted git servers!
// the repo param will start with a leading / so we don't include it here:
NSString* const kGithubIssueSubmitUrl = @"https://api.github.com/repos%@/issues";	// POST method



@interface HYIssueViewGithub () {}

@property (strong) NSURLSession* session;
@property (strong) NSURL* repo;	// this is actually owner/repo, already formated for inclusion in API url.
@property (strong) NSProgressIndicator* activityIndicator;
@property (strong) HYPrefs* prefsWindow;


@property NSString* userName;
@property NSString* hostName;

@end

@implementation HYIssueViewGithub



#pragma mark - utilities
- (void) activateSubmit
{
	if( ([[self.descriptionTextView textStorage] string].length > 0) && ([self.titleTextField stringValue].length > 0) )
	{
		self.buttonSubmit.enabled = YES;
	}
}



#pragma mark - buttons
- (IBAction)didTapCancelButton:(id)sender
{
	[self.window.sheetParent endSheet:self.window returnCode:NSModalResponseCancel];
}



- (IBAction)didTapSubmitButton:(id)sender
{
	[self.activityIndicator startAnimation:self];
	self.activityIndicator.hidden = false;

	// submit the issue:
	NSString *requestString = [[NSString alloc] initWithFormat:kGithubIssueSubmitUrl, [self.repo path]];
	
	NSURL *url = [NSURL URLWithString:requestString];
	NSMutableURLRequest * urlRequest = [NSMutableURLRequest requestWithURL:url];

	NSData *userPasswordData = [[NSString stringWithFormat:@"%@:%@",
								 self.userName,
								 [HYPrefs getPassForHostUser:self.hostName user:self.userName]]
								 dataUsingEncoding:NSUTF8StringEncoding];
	NSString *base64EncodedCredential = [userPasswordData base64EncodedStringWithOptions:0];
	NSString *authString = [NSString stringWithFormat:@"Basic %@", base64EncodedCredential];

	NSURLSessionConfiguration *sessionConfig=[NSURLSessionConfiguration defaultSessionConfiguration];
	sessionConfig.HTTPAdditionalHeaders=@{@"Authorization":authString};
	self.session=[NSURLSession sessionWithConfiguration:sessionConfig];
	sessionConfig.HTTPAdditionalHeaders=@{@"Authorization":authString};


	NSMutableDictionary *json = [NSMutableDictionary dictionaryWithDictionary:@{
																@"title" : [self.titleTextField stringValue],
																@"body" : [[self.descriptionTextView string] copy]
																}];

	NSError *error = nil;
	NSData *jsonData = [NSJSONSerialization dataWithJSONObject:json options:NSJSONWritingPrettyPrinted error:&error];
	NSString *params = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];

	[urlRequest setHTTPMethod:@"POST"];
	[urlRequest setHTTPBody:[params dataUsingEncoding:NSUTF8StringEncoding]];

	NSURLSessionDataTask* submitTask =[self.session dataTaskWithRequest:urlRequest
		completionHandler:^(NSData *data, NSURLResponse *response, NSError *error)
		{
			NSLog(@"Response:%@\nerror: %@\n", response, error);
				
			[self.activityIndicator stopAnimation:nil];
			self.activityIndicator.hidden = true;
		
			if(error)
			{
				// This indicates an error within NSURLSessionDataTask, not an error returned from the server:
				NSLog(@"error: %@", error.description );
		
				NSAlert* alert = [NSAlert alertWithError:error];
				[alert runModal];
				return;
			}
			
			// Here is where we check the response code from the server:
			if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
				NSInteger statusCode = [(NSHTTPURLResponse *)response statusCode];
				
				// Status: "201 Created" is the success code we're looking for (not 200)
				if (statusCode != 201) {
					NSLog(@"dataTaskWithRequest HTTP status code: %ld", (long)statusCode );
					
					NSAlert* alert = [[NSAlert alloc] init];
					[alert setMessageText:[[NSString alloc] initWithFormat:@"server returned error: %@", [NSHTTPURLResponse localizedStringForStatusCode:statusCode]]];
					[alert runModal];
					
					return;
				}
				else {
					// put the location on the pasteboard:
					NSError* jsonError;
					NSMutableDictionary * innerJson = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&jsonError];
					NSString* issueLocation =[ innerJson objectForKey:@"html_url"];
					
					[[NSPasteboard generalPasteboard] declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:nil];
					[[NSPasteboard generalPasteboard] setString:issueLocation forType:NSStringPboardType];
					
					// let the user know it's there if they want to paste:
					NSUserNotification *notification = [[NSUserNotification alloc] init];
					notification.title = @"Issue Created";
					notification.informativeText = issueLocation;
					notification.soundName = NSUserNotificationDefaultSoundName;
					
					[[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];

					
					NSLog(@"location: %@", issueLocation);
				}
			}
			
			// debug:
			NSString * text = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
			NSLog(@"submit success: data = %@",text);
			
			// ok, we can close the sheet now:
			[self.window.sheetParent endSheet:self.window returnCode:NSModalResponseOK];
			return;
		}];
	[submitTask resume];
}



#pragma mark - textView delegate
- (void)textDidChange:(NSNotification *)notification
{
	[self activateSubmit];
}



#pragma mark - textField delegate
- (void)controlTextDidEndEditing:(NSNotification*)aNotification
{
	[self activateSubmit];
}



#pragma mark - lifecycle
- (id)initWithRepo:(NSURL*)repo
{
	self.repo = repo;

	// get the necessary info from the URL:
	self.hostName = [repo host];
	NSDictionary* prefsDict = [[NSUserDefaults standardUserDefaults] persistentDomainForName:@"com.hungri-yeti.xSendIssue"];
	self.userName =[prefsDict objectForKey:self.hostName];
	
	
	return self.init;
}



- (id)init
{
	return [super initWithWindowNibName:@"CreateIssue_github"];
}



- (void)windowDidLoad
{
	[super windowDidLoad];

	// add the activity indicator for use later when the user clicks Submit.
	// We'll center it over the description field.
	self.activityIndicator = [[NSProgressIndicator alloc] initWithFrame:NSMakeRect(20, 20, 30, 30)];
	[self.activityIndicator setFrameOrigin:NSMakePoint(
		(NSWidth([self.descriptionTextView bounds]) - NSWidth([self.activityIndicator frame])) / 2,
		(NSHeight([self.descriptionTextView bounds]) - NSHeight([self.activityIndicator frame])) / 2
	)];
	[self.activityIndicator setStyle:NSProgressIndicatorSpinningStyle];
	[self.descriptionTextView addSubview:self.activityIndicator];
	self.activityIndicator.hidden = true;
}

@end




















