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

@interface ZebraScannerDevice : NSObject <ScannerDevice, srfidISdkApiDelegate>

@property (nonatomic, strong) id<srfidISdkApi> api;
@property (nonatomic, strong) NSMutableArray<srfidReaderInfo *> *availableRFIDReaderList;

@end
