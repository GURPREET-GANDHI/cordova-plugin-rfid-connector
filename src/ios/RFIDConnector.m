/********* BluetoothScanner.m Cordova Plugin Implementation *******/

#import <Cordova/CDV.h>
#import <TSLAsciiCommands/TSLAsciiCommander.h>
#import <TSLAsciiCommands/TSLBatteryStatusCommand.h>
#import <TSLAsciiCommands/TSLVersionInformationCommand.h>
#import <TSLAsciiCommands/TSLTransponderData.h>
#import <TSLAsciiCommands/TSLInventoryCommand.h>
#import <TSLAsciiCommands/TSLBarcodeCommand.h>
#import <TSLAsciiCommands/TSLAntennaParameters.h>
#import <symbolrfid-sdk/RfidAccessParameters.h>
#import <symbolrfid-sdk/RfidSdkApi.h>
#import <symbolrfid-sdk/RfidSdkFactory.h>
#import <symbolrfid-sdk/RfidBatteryEvent.h>
#import <symbolrfid-sdk/RfidTagReportConfig.h>
#import <symbolrfid-sdk/RfidTagData.h>
#import <symbolrfid-sdk/RfidSdkApiDelegate.h>
#import <symbolrfid-sdk/RfidUniqueTagsReport.h>
#import <symbolrfid-sdk/RfidOperEndSummaryEvent.h>
#import <symbolbt-sdk/ISbtSdkApiDelegate.h>
#import <symbolbt-sdk/SbtSdkFactory.h>
#import <symbolbt-sdk/SbtSdkDefs.h>
#import <symbolbt-sdk/SbtScannerInfo.h>
#import <symbolbt-sdk/ISbtSdkApi.h>
#import <symbolbt-sdk/FirmwareUpdateEvent.h>
#import <symbolbt-sdk/RMDAttributes.h>


/* definition of class that implements srfidISdkApiDelegate protocol */
@interface EventReceiver : NSObject <ISbtSdkApiDelegate, srfidISdkApiDelegate>
/* variables */
/* methods definition */
@property (strong) CDVInvokedUrlCommand *command;
@property (strong) CDVInvokedUrlCommand *syncCommand;
@property (strong) NSObject<CDVCommandDelegate> *delegate;
@property (strong) id<srfidISdkApi> apiInstance;
@property (strong) srfidReaderInfo *reader;
@property (strong) NSString *searchTagId;
@property (strong) NSString *isSyncCommand;
@property (assign) BOOL isAscii;
@property (assign) BOOL softPress;
// @property(strong) ZebraScanner *zebraScanner;


// -(instancetype)initWithCallBacks:(CDVInvokedUrlCommand*)command commandDelegate:(NSObject<CDVCommandDelegate>*)delegate;
//
// -(instancetype)initWithCallBacksAndInstance:(CDVInvokedUrlCommand*)command commandDelegate:(NSObject<CDVCommandDelegate>*)delegate instance:(id<srfidISdkApi>)apiInstance reader:(srfidReaderInfo*)reader;

-(instancetype)initWithInstance:(CDVInvokedUrlCommand*)command  syncCommand:(CDVInvokedUrlCommand*)syncCommand commandDelegate:(NSObject<CDVCommandDelegate>*)delegate instance:(id<srfidISdkApi>)apiInstance reader:(srfidReaderInfo*)reader searchTag:(NSString*)searchTagId isAscii:(BOOL)isAscii;

- (void)srfidEventCommunicationSessionEstablished:(srfidReaderInfo*)activeReader;
- (void)srfidEventCommunicationSessionTerminated:(int)readerID;
- (void)srfidEventReaderAppeared:(srfidReaderInfo*)activeReader;
- (void)srfidEventBatteryNotity:(int)readerID aBatteryEvent:(srfidBatteryEvent*)batteryEvent;
- (void)srfidEventReadNotify:(int)readerID aTagData:(srfidTagData*)tagData;
- (void)srfidEventStatusNotify:(int)readerID aEvent:(SRFID_EVENT_STATUS)event aNotification:(id)notificationData;
- (void)srfidEventTriggerNotify:(int)readerID aTriggerEvent:(SRFID_TRIGGEREVENT)triggerEvent;
- (void)srfidEventProximityNotify:(int)readerID aProximityPercent:(int)proximityPercent;

- (void)sbtEventScannerAppeared:(SbtScannerInfo*)availableScanner;
- (void)sbtEventScannerDisappeared:(int)scannerID;
- (void)sbtEventCommunicationSessionEstablished:(SbtScannerInfo*)activeScanner;
- (void)sbtEventCommunicationSessionTerminated:(int)scannerID;
- (void)sbtEventBarcode:(NSString*)barcodeData barcodeType:(int)barcodeType fromScanner:(int)scannerID;
- (void)sbtEventBarcodeData:(NSData*)barcodeData barcodeType:(int)barcodeType fromScanner:(int)scannerID;
- (void)sbtEventFirmwareUpdate:(FirmwareUpdateEvent*)fwUpdateEventObj;

/* TBD */
- (void)sbtEventImage:(NSData*)imageData fromScanner:(int)scannerID;
/* TBD */
- (void)sbtEventVideo:(NSData*)videoFrame fromScanner:(int)scannerID;

@end




/* EventReceiver class: partial implementation */
@implementation EventReceiver


-(instancetype)initWithInstance:(CDVInvokedUrlCommand*)command syncCommand:(CDVInvokedUrlCommand*)syncCommand commandDelegate:(NSObject<CDVCommandDelegate>*)delegate instance:(id<srfidISdkApi>)apiInstance reader:(srfidReaderInfo*)reader searchTag:(NSString*)searchTagId isAscii:(BOOL)isAscii softPress:(BOOL)softPress{
  if((self = [super init])){
    NSLog(@"New Instance Created");
    _syncCommand = syncCommand;
    _command=command;
    _delegate=delegate;
    _apiInstance=apiInstance;
    _reader=reader;
    _searchTagId=searchTagId;
    _isAscii=isAscii;
    _softPress=softPress;
  }
  return self;

}

static int batteryLevel;
static BOOL batteryChargingStatus;
static BOOL isConnected;
static int totalNoOfTags=0;
static int timesTagsRead=0;
static NSMutableArray *dataArray;


-(void)srfidEventCommunicationSessionEstablished:(srfidReaderInfo*)activeReader {
NSLog(@"RFID reader has connected");
isConnected =YES;
}
+(BOOL) isConnected
{
  return isConnected;
}

-(void)srfidEventCommunicationSessionTerminated:(int)readerID
{
  NSLog(@"RFID reader has disconnected");
  isConnected = NO;
}
-(void)srfidEventReaderAppeared:(srfidReaderInfo*)activeReader
{
  NSLog(@"RFID reader has Appeared");
}

- (void)srfidEventBatteryNotity:(int)readerID aBatteryEvent:(srfidBatteryEvent*)batteryEvent
{

  batteryLevel = [batteryEvent getPowerLevel];
  batteryChargingStatus=[batteryEvent getIsCharging];
  NSLog(@"Battery Event Called");
}
+(int) batteryLevel
{
  return batteryLevel;
}
+(BOOL)batteryChargingStatus{
  return batteryChargingStatus;
}

- (void)srfidEventReadNotify:(int)readerID aTagData:(srfidTagData*)tagData {
  timesTagsRead++;
  if(_searchTagId!=nil){
     if([[tagData getTagId] isEqualToString:_searchTagId]  || [[self getAscii:[tagData getTagId]] isEqualToString:_searchTagId]){
        if(_isAscii){
      [self createRFIDJSONObject:[self getAscii:[tagData getTagId]] rssi:[tagData getPeakRSSI]];
        }else{
        [self createRFIDJSONObject:[tagData getTagId] rssi:[tagData getPeakRSSI]];
       }
    }
  }else{
      if(_isAscii){
          [self createRFIDJSONObject:[self getAscii:[tagData getTagId]] rssi:[tagData getPeakRSSI]];
        }else{
          [self createRFIDJSONObject:[tagData getTagId] rssi:[tagData getPeakRSSI]];
        }
      }
}

