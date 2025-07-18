/********* BluetoothScanner.m Cordova Plugin Implementation *******/

#import <Cordova/CDV.h>
#import <TSLAsciiCommands/TSLAsciiCommander.h>
#import <TSLAsciiCommands/TSLBatteryStatusCommand.h>
#import <TSLAsciiCommands/TSLVersionInformationCommand.h>
#import <TSLAsciiCommands/TSLTransponderData.h>
#import <TSLAsciiCommands/TSLInventoryCommand.h>
#import <TSLAsciiCommands/TSLBarcodeCommand.h>
#import <TSLAsciiCommands/TSLAntennaParameters.h>

@interface TSLScanner : NSObject {
  // Member variables go here.
}
@property (nonatomic,readwrite) TSLAsciiCommander *commander;
@property (nonatomic,readwrite) NSInteger *scanPower;

- (void)connect:(CDVInvokedUrlCommand*)command;
- (void)isConnected:(CDVInvokedUrlCommand*)command commandDelegate:(NSObject<CDVCommandDelegate>*)delegate;
- (void)disconnect:(CDVInvokedUrlCommand*)command;
- (void)getDeviceInfo:(CDVInvokedUrlCommand*)command;
- (void)scanRFIDs:(CDVInvokedUrlCommand*)command;
- (void)search:(CDVInvokedUrlCommand*)command;
- (void)setOutputPower:(CDVInvokedUrlCommand*)command;

- (TSLAsciiCommander*) getCommander;
@end

@implementation TSLScanner

  static NSString *const ERROR_LABEL = @"Error: ";
  static NSString *const DEVICE_IS_ALREADY_CONNECTED = @"Device is already connected.";
  static NSString *const SCAN_POWER = @"scanPower";
  static NSString *const ANTENNA_MAX = @"antennaMax";
  static NSString *const ANTENNA_MIN = @"antennaMin";
  static NSString *const SERIAL_NUMBER = @"serialNumber";
  static NSString *const MANUFACTURER = @"manufacturer";
  static NSString *const FIRMWARE_VERSION = @"firmwareVersion";
  static NSString *const HARDWARE_VERSION = @"hardwareVersion";
  static NSString *const BATTERY_STATUS = @"batteryStatus";
  static NSString *const BATTERY_LEVEL = @"batteryLevel";
  static NSString *const DEVICE_NAME = @"deviceName";
  static NSString *const DEVICE_IS_NOT_CONNECTED = @"Device is not connected.";

 TSLBarcodeCommand *_barcodeResponder;
 TSLInventoryCommand *_inventoryResponder;
 TSLInventoryCommand *_inventorySearchResponder;

 CDVInvokedUrlCommand *_asyncCommand;

 CDVPluginResult *_asyncPluginResult = nil;
 CDVPluginResult *_asyncSearchPluginResult = nil;

 NSObject<CDVCommandDelegate>* subsCmdDelegate;

- (TSLAsciiCommander*) getCommander
{
	if (self.commander == nil){
		self.commander = [[TSLAsciiCommander alloc] init];
	}
	return self.commander;
}

