//
//  GBPush.h
//  GBPush
//
//  Created by Luka Mirosevic on 27/04/2014.
//  Copyright (c) 2014 Goonbee. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "GBPushApi.h"

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

typedef void(^GBPushCallCompletionBlock)(BOOL success);
typedef void(^GBPushPushHandlerBlock)(NSDictionary *pushNotification, BOOL appActive);

@interface GBPush : NSObject

#pragma mark - Main API

+(void)connectToServer:(NSString *)server port:(NSUInteger)port;

+(void)setChannelSubscriptionStatusForChannel:(NSString *)channel subscriptionStatus:(BOOL)subscriptionStatus completed:(GBPushCallCompletionBlock)block;
+(void)subscriptionStatusForChannel:(NSString *)channel completed:(GBPushCallCompletionBlock)block;
+(void)subscribedChannelsWithRange:(GBSharedRange *)range completed:(GBPushCallCompletionBlock)block;
+(void)setPushHanderBlock:(GBPushPushHandlerBlock)block;

#pragma mark - AppDelegate hooks

+(void)systemDidEnablePushWithToken:(NSData *)pushToken;
+(void)systemFailedToEnablePushWithError:(NSError *)error;
+(void)handlePush:(NSDictionary *)push appActive:(BOOL)appActive;

#pragma mark - Plumbing

+(NSData *)pushToken;
+(BOOL)isPushEnabledBySystem;

@end
