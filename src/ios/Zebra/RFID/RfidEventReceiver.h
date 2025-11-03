#import <Foundation/Foundation.h>
#import <ZebraRfidSdkFramework/ZebraRfidSdkFramework.h>

@class ZebraRfidDevice;

@interface RfidEventReceiver : NSObject <srfidISdkApiDelegate>

@property (nonatomic, strong) ZebraRfidDevice *rfidDevice;
- (instancetype)initWithInstance:(ZebraRfidDevice *)rfidDevice;

@end
