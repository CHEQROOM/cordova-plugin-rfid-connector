//
//  ZebraScannerDevice.m
//  RFIDConnector
//
//  Created by Zebra Scanner Device implementation
//

#import <ZebraRfidSdkFramework/ZebraRfidSdkFramework.h>
#import <ZebraScannerFramework/ZebraScannerFramework.h>
#import "ZebraScannerDevice.h"
#import <Cordova/CDV.h>

@implementation ZebraScannerDevice

- (instancetype)init {
    self = [super init];
    if (self) {
        self.api = [srfidSdkFactory createRfidSdkApiInstance];
        self.availableRFIDReaderList = [NSMutableArray array];
        
        [self.api srfidSetOperationalMode:SRFID_OPMODE_ALL];
        [self.api srfidSubsribeForEvents: (SRFID_EVENT_READER_APPEARANCE |
                                      SRFID_EVENT_READER_DISAPPEARANCE |
                                      SRFID_EVENT_SESSION_ESTABLISHMENT |
                                      SRFID_EVENT_SESSION_TERMINATION)];
        [self.api srfidEnableAvailableReadersDetection:YES];
        [self.api srfidEnableAutomaticSessionReestablishment:YES];
        [self.api srfidSetDelegate:self];
    }
    return self;
}

- (void)getDeviceList:(CDVInvokedUrlCommand*)command commandDelegate:(NSObject<CDVCommandDelegate>*)delegate {
    CDVPluginResult* pluginResult = nil;
    if (command != nil) {
        NSMutableArray *availableReaders = [NSMutableArray arrayWithCapacity:5];
        NSMutableArray *activeReaders = [NSMutableArray arrayWithCapacity:5];
        
        [self.api srfidGetAvailableReadersList:&availableReaders];
        [self.api srfidGetActiveReadersList:&activeReaders];
        
        [self.availableRFIDReaderList removeAllObjects];
        [self.availableRFIDReaderList addObjectsFromArray:availableReaders];
        [self.availableRFIDReaderList addObjectsFromArray:activeReaders];
        
        for (srfidReaderInfo *reader in self.availableRFIDReaderList) {
            NSLog(@"Reader Name: %@", [reader getReaderName]);
            NSLog(@"Reader ID: %d", [reader getReaderID]);
        }
        
        NSMutableArray *dataArray = [[NSMutableArray alloc] init];
        NSMutableDictionary *readerObj = nil;
        for (srfidReaderInfo *reader in self.availableRFIDReaderList) {
            readerObj = [[NSMutableDictionary alloc] init];
            [readerObj setObject:obj.name forKey:@"name"];
            [readerObj setObject:obj.serialNumber forKey:@"deviceID"];
            [dataArray addObject:readerObj];
        }

        NSError *error = nil;
        NSString *status = @"true";
        NSString *errorMsg = @"";
        NSData *json = nil;
        NSString *jsonMsg = nil;
        if (!dataArray || !dataArray.count) {
            status = @"false";
            errorMsg = @"Bluetooth connection is not enabled or device is not paired.";
        }
        NSDictionary *dict = @{@"data" : dataArray, @"errorMsg" : errorMsg, @"status" : status};
        if ([NSJSONSerialization isValidJSONObject:dict]) {
            json = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:&error];
            if (json != nil && error == nil) {
                jsonMsg = [[NSString alloc] initWithData:json encoding:NSUTF8StringEncoding];
            }
        }
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:jsonMsg];
    } else {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
    }
    [delegate sendPluginResult:pluginResult callbackId:command.callbackId];
}


@end 
