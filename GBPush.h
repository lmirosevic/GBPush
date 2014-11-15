//
//  GBPush.h
//  GBPush
//
//  Created by Luka Mirosevic on 27/04/2014.
//  Copyright (c) 2014 Goonbee. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "GBPushApi.h"

#pragma mark - AppDelegate integration macros

/**
 Add this on the top level of you AppDelegate implementation to implement the required GBPush hooks into the delegate calls.
 */
#define GBPushAppDelegateHooks \
/* Push handling (Support for iOS 6 and below) */ \
- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo { \
    BOOL appInactive = application.applicationState == UIApplicationStateInactive || application.applicationState == UIApplicationStateBackground; \
    [GBPush handlePush:userInfo appActive:!appInactive]; \
} \
/* Push handling (iOS 7+ support) */ \
- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler { \
    BOOL appInactive = application.applicationState == UIApplicationStateInactive || application.applicationState == UIApplicationStateBackground; \
    [GBPush handlePush:userInfo appActive:!appInactive]; \
} \
/* Token registration (success) */ \
- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken { \
    [GBPush systemDidEnablePushWithToken:deviceToken]; \
} \
/* Token registration (failed) */ \
- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error { \
    [GBPush systemFailedToEnablePushWithError:error]; \
} \
/* User notification permission request */ \
- (void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings { \
    [GBPush systemDidFinishRequestingUserNotificationPermissions]; \
}

/**
 Add this at the end of your application:didFinishLaunchingWithOptions: method to pass on the push notification to GBPush when the app is launched via a push notification
 */
#define GBPushAppDidFinishLaunchingWithPushNotificationHook \
NSDictionary *notification = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey]; \
if (notification) [GBPush handlePush:notification appActive:NO];

#pragma mark - Types

typedef NS_OPTIONS(NSUInteger, GBPushUserNotificationType) {
    GBPushUserNotificationTypeSilent =      UIUserNotificationTypeNone,
    GBPushUserNotificationTypeBadge =       UIUserNotificationTypeBadge,
    GBPushUserNotificationTypeSound =       UIUserNotificationTypeSound,
    GBPushUserNotificationTypeAlert =       UIUserNotificationTypeAlert,
};

typedef void(^GBPushCallCompletionBlock)(id result, BOOL success);
typedef void(^GBPushSubscriptionsPotentiallyChangedHandlerBlock)();
typedef void(^GBPushPushHandlerBlock)(NSDictionary *pushNotification, BOOL appActive);
typedef void(^GBPushUserNotificationPermissionRequestCompletedBlock)(GBPushUserNotificationType permittedTypes, BOOL didRequestPermissions);

@interface GBPush : NSObject

#pragma mark - API (Basics)

/**
 Connects to the push registration server.
 */
+ (void)connectToServer:(NSString *)server port:(NSUInteger)port;

/**
 Lets you subscribe or unsubscribe from a channel.
 
 Push device tokens are automatically managed, and requested the first time you attempt to subscribe to a channel.
 */
+ (void)setChannelSubscriptionStatusForChannel:(NSString *)channel subscriptionStatus:(BOOL)subscriptionStatus completed:(GBPushCallCompletionBlock)block;

/**
 Gets the current subscription status for a channel.
 */
+ (void)subscriptionStatusForChannel:(NSString *)channel completed:(GBPushCallCompletionBlock)block;

/**
 Returns a list of chanels which you are subscribed to.
 */
+ (void)subscribedChannelsWithRange:(GBSharedRange *)range completed:(GBPushCallCompletionBlock)block;

/**
 Set the handler block which should be invoked for whena push message is received
 */
+ (void)setPushHanderBlock:(GBPushPushHandlerBlock)block;

/**
 Call this method to request permissions for showing user notification. If you do not call this method, push notifications will still be delivered when the app is open, however when the app is closed, no user visible alerts/badges/sounds can be shown to the user.
 
 This is only relevant on iOS 8+. On older systems this method has no effect and GBPush simply asks for all permissions (alert + sound + badge) when subscribing to a channel for the first time.
 
 The `permissionsRequested` flag will indicate whether the permissions were actually requested or no. Cases where the flag is NO are when the permissions are already granted, or when the method is not relevant (i.e. when running on iOS 7 or below).
 
 It seems that on iOS 8 you only get one chance to ask for permissions, so you should immediately ask for any permissions you might ever want, on the first request. The alert on iOS 8 also seems to show all the types when asking the user, irrespecitvely of what you've requested here, so the safest seems to just request all. This method simply mirrors the iOS behaviour.
 */
