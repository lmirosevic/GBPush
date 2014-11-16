//
//  GBPush.m
//  GBPush
//
//  Created by Luka Mirosevic on 27/04/2014.
//  Copyright (c) 2014 Goonbee. All rights reserved.
//

#import "GBPush.h"

#import <malloc/malloc.h>

#import <thrift/TSocketClient.h>
#import <thrift/TBinaryProtocol.h>
#import <thrift/TTransportException.h>
#import <GBToolbox/GBToolbox.h>
#import <GBStorage/GBStorage.h>

static NSString * const kGBStorageNamespace =                                       @"com.goonbee.GBPush.GBStorage";
static NSString * const kPushManagerToken =                                         @"PushToken";

static UIRemoteNotificationType const kLegacyDesiredNotificationTypes =             (UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert);

typedef void(^GBPushInternalTokenAbstractionBlock)(NSData *token);

#define kGBPushManagerThriftAugmentedBlock(block, shouldTriggerHandler) ^(int status, id result, BOOL cancelled) { \
    if (status == ResponseStatus_SUCCESS) { \
        if (block) block(result, YES); \
        if (shouldTriggerHandler) [self _callAllSubscriptionsPotentiallyChangedHandlerBlocks]; \
    } \
    else { \
        if (block) block(nil, NO); \
    } \
}

@interface GBPush ()

@property (strong, nonatomic) NSMutableArray                                        *commandQueue;
@property (copy, nonatomic) GBPushPushHandlerBlock                                  pushHandlerBlock;

@property (strong, nonatomic) NSMapTable                                            *handlersForContext;

@property (copy, nonatomic) GBPushUserNotificationPermissionRequestCompletedBlock   userNotificationsPermissionRequestBlock;
@property (assign, nonatomic) BOOL                                                  isRequestForPermissionsForShowingUserNotificationsInProgress;

@end

@implementation GBPush

#pragma mark - Life

+ (GBPush *)sharedPush {
    static GBPush *_sharedPush;
    @synchronized(self) {
        if (!_sharedPush) {
            _sharedPush = [self.class new];
        }
    }
    
    return _sharedPush;
}

- (id)init {
    if (self = [super init]) {
        self.commandQueue = [NSMutableArray new];
        self.handlersForContext = [NSMapTable new];
        self.isRequestForPermissionsForShowingUserNotificationsInProgress = NO;
    }
    
    return self;
}

#pragma mark - API (Basics)

+ (void)connectToServer:(NSString *)server port:(NSUInteger)port {
    [[GBPushApi sharedApi] connectToServer:server port:port];
}

+ (void)setChannelSubscriptionStatusForChannel:(NSString *)channel subscriptionStatus:(BOOL)subscriptionStatus completed:(GBPushCallCompletionBlock)block {
    [self setChannelSubscriptionStatusForChannel:channel subscriptionStatus:subscriptionStatus completed:block triggerHandler:YES];
}

+ (void)subscriptionStatusForChannel:(NSString *)channel completed:(GBPushCallCompletionBlock)block {
    [self subscriptionStatusForChannel:channel completed:block triggerHandler:YES];
}

+ (void)subscribedChannelsWithRange:(GBSharedRange *)range completed:(GBPushCallCompletionBlock)block {
    [self subscribedChannelsWithRange:range completed:block triggerHandler:YES];
}

+ (void)setChannelSubscriptionStatusForChannel:(NSString *)channel subscriptionStatus:(BOOL)subscriptionStatus completed:(GBPushCallCompletionBlock)block triggerHandler:(BOOL)shouldTriggerHandler {
    [[self sharedPush] _callCommandWhenPushAvailable:^(NSData *token) {
        if (token) {
            [[GBPushApi sharedApi] setChannelSubscriptionStatusWithPushToken:token channel:channel subscriptionStatus:subscriptionStatus completed:kGBPushManagerThriftAugmentedBlock(block, shouldTriggerHandler)];
        }
        else {
            if (block) block(nil, NO);
        }
    }];
}

+ (void)subscriptionStatusForChannel:(NSString *)channel completed:(GBPushCallCompletionBlock)block triggerHandler:(BOOL)shouldTriggerHandler {
    [[self sharedPush] _callCommandWhenPushAvailable:^(NSData *token) {
        if (token) {
            [[GBPushApi sharedApi] subscriptionStatusForPushToken:token channel:channel completed:kGBPushManagerThriftAugmentedBlock(block, shouldTriggerHandler)];
        }
        else {
            if (block) block(nil, NO);
        }
    }];
}

