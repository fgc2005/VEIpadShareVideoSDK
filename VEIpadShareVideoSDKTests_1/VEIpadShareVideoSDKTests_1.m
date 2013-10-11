//
//  VEIpadShareVideoSDKTests_1.m
//  VEIpadShareVideoSDKTests_1
//
//  Created by chao on 13-10-11.
//  Copyright (c) 2013年 Sachsen. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>
#import "VEIpadShareVideoSDK.h"

@interface VEIpadShareVideoSDKTests_1 : SenTestCase
<
VEIpadShareFlickrDelegate
>

@end

@implementation VEIpadShareVideoSDKTests_1

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExample
{
//    STFail(@"No implementation for \"%s\"", __PRETTY_FUNCTION__);
    
    VEIpadShareFlickr *padShareFlickr = [[VEIpadShareFlickr alloc]initWithDelegate:self applicationKey:@"8d481161fd2d99ef633f94b3c55b5309" applicationSecret:@"e85b9240af2898e3"];
    [padShareFlickr go:NO];
    CFRunLoopRun();
}

#pragma mark - VEIpadShareFlickrDelegate

- (void)flickrNetworkIsCorrect:(BOOL)isCorrect
{
    if (isCorrect)
    {
        NSLog(@"flick network ok");
    }
    else
    {
        NSLog(@"flick network fail");
    }
    
    CFRunLoopRef runLoopRef = CFRunLoopGetCurrent();
    CFRunLoopStop(runLoopRef);
}

- (void)flickrIsStoreTokenValid:(BOOL)isValid
{

}

- (void)flickrDidGetLoginTokenIsSuccess:(BOOL)isSuccess withRequest:(NSURLRequest *)request withFailType:(DidGetLoginTokenFailType)type
{

}

- (void)flickrAuthenticateIsSuccess:(BOOL)isSuccess withFailType:(FlickrAuthenticateFailType)type
{
    
}

@end
