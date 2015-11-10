//
//  LFCGzipUtillity.h
//  TechownShow
//
//  Created by kuro on 12-8-27.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Encryption : NSObject

+ (NSData *) dataWithArray:(NSArray *) dataArray;
+ (NSData *) dataWithByte:(Byte *) bytes length:(NSUInteger)len;

+ (NSString *) stringWithData:(NSData *) data;
+ (NSString *) stringWithDic:(NSMutableDictionary *)dic;

+ (Byte*) byteWithArray:(NSArray*) array;

//+ (NSArray *) arrayWithByte:(Byte *)bytes;
+ (NSArray *) arrayWithData:(NSData *)data;

+(NSString *) jsonStringWithDictionary:(NSDictionary *)dictionary;

@end
