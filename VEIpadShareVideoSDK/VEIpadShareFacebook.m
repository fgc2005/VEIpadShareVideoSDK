//
//  VEIpadShareFacebook.m
//  VE
//
//  Created by chao on 13-10-9.
//  Copyright (c) 2013年 Sikai. All rights reserved.
//

#import "VEIpadShareFacebook.h"

#define NSLog_INFO(xx, ...) NSLog(xx, ##__VA_ARGS__)
#define NSLog_DEBUG(xx, ...) NSLog(@"%@ %s %d: " xx, [[NSString stringWithUTF8String:__FILE__] lastPathComponent], __func__, __LINE__, ##__VA_ARGS__)

@implementation VEIpadShareFacebook

#define     KEY_TOKEN_FACEBOOK                          @"token_facebook"
#define     TOKEN_FACEBOOK                              [[NSUserDefaults standardUserDefaults] objectForKey:KEY_TOKEN_FACEBOOK]

#define     KEY_LOGIN_DATE_FOR_EXPIRATION_FACEBOOK      @"LoginDateForExpiration"
#define     LOGIN_DATE_FOR_EXPIRATION_FACEBOOK          [[NSUserDefaults standardUserDefaults] objectForKey:KEY_LOGIN_DATE_FOR_EXPIRATION_FACEBOOK]

- (void)dealloc
{
    _observers = nil;
    
    [_receivedData release];
    _receivedData = nil;
    
    [_uploader cancel];
    [_uploader release];
    _uploader = nil;
    
    [super dealloc];
}

- (id)initFacebookWithDelegates:(NSMutableArray *)array appID:(NSString *)appID appSecret:(NSString *)appSecret
{
    self = [super init];
    
    if (self)
    {
        _observers = array;

        self.appID = appID;
        _appSecret = appSecret;
        
        NSString *uploadTempFilename = [NSTemporaryDirectory() stringByAppendingPathComponent:@"essfacebookTempVideoUpload"];
        [[NSFileManager defaultManager] removeItemAtPath:uploadTempFilename error:nil];
    }
    
    return self;
}

- (void)performProtocolSelector:(SEL)aSelector
{
    for (id<VEIpadShareFacebookDelegate> _observer in _observers)
    {
        [_observer facebookIsStoreTokenValid:YES];
    }
}

#pragma mark - progress

- (void)go:(BOOL)isAsyn
{
    _isSendAsynReq = isAsyn;
    [self checkFacebookInternet];
}

- (void)checkFacebookInternet;
{
    //    isSyn = YES;
    
 	NSURL *testURL = [NSURL URLWithString:@"https://graph.facebook.com/1553396397"];
    NSURLRequest *request = [NSURLRequest requestWithURL:testURL
                                             cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
                                         timeoutInterval:5.0f];
    
    void(^handleCheckFacebookInternetResponse)() = ^(NSData *inputData, NSError *inputError) {
        
        if (nil == inputData || nil != inputError)
        {
            for (id<VEIpadShareFacebookDelegate> observer in _observers)
            {
                if (observer && [observer respondsToSelector:@selector(facebookNetworkIsCorrect:)])
                {
                    [observer facebookNetworkIsCorrect:NO];
                }
            }
        }
        else
        {
            for (id<VEIpadShareFacebookDelegate> observer in _observers)
            {
                if (observer && [observer respondsToSelector:@selector(facebookNetworkIsCorrect:)])
                {
                    [observer facebookNetworkIsCorrect:YES];
                }
            }
        }
    };
    
    if (!_isSendAsynReq)
    {
        NSError *err = nil;
        NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:&err];
        handleCheckFacebookInternetResponse(data, err);
    }
	else
    {
        [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
            
            handleCheckFacebookInternetResponse(data, connectionError);
        }];
    }
}

- (void)checkFacebookIsStoreTokenValid
{
    if (nil != TOKEN_FACEBOOK)
    {
        NSURL *nameURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://graph.facebook.com/me?access_token=%@", TOKEN_FACEBOOK]];
        NSURLRequest *request = [NSURLRequest requestWithURL:nameURL cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:5.0f];
        
        void(^handleCheckFacebookIsStoreTokenValidResponse)() = ^(NSData *inputData, NSError *inputError) {
            
            BOOL isValid = YES;
            
            if (nil != inputData)
            {
                NSString *retStr = [[NSString alloc]initWithData:inputData encoding:NSUTF8StringEncoding];
                NSRange nameRange = [retStr rangeOfString:@"\"error\":"];
                [retStr release];
                
                if (nameRange.location != NSNotFound)
                {
                    [[NSUserDefaults standardUserDefaults] removeObjectForKey:KEY_TOKEN_FACEBOOK];
                    [[NSUserDefaults standardUserDefaults] removeObjectForKey:KEY_LOGIN_DATE_FOR_EXPIRATION_FACEBOOK];
                    
                    isValid = NO;
                }
            }

            for (id<VEIpadShareFacebookDelegate> observer in _observers)
            {
                if (observer && [observer respondsToSelector:@selector(facebookIsStoreTokenValid:)])
                {
                    [observer facebookIsStoreTokenValid:isValid];
                }
            }
        };
        
        if (!_isSendAsynReq)
        {
            NSData *retData = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
            handleCheckFacebookIsStoreTokenValidResponse(retData, nil);
        }
        else
        {
            [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                
                handleCheckFacebookIsStoreTokenValidResponse(data, nil);
            }];
        }
        
        return;
    }

    for (id<VEIpadShareFacebookDelegate> observer in _observers)
    {
        if (observer && [observer respondsToSelector:@selector(facebookIsStoreTokenValid:)])
        {
            [observer facebookIsStoreTokenValid:NO];
        }
    }
}

