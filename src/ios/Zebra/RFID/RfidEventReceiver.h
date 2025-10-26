@interface RfidEventReceiver : NSObject <srfidISdkApiDelegate> {
    @property (strong) ZebraRfidDevice *rfidDevice;
    @property (strong) srfidReaderInfo *reader;
}