#import <Foundation/Foundation.h>
#import "IQUSDKIDs.h"

#pragma mark - Classes referenced

@class IQUSDKMessageQueue;
@class IQUSDKIDs;

#pragma mark - INTERFACE

/**
  IQUSDKMessage encapsulates a single message for the server. A message exists of an event and ids.
*/
@interface IQUSDKMessage : NSObject<NSCoding>

#pragma mark - Public properties

/**
  The next property contains the next message in the linked list chain.
*/
@property IQUSDKMessage* next;

/**
  The eventType property contains the type of event or an empty string if
  the type could not be determined.
*/
@property (readonly) NSString* eventType;

/**
  The queue property contains the queue the message is currently part of.
*/
@property IQUSDKMessageQueue* queue;

#pragma mark - Public methods

/**
  Initializes a new message instance and set the ids and event.
 
  @param anIds Ids to use (a copy is stored)
  @param anEvent Event the message encapsulates
*/
- (instancetype)init:(IQUSDKIDs*)anIDs event:(id)anEvent;

/**
  Removes references and resources.
*/
- (void)destroy;

/**
  Update an id with a new value. For certain types the id only gets updated
  if it is empty.
 
  @param aType Type to update
  @param aNewValue New value to use
*/
- (void)updateID:(IQUSDKIDType)aType newValue:(NSString*)aNewValue;

/**
  Returns the ids and event as JSON formatted string, using the following
  format:
 
      { "identifiers":{..}, "event":{..} }
 
  The dirty JSON state will be reset.
 
  @return JSON formatted object definition string
*/
- (NSString*)toJSONString;

#pragma mark - NSCoder

/**
  Initializes a message instance from a NSCoder. The queue and next properties are initialized to nil.
 
  @param aCoder NSCoder instance to initialize message with.
*/
- (instancetype)initWithCoder:(NSCoder *)aCoder;

/**
   Store message using NSCoder.
 
   @param aCoder NSCoder instance to store message in.
*/
- (void)encodeWithCoder:(NSCoder *)aCoder;

@end
