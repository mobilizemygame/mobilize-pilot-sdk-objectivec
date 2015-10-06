#import "IQUSDKConfig.h"
#import "IQUSDK.h"
#import "IQUSDKIDs.h"
#import "IQUSDKLocalStorage.h"
#import "IQUSDKMessageQueue.h"
#import "IQUSDKMessage.h"
#import "IQUSDKNetwork.h"
#import "IQUSDKUtils.h"
#ifdef TARGET_OS_IPHONE
@import UIKit;
@import CoreTelephony;
#endif

#pragma mark - PRIVATE DEFINITIONS

@interface IQUSDK ()

#pragma mark - Private properties

/**
  Contains the various ids.
*/
@property IQUSDKIDs* m_ids;

/**
  The paused state of the application
*/
@property bool m_updateThreadPaused;

/**
  When true doUpdate call is busy.
*/
@property bool m_updateThreadBusy;

/**
  When true update() should sleep and recheck this value.
*/
@property bool m_updateThreadWait;

/**
  Thread used to call update()
*/
@property NSThread* m_updateThread;

/**
  While this value is true the thread keeps running in an infinite loop
*/
@property bool m_updateThreadRunning;

/**
  Will be true until update is called at least once.
*/
@property bool m_firstUpdateCall;

/**
  Network part of IQU SDK.
*/
@property IQUSDKNetwork* m_network;

/**
  Local storage part of IQU SDK.
*/
@property IQUSDKLocalStorage* m_localStorage;

/**
  Contains messages that are pending to be sent.
*/
@property IQUSDKMessageQueue* m_pendingMessages;

/**
  Contains messages currently being sent.
*/
@property IQUSDKMessageQueue* m_sendingMessages;

/**
  Time before a new server check is allowed.
*/
@property int64_t m_checkServerTime;

/**
  Time of last heartbeat message.
*/
@property int64_t m_heartbeatTime;

/**
  Use a dispatch semaphore to stop the update thread from waiting.
*/
@property dispatch_semaphore_t m_updateSemaphore;

/**
  Used to handle access to a property from multiple threads.
*/
@property NSObject* m_propertyLock;

/**
  Contains the log.
*/
@property NSMutableString* m_log;

/**
  Used to format date and time for use by the server.
*/
@property NSDateFormatter* m_dateFormat;

#pragma mark - Private initilization methods

/**
  Initializes the instance. This method takes care of all initialization
  except obtaining the id.
 
  @param anApiKey The API key
  @param aSecretKey The secret key
*/
- (void)initialize:(NSString*)anApiKey secretKey:(NSString*)aSecretKey payable:(bool)aPayable;

/**
  Initializes the SDK further from within the update thread. This method is called the first time update is called from
  within the separate update thread.
*/
- (void)initializeFromUpdateThread;

/**
  Clears references to instances.
*/
- (void)clearReferences;

#pragma mark - Private ID related methods

/**
  Sets the id and source.
 
  @param anId ID to use
  @param aSource ID source to use
*/
- (void)setID:(IQUSDKIDType)aType value:(NSString*)anID;

/**
  Obtains the id managed by the SDK. Try to retrieve it from local
  storage, if it fails create a new id.
*/
- (void)obtainSDKID;

/**
  Try to obtain the advertising id. This method might change the analyticsEnabled property.
 
  For OSX targets this method will do nothing.
*/
- (void)obtainAdvertisingID;

/**
  Obtain the vendor ID and store it. If the vendor ID is not available, the method will use
  [UIDevice currentDevice].uniqueIdentifier (iOS version below 6.0)
 
  For OSX targets this method will do nothing.
*/
- (void)obtainVendorID;

#pragma mark - Private thread related methods

/**
  Updates IQU, this method is called from a separate thread context.
*/
- (void)update;

/**
  Starts the update thread.
*/
- (void)startUpdateThread;

/**
  Destroys the update thread (if any).
*/
- (void)destroyUpdateThread;

/**
  Pauses the update thread, set thread paused to true and wait for the
  update thread to finish.
*/
- (void)pauseUpdateThread;

/**
  Resumes the paused thread.
*/
- (void)resumeUpdateThread;

/**
  Waits for the update thread to finish to current update call.
*/
- (void)waitForUpdateThread;

#pragma mark - Private message related methods

/**
  Processes the pending messages (if any) and try to send them to the server.
*/
- (void)processPendingMessages;

/**
  Tries to send the messages to the server. When successful the messages
  get destroyed, else the messages get saved. This method will also update
  the serverAvailable property.
 
  @param aMessages Messages to send to the server.
*/
- (void)sendMessages:(IQUSDKMessageQueue*)aMessages;

/**
  Adds a message to the pending message list. The method is thread safe
  blocking any access to the pending message queue while it's busy adding
  the message.
 
  @param aMessage Message to add.
*/
- (void)addMessage:(IQUSDKMessage*)aMessage;

#pragma mark - Private event related methods

/**
  Creates a message from an event and add it to the pending queue.
 
  @param anEvent Event to create message for.
*/
- (void)addEvent:(NSDictionary*)anEvent;

