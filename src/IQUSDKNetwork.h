#import <Foundation/Foundation.h>
#import "IQUSDKMessageQueue.h"

#pragma mark - INTERFACE

/**
  IQUNetwork takes care of sending data to the IQU server. It assumes the network IO related methods are called from a separate thread 
  and can block until the IO action has finished.
*/
@interface IQUSDKNetwork : NSObject

#pragma mark - Public methods

/**
  Initializes a new instance of the class.
 
  @param anApiKey API key
  @param aSecretKey Secret key
*/
- (instancetype)init:(NSString*)anApiKey secretKey:(NSString*)aSecretKey;

/**
  Cleans up references and resources.
*/
- (void)destroy;

/**
  Tries to send one or more messages to server.
 
  @param aMessages MessageQueue to send
 
  @return <code>true</code> if sending was successful, <code>false</code> if not.
*/
- (bool)send:(IQUSDKMessageQueue*)aMessages;

/**
  Tries to send a small message to the server to see if it is reachable.
 
  @return <code>true</code> when message could be sent, <code>false</code> if not.
*/
- (bool)checkServer;

/**
  Cancels current IO (if any). The cancellation will take max 10 milliseconds. This method can be called from other threads.
*/
- (void)cancelSend;


@end
