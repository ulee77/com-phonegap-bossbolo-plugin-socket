//
//  MessageCodec.m
//  BppClient
//
//  Created by bossbolo on 15/2/9.
//
//

#import <Foundation/Foundation.h>
#import "MessageCodec.h"
#import <Foundation/NSObjCRuntime.h>
#import <string.h>
#import "zlib.h"
#import "MessageBuffer.h"
#import "myZip.h"
#import "Encryption.h"


@implementation MessageCodec



-(MessageCodec*) init{
    self = [super init];
    urlPath = @"http://192.168.191.1/";
    filePath = @"mnt/sdcard/svg_data";
//    dataEnd = YES;
//    dataLen = 0;
    return self;
}

 BOOL dataEnd = YES;
 int allDataLen = 0;
 int currentIndex = 0;
 Byte* dataBuffer = nil;
 NSString *replyType = @"";
 NSString *messageType = @"";
 NSString *encrypted = @"";
 NSString *ziped = @"";
 NSString *status = @"";
 NSString *ConnectionID = @"";
 NSString *operationID = @"";

//+ (Byte*) encode:(NSDictionary*) json{

//fix by lihh
+ (NSArray*) encode:(NSDictionary*) json{
    @autoreleasepool {
        NSString* data = [[NSString alloc]init];
        data = [json objectForKey:@"data"];
        if ([[json objectForKey:@"encrypted"] intValue]) {
            data = [self encryption:data];
        }
        NSData* byteData = [[NSData alloc]init];
        
        byteData = [data dataUsingEncoding:NSUTF8StringEncoding];
//    客户端不做压缩
//        if ([[json objectForKey:@"ziped"] intValue]) {
//            byteData = [MyZip gzipData:data length:(NSInteger *)[data length]];
//        }else{
//            byteData = [data dataUsingEncoding:NSUTF8StringEncoding];
//        }
        NSInteger len = [data length];
        Byte* buffer = (Byte*)malloc(25+len);
        buffer[0] = (Byte) 0xff & [[json objectForKey:@"replyType"] intValue];
        buffer[1] = (Byte) 0xff & [[json objectForKey:@"messageType"] intValue];
        buffer[2] = (Byte) 0xff & [[json objectForKey:@"encrypted"] intValue];
        buffer[3] = (Byte) 0xff & [[json objectForKey:@"ziped"] intValue];
        buffer[4] = (Byte) 0xff & [[json objectForKey:@"status"] intValue];
    
        long long* temp = (long long*)(buffer+5); // 存连接id，操作id
        *temp = [[json objectForKey:@"ConnectionID"] longValue];
        *temp = [self longChangeByteOrder:*temp];  // 转成大端发送
    
        temp = (long long*)(buffer+13);
        *temp = [[json objectForKey:@"operationID"] longValue];
        *temp = [self longChangeByteOrder:*temp];  // 转成大端发送
    
        int* temp2 = (int*)(buffer+21); // 存data长度
        *temp2 = [self intChangeByteOrder:len];
    
        Byte *dataByte = (Byte*)[byteData bytes];
    
        memcpy(buffer+25,dataByte,len);
        NSMutableArray* array = [[NSMutableArray alloc] init];
        for (int i = 0; i<25+len; i++) {
            [array addObject:[NSString stringWithFormat:@"%d",buffer[i]]];
        }
        free(buffer);
        return array;
    }
}

