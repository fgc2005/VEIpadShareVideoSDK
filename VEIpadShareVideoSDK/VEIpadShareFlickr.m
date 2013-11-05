//
//  VEIpadShareFlickr.m
//  VE
//
//  Created by chao on 13-10-11.
//  Copyright (c) 2013年 Sikai. All rights reserved.
//

#import "VEIpadShareFlickr.h"
#import "OAuthConsumer.h"

#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>

//#define     KEY_OATOKEN_FLICKR          @"oatoken_flickr"
//#define     OATOKEN_FLICKR                  [[NSUserDefaults standardUserDefaults] objectForKey:KEY_OATOKEN_FLICKR]

//#define     KEY_OATOKEN_SECRET_FLICKR          @"oatoken_secret_flickr"
//#define     OATOKEN_SECRET_FLICKR              [[NSUserDefaults standardUserDefaults] objectForKey:KEY_OATOKEN_SECRET_FLICKR]

#pragma mark - addition

#ifdef DEBUG

#define NSLog_INFO(xx, ...) NSLog(xx, ##__VA_ARGS__)
#define NSLog_DEBUG(xx, ...) NSLog(@"%@ %s %d: " xx, [[NSString stringWithUTF8String:__FILE__] lastPathComponent], __func__, __LINE__, ##__VA_ARGS__)

#else

#define NSLog_INFO(xx, ...)
#define NSLog_DEBUG(xx, ...)

#endif

@interface VEIpadShareFlickr()
{
    OAConsumer                              *_oaconsumer;
    OAPlaintextSignatureProvider            *_sigProv;
    OAToken                                 *_authToken;
    OAToken                                 *_requestToken;
    
    NSString                                *_oauth_verifier;
}

@end

@implementation VEIpadShareFlickr

/*
 the following two functions are taken directly from http://opensource.apple.com/source/CF/CF-635/CFXMLParser.c since it's not available on iOS for a reason unknown to me
 */

#pragma mark - char dell