- (void) createRFIDJSONObject:(NSString*)epc rssi:(int)rssi{
 BOOL isNew =true;
  for (NSMutableDictionary *item in dataArray) {
     NSString* availableId =[item objectForKey:@"id"];
      if([epc isEqual:availableId]){
         isNew =false;
     }
  }
if(isNew){
     NSMutableDictionary *resultMessage = [[NSMutableDictionary alloc] init];
         [resultMessage setObject:@"rfid" forKey:@"type"];
         [resultMessage setObject:epc forKey:@"id"];
         [resultMessage setObject:[NSNumber numberWithInt:rssi] forKey:@"RSSI"];

     [dataArray addObject:resultMessage];
}
  

 

}

- (NSString *)getAscii:(NSString *) hexString
{      NSString * str = hexString;
      NSMutableString * newString = [[NSMutableString alloc] init];
      int i = 0;
      while (i < [str length]){
          NSString * hexChar = [str substringWithRange: NSMakeRange(i, 2)];
          int value = 0;

          sscanf([hexChar cStringUsingEncoding:NSASCIIStringEncoding], "%x", &value);
          [newString appendFormat:@"%c", (char)value];
          i+=2;
      }
      NSLog(@"%@", newString);
      return newString;
}




- (void)srfidEventStatusNotify:(int)readerID aEvent:(SRFID_EVENT_STATUS)event aNotification:(id)notificationData {
   NSError *error = nil;
   NSString* status = @"true";
   NSString *errorMsg = @"";
   NSData *json = nil;
   NSString *jsonMsg = nil;
   NSLog(@"Radio operation has %@\n", ((SRFID_EVENT_STATUS_OPERATION_START == event) ? @"started" : @"stopped"));

      if(SRFID_EVENT_STATUS_OPERATION_START==event){
        dataArray = [[NSMutableArray alloc] init];
      }

      if(SRFID_EVENT_STATUS_OPERATION_END_SUMMARY ==event){
      // NSString *connectionMsg=tagsData;
	    NSDictionary *dict = @{@"data" : dataArray, @"errorMsg" : errorMsg, @"status" : status};
    if ([NSJSONSerialization isValidJSONObject:dict])
    {
        json = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:&error];
        if (json != nil && error == nil)
        {
          jsonMsg = [[NSString alloc] initWithData:json encoding:NSASCIIStringEncoding];
        }
    }
      NSUInteger dataLength = [dataArray count];
        if(dataLength > 0 ){
        CDVPluginResult* tagPluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:jsonMsg];
        [tagPluginResult setKeepCallbackAsBool:YES];
         if(_softPress){
        //  [tagPluginResult setKeepCallbackAsBool:NO];
         [_delegate sendPluginResult:tagPluginResult callbackId:_syncCommand.callbackId];
         _softPress =NO;
         }else{
            //  [tagPluginResult setKeepCallbackAsBool:YES];
             [_delegate sendPluginResult:tagPluginResult callbackId:_command.callbackId];
         }
         
        [dataArray removeAllObjects];
      }

  }
}
+(int)totalNoOfTags
{
  return totalNoOfTags;
}

- (void)srfidEventTriggerNotify:(int)readerID aTriggerEvent:(SRFID_TRIGGEREVENT)triggerEvent{
  NSLog(@"Event Trigger Notify");
  srfidReportConfig *report_config =[[srfidReportConfig alloc] init];
  srfidAccessConfig *access_cfg=[[srfidAccessConfig alloc] init];
  NSString *error_response =nil;
  // static EventReceiver *inventoryEventListener;
  // inventoryEventListener  = [[EventReceiver alloc] initWithCallBacks:(CDVInvokedUrlCommand*)command commandDelegate:(NSObject<CDVCommandDelegate>*)delegate];
  NSString *connectionMsg=@"Tags are";
  // CDVPluginResult* handHeldtagPluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:connectionMsg];
  // [_delegate sendPluginResult:tagPluginResult callbackId:_command.callbackId];
  // [handHeldtagPluginResult setKeepCallbackAsBool:YES];
  if(SRFID_TRIGGEREVENT_PRESSED == triggerEvent){
          NSLog(@"Event Trigger Pressed");
          if(_apiInstance !=nil && _reader !=nil){

            [report_config setIncPC:YES];
            [report_config setIncPhase:YES];
            [report_config setIncChannelIndex:YES];
            [report_config setIncRSSI:YES];
            [report_config setIncTagSeenCount:NO];
            [report_config setIncFirstSeenTime:NO];
            [report_config setIncLastSeenTime:NO];
            [access_cfg setPower:270];
            [access_cfg setDoSelect:NO];
            }else{
            NSLog(@"API is not working");
            }

            SRFID_RESULT result=[_apiInstance srfidStartInventory:[_reader getReaderID] aMemoryBank:SRFID_MEMORYBANK_EPC aReportConfig:report_config aAccessConfig:access_cfg aStatusMessage:&error_response];
            if (SRFID_RESULT_SUCCESS == result) {
           
             NSLog(@"Request succeed\n");
//             SRFID_RESULT inventoryStarted =[_apiInstance srfidStopInventory:[_reader getReaderID] aStatusMessage:nil];
//                if(SRFID_RESULT_SUCCESS == inventoryStarted) {
//              dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)),dispatch_get_main_queue(),^{
//                 [_apiInstance srfidStopInventory:[_reader getReaderID] aStatusMessage:nil];
//
//                });
//              }
             }
             else if (SRFID_RESULT_RESPONSE_ERROR == result) {
             NSLog(@"Error response from RFID reader: %@\n", error_response);
			
             }
             else {
             NSLog(@"Request failed\n");
             }

        }

if(SRFID_TRIGGEREVENT_RELEASED == triggerEvent){
        NSLog(@"Event Trigger Released");
       
       SRFID_RESULT response = [_apiInstance srfidStopInventory:[_reader getReaderID] aStatusMessage:nil];
    
                 if(SRFID_RESULT_RESPONSE_ERROR == response){
                      NSLog(@"Inventory succeed\n");
                 }
//        if(SRFID_RESULT_RESPONSE_ERROR == response){
//           dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)),dispatch_get_main_queue(),^{
//                 [_apiInstance srfidStopInventory:[_reader getReaderID] aStatusMessage:nil];
//
//              });
//         }
      }
	  
	
              
        CDVPluginResult* handHeldtagPluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:connectionMsg];
       
        [handHeldtagPluginResult setKeepCallbackAsBool:YES];
}

- (void)srfidEventProximityNotify:(int)readerID aProximityPercent:(int)proximityPercent{

    NSLog(@"proximityPercent: %d", proximityPercent);
    NSString *connectionMsg=@"Tag id:";
    NSString *connectionMsg2 = [connectionMsg stringByAppendingFormat:@"%@ ProximityPercent:%d",_searchTagId,proximityPercent];
   //  CDVPluginResult* tagPluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:connectionMsg2];
   // [tagPluginResult setKeepCallbackAsBool:YES];
   // [_delegate sendPluginResult:tagPluginResult callbackId:_command.callbackId];

}

- (void)sbtEventScannerAppeared:(SbtScannerInfo*)availableScanner{
    NSLog(@"SCANNER reader has Appeared");

}
- (void)sbtEventScannerDisappeared:(int)scannerID{
  NSLog(@"SCANNER reader has DISAPPESRED");

}
- (void)sbtEventCommunicationSessionEstablished:(SbtScannerInfo*)activeScanner{
  NSLog(@"Zebra Scanner Connection Established!!");
}

