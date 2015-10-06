#import <Foundation/Foundation.h>

#pragma mark - INTERFACE

@interface IQUSDKLocalStorage : NSObject

#pragma mark - Public methods

/**
  Stores string for a certain key.
 
  @param aKey Key to save value for
  @param aValue value to save
*/
- (void)setString:(NSString*)aKey value:(NSString*)aValue;

/**
  Gets a string for a key, if the key does not exists the method will return a
  empty string.
 
  @param aKey Key to get value for.
 
  @return stored string value or empty string.
*/
- (NSString*)getString:(NSString*)aKey;

/**
  Gets a string for a key, if the key does not exists use the default value.
 
  @param aKey Key to get value for.
  @param aDefault Default value to use
 
  @return stored string or aDefault.
*/
- (NSString*)getString:(NSString*)aKey defaultValue:(NSString*)aDefault;

/**
  Saves the local storage to persistent storage.
*/
- (void)save;

/**
  Cleans up references and used resources.
*/
- (void)destroy;

@end