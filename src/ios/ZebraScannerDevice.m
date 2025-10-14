//
//  ZebraScannerDevice.m
//  RFIDConnector
//
//  Created by Zebra Scanner Device implementation
//
#import <ZebraRfidSdkFramework/ZebraRfidSdkFramework.h>
#import <ZebraScannerFramework/ZebraScannerFramework.h>
#import "ZebraScannerDevice.h"
#import "ScannerDeviceInfo.h"
#import <Cordova/CDV.h>
#import <UIKit/UIKit.h>

@implementation ZebraScannerDevice
- (instancetype)init {
    self = [super init];
    if (self) {
        [self setupRfidSdk];
        [self setupBarcodeSdk];

        self.connectedReaderId = nil;
        self.availableRFIDReaderList = [NSMutableArray array];
    }
    return self;
}

#pragma mark - RFID Setup
- (void)setupRfidSdk {
    self.rfidApi = [srfidSdkFactory createRfidSdkApiInstance];
    [self.rfidApi srfidSetDelegate:self];
    
    [self.rfidApi srfidSetOperationalMode:SRFID_OPMODE_ALL];
    [self.rfidApi srfidSubsribeForEvents:(SRFID_EVENT_READER_APPEARANCE |
                                          SRFID_EVENT_READER_DISAPPEARANCE |
                                          SRFID_EVENT_SESSION_ESTABLISHMENT |
                                          SRFID_EVENT_SESSION_TERMINATION)];
    [self.rfidApi srfidEnableAvailableReadersDetection:YES];
    [self.rfidApi srfidEnableAutomaticSessionReestablishment:YES];
}

#pragma mark - Barcode Setup
- (void)setupBarcodeSdk {
    self.barcodeApi = [SbtSdkFactory createSbtSdkApiInstance];
    [self.barcodeApi sbtSetDelegate:self];
    
    [self.barcodeApi sbtSetOperationalMode:SBT_OPMODE_ALL];
    [self.barcodeApi sbtSubsribeForEvents:(SBT_EVENT_SCANNER_APPEARANCE |
                                           SBT_EVENT_SCANNER_DISAPPEARANCE |
                                           SBT_EVENT_BARCODE)];
}


- (NSArray<ScannerDeviceInfo *> *)getDeviceList {
    NSMutableArray<ScannerDeviceInfo *> *deviceList = [NSMutableArray array];
    NSMutableSet<NSString *> *uniqueDeviceIds = [NSMutableSet set];

    // --- RFID Readers ---
    NSMutableArray *availableRFID = [NSMutableArray array];
    NSMutableArray *activeRFID = [NSMutableArray array];
    [self.rfidApi srfidGetAvailableReadersList:&availableRFID];
    [self.rfidApi srfidGetActiveReadersList:&activeRFID];
    
    NSArray *allRFID = [availableRFID arrayByAddingObjectsFromArray:activeRFID];
    for (srfidReaderInfo *reader in allRFID) {
        NSString *deviceId = [reader getReaderName]; 
        if (![uniqueDeviceIds containsObject:deviceId]) {
            ScannerDeviceInfo *scanner = [[ScannerDeviceInfo alloc] initWithName:deviceId
                                                                           brand:ScannerBrandZebra
                                                                            type:ScannerTypeRFID];
            [deviceList addObject:scanner];
            [uniqueDeviceIds addObject:deviceId];
        }
    }


    // --- Barcode Scanners ---
    NSMutableArray *availableScanners = [[NSMutableArray alloc] init];
    NSMutableArray *activeScanners = [[NSMutableArray alloc] init];
    [self.barcodeApi sbtGetAvailableScannersList:&availableScanners];
    [self.barcodeApi sbtGetActiveScannersList:&activeScanners];

    NSArray *allBarcode = [availableRFID arrayByAddingObjectsFromArray:activeRFID];
    for (SbtScannerInfo *device in allBarcode) {
        NSString *deviceId = [device getScannerName];
        if (![uniqueDeviceIds containsObject:deviceId]) {
            ScannerDeviceInfo *scanner = [[ScannerDeviceInfo alloc] initWithName:deviceId
                                                                           brand:ScannerBrandZebra
                                                                            type:ScannerTypeBarcode];
            [deviceList addObject:scanner];
            [uniqueDeviceIds addObject:deviceId];
        }
    }
    
    return [allBarcode copy];
}
- (ScannerConnectionStatus *)connect:(NSString *) name {
    int readerID = [self getReaderIdByName: name];
    if (readerID == -1) {
        return ScannerConnectionStatusNotFound;
    }else if(self.connectedReaderId == readerID){
        return ScannerConnectionStatusAlreadyConnected;
    }else if(self.connectedReaderId != readerID){
        [self disconnect];
    }

    SRFID_RESULT conn_result = [self.rfidApi srfidEstablishCommunicationSession:readerID];
    if (SRFID_RESULT_SUCCESS != conn_result){
        return ScannerConnectionStatusError;
    }

    return ScannerConnectionStatusSuccess;
}
- (BOOL)disconnect {
    if(self.connectedReaderId == nil){
        return false;
    }

    SRFID_RESULT result = [self.rfidApi srfidTerminateCommunicationSession:self.connectedReaderId];
    return result == SRFID_RESULT_SUCCESS;
}