- (void)sbtEventCommunicationSessionTerminated:(int)scannerID{
  NSLog(@"SCANNER Communication Terminated");

}
- (void)sbtEventBarcode:(NSString*)barcodeData barcodeType:(int)barcodeType fromScanner:(int)scannerID{
    //  NSLog(@"SCANNER barcode data has Appeared");
    //     	NSData *json = nil;
		// 			NSString *jsonMsg = nil;
    //       NSString *status = @"true";
    //       NSString *errorMsg = @"";
    //     [dataArray removeAllObjects];
    //     NSMutableDictionary *resultMessage = [[NSMutableDictionary alloc] init];
    //      [resultMessage setObject:@"barcode" forKey:@"type"];
    //      [resultMessage setObject:barcodeData forKey:@"id"];
    //      dataArray = [[NSMutableArray alloc] init];
    //      [dataArray addObject:resultMessage];
	        
    //       NSDictionary *dict = @{@"data" : dataArray, @"errorMsg" : errorMsg, @"status" : status};
     
    //       json = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:&errorMsg];
    //     if (json != nil)
    //     {
    //       jsonMsg = [[NSString alloc] initWithData:json encoding:NSASCIIStringEncoding];
    //     }
    //     CDVPluginResult* qrPluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:jsonMsg];
    //      [qrPluginResult setKeepCallbackAsBool:YES];
    //      [_delegate sendPluginResult:qrPluginResult callbackId:_command.callbackId];
    //     [dataArray removeAllObjects];
      
}
- (void)sbtEventBarcodeData:(NSData*)barcodeData barcodeType:(int)barcodeType fromScanner:(int)scannerID{
  	    NSLog(@"SCANNER barcode data has Appeared");
        	NSData *json = nil;
					NSString *jsonMsg = nil;
          NSString *status = @"true";
          NSString *errorMsg = @"";
        [dataArray removeAllObjects];
        NSMutableDictionary *resultMessage = [[NSMutableDictionary alloc] init];
        NSString* barcodeString = [[NSString alloc] initWithData:barcodeData encoding:NSUTF8StringEncoding];
         [resultMessage setObject:@"barcode" forKey:@"type"];
         [resultMessage setObject:barcodeString forKey:@"id"];
         dataArray = [[NSMutableArray alloc] init];
         [dataArray addObject:resultMessage];
	        
          NSDictionary *dict = @{@"data" : dataArray, @"errorMsg" : errorMsg, @"status" : status};
     
          json = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:&errorMsg];
        if (json != nil)
        {
          jsonMsg = [[NSString alloc] initWithData:json encoding:NSASCIIStringEncoding];
        }
        CDVPluginResult* qrPluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:jsonMsg];
         [qrPluginResult setKeepCallbackAsBool:YES];
         [_delegate sendPluginResult:qrPluginResult callbackId:_command.callbackId];
        [dataArray removeAllObjects];

}
- (void)sbtEventFirmwareUpdate:(FirmwareUpdateEvent*)fwUpdateEventObj{

}

/* TBD */
- (void)sbtEventImage:(NSData*)imageData fromScanner:(int)scannerID{

}
/* TBD */
- (void)sbtEventVideo:(NSData*)videoFrame fromScanner:(int)scannerID{

}



@end


@interface ZebraScanner : NSObject {
  // Member variables go here.

}



- (void)connect:(CDVInvokedUrlCommand*)command;
- (void)isConnected:(CDVInvokedUrlCommand*)command;
- (void)disconnect:(CDVInvokedUrlCommand*)command;
- (void)getDeviceInfo:(CDVInvokedUrlCommand*)command;
- (void)scanRFIDs:(CDVInvokedUrlCommand*)command;
- (void)search:(CDVInvokedUrlCommand*)command;
- (void)setOutputPower:(CDVInvokedUrlCommand*)command;
- (void)subscribeScanner:(CDVInvokedUrlCommand*)command;
- (void)unsubscribeScanner:(CDVInvokedUrlCommand*)command;
- (void)startSearch:(CDVInvokedUrlCommand*)command commandDelegate:(NSObject<CDVCommandDelegate>*)delegate;
- (void)stopSearch:(CDVInvokedUrlCommand*)command;

@end

__strong id <srfidISdkApi> apiInstance;
__strong id <ISbtSdkApi> scanInstance;
static srfidReaderInfo *reader;
static BOOL isDeviceConnected;
__strong EventReceiver *connectEventListener;
__strong CDVInvokedUrlCommand* asyncCommand;


@implementation ZebraScanner

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
static EventReceiver *batteryEventListener;
static EventReceiver *inventoryEventListener;
static EventReceiver *handheldInvEventListener;


- (void)connect:(CDVInvokedUrlCommand*)command commandDelegate:(NSObject<CDVCommandDelegate>*)delegate
{
   @try{
  NSString* deviceName=[command.arguments objectAtIndex:1];
  __block BOOL isAsciiConnected;
  __block SRFID_RESULT result;
 __block CDVPluginResult* pluginResult = nil;
 __block NSString* connectionMsg;
  NSLog(@"Connect in ZebraScanner");
  if(!isDeviceConnected){
 connectEventListener  = [[EventReceiver alloc] initWithInstance:(CDVInvokedUrlCommand*)command syncCommand:(CDVInvokedUrlCommand*)nil commandDelegate:(NSObject<CDVCommandDelegate>*)delegate instance:(id<srfidISdkApi>)nil  reader:(srfidReaderInfo*)nil searchTag:(NSString*)nil isAscii:(BOOL)nil softPress:(BOOL)nil];
          // initWithCallBacks:(CDVInvokedUrlCommand*)command commandDelegate:(NSObject<CDVCommandDelegate>*)delegate];
    apiInstance = [srfidSdkFactory createRfidSdkApiInstance];
   
    [apiInstance srfidSetOperationalMode:SRFID_OPMODE_MFI];
    [apiInstance srfidSubsribeForEvents:(SRFID_EVENT_SESSION_ESTABLISHMENT | SRFID_EVENT_SESSION_TERMINATION)];
    [apiInstance srfidEnableAutomaticSessionReestablishment:YES];
    [apiInstance srfidSetDelegate:connectEventListener];
    [apiInstance srfidEnableAvailableReadersDetection:YES];
    NSMutableArray *available_readers = [[NSMutableArray alloc] init];
    NSMutableArray *active_readers = [[NSMutableArray alloc] init];
    [apiInstance srfidGetAvailableReadersList:&available_readers];
    [apiInstance srfidGetActiveReadersList:&active_readers];
    NSMutableArray *readers = [[NSMutableArray alloc] init];
    [readers addObjectsFromArray:active_readers];
    [readers addObjectsFromArray:available_readers];
   
          NSString *password =@"";

       for(int i=0;i<[readers count];i++){
          reader = (srfidReaderInfo*)[readers objectAtIndex:i];
          if([[reader getReaderName] isEqualToString:deviceName] || [[reader getReaderName] containsString:deviceName]){

            result = [apiInstance srfidEstablishAsciiConnection:[reader getReaderID] aPassword:password];
            result = [apiInstance srfidEstablishCommunicationSession:[reader getReaderID]];

             dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(4 * NSEC_PER_SEC)),dispatch_get_main_queue(),^{
                  result = [apiInstance srfidEstablishAsciiConnection:[reader getReaderID] aPassword:password];
                  isAsciiConnected =[EventReceiver isConnected];
                  
                  if (SRFID_RESULT_SUCCESS == result && isAsciiConnected) {
                       connectionMsg =@"true";
                       isDeviceConnected=YES;
                     
                      pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:connectionMsg];
                     // connectionMsg = [connectionMsg stringByAppendingString:[NSNumber numberWithInt:[info getReaderID]]];
                   }else{
                     connectionMsg =@"false";
                      pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:connectionMsg];
                      [pluginResult setKeepCallbackAsBool:YES];
                   }
				   [delegate sendPluginResult:pluginResult callbackId:command.callbackId];
				  });  
              }
              else{
                   connectionMsg =@"Device Not Found!";
                   pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:connectionMsg];
                   
                }
            }
         
      }
       else{
       connectionMsg = DEVICE_IS_ALREADY_CONNECTED;
       pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:connectionMsg];
      }

   }
   @catch (NSException *exception){
     NSLog(@"Cought the exception %@",[exception name]);
   }



   @finally{
     NSLog(@"Cleanning up!");
   }
     
}
- (void)isConnected:(CDVInvokedUrlCommand*)command commandDelegate:(NSObject<CDVCommandDelegate>*)delegate{

  BOOL isAsciiConnected =[EventReceiver isConnected];
  NSString* connectionMsg;
  CDVPluginResult* pluginResult ;
if(apiInstance != nil && [reader getReaderID] !=nil){
  if(isAsciiConnected)
  {
    connectionMsg =@"true";
  }else{
    connectionMsg=@"false";
  }
 pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:connectionMsg];
}
else{
  connectionMsg=@"Device not Available!";
  pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:connectionMsg];
  }
  [delegate sendPluginResult:pluginResult callbackId:command.callbackId];

}
- (void)disconnect:(CDVInvokedUrlCommand*)command commandDelegate:(NSObject<CDVCommandDelegate>*)delegate{
NSString* connectionMsg;
    CDVPluginResult* pluginResult;
if(apiInstance != nil && isDeviceConnected){
        [apiInstance srfidUnsubsribeForEvents:SRFID_EVENT_MASK_TRIGGER];
        [apiInstance srfidUnsubsribeForEvents:SRFID_EVENT_MASK_READ];
        [apiInstance srfidUnsubsribeForEvents:SRFID_EVENT_MASK_STATUS_OPERENDSUMMARY];
  SRFID_RESULT result= [apiInstance srfidTerminateCommunicationSession:[reader getReaderID]];
  
    if(SRFID_RESULT_SUCCESS==result){
        connectionMsg=@"true";
        isDeviceConnected=NO;
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:connectionMsg];

      }else{
        connectionMsg=@"false";
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:connectionMsg];
      }
}else{
   connectionMsg=@"Device is not Connected!";
}

