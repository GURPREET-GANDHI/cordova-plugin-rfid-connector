//
//  TSLFactoryDefaultsCommand.h
//  AgoutiCommands
//
//  Created by Brian Painter on 02/04/2013.
//  Copyright (c) 2013 Technology Solutions UK Ltd. All rights reserved.
//

#import "TSLCommandParameters.h"
#import "TSLAsciiSelfResponderCommandBase.h"

///
/// A command to reset the reader to its default configuration
///
@interface TSLFactoryDefaultsCommand : TSLAsciiSelfResponderCommandBase <TSLCommandParametersProtocol>

///
/// Use macro to allow the creation of enum, parameter value and descriptive strings that are always in sync
///
#define USE_ENUM(e,p,s) e,

/// ePop-Loq mode values
#define TSL_FOR_EACH_POP_LOQ_MODE(select)\
\
select( TSL_PopLoqMode_NotSpecified = 0,  @"",      @"Not specified"    )\
select( TSL_PopLoqMode_ChargeOnly,        @"co",    @"Charge only"      )\
select( TSL_PopLoqMode_ChargeData,        @"cd",    @"Charge and data"  )\

/// The `TSL_PopLoqMode` enum is used to specify values for the popLoqMode parameter.
///
/// When issuing a command to the reader the values are interpreted as follows:
///
/// - `TSL_PopLoqMode_NOT_SPECIFIED` - _The value has not been specified and the `popLoqMode` parameter will not be sent_
/// - `TSL_PopLoqMode_ChargeOnly` - _Charge only has been specified and is sent as `'co'`_
/// - `TSL_PopLoqMode_ChargeData` - _Charge and data has been specified and is sent as `'cd'`_
///
/// When a command includes the '-p' option the `popLoqMode` parameter will be set to the reader's current value
///
typedef enum { TSL_FOR_EACH_POP_LOQ_MODE(USE_ENUM) } TSL_PopLoqMode;

/// @name Properties

/// Change the operating mode of the ePopLoq connector
@property (nonatomic, readwrite) TSL_PopLoqMode popLoqMode;

/// @name Factory Methods

///
/// Returns a synchronous TSLFactoryDefaultsCommand
///
+(TSLFactoryDefaultsCommand *)synchronousCommand;

///
/// Parse the given parameter value string and determine the corresponding TSL_PopLoqMode
///
///@param value The parameter value as NSString
///@return The TSL_PopLoqMode corresponding to the given string. Invalid parameter values return TSL_PopLoqMode_NotSpecified
///

+(TSL_PopLoqMode)popLoqModeForParameterValue:(NSString *)value;

///
/// Get the parameter value corresponding to the given TSL_PopLoqMode
///
///@param mode The TSL_PopLoqMode value to be converted
///@return The command parameter value for the given TSL_PopLoqMode or nil if invalid
///
+(NSString *)parameterValueForPopLoqMode:(TSL_PopLoqMode)mode;

///
/// Get the description corresponding to the given TSL_PopLoqMode
///
///@param mode The TSL_PopLoqMode value to be converted
///@return The user friendly name for the given TSL_PopLoqMode or nil if invalid
///

+(NSString *)descriptionForPopLoqMode:(TSL_PopLoqMode)mode;

///
/// Test the given TSL_PopLoqMode for validity
///
///@param mode The TSL_PopLoqMode value to be tested
///@return YES if the given TSL_PopLoqMode is valid otherwise NO
///
+(BOOL)isValidPopLoqMode:(TSL_PopLoqMode)mode;




@end
