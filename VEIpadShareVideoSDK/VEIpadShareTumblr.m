//
//  VEIpadShareTumblr.m
//  VEIpadShareVideoSDK
//
//  Created by chao on 13-11-13.
//  Copyright (c) 2013年 Sachsen. All rights reserved.
//

#import "VEIpadShareTumblr.h"

#import "AFOAuth1Client.h"
#import "AFJSONRequestOperation.h"

#define         kOAuth1BaseURLString        @"http://www.tumblr.com"

@interface VEIpadShareTumblr()
{
    NSString                    *_kConsumerKeyString;
    AFOAuth1Client              *_auth1Client;
}

@end

@implementation VEIpadShareTumblr

- (id)initYoutubeWithDelegates:(NSMutableArray *)array
                  developerKey:(NSString *)key
                        secret:(NSString *)secret
{
    if (0 == key.length || 0 == secret.length)
    {
        NSAssert(1 == 1, @"key or secret not nil");
    }
    
    self = [super init];
    
    if (self)
    {
        _kConsumerKeyString = key;
        
        _auth1Client = [[AFOAuth1Client alloc]initWithBaseURL:[NSURL URLWithString:kOAuth1BaseURLString] key:key secret:secret];
    }

    return self;
}

@end