/**
  Creates an event with a certain type and adds optionally a time-stamp for
  the current date and time.
 
  @param anEventType Type to use
  @param anAddTimestamp When <code>true</code> add "timestamp" field.
 
  @return JSONObject instance containing event
*/
- (NSMutableDictionary*)createEvent:(NSString*)anEventType addTimestamp:(bool)anAddTimestamp;

/**
  Checks if pending messages contain at least one message of a certain
  event type.
 
  @param aType Type to check.
 
  @return <code>true</code> if at least one message exists,
          <code>false</code> if not.
*/
- (bool)messagesHasEventType:(NSString*)aType;

#pragma mark - Private support methods

/**
  Checks if the server is available.
 
  @return <code>true</code> if the server is available, <code>false</code>
          if not.
*/
- (bool)checkServer;

#pragma mark - Private tracking methods

/**
  Checks if enough time has passed since last heartbeat message. If it has
  the method adds a new heartbeat message.
 
  @param aMessages Message queue to add the heartbeat message to.
*/
- (void)trackHeartbeat:(IQUSDKMessageQueue*)aMessages;

/**
  Creates a platform event and add it to the pending message queue.
*/
- (void)trackPlatform;

#pragma mark - Event handlers

/**
  Handles the application being switched to the background. Pause the update thread and save any pending messages.
*/
- (void)handleEnterBackground;

/**
  Handles the application returning to the foreground. Resume the update thread.
*/
- (void)handleEnterForeground;

/**
  Handles the application terminating. Destroy the update the instance and save any pending messages.
*/
- (void)handleTerminate;

@end

#pragma mark - IMPLEMENTATION

@implementation IQUSDK

#pragma mark - Synthesize

/**
  Synthesize all properties since all getters and setters are implemented
  because of multi-thread safety.
*/
@synthesize initialized = _initialized;
@synthesize analyticsEnabled = _analyticsEnabled;
@synthesize payable = _payable;
@synthesize updateInterval = _updateInterval;
@synthesize sendTimeout = _sendTimeout;
@synthesize checkServerInterval = _checkServerInterval;
@synthesize logEnabled = _logEnabled;
@synthesize testMode = _testMode;
@synthesize serverAvailable = _serverAvailable;

#pragma mark - Static variables

/**
  Contains the current singleton instance.
*/
static id __strong m_instance = nil;

#pragma mark - Private consts

/**
  Local storage key for the id.
*/
static NSString* const IDKey = @"IQU_SDK_ID";

/**
  Initial update interval value
*/
static const int DefaultUpdateInterval = 200;

/**
  Initial send time-out value
*/
static const int DefaultSendTimeout = 20000;

/**
  Initial interval in milliseconds between server available checks
*/
static const int DefaultCheckServerInterval = 2000;

/**
  Interval in milliseconds between heartbeat messages
*/
static const int HeartbeatInterval = 60000;

/**
  Event type values.
*/
static NSString* const EventRevenue = @"revenue";
static NSString* const EventHeartbeat = @"heartbeat";
static NSString* const EventItemPurchase = @"item_purchase";
static NSString* const EventTutorial = @"tutorial";
static NSString* const EventMilestone = @"milestone";
static NSString* const EventMarketing = @"marketing";
static NSString* const EventUserAttribute = @"user_attribute";
static NSString* const EventCountry = @"country";
static NSString* const EventPlatform = @"platform";

#pragma mark - Initializers

/**
  Initializes the instance.
*/
- (instancetype)init {
  self = [super init];
  if (self != nil) {
    // initialize public properties
    self->_analyticsEnabled = true;
    self->_checkServerInterval = DefaultCheckServerInterval;
    self->_initialized = false;
    self->_logEnabled = false;
    self->_sendTimeout = DefaultSendTimeout;
    self->_serverAvailable = true;
    self->_testMode = IQUSDKTestModeNone;
    self->_updateInterval = DefaultUpdateInterval;
    // initialize private properties
    self.m_checkServerTime = 0;
    self.m_dateFormat = [[NSDateFormatter alloc] init];
    [self.m_dateFormat setDateFormat:@"yyyy'-'MM'-'dd' 'HH':'mm':'ss"];
    self.m_firstUpdateCall = true;
    self.m_heartbeatTime = 0;
    self.m_ids = [[IQUSDKIDs alloc] init];
    self.m_localStorage = nil;
    self.m_log = [[NSMutableString alloc] initWithString:@""];
    self.m_network = nil;
    self.m_pendingMessages = nil;
    self.m_propertyLock = [[NSObject alloc] init];
    self.m_sendingMessages = nil;
    self.m_updateSemaphore = dispatch_semaphore_create(0);
    self.m_updateThread = nil;
    self.m_updateThreadBusy = false;
    self.m_updateThreadPaused = false;
    self.m_updateThreadRunning = false;
    self.m_updateThreadWait = false;
  }
  return self;
}

#pragma mark - Public methods

