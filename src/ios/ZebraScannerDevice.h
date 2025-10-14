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

@interface ZebraScannerDevice : NSObject <ScannerDevice, srfidISdkApiDelegate, ISbtSdkApiDelegate>

@property (nonatomic, strong) id<srfidISdkApi> rfidApi;
@property (nonatomic, strong) id<ISbtSdkApi> barcodeApi;
@property (nonatomic, strong) NSMutableArray<srfidReaderInfo *> *availableRFIDReaderList;
@property (nonatomic, assign) int connectedReaderId; 

@end
