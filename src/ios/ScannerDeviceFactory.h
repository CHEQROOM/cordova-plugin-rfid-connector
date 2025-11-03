//
//  ScannerDeviceFactory.h
//  RFIDConnector
//
//  Created by Factory for creating Scanner Device instances
//

#import <Foundation/Foundation.h>
#import "ScannerDevice.h"

@interface ScannerDeviceFactory : NSObject

/**
 * Get scanner device instance based on type
 * @param deviceBrand The brand of scanner (TSL, ZEBRA, etc.)
 * @param deviceType The type of scanner (RFID, Barcode)
 * @return ScannerDevice instance or nil if type not supported
 */
+ (id<ScannerDevice>)getInstance:(DeviceBrand*)deviceBrand deviceType:(DeviceType *)deviceType;

@end 
