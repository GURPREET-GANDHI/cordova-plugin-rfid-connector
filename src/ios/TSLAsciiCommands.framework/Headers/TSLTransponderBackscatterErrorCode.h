//
//  TSLTransponderBackscatterErrorCode.h
//  TSLAsciiCommands
//
//  Copyright © 2016 Technology Solutions UK Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

///
/// Use macro to allow the creation of enum, parameter value and descriptive strings that are always in sync
///
#define USE_ENUM(e,p,s) e,

/// Access Error values
#define TSL_FOR_EACH_TRANSPONDER_BACKSCATTER_ERROR_CODE(select)\
\
select( TSL_TransponderBackscatterErrorCode_NotSpecified = 0,                                @"",       @"Not specified"  )\
select( TSL_TransponderBackscatterErrorCode_GeneralError,                                    @"000",    @"General error"  )\
select( TSL_TransponderBackscatterErrorCode_MemoryDoesNotExistOrThePcValueIsNotSupported,    @"003",    @"Memory does not exist or the PC value is not supported"  )\
select( TSL_TransponderBackscatterErrorCode_MemoryIsLockOrPermalocked,                       @"004",    @"Memory is locked or permalocked"  )\
select( TSL_TransponderBackscatterErrorCode_TransponderHasInsufficientPower,                 @"011",    @"Transponder has insufficient power"  )\
select( TSL_TransponderBackscatterErrorCode_TransponderDoesNotSupportErrorSpecificCodes,     @"015",    @"Transponder does not support error specific codes"  )\


///
/// The TransponderBackscatterErrorCode type
///
typedef enum { TSL_FOR_EACH_TRANSPONDER_BACKSCATTER_ERROR_CODE(USE_ENUM) } TSL_TransponderBackscatterErrorCode;


#undef USE_ENUM


@interface TSLTransponderBackscatterErrorCode : NSObject

///
/// Parse the given parameter value string and determine the corresponding TSL_TransponderBackscatterErrorCode
///
///@param value The parameter value as NSString
///@return The TSL_TransponderBackscatterErrorCode corresponding to the given string. Invalid parameter values return TSL_TransponderBackscatterErrorCode_NotSpecified
///
+(TSL_TransponderBackscatterErrorCode)transponderBackscatterErrorCodeForParameterValue:(NSString *)value;

///
/// Get the parameter value corresponding to the given TSL_TransponderBackscatterErrorCode
///
///@param errorCode The TSL_TransponderBackscatterErrorCode value to be converted
///@return The command parameter value for the given TSL_TransponderBackscatterErrorCode or nil if invalid
///
+(NSString *)parameterValueForTransponderBackscatterErrorCode:(TSL_TransponderBackscatterErrorCode)errorCode;


///
/// Get the description corresponding to the given TSL_TransponderBackscatterErrorCode
///
///@param errorCode The TSL_QuerySelect value to be converted
///@return The user friendly name for the given TSL_QuerySelect or nil if invalid
///

+(NSString *)descriptionForTransponderBackscatterErrorCode:(TSL_TransponderBackscatterErrorCode)errorCode;

///
/// Test the given TSL_TransponderBackscatterErrorCode for validity
///
///@param errorCode The TSL_TransponderBackscatterErrorCode value to be tested
///@return YES if the given TSL_TransponderBackscatterErrorCode is valid otherwise NO
///
+(BOOL)isValidTransponderBackscatterErrorCode:(TSL_TransponderBackscatterErrorCode)errorCode;


@end
