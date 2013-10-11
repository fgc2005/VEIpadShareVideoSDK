//
//  Utils.h
//  ESSYoutubeRound2
//
//  Created by 叶俊荣 on 9/26/13.
//
//

#import <UIKit/UIKit.h>

@interface OAuthUtils : NSObject

+ (NSString *)URLStringWithoutQuery:(NSURL *)url;
+ (NSString *)URLEncodedString:(NSString*) str;
+ (NSString*)URLDecodedString:(NSString*) str;


@end