CFStringRef CFXMLCreateStringByUnescapingEntitiesFlickr(CFAllocatorRef allocator, CFStringRef string, CFDictionaryRef entitiesDictionary) {
	CFStringInlineBuffer inlineBuf;
	CFStringRef sub;
	CFIndex lastChunkStart, length = CFStringGetLength(string);
	CFIndex i, entityStart;
	UniChar uc;
	UInt32 entity;
	int base;
	CFMutableDictionaryRef fullReplDict = entitiesDictionary ? CFDictionaryCreateMutableCopy(allocator, 0, entitiesDictionary) : CFDictionaryCreateMutable(allocator, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
	
	CFDictionaryAddValue(fullReplDict, (const void *)CFSTR("amp"), (const void *)CFSTR("&"));
	CFDictionaryAddValue(fullReplDict, (const void *)CFSTR("quot"), (const void *)CFSTR("\""));
	CFDictionaryAddValue(fullReplDict, (const void *)CFSTR("lt"), (const void *)CFSTR("<"));
	CFDictionaryAddValue(fullReplDict, (const void *)CFSTR("gt"), (const void *)CFSTR(">"));
	CFDictionaryAddValue(fullReplDict, (const void *)CFSTR("apos"), (const void *)CFSTR("'"));
	
	CFStringInitInlineBuffer(string, &inlineBuf, CFRangeMake(0, length - 1));
	CFMutableStringRef newString = CFStringCreateMutable(allocator, 0);
	
	lastChunkStart = 0;
	// Scan through the string in its entirety
	for(i = 0; i < length; ) {
		uc = CFStringGetCharacterFromInlineBuffer(&inlineBuf, i); i++;	// grab the next character and move i.
		
		if(uc == '&') {
			entityStart = i - 1;
			entity = 0xFFFF;	// set this to a not-Unicode character as sentinel
			// we've hit the beginning of an entity. Copy everything from lastChunkStart to this point.
			if(lastChunkStart < i - 1) {
				sub = CFStringCreateWithSubstring(allocator, string, CFRangeMake(lastChunkStart, (i - 1) - lastChunkStart));
				CFStringAppend(newString, sub);
				CFRelease(sub);
			}
			
			uc = CFStringGetCharacterFromInlineBuffer(&inlineBuf, i); i++;	// grab the next character and move i.
			// Now we can process the entity reference itself
			if(uc == '#') {	// this is a numeric entity.
				base = 10;
				entity = 0;
				uc = CFStringGetCharacterFromInlineBuffer(&inlineBuf, i); i++;
				
				if(uc == 'x') {	// only lowercase x allowed. Translating numeric entity as hexadecimal.
					base = 16;
					uc = CFStringGetCharacterFromInlineBuffer(&inlineBuf, i); i++;
				}
				
				// process the provided digits 'til we're finished
				while(true) {
					if (uc >= '0' && uc <= '9')
						entity = entity * base + (uc-'0');
					else if (uc >= 'a' && uc <= 'f' && base == 16)
						entity = entity * base + (uc-'a'+10);
					else if (uc >= 'A' && uc <= 'F' && base == 16)
						entity = entity * base + (uc-'A'+10);
					else break;
					
					if (i < length) {
						uc = CFStringGetCharacterFromInlineBuffer(&inlineBuf, i); i++;
					}
					else
						break;
				}
			}
			
			// Scan to the end of the entity
			while(uc != ';' && i < length) {
				uc = CFStringGetCharacterFromInlineBuffer(&inlineBuf, i); i++;
			}
			
			if(0xFFFF != entity) { // it was numeric, and translated.
				// Now, output the result fo the entity
				if(entity >= 0x10000) {
					UniChar characters[2] = { ((entity - 0x10000) >> 10) + 0xD800, ((entity - 0x10000) & 0x3ff) + 0xDC00 };
					CFStringAppendCharacters(newString, characters, 2);
				} else {
					UniChar character = entity;
					CFStringAppendCharacters(newString, &character, 1);
				}
			} else {	// it wasn't numeric.
				sub = CFStringCreateWithSubstring(allocator, string, CFRangeMake(entityStart + 1, (i - entityStart - 2))); // This trims off the & and ; from the string, so we can use it against the dictionary itself.
				CFStringRef replacementString = (CFStringRef)CFDictionaryGetValue(fullReplDict, sub);
				if(replacementString) {
					CFStringAppend(newString, replacementString);
				} else {
					CFRelease(sub); // let the old substring go, since we didn't find it in the dictionary
					sub =  CFStringCreateWithSubstring(allocator, string, CFRangeMake(entityStart, (i - entityStart))); // create a new one, including the & and ;
					CFStringAppend(newString, sub); // ...and append that.
				}
				CFRelease(sub); // in either case, release the most-recent "sub"
			}
			
			// move the lastChunkStart to the beginning of the next chunk.
			lastChunkStart = i;
		}
	}
    
	if(lastChunkStart < length) { // we've come out of the loop, let's get the rest of the string and tack it on.
		sub = CFStringCreateWithSubstring(allocator, string, CFRangeMake(lastChunkStart, i - lastChunkStart));
		CFStringAppend(newString, sub);
		CFRelease(sub);
	}
	
	CFRelease(fullReplDict);
	
	return newString;
}

- (NSString *)_unescapedString:(NSString *)aString
{
	[aString retain];
	if (aString == nil || aString.length == 0)
	{
		[aString release];
		return nil;
	}
	
	NSString *bString = [aString stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	
	if (bString != nil)
	{
		[aString release];
		aString = [bString retain];
	}
    
#if (!TARGET_OS_IPHONE && !TARGET_OS_EMBEDDED && !TARGET_IPHONE_SIMULATOR)
	NSString *returnString = (NSString *)[(NSString *)CFXMLCreateStringByUnescapingEntities(kCFAllocatorDefault, (CFStringRef)[aString autorelease], NULL) autorelease];
#else
	NSString *returnString = (NSString *)[(NSString *)CFXMLCreateStringByUnescapingEntitiesFlickr(kCFAllocatorDefault, (CFStringRef)[aString autorelease], NULL) autorelease];
#endif
	
	if (returnString == nil)
		returnString = aString;
	else
	{
		aString = [returnString retain];
		
#if (!TARGET_OS_IPHONE && !TARGET_OS_EMBEDDED && !TARGET_IPHONE_SIMULATOR)
		returnString = (NSString *)[(NSString *)CFXMLCreateStringByUnescapingEntities(kCFAllocatorDefault, (CFStringRef)[aString autorelease], NULL) autorelease];
#else
		returnString = (NSString *)[(NSString *)CFXMLCreateStringByUnescapingEntitiesFlickr(kCFAllocatorDefault, (CFStringRef)[aString autorelease], NULL) autorelease];
#endif
		if (returnString == nil)
			returnString = aString;
	}
	
	return returnString;
}

#pragma mark - init

- (void)dealloc
{
    [_requestToken release];
    _requestToken = nil;
    
    [_oaconsumer release];
    _oaconsumer = nil;
    
    [_authToken release];
    _authToken = nil;
    
    [_sigProv release];
    _sigProv = nil;
    
    [_uploader cancel];
    [_uploader release];
    _uploader = nil;
    
    [_resultData release];
    _resultData = nil;
    
    _observers = nil;
    
    [super dealloc];
}

- (id)initWithDelegates:(NSMutableArray *)array
         applicationKey:(NSString *)key
      applicationSecret:(NSString *)secret;
{
    self = [super init];
    
    if (self)
    {
//        self.delegate = delegate;
        
        _observers = array;
        
        _oaconsumer = [[OAConsumer alloc]initWithKey:key secret:secret];
		_sigProv = [[OAPlaintextSignatureProvider alloc]init];
    }
    
    return self;
}

#pragma mark Private

#pragma mark - progress

- (void)go:(BOOL)isAsyn
{
    _isSendAsynReq = isAsyn;
    [self checkFlickrInternet];
}

- (void)checkFlickrInternet
{
    NSURL *testURL = [NSURL URLWithString:@"http://www.flickr.com/services/oauth/request_token"];
    NSURLRequest * request = [NSURLRequest requestWithURL:testURL
                                              cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
                                          timeoutInterval:5.0f];
    
    void (^handlerCheckFlickrInternetResponse)() = ^(NSData *inputData, NSError *inputError) {
    
        if (!inputData|| inputError)
        {
//            [_flickrDelegate flickrShowMessage:[@"flickr:" stringByAppendingString: err.localizedDescription ]];
            
//            if (self.delegate && [self.delegate respondsToSelector:@selector(flickrNetworkIsCorrect:)])
//            {
//                [self.delegate flickrNetworkIsCorrect:NO];
//            }
            
            for (id<VEIpadShareFlickrDelegate> observer in _observers)
            {
                if (observer && [observer respondsToSelector:@selector(flickrNetworkIsCorrect:)])
                {
                    [observer flickrNetworkIsCorrect:NO];
                }
            }
            
            return;
        }
        
//        if (self.delegate && [self.delegate respondsToSelector:@selector(flickrNetworkIsCorrect:)])
//        {
//            [self.delegate flickrNetworkIsCorrect:YES];
//        }
        
        for (id<VEIpadShareFlickrDelegate> observer in _observers)
        {
            if (observer && [observer respondsToSelector:@selector(flickrNetworkIsCorrect:)])
            {
                [observer flickrNetworkIsCorrect:YES];
            }
        }
        
        return;
    };
    
    if (!_isSendAsynReq)
    {
        NSError *err = nil;
        NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:&err];
        handlerCheckFlickrInternetResponse(data, err);
    }
    else
    {
        [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
           
            handlerCheckFlickrInternetResponse(data, connectionError);
        }];
    }
}