[delegate sendPluginResult:pluginResult callbackId:command.callbackId];
}
- (void)getDeviceInfo:(CDVInvokedUrlCommand*)command commandDelegate:(NSObject<CDVCommandDelegate>*)delegate{
 NSString *connectionMsg;
 NSMutableDictionary *infoString = [[NSMutableDictionary alloc] init];
 NSError *error = nil;
 NSString *status = @"true";
 NSString *errorMsg = @"";
 NSData *json = nil;
 NSString *jsonMsg = nil;
 NSString* echo = nil;
 CDVPluginResult* pluginResult = nil;
     
    batteryEventListener  = [[EventReceiver alloc] initWithInstance:(CDVInvokedUrlCommand*)asyncCommand syncCommand:(CDVInvokedUrlCommand*)command commandDelegate:(NSObject<CDVCommandDelegate>*)delegate instance:(id<srfidISdkApi>)apiInstance reader:(srfidReaderInfo*)reader searchTag:(NSString*)nil isAscii:(BOOL)nil softPress:(BOOL)nil];
            // initWithCallBacksAndInstance:(CDVInvokedUrlCommand*)command commandDelegate:(NSObject<CDVCommandDelegate>*)delegate instance:(id<srfidISdkApi>)apiInstance reader:(srfidReaderInfo*)reader];
    [apiInstance srfidSubsribeForEvents:SRFID_EVENT_MASK_BATTERY];
    SRFID_RESULT batteryResult = [apiInstance srfidRequestBatteryStatus:[reader getReaderID]];
    [apiInstance srfidSetDelegate:batteryEventListener];
    // batteryEventListener  = [[EventReceiver alloc] initWithCallBacks:(CDVInvokedUrlCommand*)command commandDelegate:(NSObject<CDVCommandDelegate>*)delegate];
    srfidReaderCapabilitiesInfo *capabilities = [[srfidReaderCapabilitiesInfo alloc] init];
    NSString *error_response = nil;
    SRFID_RESULT result = [apiInstance srfidGetReaderCapabilitiesInfo:[reader getReaderID] aReaderCapabilitiesInfo:&capabilities aStatusMessage:&error_response];
    if (SRFID_RESULT_SUCCESS == result) {
      int batteryLevel =[EventReceiver batteryLevel];
      NSString *batteryCharging = [EventReceiver batteryChargingStatus] ?@"Charging": @"Not Charging";
      [infoString setObject:[capabilities getScannerName] forKey:@"deviceName"];
      [infoString setObject:[NSNumber numberWithInt:batteryLevel] forKey:@"batteryLevel"];
      [infoString setObject:batteryCharging forKey:@"batteryStatus"];
      [infoString setObject:[capabilities getAsciiVersion] forKey:@"hardwareVersion"];
      [infoString setObject:[capabilities getAirProtocolVersion] forKey:@"firmwareVersion"];
      [infoString setObject:[capabilities getManufacturer] forKey:@"manufacturer"];
      [infoString setObject:[capabilities getSerialNumber] forKey:@"serialNumber"];
      [infoString setObject:[NSNumber numberWithInt:[capabilities getMinPower]] forKey:@"antennaMin"];
      [infoString setObject:[NSNumber numberWithInt:[capabilities getMaxPower]] forKey:@"antennaMax"];
      [infoString setObject:[NSNumber numberWithInt:[capabilities getMaxPower]] forKey:@"pScanPower"];
      [infoString setObject:[NSNumber numberWithInt:[capabilities getPowerStep]] forKey:@"dScanPower"];
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
  }else {
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
  [pluginResult setKeepCallbackAsBool:NO];
}
- (void)scanRFIDs:(CDVInvokedUrlCommand*)command commandDelegate:(NSObject<CDVCommandDelegate>*)delegate{
  // bool useAscii=YES;
  bool softPress =YES;
  bool useAscii = [[command.arguments objectAtIndex:0] boolValue];
   SRFID_RESULT result;
  srfidTagData *accessResults =[[srfidTagData alloc] init];
   
  CDVPluginResult* pluginResult;
  NSString *statusMessage=nil;
  NSString *connectionMsg;
  inventoryEventListener  = [[EventReceiver alloc] initWithInstance:(CDVInvokedUrlCommand*)asyncCommand  syncCommand:(CDVInvokedUrlCommand*)command commandDelegate:(NSObject<CDVCommandDelegate>*)delegate instance:(id<srfidISdkApi>)apiInstance reader:(srfidReaderInfo*)reader searchTag:(NSString*)nil isAscii:(BOOL)useAscii softPress:(BOOL)softPress];
  // initWithCallBacks:(CDVInvokedUrlCommand*)command commandDelegate:(NSObject<CDVCommandDelegate>*)delegate];
  srfidUniqueTagsReport* setUniqueTag =[[srfidUniqueTagsReport alloc] init];
  if(apiInstance !=nil && reader !=nil){
    [apiInstance srfidSetDelegate:inventoryEventListener];
    /* subscribe for tag data related events */
    [apiInstance srfidSubsribeForEvents:SRFID_EVENT_MASK_READ];
    /* subscribe for operation start/stop related events */
    [apiInstance srfidSubsribeForEvents:SRFID_EVENT_MASK_STATUS];

    [apiInstance srfidSubsribeForEvents:SRFID_EVENT_MASK_STATUS_OPERENDSUMMARY];
    [setUniqueTag setUniqueTagsReportEnabled:true];
    SRFID_RESULT setUniqeResult =[apiInstance srfidSetUniqueTagReportConfiguration:[reader getReaderID] aUtrConfiguration:setUniqueTag aStatusMessage:&statusMessage];

  srfidAntennaConfiguration *antenna_cfg=[[srfidAccessConfig alloc] init];
  srfidReportConfig *report_config =[[srfidReportConfig alloc] init];
  srfidAccessConfig *access_cfg=[[srfidAccessConfig alloc] init];
  NSString *error_response =nil;

  // SRFID_RESULT resultRegCond=[apiInstance srfidGetRegulatoryConfig:[reader getReaderID] aRegulatoryConfig:&report_config aStatusMessage:&statusMessage];

  [report_config setIncPC:YES];
  [report_config setIncPhase:YES];
  [report_config setIncChannelIndex:YES];
  [report_config setIncRSSI:YES];
  [report_config setIncTagSeenCount:NO];
  [report_config setIncFirstSeenTime:NO];
  [report_config setIncLastSeenTime:NO];
  srfidAntennaConfiguration *oldAntennaCfg=[[srfidAntennaConfiguration alloc] init];
  result =[apiInstance srfidGetAntennaConfiguration:[reader getReaderID] aAntennaConfiguration:&oldAntennaCfg aStatusMessage:&error_response];

if(SRFID_RESULT_SUCCESS != result){
    [access_cfg setPower:270];
    [access_cfg setDoSelect:NO];
} else{
  [access_cfg setPower:[oldAntennaCfg getPower]];
  [access_cfg setDoSelect:[oldAntennaCfg getDoSelect]];
}

  // SRFID_RESULT resultAccessConf =[apiInstance srfidGetAntennaConfiguration:[reader getReaderID] aAntennaConfiguration:&antenna_cfg aStatusMessage:&statusMessage];

// if(SRFID_RESULT_SUCCESS==resultRegCond && SRFID_RESULT_SUCCESS ==resultAccessConf){
//   [access_cfg setPower:[antenna_cfg getPower]];
//   [access_cfg setDoSelect:[antenna_cfg getDoSelect]];
// }
   result=[apiInstance srfidStartInventory:[reader getReaderID] aMemoryBank:SRFID_MEMORYBANK_EPC aReportConfig:report_config aAccessConfig:access_cfg aStatusMessage:&error_response];
  // SRFID_RESULT result = [apiInstance srfidStartRapidRead:[reader getReaderID] aReportConfig:report_config aAccessConfig:access_cfg aStatusMessage:&error_response];
  if (SRFID_RESULT_SUCCESS == result) {
  NSLog(@"Request succeed\n");
  // [apiInstance srfidStopRapidRead:[reader getReaderID] aStatusMessage:nil];
   [apiInstance srfidStopInventory:[reader getReaderID] aStatusMessage:nil];
  }
  else if (SRFID_RESULT_RESPONSE_ERROR == result) {
  NSLog(@"Error response from RFID reader: %@\n", error_response);
  connectionMsg=@"Error response from RFID reader";
  pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:connectionMsg];
  [delegate sendPluginResult:pluginResult callbackId:command.callbackId];
  }
  else {
  NSLog(@"Request failed\n");
  connectionMsg=@"Error response from RFID reader";
  pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:connectionMsg];
  [delegate sendPluginResult:pluginResult callbackId:command.callbackId];
  }
 [setUniqueTag setUniqueTagsReportEnabled:false];
 setUniqeResult =[apiInstance srfidSetUniqueTagReportConfiguration:[reader getReaderID] aUtrConfiguration:setUniqueTag aStatusMessage:&statusMessage];

if(SRFID_RESULT_SUCCESS==setUniqeResult){
  NSLog(@"set unique success");
}
else{
  NSLog(@"set unique fail");
}
}
else{
  NSLog(@"API is not working");
}
connectionMsg=@"tags are:";
pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:connectionMsg];
// [delegate sendPluginResult:pluginResult callbackId:command.callbackId];
[pluginResult setKeepCallbackAsBool:NO];
}




