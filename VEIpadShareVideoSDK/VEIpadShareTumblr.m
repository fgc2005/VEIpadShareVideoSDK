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

#import "AFNetworkActivityIndicatorManager.h"

#define NSLog_INFO(xx, ...) NSLog(xx, ##__VA_ARGS__)
#define NSLog_DEBUG(xx, ...) NSLog(@"%@ %s %d: " xx, [[NSString stringWithUTF8String:__FILE__] lastPathComponent], __func__, __LINE__, ##__VA_ARGS__)

#define         kOAuth1BaseURLString        @"http://www.tumblr.com"

@interface VEIpadShareTumblr()
<
AFOAuthClientDelegate,
AFJSONRequestOperationDelegate
>
{
    AFOAuth1Client              *_auth1Client;
    AFJSONRequestOperation      *_mAFJSONRequestOperation;
    
    NSString                    *_kConsumerKeyString;
    NSString                    *_isAuthorize;
}

@end

@implementation VEIpadShareTumblr

- (void)dealloc
{
    _observers = nil;
    
    [_auth1Client release];
    _auth1Client = nil;
    
    [_mAFJSONRequestOperation release];
    _mAFJSONRequestOperation = nil;
    
    _kConsumerKeyString = nil;
    
    _isAuthorize = nil;
    
//    [[AFNetworkActivityIndicatorManager sharedManager] setEnabled:NO];
    
    [super dealloc];
}

- (id)initYoutubeWithDelegates:(NSMutableArray *)array
                  developerKey:(NSString *)key
                        secret:(NSString *)secret
{
//    NSLog_DEBUG(@"");
    
    if (0 == key.length || 0 == secret.length)
    {
        NSAssert(1 == 1, @"key or secret not nil");
    }
    
    _observers = array;
    
//    NSLog_DEBUG(@"");
    
    self = [super init];
    
//    NSLog_DEBUG(@"");
    
    if (self)
    {
//        NSLog_DEBUG(@"");
        
        [[AFNetworkActivityIndicatorManager sharedManager] setEnabled:YES];
        
//        NSLog_DEBUG(@"");
        
        _kConsumerKeyString = key;
        
//        NSLog_DEBUG(@"");
        
        _auth1Client = [[AFOAuth1Client alloc]initWithBaseURL:[NSURL URLWithString:kOAuth1BaseURLString] key:key secret:secret];
        [_auth1Client registerHTTPOperationClass:[AFJSONRequestOperation class]];
        [_auth1Client setDefaultHeader:@"Accept" value:@"application/json"];
        
//        NSLog_DEBUG(@"");
    }
    
//    NSLog_DEBUG(@"");

    return self;
}

- (void)checkGotLogin
{
    _isAuthorize = nil;
    _isAuthorize = [[NSUserDefaults standardUserDefaults] objectForKey:@"tumblrIsUploadAuthorizeSuccess"];
    
    if (![_isAuthorize  isEqual: @"YES"])
    {
		[self authorize]; //if we have no auth key saved from a previous session, this will take care of showing the login panel for us
    }
    else
    {
        for (id<VEIpadShareTumblrDelegate> observer in _observers)
        {
            if (observer && [observer respondsToSelector:@selector(tumblrAuthorizet:type:message:)])
            {
                [observer tumblrAuthorizet:YES type:TumblrFailType_NoFail message:@"tumblr authorize success"];
            }
        }
        
    }
}