- (void)checkFlickrIsStoreTokenValid
{
    [self _canUploadVideosKeyInvalidCheck:nil withUsername:nil];
}

- (void)_canUploadVideosKeyInvalidCheck:(OAToken *)forCheckToken withUsername:(NSString *)username // :(BOOL *)keyInvalid errorConnecting:(BOOL *)errorConnecting
{
    OAToken *authToken = nil;
    
    if (nil == forCheckToken)
    {
        authToken = [[[OAToken alloc]initWithUserDefaultsUsingServiceProviderName:@"essflickr" prefix:@"essflickrvideoupload"]autorelease];
    }
    else
    {
        authToken = [[forCheckToken retain]autorelease];
    }

	if (nil == authToken)
    {
        for (id<VEIpadShareFlickrDelegate> observer in _observers)
        {
            if (observer && [observer respondsToSelector:@selector(flickrIsStoreTokenValid:)])
            {
                [observer flickrIsStoreTokenValid:NO];
            }
        }
        
        return;
    }

	OAMutableURLRequest *req = [[[OAMutableURLRequest alloc]initWithURL:[NSURL URLWithString:@"http://api.flickr.com/services/rest"]
															   consumer:_oaconsumer
																  token:authToken
																  realm:nil
													  signatureProvider:_sigProv]autorelease];
	[req setTimeoutInterval:5.0f];
	[req setHTTPMethod:@"GET"];
	
	NSMutableArray *oaparams = [NSMutableArray array];
	OARequestParameter *mPar = [[OARequestParameter alloc] initWithName:@"method" value:@"flickr.people.getUploadStatus"];
	[oaparams addObject:mPar];
	[mPar release];
	OARequestParameter *fPar = [[OARequestParameter alloc] initWithName:@"format" value:@"rest"];
	[oaparams addObject:fPar];
	[fPar release];
	
	[req setParameters:oaparams];
	[req prepare];
    
    void(^handleCheckFlickrIsStoreTokenValidResponse)() = ^(NSData *inputData, NSError *inputError) {

        if (nil == inputData || nil != inputError)
        {
            if (nil == forCheckToken)
            {
                for (id<VEIpadShareFlickrDelegate> observer in _observers)
                {
                    if (observer && [observer respondsToSelector:@selector(flickrIsStoreTokenValid:)])
                    {
                        [observer flickrIsStoreTokenValid:NO];
                    }
                }
            }

            return;
        }
        
        NSString *str = [[[NSString alloc] initWithData:inputData encoding:NSUTF8StringEncoding]autorelease];
        NSRange videosRange = [str rangeOfString:@"<videos "];
        
        BOOL checkIsTokenValid = YES;
        
        if (videosRange.location == NSNotFound)
        {
            checkIsTokenValid = NO;

        }
        
        str = [str substringFromIndex:videosRange.location+videosRange.length];
        NSRange remainingRange = [str rangeOfString:@" remaining=\""];
        
        if (remainingRange.location == NSNotFound)
        {
            checkIsTokenValid = NO;
        }

        str = [str substringFromIndex:remainingRange.location+remainingRange.length];
        str = [str substringToIndex:[str rangeOfString:@"\""].location];
        
        if ([str rangeOfString:@"lots" options:NSCaseInsensitiveSearch].location == NSNotFound)
        {
            NSUInteger amount = [str integerValue];
            
            BOOL isValid = (amount > 0);
            
            checkIsTokenValid = isValid;
        }
        
        if (nil == forCheckToken)
        {
            for (id<VEIpadShareFlickrDelegate> observer in _observers)
            {
                if (observer && [observer respondsToSelector:@selector(flickrIsStoreTokenValid:)])
                {
                    [observer flickrIsStoreTokenValid:checkIsTokenValid];
                }
            }
        }
        else
        {
            for (id<VEIpadShareFlickrDelegate> observer in _observers)
            {
                if (observer && [observer respondsToSelector:@selector(flickrIsAccessTokenSuccess:withUsername:withFailType:)])
                {
                    if (checkIsTokenValid)
                    {
                        [_authToken release];
                        _authToken = nil;
                        _authToken = [authToken retain];
                        [observer flickrIsAccessTokenSuccess:YES withUsername:username withFailType:FlickrAccessTokenFailType_NoFail];
                    }
                    else
                    {
                        [observer flickrIsAccessTokenSuccess:NO withUsername:nil withFailType:FlickrAccessTokenFailType_NullToken];
                    }
                }
            }
        }

        return;
    };
	
    if (!_isSendAsynReq)
    {
        NSURLResponse *resp = nil;
        NSError *err = nil;
        NSData *retData = [NSURLConnection sendSynchronousRequest:req returningResponse:&resp error:&err];
        handleCheckFlickrIsStoreTokenValidResponse(retData, err);
    }
    else
    {
        [NSURLConnection sendAsynchronousRequest:req queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
            
            handleCheckFlickrIsStoreTokenValidResponse(data, connectionError);
        }];
    }
}

//
/**
 取得要求記錄,
 
返回
 oauth_callback_confirmed=true
 &oauth_token=72157626737672178-022bbd2f4c2f3432
 &oauth_token_secret=fccb68c4e6103197
 
 并且输出含有 http://www.flickr.com/services/oauth/authorize?%@&perms=write 请求的 request
 
*/