- (void)connect:(CDVInvokedUrlCommand*)command commandDelegate:(NSObject<CDVCommandDelegate>*)delegate
{
    CDVPluginResult* pluginResult = nil;
    NSString* deviceName = [command.arguments objectAtIndex:1];

    if (deviceName != nil && [deviceName length] > 0) {
			  EAAccessory *accessory = nil;
		  	TSLAsciiCommander* commander = [self getCommander];
				NSString* connectionMsg = @"";

				if([commander isConnected]){

						accessory = commander.connectedAccessory;
						if([deviceName isEqualToString:accessory.name] || [deviceName isEqualToString:accessory.serialNumber]){
               connectionMsg = DEVICE_IS_ALREADY_CONNECTED;
						}
						else{
							connectionMsg = [@"Already another device is in use, please disconnect first " stringByAppendingString:deviceName];
						}
						pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:connectionMsg];
				}
				if(![commander isConnected]){
								NSArray* _currentAccessories = [[EAAccessoryManager sharedAccessoryManager] connectedAccessories];
								for (EAAccessory *obj in _currentAccessories)
										{
											if([deviceName isEqualToString:obj.name] || [deviceName isEqualToString:obj.serialNumber]){
													accessory = obj;
											}
										}
								if(!accessory){
									connectionMsg = [@"Device not found " stringByAppendingString:deviceName];
									pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:connectionMsg];
								}
								if(accessory){
										 self.scanPower = -1;
                     NSString* echo = [commander connect:accessory] ? @"true" : @"false";
										 connectionMsg = echo;//[@"Trying to connect " stringByAppendingString:deviceName];
										 // BOOL connected = [commander isConnected];
										 // echo = connected ? @"CONNECTED" : @"NOT-CONNECTED";
                     if([commander isConnected]){
                       [self removeAsyncAndAddSyncResponder];
                        TSLVersionInformationCommand* versionInformationCommand = [TSLVersionInformationCommand synchronousCommand];
				              	[commander executeCommand:versionInformationCommand];
                        NSString *connectedDevice = versionInformationCommand.manufacturer;
                       
                        if( ([connectedDevice rangeOfString:@"TSL" options:NSCaseInsensitiveSearch].length > 0) || ([connectedDevice rangeOfString:@"Technology Solutions" options:NSCaseInsensitiveSearch].length  >0 )){
                          TSLInventoryCommand *invCommand = [TSLInventoryCommand synchronousCommand];;
                          invCommand.takeNoAction = TSL_TriState_YES;
                          invCommand.includeEPC = TSL_TriState_YES;
                          invCommand.includeTransponderRSSI = TSL_TriState_YES;
                          [commander executeCommand:invCommand];
                          [self removeSyncAndAddAsyncResponder];
                           pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:connectionMsg];
                          }else{
                           [commander disconnect];
                           connectionMsg =@"Not a recognised device";
                           pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR  messageAsString:connectionMsg];
                         }
                       }
							   	}
						}
     } else {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
    }
    [delegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)isConnected:(CDVInvokedUrlCommand*)command commandDelegate:(NSObject<CDVCommandDelegate>*)delegate
{
    CDVPluginResult* pluginResult = nil;
    NSString* echo = @"n/a";
		if (command != nil) {
				TSLAsciiCommander* commander = [self getCommander];
				echo = [commander isConnected] ? @"true" : @"false";
				pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:echo];
		}else{
       echo = @"false";
		pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:echo];
    }
		[delegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)disconnect:(CDVInvokedUrlCommand*)command commandDelegate:(NSObject<CDVCommandDelegate>*)delegate
{
    CDVPluginResult* pluginResult = nil;
    NSString* disconnectMsg = @"n/a";
		TSLAsciiCommander* commander = [self getCommander];
    if (command != nil && [commander isConnected]) {
      [self removeAsyncResponder];
			_inventoryResponder = nil;
			_barcodeResponder = nil;
      _asyncPluginResult=nil;
      _asyncCommand = nil;
				[commander disconnect];
				self.scanPower = -1;
				disconnectMsg = @"true";
				pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:disconnectMsg];
    }
		else {
			disconnectMsg = @"No connection exist to disconnect.";
			pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:disconnectMsg];
		}
    [delegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)getDeviceInfo:(CDVInvokedUrlCommand*)command commandDelegate:(NSObject<CDVCommandDelegate>*)delegate
{
		CDVPluginResult* pluginResult = nil;
		NSString* echo = nil;

		if (command != nil) {
			TSLAsciiCommander* commander = [self getCommander];
			[self removeAsyncAndAddSyncResponder];
			EAAccessory *accessory = nil;
			NSError *error = nil;
			NSString *status = @"true";
			NSString *errorMsg = @"";
			NSData *json = nil;
			NSString *jsonMsg = nil;

			if([commander isConnected]){
					TSLVersionInformationCommand* versionInformationCommand = [TSLVersionInformationCommand synchronousCommand];
					[commander executeCommand:versionInformationCommand];

					TSLBatteryStatusCommand* batteryStatusCommand = [TSLBatteryStatusCommand synchronousCommand];
					[commander executeCommand:batteryStatusCommand];

          TSLInventoryCommand* invCommand = [TSLInventoryCommand synchronousCommand];
   			  invCommand.takeNoAction = TSL_TriState_YES;
          invCommand.includeEPC = TSL_TriState_YES;
          invCommand.includeTransponderRSSI = TSL_TriState_YES;
          invCommand.captureNonLibraryResponses = YES;
          invCommand.readParameters = YES;
          [commander executeCommand:invCommand];

					accessory = commander.connectedAccessory;

					//NSMutableArray *dataArray = [[NSMutableArray alloc] init];
					NSMutableDictionary *infoString = [[NSMutableDictionary alloc] init];
					// Add objects to a dictionary indexed by keys
					[infoString setObject:versionInformationCommand.serialNumber forKey:@"deviceName"];

					[infoString setObject:[NSNumber numberWithInt:[batteryStatusCommand batteryLevel]] forKey:@"batteryLevel"];
					[infoString setObject:@"n/a" forKey:@"batteryStatus"];
					[infoString setObject:accessory.hardwareRevision forKey:@"hardwareVersion"];
					[infoString setObject:versionInformationCommand.firmwareVersion forKey:@"firmwareVersion"];
					[infoString setObject:versionInformationCommand.manufacturer forKey:@"manufacturer"];
					[infoString setObject:versionInformationCommand.serialNumber forKey:@"serialNumber"];
					[infoString setObject:[NSNumber numberWithInt:[TSLInventoryCommand minimumOutputPower]] forKey:@"antennaMin"];
					[infoString setObject:[NSNumber numberWithInt:[TSLInventoryCommand maximumOutputPower]] forKey:@"antennaMax"];
					[infoString setObject:[NSNumber numberWithInt:self.scanPower] forKey:@"pScanPower"];
          [infoString setObject:[NSNumber numberWithInt:invCommand.outputPower] forKey:@"dScanPower"];
					//[infoString setObject:[NSNumber numberWithInt:[invCommand.outputPower]] forKey:@"antennaMax"];

					//[dataArray addObject:infoString];
					// Dictionary with several kay/value pairs and the above array of arrays
					NSDictionary *dict = @{@"data" : infoString, @"errorMsg" : errorMsg, @"status" : status};
					// Dictionary convertable to JSON ?
					if ([NSJSONSerialization isValidJSONObject:dict])
					{
							// Serialize the dictionary
							json = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:&error];
							if (json != nil && error == nil)
							{
								jsonMsg = [[NSString alloc] initWithData:json encoding:NSUTF8StringEncoding];
								//[jsonMsg release];// ARC forbids explicit message send of 'release'
							}
					}
					echo = jsonMsg;
					pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:echo];
			}
			else {
				status = @"false";
				errorMsg = @"Device not connected.";
				NSDictionary *dict = @{@"data" : [[NSMutableArray alloc] init], @"errorMsg" : errorMsg, @"status" : status};

				if ([NSJSONSerialization isValidJSONObject:dict])
				{
						// Serialize the dictionary
						json = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:&error];
						jsonMsg = [[NSString alloc] initWithData:json encoding:NSUTF8StringEncoding];
				}
					pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:jsonMsg];
			}
		}
		[delegate sendPluginResult:pluginResult callbackId:command.callbackId];
		[self removeSyncAndAddAsyncResponder];
}

