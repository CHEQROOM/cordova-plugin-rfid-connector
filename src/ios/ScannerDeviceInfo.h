#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, DeviceBrand) {
    DeviceBrandZebra,
    DeviceBrandTSL
};

typedef NS_ENUM(NSInteger, DeviceType) {
    DeviceTypeRFID,
    DeviceTypeBarcode
};

static inline NSString *NSStringFromDeviceBrand(DeviceBrand brand) {
    switch (brand) {
        case DeviceBrandZebra: return @"Zebra";
        case DeviceBrandTSL: return @"TSL";
    }
}

static inline NSString *NSStringFromDeviceType(DeviceType type) {
    switch (type) {
        case DeviceTypeRFID: return @"RFID";
        case DeviceTypeBarcode: return @"Barcode";
    }
}

static inline DeviceBrand DeviceBrandFromString(NSString *string) {
    if ([string isEqualToString:@"Zebra"]) return DeviceBrandZebra;
    if ([string isEqualToString:@"TSL"]) return DeviceBrandTSL;
    return DeviceBrandTSL;
}

static inline DeviceType DeviceTypeFromString(NSString *string) {
    if ([string isEqualToString:@"RFID"]) return DeviceTypeRFID;
    if ([string isEqualToString:@"Barcode"]) return DeviceTypeBarcode;
    return DeviceTypeRFID;
}

@interface ScannerDeviceInfo : NSObject

@property (nonatomic, strong) NSString *name;
@property (nonatomic, assign) DeviceBrand brand;
@property (nonatomic, assign) DeviceType type;
@property (nonatomic, strong) NSString *deviceId;

@property (nonatomic, strong) NSString *serialNumber;
@property (nonatomic, strong) NSString *manufacturer;
@property (nonatomic, strong) NSString *hardwareVersion;
@property (nonatomic, strong) NSString *firmwareVersion;
@property (nonatomic, assign) NSInteger batteryLevel;
@property (nonatomic, assign) NSInteger antennaMin;
@property (nonatomic, assign) NSInteger antennaMax;
@property (nonatomic, assign) NSInteger pScanPower;
@property (nonatomic, assign) NSInteger dScanPower;

- (instancetype)initWithName:(NSString *)name 
                       brand:(DeviceBrand)brand
                       type:(DeviceType)type
                       deviceId:(NSString *)deviceId;
- (NSDictionary *)toDictionary;
- (id)copyWithZone:(NSZone *)zone;

@end