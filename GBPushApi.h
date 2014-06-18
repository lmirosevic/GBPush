//
//  GBPushApi.h
//  GBPush
//
//  Created by Luka Mirosevic on 27/04/2014.
//  Copyright (c) 2014 Goonbee. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <GBThriftApi/GBThriftApi.h>

#import "GoonbeePushService.h"

@interface GBPushApi : GBThriftApi

-(void)setChannelSubscriptionStatusWithPushToken:(NSData *)token channel:(NSString *)channel subscriptionStatus:(BOOL)subscriptionStatus completed:(GBThriftCallCompletionBlock)block;
-(void)subscribedChannelsForPushToken:(NSData *)token range:(GBSharedRange *)range completed:(GBThriftCallCompletionBlock)block;
-(void)subscriptionStatusForPushToken:(NSData *)token channel:(NSString *)channel completed:(GBThriftCallCompletionBlock)block;

@end
