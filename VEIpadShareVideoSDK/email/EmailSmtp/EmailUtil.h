//
//  EmailUtil.h
//  SMTPSender-Example
//
//  Created by 叶俊荣 on 9/30/13.
//
//

#import <Foundation/Foundation.h>

@interface EmailUtil : NSObject

+(id)decodeBase64ForString:(NSString *)decodeString;
+(id)decodeWebSafeBase64ForString:(NSString *)decodeString;

+ (NSString *)encodeBase64ForData:(NSData *) data;
+ (NSString *)encodeWebSafeBase64ForData:(NSData *) data;
+ (NSString *)encodeWrappedBase64ForData:(NSData *) data;
+ (NSString *)appendString:(NSString *)firstString secondString:(NSString *)secondString thirdString:(NSString *)thirdString;
+ (NSString *)appendString:(NSString *)firstString secondString:(NSString *)secondString ;
@end