- (void)flickrRequestLoginPageToken
{
    NSURL *url = [NSURL URLWithString:@"http://www.flickr.com/services/oauth/request_token"];
    OAMutableURLRequest *req = [[[OAMutableURLRequest alloc]initWithURL:url consumer:_oaconsumer token:nil realm:nil signatureProvider:_sigProv]autorelease];
    [req setCachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData];
    [req setHTTPMethod:@"GET"];
    [req setOAuthParameterName:@"oauth_callback" withValue:@"essflickrvideoupload:"];
    [req prepare];
    
    void(^handleFlickrLoginResponse)() = ^(NSData *inputData, NSURLResponse *response, NSError *inputError) {
    
        if (nil == inputData || nil != inputError)
        {
            for (id<VEIpadShareFlickrDelegate> observer in _observers)
            {
                if (observer && [observer respondsToSelector:@selector(flickrDidGetLoginTokenIsSuccess:withRequest:withFailType:)])
                {
                    [observer flickrDidGetLoginTokenIsSuccess:NO withRequest:nil withFailType:DidGetLoginTokenFailType_NoResponse];
                }
            }
            
            return;
        }
        else
        {
            if ([(NSHTTPURLResponse *)response statusCode] < 400)
            {
                NSString *result = [[[NSString alloc]initWithData:inputData encoding:NSUTF8StringEncoding]autorelease];
                
                if (nil == result)
                {
                    for (id<VEIpadShareFlickrDelegate> observer in _observers)
                    {
                        if (observer && [observer respondsToSelector:@selector(flickrDidGetLoginTokenIsSuccess:withRequest:withFailType:)])
                        {
                            [observer flickrDidGetLoginTokenIsSuccess:NO withRequest:nil withFailType:DidGetLoginTokenFailType_ResponseDataError];
                        }
                    }
                    
                    return;
                }
                else
                {
                    [_requestToken release];
                    _requestToken = nil;
                    _requestToken = [[OAToken alloc]initWithHTTPResponseBody:result];

                    NSString *urlStr = [NSString stringWithFormat:@"http://www.flickr.com/services/oauth/authorize?%@&perms=write", result];
                    NSURL *url = [NSURL URLWithString:urlStr];
                    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:5.0f];

                    for (id<VEIpadShareFlickrDelegate> observer in _observers)
                    {
                        if (observer && [observer respondsToSelector:@selector(flickrDidGetLoginTokenIsSuccess:withRequest:withFailType:)])
                        {
                            [observer flickrDidGetLoginTokenIsSuccess:YES withRequest:req withFailType:DidGetLoginTokenFailType_NoFail];
                        }
                    }
                    
                    return;
                }
            }
        }
    };
    
    if (!_isSendAsynReq)
    {
        NSError *err = nil;
        NSURLResponse *resp = nil;
        NSData *data = [NSURLConnection sendSynchronousRequest:req returningResponse:&resp error:&err];
        handleFlickrLoginResponse(data, resp, err);
    }
    else
    {
        [NSURLConnection sendAsynchronousRequest:req queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
            
            handleFlickrLoginResponse(data, response, connectionError);
        }];
    }
}

/**
 取得使用者授權
 
 返回 http://www.example.com/
 ?oauth_token=72157626737672178-022bbd2f4c2f3432
 &oauth_verifier=5d1b96a26b494074
 */
- (void)flickrHandleOpenURL:(NSURL *)url
{
    NSString *retStr = url.absoluteString;
    
    NSRange oauthTokenRange = [retStr rangeOfString:@"oauth_token="];
    NSRange verifierRange = [retStr rangeOfString:@"oauth_verifier="];
    
    if (oauthTokenRange.location == NSNotFound)
    {
        for (id<VEIpadShareFlickrDelegate> observer in _observers)
        {
            if (observer && [observer respondsToSelector:@selector(flickrAuthenticateIsSuccess:withFailType:)])
            {
                [observer flickrAuthenticateIsSuccess:NO withFailType:FlickrAuthenticateFailType_NoOauthTokenReturn];
            }
        }
        
        return;
    }
    else if (verifierRange.location == NSNotFound)
    {
        for (id<VEIpadShareFlickrDelegate> observer in _observers)
        {
            if (observer && [observer respondsToSelector:@selector(flickrAuthenticateIsSuccess:withFailType:)])
            {
                [observer flickrAuthenticateIsSuccess:NO withFailType:FlickrAuthenticateFailType_NoVerifierReturn];
            }
        }
    }
    else
    {
        NSString *oauth_token = [retStr substringFromIndex:oauthTokenRange.location + oauthTokenRange.length];
        
        NSLog_DEBUG(@"oauth_token = %@", oauth_token);
        
        oauth_token = [oauth_token substringToIndex:[oauth_token rangeOfString:@"&"].location];
        
        NSLog_DEBUG(@"oauth_token = %@", oauth_token);
        
        NSString *oauth_verifier = [retStr substringFromIndex:verifierRange.location + verifierRange.length];
        
        [_oauth_verifier release];
        _oauth_verifier = nil;
        _oauth_verifier = [oauth_verifier retain];;

        for (id<VEIpadShareFlickrDelegate> observer in _observers)
        {
            if (observer && [observer respondsToSelector:@selector(flickrAuthenticateIsSuccess:withFailType:)])
            {
                [observer flickrAuthenticateIsSuccess:YES withFailType:FlickrAuthenticateFailType_NoFail];
            }
        }
        
        return;
    }
}

