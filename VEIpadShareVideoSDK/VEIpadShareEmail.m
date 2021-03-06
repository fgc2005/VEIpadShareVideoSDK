//
//  VEIpadShareEmail.m
//  VEIpadShareVideoSDK
//
//  Created by chao on 13-10-16.
//  Copyright (c) 2013年 Sachsen. All rights reserved.
//

#import "VEIpadShareEmail.h"
#import "SKPSMTPMessage.h"
#import "EmailUtil.h"

@interface VEIpadShareEmail()
<
SKPSMTPMessageDelegate
>
{
    SKPSMTPMessage                  *_smtpMessage;
    NSMutableArray                  *_parts_to_send;
    NSURL                           *_sendVideoURL;
}

@end

@implementation VEIpadShareEmail

#define NSLog_INFO(xx, ...) NSLog(xx, ##__VA_ARGS__)
#define NSLog_DEBUG(xx, ...) NSLog(@"%@ %s %d: " xx, [[NSString stringWithUTF8String:__FILE__] lastPathComponent], __func__, __LINE__, ##__VA_ARGS__)

- (void)dealloc
{
    _smtpMessage.delegate = nil;
    [_smtpMessage release];
    _smtpMessage = nil;
    
    [_parts_to_send removeAllObjects];
    [_parts_to_send release];
    _parts_to_send = nil;
    
    [_sendVideoURL release];
    _sendVideoURL = nil;
    
    _observers = nil;
    
    [super dealloc];
}

- (id)initWithDelegates:(NSMutableArray *)array     
{
    self = [super init];
    
    if (self)
    {
        _observers = array;
    }
    
    return self;
}

- (void)sendEmailWithFromEmail:(NSString *)theFromEmail
             fromEmailPassword:(NSString *)theFromEmailPassword
                     relayHost:(NSString *)theRelayHost
                       toEmail:(NSString *)theToEmail
                       subject:(NSString *)theSubject
                   messageBody:(NSString *)theMessageBody
                toEmailAddress:(NSMutableArray *)theToEmailAddress
                ccEmailAddress:(NSMutableArray *)theCCEmailAddress
                  sendVideoURL:(NSURL *)theSendVideoURL
{
    [_sendVideoURL release];
    _sendVideoURL = nil;
    _sendVideoURL = [theSendVideoURL retain];
    
    _smtpMessage.delegate = nil;
    [_smtpMessage release];
    _smtpMessage = nil;
    _smtpMessage = [[SKPSMTPMessage alloc]init];
    _smtpMessage.delegate = self;
    
    _smtpMessage.fromEmail = theFromEmail;
    _smtpMessage.pass = theFromEmailPassword;
    _smtpMessage.login = theFromEmail;
    _smtpMessage.relayHost = theRelayHost;
    _smtpMessage.wantsSecure = YES;
    _smtpMessage.requiresAuth = YES;
    _smtpMessage.toEmail = theToEmail;
    _smtpMessage.subject = theSubject;
    _smtpMessage.toEmailAddress = theToEmailAddress;
    _smtpMessage.ccEmailAddress = theCCEmailAddress;
    
    [_parts_to_send removeAllObjects];
    [_parts_to_send release];
    _parts_to_send = nil;
    _parts_to_send = [[NSMutableArray array]retain];
    
    NSData *image_data = [NSData dataWithContentsOfURL:_sendVideoURL];
    
    NSDictionary *resource = [NSDictionary dictionaryWithObjectsAndKeys:
                              @"inline;\r\n\tfilename=\"uploadFile\"",kSKPSMTPPartContentDispositionKey,
                              @"base64",kSKPSMTPPartContentTransferEncodingKey,
                              @"video;\r\n\tname=uploadFile;\r\n\tx-unix-mode=0666",kSKPSMTPPartContentTypeKey,
                              [EmailUtil encodeWrappedBase64ForData:image_data],kSKPSMTPPartMessageKey,
                              nil];
    [_parts_to_send addObject:resource];
    
    NSDictionary *plain_text_part = [NSDictionary dictionaryWithObjectsAndKeys:
                                     @"text/plain\r\n\tcharset=UTF-8;\r\n\tformat=flowed", kSKPSMTPPartContentTypeKey,
                                     [@"\n" stringByAppendingString:theMessageBody], kSKPSMTPPartMessageKey,
                                     @"quoted-printable", kSKPSMTPPartContentTransferEncodingKey,
                                     nil];
    [_parts_to_send addObject:plain_text_part];
    
    _smtpMessage.parts = _parts_to_send;
 
    if ([self checkData])
    {
       
        for (id<VEIpadShareEmailDelegate> observer in _observers)
        {
            if (observer && [observer respondsToSelector:@selector(sendEmailStart)])
            {
                [observer sendEmailStart];
            }
        }
        
        [_smtpMessage send];
    }
    else
    {
        
    }
}

