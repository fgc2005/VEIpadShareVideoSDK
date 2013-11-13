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
    DidGetLoginTokenFailType_ResponseDataError,
}
DidGetLoginTokenFailType;

typedef enum
{
    FlickrAuthenticateFailType_NoFail,
    FlickrAuthenticateFailType_NoOauthTokenReturn,
    FlickrAuthenticateFailType_NoVerifierReturn
}
FlickrAuthenticateFailType;

typedef enum
{
    FlickrAccessTokenFailType_NoFail,
    FlickrAccessTokenFailType_NullInputToken,
    FlickrAccessTokenFailType_NoResponse,
    FlickrAccessTokenFailType_ResponseDataError,
    FlickrAccessTokenFailType_NullToken,
    FlickrAccessTokenFailType_ResponseCodeError
}
FlickrAccessTokenFailType;

typedef enum
{
    FlickrUploadFailType_NoFail,
    FlickrUploadFailType_NullInputURL,
    FlickrUploadFailType_NullInputAuthToken,
    FlickrUploadFailType_NullInputOaconsumer,
    FlickrUploadFailType_NullInputUploader,
    FlickrUploadFailType_LongTime,
    FlickrUploadFailType_NoPhotoID,
    FlickrUploadFailType_ResponseNull,
    FlickrUploadFailType_ResponseHasErrorInfo,
    FlickrUploadFailType_FailedIs1Info,
    FlickrUploadFailType_NetwordFail,
    FlickrUploadFailType_ResponseHasErrorInfoInCheckIsfinish,
    FlickrUploadFailType_NOFoundPhotoIDInCheckIsfinish,
    
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


//  获取登陆页面的权限，如果成功，会返回URL给客户端
- (void)flickrRequestLoginPageToken;

//  对网页返回来的结果进行分析, 判断是否取得使用者授權
- (void)flickrHandleOpenURL:(NSURL *)url;

/**
 // 3 . 取得要求記錄
 交換要求記錄，以取得存取記錄的權限
 
 存取記錄 URL:
 
 http://www.flickr.com/services/oauth/access_token
 
 使用者授權你的應用程式後，你可以交換核准的要求記錄以取得存取記錄。 此存取記錄應由你的應用程式儲存，用於向 Flickr 作出授權要求。
 
 以下是要求存取記錄的範例：
 
 http://www.flickr.com/services/oauth/access_token
 ?oauth_nonce=37026218
 &oauth_timestamp=1305586309
 &oauth_verifier=5d1b96a26b494074
 &oauth_consumer_key=653e7a6ecc1d528c516cc8f92cf98611
 &oauth_signature_method=HMAC-SHA1
 &oauth_version=1.0
 &oauth_token=72157626737672178-022bbd2f4c2f3432
 &oauth_signature=UD9TGXzrvLIb0Ar5ynqvzatM58U%3D
 Flickr 會傳回類似於以下內容的回覆：
 
 fullname=Jamal%20Fanaian
 &oauth_token=72157626318069415-087bfc7b5816092c
 &oauth_token_secret=a202d1f853ec69de
 &user_nsid=21207597%40N07
 &username=jamalfanaian
 */
//  交換要求記錄，以取得存取記錄的權限.从页面认证成功后，可以获取信息
- (void)flickrAccessToken;

- (void)uploadVideoAtURL:(NSURL *)url
                   title:(NSString *)title
             description:(NSString *)description
                    tags:(NSString *)tags
             makePrivate:(BOOL)makePrivate;
//取消上传操作
- (void)cancelUploader ;
@end
