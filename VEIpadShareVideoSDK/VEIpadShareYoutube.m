//
//  VEIpadShareYoutube.m
//  VE
//
//  Created by chao on 13-10-9.
//  Copyright (c) 2013年 Sikai. All rights reserved.
//

#import "VEIpadShareYoutube.h"
#import <CoreFoundation/CoreFoundation.h>

@interface VEIpadShareYoutube ()
{
    NSString                        *_forCheckVideoID;
    YoutubeUploadFailType           _uploadFailType;
    NSString                        *_checkMessage;
}

@end

@implementation VEIpadShareYoutube

#define     KEY_TOKEN_YOUTUBE                          @"token_youtube"
#define     TOKEN_YOUTUBE                             [[NSUserDefaults standardUserDefaults] objectForKey:KEY_TOKEN_YOUTUBE]

#define NSLog_INFO(xx, ...) NSLog(xx, ##__VA_ARGS__)
#define NSLog_DEBUG(xx, ...) NSLog(@"%@ %s %d: " xx, [[NSString stringWithUTF8String:__FILE__] lastPathComponent], __func__, __LINE__, ##__VA_ARGS__)

CFStringRef CFXMLCreateStringByEscapingEntities(CFAllocatorRef allocator, CFStringRef string, CFDictionaryRef entitiesDictionary) {
	CFMutableStringRef newString = CFStringCreateMutable(allocator, 0); // unbounded mutable string
	CFMutableCharacterSetRef startChars = CFCharacterSetCreateMutable(allocator);
	
	CFStringInlineBuffer inlineBuf;
	CFIndex idx = 0;
	CFIndex mark = idx;
	CFIndex stringLength = CFStringGetLength(string);
	UniChar uc;
	
	CFCharacterSetAddCharactersInString(startChars, CFSTR("&<>'\""));
	
	CFStringInitInlineBuffer(string, &inlineBuf, CFRangeMake(0, stringLength));
	for(idx = 0; idx < stringLength; idx++) {
		uc = CFStringGetCharacterFromInlineBuffer(&inlineBuf, idx);
		if(CFCharacterSetIsCharacterMember(startChars, uc)) {
			CFStringRef previousSubstring = CFStringCreateWithSubstring(allocator, string, CFRangeMake(mark, idx - mark));
			CFStringAppend(newString, previousSubstring);
			CFRelease(previousSubstring);
			switch(uc) {
				case '&':
					CFStringAppend(newString, CFSTR("&amp;"));
					break;
				case '<':
					CFStringAppend(newString, CFSTR("&lt;"));
					break;
				case '>':
					CFStringAppend(newString, CFSTR("&gt;"));
					break;
				case '\'':
					CFStringAppend(newString, CFSTR("&apos;"));
					break;
				case '"':
					CFStringAppend(newString, CFSTR("&quot;"));
					break;
			}
			mark = idx + 1;
		}
	}
	// Copy the remainder to the output string before returning.
	CFStringRef remainder = CFStringCreateWithSubstring(allocator, string, CFRangeMake(mark, idx - mark));
	if (NULL != remainder) {
		CFStringAppend(newString, remainder);
		CFRelease(remainder);
	}
	
	CFRelease(startChars);
	return newString;
}

CFStringRef CFXMLCreateStringByUnescapingEntities(CFAllocatorRef allocator, CFStringRef string, CFDictionaryRef entitiesDictionary) {
	CFStringInlineBuffer inlineBuf; /* use this for fast traversal of the string in question */
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
    
	if(lastChunkStart < length)
    { // we've come out of the loop, let's get the rest of the string and tack it on.
		sub = CFStringCreateWithSubstring(allocator, string, CFRangeMake(lastChunkStart, i - lastChunkStart));
		CFStringAppend(newString, sub);
		CFRelease(sub);
	}
	
	CFRelease(fullReplDict);
	
	return newString;
}