+ (void)subscribedChannelsWithRange:(GBSharedRange *)range completed:(GBPushCallCompletionBlock)block triggerHandler:(BOOL)shouldTriggerHandler {
    [[self sharedPush] _callCommandWhenPushAvailable:^(NSData *token) {
        if (token) {
            [[GBPushApi sharedApi] subscribedChannelsForPushToken:token range:range completed:kGBPushManagerThriftAugmentedBlock(block, shouldTriggerHandler)];
        }
        else {
            if (block) block(nil, NO);
        }
    }];
}

+ (void)setPushHanderBlock:(GBPushPushHandlerBlock)block {
    [[self sharedPush] setPushHandlerBlock:block];
}

+ (void)requestPermissionForShowingUserNotificationTypes:(GBPushUserNotificationType)types completed:(GBPushUserNotificationPermissionRequestCompletedBlock)block {
    // if the user wants the silent notifications
    if (types == GBPushUserNotificationTypeSilent) {
        // then we should warn him if he has not included the remote-notification key in the UIBackgroundModes array
        if (![InfoPlist[@"UIBackgroundModes"] containsObject:@"remote-notification"]) {
            NSLog(@"You've asked for permissions for silent notifications, but you still need to add \"remote-notification\" to the list of your supported UIBackgroundModes in your Info.plist.");
        }
    }
    
    // this method has no effect on iOS versions 7 and below. It's only relevant for iOS 8+ where we need to request permissions to notifiy the user.
    if ([[UIApplication sharedApplication] respondsToSelector:@selector(registerUserNotificationSettings:)]) {
        // make sure we're not already checking for this
        if (![self isRequestForPermissionsForShowingUserNotificationsInProgress]) {
            [self sharedPush].isRequestForPermissionsForShowingUserNotificationsInProgress = YES;
            
            // check if the currently permitted user notification types differ from what we want
            if (![self _areAllRequestedPermissionsAlreadyPermitted:types]) {
                // store out callback
                [self sharedPush].userNotificationsPermissionRequestBlock = block;
                
                // fire off the request to the system
                [[UIApplication sharedApplication] registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:(UIUserNotificationType)types categories:nil]];
            }
            // if they don't differ
            else {
                // call the block immediately
                if (block) block([self currentPermittedUserNotificationTypes], NO);
            }
        }
        else {
            NSLog(@"GBPush: requestPermissionForShowingUserNotificationTypes:completed: can only be called once at a time, you must wait for the previous call to finish before calling it again. Doing nothing, your handler will not get called!");
        }
    }
    // iOS 7 or below
    else {
        if (block) block([self currentPermittedUserNotificationTypes], NO);
        // noop. Permissions are gathered automatically when registering for remote notifications
    }
}

+ (GBPushUserNotificationType)currentPermittedUserNotificationTypes {
    // this method has no effect on iOS versions 7 and below. It's only relevant for iOS 8+ where we need to request permissions to notifiy the user.
    if ([[UIApplication sharedApplication] respondsToSelector:@selector(registerUserNotificationSettings:)]) {
        // we can just cast it because our bitmask is defined in terms of UIUserNotificationType. The reason for this is that it adds a layer of abstraction between our library and the UIUserNotificationType bitmask which might change or get deprecated in the future, if/when that happens we can no longer cast here and will have to convert.
        return (GBPushUserNotificationType)[[UIApplication sharedApplication] currentUserNotificationSettings].types;
    }
    // iOS 7 and below
    else {
        // on older systems we just need to check if we are registered for push, if so we know all the notification types we requested are granted, if we're not registered then nothing was granted.
        return ([self hasRegisteredForPush] ? (GBPushUserNotificationType)kLegacyDesiredNotificationTypes : GBPushUserNotificationTypeSilent);
    }
}

#pragma mark - API (Advanced)

+ (BOOL)isRequestForPermissionsForShowingUserNotificationsInProgress {
    return [GBPush sharedPush].isRequestForPermissionsForShowingUserNotificationsInProgress;
}

+ (void)addPushSubscriptionsPotentiallyChangedHandler:(GBPushSubscriptionsPotentiallyChangedHandlerBlock)block forContext:(id)context {
    if (!context) @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"Must pass in a non-nil context" userInfo:nil];
    
    // lazy creation of bucket
    if (![self sharedPush].handlersForContext[context]) {
        [self sharedPush].handlersForContext[context] = [NSMutableSet new];
    }
    
    // add the handler
    [[self sharedPush].handlersForContext[context] addObject:[block copy]];

}

