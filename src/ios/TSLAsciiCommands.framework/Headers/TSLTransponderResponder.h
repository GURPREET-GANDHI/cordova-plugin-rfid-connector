//
//  TSLTransponderResponder.h
//  TSLAsciiCommands
//
//  Created by Brian Painter on 17/08/2016.
//  Copyright © 2016 Technology Solutions UK Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "TSLTransponderAccessErrorCode.h"
#import "TSLTransponderBackscatterErrorCode.h"
#import "TSLTransponderReceivedDelegate.h"

///
/// A Responder class that handles responses from Transponders
///
@interface TSLTransponderResponder : NSObject

/// The delegate to inform when each transponder is received
@property (nonatomic, readwrite) id<TSLTransponderReceivedDelegate> transponderDelegate;

/// Init a new instance of the TSLTransponderResponder class
-(TSLTransponderResponder *)init;

/// Clear the cached transponder values ready to receive the next one
-(void)clearLastResponse;

///
/// Each correctly terminated line from the device is passed to this method for processing
///
/// @param header - the response line header excluding the colon e.g. 'CS' for a command started response
/// @param value - the response line following the colon e.g. '.iv'
///
/// @return YES if this line should not be passed to any other responder
///
-(BOOL)processReceivedLine:(NSString *)header value:(NSString *)value;


///
/// Call this method when a transponder response has completed
///
///
/// @param moreAvailable - NO if there are no more transponder responses from this command to follow
///
-(void)transponderCompleteWithMoreAvailable:(BOOL)moreAvailable;

@end