+ (void)requestPermissionForShowingUserNotificationTypes:(GBPushUserNotificationType)types completed:(GBPushUserNotificationPermissionRequestCompletedBlock)block;

/**
 Returns the currently permitted user notification types.
 */
+ (GBPushUserNotificationType)currentPermittedUserNotificationTypes;

#pragma mark - API (Advanced)

/**
 Lets you check whether a request for permissions from the user to show user notifications is in progress.
 */
+ (BOOL)isRequestForPermissionsForShowingUserNotificationsInProgress;

/**
 Adds a handler which will be invoked when the list of push channels to which you are subscribed potentially changes, for a context.
 */
+ (void)addPushSubscriptionsPotentiallyChangedHandler:(GBPushSubscriptionsPotentiallyChangedHandlerBlock)block forContext:(id)context;

/**
 Removes all handlers for a context for when the push list might change.
 */
+ (void)removeAllPushSubscriptionsChangedHandlersForContext:(id)context;

/**
 Lets you subscribe or unsubscribe from a channel. You can set shouldTriggerHandler to NO if you don't want this registration to fire the PushSubscriptionsPotentiallyChanged handlers.
 */
+ (void)setChannelSubscriptionStatusForChannel:(NSString *)channel subscriptionStatus:(BOOL)subscriptionStatus completed:(GBPushCallCompletionBlock)block triggerHandler:(BOOL)shouldTriggerHandler;

/**
 Gets the current subscription status for a channel. This call might actualise the internal list of subscribed push channels, if you don't want this to trigger the the PushSubscriptionsPotentiallyChanged handlers, then you can set shouldTriggerHandler to NO.
 */
+ (void)subscriptionStatusForChannel:(NSString *)channel completed:(GBPushCallCompletionBlock)block triggerHandler:(BOOL)shouldTriggerHandler;

/**
 Gets the current list of subscribed channels. This call might actualise the internal list of subscribed push channels, if you don't want this to trigger the the PushSubscriptionsPotentiallyChanged handlers, then you can set shouldTriggerHandler to NO.
 */
+ (void)subscribedChannelsWithRange:(GBSharedRange *)range completed:(GBPushCallCompletionBlock)block triggerHandler:(BOOL)shouldTriggerHandler;


#pragma mark - AppDelegate hooks

/**
 This should be called from application:didRegisterForRemoteNotificationsWithDeviceToken: passing in the deviceToken, to give GBPush the device token.
 */
+ (void)systemDidEnablePushWithToken:(NSData *)pushToken;

/**
 This should be called from application:didFailToRegisterForRemoteNotificationsWithError: passing in the error.
 */
+ (void)systemFailedToEnablePushWithError:(NSError *)error;

/**
 This should be called from application:didRegisterUserNotificationSettings:.
 */
+ (void)systemDidFinishRequestingUserNotificationPermissions;

/**
 This should be called when the app receives a push, to let GBPush take over the rest. You need to call this from 2 AppDelegate methods.
 
 In application:didReceiveRemoteNotification: you should call it passing in the userInfo dictionary, and setting appActive to YES if the applicationState is neither of UIApplicationStateInactive or UIApplicationStateBackground.
 
 In application:didFinishLaunchingWithOptions: you should call it if the launchOptions dictionary contains the UIApplicationLaunchOptionsRemoteNotificationKey key, passing in the value for that key, and setting appActive to NO.
 */
+ (void)handlePush:(NSDictionary *)push appActive:(BOOL)appActive;

#pragma mark - Plumbing

/**
 Lets you retrieve the current device token.
 */
+ (NSData *)pushToken;

/**
 Lets you check whether the app has succesfully obtained a device token.
 */
+ (BOOL)hasRegisteredForPush;

/**
 Lets you check whether push for this application has been enabled by the system. You should check this property to and if it returns NO, you can warn/urge the user to go to notification settings and enable notifications for your app.
 */
+ (BOOL)isPushEnabledBySystem;

@end