- (NSString *)messageDetailWithState:(NSString *)state
{
    NSString *output = @"";
    
    if ([state rangeOfString:@"requesterRegion" options:NSCaseInsensitiveSearch].location != NSNotFound)
    {
        output = @"The video is not available in the user's region.";
        _uploadFailType = YoutubeUploadFailType_RequesterRegion;
    }
    else if ([state rangeOfString:@"limitedSyndication" options:NSCaseInsensitiveSearch].location != NSNotFound)
    {
        output = @"The video is not and, based on the content owner's current preferences, will not be available to play in non-browser devices, such as mobile phones.";
        _uploadFailType = YoutubeUploadFailType_LimitedSyndication;
    }
    else if ([state rangeOfString:@"private" options:NSCaseInsensitiveSearch].location != NSNotFound)
    {
        output = @"The video owner has restricted access to the video. This reasonCode signals that a video in a feed, such as a playlist or favorite videos feed, has been made a private video by the video's owner and is therefore unavailable.";
        _uploadFailType = YoutubeUploadFailType_Private;
    }
    else if ([state rangeOfString:@"copyright" options:NSCaseInsensitiveSearch].location != NSNotFound)
    {
        output = @"The video commits a copyright infringement.";
        _uploadFailType = YoutubeUploadFailType_Copyright;
    }
    else if ([state rangeOfString:@"inappropriate" options:NSCaseInsensitiveSearch].location != NSNotFound)
    {
        output = @"The video contains inappropriate content.";
        _uploadFailType = YoutubeUploadFailType_Inappropriate;
    }
    else if ([state rangeOfString:@"duplicate" options:NSCaseInsensitiveSearch].location != NSNotFound)
    {
        output = @"The video is a duplicate of another uploaded video.";
        _uploadFailType = YoutubeUploadFailType_Duplicate;
    }
    else if ([state rangeOfString:@"termsOfUse" options:NSCaseInsensitiveSearch].location != NSNotFound)
    {
        output = @"The video commits a terms of use violate.";
        _uploadFailType = YoutubeUploadFailType_TermsOfUse;
    }
    else if ([state rangeOfString:@"suspended" options:NSCaseInsensitiveSearch].location != NSNotFound)
    {
        output = @"The account associated with the video has been suspended.";
        _uploadFailType = YoutubeUploadFailType_Suspended;
    }
    else if ([state rangeOfString:@"tooLong" options:NSCaseInsensitiveSearch].location != NSNotFound)
    {
        output = @"The video exceeds the maximum duration of 10 minutes.";
        _uploadFailType = YoutubeUploadFailType_TooLong;
    }
    else if ([state rangeOfString:@"blocked" options:NSCaseInsensitiveSearch].location != NSNotFound)
    {
        output = @"The video has been blocked by the content owner.";
        _uploadFailType = YoutubeUploadFailType_Blocked;
    }
    else if ([state rangeOfString:@"cantProcess" options:NSCaseInsensitiveSearch].location != NSNotFound)
    {
        output = @"YouTube is unable to convert the video file.";
        _uploadFailType = YoutubeUploadFailType_CantProcess;
    }
    else if ([state rangeOfString:@"invalidFormat" options:NSCaseInsensitiveSearch].location != NSNotFound)
    {
        output = @"The uploaded video is in an invalid file format.";
        _uploadFailType = YoutubeUploadFailType_InvalidFormat;
    }
    else if ([state rangeOfString:@"unsupportedCodec" options:NSCaseInsensitiveSearch].location != NSNotFound)
    {
        output = @"The video uses an unsupported codec.";
        _uploadFailType = YoutubeUploadFailType_UnsupportedCodec;
    }
    else if ([state rangeOfString:@"empty" options:NSCaseInsensitiveSearch].location != NSNotFound)
    {
        output = @"The uploaded file is empty.";
        _uploadFailType = YoutubeUploadFailType_Empty;
    }
    else if ([state rangeOfString:@"tooSmall" options:NSCaseInsensitiveSearch].location != NSNotFound)
    {
        output = @"The uploaded file is too small.";
        _uploadFailType = YoutubeUploadFailType_TooSmall;
    }
    
    return output;
}

- (void)dealloc
{
    _observers = nil;
    [super dealloc];
}

- (id)initYoutubeWithDelegates:(NSMutableArray *)array developerKey:(NSString *)key
{
    self = [super init];
    
    if (self)
    {
        _observers = array;
//        self.delegate = delegate;
        _developerKey = key;
    }
    
    return self;
}

#pragma mark - progress

- (void)go:(BOOL)isAsyn
{
    _isSendAsynReq = isAsyn;
    [self checkYoutubeInternet];
}

- (void)checkYoutubeInternet
{
    __block BOOL isCorrect = YES;
    
    NSURL *testURL = [NSURL URLWithString:@"http://gdata.youtube.com/feeds/api/users/oddysseey"];
    NSURLRequest *request = [NSURLRequest requestWithURL:testURL cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:5.0f];
    
    void (^handlerCheckYoutubeInternetResponse)() = ^(NSData *inputData, NSError *inputError) {
 
        if (nil == inputData || nil != inputError)
        {
            isCorrect = NO;
        }
        
//        if (self.delegate && [self.delegate respondsToSelector:@selector(youtubeNetworkIsCorrect:)])
//        {
//            [self.delegate youtubeNetworkIsCorrect:isCorrect];
//        }
        
        for (id<VEIpadShareYoutubeDelegate> observer in _observers)
        {
            if (observer && [observer respondsToSelector:@selector(youtubeNetworkIsCorrect:)])
            {
                [observer youtubeNetworkIsCorrect:isCorrect];
            }
        }
    };
    
    if (!_isSendAsynReq)
    {
        NSError *err = nil;
        NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:&err];
        handlerCheckYoutubeInternetResponse(data, err);
    }
    else
    {
        [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
            handlerCheckYoutubeInternetResponse(data, connectionError);
        }];
    }

    return;
}