- (BOOL)checkData
{
    if (0 == [_smtpMessage.toEmail length])
    {
//        [_emailDelegate emailPromptMessage:@"to email nil"];
        
        for (id<VEIpadShareEmailDelegate> observer in _observers)
        {
            if (observer && [observer respondsToSelector:@selector(sendEmailIsSuccess:withFailType:errorMeessage:)])
            {
                [observer sendEmailIsSuccess:NO withFailType:SendEmailFailType_ToEmailNull errorMeessage:@"email send  to email address null"];
            }
        }
        
        return NO;
    }
    else if (0 == [_smtpMessage.fromEmail length])
    {
//        [_emailDelegate emailPromptMessage:@"from email nil"];
        
        for (id<VEIpadShareEmailDelegate> observer in _observers)
        {
            if (observer && [observer respondsToSelector:@selector(sendEmailIsSuccess:withFailType:errorMeessage:)])
            {
                [observer sendEmailIsSuccess:NO withFailType:SendEmailFailType_FromEmailNull errorMeessage:@"email send email null"];
            }
        }
        
        return NO;
    }
    else if (0 == [_smtpMessage.pass length])
    {
//        [_emailDelegate emailPromptMessage:@"from email password nil"];
        
        for (id<VEIpadShareEmailDelegate> observer in _observers)
        {
            if (observer && [observer respondsToSelector:@selector(sendEmailIsSuccess:withFailType:errorMeessage:)])
            {
                [observer sendEmailIsSuccess:NO withFailType:SendEmailFailType_FromPasswrodNull errorMeessage:@"email send email password null"];
            }
        }
        
        return NO;
    }
    else if (0 == [_smtpMessage.relayHost length])
    {
//        [_emailDelegate emailPromptMessage:@"relay host  nil"];
        
        for (id<VEIpadShareEmailDelegate> observer in _observers)
        {
            if (observer && [observer respondsToSelector:@selector(sendEmailIsSuccess:withFailType:errorMeessage:)])
            {
                [observer sendEmailIsSuccess:NO withFailType:SendEmailFailType_RelayHostNull errorMeessage:@"email send relay host null"];
            }
        }
        
        return NO;
    }
    else if (0 == [_smtpMessage.subject length])
    {
//        [_emailDelegate emailPromptMessage:@"email subject nil"];
        
        for (id<VEIpadShareEmailDelegate> observer in _observers)
        {
            if (observer && [observer respondsToSelector:@selector(sendEmailIsSuccess:withFailType:errorMeessage:)])
            {
                [observer sendEmailIsSuccess:NO withFailType:SendEmailFailType_EmailSubjectNull errorMeessage:@"email send subject null "];
            }
        }
        
        return NO;
    }
    else if (0 == [_sendVideoURL.relativePath length])
    {
//        [_emailDelegate emailPromptMessage:@"emial video nil"];
        
        for (id<VEIpadShareEmailDelegate> observer in _observers)
        {
            if (observer && [observer respondsToSelector:@selector(sendEmailIsSuccess:withFailType:errorMeessage:)])
            {
                [observer sendEmailIsSuccess:NO withFailType:SendEmailFailType_EmialVideoNull errorMeessage:@"email send video url nil"];
            }
        }
        
        return NO;
    }

    return YES;
}

#pragma mark - SKPSMTPMessageDelegate

- (void)messageSent:(SKPSMTPMessage *)message
{
    for (id<VEIpadShareEmailDelegate> observer in _observers)
    {
        if (observer && [observer respondsToSelector:@selector(sendEmailIsSuccess:withFailType:errorMeessage:)])
        {
            [observer sendEmailIsSuccess:YES withFailType:SendEmailFailType_NoFail errorMeessage:nil];
        }
    }
}

- (void)messageFailed:(SKPSMTPMessage *)message error:(NSError *)error
{
    for (id<VEIpadShareEmailDelegate> observer in _observers)
    {
        if (observer && [observer respondsToSelector:@selector(sendEmailIsSuccess:withFailType:errorMeessage:)])
        {
            [observer sendEmailIsSuccess:NO withFailType:SendEmailFailType_Fail errorMeessage:error.localizedDescription];
        }
    }
}

- (void)messageState:(SKPSMTPState)messageState
{
    float p = (float)messageState/(float)kSKPSMTPWaitingSendSuccess;
    
    for (id<VEIpadShareEmailDelegate> observer in _observers)
    {
        if (observer && [observer respondsToSelector:@selector(sendEmailProgress:)])
        {
            [observer sendEmailProgress:p];
        }
    }
}

@end
