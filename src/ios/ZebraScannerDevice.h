//
//  ZebraScannerDevice.h
//  RFIDConnector
//
//  Created by Zebra Scanner Device implementation
//

#import <Foundation/Foundation.h>
#import <ZebraScannerSDK/ZebraScannerSDK.h>
#import "ScannerDevice.h"

@interface ZebraScannerDevice : NSObject <ScannerDevice, ISbtSdkApiDelegate>

@property (nonatomic, strong) id<ISbtSdkApi> sdkApi;
@property (nonatomic, strong) SbtScannerInfo *connectedScanner;
@property (nonatomic, assign) NSInteger scanPower;

@end
