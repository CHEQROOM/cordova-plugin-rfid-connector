//
//  ZebraScannerDevice.m
//  RFIDConnector
//
//  Created by Zebra Scanner Device implementation
//

#import "ZebraScannerDevice.h"
#import <Cordova/CDV.h>

@implementation ZebraScannerDevice

- (void)connect:(CDVInvokedUrlCommand*)command commandDelegate:(NSObject<CDVCommandDelegate>*)delegate {
    CDVPluginResult* pluginResult = nil;
    NSString* deviceName = [command.arguments objectAtIndex:1];
    
    if (deviceName != nil && [deviceName length] > 0) {
        // Initialize Zebra SDK
        self.sdkApi = [SbtSdkFactory createSbtSdkApiInstance];
        [self.sdkApi sbtSetDelegate:self];
        
        // Connect to device
        SbtScannerInfo *scannerInfo = [[SbtScannerInfo alloc] init];
        scannerInfo.scannerName = deviceName;
        
        if ([self.sdkApi sbtConnect:scannerInfo]) {
            self.connectedScanner = scannerInfo;
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"Connected"];
        } else {
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Failed to connect"];
        }
    } else {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Invalid device name"];
    }
    
    [delegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)isConnected:(CDVInvokedUrlCommand*)command commandDelegate:(NSObject<CDVCommandDelegate>*)delegate {
    CDVPluginResult* pluginResult = nil;
    NSString* echo = @"false";
    
    if (self.connectedScanner && [self.sdkApi sbtIsConnected:self.connectedScanner]) {
        echo = @"true";
    }
    
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:echo];
    [delegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)disconnect:(CDVInvokedUrlCommand*)command commandDelegate:(NSObject<CDVCommandDelegate>*)delegate {
    CDVPluginResult* pluginResult = nil;
    NSString* disconnectMsg = @"false";
    
    if (self.connectedScanner) {
        [self.sdkApi sbtDisconnect:self.connectedScanner];
        self.connectedScanner = nil;
        disconnectMsg = @"true";
    }
    
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:disconnectMsg];
    [delegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)getDeviceList:(CDVInvokedUrlCommand*)command commandDelegate:(NSObject<CDVCommandDelegate>*)delegate {
    CDVPluginResult* pluginResult = nil;
    
    // Get available Zebra scanners
    NSArray *scanners = [self.sdkApi sbtGetAvailableScannersList];
    NSMutableArray *dataArray = [[NSMutableArray alloc] init];
    
    for (SbtScannerInfo *scanner in scanners) {
        NSMutableDictionary *scannerInfo = [[NSMutableDictionary alloc] init];
        [scannerInfo setObject:scanner.scannerName forKey:@"name"];
        [scannerInfo setObject:scanner.scannerID forKey:@"deviceID"];
        [dataArray addObject:scannerInfo];
    }
    
    NSError *error = nil;
    NSString *status = @"true";
    NSString *errorMsg = @"";
    NSData *json = nil;
    NSString *jsonMsg = nil;
    
    if (!dataArray || !dataArray.count) {
        status = @"false";
        errorMsg = @"No Zebra scanners found";
    }
    
    NSDictionary *dict = @{@"data" : dataArray, @"errorMsg" : errorMsg, @"status" : status};
    if ([NSJSONSerialization isValidJSONObject:dict]) {
        json = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:&error];
        if (json != nil && error == nil) {
            jsonMsg = [[NSString alloc] initWithData:json encoding:NSUTF8StringEncoding];
        }
    }
    
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:jsonMsg];
    [delegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)getDeviceInfo:(CDVInvokedUrlCommand*)command commandDelegate:(NSObject<CDVCommandDelegate>*)delegate {
    CDVPluginResult* pluginResult = nil;
    
    if (self.connectedScanner) {
        NSMutableDictionary *infoString = [[NSMutableDictionary alloc] init];
        [infoString setObject:self.connectedScanner.scannerName forKey:@"deviceName"];
        [infoString setObject:@"n/a" forKey:@"batteryLevel"];
        [infoString setObject:@"n/a" forKey:@"batteryStatus"];
        [infoString setObject:@"n/a" forKey:@"hardwareVersion"];
        [infoString setObject:@"n/a" forKey:@"firmwareVersion"];
        [infoString setObject:@"Zebra" forKey:@"manufacturer"];
        [infoString setObject:self.connectedScanner.scannerID forKey:@"serialNumber"];
        [infoString setObject:[NSNumber numberWithInt:0] forKey:@"antennaMin"];
        [infoString setObject:[NSNumber numberWithInt:30] forKey:@"antennaMax"];
        [infoString setObject:[NSNumber numberWithInt:self.scanPower] forKey:@"pScanPower"];
        [infoString setObject:[NSNumber numberWithInt:self.scanPower] forKey:@"dScanPower"];
        
        NSError *error = nil;
        NSString *status = @"true";
        NSString *errorMsg = @"";
        NSData *json = nil;
        NSString *jsonMsg = nil;
        
        NSDictionary *dict = @{@"data" : infoString, @"errorMsg" : errorMsg, @"status" : status};
        if ([NSJSONSerialization isValidJSONObject:dict]) {
            json = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:&error];
            if (json != nil && error == nil) {
                jsonMsg = [[NSString alloc] initWithData:json encoding:NSUTF8StringEncoding];
            }
        }
        
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:jsonMsg];
    } else {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Device not connected"];
    }
    
    [delegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)scanRFIDs:(CDVInvokedUrlCommand*)command commandDelegate:(NSObject<CDVCommandDelegate>*)delegate {
    // Zebra implementation for RFID scanning
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Zebra RFID scanning not implemented"];
    [delegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)search:(CDVInvokedUrlCommand*)command commandDelegate:(NSObject<CDVCommandDelegate>*)delegate {
    // Zebra implementation for tag search
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Zebra tag search not implemented"];
    [delegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)setOutputPower:(CDVInvokedUrlCommand*)command commandDelegate:(NSObject<CDVCommandDelegate>*)delegate {
    CDVPluginResult* pluginResult = nil;
    NSInteger newPower = [[command.arguments objectAtIndex:0] intValue];
    
    if (newPower >= 0 && newPower <= 30) {
        self.scanPower = newPower;
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"Power set"];
    } else {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Invalid power level"];
    }
    
    [delegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)subscribeScanner:(CDVInvokedUrlCommand*)command commandDelegate:(NSObject<CDVCommandDelegate>*)delegate {
    // Zebra implementation for scanner subscription
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Zebra subscription not implemented"];
    [delegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)unsubscribeScanner:(CDVInvokedUrlCommand*)command commandDelegate:(NSObject<CDVCommandDelegate>*)delegate {
    // Zebra implementation for scanner unsubscription
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Zebra unsubscription not implemented"];
    [delegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)startSearch:(CDVInvokedUrlCommand*)command commandDelegate:(NSObject<CDVCommandDelegate>*)delegate {
    // Zebra implementation for continuous search
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Zebra continuous search not implemented"];
    [delegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)stopSearch:(CDVInvokedUrlCommand*)command commandDelegate:(NSObject<CDVCommandDelegate>*)delegate {
    // Zebra implementation for stopping search
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Zebra stop search not implemented"];
    [delegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

@end 