- (void)facebookLogin:(NSString *)token expirationDate:(NSDate *)expDate
{
    NSString *loginToken = token;
    
	//retrieve name for current user
	NSURL *nameURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://graph.facebook.com/me?access_token=%@", token]];
    NSURLRequest *request = [NSURLRequest requestWithURL:nameURL cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:5.0];
    
    void(^handleFacebookLoginResponse)() = ^(NSData *inputData, NSError *inputError) {
        
        [loginToken retain];
        
        NSString *name = nil;
        
        if (nil != inputData)
        {
            NSString *retStr = [[NSString alloc]initWithData:inputData encoding:NSUTF8StringEncoding];
            
            NSRange nameRange = [retStr rangeOfString:@"\"name\":\""];
            
            if (nameRange.location == NSNotFound)
            {
                nameRange = [retStr rangeOfString:@"\"name\": \""];
            }
			
            if (nameRange.location != NSNotFound)
            {
                name = [retStr substringFromIndex:nameRange.location+nameRange.length];
                name = [name substringToIndex:[name rangeOfString:@"\""].location];
            }
            
            [retStr release];
        }
        
        [token release];
        
        if (name)
        {
            NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
            [userDefaults setObject:token forKey:KEY_TOKEN_FACEBOOK];
            [userDefaults setObject:expDate forKey:KEY_LOGIN_DATE_FOR_EXPIRATION_FACEBOOK];
            [userDefaults synchronize];

            for (id<VEIpadShareFacebookDelegate> observer in _observers)
            {
                if (observer && [observer respondsToSelector:@selector(facebookAuthenticateIsSuccess:withFailType:)])
                {
                    [observer facebookAuthenticateIsSuccess:YES withFailType:FacebookAuthenticateFailType_NoFail];
                }
            }
            
            return;
        }

        for (id<VEIpadShareFacebookDelegate> observer in _observers)
        {
            if (observer && [observer respondsToSelector:@selector(facebookAuthenticateIsSuccess:withFailType:)])
            {
                [observer facebookAuthenticateIsSuccess:NO withFailType:FacebookAuthenticateFailType_TokenLoginFail];
            }
        }
    };
    
    if (!_isSendAsynReq)
    {
        NSData *retData = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
        handleFacebookLoginResponse(retData, nil);
    }
    else
    {
        [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
            
            handleFacebookLoginResponse(data, nil);
        }];
    }
}

