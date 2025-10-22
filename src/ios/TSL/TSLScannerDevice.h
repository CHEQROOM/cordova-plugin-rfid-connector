//
//  TSLScannerDevice.h
//  RFIDConnector
//
//  Created by TSL Scanner Device implementation
//

#import <Foundation/Foundation.h>
#import <TSLAsciiCommands/TSLAsciiCommander.h>
#import <TSLAsciiCommands/TSLBatteryStatusCommand.h>
#import <TSLAsciiCommands/TSLVersionInformationCommand.h>
#import <TSLAsciiCommands/TSLTransponderData.h>
#import <TSLAsciiCommands/TSLInventoryCommand.h>
#import <TSLAsciiCommands/TSLBarcodeCommand.h>
#import <TSLAsciiCommands/TSLAntennaParameters.h>
#import "ScannerDevice.h"

@interface TSLScannerDevice : NSObject <ScannerDevice>

@property (nonatomic, readwrite) TSLAsciiCommander *commander;
@property (nonatomic, readwrite) NSInteger scanPower;

- (TSLAsciiCommander*)getCommander;

@end 