- (void)authorize
{
//    NSLog_DEBUG(@"debug");
    
    [_auth1Client setDefaultHeader:@"Accept" value:@"application/x-www-form-urlencoded"];
    
//     NSLog_DEBUG(@"debug");
    
    [_auth1Client authorizeUsingOAuthWithRequestTokenPath:@"/oauth/request_token"
                                    userAuthorizationPath:@"/oauth/authorize"
                                              callbackURL:[NSURL URLWithString:@"VEIpadShareVideoSDKSuccess://success"]
                                          accessTokenPath:@"/oauth/access_token"
                                             accessMethod:@"POST"
                                                  success:^(AFOAuth1Token *accessToken )
    {
        
         NSLog_DEBUG(@"debug authorize success");
        
        for (id<VEIpadShareTumblrDelegate> observer in _observers)
        {
            if (observer && [observer respondsToSelector:@selector(tumblrAuthorizet:type:message:)])
            {
                [observer tumblrAuthorizet:YES type:TumblrFailType_NoFail message:@"tumblr authorize success"];
            }
        }
        
//         NSLog_DEBUG(@"debug");
        
        [[NSUserDefaults standardUserDefaults] setObject:@"YES" forKey:@"tumblrIsUploadAuthorizeSuccess"];
        
//         NSLog_DEBUG(@"debug");
        
    } failure:^(NSError *error) {
        
         NSLog_DEBUG(@"debug authorize success");
        
//        [_tumblrDelegate tumblrAuthorizet:NO message:error.localizedDescription];
        
        for (id<VEIpadShareTumblrDelegate> observer in _observers)
        {
            if (observer && [observer respondsToSelector:@selector(tumblrAuthorizet:type:message:)])
            {
//                [observer tumblrAuthorizet:NO message:error.localizedDescription];
                [observer tumblrAuthorizet:NO type:TumblrFailType_Fail message:error.localizedDescription];
            }
        }
        
//        NSLog_DEBUG(@"debug");
        
        [[NSUserDefaults standardUserDefaults] setObject:@"NO" forKey:@"tumblrIsUploadAuthorizeSuccess"];
        
//        NSLog_DEBUG(@"debug");
        
    } AFOAuthClientDelagate:(NSObject<AFOAuthClientDelegate> *)self];
    
    NSLog_DEBUG(@"debug");
}

