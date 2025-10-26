//
//  ZebraScannerDevice.m
//  RFIDConnector
//
//  Created by Zebra Scanner Device implementation
//
#import <ZebraScannerFramework/ZebraScannerFramework.h>
#import "ZebraScannerDevice.h"
#import "ScannerDeviceInfo.h"
#import "ScannerEventReceiver.h"
#import <Cordova/CDV.h>
#import <UIKit/UIKit.h>

@implementation ZebraScannerDevice
- (instancetype)init {
    self = [super init];
    if (self) {
        self.barcodeApi = [SbtSdkFactory createSbtSdkApiInstance];

        self.eventListener = [[ScannerEventReceiver alloc] init];
        [self.barcodeApi sbtSetDelegate:self.eventListener];
        
        [self.barcodeApi sbtSetOperationalMode:SBT_OPMODE_ALL];
        [self.barcodeApi sbtSubsribeForEvents:(SBT_EVENT_SCANNER_APPEARANCE |
                                            SBT_EVENT_SCANNER_DISAPPEARANCE |
                                            SBT_EVENT_SESSION_ESTABLISHMENT |
                                            SBT_EVENT_SESSION_TERMINATION |
                                            SBT_EVENT_BARCODE)];

        self.connectedBarcodeScannerId = nil;

        self.deviceList = [NSMutableArray array];
    }
    return self;
}


- (NSArray<ScannerDeviceInfo *> *)getDeviceList {
    if (self.deviceList.count > 0) {
        return self.deviceList;
    }

    // --- Barcode Scanners ---
    NSMutableArray *availableScanners = [[NSMutableArray alloc] init];
    NSMutableArray *activeScanners = [[NSMutableArray alloc] init];
    [self.barcodeApi sbtGetAvailableScannersList:&availableScanners];
    [self.barcodeApi sbtGetActiveScannersList:&activeScanners];

    NSArray *allScanners = [availableScanners arrayByAddingObjectsFromArray:activeScanners];
    for (SbtScannerInfo *barcodeScanner in allScanners) {
        NSString *scannerName = [barcodeScanner getScannerName];
        int scannerId = [barcodeScanner getScannerID];
        ScannerDeviceInfo *scanner = [[ScannerDeviceInfo alloc] initWithName:scannerName
                                                                       brand:DeviceBrandZebra
                                                                        type:DeviceTypeBarcode
                                                                    deviceId:[@(scannerId) stringValue]];
        [self.deviceList addObject:scanner];
        
    }
    
    return [self.deviceList copy];
}
- (ScannerConnectionStatus *)connect:(NSString *) deviceId {
    ScannerDeviceInfo *deviceInfo = [self getDeviceInfoById:deviceId];
    if (deviceInfo == nil) {
        return ScannerConnectionStatusNotFound;
    }else if(self.connectedBarcodeScannerId == deviceId){
        return ScannerConnectionStatusAlreadyConnected;
    }else if(self.connectedBarcodeScannerId == deviceId){
        [self disconnect];
    }

    SBT_RESULT connectionResult =[self.barcodeApi sbtEstablishCommunicationSession:[deviceInfo.deviceId intValue]];
    if(connectionResult != SBT_RESULT_SUCCESS){
        return ScannerConnectionStatusError;
    }

    return ScannerConnectionStatusSuccess;
}
- (BOOL)disconnect {
    if(self.connectedBarcodeScannerId == nil){
        return false;
    }

    SBT_RESULT scannerResult = [self.barcodeApi sbtTerminateCommunicationSession:self.connectedBarcodeScannerId];
    if(scannerResult != SBT_RESULT_SUCCESS){
        return false;
    }
    self.connectedBarcodeScannerId = nil;
    
    return true;
}


- (ScannerDeviceInfo *)getDeviceInfo {
    if(self.connectedBarcodeScannerId == nil){
        return nil;
    }

   NSMutableString *outXml = [NSMutableString new];
    SBT_RESULT result = [self.sdk sbtRsmAttributeGetAll:self.connectedScannerId
                                               aOutXML:outXml
                                               aStatus:nil];

    if (result != SBT_RESULT_SUCCESS) {
        NSLog(@"Failed to get attributes: %d", result);
        return nil;
    }

    ScannerDeviceInfo *deviceInfo = [self getDeviceInfoById:[@(self.connectedScannerId) stringValue]];
    deviceInfo.serialNumber    = [self parseRsmXml:outXml forAttribute:SBT_ATTR_ID_SERIAL_NUMBER];
    deviceInfo.manufacturer    = [self parseRsmXml:outXml forAttribute:SBT_ATTR_ID_MANUFACTURER];
    deviceInfo.firmwareVersion = [self parseRsmXml:outXml forAttribute:SBT_ATTR_ID_FW_VERSION];
    deviceInfo.hardwareVersion = [self parseRsmXml:outXml forAttribute:SBT_ATTR_ID_MODEL_NUMBER];
    deviceInfo.batteryLevel    = [[self parseRsmXml:outXml forAttribute:SBT_ATTR_ID_BATTERY_STATUS] intValue];

    return deviceInfo;

    return nil;
}
- (BOOL)isConnected {
    return self.connectedBarcodeScannerId != nil;    
 }
- (void)subscribeScanner:(CDVInvokedUrlCommand *)command commandDelegate:(NSObject<CDVCommandDelegate> *)delegate { }
- (void)unsubscribeScanner:(CDVInvokedUrlCommand *)command commandDelegate:(NSObject<CDVCommandDelegate> *)delegate { }
- (void)setOutputPower:(CDVInvokedUrlCommand *)command commandDelegate:(NSObject<CDVCommandDelegate> *)delegate { }
- (void)scanRFIDs:(CDVInvokedUrlCommand *)command commandDelegate:(NSObject<CDVCommandDelegate> *)delegate { }
- (void)search:(CDVInvokedUrlCommand *)command commandDelegate:(NSObject<CDVCommandDelegate> *)delegate { }
- (void)startSearch:(CDVInvokedUrlCommand *)command commandDelegate:(NSObject<CDVCommandDelegate> *)delegate { }
- (void)stopSearch:(CDVInvokedUrlCommand *)command commandDelegate:(NSObject<CDVCommandDelegate> *)delegate { }

- (NSString *)getPairingBarcode {
    // Get the barcode from Zebra SDK
    UIImage *barcodeImage = [self.barcodeApi sbtGetPairingBarcode:BARCODE_TYPE_STC withComProtocol:STC_SSI_BLE withSetDefaultStatus:SETDEFAULT_NO withImageFrame:CGRectMake(0, 0, 300, 300)];
    
    // Convert to PNG data
    NSData *imageData = UIImagePNGRepresentation(barcodeImage);
    
    // Encode to Base64 string
    NSString *base64String = [imageData base64EncodedStringWithOptions:0];

    return base64String;
}

@end