- (void)uploadFacebookVideoAtURL:(NSURL *)videoURL
                           title:(NSString *)title
                     description:(NSString *)description
                       isPrivate:(BOOL)isPrivate
{
    if (nil == videoURL)
    {
        for (id<VEIpadShareFacebookDelegate> observer in _observers)
        {
            if (observer && [observer respondsToSelector:@selector(facebookUploadFinish:returnURL:returnMessage: message:)])
            {
                [observer facebookUploadFinish:NO returnURL:nil returnMessage:FacebookUploadFailType_UrlNull message:@"facebook upload video url nil."];
            }
        }
        
        return;
    }
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:[videoURL path]])
    {
        for (id<VEIpadShareFacebookDelegate> observer in _observers)
        {
            if (observer && [observer respondsToSelector:@selector(facebookUploadFinish:returnURL:returnMessage:message:)])
            {
                [observer facebookUploadFinish:NO returnURL:nil returnMessage:FacebookUploadFailType_FileNotFound message:@"facebook upload video file not exit."];
            }
        }
        
        return;
    }
    
    if (nil != _uploader)
    {
        for (id<VEIpadShareFacebookDelegate> observer in _observers)
        {
            if (observer && [observer respondsToSelector:@selector(facebookUploadFinish:returnURL:returnMessage:message:)])
            {
                [observer facebookUploadFinish:NO returnURL:nil returnMessage:FacebookUploadFailType_Uploading message:@"upload fail"];
            }
        }
        
        return;
    }
    
    if (0 == [[title stringByReplacingOccurrencesOfString:@" " withString:@""]length])
    {
        for (id<VEIpadShareFacebookDelegate> observer in _observers)
        {
            if (observer && [observer respondsToSelector:@selector(facebookUploadFinish:returnURL:returnMessage:message:)])
            {
                [observer facebookUploadFinish:NO returnURL:nil returnMessage:FacebookUploadFailType_TitleNull message:@"facebook upload title nil ."];
            }
        }
        
        return;
    }
    
    if (0 == [[description stringByReplacingOccurrencesOfString:@" " withString:@""]length])
    {
        for (id<VEIpadShareFacebookDelegate> observer in _observers)
        {
            if (observer && [observer respondsToSelector:@selector(facebookUploadFinish:returnURL:returnMessage:message:)])
            {
                [observer facebookUploadFinish:NO returnURL:nil returnMessage:FacebookUploadFailType_DescriptionNull message:@"facebook upload description nil."];
            }
        }
        
        return;
    }
    
	NSString *urlEscTitle = (NSString *)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (CFStringRef)title, NULL, NULL, kCFStringEncodingUTF8);
	NSString *urlEscDesc = (NSString *)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (CFStringRef)description, NULL, NULL, kCFStringEncodingUTF8);
	NSString *baseString = [NSString stringWithFormat:@"https://graph-video.facebook.com/me/videos?title=%@&description=%@&access_token=%@",urlEscTitle,urlEscDesc, TOKEN_FACEBOOK];
	[urlEscTitle release];
	[urlEscDesc release];
	if (isPrivate)
		baseString = [baseString stringByAppendingString:@"&privacy=%7B%22value%22%3A%22SELF%22%7D"];
	NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:baseString] cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:5.0f];
	[req setHTTPMethod:@"POST"];
	
	//first, re-write the data of videoURL combined with the MIME-stuff to disk again
	NSString *beginString = @"--3i2ndDfv2rTHiSisAbouNdArYfORhtTPEefj3q2f\r\nContent-Disposition: form-data; name=\"video\"; filename=\"filename.mov\"\r\nContent-Type: multipart/form-data\r\n\r\n";
	NSString *uploadTempFilename = [NSTemporaryDirectory() stringByAppendingPathComponent:@"essfacebookTempVideoUpload"];
	[[NSFileManager defaultManager] removeItemAtPath:uploadTempFilename error:nil];
	
	NSOutputStream *oStr = [NSOutputStream outputStreamToFileAtPath:uploadTempFilename append:NO];
	[oStr open];
	const char *UTF8String;
	size_t writeLength;
	UTF8String = [beginString UTF8String];
	writeLength = strlen(UTF8String);
	size_t __unused actualWrittenLength;
	actualWrittenLength = [oStr write:(uint8_t *)UTF8String maxLength:writeLength];
    
	if (actualWrittenLength != writeLength)
    {
        for (id<VEIpadShareFacebookDelegate> observer in _observers)
        {
            if (observer && [observer respondsToSelector:@selector(facebookUploadFinish:returnURL:returnMessage:message:)])
            {
                [observer facebookUploadFinish:NO returnURL:nil returnMessage:FacebookUploadFailType_DescriptionNull message:@"facebook upload fail"];
            }
        }
        
        return;
    }
	
	const size_t bufferSize = 65536;
	size_t readSize = 0;
	uint8_t *buffer = (uint8_t *)calloc(1, bufferSize);
	NSInputStream *iStr = [NSInputStream inputStreamWithURL:videoURL];
	[iStr open];
    
	while ([iStr hasBytesAvailable])
	{
		if (!(readSize = [iStr read:buffer maxLength:bufferSize]))
			break;
		
		size_t __unused actualWrittenLength;
		actualWrittenLength = [oStr write:buffer maxLength:readSize];
        
		if (actualWrittenLength != readSize)
        {
            for (id<VEIpadShareFacebookDelegate> observer in _observers)
            {
                if (observer && [observer respondsToSelector:@selector(facebookUploadFinish:returnURL:returnMessage:message:)])
                {
                    [observer facebookUploadFinish:NO returnURL:nil returnMessage:FacebookUploadFailType_ErrorReading message:@"facebook upload fail"];
                }
            }
            
            [iStr close];
            free(buffer);
            buffer = NULL;
            
            return;
        }
	}
	[iStr close];
	free(buffer);
    buffer = NULL;
	
	NSString *endString = @"\r\n--3i2ndDfv2rTHiSisAbouNdArYfORhtTPEefj3q2f\r\n";
	UTF8String = [endString UTF8String];
	writeLength = strlen(UTF8String);
	actualWrittenLength = [oStr write:(uint8_t *)UTF8String maxLength:writeLength];
    
	if (actualWrittenLength != writeLength)
    {
        for (id<VEIpadShareFacebookDelegate> observer in _observers)
        {
            if (observer && [observer respondsToSelector:@selector(facebookUploadFinish:returnURL:returnMessage: message:)])
            {
                [observer facebookUploadFinish:NO returnURL:nil returnMessage:FacebookUploadFailType_ErrorWriting message:@"facebook upload fail"];
            }
        }
        
        return;
    }
	[oStr close];
	
	unsigned long long fileSize = -1;
	fileSize = [[[NSFileManager defaultManager] attributesOfItemAtPath:uploadTempFilename error:nil] fileSize];
	[req setValue:@"multipart/form-data; boundary=3i2ndDfv2rTHiSisAbouNdArYfORhtTPEefj3q2f" forHTTPHeaderField:@"Content-Type"];
	[req setValue:[NSString stringWithFormat:@"%llu",fileSize] forHTTPHeaderField:@"Content-Length"];
	
	//second, upload it
	NSInputStream *inStr = [NSInputStream inputStreamWithFileAtPath:uploadTempFilename];
	[req setHTTPBodyStream:inStr];
	
	_uploader = [[NSURLConnection alloc] initWithRequest:req delegate:self];
	[_uploader start];
}

