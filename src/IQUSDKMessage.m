#import "IQUSDKConfig.h"
#import "IQUSDKMessage.h"
#import "IQUSDKMessageQueue.h"

#pragma mark - INTERFACE

@interface IQUSDKMessage ()

#pragma mark - Private properties

/**
  The event (as JSON string)
*/
@property NSString* m_event;

/**
  The ids.
*/
@property IQUSDKIDs* m_ids;

@end

#pragma mark - IMPLEMENTATION

@implementation IQUSDKMessage

#pragma mark - Private consts

/**
  Key used with NSCoder.
*/
static NSString* const EventKey = @"Event";

/**
  Key used with NSCoder.
*/
static NSString* const EventTypeKey = @"EventType";

/**
  Key used with NSCoder.
*/
static NSString* const IdsKey = @"IDs";

#pragma mark - Initializers

/**
  Implements the init:event method.
*/
- (instancetype)init:(IQUSDKIDs*)anIDs event:(NSDictionary*)anEvent {
  self = [super init];
  if (self != nil) {
    NSError* error;
    NSData* jsonData = [NSJSONSerialization dataWithJSONObject:anEvent
                                                       options:0 error:&error];
    self.m_event = [[NSString alloc] initWithData:jsonData
                                         encoding:NSUTF8StringEncoding];
    self.m_ids = [anIDs clone];
    self->_eventType = [anEvent objectForKey:@"type"];
    self->_next = nil;
    self->_queue = nil;
  }
  return self;
}

#pragma mark - Public methods

/**
  Implements destroy method.
*/
- (void)destroy {
  self->_next = nil;
  self->_queue = nil;
  if (self.m_ids != nil) {
    [self.m_ids destroy];
    self.m_ids = nil;
  }
}

/**
  Implements the updateID method.
*/
- (void)updateID:(IQUSDKIDType)aType newValue:(NSString*)aNewValue {
  NSString* currentValue = [self.m_ids get:aType];
  switch (aType) {
    case IQUSDKIDTypeCustom:
    case IQUSDKIDTypeFacebook:
    case IQUSDKIDTypeGooglePlus:
    case IQUSDKIDTypeTwitter:
    case IQUSDKIDTypeSDK:
      if (currentValue.length > 0) return;
      break;
    default:
      break;
  }
  if (![currentValue isEqualToString:aNewValue]) {
    [self.m_ids set:aType value:aNewValue];
    [self.queue onMessageChanged:self];
  }
  
}

/**
  Implements the toJSONString method.
*/
- (NSString*)toJSONString {
  return [NSString stringWithFormat:@"{\"identifiers\":%@,\"event\":%@}", [self.m_ids toJSONString], self.m_event];
}

#pragma mark - NSCoder

/**
  Implements the initWithCoder method.
*/
- (instancetype)initWithCoder:(NSCoder *)aCoder {
  self = [super init];
  if (self != nil) {
    self.m_event = [aCoder decodeObjectForKey:EventKey];
    self.m_ids = [aCoder decodeObjectForKey:IdsKey];
    self->_eventType = [aCoder decodeObjectForKey:EventTypeKey];
    self->_next = nil;
    self->_queue = nil;
  }
  return self;
}

/**
  Implements the encodeWithCoder method.
*/
- (void)encodeWithCoder:(NSCoder *)aCoder {
  [aCoder encodeObject:self.m_event forKey:EventKey];
  [aCoder encodeObject:self.m_ids forKey:IdsKey];
  [aCoder encodeObject:self->_eventType forKey:EventTypeKey];
}

@end