+ (void)removeAllPushSubscriptionsChangedHandlersForContext:(id)context {
    if (!context) @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"Must pass in a non-nil context" userInfo:nil];
    
    [[self sharedPush].handlersForContext removeObjectForKey:context];
}

#pragma mark - AppDelegate hooks

+ (void)systemDidEnablePushWithToken:(NSData *)pushToken {
    // store the token
    GBStorage(kGBStorageNamespace)[kPushManagerToken] = pushToken;
    [GBStorage(kGBStorageNamespace) save:kPushManagerToken];
    
    // process the command queue
    [[self sharedPush] _processCommandQueue];
}

+ (void)systemFailedToEnablePushWithError:(NSError *)error {
    // clear the token
    [GBStorage(kGBStorageNamespace) removePermanently:kPushManagerToken];
    
    // process the command queue
    [[self sharedPush] _processCommandQueue];
}

+ (void)systemDidFinishRequestingUserNotificationPermissions {
    // we are no longer in the process of requesting
    [self sharedPush].isRequestForPermissionsForShowingUserNotificationsInProgress = NO;
    
    // call our block, it will get the outcome by querying +[UIApplication sharedApplication] because that is the source of truth.
    [self _callUserNotificationsPermissionRequestBlock];
}

+ (void)handlePush:(NSDictionary *)push appActive:(BOOL)appActive completionHandler:(GBSystemPushCompletionHandlerBlock)completionHandler {
    // call the stored handler
    if ([[self sharedPush] pushHandlerBlock]) [[self sharedPush] pushHandlerBlock](push, appActive, completionHandler);
}

#pragma mark - Plumbing

+ (NSData *)pushToken {
    // get the push token as stored
    return GBStorage(kGBStorageNamespace)[kPushManagerToken];
}

+ (BOOL)hasRegisteredForPush {
    return ([self pushToken] != nil);
}

+ (BOOL)isPushEnabledBySystem {
    return !IsPushDisabled();
}

#pragma mark - Private

+ (void)_callUserNotificationsPermissionRequestBlock {
    // get singleton
    GBPush *sharedPush = [self sharedPush];
    
    // call our block if we had one
    if (sharedPush.userNotificationsPermissionRequestBlock) sharedPush.userNotificationsPermissionRequestBlock([self currentPermittedUserNotificationTypes], YES);
    
    // release the block
    sharedPush.userNotificationsPermissionRequestBlock = nil;
}

+ (BOOL)_areAllRequestedPermissionsAlreadyPermitted:(GBPushUserNotificationType)requestPermissions {
    return IsBitmaskASubsetOfBitmaskB(requestPermissions, [self currentPermittedUserNotificationTypes]);
}

+ (void)_callAllSubscriptionsPotentiallyChangedHandlerBlocks {
    for (id context in [self sharedPush].handlersForContext) {
        for (GBPushSubscriptionsPotentiallyChangedHandlerBlock updateHandler in [self sharedPush].handlersForContext[context]) {
            updateHandler();
        }
    }
}

+ (void)_requestPushPermissionsIfNeeded {
    // if we don't have a push token yet, try to get one
    if (![self pushToken]) {
        //iOS 8+
        if ([[UIApplication sharedApplication] respondsToSelector:@selector(registerForRemoteNotifications)]) {
            [[UIApplication sharedApplication] registerForRemoteNotifications];
        }
        //iOS 7 and below
        else {
            [[UIApplication sharedApplication] registerForRemoteNotificationTypes:kLegacyDesiredNotificationTypes];
        }
    }
    // we have a token already
    else {
        // noop
    }
}

- (void)_callCommandWhenPushAvailable:(GBPushInternalTokenAbstractionBlock)command {
    if ([self.class pushToken]) {
        // call command immediately
        command([self.class pushToken]);
    }
    else {
        // defer the command until the push token is available
        [[self.class sharedPush] _enqueueCommandAsBlock:command];
        
        // request a push token from the system
        [self.class _requestPushPermissionsIfNeeded];
    }
}

- (void)_enqueueCommandAsBlock:(GBPushInternalTokenAbstractionBlock)block {
    [self.commandQueue addObject:[block copy]];
}

- (void)_processCommandQueue {
    NSData *token = [self.class pushToken];// could be nil, that's ok
    
    for (GBPushInternalTokenAbstractionBlock command in self.commandQueue) {
        command(token);
    }
    
    [self.commandQueue removeAllObjects];
}

@end

