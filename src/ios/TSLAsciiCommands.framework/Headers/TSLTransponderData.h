//
//  TSLTransponderData.h
//  TSLAsciiCommands
//
//  Created by Brian Painter on 17/08/2016.
//  Copyright © 2016 Technology Solutions UK Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "TSLTransponderAccessErrorCode.h"
#import "TSLTransponderBackscatterErrorCode.h"


///
/// A class to represent the data received from a Transponder response
///
@interface TSLTransponderData : NSObject

/// The timestamp from the reader
/// Note: the timezone is set to the device's local time zone
@property (nonatomic, readonly) NSDate *timestamp;

/// The transponder EPC
@property (nonatomic, readonly) NSString *epc;
/// The transponder CRC
@property (nonatomic, readonly) NSNumber *crc;
/// The transponder index
@property (nonatomic, readonly) NSNumber *index;
/// The transponder PC Word
@property (nonatomic, readonly) NSNumber *pc;
/// The transponder RSSI
@property (nonatomic, readonly) NSNumber *rssi;
/// The transponder TID data (Impinj fast ID transponders only)
@property (nonatomic, readonly) NSData *fastTidData;
/// The transponder data from a read command
@property (nonatomic, readonly) NSData *readData;
/// The transponder QT response (Impinj QT transponders only)
@property (nonatomic, readonly) NSNumber *qt;
/// The transponder Lock Success response
@property (nonatomic, readonly) BOOL didLock;
/// The transponder Kill Success response
@property (nonatomic, readonly) BOOL didKill;
/// The transponder access error code
@property (nonatomic, readonly) TSL_TransponderAccessErrorCode accessErrorCode;
/// The transponder backscatter error code
@property (nonatomic, readonly) TSL_TransponderBackscatterErrorCode backscatterErrorCode;
/// The number of words written to the transponder from a write command
@property (nonatomic, readonly) NSNumber *wordsWritten;


///
/// Initialises a new instance of the TSLTransponderData class
///
/// @param timestamp - the time when the transponder was seen based on the responses timestamp
/// @param epc - the transponder identifier as hex-encoded, ascii string or nil if none
/// @param crc - the transponder CRC as unsigned short encoded in NSNumber or nil if none
/// @param index - the index of the transponder as unsigned short encoded in NSNumber or nil if none
/// @param pc - the transponder program control word as unsigned short encoded in NSNumber or nil if none
/// @param rssi - the transponders RSSI value (in dBm) as int encoded in NSNumber or nil if none
/// @param fastTidData - the transponders TID bank as NSData or nil if none (Impinj only - requires transponder support)
/// @param readData - the data read from the tag as NSData or nil if none
/// @param qt - the QT response nil if none (Impinj only - requires transponder support)
/// @param didLock - YES if the transponder is the result of a succesful Lock command
/// @param didKill - YES if the transponder is the result of a succesful Kill command
/// @param accessErrorCode - the Access error code
/// @param backscatterErrorCode - the Backscatter error code
/// @param wordsWritten - the number of words successfully written encoded in NSNumber or nil if none
///
-(TSLTransponderData *) initWithTimestamp:(NSDate *)timestamp
                                      epc:(NSString *)epc
                                      crc:(NSNumber *)crc
                                    index:(NSNumber *)index
                                       pc:(NSNumber *)pc
                                     rssi:(NSNumber *)rssi
                              fastTidData:(NSData *)fastTidData
                                 readData:(NSData *)readData
                                       qt:(NSNumber *)qt
                                  didLock:(BOOL)didLock
                                  didKill:(BOOL)didKill
                          accessErrorCode:(TSL_TransponderAccessErrorCode)accessErrorCode
                     backscatterErrorCode:(TSL_TransponderBackscatterErrorCode)backscatterErrorCode
                             wordsWritten:(NSNumber *)wordsWritten;

@end


///
/// The block type to handle transponder information received
///
/// @param transponder - the transponder information provided as a TSLTransponderData instance
/// @param moreAvailable - YES if there are more transponders to be delivered
///
typedef void(^TSLTransponderDataReceivedBlock)(TSLTransponderData *transponder, BOOL moreAvailable);