- (void)checkYoutubeIsStoreTokenValid
{
    if (nil != TOKEN_YOUTUBE)
    {
        //check if valid
        [self _nameForLoggedInUser]; //just used to check if the key we got is still valid
    }
    else
    {
//        if (self.delegate && [self.delegate respondsToSelector:@selector(youtubeIsStoreTokenValid:)])
//        {
//            [self.delegate youtubeIsStoreTokenValid:NO];
//        }
        
        for (id<VEIpadShareYoutubeDelegate> observer in _observers)
        {
            if (observer && [observer respondsToSelector:@selector(youtubeIsStoreTokenValid:)])
            {
                [observer youtubeIsStoreTokenValid:NO];
            }
        }
    }
}

- (void)getYoutubeCategoriesDictionary
{
	NSString *urlString = ESSLocalizedString(@"http://gdata.youtube.com/schemas/2007/categories.cat?hl=en-US", nil);
	NSURL *url = [NSURL URLWithString:urlString];
	NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:5.0f];
	[req setHTTPMethod:@"GET"];
	
    void (^handlerGetYoutubeCategoriesDictionaryResponse)() = ^(NSData *inputData, NSError *inputError) {
        
        if (nil == inputData)
        {
//            if (self.delegate && [self.delegate respondsToSelector:@selector(youtubeDidGetCategor:)])
//            {
//                [self.delegate youtubeDidGetCategor:nil];
//            }
            
            for (id<VEIpadShareYoutubeDelegate> observer in _observers)
            {
                if (observer && [observer respondsToSelector:@selector(youtubeDidGetCategor:)])
                {
                    [observer youtubeDidGetCategor:nil];
                }
            }
            
            return;
        }
        
        NSString *retStr = [[NSString alloc] initWithData:inputData encoding:NSUTF8StringEncoding];
        
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        NSRange range = [retStr rangeOfString:@"<atom:category term='"];
        
        while (range.location != NSNotFound)
        {
            @autoreleasepool
            {
                NSString *catStr = [retStr substringFromIndex:range.location];
                catStr = [catStr substringToIndex:[catStr rangeOfString:@"</atom:category"].location];
                
                retStr = [[[retStr autorelease] substringFromIndex:range.location+range.length] retain];
                range = [retStr rangeOfString:@"<atom:category term='"];
                
                NSRange deprecatedRange = [catStr rangeOfString:@"<yt:deprecated/>"];
                
                if (deprecatedRange.location == NSNotFound)
                {
                    NSRange assignableRange = [catStr rangeOfString:@"<yt:assignable/>"];
                    
                    if (assignableRange.location != NSNotFound)
                    {
                        //is not deprecated and is assignable
                        NSRange _range = [catStr rangeOfString:@"<atom:category term='"];
                        
                        if (_range.location != NSNotFound)
                        {
                            NSString *term = [catStr substringFromIndex:_range.location+_range.length];
                            term = [term substringToIndex:[term rangeOfString:@"'"].location];
                            _range = [catStr rangeOfString:@"' label='"];
                            
                            if (_range.location != NSNotFound)
                            {
                                NSString *label = [catStr substringFromIndex:_range.location+_range.length];
                                label = [label substringToIndex:[label rangeOfString:@"'"].location];
                                
                                term = (NSString *)[(NSString *)CFXMLCreateStringByUnescapingEntities(kCFAllocatorDefault, (CFStringRef)term, NULL) autorelease];
                                label = (NSString *)[(NSString *)CFXMLCreateStringByUnescapingEntities(kCFAllocatorDefault, (CFStringRef)label, NULL) autorelease];
                                
                                [dict setObject:term forKey:label];
                            }
                        }
                    }
                }
            }
        }
        
        [retStr release];
        
//        if (self.delegate && [self.delegate respondsToSelector:@selector(youtubeDidGetCategor:)])
//        {
//            [self.delegate youtubeDidGetCategor:dict];
//        }
        
        for (id<VEIpadShareYoutubeDelegate> observer in _observers)
        {
            if (observer && [observer respondsToSelector:@selector(youtubeDidGetCategor:)])
            {
                [observer youtubeDidGetCategor:dict];
            }
        }

    };
    
    if (!_isSendAsynReq)
    {
        NSData *retData = [NSURLConnection sendSynchronousRequest:req returningResponse:nil error:nil];
        handlerGetYoutubeCategoriesDictionaryResponse(retData, nil);
    }
    else
    {
        [NSURLConnection sendAsynchronousRequest:req queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
            
            handlerGetYoutubeCategoriesDictionaryResponse(data, nil);
        }];
    }

	return;
}

