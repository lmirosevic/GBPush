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

static NSString * const kNamespace =                                    @"wcsg.push";
static NSString * const kPushManagerToken =                             @"PushToken";

typedef void(^GBPushInternalTokenAbstractionBlock)(NSData *token);

#define kGBPushManagerThriftTranslatedBlock(block) ^(int status, id result, BOOL cancelled) { \
    if (status == ResponseStatus_SUCCESS) { \
        if (block) block(YES); \
    } \
    else { \
        if (block) block(NO); \
    } \
}

@interface GBPush ()

@property (strong, nonatomic) NSMutableArray                            *commandQueue;
@property (copy, nonatomic) GBPushPushHandlerBlock                      pushHandlerBlock;

@end

@implementation GBPush

#pragma mark - Life

+(instancetype)sharedPush {
    static GBPush *_sharedPush;
    @synchronized(self) {
        if (!_sharedPush) {
            _sharedPush = [self.class new];
        }
    }
    
    return _sharedPush;
}

-(id)init {
    if (self = [super init]) {
        self.commandQueue = [NSMutableArray new];
    }
    
    return self;
}

#pragma mark - API

+(void)connectToServer:(NSString *)server port:(NSUInteger)port {
    [[GBPushApi sharedApi] connectToServer:server port:port];
}

+(void)setChannelSubscriptionStatusForChannel:(NSString *)channel subscriptionStatus:(BOOL)subscriptionStatus completed:(GBPushCallCompletionBlock)block {
    [[self sharedPush] _callCommandWhenPushAvailable:^(NSData *token) {
        if (token) {
            [[GBPushApi sharedApi] setChannelSubscriptionStatusWithPushToken:token channel:channel subscriptionStatus:subscriptionStatus completed:kGBPushManagerThriftTranslatedBlock(block)];
        }
        else {
            if (block) block(NO);
        }
    }];
}

+(void)subscriptionStatusForChannel:(NSString *)channel completed:(GBPushCallCompletionBlock)block {
    [[self sharedPush] _callCommandWhenPushAvailable:^(NSData *token) {
        if (token) {
            [[GBPushApi sharedApi] subscriptionStatusForPushToken:token channel:channel completed:kGBPushManagerThriftTranslatedBlock(block)];
        }
        else {
            if (block) block(NO);
        }
    }];
}

+(void)subscribedChannelsWithRange:(GBSharedRange *)range completed:(GBPushCallCompletionBlock)block {
    [[self sharedPush] _callCommandWhenPushAvailable:^(NSData *token) {
        if (token) {
            [[GBPushApi sharedApi] subscribedChannelsForPushToken:token range:range completed:kGBPushManagerThriftTranslatedBlock(block)];
        }
        else {
            if (block) block(NO);
        }
    }];
}

+(void)setPushHanderBlock:(GBPushPushHandlerBlock)block {
    [[self sharedPush] setPushHandlerBlock:block];
}

#pragma mark - AppDelegate hooks

+(void)systemDidEnablePushWithToken:(NSData *)pushToken {
    // store the token
    GBStorage(kNamespace)[kPushManagerToken] = pushToken;
    [GBStorage(kNamespace) save:kPushManagerToken];
    
    // process the command queue
    [[self sharedPush] _processCommandQueue];
}

+(void)systemFailedToEnablePushWithError:(NSError *)error {
    // clear the token
    [GBStorage(kNamespace) removePermanently:kPushManagerToken];
    
    // process the command queue
    [[self sharedPush] _processCommandQueue];
}

+(void)handlePush:(NSDictionary *)push appActive:(BOOL)appActive {
    // call the stored handler
    if ([[self sharedPush] pushHandlerBlock]) [[self sharedPush] pushHandlerBlock](push, appActive);
}

#pragma mark - Plumbing

+(NSData *)pushToken {
    // get the push token as stored
    return GBStorage(kNamespace)[kPushManagerToken];
}

+(BOOL)isPushEnabledBySystem {
    return !IsPushDisabled();
}

#pragma mark - Util

+(void)_requestPushPermissionsIfNeeded {
    // if we don't have a push token yet, try to get one
    if (![self pushToken]) {
        [[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert)];
    }
    // we have a token already
    else {
        // noop
    }
}

-(void)_callCommandWhenPushAvailable:(GBPushInternalTokenAbstractionBlock)command {
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

-(void)_enqueueCommandAsBlock:(GBPushInternalTokenAbstractionBlock)block {
    [self.commandQueue addObject:[block copy]];
}

-(void)_processCommandQueue {
    NSData *token = [self.class pushToken];// could be nil, that's ok
    
    for (GBPushInternalTokenAbstractionBlock command in self.commandQueue) {
        command(token);
    }
    
    [self.commandQueue removeAllObjects];
}

@end