/**
  Implements the addLog method.
*/
- (void)addLog:(NSString*)aMessage {
#ifdef IQUSDK_DEBUG
  @synchronized(self.m_log) {
    // access property variable directly (already synchronized on same lock)
    if (self->_logEnabled) {
      [self.m_log appendString:aMessage];
      [self.m_log appendString:@"\n"];
    }
  }
#endif
}

/**
  Implements the instance method.
*/
+ (instancetype)instance {
  @synchronized(self) {
    if (m_instance == nil) {
      m_instance = [[self alloc] init];
    }
  }
  return m_instance;
}

/**
  Implements the start method.
*/
- (void)start:(NSString*)anApiKey secretKey:(NSString*)aSecretKey {
  [self start:anApiKey secretKey:aSecretKey payable:true];
}

/**
  Implements the start method.
*/
- (void)start:(NSString*)anApiKey secretKey:(NSString*)aSecretKey payable:(bool)aPayable {
  [self initialize:anApiKey secretKey:aSecretKey payable:aPayable];
}

/**
  Implements the start method.
*/
- (void)start:(NSString*)anApiKey secretKey:(NSString*)aSecretKey customID:(NSString*)anID {
  [self start:anApiKey secretKey:aSecretKey payable:true customID:anID];
}

/**
  Implements the start method.
*/
- (void)start:(NSString*)anApiKey secretKey:(NSString*)aSecretKey payable:(bool)aPayable customID:(NSString*)anID {
  [self start:anApiKey secretKey:aSecretKey payable:aPayable];
  [self setCustomID:anID];
}

#pragma mark - Public ID methods

/**
  Implements the getID method.
*/
- (NSString*)getID:(IQUSDKIDType)aType {
  return [self.m_ids get:aType];
}

/**
  Implements the setFacebookID method.
*/
- (void)setFacebookID:(NSString*)anID {
  [self setID:IQUSDKIDTypeFacebook value:anID];
}

/**
  Implements the clearFacebookID method.
*/
- (void)clearFacebookID {
  [self setID:IQUSDKIDTypeFacebook value:@""];
}

/**
  Implements the setGooglePlusID method.
*/
- (void)setGooglePlusID:(NSString*)anID {
  [self setID:IQUSDKIDTypeGooglePlus value:anID];
}

/**
  Implements the clearGooglePlusID method.
*/
- (void)clearGooglePlusID {
  [self setID:IQUSDKIDTypeGooglePlus value:@""];
}

/**
  Implements the setTwitterID method.
*/
- (void)setTwitterID:(NSString*)anID {
  [self setID:IQUSDKIDTypeTwitter value:anID];
}

/**
  Implements the clearTwitterID method.
*/
- (void)clearTwitterID {
  [self setID:IQUSDKIDTypeTwitter value:@""];
}

/**
  Implements the setCustomID method.
*/
- (void)setCustomID:(NSString*)anID {
  [self setID:IQUSDKIDTypeCustom value:anID];
}

/**
  Implements the clearCustomID method.
*/
- (void)clearCustomID {
  [self setID:IQUSDKIDTypeCustom value:@""];
}

#pragma mark - Public analytic methods

/**
  Implements the trackRevenue method.
*/
- (void)trackRevenue:(float)anAmount currency:(NSString*)aCurrency reward:(NSString*)aReward {
  // exit if not enabled or not initialized yet
  if (!self.analyticsEnabled || !self.initialized) {
    return;
  }
  NSMutableDictionary* event = [self createEvent:EventRevenue addTimestamp:true];
  [event setObject:@(anAmount) forKey:@"amount"];
  [event setObject:aCurrency forKey:@"currency"];
  if (aReward != nil) {
    [event setObject:aReward forKey:@"reward"];
  }
  [self addEvent:event];
}

/**
  Implements the trackRevenue method.
*/
- (void)trackRevenue:(float)anAmount currency:(NSString*)aCurrency {
  [self trackRevenue:anAmount currency:aCurrency reward:nil];
}

/**
  Implements the trackRevenue method.
*/
- (void)trackRevenue:(float)anAmount
            currency:(NSString*)aCurrency
     virtualCurrency:(float)aVirtualCurrencyAmount
              reward:(NSString*)aReward {
  // exit if not enabled or not initialized yet
  if (!self.analyticsEnabled || !self.initialized) {
    return;
  }
  NSMutableDictionary* event = [self createEvent:EventRevenue addTimestamp:true];
  [event setObject:@(anAmount) forKey:@"amount"];
  [event setObject:aCurrency forKey:@"currency"];
  [event setObject:@(aVirtualCurrencyAmount) forKey:@"vc_amount"];
  if (aReward != nil) {
    [event setObject:aReward forKey:@"reward"];
  }
  [self addEvent:event];
}

/**
  Implements the trackRevenue method.
*/
- (void)trackRevenue:(float)anAmount currency:(NSString*)aCurrency virtualCurrency:(float)aVirtualCurrencyAmount {
  [self trackRevenue:anAmount currency:aCurrency virtualCurrency:aVirtualCurrencyAmount reward:nil];
}

