//
//  VEIpadShareTumblr.h
//  VEIpadShareVideoSDK
//
//  Created by chao on 13-11-13.
//  Copyright (c) 2013年 Sachsen. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum
{
    TumblrFailType_NoFail,
    TumblrFailType_Fail,
}
TumblrFailType;

@protocol VEIpadShareTumblrDelegate <NSObject>

@optional
- (void)tumblrOpenLoginURL:(NSURL *)url;
- (void)tumblrUploadVideoResult:(BOOL)isSuccess message:(NSString *)message;
- (void)tumblrUploadProgress:(float)progress;
//- (void)tumblrAuthorizet:(BOOL)isSuccess message:(NSString *)message;
- (void)tumblrAuthorizet:(BOOL)isSuccess type:(TumblrFailType)type message:(NSString *)message;

@end

@interface VEIpadShareTumblr : NSObject
{
    NSMutableArray                                          *_observers;
//    id <VEIpadShareTumblrDelegate>                          _tumblrDelegate;
}

- (id)initYoutubeWithDelegates:(NSMutableArray *)array
                  developerKey:(NSString *)key
                        secret:(NSString *)secret;

- (void)postCreateANewBlogVIDEOPostWithBaseHostname:(NSString *)baseHostname AndSource:(NSString *)external_url OrAudioData:(NSData *)audioData AndParameters:(NSDictionary *)params videoCaption:(NSString *)caption AndWithDelegate:(id)AndWithDelegate;

- (void)cancelUpload;
- (void)pausedUpload;
- (void)resumeUpload;
- (void)checkGotLogin;

@end
