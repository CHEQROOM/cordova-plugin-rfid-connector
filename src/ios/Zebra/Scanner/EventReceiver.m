@implementation EventReceiver

-(instancetype)initWithInstance:(ZebraScannerDevice*)scannerDevice {
  if((self = [super init])){
    _scannerDevice=scannerDevice;
  }
  return self;

}
static int connectedReaderId
static int batteryLevel;

- (void)sbtEventCommunicationSessionEstablished:(SbtScannerInfo*)activeScanner {
    NSLog(@"Barcode Reader connected");
    connectedReaderId = [activeScanner getScannerID];
};
- (void)sbtEventCommunicationSessionTerminated:(int)scannerID {
    NSLog(@"Barcode Reader disconnected");
    connectedReaderId = nil;
};
- (void)sbtEventScannerAppeared:(SbtScannerInfo*)availableScanner {
    NSLog(@"Barcode Reader appeared");

    int scannerId = [availableScanner getScannerID];   
    NSString *scannerName = [availableScanner getScannerName];   
    ScannerDeviceInfo *deviceInfo =
            [[ScannerDeviceInfo alloc] initWithName:scannerName
                                              brand:DeviceBrandZebra
                                               type:DeviceTypeBarcode
                                           deviceId:[@(scannerId) stringValue]];
    [_scannerDevice addDevice: deviceInfo];

};
- (void)sbtEventScannerDisappeared:(int)scannerID {
    NSLog(@"Barcode Reader dissapeared");
    [_scannerDevice removeDevice: scannerID];
};
- (void)sbtEventBarcode:(NSString*)barcodeData barcodeType:(int)barcodeType fromScanner:(int)scannerID {
    NSLog(@"Barcode scanned %@", barcodeData);
};

@end