/**
  Implements the trackItemPurchase method.
*/
- (void)trackItemPurchase:(NSString*)aName {
  // exit if not enabled or not initialized yet
  if (!self.analyticsEnabled || !self.initialized) {
    return;
  }
  NSMutableDictionary* event = [self createEvent:EventItemPurchase addTimestamp:true];
  [event setObject:aName forKey:@"name"];
  [self addEvent:event];
}

/**
  Implements the trackPurchase method.
*/
- (void)trackItemPurchase:(NSString*)aName virtualCurrency:(float)aVirtualCurrencyAmount {
  // exit if not enabled or not initialized yet
  if (!self.analyticsEnabled || !self.initialized) {
    return;
  }
  NSMutableDictionary* event = [self createEvent:EventItemPurchase addTimestamp:true];
  [event setObject:aName forKey:@"name"];
  [event setObject:@(aVirtualCurrencyAmount) forKey:@"vc_amount"];
  [self addEvent:event];
}

/**
  Implements the trackTutorial method.
*/
- (void)trackTutorial:(NSString*)aStep {
  // exit if not enabled or not initialized yet
  if (!self.analyticsEnabled || !self.initialized) {
    return;
  }
  NSMutableDictionary* event = [self createEvent:EventTutorial addTimestamp:true];
  [event setObject:aStep forKey:@"step"];
  [self addEvent:event];
}

/**
  Implements the trackMilestone method.
*/
- (void)trackMilestone:(NSString*)aName value:(NSString*)aValue {
  // exit if not enabled or not initialized yet
  if (!self.analyticsEnabled || !self.initialized) {
    return;
  }
  NSMutableDictionary* event = [self createEvent:EventMilestone addTimestamp:true];
  [event setObject:aName forKey:@"name"];
  [event setObject:aValue forKey:@"value"];
  [self addEvent:event];
}

/**
  Implements the trackMarketing method.
*/
- (void)trackMarketing:(NSString*)aPartner
              campaign:(NSString*)aCampaign
                    ad:(NSString*)anAd
                 subID:(NSString*)aSubID
              subSubID:(NSString*)aSubSubID {
  // exit if not enabled or not initialized yet
  if (!self.analyticsEnabled || !self.initialized) {
    return;
  }
  NSMutableDictionary* event = [self createEvent:EventMarketing addTimestamp:true];
  if (aPartner != nil) {
    [event setObject:aPartner forKey:@"partner"];
  }
  if (aCampaign != nil) {
    [event setObject:aCampaign forKey:@"campaign"];
  }
  if (anAd != nil) {
    [event setObject:anAd forKey:@"ad"];
  }
  if (aSubID != nil) {
    [event setObject:aSubID forKey:@"subid"];
  }
  if (aSubSubID != nil) {
    [event setObject:aSubSubID forKey:@"subsubid"];
  }
  [self addEvent:event];
}

/**
  Implements the trackUserAttribute method.
*/
- (void)trackUserAttribute:(NSString*)aName value:(NSString*)aValue {
  // exit if not enabled or not initialized yet
  if (!self.analyticsEnabled || !self.initialized) {
    return;
  }
  NSMutableDictionary* event = [self createEvent:EventUserAttribute addTimestamp:true];
  [event setObject:aName forKey:@"name"];
  [event setObject:aValue forKey:@"value"];
  [self addEvent:event];
}

/**
  Implements the trackCountry method.
*/
- (void)trackCountry:(NSString*)aCountry {
  // exit if not enabled or not initialized yet
  if (!self.analyticsEnabled || !self.initialized) {
    return;
  }
  NSMutableDictionary* event = [self createEvent:EventCountry addTimestamp:true];
  [event setObject:aCountry forKey:@"value"];
  [self addEvent:event];
}

#pragma mark - Property getters & setters

/**
  Implements initialized setter.
*/
- (void)setInitialized:(bool)aValue {
  @synchronized(self.m_propertyLock) {
    self->_initialized = aValue;
  }
}

/**
  Implements initialized getter.
*/
- (bool)initialized;
{
  @synchronized(self.m_propertyLock) {
    return self->_initialized;
  }
}

/**
  Implements enabled setter.
*/
- (void)setAnalyticsEnabled:(bool)aValue {
  @synchronized(self.m_propertyLock) {
    self->_analyticsEnabled = aValue;
  }
}

/**
  Implements enabled getter.
*/
- (bool)analyticsEnabled;
{
  @synchronized(self.m_propertyLock) {
    return self->_analyticsEnabled;
  }
}

/**
  Implements payable setter.
*/
- (void)setPayable:(bool)aValue {
  @synchronized(self.m_propertyLock) {
    self->_payable = aValue;
  }
}

/**
  Implements payable getter.
*/
- (bool)payable;
{
  @synchronized(self.m_propertyLock) {
    return self->_payable;
  }
}

/**
  Implements updateInterval setter.
*/
- (void)setUpdateInterval:(int)aValue {
  @synchronized(self.m_propertyLock) {
    self->_updateInterval = aValue;
  }
}

/**
  Implements updateInterval getter.
*/
- (int)updateInterval;
{
  @synchronized(self.m_propertyLock) {
    return self->_updateInterval;
  }
}

