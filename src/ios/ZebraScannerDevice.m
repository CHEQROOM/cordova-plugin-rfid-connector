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

        self.deviceList = [NSMutableArray array];
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

    self.connectedRfidReaderId = nil;
}

#pragma mark - Barcode Setup
- (void)setupBarcodeSdk {
    self.barcodeApi = [SbtSdkFactory createSbtSdkApiInstance];
    [self.barcodeApi sbtSetDelegate:self];
    
    [self.barcodeApi sbtSetOperationalMode:SBT_OPMODE_ALL];
    [self.barcodeApi sbtSubscribeForEvents:(SBT_EVENT_SCANNER_APPEARANCE |
                                           SBT_EVENT_SCANNER_DISAPPEARANCE |
                                           SBT_EVENT_SESSION_ESTABLISHMENT |
                                           SBT_EVENT_SESSION_TERMINATION |
                                           SBT_EVENT_BARCODE)];

    self.connectedBarcodeScannerId = nil;
}


- (NSArray<ScannerDeviceInfo *> *)getDeviceList {
    if (self.deviceList.count > 0) {
        return self.deviceList;
    }

    // --- RFID Readers ---
    NSMutableArray *availableRFID = [NSMutableArray array];
    NSMutableArray *activeRFID = [NSMutableArray array];
    [self.rfidApi srfidGetAvailableReadersList:&availableRFID];
    [self.rfidApi srfidGetActiveReadersList:&activeRFID];
    
    NSArray *allRFID = [availableRFID arrayByAddingObjectsFromArray:activeRFID];
    for (srfidReaderInfo *reader in allRFID) {
        NSString *readerName = [reader getReaderName]; 
        int readerId = [reader getReaderID];
        ScannerDeviceInfo *scanner = [[ScannerDeviceInfo alloc] initWithName:readerName
                                                                       brand:ScannerBrandZebra
                                                                        type:ScannerTypeRFID
                                                                    deviceId:readerId];
        [self.deviceList addObject:scanner];
    }


    // --- Barcode Scanners ---
    NSMutableArray *availableScanners = [[NSMutableArray alloc] init];
    NSMutableArray *activeScanners = [[NSMutableArray alloc] init];
    [self.barcodeApi sbtGetAvailableScannersList:&availableScanners];
    [self.barcodeApi sbtGetActiveScannersList:&activeScanners];

    NSArray *allScanners = [availableScanners arrayByAddingObjectsFromArray:activeScanners];
    for (SbtScannerInfo *scanner in allScanners) {
        NSString *scannerName = [barcodeScanner getScannerName];
        int scannerId = [barcodeScanner getScannerID];
        ScannerDeviceInfo *scanner = [[ScannerDeviceInfo alloc] initWithName:scannerName
                                                                       brand:ScannerBrandZebra
                                                                        type:ScannerTypeBarcode
                                                                    deviceId:scannerId];
        [self.deviceList addObject:scanner];
        
    }
    
    return [self.deviceList copy];
}
- (ScannerConnectionStatus *)connect:(NSString *) deviceId {
    ScannerDeviceInfo *deviceInfo = [self.getDeviceInfoById: deviceId];
    if (deviceInfo == nil) {
        return ScannerConnectionStatusNotFound;
    }else if(self.connectedRfidReaderId == deviceId || self.connectedBarcodeScannerId == deviceId){
        return ScannerConnectionStatusAlreadyConnected;
    }else if(self.connectedRfidReaderId != deviceId || self.connectedBarcodeScannerId == deviceId){
        [self disconnect];
    }

    if(deviceInfo.type == ScannerTypeRFID){
        SRFID_RESULT connectionResult = [self.rfidApi srfidEstablishCommunicationSession:deviceInfo.deviceId];
        if (SRFID_RESULT_SUCCESS != connectionResult){
            return ScannerConnectionStatusError;
        }
    }else{
        SBT_RESULT connectionResult =[scanInstance sbtEstablishCommunicationSession:deviceInfo.deviceId];
        if(connectionResult != SBT_RESULT_SUCCESS){
            return ScannerConnectionStatusError;
        }
    }   

    return ScannerConnectionStatusSuccess;
}
- (BOOL)disconnect {
    if(self.connectedRfidReaderId == nil && self.connectedBarcodeScannerId == nil){
        return false;
    }

    if(connectedRfidReaderId != nil){
        SRFID_RESULT rfidResult = [self.rfidApi srfidTerminateCommunicationSession:self.connectedRfidReaderId];
        if(rfidResult != SRFID_RESULT_SUCCESS){
            return false;
        }
        self.connectedRfidReaderId = nil;
    }

    if(self.connectedBarcodeScannerId != nil){
        SBT_RESULT scannerResult = [self.barcodeApi sbtTerminateCommunicationSession:self.connectedBarcodeScannerId];
        if(scannerResult != SBT_RESULT_SUCCESS){
            return false;
        }
        self.connectedBarcodeScannerId = nil;
    }  

    return true;
}