- (void)authorizeYoutubeWithUsername:(NSString *)username password:(NSString *)password
{
	if (0 == [username length] || 0 == [password length] || nil == _developerKey)
    {
        return;
    }

	NSString *ns_username = (NSString *)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (CFStringRef)username, NULL, NULL, kCFStringEncodingUTF8);
	NSString *ns_password = (NSString *)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (CFStringRef)password, NULL, NULL, kCFStringEncodingUTF8);
    
	[ns_username autorelease];
    [ns_password autorelease];
    
    NSURL *url = [NSURL URLWithString:@"https://www.google.com/accounts/ClientLogin"];
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:5.0f];
    
    NSString *bodyString = [NSString stringWithFormat:@"Email=%@&Passwd=%@&service=youtube&source=essyoutube",ns_username,ns_password];
    [req setHTTPBody:[bodyString dataUsingEncoding:NSUTF8StringEncoding]];
    [req setHTTPMethod:@"POST"];
    [req setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    
    void (^handlerAuthorizeResponse)() = ^(NSData *inputData, NSError *inputError) {
        
        NSString *authToken = nil;
        
        if (nil != inputData)
        {
            authToken = [[[NSString alloc]initWithData:inputData encoding:NSUTF8StringEncoding]autorelease];
        }
        
        //iOS
        if (nil == authToken)
        {
            //                [_youTubeDelegate loginResult:NO infomation:err.localizedDescription];
            
//            if (self.delegate && [self.delegate respondsToSelector:@selector(youtubeDidAuthorizeIsSuccess:withFailType:)])
//            {
//                [self.delegate youtubeDidAuthorizeIsSuccess:NO withFailType:AuthorizeFailType_TokenNull];
//            }
            
            for (id<VEIpadShareYoutubeDelegate> observer in _observers)
            {
                if (observer && [observer respondsToSelector:@selector(youtubeDidAuthorizeIsSuccess:withFailType:)])
                {
                    [observer youtubeDidAuthorizeIsSuccess:NO withFailType:YoutubeAuthorizeFailType_TokenNull];
                }
            }
            
            return;
        }
        
        if ([authToken rangeOfString:@"Error=" options:NSCaseInsensitiveSearch].location != NSNotFound)
        {
            NSRange CodeRange = [authToken rangeOfString:@"Error"];
            NSString *returnCode = [authToken substringFromIndex:CodeRange.location + CodeRange.length];
            returnCode = [returnCode substringFromIndex:[returnCode rangeOfString:@"="].location+1];
            returnCode = [returnCode substringToIndex:[returnCode rangeOfString:@"\n"].location];
            
            //            [_youTubeDelegate loginResult:NO infomation:returnCode];
            
//            if (self.delegate && [self.delegate respondsToSelector:@selector(youtubeDidAuthorizeIsSuccess:withFailType:)])
//            {
//                [self.delegate youtubeDidAuthorizeIsSuccess:NO withFailType:AuthorizeFailType_TokenError];
//            }
            
            for (id<VEIpadShareYoutubeDelegate> observer in _observers)
            {
                if (observer && [observer respondsToSelector:@selector(youtubeDidAuthorizeIsSuccess:withFailType:)])
                {
                    [observer youtubeDidAuthorizeIsSuccess:NO withFailType:YoutubeAuthorizeFailType_TokenError];
                }
            }
            
            return;
        }
        
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        [userDefaults setObject:authToken forKey:KEY_TOKEN_YOUTUBE];
        [userDefaults synchronize];
        
        NSRange authRange = [authToken rangeOfString:@"Auth="];
        
        if (authRange.location == NSNotFound)
        {
            for (id<VEIpadShareYoutubeDelegate> observer in _observers)
            {
                if (observer && [observer respondsToSelector:@selector(youtubeDidAuthorizeIsSuccess:withFailType:)])
                {
                    [observer youtubeDidAuthorizeIsSuccess:NO withFailType:YoutubeAuthorizeFailType_Fail];
                }
            }
            
            return;
        }
        
        for (id<VEIpadShareYoutubeDelegate> observer in _observers)
        {
            if (observer && [observer respondsToSelector:@selector(youtubeDidAuthorizeIsSuccess:withFailType:)])
            {
                [observer youtubeDidAuthorizeIsSuccess:YES withFailType:YoutubeAuthorizeFailType_NoFail];
            }
        }
    };
    
    if (!_isSendAsynReq)
    {
        NSError *err = nil;
        NSData *retData = [NSURLConnection sendSynchronousRequest:req returningResponse:nil error:&err];
        handlerAuthorizeResponse(retData, err);
    }
    else
    {
        [NSURLConnection sendAsynchronousRequest:req queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
            
            handlerAuthorizeResponse(data, connectionError);
        }];
    }
}

