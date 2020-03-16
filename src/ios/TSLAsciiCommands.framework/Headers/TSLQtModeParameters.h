//
//  TSLQtModeParameters.h
//  TSLAsciiCommands
//
//  Created by Brian Painter on 26/08/2016.
//  Copyright © 2016 Technology Solutions UK Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

///
/// Use macro to allow the creation of enum, parameter value and descriptive strings that are always in sync
///
#define USE_ENUM(e,p,s) e,

/// Query Select values
#define TSL_FOR_EACH_QT_MODE(select)\
\
select( TSL_QtMode_NotSpecified = -1,               @"",      @"Not specified"                      )\
select( TSL_QtMode_None,                            @"0",     @"Standard Read/Write"                )\
select( TSL_QtMode_AccessPrivateMemory,             @"1",     @"Access private memory"              )\
select( TSL_QtMode_AccessPrivateMemoryShortRange,   @"2",     @"Access private memory short range"  )\
select( TSL_QtMode_AccessControlWord,               @"3",     @"Access Control Word"                )\


///
/// The query select type
///
typedef enum { TSL_FOR_EACH_QT_MODE(USE_ENUM) } TSL_QtMode;

///
/// Parameters for Query operations in commands and responses
///
@protocol TSLQtModeParametersProtocol <NSObject>

/// The QT mode (Impinj transponders only)
@property (nonatomic, readwrite) TSL_QtMode qtMode;

@end


///
/// Helper class for implementing TSLQtModeParametersProtocol
///
/// The `TSL_QtMode` enum is used to specify values for the qtMode parameter.
///
/// When issuing a command to the reader the values are interpreted as follows:
///
/// - `TSL_QtMode_NotSpecified` - _The value has not been specified and the `qtMode` parameter will not be sent_
/// - `TSL_QtMode_None` - _Standard operation has been specified and is sent as `'0'`_
/// - `TSL_QtMode_AccessPrivateMemory` - _Private memory access has been specified and is sent as `'1'`_
/// - `TSL_QtMode_AccessPrivateMemoryShortRange` - _Short range, private memory access has been specified and is sent as `'2'`_
/// - `TSL_QtMode_AccessControlWord` - _QT Control word access has been specified and is sent as `'3'`_
///
@interface TSLQtModeParameters : NSObject

/// Sets the parameters to default values
///
///@param object The instance to be modified
+(void)setDefaultParametersForObject:(id<TSLQtModeParametersProtocol>)object;

/// Returns the command line fragment built from the source object's properties
///
///@param source The instance whose command line is to be built
///
+(NSString *)commandLine:(id<TSLQtModeParametersProtocol>)source;

/// Examines the parameter string and, if recognised, sets the corresponding property on the object
///
///@param parameter The parameter string
///@param object The instance to be modified
///
+(BOOL)parseParameter:(NSString *)parameter forObject:(id<TSLQtModeParametersProtocol>)object;

///
/// Parse the given parameter value string and determine the corresponding TSL_QtMode
///
///@param value The parameter value as NSString
///@return The TSL_QtMode corresponding to the given string. Invalid parameter values return TSL_QtMode_NotSpecified
///
+(TSL_QtMode)qtModeForParameterValue:(NSString *)value;

///
/// Get the parameter value corresponding to the given TSL_QtMode
///
///@param select The TSL_QtMode value to be converted
///@return The command parameter value for the given TSL_QtMode or nil if invalid
///
+(NSString *)parameterValueForQtMode:(TSL_QtMode)select;


///
/// Get the description corresponding to the given TSL_QtMode
///
///@param select The TSL_QtMode value to be converted
///@return The user friendly name for the given TSL_QtMode or nil if invalid
///

+(NSString *)descriptionForQtMode:(TSL_QtMode)select;

///
/// Test the given TSL_QtMode for validity
///
///@param select The TSL_QtMode value to be tested
///@return YES if the given TSL_QtMode is valid otherwise NO
///
+(BOOL)isValidQtMode:(TSL_QtMode)select;



@end