- (void)scanRFIDs:(CDVInvokedUrlCommand*)command commandDelegate:(NSObject<CDVCommandDelegate>*)delegate
{
	__block CDVPluginResult* pluginResult = nil;
  bool useAscii = [[command.arguments objectAtIndex:0] boolValue];

	TSLAsciiCommander* commander = [self getCommander];
	NSError *error = nil;
	NSString *status = @"true";
	NSString *errorMsg = @"";
	NSData *json = nil;
	NSString *jsonMsg = nil;
	if ([commander isConnected]) {
			[self removeAsyncAndAddSyncResponder];

			// Add the inventory responder to the commander's responder chain
			 TSLInventoryCommand *invCommand = [TSLInventoryCommand synchronousCommand];
			 invCommand.takeNoAction = TSL_TriState_NO;
			 //invCommand.includeDateTime = TSL_TriState_YES;
       invCommand.includeEPC = TSL_TriState_YES;
       //invCommand.includeIndex = TSL_TriState_YES;
       //invCommand.includePC = TSL_TriState_YES;
       //invCommand.includeChecksum = TSL_TriState_YES;
       invCommand.includeTransponderRSSI = TSL_TriState_YES;
       //invCommand.useFastId = self.fastIdSwitch.isOn ? TSL_TriState_YES : TSL_TriState_NO;


			if(self.scanPower > -1) {
				 invCommand.outputPower = self.scanPower;
			}
    // Add self as the transponder delegate
    invCommand.transponderReceivedDelegate = self;

		// Pulling the Reader trigger will generate inventory responses that are not from the library.
    // To ensure these are also seen requires explicitly requesting handling of non-library command responses
    invCommand.captureNonLibraryResponses = YES;
		//__block int transpondersSeen = 0;

		NSMutableArray *dataArray = [[NSMutableArray alloc] init];

		invCommand.transponderDataReceivedBlock = ^(TSLTransponderData *transponder, BOOL moreAvailable)
    {
			NSString* epcVal = transponder.epc;
			if(useAscii){
				 epcVal = [self getAscii:epcVal];
			}
			NSMutableDictionary *resultMessage = [[NSMutableDictionary alloc] init];
      [resultMessage setObject:@"rfid" forKey:@"type"];
      [resultMessage setObject:epcVal forKey:@"id"];
			[resultMessage setObject:(transponder.rssi == nil ) ? @"n/a" : [NSString stringWithFormat:@"%3d", transponder.rssi.intValue] forKey:@"RSSI"];
			[dataArray addObject:resultMessage];
    };
		[commander executeCommand:invCommand];
		// Dictionary with several kay/value pairs and the above array of arrays
		NSDictionary *dict = @{@"data" : dataArray, @"errorMsg" : errorMsg, @"status" : status};
		// Dictionary convertable to JSON ?
		if ([NSJSONSerialization isValidJSONObject:dict])
		{
				// Serialize the dictionary
				json = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:&error];
				if (json != nil && error == nil)
				{
					jsonMsg = [[NSString alloc] initWithData:json encoding:NSASCIIStringEncoding];
					//[jsonMsg release];// ARC forbids explicit message send of 'release'
				}
		}

		pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:jsonMsg];
		} else {
			status = @"false";
			errorMsg = @"Device not connected.";
			NSDictionary *dict = @{@"data" : [[NSMutableArray alloc] init], @"errorMsg" : errorMsg, @"status" : status};

			if ([NSJSONSerialization isValidJSONObject:dict])
			{
					// Serialize the dictionary
					json = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:&error];
					jsonMsg = [[NSString alloc] initWithData:json encoding:NSUTF8StringEncoding];
			}
				pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:jsonMsg];
		}
		[delegate sendPluginResult:pluginResult callbackId:command.callbackId];
		[self removeSyncAndAddAsyncResponder];
}