- (void)uploadYoutubeVideoAtURL:(NSURL *)url
                      withTitle:(NSString *)title
                    description:(NSString *)description
                    makePrivate:(BOOL)makePrivate
                       keywords:(NSString *)keywords
                       category:(NSString *)category
{
	if (nil == _developerKey || nil == TOKEN_YOUTUBE || nil == url || 0 == [title length] || nil != _uploader)
    {
        return;
    }

	if (0 == [description length])
    {
        description = @"";
    }
		
	if (0 == [keywords length])
    {
        keywords = @"";
    }

	NSString *innerDescription = [(NSString *)CFXMLCreateStringByEscapingEntities(kCFAllocatorDefault, (CFStringRef)description, NULL) autorelease];
	NSString *innerKeywords = [(NSString *)CFXMLCreateStringByEscapingEntities(kCFAllocatorDefault, (CFStringRef)keywords, NULL) autorelease];
	NSString *innerTitle = [(NSString *)CFXMLCreateStringByEscapingEntities(kCFAllocatorDefault, (CFStringRef)title, NULL) autorelease];
	
	NSURL *uploadURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://uploads.gdata.youtube.com/feeds/api/users/default/uploads?v=2&key=%@", _developerKey]];
	NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:uploadURL cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:5.0f];
    
    NSString *tmp_token = TOKEN_YOUTUBE;
	NSString *justAuth = [tmp_token substringFromIndex:[tmp_token rangeOfString:@"Auth="].location + 5];
	justAuth = [justAuth stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    
	[req setHTTPMethod:@"POST"];
	[req setValue:[@"GoogleLogin auth=" stringByAppendingString:[justAuth stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] forHTTPHeaderField:@"Authorization"];
	[req setValue:[[url path] lastPathComponent] forHTTPHeaderField:@"Slug"];
	[req setValue:@"multipart/related; boundary=\"3i2ndDfv2rTHiSisAbouNdArYfORhtTPEefj3q2f\"" forHTTPHeaderField:@"Content-Type"];
	[req setValue:@"close" forHTTPHeaderField:@"Connection"];
	
	//first, re-write the data of videoURL combined with the MIME-stuff to disk again
	NSString *beginString = [NSString stringWithFormat:@"--3i2ndDfv2rTHiSisAbouNdArYfORhtTPEefj3q2f\r\nContent-Type: application/atom+xml; charset=UTF-8\r\n\r\n<?xml version=\"1.0\"?><entry xmlns=\"http://www.w3.org/2005/Atom\" xmlns:media=\"http://search.yahoo.com/mrss/\" xmlns:yt=\"http://gdata.youtube.com/schemas/2007\"><media:group><yt:incomplete/><media:category scheme=\"http://gdata.youtube.com/schemas/2007/categories.cat\">%@</media:category><media:title type=\"plain\">%@</media:title><media:description type=\"plain\">%@</media:description><media:keywords>%@</media:keywords>",category,innerTitle,innerDescription,innerKeywords];
    
	if (makePrivate)
    {
        beginString = [beginString stringByAppendingString:@"<yt:private/><yt:accessControl action=\"list\" permission=\"denied\"/>"];
    }
		
	beginString = [beginString stringByAppendingString:@"</media:group></entry>\r\n\r\n"];
	
	//beginString = [beginString stringByAppendingString:@"--3i2ndDfv2rTHiSisAbouNdArYfORhtTPEefj3q2f\r\nContent-Type: video/quicktime\r\nContent-Transfer-Encoding: binary\r\n\r\n"];
	beginString = [beginString stringByAppendingString:@"--3i2ndDfv2rTHiSisAbouNdArYfORhtTPEefj3q2f\r\nContent-Type: application/octet-stream\r\n\r\n"];
    
	NSString *uploadTempFilename = [NSTemporaryDirectory() stringByAppendingPathComponent:@"essyoutubeTempVideoUpload"];
    
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
        NSLog_DEBUG(@"error writing beginning");
    }

	const size_t bufferSize = 65536;
	size_t readSize = 0;
	uint8_t *buffer = (uint8_t *)calloc(1, bufferSize);
	NSInputStream *iStr = [NSInputStream inputStreamWithURL:url];
	[iStr open];
    
	while ([iStr hasBytesAvailable])
	{
		if (!(readSize = [iStr read:buffer maxLength:bufferSize]))
			break;
		
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
        NSLog(@"error writing ending of file");
    }
		
	[oStr close];
	
	unsigned long long fileSize = -1;
	fileSize = [[[NSFileManager defaultManager]attributesOfItemAtPath:uploadTempFilename error:nil]fileSize];
	[req setValue:[NSString stringWithFormat:@"%llu",fileSize] forHTTPHeaderField:@"Content-Length"];
	
	//  second, upload it
	NSInputStream *inStr = [NSInputStream inputStreamWithFileAtPath:uploadTempFilename];
	[req setHTTPBodyStream:inStr];
	
	_uploader = [[NSURLConnection alloc]initWithRequest:req delegate:self];
    [_uploader start];
}

