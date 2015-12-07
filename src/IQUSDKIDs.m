#import "IQUSDKConfig.h"
#import "IQUSDKIDs.h"
#import "IQUSDKUtils.h"

#pragma mark - PRIVATE DEFINITIONS

@interface IQUSDKIDs ()

#pragma mark - Private properties

/**
  Storage space for key & value pairs.
*/
@property NSMutableDictionary* m_ids;

#pragma mark - Private methods

/**
   Gets a name to use within JSON for a certain type.
 
   @param aType IQUSDKIDType value to get name for
 
   @return name to use in JSON data
*/
- (NSString*)getJSONName:(IQUSDKIDType)aType;

@end

#pragma mark - IMPLEMENTATION

@implementation IQUSDKIDs

#pragma mark - Private consts

/**
  Define an array with all types (since objective c can not enumerate over enum types)
*/
static IQUSDKIDType const m_types[] = {IQUSDKIDTypeCustom,
                                       IQUSDKIDTypeFacebook,
                                       IQUSDKIDTypeGooglePlus,
                                       IQUSDKIDTypeIOSAdvertising,
                                       IQUSDKIDTypeIOSAdTracking,
                                       IQUSDKIDTypeIOSVendor,
                                       IQUSDKIDTypeSDK,
                                       IQUSDKIDTypeTwitter};

/**
  Key used with NSCoder.
*/
static NSString* const IDsKey = @"IDs";

#pragma mark - Initializers

/**
  Initializes the new instance.
*/
- (instancetype)init {
  self = [super init];
  if (self != nil) {
    self.m_ids = [[NSMutableDictionary alloc] init];
  }
  return self;
}

/**
  Implements the initWithCoder method.
*/
- (instancetype)initWithCoder:(NSCoder*)aCoder {
  self = [super init];
  if (self != nil) {
    self.m_ids = [aCoder decodeObjectForKey:IDsKey];
  }
  return self;
}

/**
  Initializes a new instance copying the ids from another instance.
 
  @param anIDs Instance to copy values from.
*/
- (instancetype)init:(IQUSDKIDs*)anIDs {
  self = [super init];
  if (self != nil) {
    self.m_ids = anIDs.m_ids.mutableCopy;
  }
  return self;
}

#pragma mark - Public methods

/**
  Implements the destroy method.
*/
- (void)destroy {
  self.m_ids = nil;
}

/**
  Implements encodeWithCoder method.
*/
- (void)encodeWithCoder:(NSCoder*)aCoder {
  [aCoder encodeObject:self.m_ids forKey:IDsKey];
}

/**
  Implements the get method.
*/
- (NSString*)get:(IQUSDKIDType)aType {
  NSString* result = nil;
  switch (aType) {
    default:
      result = [self.m_ids objectForKey:@(aType)];
      break;
  }
  return result == nil ? @"" : result;
}

/**
  Implements the set method.
*/
- (void)set:(IQUSDKIDType)aType value:(NSString*)aValue {
  [self.m_ids setObject:aValue forKey:@(aType)];
}

/**
  Implements the clone method.
*/
- (instancetype)clone {
  return [[IQUSDKIDs alloc] init:self];
}

/**
  Implements the toJSONString method.
*/
- (NSString*)toJSONString {
  // build a collection for non empty ids using JSON name of the type for key
  // and the id value as value.
  NSMutableDictionary* collection = [[NSMutableDictionary alloc] initWithCapacity:self.m_ids.count];
  for (int index = (sizeof m_types) / (sizeof m_types[0]) - 1; index >= 0; index--) {
    IQUSDKIDType type = m_types[index];
    NSString* value = [self get:type];
    if (value.length > 0) {
      [collection setObject:value forKey:[self getJSONName:type]];
    }
  }
  return [IQUSDKUtils toJSON:collection];
}

#pragma mark - Private methods

/**
  Implements the getJSONName method.
*/
- (NSString*)getJSONName:(IQUSDKIDType)aType {
  switch (aType) {
    case IQUSDKIDTypeIOSVendor:
      return @"ios_vendor_id";
    case IQUSDKIDTypeIOSAdvertising:
      return @"ios_advertising_identifier";
    case IQUSDKIDTypeIOSAdTracking:
      return @"ios_ad_tracking";
    case IQUSDKIDTypeCustom:
      return @"custom_user_id";
    case IQUSDKIDTypeFacebook:
      return @"facebook_user_id";
    case IQUSDKIDTypeGooglePlus:
      return @"google_plus_user_id";
    case IQUSDKIDTypeSDK:
      return @"iqu_sdk_id";
    case IQUSDKIDTypeTwitter:
      return @"twitter_user_id";
    default:
      return [NSString stringWithFormat:@"unknown_type_%d", (int)aType];
  }
}

@end