- (void)search:(CDVInvokedUrlCommand*)command commandDelegate:(NSObject<CDVCommandDelegate>*)delegate{
    NSString *error_response;
    // NSString *searchTagId =@"4142434430303534";
    NSString* searchTagId = [command.arguments objectAtIndex:0];
    // bool useAscii=YES;
    bool softPress=YES;
    SRFID_RESULT result;
CDVPluginResult* pluginResult ;
    bool useAscii = [[command.arguments objectAtIndex:1] boolValue];
    NSString* connectionMsg;
    srfidTagData *accessResults =[[srfidTagData alloc] init];
    NSString *statusMessage=nil;
    inventoryEventListener  = [[EventReceiver alloc] initWithInstance:(CDVInvokedUrlCommand*)asyncCommand syncCommand:(CDVInvokedUrlCommand*)command commandDelegate:(NSObject<CDVCommandDelegate>*)delegate instance:(id<srfidISdkApi>)nil reader:(srfidReaderInfo*)nil searchTag:(NSString*)searchTagId isAscii:(BOOL)useAscii softPress:(BOOL)softPress];
    // initWithCallBacks:(CDVInvokedUrlCommand*)command commandDelegate:(NSObject<CDVCommandDelegate>*)delegate];
    srfidUniqueTagsReport* setUniqueTag =[[srfidUniqueTagsReport alloc] init];
    if(apiInstance !=nil && reader !=nil){
      [apiInstance srfidSetDelegate:inventoryEventListener];
      /* subscribe for tag data related events */
      [apiInstance srfidSubsribeForEvents:SRFID_EVENT_MASK_READ];
      /* subscribe for operation start/stop related events */
      [apiInstance srfidSubsribeForEvents:SRFID_EVENT_MASK_STATUS];

      [apiInstance srfidSubsribeForEvents:SRFID_EVENT_MASK_STATUS_OPERENDSUMMARY];
      [setUniqueTag setUniqueTagsReportEnabled:true];
      SRFID_RESULT setUniqeResult =[apiInstance srfidSetUniqueTagReportConfiguration:[reader getReaderID] aUtrConfiguration:setUniqueTag aStatusMessage:&statusMessage];

    srfidAntennaConfiguration *antenna_cfg=[[srfidAccessConfig alloc] init];
    srfidReportConfig *report_config =[[srfidReportConfig alloc] init];
    srfidAccessConfig *access_cfg=[[srfidAccessConfig alloc] init];
    NSString *error_response =nil;

    // SRFID_RESULT resultRegCond=[apiInstance srfidGetRegulatoryConfig:[reader getReaderID] aRegulatoryConfig:&report_config aStatusMessage:&statusMessage];


    [report_config setIncPC:YES];
    [report_config setIncPhase:YES];
    [report_config setIncChannelIndex:YES];
    [report_config setIncRSSI:YES];
    [report_config setIncTagSeenCount:NO];
    [report_config setIncFirstSeenTime:NO];
    [report_config setIncLastSeenTime:NO];

    srfidAntennaConfiguration *oldAntennaCfg=[[srfidAntennaConfiguration alloc] init];
    result =[apiInstance srfidGetAntennaConfiguration:[reader getReaderID] aAntennaConfiguration:&oldAntennaCfg aStatusMessage:&error_response];

  if(SRFID_RESULT_SUCCESS != result){
      [access_cfg setPower:270];
      [access_cfg setDoSelect:NO];
  } else{
    [access_cfg setPower:[oldAntennaCfg getPower]];
    [access_cfg setDoSelect:[oldAntennaCfg getDoSelect]];
  }

    // SRFID_RESULT resultAccessConf =[apiInstance srfidGetAntennaConfiguration:[reader getReaderID] aAntennaConfiguration:&antenna_cfg aStatusMessage:&statusMessage];

  // if(SRFID_RESULT_SUCCESS==resultRegCond && SRFID_RESULT_SUCCESS ==resultAccessConf){
  //   [access_cfg setPower:[antenna_cfg getPower]];
  //   [access_cfg setDoSelect:[antenna_cfg getDoSelect]];
  // }
    SRFID_RESULT result=[apiInstance srfidStartInventory:[reader getReaderID] aMemoryBank:SRFID_MEMORYBANK_EPC aReportConfig:report_config aAccessConfig:access_cfg aStatusMessage:&error_response];
    // SRFID_RESULT result = [apiInstance srfidStartRapidRead:[reader getReaderID] aReportConfig:report_config aAccessConfig:access_cfg aStatusMessage:&error_response];
    if (SRFID_RESULT_SUCCESS == result) {
    NSLog(@"Request succeed\n");
    // [apiInstance srfidStopRapidRead:[reader getReaderID] aStatusMessage:nil];
     [apiInstance srfidStopInventory:[reader getReaderID] aStatusMessage:nil];
    }
    else if (SRFID_RESULT_RESPONSE_ERROR == result) {
    NSLog(@"Error response from RFID reader: %@\n", error_response);
    connectionMsg=@"Error response from RFID reader";
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:connectionMsg];
    [delegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }
    else {
    NSLog(@"Request failed\n");
    connectionMsg=@"Request failed";
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:connectionMsg];
    [delegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }
   [setUniqueTag setUniqueTagsReportEnabled:false];
   setUniqeResult =[apiInstance srfidSetUniqueTagReportConfiguration:[reader getReaderID] aUtrConfiguration:setUniqueTag aStatusMessage:&statusMessage];

  if(SRFID_RESULT_SUCCESS==setUniqeResult){
    NSLog(@"set unique success");
  }
  else{
    NSLog(@"set unique fail");
    }
  }
  else{
    NSLog(@"API is not working");
  }
  connectionMsg=@"tags are:";

   pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:connectionMsg];
  // [delegate sendPluginResult:pluginResult callbackId:command.callbackId];
  [pluginResult setKeepCallbackAsBool:NO];