/**
  Implements sendTimeout setter.
*/
- (void)setSendTimeout:(int)aValue {
  @synchronized(self.m_propertyLock) {
    self->_sendTimeout = aValue;
  }
}

/**
  Implements sendTimeout getter.
*/
- (int)sendTimeout;
{
  @synchronized(self.m_propertyLock) {
    return self->_sendTimeout;
  }
}

/**
  Implements checkServerInterval setter.
*/
- (void)setCheckServerInterval:(int)aValue {
  @synchronized(self.m_propertyLock) {
    self->_checkServerInterval = aValue;
  }
}

/**
  Implements checkServerInterval getter.
*/
- (int)checkServerInterval {
  @synchronized(self.m_propertyLock) {
    return self->_checkServerInterval;
  }
}

/**
  Implements logEnabled setter.
*/
- (void)setLogEnabled:(bool)aValue {
  @synchronized(self.m_log) {
    self->_logEnabled = aValue;
    if (!aValue) {
      [self.m_log setString:@""];
    }
  }
}

/**
  Implements logEnabled getter.
*/
- (bool)logEnabled {
  @synchronized(self.m_log) {
    return self->_logEnabled;
  }
}

/**
  Implements log getter.
*/
- (NSString*)log {
  @synchronized(self.m_log) {
    return self.m_log;
  }
}

/**
  Implements payable setter.
*/
- (void)setServerAvailable:(bool)aValue {
  @synchronized(self.m_propertyLock) {
    self->_serverAvailable = aValue;
  }
}

/**
  Implements payable getter.
*/
- (bool)serverAvailable;
{
  @synchronized(self.m_propertyLock) {
    return self->_serverAvailable;
  }
}

/**
  Implements testMode setter.
*/
- (void)setTestMode:(IQUSDKTestMode)aValue {
  @synchronized(self.m_propertyLock) {
    self->_testMode = aValue;
  }
}

/**
  Implements testMode getter.
*/
- (IQUSDKTestMode)testMode {
  @synchronized(self.m_propertyLock) {
    return self->_testMode;
  }
}

#pragma mark - Private initialization methods

/**
  Implements the initialize method.
*/
- (void)initialize:(NSString*)anApiKey secretKey:(NSString*)aSecretKey payable:(bool)aPayable {
  // exit if already initialized
  if (self.initialized) {
#ifdef IQUSDK_DEBUG
    [self addLog:@"[Init][Error] IQU SDK is already initialized"];
#endif
    return;
  }
  // create local storage
  self.m_localStorage = [[IQUSDKLocalStorage alloc] init];
  // create network
  self.m_network = [[IQUSDKNetwork alloc] init:anApiKey secretKey:aSecretKey];
  // create message queues
  self.m_pendingMessages = [[IQUSDKMessageQueue alloc] init];
  self.m_sendingMessages = [[IQUSDKMessageQueue alloc] init];
  // update properties
  self.payable = aPayable;
  // retrieve or create an unique ID
  [self obtainSDKID];
  // try to get advertising id and limit ad tracking
  [self obtainAdvertisingID];
  // start update thread
  [self startUpdateThread];
#ifdef TARGET_OS_IPHONE
  // handle application state changes within iOS
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(handleEnterBackground)
                                               name:UIApplicationDidEnterBackgroundNotification
                                             object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(handleEnterForeground)
                                               name:UIApplicationWillEnterForegroundNotification
                                             object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(handleTerminate)
                                               name:UIApplicationWillTerminateNotification
                                             object:nil];
#endif
  // instance is now initialized and messages can be sent
  self.initialized = true;
#ifdef IQUSDK_DEBUG
  [self addLog:@"[Init] IQU SDK is initialized"];
#endif
}

/**
  Implements the initializeUpdateThread method.
*/
- (void)initializeFromUpdateThread {
  // obtain the vendor ID
  [self obtainVendorID];
  // clear pending messages if analytics are not allowed to remove any tracking messages added after the initialize call and before this method.
  if (!self.analyticsEnabled) {
    @synchronized(self.m_pendingMessages) {
      [self.m_pendingMessages clear:false];
    }
  }
  // get unsent messages stored in persistent storage
  [self loadMessages];
  // add platform message if there is none and the analytics part is enabled
  if (![self messagesHasEventType:EventPlatform] && self.analyticsEnabled) {
    [self trackPlatform];
  }
}

/**
  Implements the clearReferences method.
*/
- (void)clearReferences {
  if (self.m_localStorage != nil) {
    [self.m_localStorage destroy];
    self.m_localStorage = nil;
  }
  if (self.m_network != nil) {
    [self.m_network destroy];
    self.m_network = nil;
  }
  if (self.m_pendingMessages != nil) {
    [self.m_pendingMessages destroy];
    self.m_pendingMessages = nil;
  }
  if (self.m_sendingMessages != nil) {
    [self.m_sendingMessages destroy];
    self.m_sendingMessages = nil;
  }
  if (self.m_ids != nil) {
    [self.m_ids destroy];
    self.m_ids = nil;
  }
#ifdef TARGET_OS_IPHONE
  [[NSNotificationCenter defaultCenter] removeObserver:self
                                                  name:UIApplicationWillEnterForegroundNotification
                                                object:nil];
  [[NSNotificationCenter defaultCenter] removeObserver:self
                                                  name:UIApplicationDidEnterBackgroundNotification
                                                object:nil];
  [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillTerminateNotification object:nil];
#endif
}

