//
//  TSLTransponderAccessErrorCode.h
//  TSLAsciiCommands
//
//  Created by Brian Painter on 18/08/2016.
//  Copyright © 2016 Technology Solutions UK Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

///
/// Use macro to allow the creation of enum, parameter value and descriptive strings that are always in sync
///
#define USE_ENUM(e,p,s) e,

/// Access Error values
#define TSL_FOR_EACH_TRANSPONDER_ACCESS_ERROR_CODE(select)\
\
select( TSL_TransponderAccessErrorCode_NotSpecified = 0,                @"",       @"Not specified"                     )\
select( TSL_TransponderAccessErrorCode_HandleMismatch,                  @"001",    @"Handle Mismatch"                   )\
select( TSL_TransponderAccessErrorCode_CrcErrorOnTransponderResponse,   @"002",    @"CRC error on transponder response" )\
select( TSL_TransponderAccessErrorCode_NoTransponderReply,              @"003",    @"No transponder reply"              )\
select( TSL_TransponderAccessErrorCode_InvalidPassword,                 @"004",    @"Invalid password"                  )\
select( TSL_TransponderAccessErrorCode_ZeroKillPassword,                @"005",    @"Kill password is zero"             )\
select( TSL_TransponderAccessErrorCode_TransponderLost,                 @"006",    @"Transponder lost"                  )\
select( TSL_TransponderAccessErrorCode_CommandFormatError,              @"007",    @"Command format error"              )\
select( TSL_TransponderAccessErrorCode_ReadCountInvalid,                @"008",    @"Read count invalid"                )\
select( TSL_TransponderAccessErrorCode_OutOfRetries,                    @"009",    @"Out of retries"                    )\
select( TSL_TransponderAccessErrorCode_OperationFailed,                 @"255",    @"Operation failed"                  )\


///
/// The TransponderAccessErrorCode type
///
typedef enum { TSL_FOR_EACH_TRANSPONDER_ACCESS_ERROR_CODE(USE_ENUM) } TSL_TransponderAccessErrorCode;


#undef USE_ENUM


@interface TSLTransponderAccessErrorCode : NSObject

///
/// Parse the given parameter value string and determine the corresponding TSL_TransponderAccessErrorCode
///
///@param value The parameter value as NSString
///@return The TSL_TransponderAccessErrorCode corresponding to the given string. Invalid parameter values return TSL_TransponderAccessErrorCode_NotSpecified
///
+(TSL_TransponderAccessErrorCode)transponderAccessErrorCodeForParameterValue:(NSString *)value;

///
/// Get the parameter value corresponding to the given TSL_TransponderAccessErrorCode
///
///@param errorCode The TSL_TransponderAccessErrorCode value to be converted
///@return The command parameter value for the given TSL_TransponderAccessErrorCode or nil if invalid
///
+(NSString *)parameterValueForTransponderAccessErrorCode:(TSL_TransponderAccessErrorCode)errorCode;


///
/// Get the description corresponding to the given TSL_TransponderAccessErrorCode
///
///@param errorCode The TSL_QuerySelect value to be converted
///@return The user friendly name for the given TSL_QuerySelect or nil if invalid
///

+(NSString *)descriptionForTransponderAccessErrorCode:(TSL_TransponderAccessErrorCode)errorCode;

///
/// Test the given TSL_TransponderAccessErrorCode for validity
///
///@param errorCode The TSL_TransponderAccessErrorCode value to be tested
///@return YES if the given TSL_TransponderAccessErrorCode is valid otherwise NO
///
+(BOOL)isValidTransponderAccessErrorCode:(TSL_TransponderAccessErrorCode)errorCode;



@end
