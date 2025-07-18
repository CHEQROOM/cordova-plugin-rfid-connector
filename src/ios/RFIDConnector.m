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
    // Get scanner type from command or use default
    NSString *deviceType = [command.arguments objectAtIndex:0];
    if (!deviceType) {
        deviceType = @"TSL"; // Default
    }
    
    id<ScannerDevice> scanner = [ScannerDeviceFactory getInstance:deviceType];
    if (scanner) {
        [scanner getDeviceList:command commandDelegate:self.commandDelegate];
    } else {
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Unsupported scanner type"];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }
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