- (void)getDeviceInfo:(CDVInvokedUrlCommand *)command commandDelegate:(NSObject<CDVCommandDelegate> *)delegate {}
- (BOOL)isConnected:(NSString *) name {
    return self.connectedReaderId != nil;    
 }
- (void)scanRFIDs:(CDVInvokedUrlCommand *)command commandDelegate:(NSObject<CDVCommandDelegate> *)delegate { }
- (void)search:(CDVInvokedUrlCommand *)command commandDelegate:(NSObject<CDVCommandDelegate> *)delegate { }
- (void)setOutputPower:(CDVInvokedUrlCommand *)command commandDelegate:(NSObject<CDVCommandDelegate> *)delegate { }
- (void)startSearch:(CDVInvokedUrlCommand *)command commandDelegate:(NSObject<CDVCommandDelegate> *)delegate { }
- (void)stopSearch:(CDVInvokedUrlCommand *)command commandDelegate:(NSObject<CDVCommandDelegate> *)delegate { }
- (void)subscribeScanner:(CDVInvokedUrlCommand *)command commandDelegate:(NSObject<CDVCommandDelegate> *)delegate { }
- (void)unsubscribeScanner:(CDVInvokedUrlCommand *)command commandDelegate:(NSObject<CDVCommandDelegate> *)delegate { }


- (int)getReaderIdByName:(NSString *)name {
    if (self.availableRFIDReaderList.count == 0) {
        [self getDeviceList];
    }

    for (srfidReaderInfo *reader in self.availableRFIDReaderList) {
        if ([[reader getReaderName] isEqualToString:name]) {
            return [reader getReaderID];
        }
    }

    return -1;
}

- (NSString)getPairingBarcode {
    // Get the barcode from Zebra SDK
    UIImage *barcodeImage = [self.barcodeApi sbtGetPairingBarcode:BARCODE_TYPE_BTLE];

    // Convert to PNG data
    NSData *imageData = UIImagePNGRepresentation(barcodeImage);
    
    // Encode to Base64 string
    NSString *base64String = [imageData base64EncodedStringWithOptions:0];

    return base64String
}


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
    NSLog(@"Rfid Reader connected");
    self.connectedReaderId = [activeReader getReaderID];
}
- (void)srfidEventCommunicationSessionTerminated:(int)readerID { 
    NSLog(@"Rfid Reader disconnected");
    self.connectedReaderId = nil;
}
- (void)srfidEventConnectedInterfaceNotity:(int)readerID aConnectedInterfaceEvent:(sfidConnectedInterfaceEvent *)connectedInterfaceEvent { }
- (void)srfidEventIOTSatusNotity:(int)readerID aIOTStatusEvent:(srfidIOTStatusEvent *)iotStatusEvent { }
- (void)srfidEventMultiProximityNotify:(int)readerID aTagData:(srfidTagData *)tagData { }
- (void)srfidEventProximityNotify:(int)readerID aProximityPercent:(int)proximityPercent { }
- (void)srfidEventReadNotify:(int)readerID aTagData:(srfidTagData *)tagData { 
     NSLog(@"Rfid read tag");
}
- (void)srfidEventStatusNotify:(int)readerID aEvent:(SRFID_EVENT_STATUS)event aNotification:(id)notificationData { }
- (void)srfidEventTriggerNotify:(int)readerID aTriggerEvent:(SRFID_TRIGGEREVENT)triggerEvent { }
- (void)srfidEventWifiScan:(int)readerID wlanSCanObject:(srfidWlanScanList *)wlanScanObject { }


- (void)sbtEventCommunicationSessionEstablished:(SbtScannerInfo*)activeScanner {
     NSLog(@"Barcode Reader connected");
};
- (void)sbtEventCommunicationSessionTerminated:(int)scannerID {
     NSLog(@"Barcode Reader disconnected");
};
- (void)sbtEventScannerAppeared:(SbtScannerInfo*)availableScanner {
    NSLog(@"Barcode Reader appeared");
};
- (void)sbtEventScannerDisappeared:(int)scannerID {
    NSLog(@"Barcode Reader dissapeared");
};
- (void)sbtEventBarcode:(NSString*)barcodeData barcodeType:(int)barcodeType fromScanner:(int)scannerID {
    NSLog(@"Barcode scanned %@", barcodeData);
};
@end

