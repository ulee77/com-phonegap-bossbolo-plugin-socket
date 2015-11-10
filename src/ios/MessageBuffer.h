//
//  MessageBuffer.h
//
//  Created by lihh on 15-3-20.
//  Copyright (c) 2015年 bolo. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MessageBuffer : NSObject
{
    NSMutableDictionary *_jsonData;
}

@property(readwrite,retain) NSMutableDictionary * jsonData;

+(MessageBuffer*) getInstance;
-(void)initJsonData;

@end
