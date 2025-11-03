//
//  ZebraScannerDevice.m
//  RFIDConnector
//
//  Created by Zebra Scanner Device implementation
//
#import <ZebraRfidSdkFramework/ZebraRfidSdkFramework.h>
#import "ScannerDeviceInfo.h"
#import <Cordova/CDV.h>
#import <UIKit/UIKit.h>
#import "ZebraRfidDevice.h"
#import "RfidEventReceiver.h"

@implementation ZebraRfidDevice
- (instancetype)init {
    self = [super init];
    if (self) {
        self.rfidApi = [srfidSdkFactory createRfidSdkApiInstance];

        self.eventListener = [[RfidEventReceiver alloc] init];
        [self.rfidApi srfidSetDelegate:self.eventListener];

        [self.rfidApi srfidSetOperationalMode:SRFID_OPMODE_ALL];
        [self.rfidApi srfidSubsribeForEvents:(SRFID_EVENT_READER_APPEARANCE |
                                            SRFID_EVENT_READER_DISAPPEARANCE |
                                            SRFID_EVENT_SESSION_ESTABLISHMENT |
                                            SRFID_EVENT_SESSION_TERMINATION | 
                                            SRFID_EVENT_MASK_BATTERY)];
        [self.rfidApi srfidEnableAvailableReadersDetection:YES];
        [self.rfidApi srfidEnableAutomaticSessionReestablishment:YES];

        self.connectedReaderId = nil;

        self.deviceList = [NSMutableArray array];
    }
    return self;
}


- (NSArray<ScannerDeviceInfo *> *)getDeviceList {
    if (self.deviceList.count > 0) {
        return self.deviceList;
    }

    NSMutableArray *availableRFID = [NSMutableArray array];
    NSMutableArray *activeRFID = [NSMutableArray array];
    [self.rfidApi srfidGetAvailableReadersList:&availableRFID];
    [self.rfidApi srfidGetActiveReadersList:&activeRFID];
    
    NSArray *allRFID = [availableRFID arrayByAddingObjectsFromArray:activeRFID];
    for (srfidReaderInfo *reader in allRFID) {
        NSString *readerName = [reader getReaderName]; 
        int readerId = [reader getReaderID];
        ScannerDeviceInfo *scanner = [[ScannerDeviceInfo alloc] initWithName:readerName
                                                                       brand:DeviceBrandZebra
                                                                        type:DeviceTypeRFID
                                                                    deviceId:[@(readerId) stringValue]];
        [self.deviceList addObject:scanner];
    }
    
    return [self.deviceList copy];
}
- (ScannerConnectionStatus *)connect:(NSString *) deviceId {
    ScannerDeviceInfo *deviceInfo = [self getDeviceInfoById:deviceId];
    if (deviceInfo == nil) {
        return ScannerConnectionStatusNotFound;
    }else if(self.connectedReaderId == deviceId){
        return ScannerConnectionStatusAlreadyConnected;
    }else if(self.connectedReaderId != deviceId){
        [self disconnect];
    }

    SRFID_RESULT connectionResult = [self.rfidApi srfidEstablishCommunicationSession:[deviceInfo.deviceId intValue]];
    if (SRFID_RESULT_SUCCESS != connectionResult){
        return ScannerConnectionStatusError;
    }     

    return ScannerConnectionStatusSuccess;
}
- (BOOL)disconnect {
    if(self.connectedReaderId == nil){
        return false;
    }

    SRFID_RESULT rfidResult = [self.rfidApi srfidTerminateCommunicationSession:self.connectedReaderId];
    if(rfidResult != SRFID_RESULT_SUCCESS){
        return false;
    }
    self.connectedReaderId = nil;

    return true;
}


- (ScannerDeviceInfo *)getDeviceInfo {
    if(self.connectedReaderId == nil){
        return nil;
    }

    [self.rfidApi srfidRequestBatteryStatus:self.connectedReaderId];

    srfidReaderCapabilitiesInfo *capabilities = [[srfidReaderCapabilitiesInfo alloc] init];
    NSString *error_response = nil;
    
    SRFID_RESULT result = [self.rfidApi srfidGetReaderCapabilitiesInfo:self.connectedReaderId aReaderCapabilitiesInfo:&capabilities aStatusMessage:&error_response];
    if (SRFID_RESULT_SUCCESS == result) {

        ScannerDeviceInfo *deviceInfo = [self getDeviceInfoById: [@(self.connectedReaderId) stringValue]];    
        deviceInfo.serialNumber = [capabilities getSerialNumber];
        deviceInfo.manufacturer = [capabilities getManufacturer];
        deviceInfo.hardwareVersion = [capabilities getAsciiVersion];
        deviceInfo.firmwareVersion = [capabilities getAirProtocolVersion];
        deviceInfo.batteryLevel = self.batteryLevel;
        deviceInfo.antennaMin = [capabilities getMinPower];
        deviceInfo.antennaMax = [capabilities getMaxPower];
        deviceInfo.pScanPower = [capabilities getMaxPower];
        deviceInfo.dScanPower = [capabilities getPowerStep];
        return deviceInfo;
    }

    return nil;
}
- (BOOL)isConnected {
    return self.connectedReaderId != nil;    
 }
- (void)subscribeScanner:(CDVInvokedUrlCommand *)command commandDelegate:(NSObject<CDVCommandDelegate> *)delegate { }
- (void)unsubscribeScanner:(CDVInvokedUrlCommand *)command commandDelegate:(NSObject<CDVCommandDelegate> *)delegate { }
- (void)setOutputPower:(CDVInvokedUrlCommand *)command commandDelegate:(NSObject<CDVCommandDelegate> *)delegate { }
- (void)scanRFIDs:(CDVInvokedUrlCommand *)command commandDelegate:(NSObject<CDVCommandDelegate> *)delegate { }
- (void)search:(CDVInvokedUrlCommand *)command commandDelegate:(NSObject<CDVCommandDelegate> *)delegate { }
- (void)startSearch:(CDVInvokedUrlCommand *)command commandDelegate:(NSObject<CDVCommandDelegate> *)delegate { }
- (void)stopSearch:(CDVInvokedUrlCommand *)command commandDelegate:(NSObject<CDVCommandDelegate> *)delegate { }

@end

