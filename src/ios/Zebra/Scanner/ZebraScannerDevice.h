//
//  ZebraScannerDevice.h
//  RFIDConnector
//
//  Created by Zebra Scanner Device implementation
//

#import <Foundation/Foundation.h>
#import <ZebraScannerFramework/ZebraScannerFramework.h>
#import "ScannerDevice.h"
#import "ScannerDeviceInfo.h"
#import "ScannerEventReceiver.h"
#import "ZebraDeviceBase.h"

@interface ZebraScannerDevice : ZebraDeviceBase <ScannerDevice>

@property (nonatomic, strong) id<ISbtSdkApi> barcodeApi;
@property (strong, nonatomic) ScannerEventReceiver *eventListener;

@property (nonatomic, strong) NSMutableArray<ScannerDeviceInfo *> *deviceList;

@property (nonatomic, assign) int connectedBarcodeScannerId;

@property (nonatomic, assign) int batteryLevel;

@end
