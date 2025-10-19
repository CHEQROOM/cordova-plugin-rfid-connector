//
//  ScannerDeviceFactory.m
//  RFIDConnector
//
//  Created by Factory implementation for creating Scanner Device instances
//

#import "ScannerDeviceFactory.h"
#import "TSLScannerDevice.h"
#import "ZebraScannerDevice.h"

@implementation ScannerDeviceFactory

+ (id<ScannerDevice>)getInstance:(NSString*)deviceType {
    if ([deviceType isEqualToString:@"TSL"]) {
        static TSLScannerDevice *tslInstance = nil;
        static dispatch_once_t onceTokenTSL;
        dispatch_once(&onceTokenTSL, ^{
            tslInstance = [[TSLScannerDevice alloc] init];
        });
        return tslInstance;
    } else if ([deviceType isEqualToString:@"ZEBRA"]) {
        static ZebraScannerDevice *zebraInstance = nil;
        static dispatch_once_t onceTokenZebra;
        dispatch_once(&onceTokenZebra, ^{
            zebraInstance = [[ZebraScannerDevice alloc] init];
        });
        return zebraInstance;
    } else {
        return nil;
    }
}

@end
