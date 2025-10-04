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
        [self.api srfidSetDelegate:self];

        self.availableRFIDReaderList = [NSMutableArray array];
        
        
        
        [self.api srfidSetOperationalMode:SRFID_OPMODE_MFI];
        [self.api srfidSubsribeForEvents: (SRFID_EVENT_READER_APPEARANCE |
                                      SRFID_EVENT_READER_DISAPPEARANCE |
                                      SRFID_EVENT_SESSION_ESTABLISHMENT |
                                      SRFID_EVENT_SESSION_TERMINATION)];
        [self.api srfidEnableAvailableReadersDetection:YES];
        [self.api srfidEnableAutomaticSessionReestablishment:YES];
        
    }
    return self;
}

- (void)getDeviceList:(CDVInvokedUrlCommand*)command commandDelegate:(NSObject<CDVCommandDelegate>*)delegate {
    CDVPluginResult* pluginResult = nil;
    if (command != nil) {
        /* allocate an array for storage of list of available RFID readers */
        NSMutableArray *available_readers = [[NSMutableArray alloc] init];

        /* allocate an array for storage of list of active RFID readers */
        NSMutableArray *active_readers = [[NSMutableArray alloc] init];

        [self.api srfidGetAvailableReadersList:&available_readers];
        [self.api srfidGetActiveReadersList:&active_readers];
        
        [self.availableRFIDReaderList removeAllObjects];
        [self.availableRFIDReaderList addObjectsFromArray:available_readers];
        [self.availableRFIDReaderList addObjectsFromArray:active_readers];
        
        NSMutableArray *dataArray = [[NSMutableArray alloc] init];
        NSMutableDictionary *readerObj = nil;
        for (srfidReaderInfo *reader in self.availableRFIDReaderList) {
            readerObj = [[NSMutableDictionary alloc] init];
            [readerObj setObject:[reader getReaderName] forKey:@"name"];
            //[readerObj setObject:[reader getReaderID] forKey:@"deviceID"];
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
- (void)connect:(CDVInvokedUrlCommand *)command commandDelegate:(NSObject<CDVCommandDelegate> *)delegate {}
- (void)disconnect:(CDVInvokedUrlCommand *)command commandDelegate:(NSObject<CDVCommandDelegate> *)delegate {}
- (void)getDeviceInfo:(CDVInvokedUrlCommand *)command commandDelegate:(NSObject<CDVCommandDelegate> *)delegate {}
- (void)isConnected:(CDVInvokedUrlCommand *)command commandDelegate:(NSObject<CDVCommandDelegate> *)delegate { }
- (void)scanRFIDs:(CDVInvokedUrlCommand *)command commandDelegate:(NSObject<CDVCommandDelegate> *)delegate { }
- (void)search:(CDVInvokedUrlCommand *)command commandDelegate:(NSObject<CDVCommandDelegate> *)delegate { }
- (void)setOutputPower:(CDVInvokedUrlCommand *)command commandDelegate:(NSObject<CDVCommandDelegate> *)delegate { }
- (void)startSearch:(CDVInvokedUrlCommand *)command commandDelegate:(NSObject<CDVCommandDelegate> *)delegate { }
- (void)stopSearch:(CDVInvokedUrlCommand *)command commandDelegate:(NSObject<CDVCommandDelegate> *)delegate { }
- (void)subscribeScanner:(CDVInvokedUrlCommand *)command commandDelegate:(NSObject<CDVCommandDelegate> *)delegate { }
- (void)unsubscribeScanner:(CDVInvokedUrlCommand *)command commandDelegate:(NSObject<CDVCommandDelegate> *)delegate { }

-(void)srfidEventReaderAppeared:(srfidReaderInfo*)availableReader {
    /* print the information about RFID reader represented by srfidReaderInfo
     object */
    NSLog(@"RFID reader has appeared: ID = %d name = %@\n", [availableReader getReaderID],
          [availableReader getReaderName]);
}
-(void)srfidEventReaderDisappeared:(int)readerID {
    NSLog(@"RFID reader has disappeared: ID = %d\n", readerID);
}
- (void)srfidEventBatteryNotity:(int)readerID aBatteryEvent:(srfidBatteryEvent *)batteryEvent { }
- (void)srfidEventCommunicationSessionEstablished:(srfidReaderInfo *)activeReader { 
    NSLog(@"Reader connected");
}
- (void)srfidEventCommunicationSessionTerminated:(int)readerID { 
    NSLog(@"Reader disconnected");
}
- (void)srfidEventConnectedInterfaceNotity:(int)readerID aConnectedInterfaceEvent:(sfidConnectedInterfaceEvent *)connectedInterfaceEvent { }
- (void)srfidEventIOTSatusNotity:(int)readerID aIOTStatusEvent:(srfidIOTStatusEvent *)iotStatusEvent { }
- (void)srfidEventMultiProximityNotify:(int)readerID aTagData:(srfidTagData *)tagData { }
- (void)srfidEventProximityNotify:(int)readerID aProximityPercent:(int)proximityPercent { }
- (void)srfidEventReadNotify:(int)readerID aTagData:(srfidTagData *)tagData { }
- (void)srfidEventStatusNotify:(int)readerID aEvent:(SRFID_EVENT_STATUS)event aNotification:(id)notificationData { }
- (void)srfidEventTriggerNotify:(int)readerID aTriggerEvent:(SRFID_TRIGGEREVENT)triggerEvent { }
- (void)srfidEventWifiScan:(int)readerID wlanSCanObject:(srfidWlanScanList *)wlanScanObject { }
@end

