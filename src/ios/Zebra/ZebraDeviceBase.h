@interface ZebraDeviceBase : NSObject

@property (strong, nonatomic) NSMutableArray<ScannerDeviceInfo *> *deviceList;

- (void)addDevice:(ScannerDeviceInfo *)device;
- (void)removeDevice:(int)deviceId;
- (ScannerDeviceInfo *)getDeviceInfoById:(NSString *)deviceId;

@end
