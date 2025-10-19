#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, ScannerBrand) {
    ScannerBrandZebra,
    ScannerBrandTSL
};

typedef NS_ENUM(NSInteger, ScannerType) {
    ScannerTypeRFID,
    ScannerTypeBarcode
};

@interface ScannerDeviceInfo : NSObject

@property (nonatomic, strong) NSString *name;
@property (nonatomic, assign) ScannerBrand brand;
@property (nonatomic, assign) ScannerType type;
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
                       brand:(ScannerBrand)brand
                       type:(ScannerType)type
                       deviceId:(NSString *)deviceId;
- (NSDictionary *)toDictionary;
- (id)copyWithZone:(NSZone *)zone;

@end