- (void)search:(CDVInvokedUrlCommand*)command commandDelegate:(NSObject<CDVCommandDelegate>*)delegate
{
    NSString* tagID = [command.arguments objectAtIndex:0];
		bool useAscii = [[command.arguments objectAtIndex:1] boolValue];

		__block CDVPluginResult* pluginResult = nil;
		TSLAsciiCommander* commander = [self getCommander];
		NSError *error = nil;
		NSString *status = @"true";
		NSString *errorMsg = @"";
		NSData *json = nil;
		NSString *jsonMsg = nil;

		if (tagID != nil && [tagID length] > 0 && [commander isConnected]) {
				[self removeAsyncAndAddSyncResponder];
				// Add the inventory responder to the commander's responder chain
				 TSLInventoryCommand *invCommand = [TSLInventoryCommand synchronousCommand];;
	       invCommand.includeEPC = TSL_TriState_YES;
	       invCommand.includeTransponderRSSI = TSL_TriState_YES;
				 invCommand.takeNoAction = TSL_TriState_NO;
				 if(self.scanPower > -1) {
	 				 invCommand.outputPower = self.scanPower;
	 			 }

	    // Add self as the transponder delegate
	    invCommand.transponderReceivedDelegate = self;
	    invCommand.captureNonLibraryResponses = YES;

			NSMutableArray *dataArray = [[NSMutableArray alloc] init];
			invCommand.transponderDataReceivedBlock = ^(TSLTransponderData *transponder, BOOL moreAvailable)
		    {
					NSString* epcVal = transponder.epc;
					if(useAscii){
						 epcVal = [self getAscii:epcVal];
					}
					if ([epcVal isEqualToString:tagID])
					{
					   NSMutableDictionary *resultMessage = [[NSMutableDictionary alloc] init];
              [resultMessage setObject:@"rfid" forKey:@"type"];
              [resultMessage setObject:epcVal forKey:@"id"];
         			[resultMessage setObject:(transponder.rssi == nil ) ? @"n/a" : [NSString stringWithFormat:@"%3d", transponder.rssi.intValue] forKey:@"RSSI"];
  						[dataArray addObject:resultMessage];
					}
		    };

			[commander executeCommand:invCommand];
			NSDictionary *dict = @{@"data" : dataArray, @"errorMsg" : errorMsg, @"status" : status};
			// Dictionary convertable to JSON ?
			if ([NSJSONSerialization isValidJSONObject:dict])
			{
					// Serialize the dictionary
					json = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:&error];
					if (json != nil && error == nil)
					{
						jsonMsg = [[NSString alloc] initWithData:json encoding:NSASCIIStringEncoding];
						//[jsonMsg release];// ARC forbids explicit message send of 'release'
					}
			}
			pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:jsonMsg];
			} else {
				status = @"false";
				errorMsg = @"Device not connected.";
				NSDictionary *dict = @{@"data" : [[NSMutableArray alloc] init], @"errorMsg" : errorMsg, @"status" : status};

				if ([NSJSONSerialization isValidJSONObject:dict]) {
						// Serialize the dictionary
						json = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:&error];
						jsonMsg = [[NSString alloc] initWithData:json encoding:NSUTF8StringEncoding];
				}
					pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:jsonMsg];
			}
			[delegate sendPluginResult:pluginResult callbackId:command.callbackId];
			[self removeSyncAndAddAsyncResponder];
}

- (void)setOutputPower:(CDVInvokedUrlCommand*)command commandDelegate:(NSObject<CDVCommandDelegate>*)delegate
{
	CDVPluginResult* pluginResult = nil;
  NSInteger newPower = [[command.arguments objectAtIndex:0] intValue];
  NSLog(@" me called setOutputPower");
	TSLAsciiCommander* commander = [self getCommander];
	NSMutableString *msg = [NSMutableString stringWithFormat:@""];
	if([commander isConnected]){
      NSInteger minPower = [TSLInventoryCommand minimumOutputPower];
      NSInteger maxPower = [TSLInventoryCommand maximumOutputPower];
      [self removeAsyncAndAddSyncResponder];
      if(newPower >= minPower && newPower <= maxPower){
        NSInteger oldPowerVal = self.scanPower;
        self.scanPower = newPower;
        TSLInventoryCommand* invCommand = [TSLInventoryCommand synchronousCommand];
        invCommand.takeNoAction = TSL_TriState_YES;
        invCommand.includeEPC = TSL_TriState_YES;
        invCommand.includeTransponderRSSI = TSL_TriState_YES;
        invCommand.captureNonLibraryResponses = YES;
        invCommand.outputPower=newPower;
        NSLog(@" me called setOutputPower new power %d",newPower);
        [commander executeCommand:invCommand];
        [msg appendFormat:@"Scan power set from %d", oldPowerVal];
				[msg appendFormat:@" to %d",newPower];
			}else {
				[msg appendFormat:@"Scan power %d",newPower];
				[msg appendFormat:@" is not in device range  %d",[TSLInventoryCommand minimumOutputPower]];
				[msg appendFormat:@" to  %d",[TSLInventoryCommand maximumOutputPower]];
      }
			pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:msg];
	}else{
		  [msg stringByAppendingString:@"Device is not connected."];
		  pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:msg];
	}
	[delegate sendPluginResult:pluginResult callbackId:command.callbackId];
  [self removeSyncAndAddAsyncResponder];
}

//The following methods convert HEX to ASCII
- (NSString *)getAscii:(NSString *) hexString
{
	    // The hex codes should all be two characters.
	    if (([hexString length] % 2) != 0){
				  return nil;
			}
	    NSMutableString *string = [NSMutableString string];

	    for (NSInteger i = 0; i < [hexString length]; i += 2) {

	        NSString *hex = [hexString substringWithRange:NSMakeRange(i, 2)];
	        NSInteger decimalValue = 0;
	        sscanf([hex UTF8String], "%x", &decimalValue);
	        [string appendFormat:@"%c", decimalValue];

	    }
	    return string;
}

