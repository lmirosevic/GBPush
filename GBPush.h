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
-(void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo { \
    BOOL appInactive = application.applicationState == UIApplicationStateInactive || application.applicationState == UIApplicationStateBackground; \
    [GBPush handlePush:userInfo appActive:!appInactive]; \
} \
-(void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken { \
    [GBPush systemDidEnablePushWithToken:deviceToken]; \
} \
-(void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error { \
    [GBPush systemFailedToEnablePushWithError:error]; \
}

/**
 Add this at the end of your application:didFinishLaunchingWithOptions: method to pass on the push notification to GBPush when the app is launched via a push notification
 */
#define GBPushAppDidFinishLaunchingWithPushNotificationHook \
NSDictionary *notification = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey]; \
if (notification) [GBPush handlePush:notification appActive:NO];

#pragma mark - Types

typedef void(^GBPushCallCompletionBlock)(id result, BOOL success);
typedef void(^GBPushSubscriptionsPotentiallyChangedHandlerBlock)();
typedef void(^GBPushPushHandlerBlock)(NSDictionary *pushNotification, BOOL appActive);

@interface GBPush : NSObject

#pragma mark - API (Simple)

/**
 Connects to the push registration server.
 */
+(void)connectToServer:(NSString *)server port:(NSUInteger)port;

/**
 Lets you subscribe or unsubscribe from a channel.
 */
+(void)setChannelSubscriptionStatusForChannel:(NSString *)channel subscriptionStatus:(BOOL)subscriptionStatus completed:(GBPushCallCompletionBlock)block;

/**
 Gets the current subscription status for a channel.
 */
+(void)subscriptionStatusForChannel:(NSString *)channel completed:(GBPushCallCompletionBlock)block;

/**
 Returns a list of chanels which you are subscribed to.
 */
+(void)subscribedChannelsWithRange:(GBSharedRange *)range completed:(GBPushCallCompletionBlock)block;

/**
 Set the handler block which should be invoked for whena push message is received
 */
+(void)setPushHanderBlock:(GBPushPushHandlerBlock)block;

#pragma mark - API (Advanced)

/**
 Adds a handler which will be invoked when the list of push channels to which you are subscribed potentially changes, for a context.
 */
+(void)addPushSubscriptionsPotentiallyChangedHandler:(GBPushSubscriptionsPotentiallyChangedHandlerBlock)block forContext:(id)context;

/**
 Removes all handlers for a context for when the push list might change.
 */
+(void)removeAllPushSubscriptionsChangedHandlersForContext:(id)context;

/**
 Lets you subscribe or unsubscribe from a channel. You can set shouldTriggerHandler to NO if you don't want this registration to fire the PushSubscriptionsPotentiallyChanged handlers.
 */
+(void)setChannelSubscriptionStatusForChannel:(NSString *)channel subscriptionStatus:(BOOL)subscriptionStatus completed:(GBPushCallCompletionBlock)block triggerHandler:(BOOL)shouldTriggerHandler;

/**
 Gets the current subscription status for a channel. This call might actualise the internal list of subscribed push channels, if you don't want this to trigger the the PushSubscriptionsPotentiallyChanged handlers, then you can set shouldTriggerHandler to NO.
 */
+(void)subscriptionStatusForChannel:(NSString *)channel completed:(GBPushCallCompletionBlock)block triggerHandler:(BOOL)shouldTriggerHandler;

/**
 Gets the current list of subscribed channels. This call might actualise the internal list of subscribed push channels, if you don't want this to trigger the the PushSubscriptionsPotentiallyChanged handlers, then you can set shouldTriggerHandler to NO.
 */
+(void)subscribedChannelsWithRange:(GBSharedRange *)range completed:(GBPushCallCompletionBlock)block triggerHandler:(BOOL)shouldTriggerHandler;


#pragma mark - AppDelegate hooks

/**
 This should be called from application:didRegisterForRemoteNotificationsWithDeviceToken: passing in the deviceToken, to give GBPush the device token.
 */
+(void)systemDidEnablePushWithToken:(NSData *)pushToken;

/**
 This should be called from application:didFailToRegisterForRemoteNotificationsWithError: passing in the error.
 */
+(void)systemFailedToEnablePushWithError:(NSError *)error;

/**
 This should be called when the app receives a push, to let GBPush take over the rest. You need to call this from 2 AppDelegate methods.
 
 In application:didReceiveRemoteNotification: you should call it passing in the userInfo dictionary, and setting appActive to YES if the applicationState is neither of UIApplicationStateInactive or UIApplicationStateBackground.
 
 In application:didFinishLaunchingWithOptions: you should call it if the launchOptions dictionary contains the UIApplicationLaunchOptionsRemoteNotificationKey key, passing in the value for that key, and setting appActive to NO.
 */
+(void)handlePush:(NSDictionary *)push appActive:(BOOL)appActive;

#pragma mark - Plumbing

/**
 Lets you retrieve the current device token.
 */
+(NSData *)pushToken;

/**
 Lets you check whether push for this application has been enabled by the system. You should check this property to and if it returns NO, you can warn/urge the user to go to notification settings and enable notifications for your app.
 */
+(BOOL)isPushEnabledBySystem;

@end
