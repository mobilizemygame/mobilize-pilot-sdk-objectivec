#import "IQUSDKConfig.h"
#import "IQUSDKUtils.h"

#pragma mark - PRIVATE DEFINITIONS

@interface IQUSDKUtils ()
@end

#pragma mark - IMPLEMENTATION

@implementation IQUSDKUtils

#pragma mark - Public methods

/**
  Implements the currentTimeMillis method.
*/
+ (int64_t)currentTimeMillis {
  return (int64_t)([[NSDate date] timeIntervalSince1970] * 1000.0);
}

/**
  Implements the toJSON method.
*/
+ (NSString*)toJSON:(NSDictionary*)aCollection {
  NSError* error;
#ifdef IQUSDK_DEBUG
  NSData* jsonData =
      [NSJSONSerialization dataWithJSONObject:aCollection
                                      options:NSJSONWritingPrettyPrinted
                                        error:&error];
#else
  NSData* jsonData = [NSJSONSerialization dataWithJSONObject:aCollection
                                                     options:0
                                                       error:&error];
#endif
  if (!jsonData) {
    NSLog(@"toJSON: error: %@", error.localizedDescription);
    return @"{}";
  } else {
    return
        [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
  }
}

@end
