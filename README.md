## Wishbox iOS client

1. To build this app, a provisioning profile should be created first at the Apple developer portal.

  The easiest way to create this provisioning profile is to allow Xcode to handle it:
  - navigate to the project settings, select "wishbox" target, and then select "General" tab. Click the "Fix issue" button, which should be under the "No identity or provisioning profile" warning. When it will be done, click it again to fix the next issue.
  - do the same steps for the "add action" target.

2. Update the first part (before the dot) of the kSharedKeychainGroupName parameter in [Shared/Settings.m](https://github.com/dmirkitanov/wishbox-ios/blob/master/Shared/Settings.m) to match your team id. Team id can be found at the Apple developer portal: Member center -> Your account -> Account summary -> Team ID