+  (void) decode: (NSMutableDictionary*)decodeData resData:(NSArray*) resData{
    if(!resData){
        return;
    }
    int dataCount = (int)[resData count];
    
    if (dataCount > 25) {
        NSUInteger dataLength = dataCount - 25;
        NSArray* msgdata = [resData subarrayWithRange: NSMakeRange(25, dataLength)];
//        Byte* bytes = [Encryption byteWithArray:resData];
//        int dataCount = (int)[array count];
        Byte* bytes = (Byte*) malloc(dataCount+1);
        for (int i=0; i<dataCount; i++) {
            bytes[i] = (Byte)[[resData objectAtIndex:i] intValue];
        }
        bytes[dataCount] = 0;
        
        long long* temp = (long long*)(bytes+5);
        long long lldConnectionID = [self longChangeByteOrder:*temp];
        
        long long* temp1 = (long long*)(bytes+13);
        long long lldOperationID = [self longChangeByteOrder:*temp1];
        
        int* datalen = (int*)(bytes+21);
        int dataLen= [self intChangeByteOrder:*datalen];
        [decodeData setObject:[NSNumber numberWithInt: bytes[0]] forKey:@"replyType"];
        [decodeData setObject:[NSNumber numberWithInt: bytes[1]] forKey:@"messageType"];
        [decodeData setObject:[NSNumber numberWithInt: bytes[2]] forKey:@"encrypted"];
        [decodeData setObject:[NSNumber numberWithInt: bytes[3]] forKey:@"ziped"];
        [decodeData setObject:[NSNumber numberWithInt: bytes[4]] forKey:@"status"];
        [decodeData setObject:[NSNumber numberWithLongLong: lldConnectionID] forKey:@"ConnectionID"];
        [decodeData setObject:[NSNumber numberWithLongLong: lldOperationID] forKey:@"operationID"];
        [decodeData setObject:[NSNumber numberWithInt: dataLen] forKey:@"dataLength"];
        free(bytes);
        if(dataLen == 0){
            [decodeData setObject:@"1" forKey:@"completed"];
            [decodeData setObject:@"" forKey:@"data"];
        }else{
            [decodeData setObject:[NSNumber numberWithInt: 0] forKey:@"dataIndex"];
            [self decodeData:decodeData messageData:msgdata];
        }
    }else{
        return;
    }
}

+ (void) decodeData:(NSMutableDictionary*)json messageData:(NSArray*)data
{
    int dataLength = [[json objectForKey:@"dataLength"] intValue];
    int dataIndex = [[json objectForKey:@"dataIndex"] intValue];
    int blankLength = dataLength - dataIndex;
    NSArray* dataArray  = (NSArray*)[json objectForKey:@"data"];
    int dataCount = (int)[data count];
    
    NSMutableArray *arrayOld = [NSMutableArray arrayWithArray:dataArray];
    
    if(blankLength<dataCount){
        dataCount = blankLength;
    }
    [arrayOld addObjectsFromArray:data];
    //数据接收完成
    if(dataCount == blankLength){
        //对于压缩的数据要进行解压
        int ziped = [[json objectForKey:@"ziped"] intValue];
        if(ziped){
            [json setObject:[MyZip uncompressZippedData:arrayOld] forKey:@"data"];
        }else{
//            Byte* bytes = [Encryption byteWithArray:arrayOld];
            
            int oldCount = (int)[arrayOld count];
            Byte* bytes = (Byte*) malloc(oldCount+1);
            for (int i=0; i<oldCount; i++) {
                bytes[i] = (Byte)[[arrayOld objectAtIndex:i] intValue];
            }
            bytes[oldCount] = 0;
            
            NSString *msgString = [[NSString alloc] initWithBytes:bytes length:[arrayOld count] encoding:NSASCIIStringEncoding];
            free(bytes);
            
            [json setObject:msgString forKey:@"data"];
        }
        [json setObject:@"1" forKey:@"completed"];
    }
    else {
        [json setObject:arrayOld forKey:@"data"];
        dataIndex += dataCount;
        [json setObject:[NSNumber numberWithInt: dataIndex] forKey:@"dataIndex"];
    }
}

