xSendIssue:
===========

Introduction:
-------------
xSendIssue is an Xcode plugin that provides a quick and easy way to file Github issues on your Xcode project from within Xcode itself.


Requirements:
-------------
- Xcode 7
- Project is hosted on github.com with Issues enabled
- Your github login info is in the default keychain:
   * Name: github.com
   * Kind: Internet password
   * Account: your github login or email address, either will work
   * Password: duh...


Installation:
-------------
1. unzip the file (do I really need to iterate this step?)
2. Open the project in Xcode
3. Build the project; this will install the plugin for you at ~/Library/Application Support/Developer/Shared/Xcode/Plug-ins
4. Exit and restart Xcode. You may get a message saying: Unexpected code bundle "xSendIssue.xcplugin" Just click Load Bundle.


How to use:
-----------
1. Start Xcode
2. Open a local Xcode project file. The project must already be checked in to git and setup to use github.com as the remote repository.
3. From the Source Control menu select "Create Issue"
4. Fill out form fields as desired
5. Click the Submit button
6. After the issue has been successfully created, the corresponding URL will be added to the pasteboard and you can paste the URL.
   - Note: xSendIssue uses defaultUserNotificationCenter so if you don't see anything response you may need to check your settings in Notification Center.

xSendIssue uses a separate preferences file from Xcode:
    
    ~/Library/Preferences/com.hungri-yeti.xSendIssue.plist


ToDo:
-----
These are some of the features under consideration, in no particular order nor promise of ever being implemented:

- support OAuth
- support specifying Assignees, Labels, and Milestones
- support private self-hosted git servers
- Slack integration
- Bitbucket support
- Alcatraz support
- Use Xcode's notification instead of system


Credits:
--------

Local github repo parsing code from [ShowInGithub](https://github.com/larsxschneider/ShowInGitHub). I would like to personally thank Lars Schneider, this plugin simply wouldn't be possible without his code.
