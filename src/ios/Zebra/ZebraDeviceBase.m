
@implementation ZebraDeviceBase

- (instancetype)init {
    self = [super init];
    if (self) {
        self.deviceList = [NSMutableArray array];
    }
    return self;
}

- (void)addDevice:(ScannerDeviceInfo *)device {
    BOOL exists = NO;
    for (ScannerDeviceInfo *info in self.deviceList) {
        if ([info.name isEqualToString:device.name]) {
            exists = YES;
            break;
        }
    }
    if (!exists) {
        [self.deviceList addObject:device];
    }
}

- (void)removeDevice:(int)deviceId {
    ScannerDeviceInfo *toRemove = nil;
    for (ScannerDeviceInfo *info in self.deviceList) {
        if (info.deviceId == deviceId) {
            toRemove = info;
            break;
        }
    }
    if (toRemove) {
        [self.deviceList removeObject:toRemove];
    }
}

- (ScannerDeviceInfo *)getDeviceInfoById:(NSString *)deviceId {
    for (ScannerDeviceInfo *deviceInfo in self.deviceList) {
        if ([deviceInfo.deviceId isEqualToString:deviceId]) {
            return [deviceInfo copy];
        }
    }
    return nil;
}

@end