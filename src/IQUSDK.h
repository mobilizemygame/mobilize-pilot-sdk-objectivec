#import <Foundation/Foundation.h>
#import "IQUSDKIDType.h"
#import "IQUSDKTestMode.h"

#pragma mark - INTERFACE

/**
  Defines the IQUSDK class which is used for using IQU analytics services.
*/
@interface IQUSDK : NSObject

#pragma mark - Static methods

/**
  Gets the singleton IQUSDK instance. If no instance exists a new instance will be created.

  @return singleton IQUSDK instance.
*/
+ (instancetype)instance;

#pragma mark - Start methods

/**
  Calls start:secretKey:payable: with <code>true</code> for aPayable parameter.

  @param anApiKey API key
  @param aSecretKey Secret key
 */
- (void)start:(NSString*)anApiKey secretKey:(NSString*)aSecretKey;

/**
  Starts the SDK using and sets the payable property to the specified value.

  If the SDK is already started, another call to this method will be ignored.

  @param anApiKey API key
  @param aSecretKey Secret key
  @param aPayable Initial payable value
 */
- (void)start:(NSString*)anApiKey secretKey:(NSString*)aSecretKey payable:(bool)aPayable;

/**
  Calls start:secretKey:payable:customID with <code>true</code> for aPayable parameter.

  @param anApiKey API key
  @param aSecretKey Secret key
  @param anID A custom ID that the SDK should use.
*/
- (void)start:(NSString*)anApiKey secretKey:(NSString*)aSecretKey customID:(NSString*)anID;

/**
  Calls and then calls setCustomId to store aCustomId.

  If the SDK is already started, another call to this method will only update the custom ID.

  @param anApiKey API key
  @param aSecretKey Secret key
  @param aPayable Initial payable value
  @param anID A custom ID that the SDK should use.
*/
- (void)start:(NSString*)anApiKey secretKey:(NSString*)aSecretKey payable:(bool)aPayable customID:(NSString*)anID;

#pragma mark - ID related methods

/**
  Return ID for a certain type. If the ID is not known (yet), the method will return an empty string.

  @param aType Type to get ID for.

  @return stored ID value or empty string if it not (yet) known.
*/
- (NSString*)getID:(IQUSDKIDType)aType;

/**
  Sets the Facebook ID the SDK should use.

  @param anID Facebook ID.
*/
- (void)setFacebookID:(NSString*)anID;

/**
  Removes the current used Facebook ID.
*/
- (void)clearFacebookID;

/**
  Sets the Google+ ID the SDK should use.

  @param anID Google+ ID.
*/
- (void)setGooglePlusID:(NSString*)anID;

/**
  Removes the current used Google+ ID.
*/
- (void)clearGooglePlusID;

/**
  Sets the Twitter ID the SDK should use.

  @param anID Twitter ID.
*/
- (void)setTwitterID:(NSString*)anID;

/**
  Removes the current used Twitter ID.
*/
- (void)clearTwitterID;

/**
  Sets the custom ID the SDK should use.

  @param anID Custom ID.
*/
- (void)setCustomID:(NSString*)anID;

/**
  Removes the current used custom ID.
*/
- (void)clearCustomID;

#pragma mark - Tracking methods

/**
  Tracks payment made by the user.

  If the IQU SDK has not been initialized or analyticsEnabled is <code>false</code>, this method will do nothing.

  @param anAmount Amount
  @param aCurrency Currency code (ISO 4217 standard)
  @param aReward Name of reward or null if there no such value
*/
- (void)trackRevenue:(float)anAmount currency:(NSString*)aCurrency reward:(NSString*)aReward;

/**
 Tracks revenue, just calls trackRevenue:currency:reward with null for aReward.

 If the IQU SDK has not been initialized or analyticsEnabled is <code>false</code>, this method will do nothing.

  @param anAmount Amount
  @param aCurrency Currency code (ISO 4217 standard)
*/
- (void)trackRevenue:(float)anAmount currency:(NSString*)aCurrency;

/**
  Tracks payment made by the user including an amount in a virtual currency.

  If the IQU SDK has not been initialized or analyticsEnabled is <code>false</code>, this method will do nothing.

  @param anAmount Amount
  @param aCurrency Currency code (ISO 4217 standard)
  @param aVirtualCurrencyAmount Amount of virtual currency rewarded with this purchase
  @param aReward Name of reward or null if there no such value
*/
- (void)trackRevenue:(float)anAmount
            currency:(NSString*)aCurrency
     virtualCurrency:(float)aVirtualCurrencyAmount
              reward:(NSString*)aReward;

/**
  Tracks revenue, just calls trackRevenue:currency:virtualCurrency:reward with null for aReward.

  If the IQU SDK has not been initialized or analyticsEnabled is <code>false</code>, this method will do nothing.

  @param anAmount Amount
  @param aCurrency Currency code (ISO 4217 standard)
  @param aVirtualCurrencyAmount Amount of virtual currency rewarded with this purchase
*/
- (void)trackRevenue:(float)anAmount currency:(NSString*)aCurrency virtualCurrency:(float)aVirtualCurrencyAmount;

/**
  Tracks an item purchase.

  If the IQU SDK has not been initialized or analyticsEnabled is <code>false</code>, this method will do nothing.

  @param aName Name of item
*/
- (void)trackItemPurchase:(NSString*)aName;