- (void)cancelYoutubeUploader
{
    [_uploader cancel];
    [_uploader release];
    _uploader = nil;
}

#pragma mark - private

- (void)_nameForLoggedInUser
{
	if (nil == _developerKey || nil == TOKEN_YOUTUBE)
    {
        for (id<VEIpadShareYoutubeDelegate> observer in _observers)
        {
            if (observer && [observer respondsToSelector:@selector(youtubeIsStoreTokenValid:)])
            {
                [observer youtubeIsStoreTokenValid:NO];
            }
        }
        
        return;
    }

    NSString *token = TOKEN_YOUTUBE;
	NSString *justAuth = [token substringFromIndex:[token rangeOfString:@"Auth="].location + 5];
	justAuth = [justAuth stringByReplacingOccurrencesOfString:@"\n" withString:@""];
	
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://gdata.youtube.com/feeds/api/users/default?v=2&key=%@&format=xml", _developerKey]];
	NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:5.0f];
	[req setHTTPMethod:@"GET"];
	[req setValue:[@"GoogleLogin auth=" stringByAppendingString:[justAuth stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] forHTTPHeaderField:@"Authorization"];

    __block BOOL isValid = YES;
    
    void (^handlerCheckYoutubeIsStoreTokenValidResponse)() = ^(NSData *inputData, NSError *inputError) {
        
        if (inputError)
        {
            isValid = NO;
        }
        
        if (nil == inputData)
        {
            isValid = NO;
        }
        
        NSString *retStr = [[[NSString alloc]initWithData:inputData encoding:NSUTF8StringEncoding]autorelease];
        
        NSRange userNameRange = [retStr rangeOfString:@"<yt:username "];
        NSRange nameRange = [retStr rangeOfString:@"<name"];
        
        if ((userNameRange.location == NSNotFound) || nameRange.location == NSNotFound)
        {
            isValid = NO;
        }
        
        //  changes by Jean-Pierre Rizzi
        NSString *username = nil;
        
        if (retStr)
        {
            username = [retStr substringFromIndex:userNameRange.location+userNameRange.length];
        }

        if (username)
        {
            username = [username substringFromIndex:[username rangeOfString:@">"].location+1];
        }
        
        if (username)
        {
            username = [username substringToIndex:[username rangeOfString:@"</yt:username"].location];
        }
        
        
        NSString *nameStr = nil;
        
        if ([retStr length] > 0)
        {
            nameStr = [retStr substringFromIndex:nameRange.location+nameRange.length];
        }
        
        if ([nameStr length] > 0)
        {
            nameStr = [nameStr substringFromIndex:[nameStr rangeOfString:@">"].location+1];
        }
        
        if ([nameStr length] > 0)
        {
            nameStr = [nameStr substringToIndex:[nameStr rangeOfString:@"</name"].location];
        }
        
        if ([nameStr length] > 0)
        {
            isValid = YES;
        }

        for (id<VEIpadShareYoutubeDelegate> observer in _observers)
        {
            if (observer && [observer respondsToSelector:@selector(youtubeIsStoreTokenValid:)])
            {
                [observer youtubeIsStoreTokenValid:isValid];
            }
        }
    };
    
    if (!_isSendAsynReq)
    {
        NSError *error = nil;
        NSData *retDat = [NSURLConnection sendSynchronousRequest:req returningResponse:nil error:&error];
        handlerCheckYoutubeIsStoreTokenValidResponse(retDat, error);
    }
    else
    {
        [NSURLConnection sendAsynchronousRequest:req queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
            
            handlerCheckYoutubeIsStoreTokenValidResponse(data, connectionError);
        }];
    }
}

