@implementation EventReceiver

- (void)sbtEventCommunicationSessionEstablished:(SbtScannerInfo*)activeScanner {
    NSLog(@"Barcode Reader connected");
    self.connectedBarcodeScannerId = [activeScanner getScannerID];
};
- (void)sbtEventCommunicationSessionTerminated:(int)scannerID {
    NSLog(@"Barcode Reader disconnected");
    self.connectedBarcodeScannerId = nil;
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
    [self addDevice: deviceInfo];

};
- (void)sbtEventScannerDisappeared:(int)scannerID {
    NSLog(@"Barcode Reader dissapeared");
    [self removeDevice: scannerID];
};
- (void)sbtEventBarcode:(NSString*)barcodeData barcodeType:(int)barcodeType fromScanner:(int)scannerID {
    NSLog(@"Barcode scanned %@", barcodeData);
};

@end