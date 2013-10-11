//
//  Utils.m
//  ESSYoutubeRound2
//
//  Created by 叶俊荣 on 9/26/13.
//
//

#import "OAuthUtils.h"

@interface OAuthUtils ()

@end

@implementation OAuthUtils

+ (NSString *)URLStringWithoutQuery:(NSURL *)url{
    NSArray *parts = [[url absoluteString] componentsSeparatedByString:@"?"];
    return [parts objectAtIndex:0];
}


+ (NSString *)URLEncodedString:(NSString*) str
{
    NSString *result = (NSString *)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
                                                                           (CFStringRef)str,
                                                                           NULL,
																		   CFSTR("!*'();:@&=+$,/?%#[]"),
                                                                           kCFStringEncodingUTF8);
    [result autorelease];
	return result;
}

+ (NSString*)URLDecodedString:(NSString*) str {
	NSString *result = (NSString *)CFURLCreateStringByReplacingPercentEscapesUsingEncoding(kCFAllocatorDefault,
																						   (CFStringRef)str,
																						   CFSTR(""),
																						   kCFStringEncodingUTF8);
    [result autorelease];
	return result;
}

@end
