#import <Foundation/Foundation.h>
#import "IQUSDKIDType.h"

#pragma mark - INTERFACE

@interface IQUSDKIDs : NSObject<NSCoding>

#pragma mark - Public methods

/**
  Initializes a the instance from a NSCoder.
 
  @param aCoder NSCoder instance to initialize with.
*/
- (instancetype)initWithCoder:(NSCoder *)aCoder;

/**
  Cleans up references and used resources.
*/
- (void)destroy;

/**
  Returns a id value for a certain type. If the id is not known, an empty
  string is returned.
 
  @param aType Id type to get value for.
 
  @return id value or "" if no value was stored for that type.
*/
- (NSString*)get:(IQUSDKIDType)aType;

/**
  Store a value for a certain type. Any previous value is overwritten.
 
  @param aType Type to store value for.
  @param aValue Value to store for the type.
*/
- (void)set:(IQUSDKIDType)aType value:(NSString*)aValue;

/**
   Store IDs using NSCoder.
 
   @param aCoder NSCoder instance to store IDs in.
*/
- (void)encodeWithCoder:(NSCoder *)aCoder;

/**
  Return a copy of this instance.
 
  @return IQUIds instance containing same ids.
*/
- (IQUSDKIDs*)clone;

/**
  Returns ids as JSON formatted string; only non empty ids are returned.
 
  @return JSON formatted string
*/
- (NSString*)toJSONString;

@end