- (void)subscribeScanner:(CDVInvokedUrlCommand*)command commandDelegate:(NSObject<CDVCommandDelegate>*)delegate
{
		bool useAscii = [[command.arguments objectAtIndex:0] boolValue];
    subsCmdDelegate = delegate;
		TSLAsciiCommander* commander = [self getCommander];
		__block NSError *error = nil;
		__block NSString* status = @"subscribing";
		NSString *errorMsg = @"";
		__block NSData *json = nil;
		__block NSString *jsonMsg = nil;

		if ([commander isConnected] && _asyncCommand == nil) {
      NSLog(@" me called subscribeScanner - _asyncCommand nil");
         _asyncCommand = command;
				 _inventoryResponder = [[TSLInventoryCommand alloc] init];
	       _inventoryResponder.includeEPC = TSL_TriState_YES;
	       _inventoryResponder.includeTransponderRSSI = TSL_TriState_YES;

				if(self.scanPower > -1) {
					 _inventoryResponder.outputPower = [self scanPower];
				}

				_inventoryResponder.transponderReceivedDelegate = self;
	    	_inventoryResponder.captureNonLibraryResponses = YES;

			NSMutableArray *dataArray = [[NSMutableArray alloc] init];

			_inventoryResponder.transponderDataReceivedBlock = ^(TSLTransponderData *transponder, BOOL moreAvailable)
	    {
				NSString* epcVal = transponder.epc;
					if(useAscii){
						 epcVal = [self getAscii:epcVal];
					}
				NSMutableDictionary *resultMessage = [[NSMutableDictionary alloc] init];
        [resultMessage setObject:@"rfid" forKey:@"type"];
        [resultMessage setObject:epcVal forKey:@"id"];
  			[resultMessage setObject:(transponder.rssi == nil ) ? @"n/a" : [NSString stringWithFormat:@"%3d", transponder.rssi.intValue] forKey:@"RSSI"];
				[dataArray addObject:resultMessage];

				if(!moreAvailable) {
							NSDictionary *dict = @{@"data" : dataArray, @"errorMsg" : errorMsg, @"status" : status};
							if ([NSJSONSerialization isValidJSONObject:dict])
							{
									json = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:&error];
									if (json != nil && error == nil)
									{
										jsonMsg = [[NSString alloc] initWithData:json encoding:NSASCIIStringEncoding];
									}
							}
							_asyncPluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:jsonMsg];
							// here we tell Cordova not to cleanup the callback id after sendPluginResult()
						 [_asyncPluginResult setKeepCallbackAsBool:YES];
						 [delegate sendPluginResult:_asyncPluginResult callbackId:_asyncCommand.callbackId];
						 [dataArray removeAllObjects];
				}
			};

			_barcodeResponder = [[TSLBarcodeCommand alloc] init];
			_barcodeResponder.barcodeReceivedDelegate = self;
			_barcodeResponder.captureNonLibraryResponses = YES;
      [self removeSyncAndAddAsyncResponder];

        _asyncPluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"Scanner subscribed"];
  		 [_asyncPluginResult setKeepCallbackAsBool:YES];
  		 [delegate sendPluginResult:_asyncPluginResult callbackId:_asyncCommand.callbackId];

     } else if([commander isConnected] && _asyncCommand != nil){
				status = @"true";
				errorMsg = @"DEVICE IS ALREADY SUBSCRIBED";
				NSDictionary *dict = @{@"data" : [[NSMutableArray alloc] init], @"errorMsg" : errorMsg, @"status" : status};

				if ([NSJSONSerialization isValidJSONObject:dict])
				{
						json = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:&error];
						jsonMsg = [[NSString alloc] initWithData:json encoding:NSUTF8StringEncoding];
				}
					_asyncPluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:jsonMsg];
					[_asyncPluginResult setKeepCallbackAsBool:YES];
					[delegate sendPluginResult:_asyncPluginResult callbackId:_asyncCommand.callbackId];
			}
      else {
        status = @"false";
        errorMsg = @"DEVICE IS NOT CONNECTED.";
        NSDictionary *dict = @{@"data" : [[NSMutableArray alloc] init], @"errorMsg" : errorMsg, @"status" : status};

        if ([NSJSONSerialization isValidJSONObject:dict])
        {
            json = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:&error];
            jsonMsg = [[NSString alloc] initWithData:json encoding:NSUTF8StringEncoding];
        }
          _asyncPluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:jsonMsg];
          [_asyncPluginResult setKeepCallbackAsBool:YES];
          [delegate sendPluginResult:_asyncPluginResult callbackId:_asyncCommand.callbackId];
      }
}

- (void) unsubscribeScanner:(CDVInvokedUrlCommand*)command commandDelegate:(NSObject<CDVCommandDelegate>*)delegate{
    CDVPluginResult* unsubscribePluginResult = nil;
		if([self.commander isConnected] && _asyncPluginResult != nil) {
			[self removeAsyncResponder];
			_inventoryResponder = nil;
			_barcodeResponder = nil;
      _asyncPluginResult=nil;
      _asyncCommand = nil;

			unsubscribePluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"Responders removed"];
			[unsubscribePluginResult setKeepCallbackAsBool:NO];
	    [delegate sendPluginResult:unsubscribePluginResult callbackId:command.callbackId];
		}
}