// SRFID_RESULT result = [apiInstance srfidStartTagLocationing:[reader getReaderID] aTagEpcId:searchTagId aStatusMessage:&error_response];
//     if (SRFID_RESULT_SUCCESS == result) {
//     /* pre-filters have been set */
//     NSLog(@"Pre-filters has been set\n");
//       // [apiInstance srfidStopTagLocationing:[reader getReaderID] aStatusMessage:nil];
//     dispatch_after(dispatch_time(DISPATCH_TIME_NOW,(int64_t)(1 * NSEC_PER_SEC)),dispatch_get_main_queue(),^{
//       [apiInstance srfidStopTagLocationing:[reader getReaderID] aStatusMessage:nil];
//     });
//     }
//     else if (SRFID_RESULT_RESPONSE_ERROR == result) {
//     NSLog(@"Error response from RFID reader: %@\n", error_response);
//     }
//     else {
//     NSLog(@"Failed to set tag report parameters\n");
//     }
//     static EventReceiver *inventoryEventListener;
//     NSString *statusMessage=nil;
//     // inventoryEventListener  = [[EventReceiver alloc] initWithCallBacks:(CDVInvokedUrlCommand*)command commandDelegate:(NSObject<CDVCommandDelegate>*)delegate];
//     inventoryEventListener = [[EventReceiver alloc] initWithInstance:(CDVInvokedUrlCommand*)command commandDelegate:(NSObject<CDVCommandDelegate>*)delegate instance:(id<srfidISdkApi>)apiInstance reader:(srfidReaderInfo*)reader searchTag:(NSString*)searchTagId isAscii:(BOOL)YES];
//     // initWithCallBacksInstanceAndSearchTag:(CDVInvokedUrlCommand*)command commandDelegate:(NSObject<CDVCommandDelegate>*)delegate instance:(id<srfidISdkApi>)apiInstance reader:(srfidReaderInfo*)reader searchTag:(NSString*)searchTagId];
//     // srfidUniqueTagsReport* setUniqueTag =[[srfidUniqueTagsReport alloc] init];
//     if(apiInstance !=nil && reader !=nil){
//       [apiInstance srfidSetDelegate:inventoryEventListener];
//       [apiInstance srfidSubsribeForEvents:SRFID_EVENT_MASK_PROXIMITY];
//       /* subscribe for tag data related events */
//       // [apiInstance srfidSubsribeForEvents:SRFID_EVENT_MASK_READ];
//       /* subscribe for operation start/stop related events */
//       [apiInstance srfidSubsribeForEvents:SRFID_EVENT_MASK_STATUS];
//       // [setUniqueTag setUniqueTagsReportEnabled:true];
//       // SRFID_RESULT setUniqeResult =[apiInstance srfidSetUniqueTagReportConfiguration:[reader getReaderID] aUtrConfiguration:setUniqueTag aStatusMessage:&statusMessage];
    // NSString* connectionMsg = @"Trying to fetch Tags";
    // CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:connectionMsg];
    // // [delegate sendPluginResult:pluginResult callbackId:command.callbackId];
    // [pluginResult setKeepCallbackAsBool:NO];

}

- (void)setOutputPower:(CDVInvokedUrlCommand*)command commandDelegate:(NSObject<CDVCommandDelegate>*)delegate{
  // NSInteger newPower=240;
    NSMutableString *msg = [NSMutableString stringWithFormat:@""];
    CDVPluginResult* pluginResult;
  NSInteger newPower = [[command.arguments objectAtIndex:0] intValue];
  short oldPower;

  srfidAntennaConfiguration *oldAntennaCfg=[[srfidAntennaConfiguration alloc] init];
  srfidAntennaConfiguration *newAntennaCfg=[[srfidAntennaConfiguration alloc] init];

  NSString *error_response =nil;
  SRFID_RESULT result =[apiInstance srfidGetAntennaConfiguration:[reader getReaderID] aAntennaConfiguration:&oldAntennaCfg aStatusMessage:&error_response];
if(SRFID_RESULT_SUCCESS==result){
  oldPower=[oldAntennaCfg getPower];
  [newAntennaCfg setLinkProfileIdx:[oldAntennaCfg getLinkProfileIdx]];
  [newAntennaCfg setPower:newPower];
  [newAntennaCfg setTari:[oldAntennaCfg getTari]];
  [newAntennaCfg setDoSelect:[oldAntennaCfg getDoSelect]];

  result=[apiInstance srfidSetAntennaConfiguration:[reader getReaderID] aAntennaConfiguration:newAntennaCfg aStatusMessage:&error_response];

if(SRFID_RESULT_SUCCESS==result){
  [msg appendFormat:@"Scan power set from %d", oldPower];
  [msg appendFormat:@" to %d",newPower];
	pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:msg];

}
else{
  [msg stringByAppendingString:@"Device is not connected."];
   pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:msg];
   }
}
  [delegate sendPluginResult:pluginResult callbackId:command.callbackId];

}

