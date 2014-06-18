//
//  GBPushApi.m
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

@implementation GBPushApi

#pragma mark - Overrides

+(Class)thriftServiceClass {
    return GBPushGoonbeePushServiceClient.class;
}

#pragma mark - Life

+(instancetype)sharedPushApi {
    static GBPushApi *_sharedPushApi;
    @synchronized(self) {
        if (!_sharedPushApi) {
            _sharedPushApi = [self.class new];
        }
    }
    
    return _sharedPushApi;
}

#pragma mark - API calls

-(void)setChannelSubscriptionStatusWithPushToken:(NSData *)token channel:(NSString *)channel subscriptionStatus:(BOOL)subscriptionStatus completed:(GBThriftCallCompletionBlock)block {
    GBPushPushToken *pushToken = [self.class _iOSPushTokenForToken:token];
    [self callAPIMethodWithSelector:@selector(setChannelSubscriptionStatus:channel:subscriptionStatus:) block:block arguments:&pushToken, &channel, &subscriptionStatus, nil];
}

-(void)subscribedChannelsForPushToken:(NSData *)token range:(GBSharedRange *)range completed:(GBThriftCallCompletionBlock)block {
    GBPushPushToken *pushToken = [self.class _iOSPushTokenForToken:token];
    [self callAPIMethodWithSelector:@selector(subscribedChannels:range:) block:block arguments:&pushToken, &range, nil];
}

-(void)subscriptionStatusForPushToken:(NSData *)token channel:(NSString *)channel completed:(GBThriftCallCompletionBlock)block {
    GBPushPushToken *pushToken = [self.class _iOSPushTokenForToken:token];
    [self callAPIMethodWithSelector:@selector(subscriptionStatus:channel:) block:block arguments:&pushToken, &channel, nil];
}

#pragma mark - Util

+(GBPushPushToken *)_iOSPushTokenForToken:(NSData *)token {
    return [[GBPushPushToken alloc] initWithType:PushTokenType_APNS token:[[NSString alloc] initWithData:token encoding:NSUTF8StringEncoding]];
}

@end
