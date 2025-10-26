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
#import "EventReceiver.h"

@interface ZebraScannerDevice : NSObject <ScannerDevice, ZebraDeviceBase, srfidISdkApiDelegate>

@property (nonatomic, strong) id<srfidISdkApi> rfidApi;
@property (strong, nonatomic) EventReceiver *eventListener;
@property (nonatomic, strong) NSMutableArray<ScannerDeviceInfo *> *deviceList;

@property (nonatomic, assign) int connectedReaderId;
@property (nonatomic, assign) int batteryLevel;

@end