- (void)flickrAccessToken
{
    if (!_oaconsumer || !_requestToken)
    {
        for (id<VEIpadShareFlickrDelegate> observer in _observers)
        {
            if (observer && [observer respondsToSelector:@selector(flickrIsAccessTokenSuccess:withUsername:withFailType:)])
            {
                [observer flickrIsAccessTokenSuccess:NO withUsername:nil withFailType:FlickrAccessTokenFailType_NullInputToken];
            }
        }
        
        return;
    }
    
    NSURL *authorizeURL = [NSURL URLWithString:@"http://www.flickr.com/services/oauth/access_token"];
    OAMutableURLRequest *req = [[[OAMutableURLRequest alloc]initWithURL:authorizeURL
                                                              consumer:_oaconsumer
                                                                 token:_requestToken
                                                                 realm:nil
                                                     signatureProvider:_sigProv]autorelease];
    [req setHTTPMethod:@"GET"];
    [req setOAuthParameterName:@"oauth_verifier" withValue:_oauth_verifier];
    [req prepare];

    void(^handleFlickrLoginResponse)() = ^(NSData *inputData, NSURLResponse *response, NSError *inputError) {
        
        [_requestToken release];
        _requestToken = nil;
        
        if (nil == inputData || nil == response || nil != inputError)
        {
            for (id<VEIpadShareFlickrDelegate> observer in _observers)
            {
                if (observer && [observer respondsToSelector:@selector(flickrIsAccessTokenSuccess:withUsername:withFailType:)])
                {
                    [observer flickrIsAccessTokenSuccess:NO withUsername:nil withFailType:FlickrAccessTokenFailType_NoResponse];
                }
            }
            
            return;
        }
        else
        {
            if ([(NSHTTPURLResponse *)response statusCode] < 400)
            {
                NSString *authTokenStr = [[[NSString alloc]initWithData:inputData encoding:NSUTF8StringEncoding]autorelease];
                
                if (!authTokenStr)
                {
                    for (id<VEIpadShareFlickrDelegate> observer in _observers)
                    {
                        if (observer && [observer respondsToSelector:@selector(flickrIsAccessTokenSuccess:withUsername:withFailType:)])
                        {
                            [observer flickrIsAccessTokenSuccess:NO withUsername:nil withFailType:FlickrAccessTokenFailType_ResponseDataError];
                        }
                    }
                    
                    return;
                }
                else
                {
                    [_authToken release];
                    _authToken = nil;
                    _authToken = [[OAToken alloc]initWithHTTPResponseBody:authTokenStr];
                    [_authToken storeInUserDefaultsWithServiceProviderName:@"essflickr" prefix:@"essflickrvideoupload"];
                    
                    NSString *name = nil;
                    NSRange fullnameRange = [authTokenStr rangeOfString:@"fullname="];
                    NSRange usernameRange = [authTokenStr rangeOfString:@"username="];
                    
                    if (fullnameRange.location != NSNotFound)
                    {
                        name = [authTokenStr substringFromIndex:fullnameRange.location + fullnameRange.length];
                        name = [name substringToIndex:[name rangeOfString:@"&"].location];
                        name = [self _unescapedString:name];
                    }
                    else if (usernameRange.location != NSNotFound)
                    {
                        name = [authTokenStr substringFromIndex:usernameRange.location + usernameRange.length];
                    }

                    if (name)
                    {
                        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
                        [userDefaults setObject:name forKey:@"essflickrvideouploadUsername"];
                        [userDefaults synchronize];
                        
                    }
                    else
                    {
                        name = NSLocalizedString(@"ESSFlickrUnknownUsername", @"");
                    }

                    if (nil == _authToken)
                    {
                        for (id<VEIpadShareFlickrDelegate> observer in _observers)
                        {
                            if (observer && [observer respondsToSelector:@selector(flickrIsAccessTokenSuccess:withUsername:withFailType:)])
                            {
                                [observer flickrIsAccessTokenSuccess:NO withUsername:nil withFailType:FlickrAccessTokenFailType_NullToken];
                            }
                        }
                        
                        return;
                    }
                    else
                    {
                        [self _canUploadVideosKeyInvalidCheck:_authToken withUsername:name];
                    }
                }
            }
            else
            {
                for (id<VEIpadShareFlickrDelegate> observer in _observers)
                {
                    if (observer && [observer respondsToSelector:@selector(flickrIsAccessTokenSuccess:withUsername:withFailType:)])
                    {
                        [observer flickrIsAccessTokenSuccess:NO withUsername:nil withFailType:FlickrAccessTokenFailType_ResponseCodeError];
                    }
                }
                
                return;
            }
        }
    };
    
    if (!_isSendAsynReq)
    {
        NSError *err = nil;
        NSURLResponse *resp = nil;
        NSData *data = [NSURLConnection sendSynchronousRequest:req returningResponse:&resp error:&err];
        handleFlickrLoginResponse(data, resp, err);
    }
    else
    {
        [NSURLConnection sendAsynchronousRequest:req queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
            
            handleFlickrLoginResponse(data, response, connectionError);
        }];
    }
}