//This method only accepts video files, please convert to MP3 type the file you want to upload.
-(void)postCreateANewBlogVIDEOPostWithBaseHostname:(NSString *)baseHostname AndSource:(NSString *)external_url OrAudioData:(NSData *)audioData AndParameters:(NSDictionary *)params  videoCaption:(NSString *)caption
                                   AndWithDelegate:(id)delegate{
    
    NSLog_DEBUG(@"");
//    _tumblrDelegate = delegate;
    
    NSMutableDictionary *mutableParameters = [NSMutableDictionary dictionary];
    if (params){
        mutableParameters = [NSMutableDictionary dictionaryWithDictionary:params];
    }
    [mutableParameters setValue:_kConsumerKeyString forKey:@"api_key"];
    [mutableParameters setValue:@"video" forKey:@"type"];
    [mutableParameters setValue:caption forKey:@"caption"];
    
    if (external_url){
        [mutableParameters setValue:external_url forKey:@"external_url"];
    }
    NSDictionary *parameters = [NSDictionary dictionaryWithDictionary:mutableParameters];
    
    NSString *path = [NSString stringWithFormat:@"http://api.tumblr.com/v2/blog/%@/post", baseHostname];
    
    [_auth1Client setDefaultHeader:@"Accept" value:@"application/json"];
    
    if (audioData && !external_url)
    {
        NSData* uploadFile = nil;
        uploadFile = audioData;
        
        NSMutableURLRequest *apiRequest = [_auth1Client multipartFormRequestWithMethod:@"POST" path:path parameters:parameters constructingBodyWithBlock: ^(id <AFMultipartFormData>formData) {
            if (uploadFile) {
                [formData appendPartWithFileData:uploadFile name:@"data" fileName:@"data" mimeType:@"video/H264"];
            }
        }];
        
        _mAFJSONRequestOperation = [[AFJSONRequestOperation alloc] initWithRequest: apiRequest];
        _mAFJSONRequestOperation.aFJSONRequestOperationDelegate = self;
        AFJSONRequestOperation *AFJSONRequest = _mAFJSONRequestOperation;
        [AFJSONRequest setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
            
//            [_tumblrDelegate tumblrUploadVideoResult:YES message:@"tumblr upload video success " ];
            
            for (id<VEIpadShareTumblrDelegate> observer in _observers)
            {
                if (observer && [observer respondsToSelector:@selector(tumblrUploadVideoResult:message:)])
                {
                    [observer tumblrUploadVideoResult:YES message:@"tumblr upload video success " ];
                }
            }
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            
            if([error code] == -1011){
                [[NSUserDefaults standardUserDefaults] setObject:@"NO" forKey:@"tumblrIsUploadAuthorizeSuccess"];
                
//                [_tumblrDelegate tumblrUploadVideoResult:NO message:@"not Authorize!"];
                
                for (id<VEIpadShareTumblrDelegate> observer in _observers)
                {
                    if (observer && [observer respondsToSelector:@selector(tumblrUploadVideoResult:message:)])
                    {
                        [observer tumblrUploadVideoResult:NO message:@"not Authorize!"];
                    }
                }
                
            }else if ([error code] == -999){
                //cancle uploading
                NSLog(@"cancle uploading.....");
            }else{
                
//                [_tumblrDelegate tumblrUploadVideoResult:NO message:error.localizedDescription];
                
                for (id<VEIpadShareTumblrDelegate> observer in _observers)
                {
                    if (observer && [observer respondsToSelector:@selector(tumblrUploadVideoResult:message:)])
                    {
                        [observer tumblrUploadVideoResult:NO message:error.localizedDescription];
                    }
                }
            }
            
            
        }];
        [_mAFJSONRequestOperation start];
        
    }
    else
    {
        [_auth1Client postPath:path parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
            
//            [_tumblrDelegate tumblrUploadVideoResult:YES message:@"tumblr upload video success " ];
            
            for (id<VEIpadShareTumblrDelegate> observer in _observers)
            {
                if (observer && [observer respondsToSelector:@selector(tumblrUploadVideoResult:message:)])
                {
                    [observer tumblrUploadVideoResult:YES message:@"tumblr upload video success " ];
                }
            }
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            
//            [_tumblrDelegate tumblrUploadVideoResult:NO message:error.localizedDescription];
            
            for (id<VEIpadShareTumblrDelegate> observer in _observers)
            {
                if (observer && [observer respondsToSelector:@selector(tumblrUploadVideoResult:message:)])
                {
                    [observer tumblrUploadVideoResult:NO message:error.localizedDescription];
                }
            }
            
        }];
        
    }
    
    
}

- (void)pausedUpload
{
    NSLog_DEBUG(@"");
    [_mAFJSONRequestOperation pause];
}

- (void)resumeUpload
{
    NSLog_DEBUG(@"");
    [_mAFJSONRequestOperation resume];
}

- (void)cancelUpload
{
    NSLog_DEBUG(@"");
    [_mAFJSONRequestOperation cancel];
}

#pragma mark - AFJSONRequestOperationDelegate

- (void)tumblrUploadProgressUpdatedWithBytes:(long)totalBytesWritten ofTotalBytes:(long)totalBytesExpectedToWrite
{
    float percentDone = totalBytesWritten*100.0f/totalBytesExpectedToWrite;
//    [_tumblrDelegate tumblrUploadProgress:percentDone];
    
    for (id<VEIpadShareTumblrDelegate> observer in _observers)
    {
        if (observer && [observer respondsToSelector:@selector(tumblrUploadProgress:)])
        {
            [observer tumblrUploadProgress:percentDone];
        }
    }
}

#pragma mark - AFOAuthClientDelegate

- (void)oAuthClientOpenURL:(NSURL *)url
{
//    if(_tumblrDelegate){
//        [_tumblrDelegate tumblrOpenLoginURL:url];
//    }
//    NSLog_DEBUG("_observers = %@", _observers);
    
    for (id<VEIpadShareTumblrDelegate> observer in _observers)
    {
        if (observer && [observer respondsToSelector:@selector(tumblrOpenLoginURL:)])
        {
            [observer tumblrOpenLoginURL:url];
        }
    }
}

@end
