//
//  VEIpadShareTumblr.h
//  VEIpadShareVideoSDK
//
//  Created by chao on 13-11-13.
//  Copyright (c) 2013年 Sachsen. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface VEIpadShareTumblr : NSObject
{
    NSMutableArray              *_observers;
}

- (id)initYoutubeWithDelegates:(NSMutableArray *)array
                  developerKey:(NSString *)key
                        secret:(NSString *)secret;

@end