- (void)uploadVideoAtURL:(NSURL *)url
                   title:(NSString *)title
             description:(NSString *)description
                    tags:(NSString *)tags
             makePrivate:(BOOL)makePrivate
{
	if (nil == url)
    {
//        [self.flickrDelegate flickrUploadFinishedWithFlickrVideoURL:NO returnURL:nil returnMessage:@"url is nil"];
        
        for (id<VEIpadShareFlickrDelegate> observer in _observers)
        {
            if (observer && [observer respondsToSelector:@selector(flickrUploadIsFinished:withReturnURL:withFailType:)])
            {
                [observer flickrUploadIsFinished:NO withReturnURL:nil withFailType:FlickrUploadFailType_NullInputURL];
            }
        }
        
        NSLog_DEBUG(@"url = %@", url);
        
        return;
    }

    if (nil == _authToken)
    {
        for (id<VEIpadShareFlickrDelegate> observer in _observers)
        {
            if (observer && [observer respondsToSelector:@selector(flickrUploadIsFinished:withReturnURL:withFailType:)])
            {
                [observer flickrUploadIsFinished:NO withReturnURL:nil withFailType:FlickrUploadFailType_NullInputAuthToken];
            }
        }
        
        return;
    }
    
    if (nil == _oaconsumer)
    {
        for (id<VEIpadShareFlickrDelegate> observer in _observers)
        {
            if (observer && [observer respondsToSelector:@selector(flickrUploadIsFinished:withReturnURL:withFailType:)])
            {
                [observer flickrUploadIsFinished:NO withReturnURL:nil withFailType:FlickrUploadFailType_NullInputOaconsumer];
            }
        }
        
        return;
    }
    
    if (nil != _uploader)
    {
        for (id<VEIpadShareFlickrDelegate> observer in _observers)
        {
            if (observer && [observer respondsToSelector:@selector(flickrUploadIsFinished:withReturnURL:withFailType:)])
            {
                [observer flickrUploadIsFinished:NO withReturnURL:nil withFailType:FlickrUploadFailType_NullInputUploader];
            }
        }
        
        return;
    }
    
    AVURLAsset *vid = [[[AVURLAsset alloc] initWithURL:url options:nil] autorelease];
	CGFloat duration = vid.duration.value/vid.duration.timescale;
    
    if(duration > 90 )
    {
//        [self.flickrDelegate flickrUploadFinishedWithFlickrVideoURL:NO returnURL:nil returnMessage:@" uploaded video at 90 minutes "];
        
        for (id<VEIpadShareFlickrDelegate> observer in _observers)
        {
            if (observer && [observer respondsToSelector:@selector(flickrUploadIsFinished:withReturnURL:withFailType:)])
            {
                [observer flickrUploadIsFinished:NO withReturnURL:nil withFailType:FlickrUploadFailType_LongTime];
            }
        }
        
        return;
    }
	
	NSURL *reqURL = [NSURL URLWithString:@"http://api.flickr.com/services/upload/"];
	OAMutableURLRequest *signatureReq = [[[OAMutableURLRequest alloc] initWithURL:reqURL
																		 consumer:_oaconsumer
																			token:_authToken
																			realm:nil
																signatureProvider:_sigProv]autorelease];
	[signatureReq setHTTPMethod:@"POST"];
	[signatureReq setTimeoutInterval:5.0f];
	NSMutableArray *params = [NSMutableArray array];
	OARequestParameter *par = [[OARequestParameter alloc]initWithName:@"title" value:title];
	[params addObject:par];
	[par release];
	par = [[OARequestParameter alloc] initWithName:@"description" value:description];
	[params addObject:par];
	[par release];
	par = [[OARequestParameter alloc] initWithName:@"is_public" value:(makePrivate ? @"0":@"1")];
	[params addObject:par];
	[par release];
	par = [[OARequestParameter alloc] initWithName:@"hidden" value:(makePrivate ? @"2":@"1")];
	[params addObject:par];
	[par release];
	par = [[OARequestParameter alloc] initWithName:@"async" value:@"0"];
	[params addObject:par];
	[par release];
	
	NSArray *tagsArr = [tags componentsSeparatedByString:@","];
	NSString *tagsString = @"";
	for (NSString *tag in tagsArr)
	{
		tagsString = [tagsString stringByAppendingFormat:@"\"%@\" ",tag];
	}
	
	par = [[OARequestParameter alloc] initWithName:@"tags" value:tagsString];
	[params addObject:par];
	[par release];
	
	[signatureReq setParameters:params];
	[signatureReq prepare];
    
	//NSString *sig = [signatureReq signature];
	[signatureReq setValue:@"multipart/form-data; boundary=\"3i2ndDfv2rTHiSisAbouNdArYfORhtTPEefj3q2f\"" forHTTPHeaderField:@"Content-Type"];
	
	NSString *beginString = [NSString stringWithFormat:@"--3i2ndDfv2rTHiSisAbouNdArYfORhtTPEefj3q2f\r\nContent-Disposition: form-data; name=\"title\"\r\n\r\n%@\r\n",title];
	beginString = [beginString stringByAppendingFormat:@"--3i2ndDfv2rTHiSisAbouNdArYfORhtTPEefj3q2f\r\nContent-Disposition: form-data; name=\"description\"\r\n\r\n%@\r\n",description];
	beginString = [beginString stringByAppendingFormat:@"--3i2ndDfv2rTHiSisAbouNdArYfORhtTPEefj3q2f\r\nContent-Disposition: form-data; name=\"tags\"\r\n\r\n%@\r\n",tagsString];
	beginString = [beginString stringByAppendingFormat:@"--3i2ndDfv2rTHiSisAbouNdArYfORhtTPEefj3q2f\r\nContent-Disposition: form-data; name=\"is_public\"\r\n\r\n%i\r\n",(!makePrivate)];
	beginString = [beginString stringByAppendingFormat:@"--3i2ndDfv2rTHiSisAbouNdArYfORhtTPEefj3q2f\r\nContent-Disposition: form-data; name=\"hidden\"\r\n\r\n%@\r\n",(makePrivate ? @"2":@"1")];
	beginString = [beginString stringByAppendingString:@"--3i2ndDfv2rTHiSisAbouNdArYfORhtTPEefj3q2f\r\nContent-Disposition: form-data; name=\"async\"\r\n\r\n0\r\n"];
	
	//beginString = [beginString stringByAppendingString:@"--3i2ndDfv2rTHiSisAbouNdArYfORhtTPEefj3q2f\r\nContent-Disposition: form-data; name=\"photo\"; filename=\"speedSlideshow\"\r\nContent-Type: video/quicktime\r\n\r\n"];
	beginString = [beginString stringByAppendingString:@"--3i2ndDfv2rTHiSisAbouNdArYfORhtTPEefj3q2f\r\nContent-Disposition: form-data; name=\"photo\"; filename=\"movie\"\r\n\r\n"];
	NSString *uploadTempFilename = [NSTemporaryDirectory() stringByAppendingPathComponent:@"essflickrTempVideoUpload"];
	
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
        NSLog(@"error writing beginning");
    }
		
	
	const size_t bufferSize = 65536;
	size_t readSize = 0;
	uint8_t *buffer = (uint8_t *)calloc(1, bufferSize);
	NSInputStream *iStr = [NSInputStream inputStreamWithURL:url];
	[iStr open];
    
	while ([iStr hasBytesAvailable])
	{
		if (!(readSize = [iStr read:buffer maxLength:bufferSize]))
        {
            break;
        }

		size_t __unused actualWrittenLength;
		actualWrittenLength = [oStr write:buffer maxLength:readSize];
        
		if (actualWrittenLength != readSize)
        {
            NSLog(@"error reading the file data and writing it to new one");
        }
			
	}
	[iStr close];
	free(buffer);
	
	NSString *endString = @"\r\n--3i2ndDfv2rTHiSisAbouNdArYfORhtTPEefj3q2f--\r\n";
	UTF8String = [endString UTF8String];
	writeLength = strlen(UTF8String);
	actualWrittenLength = [oStr write:(uint8_t *)UTF8String maxLength:writeLength];
    
	if (actualWrittenLength != writeLength)
    {
        NSLog_DEBUG(@"error writing ending of file");
    }
		
	[oStr close];
	
	unsigned long long fileSize = -1;
	fileSize = [[[NSFileManager defaultManager] attributesOfItemAtPath:uploadTempFilename error:nil] fileSize];
	[signatureReq setValue:[NSString stringWithFormat:@"%llu",fileSize] forHTTPHeaderField:@"Content-Length"];
	
	//second, upload it
	NSInputStream *inStr = [NSInputStream inputStreamWithFileAtPath:uploadTempFilename];
	[signatureReq setHTTPBodyStream:inStr];
	
	_uploader = [[NSURLConnection alloc]initWithRequest:signatureReq delegate:self];
    [_uploader start];
}