- (void)_judgeAndNotifyWithVideoID:(NSString *)vID isFinishUpload:(BOOL)isFinish isFail:(BOOL)isFail
{
    if (!isFinish)
    {
        double delayInSeconds = 10.0;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [self _checkProcessingOnYouTubeWithVideoID:nil];
        });
        
        return;
    }
    else
    {
        if (isFail)
        {
            for (id<VEIpadShareYoutubeDelegate> observer in _observers)
            {
                if (observer && [observer respondsToSelector:@selector(youtubeUploadIsFinished:withYouTubeVideoURL:withFailType:)])
                {
                    [observer youtubeUploadIsFinished:NO withYouTubeVideoURL:nil withFailType:_uploadFailType];
                }
            }
        }
        else
        {
            NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://www.youtube.com/watch?v=%@", _forCheckVideoID]];
            
            for (id<VEIpadShareYoutubeDelegate> observer in _observers)
            {
                if (observer && [observer respondsToSelector:@selector(youtubeUploadIsFinished:withYouTubeVideoURL:withFailType:)])
                {
                    [observer youtubeUploadIsFinished:YES withYouTubeVideoURL:url withFailType:YoutubeUploadFailType_NoFail];
                }
            }
        }
    }
}

- (void)_checkProcessingOnYouTubeWithVideoID:(NSString *)vidID
{
    BOOL failed = NO;
    [self _videoUploadWithID:vidID isFinishedWithError:&failed];
}

- (void)_videoUploadWithID:(NSString *)videoID isFinishedWithError:(BOOL *)uploadFailed
{
	if (nil == _forCheckVideoID)
    {
        _checkMessage = @"Check does not pass";
        
        _uploadFailType = YoutubeUploadFailType_videoIDNull;
        
        for (id<VEIpadShareYoutubeDelegate> observer in _observers)
        {
            if (observer && [observer respondsToSelector:@selector(youtubeUploadIsFinished:withYouTubeVideoURL:withFailType:)])
            {
                [observer youtubeUploadIsFinished:NO withYouTubeVideoURL:nil withFailType:_uploadFailType];
            }
        }
        
        return;
    }
    
	if (nil != uploadFailed)
    {
        *uploadFailed = NO;
    }

	NSString *urlString = [NSString stringWithFormat:@"https://gdata.youtube.com/feeds/api/users/default/uploads/%@", _forCheckVideoID];
	NSURL *url = [NSURL URLWithString:urlString];
    
	NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:5.0f];
    
    NSString *token = TOKEN_YOUTUBE;
	NSString *justAuth = [token substringFromIndex:[token rangeOfString:@"Auth="].location + 5];
	justAuth = [justAuth stringByReplacingOccurrencesOfString:@"\n" withString:@""];
	[req setHTTPMethod:@"GET"];
	[req setValue:[@"GoogleLogin auth=" stringByAppendingString:[justAuth stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] forHTTPHeaderField:@"Authorization"];

    void (^handlerUploadYoutubeVideoResponse)() = ^(NSData *inputData, NSError *inputError) {

        BOOL fail = NO;
        
        if (nil == inputData)
        {
            fail = YES;
            
            _checkMessage = @"Check does not pass";
            
            _uploadFailType = YoutubeUploadFailType_ResponseDataNull;
            
            [self _judgeAndNotifyWithVideoID:nil isFinishUpload:YES isFail:fail];
            
            return;
        }
    
        NSString *str = [[[NSString alloc]initWithData:inputData encoding:NSUTF8StringEncoding]autorelease];
        
        NSRange stateRange = [str rangeOfString:@"<yt:state"];
        
        if (stateRange.location == NSNotFound)
        {
            fail = NO;
        }
        else
        {
            NSString *state = [str substringFromIndex:stateRange.location+stateRange.length];
            NSRange nameRange = [state rangeOfString:@" name='"];
            
            if (nameRange.location != NSNotFound)
            {
                NSString *state_1 = [state substringFromIndex:nameRange.location + nameRange.length];
                state_1 = [state_1 substringToIndex:[state_1 rangeOfString:@"'"].location];
                
                NSLog(@"str: %@",str);
                
                if ([state rangeOfString:@"processing" options:NSCaseInsensitiveSearch].location != NSNotFound)
                {
//                    return NO; //still processing
//                    handlerFinishUpload(NO, uploadFailed);
                    [self _judgeAndNotifyWithVideoID:nil isFinishUpload:NO isFail:fail];
                    
                    return;
                }
                else
                {
                    
                    NSRange reasonCodeRange = [state rangeOfString:@" reasonCode='"];
                    
                    if (reasonCodeRange.length != NSNotFound)
                    {
                        NSLog(@"state = %@", state);
                        state = [state substringFromIndex:reasonCodeRange.location + reasonCodeRange.length];
                        NSLog(@"state = %@", state);
                        state = [state substringToIndex:[state rangeOfString:@"'"].location];
                        NSLog(@"state = %@", state);

                        _checkMessage = [self messageDetailWithState:state];
                        
                        NSLog(@"checkMessage = %@", _checkMessage);
                    }

                    fail = YES;
                }
            }
        }

        [self _judgeAndNotifyWithVideoID:nil isFinishUpload:YES isFail:fail];
        
        return;
    };
    
    if (!_isSendAsynReq)
    {
        NSData *data = [NSURLConnection sendSynchronousRequest:req returningResponse:nil error:nil];
        handlerUploadYoutubeVideoResponse(data, nil);
    }
    else
    {
        [NSURLConnection sendAsynchronousRequest:req queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
            
            handlerUploadYoutubeVideoResponse(data, connectionError);
        }];
    }
}

