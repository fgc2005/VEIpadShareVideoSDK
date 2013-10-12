//
//  VEIpadShareFacebook.h
//  VE
//
//  Created by chao on 13-10-9.
//  Copyright (c) 2013年 Sikai. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum
{
    FacebookAuthenticateFailType_NoFail,
    FacebookAuthenticateFailType_TokenInvali,
    FacebookAuthenticateFailType_NoToken,
    FacebookAuthenticateFailType_TokenLoginFail,
}
FacebookAuthenticateFailType;

typedef enum
{
    FacebookUploadFailType_NoFail,
    FacebookUploadFailType_UrlNull,
    FacebookUploadFailType_FileNotFound,
    FacebookUploadFailType_Uploading,
    FacebookUploadFailType_TitleNull,
    FacebookUploadFailType_DescriptionNull,
    FacebookUploadFailType_ErrorWritingBeginning,
    FacebookUploadFailType_ErrorReading,
    FacebookUploadFailType_ErrorWriting,
    FacebookUploadFailType_NoVideoURLOnTheServer,
    FacebookUploadFailType_NetworkError,
}
FacebookUploadFailType;

@protocol VEIpadShareFacebookDelegate <NSObject>

@optional
- (void)facebookNetworkIsCorrect:(BOOL)isCorrect;
- (void)facebookIsStoreTokenValid:(BOOL)isValid;
- (void)facebookAuthenticateIsSuccess:(BOOL)isSuccess withFailType:(FacebookAuthenticateFailType)type;

- (void)facebookUploadFinish:(BOOL)isFinish returnURL:(NSURL *)returnURL returnMessage:(FacebookUploadFailType)type;
- (void)facebookUploadUpdatedWithBytes:(long)totalBytesWritten ofTotalBytes:(long)totalBytesExpectedToWrite;

@end

@interface VEIpadShareFacebook : NSObject
{
    //    NSString            *_appID;
    NSString            *_appSecret;
    
    NSString            *_uploadedObjectID;
    
    NSURLConnection     *_uploader;
    NSMutableData       *_receivedData;
    
    NSMutableArray      *_observers;
}

//@property(nonatomic, assign) id<VEIpadShareFacebookDelegate>    delegate;
@property(nonatomic, retain) NSString                           *appID;

@property(nonatomic, assign, readonly) BOOL                     isSendAsynReq;

//  可以按此步骤执行验证

//  初始化
//- (id)initFacebookWithDelegate:(id)delegate appID:(NSString *)appID appSecret:(NSString *)appSecret;
- (id)initFacebookWithDelegates:(NSMutableArray *)array appID:(NSString *)appID appSecret:(NSString *)appSecret;

//  从头开始流程，从验证网络开始
- (void)go:(BOOL)isAsyn;

//  检查网络, 回调或者直接返回  BOOL
- (void)checkFacebookInternet;

//  检查token，如果token验证通过，进入登陆状态，否则需要登陆。如果合法，则不再回调facebookAuthenticateSuccess
- (void)checkFacebookIsStoreTokenValid;

//  登陆，如果token存在且通过验证，可以跳过这一步。在页面验证需要通过此方法登陆.需要从外面传入token
- (void)facebookLogin:(NSString *)token expirationDate:(NSDate *)expDate;

//  开始上传
- (void)uploadFacebookVideoAtURL:(NSURL *)videoURL
                           title:(NSString *)title
                     description:(NSString *)description
                       isPrivate:(BOOL)isPrivate;

//  取消上传
- (void)cancelFacebookUploader;

@end