- (void)cancelFacebookUploader
{
    [_uploader cancel];
    [_uploader release];
    _uploader = nil;
}

#pragma mark - NSURLConnectionDataDelegate

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	if (nil == _receivedData)
    {
        _receivedData = [[NSMutableData alloc]init];
    }
    
	[_receivedData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	NSString *retStr = [[NSString alloc]initWithData:_receivedData encoding:NSUTF8StringEncoding];
    
    [_receivedData release];
	_receivedData = nil;
    
	NSRange idRange = [retStr rangeOfString:@"{\"id\":\""];
    
	if (idRange.location == NSNotFound)
    {
        idRange = [retStr rangeOfString:@"{\"id\": \""];
    }
    
	if (idRange.location == NSNotFound)
    {
        _uploadedObjectID = nil;
    }
	else
	{
		_uploadedObjectID = [retStr substringFromIndex:idRange.location+idRange.length];
		_uploadedObjectID = [_uploadedObjectID substringToIndex:[_uploadedObjectID rangeOfString:@"\""].location];
	}
	[retStr release];
	
    [_uploader cancel];
    [_uploader release];
	_uploader = nil;
    
	NSString *uploadTempFilename = [NSTemporaryDirectory() stringByAppendingPathComponent:@"essfacebookTempVideoUpload"];
	[[NSFileManager defaultManager] removeItemAtPath:uploadTempFilename error:nil];
	
	if (nil == _uploadedObjectID)
	{
        for (id<VEIpadShareFacebookDelegate> observer in _observers)
        {
            if (observer && [observer respondsToSelector:@selector(facebookUploadFinish:returnURL:returnMessage:message:)])
            {
                [observer facebookUploadFinish:NO returnURL:nil returnMessage:FacebookUploadFailType_ErrorWriting message:@"facebook upload object id nil."];
            }
        }
        
        return;
	}
    else
	{
		NSString *urlStr = [NSString stringWithFormat:@"https://www.facebook.com/video/video.php?v=%@", _uploadedObjectID];
		NSURL *url = [NSURL URLWithString:urlStr];

        for (id<VEIpadShareFacebookDelegate> observer in _observers)
        {
            if (observer && [observer respondsToSelector:@selector(facebookUploadFinish:returnURL:returnMessage:message:)])
            {
                [observer facebookUploadFinish:YES returnURL:url returnMessage:FacebookUploadFailType_NoFail message:@"facebook upload fail"];
            }
        }
	}
	
    _uploadedObjectID = nil;
}

- (void)connection:(NSURLConnection *)connection didSendBodyData:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite
{
    for (id<VEIpadShareFacebookDelegate> observer in _observers)
    {
        if (observer && [observer respondsToSelector:@selector(facebookUploadUpdatedWithBytes:ofTotalBytes:)])
        {
            [observer facebookUploadUpdatedWithBytes:totalBytesWritten ofTotalBytes:totalBytesExpectedToWrite];
        }
    }
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    for (id<VEIpadShareFacebookDelegate> observer in _observers)
    {
        if (observer && [observer respondsToSelector:@selector(facebookUploadFinish:returnURL:returnMessage: message:)])
        {
            [observer facebookUploadFinish:NO returnURL:nil returnMessage:FacebookUploadFailType_NetworkError message:error.localizedDescription];
        }
    }
    NSLog(@"facebook upload error: %@",error.localizedDescription);
}

@end
