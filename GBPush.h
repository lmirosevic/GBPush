//
//  GBPush.h
//  GBPush
//
//  Created by Luka Mirosevic on 27/04/2014.
//  Copyright (c) 2014 Goonbee. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <GBThriftApi/GBThriftApi.h>

#import "GoonbeePushService.h"

@interface GBPush : GBThriftApi

-(void)setChannelSubscriptionStatusWithPushToken:(GBPushPushToken *)pushToken channel:(NSString *)channel subscriptionStatus:(BOOL)subscriptionStatus completed:(GBThriftCallCompletionBlock)block;
-(void)subscribedChannelsForPushToken:(GBPushPushToken *)pushToken range:(GBSharedRange *)range completed:(GBThriftCallCompletionBlock)block;
-(void)subscriptionStatusForPushToken:(GBPushPushToken *)pushToken channel:(NSString *)channel completed:(GBThriftCallCompletionBlock)block;

@end
