//
//  VEIpadShareFlickr.h
//  VE
//
//  Created by chao on 13-10-11.
//  Copyright (c) 2013年 Sikai. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum
{
    DidGetLoginTokenFailType_NoFail,
    DidGetLoginTokenFailType_NoResponse,
}
DidGetLoginTokenFailType;

typedef enum
{
    FlickrAuthenticateFailType_NoFail,
    FlickrAuthenticateFailType_NoTokenReturn,
}
FlickrAuthenticateFailType;

typedef enum
{
    FlickrAccessTokenFailType_NoFail,
    FlickrAccessTokenFailType_Fail,
}
FlickrAccessTokenFailType;

typedef enum
{
    FlickrUploadFailType_NoFail,
    FlickrUploadFailType_Fail,
    FlickrUploadFailType_LongTime,
}
FlickrUploadFailType;

@protocol VEIpadShareFlickrDelegate <NSObject>

@optional
- (void)flickrNetworkIsCorrect:(BOOL)isCorrect;
- (void)flickrIsStoreTokenValid:(BOOL)isValid;
- (void)flickrDidGetLoginTokenIsSuccess:(BOOL)isSuccess withRequest:(NSURLRequest *)request withFailType:(DidGetLoginTokenFailType)type;
- (void)flickrAuthenticateIsSuccess:(BOOL)isSuccess withFailType:(FlickrAuthenticateFailType)type;
- (void)flickrIsAccessTokenSuccess:(BOOL)isSuccess withUsername:(NSString *)username withFailType:(FlickrAccessTokenFailType)type;

- (void)flickrUploadIsFinished:(BOOL)isSuccess withReturnURL:(NSURL *)returnURL withFailType:(FlickrUploadFailType)type;
- (void)flickrUploadUpdatedWithBytes:(long)totalBytesWritten ofTotalBytes:(long)totalBytesExpectedToWrite;

@end

@interface VEIpadShareFlickr : NSObject
{
    NSString            *_applicationKey;
    NSString            *_applicationSecret;
    
    NSMutableArray      *_observers;
    
    NSURLConnection     *_uploader;
    
    NSMutableData       *_resultData;
    
//    NSString        *_timestamp;
//    NSString        *_nonce;
}

//@property(nonatomic, assign) id<VEIpadShareFlickrDelegate>      delegate;
@property(nonatomic, assign, readonly) BOOL                     isSendAsynReq;

//  按此步骤执行验证

- (id)initWithDelegates:(NSMutableArray *)array
		applicationKey:(NSString *)key
	 applicationSecret:(NSString *)secret;

//  从开始检查网络开始
- (void)go:(BOOL)isAsyn;

//  检查网络, 回调或者直接返回BOOL
- (void)checkFlickrInternet;

//  检查token，如果token验证通过，进入登陆状态，否则需要登陆。
- (void)checkFlickrIsStoreTokenValid;

/**
 1 . 2
 簽署要求
 
 你必須向 Flickr API 簽署所有要求。 目前，Flickr 僅支援 HMAC-SHA1 簽章加密。
 
 首先，你必須在你的要求中建立基本字串。 此基本字串由 HTTP 動詞、要求 URL 和所有按名稱排序 (使用字典位元組值排序法) 的要求參數串連構成，並以「&」隔開。
 
 使用諸如 text 的基本字串，而 key 是以「&」隔開的消費者密鑰和記錄密鑰的串連值。
 
 以使用以下 URL 為例：
 
 http://www.flickr.com/services/oauth/request_token
 ?oauth_nonce=89601180
 &oauth_timestamp=1305583298
 &oauth_consumer_key=653e7a6ecc1d528c516cc8f92cf98611
 &oauth_signature_method=HMAC-SHA1
 &oauth_version=1.0
 &oauth_callback=http%3A%2F%2Fwww.example.com
 以下為基本字串的例範：
 
 GET&http%3A%2F%2Fwww.flickr.com%2Fservices%2Foauth%2Frequest_token&oauth_callback%3Dhttp%253A%252F%252Fwww.example.com%26oauth_consumer_key%3D653e7a6ecc1d528c516cc8f92cf98611%26oauth_nonce%3D95613465%26oauth_signature_method%3DHMAC-SHA1%26oauth_timestamp%3D1305586162%26oauth_version%3D1.0
 
 */


// 3 . 取得要求記錄
//  获取登陆页面的权限，如果成功，会返回URL给客户端
- (void)flickrRequestLoginPageToken;

//  对网页返回来的结果进行分析, 判断是否取得使用者授權
- (void)flickrHandleOpenURL:(NSURL *)url;

//  交換要求記錄，以取得存取記錄的權限.从页面认证成功后，可以获取信息
- (void)flickrAccessToken;

- (void)uploadVideoAtURL:(NSURL *)url
                   title:(NSString *)title
             description:(NSString *)description
                    tags:(NSString *)tags
             makePrivate:(BOOL)makePrivate;

@end
