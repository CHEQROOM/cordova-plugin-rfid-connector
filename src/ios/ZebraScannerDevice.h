//
//  ZebraScannerDevice.h
//  RFIDConnector
//
//  Created by Zebra Scanner Device implementation
//

#import <Foundation/Foundation.h>
#import "ScannerDevice.h"
#import <ZebraRfidSdkFramework/ZebraRfidSdkFramework.h>
#import <ZebraScannerFramework/ZebraScannerFramework.h>
#import "ScannerDeviceInfo.h"

@interface ZebraScannerDevice : NSObject <ScannerDevice, srfidISdkApiDelegate, ISbtSdkApiDelegate>

@property (nonatomic, strong) id<srfidISdkApi> rfidApi;
@property (nonatomic, strong) id<ISbtSdkApi> barcodeApi;

@property (nonatomic, strong) NSMutableArray<ScannerDeviceInfo *> *deviceList;

@property (nonatomic, assign) int connectedBarcodeScannerId;
@property (nonatomic, assign) int connectedRfidReaderId;

@property (nonatomic, assign) int batteryLevel;

@end
