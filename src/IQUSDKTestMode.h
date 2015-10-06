#import <Foundation/Foundation.h>

/**
  IQUSDKTestMode defines the different test modes that can be used while developing.
*/
typedef NS_ENUM(NSInteger, IQUSDKTestMode) {

  /**
    Normal operation mode.
  */
  IQUSDKTestModeNone = 0,

  /**
    Don't perform any network IO, simulate that every transaction is successful.
  */
  IQUSDKTestModeSimulateServer = 1,

  /**
    Simulate that the server is off-line.
  */
  IQUSDKTestModeSimulateOffline = 2

};