- (ScannerDeviceInfo *)getDeviceInfo {
    if(self.connectedReaderId == nil){
        return nil;
    }

    srfidBatteryStatusInfo *batteryInfo = [[srfidBatteryStatusInfo alloc] init];
    [self.rfidApi srfidGetBatteryStatus:self.connectedRfidReaderId aBatteryStatusInfo:batteryInfo];

    srfidReaderCapabilitiesInfo *capabilities = [[srfidReaderCapabilitiesInfo alloc] init];
    NSString *error_response = nil;
    
    SRFID_RESULT result = [self.rfidApi srfidGetReaderCapabilitiesInfo:[reader getReaderID] aReaderCapabilitiesInfo:&capabilities aStatusMessage:&error_response];
    if (SRFID_RESULT_SUCCESS == result) {
        ScannerDeviceInfo *deviceInfo = [self.getDeviceInfoById: deviceId];    
        deviceInfo.serialNumber = [capabilities getSerialNumber];
        deviceInfo.manufacturer = [capabilities getManufacturer];
        deviceInfo.hardwareVersion = [capabilities getAsciiVersion];
        deviceInfo.firmwareVersion = [capabilities getAirProtocolVersion];
        deviceInfo.batteryLevel = [batteryInfo getLevelInPercentage];
        deviceInfo.antennaMin = [capabilities getMinPower];
        deviceInfo.antennaMax = [capabilities getMaxPower];
        deviceInfo.pScanPower = [capabilities getMaxPower];
        deviceInfo.dScanPower = [capabilities getPowerStep];
        return deviceInfo;
    }

    return nil;
}
- (BOOL)isConnected:(NSString *) name {
    return self.connectedRfidReaderId != nil;    
 }
- (void)subscribeScanner:(CDVInvokedUrlCommand *)command commandDelegate:(NSObject<CDVCommandDelegate> *)delegate { }
- (void)unsubscribeScanner:(CDVInvokedUrlCommand *)command commandDelegate:(NSObject<CDVCommandDelegate> *)delegate { }
- (void)setOutputPower:(CDVInvokedUrlCommand *)command commandDelegate:(NSObject<CDVCommandDelegate> *)delegate { }
- (void)scanRFIDs:(CDVInvokedUrlCommand *)command commandDelegate:(NSObject<CDVCommandDelegate> *)delegate { }
- (void)search:(CDVInvokedUrlCommand *)command commandDelegate:(NSObject<CDVCommandDelegate> *)delegate { }
- (void)startSearch:(CDVInvokedUrlCommand *)command commandDelegate:(NSObject<CDVCommandDelegate> *)delegate { }
- (void)stopSearch:(CDVInvokedUrlCommand *)command commandDelegate:(NSObject<CDVCommandDelegate> *)delegate { }


