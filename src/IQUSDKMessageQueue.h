#import <Foundation/Foundation.h>
#import "IQUSDKIDType.h"

#pragma mark - Classes referenced

@class IQUSDKMessage;

#pragma mark - INTERFACE

/**
  IQUSDKMessageQueue manages a list of IQUSDKMessage instances. It can store
  the messages to a local storage and return the whole list as a JSON string.
*/
@interface IQUSDKMessageQueue : NSObject

#pragma mark - Public methods

/**
  Checks if the queue does not contain any message.
 
  @return <code>true</code> if queue is empty.
*/
- (bool)isEmpty;

/**
  Adds a message to the end of the queue.
 
  @param aMessage Message to add to the queue.
*/
- (void)add:(IQUSDKMessage*)aMessage;

/**
  Moves the items from another queue to the front of this queue.
 
  After this call, aQueue will be empty.
 
  @param aQueue The queue to insert before this queue.
  @param aChangeQueue When <code>true</code> change the queue property in every message to this queue.
*/
- (void)prepend:(IQUSDKMessageQueue*)aQueue changeQueue:(bool)aChangeQueue;

/**
  Destroy the queue. It will call destroy on every message and remove any reference to each message instance.

  After this method, the queue will be empty and can be filled again.
*/
- (void)destroy;

/**
  Counts the number of messages in the queue.
 
  @return number of messages
*/
- (int)getCount;

/**
  Destroy the queue. It will call destroy on every message and remove any reference to each message instance.

  After this method, the queue will be empty and can be filled again.
 
  @param aClearStorage When <code>true</code> clear the persistently stored messages.
*/
- (void)clear:(bool)aClearStorage;

/**
  Saves the messages to persistent storage. This method only performs the save if new messages have been added or one of the messages changed.
*/
- (void)save;

/**
  Loads the messages from persistent storage.
*/
- (void)load;

/**
  Returns the queue as a JSON formatted string.
 
  @return JSON formatted string.
*/
- (NSString*)toJSONString;

/**
  Update an id within all the stored messages.
 
  @param aType Id type to update value for.
  @param aNewValue New value to use.
*/
- (void)updateID:(IQUSDKIDType)aType newValue:(NSString*)aNewValue;

/**
  Checks if queue contains at least one message for a certain event type.
 
  @param aType Event type to check
 
  @return <code>true</code> if there is at least one message,
          <code>false</code> if not.
*/
- (bool)hasEventType:(NSString*)aType;

/**
  This handler is called by IQUMessage when the contents changes.
 
  @param aMessage Message with changed content
*/
- (void)onMessageChanged:(IQUSDKMessage*)aMessage;

@end
