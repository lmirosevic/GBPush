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

@implementation GBPush

#pragma mark - Overrides

+(Class)thriftServiceClass {
    return GBPushGoonbeePushServiceClient.class;
}

#pragma mark - API calls

-(void)setChannelSubscriptionStatusWithPushToken:(GBPushPushToken *)pushToken channel:(NSString *)channel subscriptionStatus:(BOOL)subscriptionStatus completed:(GBThriftCallCompletionBlock)block {
    [self callAPIMethodWithSelector:@selector(setChannelSubscriptionStatus:channel:subscriptionStatus:) block:block arguments:&pushToken, &channel, &subscriptionStatus, nil];
}

-(void)subscribedChannelsForPushToken:(GBPushPushToken *)pushToken range:(GBSharedRange *)range completed:(GBThriftCallCompletionBlock)block {
    [self callAPIMethodWithSelector:@selector(subscribedChannels:range:) block:block arguments:&pushToken, &range, nil];
}

-(void)subscriptionStatusForPushToken:(GBPushPushToken *)pushToken channel:(NSString *)channel completed:(GBThriftCallCompletionBlock)block {
    [self callAPIMethodWithSelector:@selector(subscriptionStatus:channel:) block:block arguments:&pushToken, &channel, nil];
}

@end