- (void)subscribeScanner:(CDVInvokedUrlCommand*)command commandDelegate:(NSObject<CDVCommandDelegate>*)delegate
{
    asyncCommand = command;
    // bool useAscii=YES;
    bool softPress=NO;
    bool useAscii = [[command.arguments objectAtIndex:0] boolValue];
  
  CDVPluginResult* pluginResult;
  NSString* connectionMsg;
  handheldInvEventListener  = [[EventReceiver alloc] initWithInstance:(CDVInvokedUrlCommand*)command syncCommand:(CDVInvokedUrlCommand*)nil commandDelegate:(NSObject<CDVCommandDelegate>*)delegate instance:(id<srfidISdkApi>)apiInstance reader:(srfidReaderInfo*)reader searchTag:(NSString*)nil isAscii:(BOOL)useAscii softPress:(BOOL)softPress];
  //Scan Instance
   scanInstance = [SbtSdkFactory createSbtSdkApiInstance];
  if(scanInstance!= nil && apiInstance !=nil && reader !=nil){
      [apiInstance srfidSubsribeForEvents:SRFID_EVENT_MASK_TRIGGER];
      [apiInstance srfidSetDelegate:handheldInvEventListener];
      /* subscribe for tag data related events */
      [apiInstance srfidSubsribeForEvents:SRFID_EVENT_MASK_READ];
      [apiInstance srfidSubsribeForEvents:SRFID_EVENT_MASK_STATUS_OPERENDSUMMARY];
      /* subscribe for operation start/stop related events */
      // [apiInstance srfidSubsribeForEvents:SRFID_EVENT_MASK_STATUS];
      // [apiInstance srfidSubsribeForEvents:SRFID_EVENT_MASK_READ];
      [apiInstance srfidSubsribeForEvents:SRFID_EVENT_MASK_STATUS];
      NSString* connectionMsg = @"Trying to fetch Tags";
       //Connect to scanner here...
          //If Success try to use the handler
    [scanInstance sbtSetDelegate:handheldInvEventListener]; 
    [scanInstance sbtSetOperationalMode:SBT_OPMODE_ALL];

    [scanInstance sbtEnableAvailableScannersDetection :YES];
    [scanInstance sbtSubsribeForEvents:SBT_EVENT_SCANNER_APPEARANCE | SBT_EVENT_SCANNER_DISAPPEARANCE | SBT_EVENT_SESSION_ESTABLISHMENT | SBT_EVENT_SESSION_TERMINATION | SBT_EVENT_BARCODE | SBT_EVENT_IMAGE | SBT_EVENT_VIDEO];  
    

    // Allocate an array for storage of a list of available scanners
      NSMutableArray *availableScanners = [[NSMutableArray alloc] init];
      // Allocate an array for storage of a list of active scanners
      NSMutableArray *activeScanners = [[NSMutableArray alloc] init];
      
      // Retrieve a list of available scanners
      [scanInstance sbtGetAvailableScannersList:&availableScanners];
      // Retrieve a list of active scanners
      [scanInstance sbtGetAvailableScannersList:&activeScanners];
      // Merge the available and active scanners into a single list
      NSMutableArray *allScanners = [[NSMutableArray alloc] init];
      [allScanners addObjectsFromArray:availableScanners];
      [allScanners addObjectsFromArray:activeScanners];
  //---------------------Scanner Events-----------------------------  
     
      SBT_RESULT scanResult =[scanInstance sbtEstablishCommunicationSession:[[allScanners objectAtIndex:0] getScannerID]];
      // SBT_RESULT scanResult = [scanInstance sbtEstablishCommunicationSession:[allScanners objectAtIndex:0]];
      // [scanInstance sbtEnableAutomaticSessionReestablishment:YES forScanner:[allScanners objectAtIndex:0]];
      // SBT_RESULT scanResult = [scanInstance sbtEstablishCommunicationSession: [reader getReaderID]];


      CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:connectionMsg];
      // [delegate sendPluginResult:pluginResult callbackId:command.callbackId];
      [pluginResult setKeepCallbackAsBool:YES];

      NSLog(@"Subscribe started!");

}
}
- (void)unsubscribeScanner:(CDVInvokedUrlCommand*)command commandDelegate:(NSObject<CDVCommandDelegate>*)delegate
{
if(apiInstance !=nil && reader !=nil){
      [apiInstance srfidUnsubsribeForEvents:SRFID_EVENT_MASK_TRIGGER];
      [apiInstance srfidUnsubsribeForEvents:SRFID_EVENT_MASK_READ];
      [apiInstance srfidUnsubsribeForEvents:SRFID_EVENT_MASK_STATUS_OPERENDSUMMARY];

      NSString* connectionMsg = @"Trying to fetch Tags";
      CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:connectionMsg];
      [delegate sendPluginResult:pluginResult callbackId:command.callbackId];
      [pluginResult setKeepCallbackAsBool:NO];

      NSLog(@"Unsubscribe ended!");

}
}
-(void) startSearch:(CDVInvokedUrlCommand*)command commandDelegate:(NSObject<CDVCommandDelegate>*)delegate{
  // NSString *searchTagId =@"4142434430303534";
  NSString* searchTagId = [command.arguments objectAtIndex:0];
  // bool useAscii=YES;
  bool softPress =NO;
  bool useAscii = [[command.arguments objectAtIndex:1] boolValue];
  handheldInvEventListener  = [[EventReceiver alloc] initWithInstance:(CDVInvokedUrlCommand*)command syncCommand:(CDVInvokedUrlCommand*)nil commandDelegate:(NSObject<CDVCommandDelegate>*)delegate instance:(id<srfidISdkApi>)apiInstance reader:(srfidReaderInfo*)reader searchTag:(NSString*)searchTagId isAscii:(BOOL)useAscii softPress:(BOOL)softPress];
  // initWithCallBacksAndInstance:(CDVInvokedUrlCommand*)command commandDelegate:(NSObject<CDVCommandDelegate>*)delegate instance:(id<srfidISdkApi>)apiInstance reader:(srfidReaderInfo*)reader];
if(apiInstance !=nil && reader !=nil){
    [apiInstance srfidSubsribeForEvents:SRFID_EVENT_MASK_TRIGGER];
    [apiInstance srfidSetDelegate:handheldInvEventListener];
    /* subscribe for tag data related events */
    [apiInstance srfidSubsribeForEvents:SRFID_EVENT_MASK_READ];
    [apiInstance srfidSubsribeForEvents:SRFID_EVENT_MASK_STATUS_OPERENDSUMMARY];
    /* subscribe for operation start/stop related events */
    // [apiInstance srfidSubsribeForEvents:SRFID_EVENT_MASK_STATUS];
    // [apiInstance srfidSubsribeForEvents:SRFID_EVENT_MASK_READ];
    [apiInstance srfidSubsribeForEvents:SRFID_EVENT_MASK_STATUS];
    NSString* connectionMsg = @"Trying to fetch Tags";
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:connectionMsg];
    // [delegate sendPluginResult:pluginResult callbackId:command.callbackId];
    [pluginResult setKeepCallbackAsBool:YES];

    NSLog(@"Search started!");
}
// static EventReceiver *handheldInvEventListener;
// handheldInvEventListener  = [[EventReceiver alloc] initWithInstance:(CDVInvokedUrlCommand*)command commandDelegate:(NSObject<CDVCommandDelegate>*)delegate instance:(id<srfidISdkApi>)apiInstance reader:(srfidReaderInfo*)reader searchTag:(NSString*)searchtagId isAscii:(BOOL)YES];
// // initWithCallBacksInstanceAndSearchTag:(CDVInvokedUrlCommand*)command commandDelegate:(NSObject<CDVCommandDelegate>*)delegate instance:(id<srfidISdkApi>)apiInstance reader:(srfidReaderInfo*)reader searchTag:(NSString*)searchtagId];
// if(apiInstance !=nil && reader !=nil){
//     [apiInstance srfidSubsribeForEvents:SRFID_EVENT_MASK_TRIGGER];
//     [apiInstance srfidSetDelegate:handheldInvEventListener];
//     /* subscribe for tag data related events */
//
//     // [apiInstance srfidSubsribeForEvents:SRFID_EVENT_MASK_READ];
//     /* subscribe for operation start/stop related events */
//     [apiInstance srfidSubsribeForEvents:SRFID_EVENT_MASK_PROXIMITY];
//     // [apiInstance srfidSubsribeForEvents:SRFID_EVENT_MASK_READ];
//     // [apiInstance srfidSubsribeForEvents:SRFID_EVENT_MASK_STATUS];
//     NSString* connectionMsg = @"Trying to fetch Tags";
//     CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:connectionMsg];
//     // [delegate sendPluginResult:pluginResult callbackId:command.callbackId];
//     [pluginResult setKeepCallbackAsBool:YES];
//
//       NSLog(@"Search ended!");
//     }
}