#pragma mark - Private ID related methods

/**
  Implements the setID method.
*/
- (void)setID:(IQUSDKIDType)aType value:(NSString*)anID {
  // store new id
  @synchronized(self.m_ids) {
    [self.m_ids set:aType value:anID];
  }
  // and update all existing messages
  if (self.initialized) {
    @synchronized(self.m_pendingMessages) {
      [self.m_pendingMessages updateID:aType newValue:anID];
    }
  }
}
/**
  Implements the obtainSDKID method.
*/
- (void)obtainSDKID {
  // get id from local storage
  NSString* sdkID = [self.m_localStorage getString:IDKey defaultValue:@""];
  // create new id and store it when none was found
  if (sdkID.length == 0) {
    sdkID = [[NSUUID UUID] UUIDString];
    [self.m_localStorage setString:IDKey value:sdkID];
  }
  // set SDK id
  [self setID:IQUSDKIDTypeSDK value:sdkID];
}

/**
  Implements the obtainAdvertisingID method.
*/
- (void)obtainAdvertisingID {
#ifdef IQUSDK_ADVERTISING_ID
#ifdef TARGET_OS_IPHONE
  // get ASIdentifierManager class
  Class identifierManager = NSClassFromString(@"ASIdentifierManager");
  if (identifierManager != nil) {
    // sharedManager = [ASIdentifierManager sharedManager]
    SEL sharedManagerSel = NSSelectorFromString(@"sharedManager");
    IMP sharedManagerImp = [identifierManager methodForSelector:sharedManagerSel];
    id sharedManager = ((id (*)(id, SEL))sharedManagerImp)(identifierManager, sharedManagerSel);
    if (sharedManager != nil) {
      // call [sharedManager isAdvertisingTrackingEnabled]
      SEL advertisingEnabledSel = NSSelectorFromString(@"isAdvertisingTrackingEnabled");
      IMP advertisingEnabledImp = [sharedManager methodForSelector:advertisingEnabledSel];
      self.analyticsEnabled = ((BOOL (*)(id, SEL))advertisingEnabledImp)(sharedManager, advertisingEnabledSel);
      // call [sharedManager advertisingIdentifier] and store result
      SEL advertisingIdentifierSel = NSSelectorFromString(@"advertisingIdentifier");
      IMP advertisingIdentifierImp = [sharedManager methodForSelector:advertisingIdentifierSel];
      NSUUID* uuid = ((NSUUID* (*)(id, SEL))advertisingIdentifierImp)(sharedManager, advertisingIdentifierSel);
      [self setID:IQUSDKIDTypeIOSAdvertising value:uuid.UUIDString];
    }
  }
#endif
#endif
}

/**
  Implements the obtainVendorID method.
*/
- (void)obtainVendorID {
#ifdef TARGET_OS_IPHONE
  NSString* uuid;
  // use vendor uuid if it is available
  if ([[UIDevice currentDevice] respondsToSelector:NSSelectorFromString(@"identifierForVendor")]) {
    // get vendor uuid as string
    uuid = [UIDevice currentDevice].identifierForVendor.UUIDString;
  } else {
    // vendor id not available, use [UIDevice currentDevice].uniqueIdentifier instead
    UIDevice* currentDevice = [UIDevice currentDevice];
    SEL uniqueIdentifierSel = NSSelectorFromString(@"uniqueIdentifier");
    IMP uniqueIdentifierImp = [currentDevice methodForSelector:uniqueIdentifierSel];
    uuid = ((NSString* (*)(id, SEL))uniqueIdentifierImp)(currentDevice, uniqueIdentifierSel);
  }
  [self setID:IQUSDKIDTypeIOSVendor value:uuid];
#endif
}

#pragma mark - Private thread related methods

/**
  Implements the update method.
*/
- (void)update {
  // store reference to thread
  self.m_updateThread = [NSThread currentThread];
  // loop for ever until running is disabled
  while (self.m_updateThreadRunning) {
    // need to wait?
    while (self.m_updateThreadWait) {
      [NSThread sleepForTimeInterval:0.01];
    }
    // only process if thread is not paused
    if (!self.m_updateThreadPaused) {
      // busy now
      self.m_updateThreadBusy = true;
      // make sure m_updateThreadBusy gets reset to false
      @try {
        // first time update is called?
        if (self.m_firstUpdateCall) {
          [self initializeFromUpdateThread];
          self.m_firstUpdateCall = false;
        }
        // process pending messages
        [self processPendingMessages];
      } @finally {
        // update is no longer busy
        self.m_updateThreadBusy = false;
      }
    }
    // wait and repeat loop, using semaphore so the wait can be interrupted
    int64_t updateInterval = (int64_t)(self.updateInterval) * (int64_t)(NSEC_PER_MSEC);
    dispatch_semaphore_wait(self.m_updateSemaphore, dispatch_time(DISPATCH_TIME_NOW, updateInterval));
  }
  // clear reference
  self.m_updateThread = nil;
}

