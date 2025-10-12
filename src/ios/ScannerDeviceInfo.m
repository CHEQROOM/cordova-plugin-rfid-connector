#import "ScannerDeviceInfo.h"

@implementation ScannerDeviceInfo

- (instancetype)initWithName:(NSString *)name brand:(ScannerBrand)brand type:(ScannerType)type {
    self = [super init];
    if (self) {
        _name = name;
        _brand = brand;
        _type = type;
    }
    return self;
}

@end