- (void)_checkPhotoID:(NSString *)photoID
{
	if (photoID == nil)
	{
        for (id<VEIpadShareFlickrDelegate> observer in _observers)
        {
            if (observer && [observer respondsToSelector:@selector(flickrUploadIsFinished:withReturnURL:withFailType:)])
            {
                [observer flickrUploadIsFinished:NO withReturnURL:nil withFailType:FlickrUploadFailType_NoPhotoID];
            }
        }
        
		return;
	}
    
    OAMutableURLRequest *req = [[[OAMutableURLRequest alloc]initWithURL:[NSURL URLWithString:@"http://api.flickr.com/services/rest"]
                                                               consumer:_oaconsumer
                                                                  token:_authToken
                                                                  realm:nil
                                                      signatureProvider:_sigProv]autorelease];
    [req setTimeoutInterval:5.0f];
    [req setHTTPMethod:@"GET"];
    
    NSMutableArray *oaparams = [NSMutableArray array];
    OARequestParameter *mPar = [[OARequestParameter alloc]initWithName:@"method" value:@"flickr.photos.getInfo"];
    [oaparams addObject:mPar];
    [mPar release];
    OARequestParameter *fPar = [[OARequestParameter alloc]initWithName:@"format" value:@"rest"];
    [oaparams addObject:fPar];
    [fPar release];
    fPar = [[OARequestParameter alloc]initWithName:@"photo_id" value:photoID];
    [oaparams addObject:fPar];
    [fPar release];
    
    [req setParameters:oaparams];
    [req prepare];
    
    void(^handleCheckFlickrPhotoIDResponse)() = ^(NSData *inputData, NSError *inputError) {
        
        if (nil == inputData|| nil != inputError)
        {
            for (id<VEIpadShareFlickrDelegate> observer in _observers)
            {
                if (observer && [observer respondsToSelector:@selector(flickrUploadIsFinished:withReturnURL:withFailType:)])
                {
                    [observer flickrUploadIsFinished:NO withReturnURL:nil withFailType:FlickrUploadFailType_ResponseNull];
                }
            }
        }
        
        NSString *retStr = [[[NSString alloc] initWithData:inputData encoding:NSUTF8StringEncoding] autorelease];
        
        if ([retStr rangeOfString:@"<rsp stat=\"fail"].location != NSNotFound ||
            [retStr rangeOfString:@"<err code=\""].location != NSNotFound)
        {
            for (id<VEIpadShareFlickrDelegate> observer in _observers)
            {
                if (observer && [observer respondsToSelector:@selector(flickrUploadIsFinished:withReturnURL:withFailType:)])
                {
                    [observer flickrUploadIsFinished:NO withReturnURL:nil withFailType:FlickrUploadFailType_ResponseHasErrorInfo];
                }
            }
        }
        
        NSRange pendingRange = [retStr rangeOfString:@"pending=\"1"];
        
        if (pendingRange.location != NSNotFound)
        {
            [photoID retain];
            double delayInSeconds = 10.0;
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                [self _checkPhotoID:[photoID autorelease]];
            });
            return;
        }
        
        NSRange failedRange = [retStr rangeOfString:@"failed=\"1"];
        
        if (failedRange.location != NSNotFound)
        {
            for (id<VEIpadShareFlickrDelegate> observer in _observers)
            {
                if (observer && [observer respondsToSelector:@selector(flickrUploadIsFinished:withReturnURL:withFailType:)])
                {
                    [observer flickrUploadIsFinished:NO withReturnURL:nil withFailType:FlickrUploadFailType_FailedIs1Info];
                }
            }
        }
        
        NSRange successRange = [retStr rangeOfString:@"ready=\"1"];
        
        if (successRange.location != NSNotFound)
        {
            NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://www.flickr.com/photos/upload/edit/?ids=%@",photoID]];
            
            for (id<VEIpadShareFlickrDelegate> observer in _observers)
            {
                if (observer && [observer respondsToSelector:@selector(flickrUploadIsFinished:withReturnURL:withFailType:)])
                {
                    [observer flickrUploadIsFinished:YES withReturnURL:url withFailType:FlickrUploadFailType_NoFail];
                }
            }
        }
    };
    
    if (!_isSendAsynReq)
    {
        NSURLResponse *resp = nil;
        NSError *err = nil;
        NSData *retData = [NSURLConnection sendSynchronousRequest:req returningResponse:&resp error:&err];
        handleCheckFlickrPhotoIDResponse(retData, err);
    }
    else
    {
        [NSURLConnection sendAsynchronousRequest:req queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
            handleCheckFlickrPhotoIDResponse(data, connectionError);
        }];
    }
}