/**
  Implements the startUpdateThread method.
*/
- (void)startUpdateThread {
  self.m_updateThreadRunning = true;
  [NSThread detachNewThreadSelector:@selector(update) toTarget:self withObject:nil];
}

/**
  Implements the destroyUpdateThread method.
*/
- (void)destroyUpdateThread {
  // update thread is active?
  if (self.m_updateThread != nil) {
    // first pause the thread
    if (!self.m_updateThreadPaused) {
      [self pauseUpdateThread];
    }
    // stop thread from running
    self.m_updateThreadRunning = false;
    // cancel any wait
    dispatch_semaphore_signal(self.m_updateSemaphore);
    // wait till update thread no longer exists.
    while (self.m_updateThread != nil) {
      [NSThread sleepForTimeInterval:0.01f];
    }
  }
}

/**
  Implements the pauseUpdateThread method.
*/
- (void)pauseUpdateThread {
  // prevent update from doing anything (when update call starts while
  // processing this code)
  self.m_updateThreadWait = true;
  @try {
    // thread is paused now
    self.m_updateThreadPaused = true;
    // cancel any IO being executed
    if (self.m_network != nil)
      [self.m_network cancelSend];
  } @finally {
    // unblock update, if it was waiting it will exit immediately
    // because of paused state
    self.m_updateThreadWait = false;
  }
  // wait for update thread to finish current update call
  [self waitForUpdateThread];
}

/**
  Implements the resumeUpdateThread method.
*/
- (void)resumeUpdateThread {
  self.m_updateThreadPaused = false;
}

/**
  Implements the waitForUpdateThread method.
*/
- (void)waitForUpdateThread {
  while (self.m_updateThreadBusy) {
    [NSThread sleepForTimeInterval:0.01];
  }
}

#pragma mark - Private message related methods

/**
  Loads previously saved messages and prepend them to pending messages.
*/
- (void)loadMessages {
  IQUSDKMessageQueue* storedMessages = [[IQUSDKMessageQueue alloc] init];
  [storedMessages load];
  @synchronized(self.m_pendingMessages) {
    [self.m_pendingMessages prepend:storedMessages changeQueue:true];
  }
  [storedMessages destroy];
}

/**
  Implements the processPendingMessages method.
*/
- (void)processPendingMessages {
  // wait till other threads are finished accessing pending message queue.
  @synchronized(self.m_pendingMessages) {
    // move messages from pending messages to sending messages; this
    // will clear the pending message queue. The sending messages queue
    // is always empty before this call.
    // The queue property in every message is not updated, since
    // messages will not change while they are in the sending queue.
    [self.m_sendingMessages prepend:self.m_pendingMessages changeQueue:false];
  }
  // check if a new heartbeat message needs to be created
  [self trackHeartbeat:self.m_sendingMessages];
  // any message that needs to be sent?
  if (![self.m_sendingMessages isEmpty]) {
    // server is available?
    if ([self checkServer]) {
      // try to send the messages
      [self sendMessages:self.m_sendingMessages];
    } else {
      // server not reachable, call save because new messages might
      // have been added since the previous call to this method.
      [self.m_sendingMessages save];
    }
  }
  // wait till other threads are finished accessing pending message queue.
  @synchronized(self.m_pendingMessages) {
    // move any failed messages to the front of the pending messages
    // (this will also clear sending messages queue)
    // The queue property of every message in the sending queue is still
    // pointing to the pending message queue so no need to update it.
    [self.m_pendingMessages prepend:self.m_sendingMessages changeQueue:false];
  }
}

/**
  Implements the sendMessages method.
*/
- (void)sendMessages:(IQUSDKMessageQueue*)aMessages {
  // try to send messages to the server
  if ([self.m_network send:aMessages]) {
    // messages were sent successfully, so destroy them (including the persistent stored messages).
    [aMessages clear:true];
    // server is available
    self.serverAvailable = true;
  } else {
#ifdef IQUSDK_DEBUG
    [self addLog:@"[Network] server is not available"];
#endif
    // messages were not sent, save them
    [aMessages save];
    // server is not available
    self.serverAvailable = false;
  }
}

/**
  Implements the addMessage method.
*/
- (void)addMessage:(IQUSDKMessage*)aMessage {
  if (self.initialized) {
    @synchronized(self.m_pendingMessages) {
      [self.m_pendingMessages add:aMessage];
    }
  } else {
    [aMessage destroy];
  }
}

#pragma mark - Private event related methods

/**
  Implements the addEvent method.
*/
- (void)addEvent:(NSDictionary*)anEvent {
  IQUSDKMessage* message;
  @synchronized(self.m_ids) {
    message = [[IQUSDKMessage alloc] init:self.m_ids event:anEvent];
  }
  [self addMessage:message];
}

