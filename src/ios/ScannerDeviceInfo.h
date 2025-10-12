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

@property (nonatomic, strong) NSString *name
@property (nonatomic, assign) ScannerBrand *brand
@property (nonatomic, assign) ScannerType *type

- (instancetype)initWithName:(NSString *)name brand:(ScannerBrand)brand; type:(ScannerType)type

@end