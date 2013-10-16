//
//  EmailUtil.m
//  SMTPSender-Example
//
//  Created by 叶俊荣 on 9/30/13.
//
//

#import "EmailUtil.h"
#import "EmailBase64Transcoder.h"

@implementation EmailUtil
+(id)decodeBase64ForString:(NSString *)decodeString
{
    NSData *decodeBuffer = nil;
    // Must be 7-bit clean!
    NSData *tmpData = [decodeString dataUsingEncoding:NSASCIIStringEncoding];
    
    size_t estSize = EstimateBas64DecodedDataSize([tmpData length]);
    uint8_t* outBuffer = calloc(estSize, sizeof(uint8_t));
    
    size_t outBufferLength = estSize;
    if (Base64DecodeData([tmpData bytes], [tmpData length], outBuffer, &outBufferLength))
    {
        decodeBuffer = [NSData dataWithBytesNoCopy:outBuffer length:outBufferLength freeWhenDone:YES];
    }
    else
    {
        free(outBuffer);
        [NSException raise:@"NSData+Base64AdditionsException" format:@"Unable to decode data!"];
    }
    
    return decodeBuffer;
}

+(id)decodeWebSafeBase64ForString:(NSString *)decodeString
{
    return [self decodeBase64ForString:[[decodeString stringByReplacingOccurrencesOfString:@"-" withString:@"+"] stringByReplacingOccurrencesOfString:@"_" withString:@"/"]];
}

+ (NSString *)encodeBase64ForData:(NSData *)data
{
    NSString *encodedString = nil;
    
    // Make sure this is nul-terminated.
    size_t outBufferEstLength = EstimateBas64EncodedDataSize([data length]) + 1;
    char *outBuffer = calloc(outBufferEstLength, sizeof(char));
    
    size_t outBufferLength = outBufferEstLength;
    if (Base64EncodeData([data bytes], [data length], outBuffer, &outBufferLength, FALSE))
    {
        encodedString = [NSString stringWithCString:outBuffer encoding:NSASCIIStringEncoding];
    }
    else
    {
        [NSException raise:@"NSData+Base64AdditionsException" format:@"Unable to encode data!"];
    }
    
    free(outBuffer);
    
    return encodedString;
}

+ (NSString *)encodeWebSafeBase64ForData:(NSData *) data
{
    return [[[self encodeBase64ForData:data] stringByReplacingOccurrencesOfString:@"+" withString:@"-"] stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
}

+ (NSString *)encodeWrappedBase64ForData:(NSData *) data
{
    NSString *encodedString = nil;
    
    // Make sure this is nul-terminated.
    size_t outBufferEstLength = EstimateBas64EncodedDataSize([data length]) + 1;
    char *outBuffer = calloc(outBufferEstLength, sizeof(char));
    
    size_t outBufferLength = outBufferEstLength;
    if (Base64EncodeData([data bytes], [data length], outBuffer, &outBufferLength, TRUE))
    {
        encodedString = [NSString stringWithCString:outBuffer encoding:NSASCIIStringEncoding];
    }
    else
    {
        [NSException raise:@"NSData+Base64AdditionsException" format:@"Unable to encode data!"];
    }
    
    free(outBuffer);
    
    return encodedString;
}

+ (NSString *)appendString:(NSString *)firstString secondString:(NSString *)secondString thirdString:(NSString *)thirdString{
    return [[firstString stringByAppendingString:secondString] stringByAppendingString:thirdString];
}

+ (NSString *)appendString:(NSString *)firstString secondString:(NSString *)secondString {
    return  [firstString stringByAppendingString:secondString] ;
} 

@end
