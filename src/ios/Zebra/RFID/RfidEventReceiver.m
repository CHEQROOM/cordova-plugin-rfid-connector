@implementation RfidEventReceiver

-(instancetype)initWithInstance:(ZebraRfidDevice*)rfidDevice {
  if((self = [super init])){
    _rfidDevice=rfidDevice;
  }
  return self;

}
static int connectedReaderId
static int batteryLevel;

+(int) readerId{
  return connectedReaderId;
}

+(BOOL) isConnected{
  return connectedReaderId != nil;
}

+(int) batteryLevel{
  return batteryLevel;
}

-(void)srfidEventReaderAppeared:(srfidReaderInfo*)availableReader {
    int readerId = [availableReader getReaderID];   
    NSString *readerName = [availableReader getReaderName];   
    ScannerDeviceInfo *deviceInfo =
            [[ScannerDeviceInfo alloc] initWithName:readerName
                                              brand:DeviceBrandZebra
                                               type:DeviceTypeRFID
                                           deviceId:[@(readerId) stringValue]];
    [_rfidDevice addDevice: deviceInfo];

    NSLog(@"RFID reader has appeared: name = %@", readerName);
}
-(void)srfidEventReaderDisappeared:(int)readerID {
    NSLog(@"RFID reader has disappeared: ID = %d", readerID);
    [_rfidDevice removeDevice: readerID];
}
- (void)srfidEventCommunicationSessionEstablished:(srfidReaderInfo *)activeReader { 
    NSLog(@"Rfid Reader connected");
    connectedReaderId = [activeReader getReaderID];
}
- (void)srfidEventCommunicationSessionTerminated:(int)readerID { 
    NSLog(@"Rfid Reader disconnected");
    connectedReaderId = nil;
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
    batteryLevel = [batteryEvent getPowerLevel];
}

@end