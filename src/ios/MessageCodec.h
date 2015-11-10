//
//  MessageCodec.h
//  BppClient
//
//  Created by bossbolo on 15/2/9.
//
//

#import <Foundation/Foundation.h>
#import <Cordova/CDVPlugin.h>

#ifndef PowerBClient_MessageCodec_h
#define PowerBClient_MessageCodec_h

@interface MessageCodec : NSObject
{
    NSString* urlPath;
    NSString* filePath;
//    BOOL dataEnd;
//    Byte* dataByte;
    int dataLen;
}

//@public
-(MessageCodec*) init;


//+ (Byte*) encode:(NSDictionary*) json;
//+ (NSDictionary*) decode:(Byte*) bytes;

//fix by lihh
+ (NSArray*) encode:(NSDictionary*) json;
+ (void) decode: (NSMutableDictionary*)decodeData resData:(NSArray*) resData;
+ (void) decodeData:(NSMutableDictionary*)json messageData:(NSArray*)data;
//+ (NSMutableDictionary*) decode:(NSArray*) bytes;
//+ (NSMutableDictionary*) decodeData:(NSMutableDictionary*)json messageData:(NSArray*)data;
+ (void) msgCodecDecodeData:(NSMutableDictionary*)json messageData:(NSArray*)data;
+ (NSArray*) Byte2Array:(Byte*) bytebuffer;
//+ (Byte*) Array2Byte:(NSArray*) array;

+ (NSString*) encryption:(NSString*) data;
+ (NSString*) decryption:(NSString*) data;

+(NSData*) String2Data:(NSString*) stringData;
+(NSString*) Data2String:(NSData*)data;

+ (int) intChangeByteOrder:(int) num;
+ (long long) longChangeByteOrder:(long long) num;

@end



#endif
