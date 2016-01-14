# GBPush ![Version](https://img.shields.io/cocoapods/v/GBPush.svg?style=flat)&nbsp;![License](https://img.shields.io/badge/license-Apache_2-green.svg?style=flat)

Objective-C client library for Goonbee's push service for iOS. Use this in your iOS apps to register on channels and handle received push notifications.

Usage
------------

First import the library:

```objective-c
#import <GBPush/GBPush.h>
```

Connect to the GBPush service. This also initialises the GBPush library and connects it to the iOS APNS machinery:

```objective-c
[GBPush connectToServer:@"push.myapp.com" port:56201];
```

Then subscribe to channels that you're interested in (if you have more than one channel, you'd call this method several times, once for each channel):

```objective-c
[GBPush setChannelSubscriptionStatusForChannel:@"user.lmirosevic" subscriptionStatus:YES completed:nil];
```

Implement the handler to be executed when a push notification is received. (If `appActive` is `NO`, it means your application was not active when the push was received, and it was opened in response to the user tapping on the notification):

```objective-c
[GBPush onPush:^(NSDictionary *pushNotification, BOOL appActive) {
    // Get the APNS properties out of the push message
    NSString *alert = pushNotification[@"aps"][@"alert"];
    NSString *badge = pushNotification[@"aps"][@"badge"];
    
    // Get the custom payload out of the push
    NSDictionary *payload = pushNotification[@"p"];
    
    // Do something in response to the push...
    NSLog(@"Got payload via push: %@", payload);
}];
```

Before you can receive push notifications, you will have to ask the user's permission to allow push notifications for your app. GBPush allows you to control when this happens. At the opportune time of your choosing, you can request this while specifying what kinds of messages you're interested in (alert, badge, sound and/or background/silent):

```objective-c
[GBPush requestPermissionForShowingUserNotificationTypes:(GBPushUserNotificationTypeAlert | GBPushUserNotificationTypeBadge | GBPushUserNotificationTypeSound | GBPushUserNotificationTypeSilent) completed:^(GBPushUserNotificationType permittedTypes, BOOL didRequestPermissions) {
    // Check if we're allowed to show alerts
    if (permittedTypes & GBPushUserNotificationTypeAlert) {
        NSLog(@"We are now allowed to show alerts to the user");
    }
    
    // Check if we're allowed the receive background push messages
    if (permittedTypes & GBPushUserNotificationTypeSilent) {
        NSLog(@"We can send background push messages");
    }

    // It can happen that the user was not even asked to allow push notifications...
    if (!didRequestPermissions) {
        // ...perhaps they were asked before and rejected it for our app, and you only get to ask once.
        
        // What we can do now is show an alert to the user, or urge them to go to the Settings app and enable push for our app there.
        // ...
    }
}];
```

Advanced use
------------

Unsubscribing from a channel:

```objective-c
[GBPush setChannelSubscriptionStatusForChannel:@"user.lmirosevic" subscriptionStatus:NO completed:nil];
```

Checking whether or not we're currently subscribed to a particular channel:

```objective-c
[GBPush subscriptionStatusForChannel:@"user.lmirosevic" completed:^(BOOL subscribed, BOOL success) {
	NSLog(@"We're subscribed: %@", subscribed ? @"YES" : @"NO");
}];
```

Getting a list of channels we're currently subscribed to. In this example we're getting the 5 most recently subscribed to channels:

```objective-c
[GBPush subscribedChannelsWithRange:[[GBSharedRange alloc] initWithDirection:Direction_BACKWARDS index:0 length:5] completed:^(NSArray channels, BOOL success) {
    NSLog(@"These are the 5 msot recent channels we're currently subscribed on: %@", channels);
}];
```

Checking what types of notifcations we're currently allowed to show to the user:

```objective-c
if ([GBPush currentPermittedUserNotificationTypes] & GBPushUserNotificationTypeBadge) {
    NSLog(@"Badges allowed!");
}
```

Getting the push device token:

```objective-c
NSData *pushToken = [GBPush pushToken];
```

Checking whether we've registered for remote push:

```objective-c
BOOL hasRegistered = [GBPush hasRegisteredForPush];
```


Copyright & License
------------

Copyright 2016 Goonbee

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this work except in compliance with the License. You may obtain a copy of the License in the LICENSE file, or at:

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
