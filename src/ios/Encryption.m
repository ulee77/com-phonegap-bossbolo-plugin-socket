//
//  LFCGzipUtillity.m
//  TechownShow
//
//  Created by kuro on 12-8-27.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "Encryption.h"
#import "MessageCodec.h"

@implementation Encryption

+ (NSData *) dataWithArray:(NSArray *) dataArray
{
    @autoreleasepool {
        int dataCount = (int)[dataArray count];
        Byte* bytes = (Byte*) malloc(dataCount);
        for (int i=0; i<dataCount; i++) {
            bytes[i] = (Byte)[[dataArray objectAtIndex:i] intValue];
        }
        NSMutableData *mData = [[NSMutableData alloc] initWithBytes:bytes length:dataCount];
        free(bytes);
        return mData;
    }
}

+ (NSData *) dataWithByte:(Byte *)bytes length:(NSUInteger)len
{
    NSData *mData = [[NSData alloc] initWithBytes:bytes length:len];
    return mData;
}



+ (NSString *) stringWithData:(NSData *) data
{
    NSString *dataString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    return dataString;
}

+ (NSString *) stringWithDic:(NSMutableDictionary *)dic
{
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:&error];
    NSString *jsonstr =[[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    return jsonstr;
}



+ (Byte*) byteWithArray:(NSArray*) array{
    @autoreleasepool {
        int dataCount = (int)[array count];
        Byte* bytes = (Byte*) malloc(dataCount+1);
        for (int i=0; i<dataCount; i++) {
            bytes[i] = (Byte)[[array objectAtIndex:i] intValue];
        }
        bytes[dataCount] = 0;
        return bytes;
    }
}



+ (NSArray *) arrayWithByte:(Byte *)bytes length:(NSUInteger*)len
{
    NSMutableArray *mArray = [NSMutableArray arrayWithObject:[self dataWithByte:bytes length:*len]];
    NSArray *array = [NSArray arrayWithArray:mArray];
    return array;
}

+ (NSArray *) arrayWithData:(NSData *)data
{
//    NSMutableDictionary *nsmd = [[NSMutableDictionary alloc]init];
    
    return nil;
}


+(NSString *) jsonStringWithDictionary:(NSDictionary *)dictionary{
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dictionary options:0 error:nil];
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    return jsonString;
}

@end
