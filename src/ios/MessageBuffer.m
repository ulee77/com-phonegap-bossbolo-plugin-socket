//
//  LFCGzipUtillity.m
//  TechownShow
//
//  Created by kuro on 12-8-27.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "MessageBuffer.h"


static MessageBuffer *msgBuffer = nil;

@implementation MessageBuffer

@synthesize jsonData = _jsonData;

+(MessageBuffer*)getInstance
{
    if(msgBuffer == nil){
        msgBuffer = [[MessageBuffer alloc]init];
        [msgBuffer initJsonData];
    }
    return msgBuffer;
}

-(void)initJsonData{
    _jsonData = [[NSMutableDictionary alloc]init];
}

@end