- (ScannerDeviceInfo *)getDeviceInfoById:(int) deviceId {
    if (self.deviceList.count == 0) {
        [self getDeviceList];
    }

    for (ScannerDeviceInfo *deviceInfo in self.deviceList) {
        if ([deviceInfo.deviceid isEqualToString:deviceId]) {
            return [deviceInfo copy];
        }
    }

    return nil;
}

- (NSString *)getPairingBarcode {
    // Get the barcode from Zebra SDK
    UIImage *barcodeImage = [self.barcodeApi sbtGetPairingBarcode:BARCODE_TYPE_BTLE withComProtocol:STC_SSI_BLE withSetDefaultStatus:SETDEFAULT_NO withImageFrame:CGRectMake(0, 0, 300, 300)];
    
    // Convert to PNG data
    NSData *imageData = UIImagePNGRepresentation(barcodeImage);
    
    // Encode to Base64 string
    NSString *base64String = [imageData base64EncodedStringWithOptions:0];

    return base64String;
}

-(void) addDevice:(ScannerDeviceInfo *) device {
    BOOL exists = NO;
    for (ScannerDeviceInfo *info in self.deviceList) {
        if ([info.name isEqualToString:device.name]) {
            exists = YES;
            break;
        }
    }
    if (!exists) {
        [self.deviceList addObject:device];
    }
}

-(void) removeDevice:(int) deviceId {
    ScannerDeviceInfo *toRemove = nil;
    for (ScannerDeviceInfo *info in self.deviceList) {
        if (info.deviceId == deviceId) {
            toRemove = info;
            break;
        }
    }

    if (toRemove) {
        [self.deviceList removeObject:toRemove];
    }
}


-(void)srfidEventReaderAppeared:(srfidReaderInfo*)availableReader {
    int readerId = [availableReader getReaderID];   
    NSString *readerName = [availableReader getReaderName];   
    ScannerDeviceInfo *deviceInfo =
            [[ScannerDeviceInfo alloc] initWithName:readerName
                                              brand:ScannerBrandZebra
                                               type:ScannerTypeRFID
                                           deviceId:readerId];
    [self.addDevice deviceInfo]

    NSLog(@"RFID reader has appeared: name = %@", readerName);
}
-(void)srfidEventReaderDisappeared:(int)readerID {
    NSLog(@"RFID reader has disappeared: ID = %d", readerID);
    [self.removeDevice readerID]
}
- (void)srfidEventBatteryNotity:(int)readerID aBatteryEvent:(srfidBatteryEvent *)batteryEvent { }
- (void)srfidEventCommunicationSessionEstablished:(srfidReaderInfo *)activeReader { 
    NSLog(@"Rfid Reader connected");
    self.connectedRfidReaderId = [activeReader getReaderID];
}
- (void)srfidEventCommunicationSessionTerminated:(int)readerID { 
    NSLog(@"Rfid Reader disconnected");
    self.connectedRfidReaderId = nil;
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
    self.connectedBarcodeScannerId = [activeScanner getScannerID] 
};
- (void)sbtEventCommunicationSessionTerminated:(int)scannerID {
    NSLog(@"Barcode Reader disconnected");
    self.connectedBarcodeScannerId = nil;
};
- (void)sbtEventScannerAppeared:(SbtScannerInfo*)availableScanner {
    NSLog(@"Barcode Reader appeared");

    int scannerId = [availableScanner getScannerID];   
    NSString *scannerName = [availableScanner getScannerName];   
    ScannerDeviceInfo *deviceInfo =
            [[ScannerDeviceInfo alloc] initWithName:scannerName
                                              brand:ScannerBrandZebra
                                               type:ScannerTypeBarcode
                                           deviceId:scannerId];
    [self.addDevice deviceInfo]

};
- (void)sbtEventScannerDisappeared:(int)scannerID {
    NSLog(@"Barcode Reader dissapeared");
    [self.removeDevice scannerID]
};
- (void)sbtEventBarcode:(NSString*)barcodeData barcodeType:(int)barcodeType fromScanner:(int)scannerID {
    NSLog(@"Barcode scanned %@", barcodeData);
};
@end

