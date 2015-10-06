#import <Foundation/Foundation.h>

#pragma mark - INTERFACE

/**
  IQUSDKUtils defines various static support methods.
*/
@interface IQUSDKUtils : NSObject

#pragma mark - Public methods

/**
  Returns the time passed in milliseconds since 1970-01-01 00:00:00.000
 
  @return time in milliseconds
*/
+ (int64_t)currentTimeMillis;

/**
  Convert a NSDictionary to a JSON formatted string. If IQUSDK_DEBUG is defined use pretty printing, else return compact version.
*/
+ (NSString*)toJSON:(NSDictionary*)aCollection;

@end
