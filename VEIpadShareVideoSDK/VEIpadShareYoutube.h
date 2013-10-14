//
//  VEIpadShareYoutube.h
//  VE
//
//  Created by chao on 13-10-9.
//  Copyright (c) 2013年 Sikai. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum
{
    YoutubeAuthorizeFailType_NoFail,
    YoutubeAuthorizeFailType_TokenNull,
    YoutubeAuthorizeFailType_TokenError,
    YoutubeAuthorizeFailType_Fail,
}
YoutubeAuthorizeFailType;

typedef enum
{
    YoutubeUploadFailType_NoFail,
    YoutubeUploadFailType_NetworkError,
    YoutubeUploadFailType_ResponseDataNull,
    YoutubeUploadFailType_videoIDNull,
    
    YoutubeUploadFailType_NoVideoTag,
    YoutubeUploadFailType_RequesterRegion,
    YoutubeUploadFailType_LimitedSyndication,
    YoutubeUploadFailType_Private,
    YoutubeUploadFailType_Copyright,
    YoutubeUploadFailType_Inappropriate,
    YoutubeUploadFailType_Duplicate,
    YoutubeUploadFailType_TermsOfUse,
    YoutubeUploadFailType_Suspended,
    YoutubeUploadFailType_TooLong,
    YoutubeUploadFailType_Blocked,
    YoutubeUploadFailType_CantProcess,
    YoutubeUploadFailType_InvalidFormat,
    YoutubeUploadFailType_UnsupportedCodec,
    YoutubeUploadFailType_Empty,
    YoutubeUploadFailType_TooSmall
}
YoutubeUploadFailType;


#define ESSLocalizedString(key, comment) NSLocalizedStringFromTableInBundle((key),nil,[NSBundle bundleForClass:[self class]],(comment))

@protocol VEIpadShareYoutubeDelegate <NSObject>

@optional
- (void)youtubeNetworkIsCorrect:(BOOL)isCorrect;
- (void)youtubeIsStoreTokenValid:(BOOL)isValid;
- (void)youtubeDidGetCategor:(NSDictionary *)categor;
- (void)youtubeDidAuthorizeIsSuccess:(BOOL)isSuccess withFailType:(YoutubeAuthorizeFailType)type;

- (void)youtubeUploadUpdatedWithUploadedBytes:(long)uploadedBytes ofTotalBytes:(long)totalBytes;
- (void)youtubeUploadIsFinished:(BOOL)isFinish withYouTubeVideoURL:(NSURL *)url withFailType:(YoutubeUploadFailType)type;

@end

@interface VEIpadShareYoutube : NSObject
{
    NSURLConnection             *_uploader;
    NSMutableData               *_receivedData;
    NSString                    *_developerKey;
    
    NSMutableArray              *_observers;
}

//@property(nonatomic, assign) id<VEIpadShareYoutubeDelegate>     delegate;
@property(nonatomic, assign, readonly) BOOL                     isSendAsynReq;

//  按此步骤执行验证

//  初始化
- (id)initYoutubeWithDelegates:(NSMutableArray *)array developerKey:(NSString *)key;

//  从开始检查网络开始
- (void)go:(BOOL)isAsyn;

//  检查网络, 回调或者直接返回BOOL
- (void)checkYoutubeInternet;

//  检查token，如果token验证通过，进入登陆状态，否则需要登陆。如果合法，则不再回调youtubeAuthenticateSuccess，回调youtubeIsStoreTokenValid，如果为NO，客户端应该调出登陆界面
- (void)checkYoutubeIsStoreTokenValid;

//  获得视频的类型，是否登陆成功才能够获取？
- (void)getYoutubeCategoriesDictionary;

//  通过用户名，密码来登陆
- (void)authorizeYoutubeWithUsername:(NSString *)username password:(NSString *)password;

- (void)uploadYoutubeVideoAtURL:(NSURL *)url
                      withTitle:(NSString *)title
                    description:(NSString *)description
                    makePrivate:(BOOL)makePrivate
                       keywords:(NSString *)keywords
                       category:(NSString *)category;

//  取消上传
- (void)cancelYoutubeUploader;

@end