-(void) startSearch:(CDVInvokedUrlCommand*)command commandDelegate:(NSObject<CDVCommandDelegate>*)delegate {
        TSLAsciiCommander* commander = [self getCommander];
        NSString* tagID = [command.arguments objectAtIndex:0];
        bool useAscii = [[command.arguments objectAtIndex:1] boolValue];
        __block NSError *error = nil;
    		__block NSString* status = @"subscribing";
    		NSString *errorMsg = @"";
    		__block NSData *json = nil;
    		__block NSString *jsonMsg = nil;

        if ([commander isConnected]) {
             [self removeAsyncResponder];
             if(_inventorySearchResponder == nil){
               _inventorySearchResponder = [[TSLInventoryCommand alloc] init];
               _inventorySearchResponder.takeNoAction = TSL_TriState_NO;
               _inventorySearchResponder.includeTransponderRSSI = TSL_TriState_YES;

               if(self.scanPower > -1) {
       					 _inventorySearchResponder.outputPower = [self scanPower];
       				 }
               _inventorySearchResponder.inventoryOnly = TSL_TriState_YES;
               _inventorySearchResponder.queryTarget = TSL_QueryTarget_B;
               _inventorySearchResponder.querySession = TSL_QuerySession_S0;
               _inventorySearchResponder.selectAction = TSL_SelectAction_DeassertSetB_AssertSetA;
               _inventorySearchResponder.selectTarget = TSL_SelectTarget_S0;
               _inventorySearchResponder.selectBank = TSL_DataBank_ElectronicProductCode;

               NSString* tagIDTemp = tagID;
               if(useAscii){
     						 tagIDTemp = [self getAscii:tagID];
     					 }
               _inventorySearchResponder.selectData = tagIDTemp;
               _inventorySearchResponder.selectOffset = 0020;
               _inventorySearchResponder.selectLength = 40;
               _inventorySearchResponder.captureNonLibraryResponses = YES;

               _inventorySearchResponder.transponderReceivedDelegate = self;

               [self.commander addResponder:_inventorySearchResponder];
               NSMutableArray *dataArray = [[NSMutableArray alloc] init];
         			//[self removeSyncAndAddAsyncResponder];
               _inventorySearchResponder.transponderDataReceivedBlock = ^(TSLTransponderData *transponder, BOOL moreAvailable)
         	    {
         				NSString* epcVal = transponder.epc;
         					if(useAscii){
         						 epcVal = [self getAscii:epcVal];
         					}
                  if ([epcVal isEqualToString:tagID]) {
               				NSMutableDictionary *resultMessage = [[NSMutableDictionary alloc] init];
                      [resultMessage setObject:@"rfid" forKey:@"type"];
                      [resultMessage setObject:epcVal forKey:@"id"];
                			[resultMessage setObject:(transponder.rssi == nil ) ? @"n/a" : [NSString stringWithFormat:@"%3d", transponder.rssi.intValue] forKey:@"RSSI"];
               				[dataArray addObject:resultMessage];
                  }
           				if(!moreAvailable) {
           							NSDictionary *dict = @{@"data" : dataArray, @"errorMsg" : errorMsg, @"status" : status};
           							if ([NSJSONSerialization isValidJSONObject:dict])
           							{
           									json = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:&error];
           									if (json != nil && error == nil)
           									{
           										jsonMsg = [[NSString alloc] initWithData:json encoding:NSASCIIStringEncoding];
           									}
           							}
           							_asyncSearchPluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:jsonMsg];
           							// here we tell Cordova not to cleanup the callback id after sendPluginResult()
           						 [_asyncSearchPluginResult setKeepCallbackAsBool:YES];
           						 [delegate sendPluginResult:_asyncSearchPluginResult callbackId:command.callbackId];
           						 [dataArray removeAllObjects];
           				}
         			  };}
                _asyncSearchPluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:jsonMsg];
               [_asyncSearchPluginResult setKeepCallbackAsBool:YES];

               [delegate sendPluginResult:_asyncSearchPluginResult callbackId:command.callbackId];
         			}
              else if([commander isConnected] && _inventorySearchResponder != nil){
                  status = @"false";
                  errorMsg = @"SEARCH IS ALREADY ACTIVATED.";
                  NSDictionary *dict = @{@"data" : [[NSMutableArray alloc] init], @"errorMsg" : errorMsg, @"status" : status};

                  if ([NSJSONSerialization isValidJSONObject:dict]) {
                      // Serialize the dictionary
                      json = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:&error];
                      jsonMsg = [[NSString alloc] initWithData:json encoding:NSUTF8StringEncoding];
                  }
                    _asyncSearchPluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:jsonMsg];
              }
              else {
         				status = @"false";
         				errorMsg = DEVICE_IS_NOT_CONNECTED;
         				NSDictionary *dict = @{@"data" : [[NSMutableArray alloc] init], @"errorMsg" : errorMsg, @"status" : status};

         				if ([NSJSONSerialization isValidJSONObject:dict]) {
         						// Serialize the dictionary
         						json = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:&error];
         						jsonMsg = [[NSString alloc] initWithData:json encoding:NSUTF8StringEncoding];
         				}
         					_asyncSearchPluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:jsonMsg];
         			}
        		 [_asyncSearchPluginResult setKeepCallbackAsBool:YES];
        		 [delegate sendPluginResult:_asyncSearchPluginResult callbackId:command.callbackId];
}

