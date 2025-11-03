//
//  ZebraScannerDevice.h
//  RFIDConnector
//
//  Created by Zebra Scanner Device implementation
//

#import <Foundation/Foundation.h>
#import <ZebraRfidSdkFramework/ZebraRfidSdkFramework.h>
#import "ScannerDevice.h"
#import "ScannerDeviceInfo.h"
#import "RfidEventReceiver.h"
#import "ZebraDeviceBase.h"

@interface ZebraRfidDevice : ZebraDeviceBase <ScannerDevice>

@property (nonatomic, strong) id<srfidISdkApi> rfidApi;
@property (strong, nonatomic) RfidEventReceiver *eventListener;
@property (nonatomic, strong) NSMutableArray<ScannerDeviceInfo *> *deviceList;

@property (nonatomic, assign) int connectedReaderId;
@property (nonatomic, assign) int batteryLevel;

@end
