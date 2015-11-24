#import "BoloSocket.h"
#import "SocketAdapter.h"
#import <cordova/CDV.h>
#import <Foundation/Foundation.h>
#import "MessageCodec.h"
//#import "MessageBuffer.h"
#import "BoloCustomGlobal.h"
#import "Encryption.h"

@implementation BoloSocket : CDVPlugin

- (void) open : (CDVInvokedUrlCommand*) command {
    
	NSString *socketKey = [command.arguments objectAtIndex:0];
	NSString *host = [command.arguments objectAtIndex:1];
	NSNumber *port = [command.arguments objectAtIndex:2];
    
    if (socketAdapters == nil) {
		self->socketAdapters = [[NSMutableDictionary alloc] init];
	}
    
	__block SocketAdapter* socketAdapter = [[SocketAdapter alloc] init];
    socketAdapter.openEventHandler = ^ void () {
        [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK] callbackId:command.callbackId];
        
        [self->socketAdapters setObject:socketAdapter forKey:socketKey];
        
        socketAdapter = nil;
    };
    socketAdapter.openErrorEventHandler = ^ void (NSString *error){
        [self.commandDelegate
         sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error]
         callbackId:command.callbackId];
        
        socketAdapter = nil;
    };
    socketAdapter.errorEventHandler = ^ void (NSString *error){        
        NSMutableDictionary *errorDictionaryData = [[NSMutableDictionary alloc] init];
        [errorDictionaryData setObject:@"Error" forKey:@"type"];
        [errorDictionaryData setObject:error forKey:@"errorMessage"];
        [errorDictionaryData setObject:socketKey forKey:@"socketKey"];
        
        [self dispatchEventWithDictionary:errorDictionaryData];
    };
    socketAdapter.dataConsumer = ^ void (NSArray* dataArray) {
        BoloCustomGlobal *app = [BoloCustomGlobal getInstance];
        if([app.jsonData count]==0) {
            [MessageCodec decode:app.jsonData resData:dataArray];
            if([app.jsonData count]==0){
                return;
            }
        }else {
            [MessageCodec decodeData:app.jsonData messageData:dataArray];
        }
        
        @try {
            if((BOOL)[app.jsonData objectForKey:@"completed"]){
                [app.jsonData removeObjectForKey:@"completed"];
                
                NSData *jsonData = [NSJSONSerialization dataWithJSONObject:app.jsonData options:0 error:nil];
                NSString *dataString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
                
                [app.jsonData removeAllObjects];
                
                NSMutableDictionary *dataDictionary = [[NSMutableDictionary alloc] init];
                [dataDictionary setObject:@"DataReceived" forKey:@"type"];
                [dataDictionary setObject:dataString forKey:@"data"];
                [dataDictionary setObject:socketKey forKey:@"socketKey"];
                [self dispatchEventWithDictionary:dataDictionary];
            }
        }
        @catch
        (NSException *exception) {
            NSLog(@"Caught %@%@", [exception name], [exception reason]);
        }
    };
    
    socketAdapter.closeEventHandler = ^ void (BOOL hasErrors) {
        NSMutableDictionary *closeDictionaryData = [[NSMutableDictionary alloc] init];
        [closeDictionaryData setObject:@"Close" forKey:@"type"];
        [closeDictionaryData setObject:(hasErrors == TRUE ? @"true": @"false") forKey:@"hasError"];
        [closeDictionaryData setObject:socketKey forKey:@"socketKey"];
        
        [self dispatchEventWithDictionary:closeDictionaryData];
        
        [self removeSocketAdapter:socketKey];
    };
     
    
    [self.commandDelegate runInBackground:^{
        
        @try {
            [socketAdapter open:host port:port];
        }
        @catch (NSException *e) {
            [self.commandDelegate
                sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:e.reason]
                callbackId:command.callbackId];
            
            socketAdapter = nil;
        }
    }];
}

- (void) write:(CDVInvokedUrlCommand *) command {
	
    NSString* socketKey = [command.arguments objectAtIndex:0];
    NSString *str = [command.arguments objectAtIndex:1];
    
    NSData* data = [str dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error = nil;
    NSDictionary* jsonData = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:&error];
    NSArray* buffer = [MessageCodec encode:jsonData];
    
    SocketAdapter *socket = [self getSocketAdapter:socketKey];
    if (socket == nil) {
        return;
    }
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0),
//                   ^{
//                       @try {
//                           [socket write:buffer];
//                           [self.commandDelegate
//                            sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK]
//                            callbackId:command.callbackId];
//                       }
//                       @catch (NSException *e) {
//                           [self.commandDelegate
//                            sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:e.reason]
//                            callbackId:command.callbackId];
//                       }
//                   }
//                   );
    
	[self.commandDelegate runInBackground:^{
        @try {
            [socket write:buffer];
            [self.commandDelegate
             sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK]
             callbackId:command.callbackId];
        }
        @catch (NSException *e) {
            [self.commandDelegate
             sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:e.reason]
             callbackId:command.callbackId];
        }
    }];
}

- (void) shutdownWrite:(CDVInvokedUrlCommand *) command {
    
    NSString* socketKey = [command.arguments objectAtIndex:0];
	
	SocketAdapter *socket = [self getSocketAdapter:socketKey];
    if (socket == nil) {
        return;
    }
    
    [self.commandDelegate runInBackground:^{
        @try {
            [socket shutdownWrite];
            [self.commandDelegate
            sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK]
            callbackId:command.callbackId];
        }
        @catch (NSException *e) {
            [self.commandDelegate
            sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:e.reason]
            callbackId:command.callbackId];
        }
    }];
}

- (void) close:(CDVInvokedUrlCommand *) command {
    
    NSString* socketKey = [command.arguments objectAtIndex:0];
	
	SocketAdapter *socket = [self getSocketAdapter:socketKey];
    if (socket == nil) {
        return;
    }
    
    [self.commandDelegate runInBackground:^{
        @try {
            [socket close];
            [self.commandDelegate
             sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK]
             callbackId:command.callbackId];
        }
        @catch (NSException *e) {
            [self.commandDelegate
             sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:e.reason]
             callbackId:command.callbackId];
        }
    }];
}

- (void) setOptions: (CDVInvokedUrlCommand *) command {
}

- (SocketAdapter*) getSocketAdapter: (NSString*) socketKey {
	SocketAdapter* socketAdapter = [self->socketAdapters objectForKey:socketKey];
	if (socketAdapter == nil) {
		NSString *exceptionReason = [NSString stringWithFormat:@"Cannot find socketKey: %@. Connection is probably closed.", socketKey];
        return nil;
//		@throw [NSException exceptionWithName:@"IllegalArgumentException" reason:exceptionReason userInfo:nil];
	}
	return socketAdapter;
}

- (void) removeSocketAdapter: (NSString*) socketKey {
    NSLog(@"Removing socket adapter from storage.");
    [self->socketAdapters removeObjectForKey:socketKey];
}

- (BOOL) socketAdapterExists: (NSString*) socketKey {
	SocketAdapter* socketAdapter = [self->socketAdapters objectForKey:socketKey];
	return socketAdapter != nil;
}

- (void) dispatchEventWithDictionary: (NSDictionary*) dictionary {
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dictionary options:0 error:nil];
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    
    [self dispatchEvent:jsonString];
}

- (void) dispatchEvent: (NSString *) jsonEventString {
    NSString *jsToEval = [NSString stringWithFormat : @"window.Socket.dispatchEvent(%@);", jsonEventString];
    [self.commandDelegate evalJs:jsToEval];
}

@end