-(void) stopSearch:(CDVInvokedUrlCommand*)command commandDelegate:(NSObject<CDVCommandDelegate>*)delegate{
      TSLAsciiCommander* commander = [self getCommander];
      CDVPluginResult* pluginResult = nil;
      if ([commander isConnected]) {
          if(_inventorySearchResponder != nil) {
              [self.commander removeResponder:_inventorySearchResponder];
              pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"REMOVING SEARCH RESPONDER"];
              [pluginResult setKeepCallbackAsBool:YES];
              [delegate sendPluginResult:pluginResult callbackId:command.callbackId];
          }
          _inventorySearchResponder = nil;
          _asyncSearchPluginResult = nil;
          [self addAsyncResponder];

          pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"SEARCH DEACTIVATED"];
          [delegate sendPluginResult:pluginResult callbackId:command.callbackId];
      }
      else {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:DEVICE_IS_NOT_CONNECTED];
        [delegate sendPluginResult:pluginResult callbackId:command.callbackId];
      }
}

- (void)removeAsyncAndAddSyncResponder {
  NSLog(@" me called removeAsyncAndAddSyncResponder");
	  [self removeAsyncResponder];
		[self.commander addSynchronousResponder];
}

- (void)removeSyncAndAddAsyncResponder {
  NSLog(@" me called removeSyncAndAddAsyncResponder");
	[self.commander removeSynchronousResponder];
	[self addAsyncResponder];
}

- (void)removeAsyncResponder {
  NSLog(@" me called removeAsyncResponder");
				if(_inventoryResponder != nil) {
					 [self.commander removeResponder:_inventoryResponder];
				}
        if(_barcodeResponder != nil){
          [self.commander removeResponder:_barcodeResponder];
        }
}

- (void)addAsyncResponder {
  NSLog(@" me called addAsyncResponder");
				if(_inventoryResponder != nil) {
					 [self.commander addResponder:_inventoryResponder];
				}
        if(_barcodeResponder != nil) {
           [self.commander addResponder:_barcodeResponder];
				}
}

-(void)barcodeReceived:(NSString *)data
{
  NSLog(@" me called barcodeReceived");
  TSLAsciiCommander* commander = [self getCommander];
  __block NSError *error = nil;
  __block NSString* status = @"subscribing";
  NSString *errorMsg = @"";
  __block NSData *json = nil;
  __block NSString *jsonMsg = nil;
    if(data){
      NSMutableArray *bcDataArray = [[NSMutableArray alloc] init];
      NSMutableDictionary *bcResultMessage = [[NSMutableDictionary alloc] init];
      [bcResultMessage setObject:@"barcode" forKey:@"type"];
      [bcResultMessage setObject:data forKey:@"id"];
      [bcDataArray addObject:bcResultMessage];

      NSDictionary *bcDict = @{@"data" : bcDataArray, @"errorMsg" : errorMsg, @"status" : status};
      if ([NSJSONSerialization isValidJSONObject:bcDict])
      {
          json = [NSJSONSerialization dataWithJSONObject:bcDict options:NSJSONWritingPrettyPrinted error:&error];
          if (json != nil && error == nil)
          {
            jsonMsg = [[NSString alloc] initWithData:json encoding:NSUTF8StringEncoding];
          }
          _asyncPluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:jsonMsg];
         [_asyncPluginResult setKeepCallbackAsBool:YES];
         [subsCmdDelegate sendPluginResult:_asyncPluginResult callbackId:_asyncCommand.callbackId];
         [bcDataArray removeAllObjects];
      }
    }
}

@end


@interface RFIDConnector : CDVPlugin {
  // Member variables go here.
   NSString *scannerType;
   TSLScanner *tslScanner;
}
@property (nonatomic,retain) TSLScanner *tslScanner;

+ (id)sharedTSLInstance;

- (void)getDeviceList:(CDVInvokedUrlCommand*)command;
- (void)connect:(CDVInvokedUrlCommand*)command;
- (void)isConnected:(CDVInvokedUrlCommand*)command;
- (void)disconnect:(CDVInvokedUrlCommand*)command;
- (void)getDeviceInfo:(CDVInvokedUrlCommand*)command;
- (void)scanRFIDs:(CDVInvokedUrlCommand*)command;
- (void)search:(CDVInvokedUrlCommand*)command;
- (void)setOutputPower:(CDVInvokedUrlCommand*)command;
- (void)subscribeScanner:(CDVInvokedUrlCommand*)command;
- (void)unsubscribeScanner:(CDVInvokedUrlCommand*)command;
- (void)startSearch:(CDVInvokedUrlCommand*)command;
- (void)stopSearch:(CDVInvokedUrlCommand*)command;

@end

@implementation RFIDConnector{
  
}

+ (id)sharedTSLInstance {
static TSLScanner *sharedTSLInstance = nil;
static dispatch_once_t onceToken;
dispatch_once(&onceToken, ^{
sharedTSLInstance =[[TSLScanner alloc]init];
});
return sharedTSLInstance;
}

