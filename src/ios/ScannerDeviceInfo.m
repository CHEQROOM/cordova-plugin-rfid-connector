#import "ScannerDeviceInfo.h"

@implementation ScannerDeviceInfo

- (instancetype)initWithName:(NSString *)name brand:(DeviceBrand)brand type:(DeviceType)type deviceId:(NSString *)deviceId {
    self = [super init];
    if (self) {
        _name = name;
        _brand = brand;
        _type = type;
        _deviceId = deviceId;
    }
    return self;
}

- (NSDictionary *)toDictionary {
    NSMutableDictionary *dict = [@{
        @"name": self.name ?: @"",
        @"brand": NSStringFromDeviceBrand(self.brand),
        @"type": NSStringFromDeviceType(self.type),
        @"deviceId": self.deviceId ?: @""
    } mutableCopy];

    // Optional info if available
    if (self.serialNumber) [dict setObject:self.serialNumber forKey:@"serialNumber"];
    if (self.manufacturer) [dict setObject:self.manufacturer forKey:@"manufacturer"];
    if (self.hardwareVersion) [dict setObject:self.hardwareVersion forKey:@"hardwareVersion"];
    if (self.firmwareVersion) [dict setObject:self.firmwareVersion forKey:@"firmwareVersion"];
    if (self.batteryLevel >= 0) [dict setObject:@(self.batteryLevel) forKey:@"batteryLevel"];
    if (self.antennaMin) [dict setObject:@(self.antennaMin) forKey:@"antennaMin"];
    if (self.antennaMax) [dict setObject:@(self.antennaMax) forKey:@"antennaMax"];
    if (self.pScanPower) [dict setObject:@(self.pScanPower) forKey:@"pScanPower"];
    if (self.dScanPower) [dict setObject:@(self.dScanPower) forKey:@"dScanPower"];

    return dict;
}

- (id)copyWithZone:(NSZone *)zone {
    ScannerDeviceInfo *copy = [[[self class] allocWithZone:zone] init];
    copy.name = self.name;
    copy.brand = self.brand;
    copy.type = self.type;
    copy.deviceId = self.deviceId;
    copy.serialNumber = self.serialNumber;
    copy.manufacturer = self.manufacturer;
    copy.hardwareVersion = self.hardwareVersion;
    copy.firmwareVersion = self.firmwareVersion;
    copy.batteryLevel = self.batteryLevel;
    copy.antennaMin = self.antennaMin;
    copy.antennaMax = self.antennaMax;
    copy.pScanPower = self.pScanPower;
    copy.dScanPower = self.dScanPower;
    return copy;
}

@end