//
//  ScannerDevice.h
//  RFIDConnector
//
//  Created by Interface for Scanner Device implementations
//

#import <Foundation/Foundation.h>
#import <Cordova/CDV.h>

@protocol ScannerDevice <NSObject>

/**
 * Connect to a device
 * @param command The Cordova command containing device information
 * @param delegate The command delegate for sending results
 */
- (void)connect:(CDVInvokedUrlCommand*)command commandDelegate:(NSObject<CDVCommandDelegate>*)delegate;

/**
 * Check if device is connected
 * @param command The Cordova command
 * @param delegate The command delegate for sending results
 */
- (void)isConnected:(CDVInvokedUrlCommand*)command commandDelegate:(NSObject<CDVCommandDelegate>*)delegate;

/**
 * Disconnect from device
 * @param command The Cordova command
 * @param delegate The command delegate for sending results
 */
- (void)disconnect:(CDVInvokedUrlCommand*)command commandDelegate:(NSObject<CDVCommandDelegate>*)delegate;

/**
 * Get list of available devices
 * @param command The Cordova command
 * @param delegate The command delegate for sending results
 */
- (void)getDeviceList:(CDVInvokedUrlCommand*)command commandDelegate:(NSObject<CDVCommandDelegate>*)delegate;

/**
 * Get device information
 * @param command The Cordova command
 * @param delegate The command delegate for sending results
 */
- (void)getDeviceInfo:(CDVInvokedUrlCommand*)command commandDelegate:(NSObject<CDVCommandDelegate>*)delegate;

/**
 * Scan for RFID tags
 * @param command The Cordova command containing scan parameters
 * @param delegate The command delegate for sending results
 */
- (void)scanRFIDs:(CDVInvokedUrlCommand*)command commandDelegate:(NSObject<CDVCommandDelegate>*)delegate;

/**
 * Search for specific tag
 * @param command The Cordova command containing tag ID
 * @param delegate The command delegate for sending results
 */
- (void)search:(CDVInvokedUrlCommand*)command commandDelegate:(NSObject<CDVCommandDelegate>*)delegate;

/**
 * Set output power
 * @param command The Cordova command containing power level
 * @param delegate The command delegate for sending results
 */
- (void)setOutputPower:(CDVInvokedUrlCommand*)command commandDelegate:(NSObject<CDVCommandDelegate>*)delegate;

/**
 * Subscribe to scanner events
 * @param command The Cordova command containing subscription parameters
 * @param delegate The command delegate for sending results
 */
- (void)subscribeScanner:(CDVInvokedUrlCommand*)command commandDelegate:(NSObject<CDVCommandDelegate>*)delegate;

/**
 * Unsubscribe from scanner events
 * @param command The Cordova command
 * @param delegate The command delegate for sending results
 */
- (void)unsubscribeScanner:(CDVInvokedUrlCommand*)command commandDelegate:(NSObject<CDVCommandDelegate>*)delegate;

/**
 * Start continuous search for specific tag
 * @param command The Cordova command containing tag ID
 * @param delegate The command delegate for sending results
 */
- (void)startSearch:(CDVInvokedUrlCommand*)command commandDelegate:(NSObject<CDVCommandDelegate>*)delegate;

/**
 * Stop continuous search
 * @param command The Cordova command
 * @param delegate The command delegate for sending results
 */
- (void)stopSearch:(CDVInvokedUrlCommand*)command commandDelegate:(NSObject<CDVCommandDelegate>*)delegate;

@end 