+ (void) msgCodecDecodeData:(NSMutableDictionary*)jsons messageData:(NSArray*)data
{
    int dataLength = [[jsons objectForKey:@"dataLength"] intValue];
    int dataIndex = [[jsons objectForKey:@"dataIndex"] intValue];
    int blankLength = dataLength - dataIndex;
    NSArray* dataArray  = (NSArray*)[jsons objectForKey:@"data"];
    int dataCount = (int)[data count];
    
    NSMutableArray *arrayOld = [NSMutableArray arrayWithArray:dataArray];
    
    if(blankLength<dataCount){
        dataCount = blankLength;
    }
    [arrayOld addObjectsFromArray:data];
    //数据接收完成
    if(dataCount == blankLength){
        //对于压缩的数据要进行解压
        int ziped = [[jsons objectForKey:@"ziped"] intValue];
        if(ziped){
            [jsons setObject:[MyZip uncompressZippedData:arrayOld] forKey:@"data"];
        }else{
//            Byte* bytes = [Encryption byteWithArray:arrayOld];
            Byte* bytes = (Byte*) malloc(dataCount+1);
            for (int i=0; i<dataCount; i++) {
                bytes[i] = (Byte)[[arrayOld objectAtIndex:i] intValue];
            }
            bytes[dataCount] = 0;
            
            NSString *msgString = [[NSString alloc] initWithBytes:bytes length:([arrayOld count]+1) encoding:NSASCIIStringEncoding];
            free(bytes);
            
            [jsons setObject:msgString forKey:@"data"];
        }
        [jsons setObject:@"1" forKey:@"completed"];
    }
    else {
        [jsons setObject:arrayOld forKey:@"data"];
        dataIndex += dataCount;
        [jsons setObject:[NSNumber numberWithInt: dataIndex] forKey:@"dataIndex"];
    }
}

+ (NSString*) encryption:(NSString*) data
{
    return data;
}
+ (NSString*) decryption:(NSString*) data
{
    return data;
}

+(NSData*) String2Data:(NSString*) stringData{
    NSData* data = [stringData dataUsingEncoding: NSUTF8StringEncoding];
    return data;
}

+(NSString*) Data2String:(NSData*)data{
    NSString *stringData = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    return stringData;
}

//此函数用于将Byte*转成NSArray，具体字符顺序见报文。
+ (NSArray*) Byte2Array:(Byte*) bytebuffer{
    @autoreleasepool {
        NSMutableArray* array = [[NSMutableArray alloc] init];
        if (!bytebuffer) {
            return nil;
        }
        [array addObject:[NSString stringWithFormat:@"%d",bytebuffer[0]]];
        [array addObject:[NSString stringWithFormat:@"%d",bytebuffer[1]]];
        [array addObject:[NSString stringWithFormat:@"%d",bytebuffer[2]]];
        [array addObject:[NSString stringWithFormat:@"%d",bytebuffer[3]]];
        [array addObject:[NSString stringWithFormat:@"%d",bytebuffer[4]]];
        double* temp = (double*)(bytebuffer+5);
        [array addObject:[NSString stringWithFormat:@"%.0lf",*temp]];
        double* temp1 = (double*)(bytebuffer+13);
        [array addObject:[NSString stringWithFormat:@"%.0lf",*temp1]];
        int* temp2 = (int*)(bytebuffer+21);
        [array addObject:[NSString stringWithFormat:@"%d",*temp2]];
        [array addObject:[NSString stringWithFormat:@"%s",bytebuffer+25]];
        
        return array;
    }
}

// 解决网络传输大小端问题，调换高低字节顺序
+ (int) intChangeByteOrder:(int) num{
    Byte temp[4] = {0};
    temp[0] = (Byte)((num >> 24) & 0xff);
    temp[1] = (Byte)((num >> 16) & 0xff);
    temp[2] = (Byte)((num >> 8) & 0xff);
    temp[3] = (Byte)(num & 0xff);
    int ret = 0;
    memcpy(&ret,temp,4);
    return ret;
}


// 解决网络传输大小端问题，调换高低字节顺序
+ (long long) longChangeByteOrder:(long long) num{
    Byte temp[8] = {0};
    temp[0] = (Byte)((num >> 56) & 0xff);
    temp[1] = (Byte)((num >> 48) & 0xff);
    temp[2] = (Byte)((num >> 40) & 0xff);
    temp[3] = (Byte)((num >> 32) & 0xff);
    temp[4] = (Byte)((num >> 24) & 0xff);
    temp[5] = (Byte)((num >> 16) & 0xff);
    temp[6] = (Byte)((num >> 8) & 0xff);
    temp[7] = (Byte)(num & 0xff);
    long long ret = 0;
    memcpy(&ret,temp,8);
    return ret;
}

@end