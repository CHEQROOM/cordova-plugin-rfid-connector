/********* RFIDConnector.m Cordova Plugin Implementation *******/

#import <Cordova/CDV.h>
#import "ScannerDevice.h"
#import "ScannerDeviceFactory.h"

@interface RFIDConnector : CDVPlugin {
    NSString *scannerType;
    id<ScannerDevice> currentScanner;
}

@end

@implementation RFIDConnector

- (void)getDeviceList:(CDVInvokedUrlCommand*)command {
    [self.commandDelegate runInBackground:^{
        NSArray *supportedTypes = @[@"TSL", @"ZEBRA"];
        NSMutableArray *allDevices = [NSMutableArray array];

        for (NSString *type in supportedTypes) {
            id<ScannerDevice> scanner = [ScannerDeviceFactory getInstance:type];
            if (scanner) {
                NSArray *devices = [scanner getDeviceList];
                for (NSDictionary *device in devices) {
                    NSMutableDictionary *deviceWithType = [device mutableCopy];
                    deviceWithType[@"deviceType"] = type;
                    [allDevices addObject:deviceWithType];
                }
            }
        }

        NSError *error = nil;
        NSString *status = @"true";
        NSString *errorMsg = @"";
        NSData *json = nil;
        NSString *jsonMsg = nil;
        if (!allDevices || !allDevices.count) {
            status = @"false";
            errorMsg = @"Bluetooth connection is not enabled or device is not paired.";
        }
        NSDictionary *dict = @{@"data" : allDevices, @"errorMsg" : errorMsg, @"status" : status};
        if ([NSJSONSerialization isValidJSONObject:dict]) {
            json = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:&error];
            if (json != nil && error == nil) {
                jsonMsg = [[NSString alloc] initWithData:json encoding:NSUTF8StringEncoding];
            }
        }

        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:jsonMsg];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }];
}

- (void)connect:(CDVInvokedUrlCommand*)command {
    scannerType = [command.arguments objectAtIndex:0];
    currentScanner = [ScannerDeviceFactory getInstance:scannerType];
    
    if (currentScanner) {
        [currentScanner connect:command commandDelegate:self.commandDelegate];
    } else {
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Unsupported scanner type"];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }
}

- (void)isConnected:(CDVInvokedUrlCommand*)command {
    if (currentScanner) {
        [currentScanner isConnected:command commandDelegate:self.commandDelegate];
    } else {
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"No scanner connected"];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }
}

- (void)disconnect:(CDVInvokedUrlCommand*)command {
    if (currentScanner) {
        [currentScanner disconnect:command commandDelegate:self.commandDelegate];
        currentScanner = nil;
    } else {
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"No scanner connected"];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }
}

- (void)getDeviceInfo:(CDVInvokedUrlCommand*)command {
    if (currentScanner) {
        [currentScanner getDeviceInfo:command commandDelegate:self.commandDelegate];
    } else {
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"No scanner connected"];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }
}

- (void)scanRFIDs:(CDVInvokedUrlCommand*)command {
    if (currentScanner) {
        [currentScanner scanRFIDs:command commandDelegate:self.commandDelegate];
    } else {
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"No scanner connected"];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }
}

- (void)search:(CDVInvokedUrlCommand*)command {
    if (currentScanner) {
        [currentScanner search:command commandDelegate:self.commandDelegate];
    } else {
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"No scanner connected"];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }
}

- (void)setOutputPower:(CDVInvokedUrlCommand*)command {
    if (currentScanner) {
        [currentScanner setOutputPower:command commandDelegate:self.commandDelegate];
    } else {
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"No scanner connected"];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }
}

- (void)subscribeScanner:(CDVInvokedUrlCommand*)command {
    if (currentScanner) {
        [currentScanner subscribeScanner:command commandDelegate:self.commandDelegate];
    } else {
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"No scanner connected"];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }
}

- (void)unsubscribeScanner:(CDVInvokedUrlCommand*)command {
    if (currentScanner) {
        [currentScanner unsubscribeScanner:command commandDelegate:self.commandDelegate];
    } else {
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"No scanner connected"];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }
}

- (void)startSearch:(CDVInvokedUrlCommand*)command {
    if (currentScanner) {
        [currentScanner startSearch:command commandDelegate:self.commandDelegate];
    } else {
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"No scanner connected"];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }
}

- (void)stopSearch:(CDVInvokedUrlCommand*)command {
    if (currentScanner) {
        [currentScanner stopSearch:command commandDelegate:self.commandDelegate];
    } else {
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"No scanner connected"];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }
}

@end
