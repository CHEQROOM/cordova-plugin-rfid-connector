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
        return [[TSLScannerDevice alloc] init];
    } else if ([deviceType isEqualToString:@"ZEBRA"]) {
        return [[ZebraScannerDevice alloc] init];
    } else {
        return nil;
    }
}

@end
