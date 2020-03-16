//
//  TSLInventoryCommand.h
//  AgoutiCommands
//
//  Created by Brian Painter on 21/03/2013.
//  Copyright (c) 2013 Technology Solutions UK Ltd. All rights reserved.
//

#import "TSLCommandParameters.h"
#import "TSLTransponderParameters.h"
#import "TSLResponseParameters.h"
#import "TSLAntennaParameters.h"
#import "TSLQueryParameters.h"
#import "TSLQAlgorithmParameters.h"
#import "TSLSelectMaskParameters.h"
#import "TSLSelectControlParameters.h"
#import "TSLTransponderReceivedDelegate.h"
#import "TSLTransponderData.h"

#import "TSLAsciiSelfResponderCommandBase.h"

///
/// Protocol for objects wishing to receive asynchronous notification of each transponder received
///
@protocol TSLInventoryCommandTransponderReceivedDelegate <NSObject>

///
/// The transponder information received
///
/// @param epc - the transponder identifier as hex-encoded, ascii string
/// @param crc - the transponder CRC as unsigned short encoded in NSNumber or nil if none
/// @param pc - the transponder program control word as unsigned short encoded in NSNumber or nil if none
/// @param rssi - the transponders RSSI value (in dBm) as int encoded in NSNumber or nil if none
/// @param fastId - the transponders TID bank as NSData or nil if none (Impinj Only - requires transponder support)
/// @param moreAvailable - YES if there are more transponders to be delivered
///
-(void)transponderReceived:(NSString *)epc crc:(NSNumber *)crc pc:(NSNumber *)pc rssi:(NSNumber *)rssi fastId:(NSData *)fastId moreAvailable:(BOOL)moreAvailable;

@end

///
/// The block type to handle transponder information received
///
/// @param epc - the transponder identifier as hex-encoded, ascii string
/// @param crc - the transponder CRC as unsigned short encoded in NSNumber or nil if none
/// @param pc - the transponder program control word as unsigned short encoded in NSNumber or nil if none
/// @param rssi - the transponders RSSI value (in dBm) as int encoded in NSNumber or nil if none
/// @param fastId - the transponders TID bank as NSData or nil if none (Impinj Only - requires transponder support)
/// @param moreAvailable - YES if there are more transponders to be delivered
///
typedef void(^TSLInventoryTransponderReceivedBlock)(NSString *epc, NSNumber *crc, NSNumber *pc, NSNumber *rssi, NSData *fastId, BOOL moreAvailable);


///
/// A command to perform an inventory
///
/// Configure this command using the properties defined in the parameter protocols this class implements
///
@interface TSLInventoryCommand : TSLAsciiSelfResponderCommandBase <TSLCommandParametersProtocol,TSLAntennaParametersProtocol,TSLTransponderParametersProtocol, TSLResponseParametersProtocol, TSLQueryParametersProtocol, TSLQAlgorithmParametersProtocol, TSLSelectMaskParametersProtocol, TSLSelectControlParametersProtocol, TSLTransponderReceivedDelegate>

/// @name Properties

/// When set to `TSL_TriState_YES` the Select operation is NOT performed
@property (nonatomic, readwrite) TSL_TriState inventoryOnly;

/// When set to `TSL_TriState_YES` only the tag with the strongest response is returned
@property (nonatomic, readwrite) TSL_TriState filterStrongest;

/// Control the inclusion of the EPC identifier value in reader responses
@property (nonatomic, readwrite) TSL_TriState includeEPC;

/// When set to `TSL_TriState_YES`
/// Impinj Only - requires transponder support
@property (nonatomic, readwrite) TSL_TriState useFastId;

/// When set to `TSL_TriState_YES`
/// Impinj Only - requires transponder support
@property (nonatomic, readwrite) TSL_TriState useTagFocus;


/// Convenience property returning the 'query session' parameter
@property (nonatomic, readonly) NSString *sessionModeDescription;

/// The TSLInventoryCommandTransponderReceivedDelegate to inform after each transponder is received
@property (weak, nonatomic, readwrite) id<TSLInventoryCommandTransponderReceivedDelegate>transponderReceivedDelegate;

/// The TSLTransponderReceivedBlock
@property (nonatomic, copy) TSLInventoryTransponderReceivedBlock transponderReceivedBlock;

///
/// The TSLTransponderDataReceivedBlock
///
/// All transponder responses will invoke this block even when no EPC response is present
/// which is something that the other Block and Delegate methods do not do.
///
/// Warning: When a TSLTransponderDataReceivedBlock is supplied this prevents any TSLInventoryTransponderReceivedBlock
/// or the TSLInventoryCommandTransponderReceivedDelegate from being invoked
///
@property (nonatomic, copy) TSLTransponderDataReceivedBlock transponderDataReceivedBlock;


/// @name Factory Methods

///
/// Returns a synchronous TSLInventoryCommand
///
+(TSLInventoryCommand *)synchronousCommand;

@end