- (void)cancelUploader
{
    [_uploader cancel];
    [_uploader release];
    _uploader = nil;
}


#pragma mark - NSURLConnectionDelegate

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    [_uploader cancel];
    [_uploader release];
	_uploader = nil;
    
    for (id<VEIpadShareFlickrDelegate> observer in _observers)
    {
        if (observer && [observer respondsToSelector:@selector(flickrUploadIsFinished:withReturnURL:withFailType:)])
        {
            [observer flickrUploadIsFinished:NO withReturnURL:nil withFailType:FlickrUploadFailType_NetwordFail];
        }
    }
    
//#if (!TARGET_OS_IPHONE && !TARGET_OS_EMBEDDED && !TARGET_IPHONE_SIMULATOR)
//	[self._flWinCtr uploadFinishedWithFlickrURL:nil success:NO];
//#else
//    //	[self._viewCtr uploadFinishedWithURL:nil];
//    [self.flickrDelegate flickrUploadFinishedWithFlickrVideoURL:NO returnURL:nil returnMessage:error.localizedDescription ];
//#endif
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	if (nil == _resultData)
    {
        _resultData = [[NSMutableData data]retain];
    }
	
	[_resultData appendData:data];
}

- (void)connection:(NSURLConnection *)connection didSendBodyData:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite
{
    for (id<VEIpadShareFlickrDelegate> observer in _observers)
    {
        if (observer && [observer respondsToSelector:@selector(flickrUploadUpdatedWithBytes:ofTotalBytes:)])
        {
            [observer flickrUploadUpdatedWithBytes:totalBytesWritten ofTotalBytes:totalBytesExpectedToWrite];
        }
    }
    
//#if (!TARGET_OS_IPHONE && !TARGET_OS_EMBEDDED && !TARGET_IPHONE_SIMULATOR)
//	[self._flWinCtr uploadUpdatedWithBytes:totalBytesWritten ofTotal:totalBytesExpectedToWrite];
//#else
//    //	[self._viewCtr uploadUpdatedWithUploadedBytes:totalBytesWritten ofTotalBytes:totalBytesExpectedToWrite];
//    [self.flickrDelegate flickrUploadUpdatedWithBytes:totalBytesWritten ofTotalBytes:totalBytesExpectedToWrite];
//#endif
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    if (nil == _resultData)
    {
        return;
    }
    
	NSString *result = [[[NSString alloc]initWithData:_resultData encoding:NSUTF8StringEncoding]autorelease];
	
    [_resultData release];
    _resultData = nil;
	
	if ([result rangeOfString:@"<rsp stat=\"fail"].location != NSNotFound
        || [result rangeOfString:@"<err code=\""].location != NSNotFound)
	{
        for (id<VEIpadShareFlickrDelegate> observer in _observers)
        {
            if (observer && [observer respondsToSelector:@selector(flickrUploadIsFinished:withReturnURL:withFailType:)])
            {
                [observer flickrUploadIsFinished:NO withReturnURL:nil withFailType:FlickrUploadFailType_ResponseHasErrorInfoInCheckIsfinish];
            }
        }
	}
    else
	{
		NSRange photoIDRange = [result rangeOfString:@"<photoid>"];
        
		if (photoIDRange.location == NSNotFound)
		{
            for (id<VEIpadShareFlickrDelegate> observer in _observers)
            {
                if (observer && [observer respondsToSelector:@selector(flickrUploadIsFinished:withReturnURL:withFailType:)])
                {
                    [observer flickrUploadIsFinished:NO withReturnURL:nil withFailType:FlickrUploadFailType_NOFoundPhotoIDInCheckIsfinish];
                }
            }

			return;
		}
		
		NSString *photoID = [result substringFromIndex:photoIDRange.location+photoIDRange.length];
		photoID = [photoID substringToIndex:[photoID rangeOfString:@"</photo"].location];
		
		[self _checkPhotoID:photoID];
	}

    [_uploader cancel];
    _uploader = nil;
	_uploader = nil;
}


@end