-(void) stopSearch:(CDVInvokedUrlCommand*)command commandDelegate:(NSObject<CDVCommandDelegate>*)delegate{
  // if(apiInstance !=nil && reader !=nil){
  //       [apiInstance srfidUnsubsribeForEvents:SRFID_EVENT_MASK_PROXIMITY];
  //       [apiInstance srfidUnsubsribeForEvents:SRFID_EVENT_MASK_STATUS];
  //
  //       NSString* connectionMsg = @"Trying to fetch Tags";
  //       CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:connectionMsg];
  //       // [delegate sendPluginResult:pluginResult callbackId:command.callbackId];
  //       [pluginResult setKeepCallbackAsBool:NO];
  //
  //       NSLog(@"Search ended!");
  // }
  if(apiInstance !=nil && reader !=nil){
        [apiInstance srfidUnsubsribeForEvents:SRFID_EVENT_MASK_TRIGGER];
        [apiInstance srfidUnsubsribeForEvents:SRFID_EVENT_MASK_READ];
        [apiInstance srfidUnsubsribeForEvents:SRFID_EVENT_MASK_STATUS_OPERENDSUMMARY];

        NSString* connectionMsg = @"Scan Stopped";
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:connectionMsg];
        [delegate sendPluginResult:pluginResult callbackId:command.callbackId];
        [pluginResult setKeepCallbackAsBool:NO];

        NSLog(@"Search ended!");
}
}

@end




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

 // static NSString *const ERROR_LABEL = @"Error: ";
 // static NSString *const DEVICE_IS_ALREADY_CONNECTED = @"Device is already connected.";
 // static NSString *const SCAN_POWER = @"scanPower";
 // static NSString *const ANTENNA_MAX = @"antennaMax";
 // static NSString *const ANTENNA_MIN = @"antennaMin";
 // static NSString *const SERIAL_NUMBER = @"serialNumber";
 // static NSString *const MANUFACTURER = @"manufacturer";
 // static NSString *const FIRMWARE_VERSION = @"firmwareVersion";
 // static NSString *const HARDWARE_VERSION = @"hardwareVersion";
 // static NSString *const BATTERY_STATUS = @"batteryStatus";
 // static NSString *const BATTERY_LEVEL = @"batteryLevel";
 // static NSString *const DEVICE_NAME = @"deviceName";
 // static NSString *const DEVICE_IS_NOT_CONNECTED = @"Device is not connected.";

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
  ZebraScanner *zebraScanner;
   NSString *scannerType;
   TSLScanner *tslScanner;
}
@property (nonatomic,retain) TSLScanner *tslScanner;
@property (nonatomic,retain) TSLScanner *zebraScanner;

+ (id)sharedTSLInstance;
+ (id)sharedZebraInstance;

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

+ (id)sharedZebraInstance {
static ZebraScanner *sharedZebraInstance = nil;
static dispatch_once_t onceToken;
dispatch_once(&onceToken, ^{
sharedZebraInstance =[[ZebraScanner alloc]init];
});
return sharedZebraInstance;
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
  }else{
     zebraScanner = [RFIDConnector sharedZebraInstance];
     NSLog(@"getDeviceList in RFIDConnector Zebra");
    [zebraScanner connect:command commandDelegate:self.commandDelegate];
    
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
  } else {
     NSLog(@"isConnected in RFIDConnector zebra");
     [zebraScanner isConnected:command commandDelegate:self.commandDelegate];
  }
  // NSLog(@"isConnected in RFIDConnector");
  //[scanner isConnected:command

}
- (void)disconnect:(CDVInvokedUrlCommand*)command{
  if([scannerType isEqualToString:@"TSL"]) {
     NSLog(@"isConnected in RFIDConnector tsl");
     [tslScanner disconnect:command commandDelegate:self.commandDelegate];
  } else {
     NSLog(@"isConnected in RFIDConnector zebra");
    [zebraScanner disconnect:command commandDelegate:self.commandDelegate];
  }
}
- (void)getDeviceInfo:(CDVInvokedUrlCommand*)command{
  if([scannerType isEqualToString:@"TSL"]) {
     NSLog(@"isConnected in RFIDConnector tsl");
     [tslScanner getDeviceInfo:command commandDelegate:self.commandDelegate];
  } else {
     NSLog(@"isConnected in RFIDConnector zebra");
    [zebraScanner getDeviceInfo:command commandDelegate:self.commandDelegate];
  }
}
- (void)scanRFIDs:(CDVInvokedUrlCommand*)command{
  if([scannerType isEqualToString:@"TSL"]) {
     NSLog(@"isConnected in RFIDConnector tsl");
     [tslScanner scanRFIDs:command commandDelegate:self.commandDelegate];
  } else {
     NSLog(@"isConnected in RFIDConnector zebra");
   [zebraScanner scanRFIDs:command commandDelegate:self.commandDelegate];
  }
}
- (void)search:(CDVInvokedUrlCommand*)command{
 if([scannerType isEqualToString:@"TSL"]) {
     NSLog(@"isConnected in RFIDConnector tsl");
     [tslScanner search:command commandDelegate:self.commandDelegate];
  } else {
     NSLog(@"isConnected in RFIDConnector zebra");
   [zebraScanner search:command commandDelegate:self.commandDelegate];
  }
}
- (void)setOutputPower:(CDVInvokedUrlCommand*)command{
  if([scannerType isEqualToString:@"TSL"]) {
     NSLog(@"isConnected in RFIDConnector tsl");
     [tslScanner setOutputPower:command commandDelegate:self.commandDelegate];
  } else {
     NSLog(@"isConnected in RFIDConnector zebra");
   [zebraScanner setOutputPower:command commandDelegate:self.commandDelegate];
  }
  
}

- (void)subscribeScanner:(CDVInvokedUrlCommand*)command{
  if([scannerType isEqualToString:@"TSL"]) {
     NSLog(@"isConnected in RFIDConnector tsl");
     [tslScanner subscribeScanner:command commandDelegate:self.commandDelegate];
  } else {
     NSLog(@"isConnected in RFIDConnector zebra");
    [zebraScanner subscribeScanner:command commandDelegate:self.commandDelegate];
  }     
}
- (void)unsubscribeScanner:(CDVInvokedUrlCommand*)command{
  if([scannerType isEqualToString:@"TSL"]) {
     NSLog(@"isConnected in RFIDConnector tsl");
     [tslScanner unsubscribeScanner:command commandDelegate:self.commandDelegate];
  } else {
     NSLog(@"isConnected in RFIDConnector zebra");
      [zebraScanner unsubscribeScanner:command commandDelegate:self.commandDelegate];
  }
}
- (void)startSearch:(CDVInvokedUrlCommand*)command{
  if([scannerType isEqualToString:@"TSL"]) {
     NSLog(@"isConnected in RFIDConnector tsl");
     [tslScanner startSearch:command commandDelegate:self.commandDelegate];
  } else {
     NSLog(@"isConnected in RFIDConnector zebra");
   [zebraScanner startSearch:command commandDelegate:self.commandDelegate];
  }    
}
- (void)stopSearch:(CDVInvokedUrlCommand*)command{
  if([scannerType isEqualToString:@"TSL"]) {
     NSLog(@"isConnected in RFIDConnector tsl");
     [tslScanner stopSearch:command commandDelegate:self.commandDelegate];
  } else {
     NSLog(@"isConnected in RFIDConnector zebra");
     [zebraScanner stopSearch:command commandDelegate:self.commandDelegate];
  }  
}

@end
