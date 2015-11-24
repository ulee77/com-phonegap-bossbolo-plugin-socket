#import <Cordova/CDV.h>

@interface BoloSocket : CDVPlugin {
    NSMutableDictionary *socketAdapters;
}

-(void) open: (CDVInvokedUrlCommand *) command;
-(void) write: (CDVInvokedUrlCommand *) command;
-(void) close: (CDVInvokedUrlCommand *) command;
-(void) setOptions: (CDVInvokedUrlCommand *) command;
//-(void) exitApp: (CDVInvokedUrlCommand *) command;
//+(void) dispatchEventWithDictionaryOpen:(NSDictionary*) dictionary;

@end