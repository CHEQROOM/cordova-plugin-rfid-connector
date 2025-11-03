//
//  ScannerDeviceFactory.m
//  RFIDConnector
//
//  Created by Factory implementation for creating Scanner Device instances
//

#import "ScannerDeviceFactory.h"
#import "TSLScannerDevice.h"
#import "ZebraScannerDevice.h"
#import "ZebraRfidDevice.h"

@implementation ScannerDeviceFactory

+ (id<ScannerDevice>)getInstance:(DeviceBrand *)deviceBrand deviceType:(DeviceType *)deviceType {
    if (deviceBrand == DeviceBrandTSL) {
        static TSLScannerDevice *tslInstance = nil;
        static dispatch_once_t onceTokenTSL;
        dispatch_once(&onceTokenTSL, ^{
            tslInstance = [[TSLScannerDevice alloc] init];
        });
        return tslInstance;
    } else if (deviceBrand == DeviceBrandZebra) {
        if(deviceType == DeviceTypeBarcode){
            static ZebraScannerDevice *zebraInstance = nil;
            static dispatch_once_t onceTokenZebra;
            dispatch_once(&onceTokenZebra, ^{
                zebraInstance = [[ZebraScannerDevice alloc] init];
            });
            return zebraInstance;
        }else{
            static ZebraRfidDevice *zebraInstance = nil;
            static dispatch_once_t onceTokenZebra;
            dispatch_once(&onceTokenZebra, ^{
                zebraInstance = [[ZebraRfidDevice alloc] init];
            });
            return zebraInstance;
        }
    } else {
        return nil;
    }
}

@end
