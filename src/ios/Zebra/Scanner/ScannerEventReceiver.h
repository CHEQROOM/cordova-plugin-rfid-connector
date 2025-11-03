#import <Foundation/Foundation.h>
#import <ZebraScannerFramework/ZebraScannerFramework.h>

@class ZebraScannerDevice;

@interface ScannerEventReceiver : NSObject <ISbtSdkApiDelegate>

@property (nonatomic, strong) ZebraScannerDevice *scannerDevice;
- (instancetype)initWithInstance:(ZebraScannerDevice *)scannerDevice;

@end