/**
  Tracks an item purchase including amount in virtual currency.

  If the IQU SDK has not been initialized or analyticsEnabled is <code>false</code>, this method will do nothing.

  @param aName Name of item
  @param aVirtualCurrencyAmount Amount of virtual currency rewarded with this purchase
*/
- (void)trackItemPurchase:(NSString*)aName virtualCurrency:(float)aVirtualCurrencyAmount;

/**
  Tracks tutorial progression achieved by the user.

  If the IQU SDK has not been initialized or analyticsEnabled is <code>false</code>, this method will do nothing.

  @param aStep Step name or number of the tutorial.
*/
- (void)trackTutorial:(NSString*)aStep;

/**
  Tracks a milestone achieved by the user, e.g. if the user achieved a level.

  If the IQU SDK has not been initialized or analyticsEnabled is <code>false</code>, this method will do nothing.

  @param aName Milestone name
  @param aValue Value of the milestone
*/
- (void)trackMilestone:(NSString*)aName value:(NSString*)aValue;

/**
  Tracks a marketing source. All parameters are optional, if a value is not known nil must be used.

  If the IQU SDK has not been initialized or analyticsEnabled is <code>false</code>, this method will do nothing.

  @param aPartner Marketing partner name or null if there is none.
  @param aCampaign Marketing campaign name or null if there is none.
  @param anAd Marketing ad name or null if there is none.
  @param aSubID Marketing partner sub ID or null if there is none.
  @param aSubSubID Marketing partner sub sub ID or null if there is none.
*/
- (void)trackMarketing:(NSString*)aPartner
              campaign:(NSString*)aCampaign
                    ad:(NSString*)anAd
                 subID:(NSString*)aSubID
              subSubID:(NSString*)aSubSubID;

/**
  Tracks an user attribute, e.g. gender or birthday.

  If the IQU SDK has not been initialized or analyticsEnabled is <code>false</code>, this method will do nothing.

  @param aName Name of the user attribute, e.g. gender
  @param aValue Value of the user attribute, e.g. female
*/
- (void)trackUserAttribute:(NSString*)aName value:(NSString*)aValue;

/**
  Tracks the country of the user, only required for S2S implementations.

  If the IQU SDK has not been initialized or analyticsEnabled is <code>false</code>, this method will do nothing.

  @param aCountry Country as specified in ISO3166-1 alpha-2, e.g. US, NL, DE
*/
- (void)trackCountry:(NSString*)aCountry;

#pragma mark - Public methods for internal use

/**
  Add a message to the log. This method is used by other classes to add debug messages.

  If IQUSDK_DEBUG is not defined then this method will do nothing and the log will stay empty.

  @param aMessage Message to add to the log (messages are separated by \n)
*/
- (void)addLog:(NSString*)aMessage;

#pragma mark - Properties

/**
  This property reflects the limit ad tracking value. When <code>false</code> all tracking calls will be ignored.
*/
@property (readonly, nonatomic) bool analyticsEnabled;

/**
  The initialized state property. After a call to start this property will return <code>true</code>.
*/
@property (readonly, nonatomic) bool initialized;

/**
 The payable property determines if a payable event is active or not.

 The default value is <code>true</code>.
*/
@property (nonatomic) bool payable;

/**
  This property determines the time in milliseconds to wait between update calls.

  Any new value assigned will be used with the next wait call.

  Default value is 200.

  This value determines the maximum delay between creating messages and sending them.
*/
@property (nonatomic) int updateInterval;

/**
  This property determines the maximum time in milliseconds sending a message to the IQU server is allowed to take.

  If there is no response by the IQU server within this time, the SDK assumes the server is not reachable and will set
  the serverAvailable property to <code>false</code>.

  Default value is 20000 (20 seconds).

  The minimum value allowed is 100.
*/
@property (nonatomic) int sendTimeout;

/**
  This property determines the time between server availability checks in milliseconds.

  This property is used once the sending of a message fails. The checkServerInterval property determines the time the
  SDK waits before checking the availability of the server and trying to resend the messages.

  The default value is 2000 (2 seconds).

  The minimum value allowed is 100.
*/
@property (nonatomic) int checkServerInterval;

/**
  Turns the log on or off. When turned on, various IQU SDK methods will add information to the log property.

  The current log will be cleared when turning off the logging.

  The default value is true if IQUSDK_DEBUG is defined, else it is false.

  This property is only of use when IQUSDK_DEBUG is defined, else there is no logging and setting this property to true
  has no effect.
*/
@property (nonatomic) bool logEnabled;

/**
  Gets the current log.
*/
@property (readonly, nonatomic) NSString* log;

/**
  Returns the sever availability state. The state is updated when messages are sent to the server.

  While the server is not available, messages will be queued to be sent once the server is available again.

  If the server is not available and there are pending messages, the class will check the server availability at regular
  intervals. Once the server becomes available again, the messages are sent to the server.
*/
@property (readonly, nonatomic) bool serverAvailable;

/**
  The test mode property can be used during development to simulate a certain situation.

  Use IQUSDKTestModeSimulateServer to prevent any network traffic.

  Use IQUSDKTestModeSimulateOffline to test the SDK behaviour while the server is not available.

  To go back to normal operation use IQUSDKTestModeNone.
*/
@property (nonatomic) IQUSDKTestMode testMode;

@end