/**
  Implements the createEvent method.
*/
- (NSMutableDictionary*)createEvent:(NSString*)anEventType addTimestamp:(bool)anAddTimestamp {
  NSMutableDictionary* result = [[NSMutableDictionary alloc] initWithCapacity:10];
  [result setObject:anEventType forKey:@"type"];
  if (anAddTimestamp) {
    [result setObject:[self.m_dateFormat stringFromDate:[NSDate date]] forKey:@"timestamp"];
  }
  return result;
}

/**
  Implements the messagesHasEventType method.
*/
- (bool)messagesHasEventType:(NSString*)aType {
  // prevent other threads from accessing pending messages
  @synchronized(self.m_pendingMessages) {
    return [self.m_pendingMessages hasEventType:aType];
  }
}

#pragma mark - Private support methods

/**
  Implements the checkServer method.
*/
- (bool)checkServer {
  // server is not available since last check action?
  if (!self.serverAvailable) {
    // get current time
    int64_t currentTime = [IQUSDKUtils currentTimeMillis];
    // enough time has passed since last check?
    if (currentTime < self.m_checkServerTime) {
      // not enough time has passed, don't check, just assume server is
      // still not available
      return false;
    }
    // store new time
    self.m_checkServerTime = currentTime + (int64_t)(self.checkServerInterval);
    // check if the server is reachable and return result
    bool result = [self.m_network checkServer];
#ifdef IQUSDK_DEBUG
    // log if server is available (again)
    if (result)
      [self addLog:@"[Network] server is available"];
#endif
    // return check server result
    return result;
    
  } else {
    // don't perform any checks, if server became unavailable this will
    // be detected when sending messages.
    return true;
  }
}

#pragma mark - Private tracking methods

/**
  Implements the trackHeartbeat method.
*/
- (void)trackHeartbeat:(IQUSDKMessageQueue*)aMessages {
  int64_t currentTime = [IQUSDKUtils currentTimeMillis];
  if (currentTime > self.m_heartbeatTime + HeartbeatInterval) {
    NSMutableDictionary* event = [self createEvent:EventHeartbeat addTimestamp:true];
    [event setObject:@(self.payable) forKey:@"is_payable"];
    @synchronized(self.m_ids) {
      [aMessages add:[[IQUSDKMessage alloc] init:self.m_ids event:event]];
    }
    self.m_heartbeatTime = currentTime;
  }
}

/**
  Implements the trackPlatform method.
*/
- (void)trackPlatform {
  NSMutableDictionary* event = [self createEvent:EventPlatform addTimestamp:false];
  [event setObject:@"Apple" forKey:@"manufacturer"];
  [event setObject:@"Apple" forKey:@"device_brand"];
#ifdef TARGET_OS_IPHONE
  UIDevice* currentDevice = [UIDevice currentDevice];
  [event setObject:currentDevice.model forKey:@"device_model"];
  CTTelephonyNetworkInfo* myNetworkInfo = [[CTTelephonyNetworkInfo alloc] init];
  CTCarrier* myCarrier = [myNetworkInfo subscriberCellularProvider];
  if (myCarrier.carrierName != nil) {
    [event setObject:myCarrier.carrierName forKey:@"device_carrier"];
  }
  [event setObject:currentDevice.systemName forKey:@"os_name"];
  [event setObject:currentDevice.systemVersion forKey:@"os_version"];
  CGRect screenBounds = [[UIScreen mainScreen] bounds];
  CGFloat screenScale = [[UIScreen mainScreen] scale];
  [event setObject:@(screenBounds.size.width * screenScale) forKey:@"screen_size_width"];
  [event setObject:@(screenBounds.size.height * screenScale) forKey:@"screen_size_height"];
  float dpi;
  if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
    dpi = 132 * screenScale;
  } else if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
    dpi = 163 * screenScale;
  } else {
    dpi = 160 * screenScale;
  }
  [event setObject:@(dpi) forKey:@"screen_size_dpi"];
#endif
  [self addEvent:event];
}

#pragma mark - Event handlers

/**
  Implements the onEnterBackground method.
*/
- (void)handleEnterBackground {
  [self pauseUpdateThread];
  if (self.m_localStorage != nil) {
    [self.m_localStorage save];
  }
  if (self.m_pendingMessages != nil) {
    @synchronized(self.m_pendingMessages) {
      [self.m_pendingMessages save];
    }
  }
#ifdef IQUSDK_DEBUG
  [self addLog:@"[SDK] enter background"];
#endif
}

/**
  Implements the onEnterForeground method.
*/
- (void)handleEnterForeground {
  [self resumeUpdateThread];
#ifdef IQUSDK_DEBUG
  [self addLog:@"[SDK] enter foreground"];
#endif
}

/**
  Implements the onTerminate method.
*/
- (void)handleTerminate {
  [self destroyUpdateThread];
  if (self.m_pendingMessages != nil) {
    @synchronized(self.m_pendingMessages) {
      [self.m_pendingMessages save];
    }
  }
  [self clearReferences];
}

@end