- (void)getDeviceList:(CDVInvokedUrlCommand*)command{
	NSLog(@"getDeviceList in Scanner");
    CDVPluginResult* pluginResult = nil;
    if (command != nil) {
			NSArray* _currentAccessories = [[EAAccessoryManager sharedAccessoryManager] connectedAccessories];
			NSMutableArray *dataArray = [[NSMutableArray alloc] init];
			//dataArray = [NSMutableArray arrayWithObjects:@"",nil];
			NSMutableDictionary *accessories = nil;
			for (EAAccessory *obj in _currentAccessories)
			    {
						 accessories = [[NSMutableDictionary alloc] init];
						 // Add objects to a dictionary indexed by keys
						 [accessories setObject:obj.name forKey:@"name"];
						 [accessories setObject:obj.serialNumber forKey:@"deviceID"];
					   [dataArray addObject:accessories];
			    }
					NSError *error = nil;
					NSString *status = @"true";
					NSString *errorMsg = @"";
					NSData *json = nil;
					NSString *jsonMsg = nil;
					if (!dataArray || !dataArray.count){
						  status = @"false";
							errorMsg = @"Bluetooth connection is not enabled or device is not paired.";
					}
							// Dictionary with several kay/value pairs and the above array of arrays
							NSDictionary *dict = @{@"data" : dataArray, @"errorMsg" : errorMsg, @"status" : status};
							// Dictionary convertable to JSON ?
							if ([NSJSONSerialization isValidJSONObject:dict])
							{
								  // Serialize the dictionary
								  json = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:&error];
								  if (json != nil && error == nil)
								  {
								    jsonMsg = [[NSString alloc] initWithData:json encoding:NSUTF8StringEncoding];
								    //[jsonMsg release];// ARC forbids explicit message send of 'release'
								  }
							}
			  pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:jsonMsg];
    } else {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
    }
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    
}

- (void)connect:(CDVInvokedUrlCommand*)command{
   scannerType = [command.arguments objectAtIndex:0];
  if([scannerType isEqualToString:@"TSL"]) {
    tslScanner=[RFIDConnector sharedTSLInstance];
     NSLog(@"getDeviceList in RFIDConnector tsl");
     [tslScanner connect:command commandDelegate:self.commandDelegate];
  }    
}
- (void)isConnected:(CDVInvokedUrlCommand*)command{
  // ZebraScanner *zebraScanner = [[ZebraScanner alloc]init];
  // TSLScanner *tslScanner  = [[TSLScanner alloc]init];
  // NSLog(@"isConnected in RFIDConnector 1");
  // NSString *scannerType = @"ZEBRA";
  if([scannerType isEqualToString:@"TSL"]) {
     NSLog(@"isConnected in RFIDConnector tsl");
     [tslScanner isConnected:command commandDelegate:self.commandDelegate];
  }
  // NSLog(@"isConnected in RFIDConnector");
  //[scanner isConnected:command

}
- (void)disconnect:(CDVInvokedUrlCommand*)command{
  if([scannerType isEqualToString:@"TSL"]) {
     NSLog(@"isConnected in RFIDConnector tsl");
     [tslScanner disconnect:command commandDelegate:self.commandDelegate];
  }
}
- (void)getDeviceInfo:(CDVInvokedUrlCommand*)command{
  if([scannerType isEqualToString:@"TSL"]) {
     NSLog(@"isConnected in RFIDConnector tsl");
     [tslScanner getDeviceInfo:command commandDelegate:self.commandDelegate];
  }
}
- (void)scanRFIDs:(CDVInvokedUrlCommand*)command{
  if([scannerType isEqualToString:@"TSL"]) {
     NSLog(@"isConnected in RFIDConnector tsl");
     [tslScanner scanRFIDs:command commandDelegate:self.commandDelegate];
  }
}
- (void)search:(CDVInvokedUrlCommand*)command{
 if([scannerType isEqualToString:@"TSL"]) {
     NSLog(@"isConnected in RFIDConnector tsl");
     [tslScanner search:command commandDelegate:self.commandDelegate];
  }
}
- (void)setOutputPower:(CDVInvokedUrlCommand*)command{
  if([scannerType isEqualToString:@"TSL"]) {
     NSLog(@"isConnected in RFIDConnector tsl");
     [tslScanner setOutputPower:command commandDelegate:self.commandDelegate];
  }
  
}

- (void)subscribeScanner:(CDVInvokedUrlCommand*)command{
  if([scannerType isEqualToString:@"TSL"]) {
     NSLog(@"isConnected in RFIDConnector tsl");
     [tslScanner subscribeScanner:command commandDelegate:self.commandDelegate];
  }   
}
- (void)unsubscribeScanner:(CDVInvokedUrlCommand*)command{
  if([scannerType isEqualToString:@"TSL"]) {
     NSLog(@"isConnected in RFIDConnector tsl");
     [tslScanner unsubscribeScanner:command commandDelegate:self.commandDelegate];
  }
}
- (void)startSearch:(CDVInvokedUrlCommand*)command{
  if([scannerType isEqualToString:@"TSL"]) {
     NSLog(@"isConnected in RFIDConnector tsl");
     [tslScanner startSearch:command commandDelegate:self.commandDelegate];
  }    
}
- (void)stopSearch:(CDVInvokedUrlCommand*)command{
  if([scannerType isEqualToString:@"TSL"]) {
     NSLog(@"isConnected in RFIDConnector tsl");
     [tslScanner stopSearch:command commandDelegate:self.commandDelegate];
  } 
}

@end
