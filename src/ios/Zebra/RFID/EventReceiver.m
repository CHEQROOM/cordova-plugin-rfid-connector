@implementation EventReceiver


-(void)srfidEventReaderAppeared:(srfidReaderInfo*)availableReader {
    int readerId = [availableReader getReaderID];   
    NSString *readerName = [availableReader getReaderName];   
    ScannerDeviceInfo *deviceInfo =
            [[ScannerDeviceInfo alloc] initWithName:readerName
                                              brand:DeviceBrandZebra
                                               type:DeviceTypeRFID
                                           deviceId:[@(readerId) stringValue]];
    [self addDevice: deviceInfo];

    NSLog(@"RFID reader has appeared: name = %@", readerName);
}
-(void)srfidEventReaderDisappeared:(int)readerID {
    NSLog(@"RFID reader has disappeared: ID = %d", readerID);
    [self removeDevice: readerID];
}
- (void)srfidEventCommunicationSessionEstablished:(srfidReaderInfo *)activeReader { 
    NSLog(@"Rfid Reader connected");
    self.connectedRfidReaderId = [activeReader getReaderID];
}
- (void)srfidEventCommunicationSessionTerminated:(int)readerID { 
    NSLog(@"Rfid Reader disconnected");
    self.connectedRfidReaderId = nil;
}
- (void)srfidEventConnectedInterfaceNotity:(int)readerID aConnectedInterfaceEvent:(sfidConnectedInterfaceEvent *)connectedInterfaceEvent { }
- (void)srfidEventIOTSatusNotity:(int)readerID aIOTStatusEvent:(srfidIOTStatusEvent *)iotStatusEvent { }
- (void)srfidEventMultiProximityNotify:(int)readerID aTagData:(srfidTagData *)tagData { }
- (void)srfidEventProximityNotify:(int)readerID aProximityPercent:(int)proximityPercent { }
- (void)srfidEventReadNotify:(int)readerID aTagData:(srfidTagData *)tagData { 
     NSLog(@"Rfid read tag");
}
- (void)srfidEventStatusNotify:(int)readerID aEvent:(SRFID_EVENT_STATUS)event aNotification:(id)notificationData { }
- (void)srfidEventTriggerNotify:(int)readerID aTriggerEvent:(SRFID_TRIGGEREVENT)triggerEvent { }
- (void)srfidEventWifiScan:(int)readerID wlanSCanObject:(srfidWlanScanList *)wlanScanObject { }
- (void)srfidEventBatteryNotity:(int)readerID aBatteryEvent:(srfidBatteryEvent*)batteryEvent {
    self.batteryLevel = [batteryEvent getPowerLevel];
}

@end