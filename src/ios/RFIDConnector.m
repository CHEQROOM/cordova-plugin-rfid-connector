/********* RFIDConnector.m Cordova Plugin Implementation *******/

#import <Cordova/CDV.h>
#import "ScannerDevice.h"
#import "ScannerDeviceFactory.h"
#import "ScannerDeviceInfo.h"

@interface RFIDConnector : CDVPlugin {
    DeviceBrand *deviceBrand;
    id<ScannerDevice> currentScanner;
}

@end

@implementation RFIDConnector

- (void)getDeviceList:(CDVInvokedUrlCommand*)command {
    [self.commandDelegate runInBackground:^{
        NSArray<NSNumber *> *supportedDeviceBrands = @[
            @(DeviceBrandZebra),
            @(DeviceBrandTSL)
        ];
        NSMutableArray *allDevices = [NSMutableArray array];

        for (NSNumber *supportedDeviceBrand in supportedDeviceBrands) {
            DeviceBrand deviceBrand = DeviceBrandFromString([supportedDeviceBrand stringValue]);

            id<ScannerDevice> scanner = [ScannerDeviceFactory getInstance:deviceBrand deviceType:DeviceTypeRFID];
            if (scanner) {
                NSArray *devices = [scanner getDeviceList];
                [allDevices addObjectsFromArray:[devices valueForKey:@"toDictionary"]];
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
    [self.commandDelegate runInBackground:^{
        deviceBrand = DeviceBrandFromString([command.arguments objectAtIndex:0]);
        NSString *deviceName = [command.arguments objectAtIndex:1];
        DeviceType *deviceType = DeviceTypeFromString([command.arguments objectAtIndex:2]);

        CDVPluginResult* pluginResult = nil;
        if (deviceName == nil || [deviceName length] == 0) {
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Device name is empty"];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
            return;
        }

        currentScanner = [ScannerDeviceFactory getInstance:deviceBrand deviceType:DeviceTypeRFID];
        if(currentScanner == nil){
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Unsupported scanner type"];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        }

        ScannerConnectionStatus status = [currentScanner connect:deviceName];
        if(status == ScannerConnectionStatusSuccess){
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
        } else {
            NSString* errorMsg = @"";
            switch(status){
                case ScannerConnectionStatusAlreadyConnected:
                    errorMsg = @"Device is already connected.";
                    break;
                case ScannerConnectionStatusNotFound:
                    errorMsg = @"Device not found.";
                    break;
                case ScannerConnectionStatusNotRecognized:
                    errorMsg = @"Not a recognized device";
                    break;
                default:
                    errorMsg = @"Failed to connect to device";
                    break;
            }
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:errorMsg];
        }
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }];
}

- (void)isConnected:(CDVInvokedUrlCommand*)command {
    [self.commandDelegate runInBackground:^{
        CDVPluginResult* pluginResult = nil;
        if (currentScanner) {
            BOOL isConnected = [currentScanner isConnected];
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:isConnected ? @"true" : @"false"];
        } else {
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"No scanner connected"];
        }

        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }];
}

- (void)disconnect:(CDVInvokedUrlCommand*)command {
    [self.commandDelegate runInBackground:^{
        CDVPluginResult* pluginResult = nil;

        if (currentScanner && [currentScanner isConnected]) {
            BOOL isDisconnected = [currentScanner disconnect];
            currentScanner = nil;
            if(isDisconnected){
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
            }else{
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Unable to disconnect"];
            }            
        } else {
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"No scanner connected"];
        }
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }];
}

- (void)getDeviceInfo:(CDVInvokedUrlCommand*)command {
    [self.commandDelegate runInBackground:^{
        CDVPluginResult* pluginResult = nil;

        if (currentScanner && [currentScanner isConnected]) {
            ScannerDeviceInfo *deviceInfo = [currentScanner getDeviceInfo];

            if(deviceInfo != nil){
                NSError *error = nil;
                NSString *status = @"true";
                NSString *errorMsg = @"";
                NSData *json = nil;
                NSString *jsonMsg = nil;
                NSDictionary *dict = @{@"data" : [deviceInfo toDictionary], @"errorMsg": errorMsg, @"status" : status};
                if ([NSJSONSerialization isValidJSONObject:dict]) {
                    json = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:&error];
                    if (json != nil && error == nil) {
                        jsonMsg = [[NSString alloc] initWithData:json encoding:NSUTF8StringEncoding];
                    }
                }
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:jsonMsg];
            }else{
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Unable to get device info"];
            }
        } else {
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"No scanner connected"];
            
        }
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }];
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

- (void)getPairingBarcode:(CDVInvokedUrlCommand*)command {
    dispatch_async(dispatch_get_main_queue(), ^{
        id<ScannerDevice> scanner = [ScannerDeviceFactory getInstance:@"ZEBRA" deviceType:DeviceTypeBarcode];
        NSString *base64String = [currentScanner getPairingBarcode];
    
        [self.commandDelegate runInBackground:^{
            CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:base64String];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        }];
    });
}

@end
