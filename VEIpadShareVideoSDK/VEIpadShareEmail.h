//
//  VEIpadShareEmail.h
//  VEIpadShareVideoSDK
//
//  Created by chao on 13-10-16.
//  Copyright (c) 2013年 Sachsen. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum
{
    SendEmailFailType_NoFail,
    SendEmailFailType_ToEmailNull,
    SendEmailFailType_FromEmailNull,
    SendEmailFailType_FromPasswrodNull,
    SendEmailFailType_RelayHostNull,
    SendEmailFailType_EmailSubjectNull,
    SendEmailFailType_EmialVideoNull,
    SendEmailFailType_Fail,
}
SendEmailFailType;

@protocol VEIpadShareEmailDelegate <NSObject>

@optional
- (void)sendEmailStart;
- (void)sendEmailIsSuccess:(BOOL)isSuccess withFailType:(SendEmailFailType)type errorMeessage:(NSString *)message;
- (void)sendEmailProgress:(float)progress;

@end

@interface VEIpadShareEmail : NSObject
{
    NSMutableArray              *_observers;
}

//@property(nonatomic, assign, readonly) BOOL                     isSendAsynReq;

- (id)initWithDelegates:(NSMutableArray *)array;

- (void)sendEmailWithFromEmail:(NSString *)theFromEmail
             fromEmailPassword:(NSString *)theFromEmailPassword
                     relayHost:(NSString *)theRelayHost
                       toEmail:(NSString *)theToEmail
                       subject:(NSString *)theSubject
                   messageBody:(NSString *)theMessageBody
                toEmailAddress:(NSMutableArray *)theToEmailAddress
                ccEmailAddress:(NSMutableArray *)theCCEmailAddress
                  sendVideoURL:(NSURL *)theSendVideoURL;

@end