#pragma mark - NSURLConnectionDelegate

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	[_uploader cancel];
    [_uploader release];
	_uploader = nil;

    for (id<VEIpadShareYoutubeDelegate> observer in _observers)
    {
        if (observer && [observer respondsToSelector:@selector(youtubeUploadIsFinished:withYouTubeVideoURL:withFailType:)])
        {
            [observer youtubeUploadIsFinished:NO withYouTubeVideoURL:nil withFailType:YoutubeUploadFailType_NetworkError];
        }
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	if (nil == _receivedData)
    {
        _receivedData = [[NSMutableData data]retain];
    }
		
	[_receivedData appendData:data];
}

- (void)connection:(NSURLConnection *)connection didSendBodyData:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite
{
    for (id<VEIpadShareYoutubeDelegate> observer in _observers)
    {
        if (observer && [observer respondsToSelector:@selector(youtubeUploadUpdatedWithUploadedBytes:ofTotalBytes:)])
        {
            [observer youtubeUploadUpdatedWithUploadedBytes:totalBytesWritten ofTotalBytes:totalBytesExpectedToWrite];
        }
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    if (nil == _receivedData)
    {
        return;
    }
    
    [_forCheckVideoID release];
    _forCheckVideoID = nil;
    
	NSString *resp = [[NSString alloc]initWithData:_receivedData encoding:NSUTF8StringEncoding];
    
    [_receivedData release];
	_receivedData = nil;
    
    //    NSLog(@"%@");
    
	NSRange URLRange = [resp rangeOfString:@":video:"];
    
	if (URLRange.location == NSNotFound)
    {//upload fail
        
        //get code
        NSRange CodeRange = [resp rangeOfString:@"<code"];
        NSString *vidCode = [resp substringFromIndex:CodeRange.location + CodeRange.length];
        vidCode = [vidCode substringFromIndex:[vidCode rangeOfString:@">"].location+1];
        vidCode = [vidCode substringToIndex:[vidCode rangeOfString:@"</code>"].location];
        NSLog(@"return error code :%@", vidCode);
        
        //get internalReason
        NSRange internalReasonRange = [resp rangeOfString:@"<internalReason"];
        NSString *vidInternalReason = [resp substringFromIndex:internalReasonRange.location + internalReasonRange.length];
        vidInternalReason = [vidInternalReason substringFromIndex:[vidInternalReason rangeOfString:@">"].location+1];
        vidInternalReason = [vidInternalReason substringToIndex:[vidInternalReason rangeOfString:@"</internalReason>"].location];
        NSLog(@"return error code :%@", vidInternalReason);

        _uploadFailType = YoutubeUploadFailType_NoVideoTag;
        
        for (id<VEIpadShareYoutubeDelegate> observer in _observers)
        {
            if (observer && [observer respondsToSelector:@selector(youtubeUploadIsFinished:withYouTubeVideoURL:withFailType:)])
            {
                [observer youtubeUploadIsFinished:NO withYouTubeVideoURL:nil withFailType:_uploadFailType];
            }
        }
	}
    else
    {//upload success
        
		NSString *vidID = [resp substringFromIndex:URLRange.location + URLRange.length];
		vidID = [vidID substringToIndex:[vidID rangeOfString:@"</id>"].location];
		
        NSLog(@"vidID = %@", vidID);
        
        [_forCheckVideoID release];
        _forCheckVideoID = nil;
        _forCheckVideoID = [vidID retain];
        
		[self _checkProcessingOnYouTubeWithVideoID:vidID];
	}
	
	[resp release];
    resp = nil;
	
	[_uploader cancel];
    [_uploader release];
	_uploader = nil;
}

@end
