#import "IQUSDKConfig.h"
#import "IQUSDKLocalStorage.h"

#pragma mark - PRIVATE DEFINITIONS

@interface IQUSDKLocalStorage ()

#pragma mark - Private properties

/**
  Storage space for key & value pairs.
*/
@property NSUserDefaults* m_userDefaults;

@end

#pragma mark - IMPLEMENTATION

@implementation IQUSDKLocalStorage

#pragma mark - Initializers

/**
  Initializes the instance.
*/
- (instancetype)init {
  self = [super init];
  if (self != nil) {
    self.m_userDefaults = [NSUserDefaults standardUserDefaults];
  }
  return self;
}

#pragma mark - Public methods

/**
  Implements the setString method.
*/
- (void)setString:(NSString*)aKey value:(NSString*)aValue {
  [self.m_userDefaults setObject:aValue forKey:aKey];
}

/**
  Implements the getString method.
*/
- (NSString*)getString:(NSString*)aKey {
  return [self getString:aKey defaultValue:@""];
}

/**
  Implements the getString method.
*/
- (NSString*)getString:(NSString*)aKey defaultValue:(NSString*)aDefault {
  return ([self.m_userDefaults objectForKey:aKey] == nil)
             ? aDefault
             : [self.m_userDefaults stringForKey:aKey];
}

/**
  Implements the save method.
*/
- (void)save {
  [self.m_userDefaults synchronize];
}

/**
  Implements the destroy method.
*/
-(void)destroy {
    self.m_userDefaults = nil;
}

@end