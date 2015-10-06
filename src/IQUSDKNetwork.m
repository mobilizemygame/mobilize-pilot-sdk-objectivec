#import <CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonHMAC.h>
#import "IQUSDKConfig.h"
#import "IQUSDKNetwork.h"
#import "IQUSDK.h"
#import "IQUSDKUtils.h"

#pragma mark - PRIVATE DEFINITIONS

@interface IQUSDKNetwork ()

#pragma mark - Private properties

/**
  Contains the API key to use.
*/
@property NSString* m_apiKey;

/**
  Contains the secret key to use.
*/
@property NSString* m_secretKey;

/**
  When true cancel any active IO running.
*/
@property bool m_cancel;

/**
  Result of an URL request.
*/
@property NSDictionary* m_result;

/**
  Data received from server.
*/
@property NSMutableData* m_responseData;

/**
  Response received.
*/
@property NSHTTPURLResponse* m_httpResponse;

/**
  Will contain the current active connection.
*/
@property NSURLConnection* m_connection;

#pragma mark - Private methods

/**
  Sleep for 1 second, unless IO got cancelled.
*/
- (void)sleepThread;

/**
   Generates a SHA512 hash and returns the hash as a hex string.

   @param aText Text to generate hash for
   @param aKey  Key to use to generate hash

   @return hash as hex string
*/
- (NSString*)sha512:(NSString*)aText withKey:(NSString*)aKey;

/**
  Simulate off-line behaviour. The method waits for 1 second and then returns a NSDictionary with only an error field.

  @param anURL URL to send to
  @param aPostContent POST data to send

  @return NSDictionary with only an error field.
*/
- (NSDictionary*)simulateOffline:(NSString*)anURL postContent:(NSString*)aPostContent;

/**
  Simulate a server IO. The IO is always successful.

  @param anURL URL to post to
  @param aPostContent Content to post
  @return NSDictionary with a successful result.
*/
- (NSDictionary*)simulateServer:(NSString*)anURL postContent:(NSString*)aPostContent;

/**
   Creates a request from an URL and optional POST data.

   @param anURL        URL to send request to
   @param aPostContent POST data or nil if there is no POST data.

   @return NSURLRequest instance.
*/
- (NSURLRequest*)createRequest:(NSString*)anURL postContent:(NSString*)aPostContent;

/**
   Sends data to the server.

   @param aRequest Request contains the URL and optional POST data.
*/
- (void)sendData:(NSURLRequest*)aRequest;

/**
   Checks if a http response was received and add statusCode to the dictionary if it did.

   @param aDictionary Dictionary to add code to (if any)
*/
- (void)addStatusCode:(NSMutableDictionary*)aDictionary;

/**
  Sends a request to the server and processes the result.

  If an error occurred while sending, the result will contain a field
  ERROR.

  The response code (if any) is stored in the field CODE.

  @param anURL URL to send request to
  @param aPostContent POST content to send or null if there is no POST content.

  @return NSDictionary with result
*/
- (NSDictionary*)send:(NSString*)anURL postContent:(NSString*)aPostContent;

/**
  Determines signature from post content, adds it to the url as parameters and continue with normal send operation. The
  url should not contain other parameters.

  @param anURL URL to send content to and to add parameters to
  @param aPostContent POST content to send

  @return NSDictionary instance with result
*/
- (NSDictionary*)sendSigned:(NSString*)anURL postContent:(NSString*)aPostContent;

#pragma mark - NSURLConnection callbacks

/**
  This method is called from NSURLConnection and handles the response received from the server.

  @param aConnection Connection calling this method.
  @param aResponse   Response received from the server.
*/
- (void)connection:(NSURLConnection*)aConnection didReceiveResponse:(NSURLResponse*)aResponse;

/**
  This method is called from NSURLConnction and handles any data received from the server.

  @param aConnection Connection calling this method.
  @param aData       Data received from the server.
*/
- (void)connection:(NSURLConnection*)aConnection didReceiveData:(NSData*)aData;

/**
  This method is called from NSURLConnection, it just returns nil to disable any caching.

  @param aConnection     Connection calling this method.
  @param aCachedResponse NSCachedURLResponse instance.

  @return will return nil
*/
- (NSCachedURLResponse*)connection:(NSURLConnection*)aConnection
                 willCacheResponse:(NSCachedURLResponse*)aCachedResponse;

/**
   This method is called from NSURLConnection when all response data has been received successfully.

   @param aConnection Connection calling this method.
*/
- (void)connectionDidFinishLoading:(NSURLConnection*)aConnection;

/**
   This method is called from NSURLConnection and handles any error that occurred.

   @param aConnection Connection calling this method
   @param anError     Error that occurred
*/
- (void)connection:(NSURLConnection*)aConnection didFailWithError:(NSError*)anError;

@end

#pragma mark - IMPLEMENTATION

@implementation IQUSDKNetwork

#pragma mark - Private consts

/**
  The key value for status code from the response.
*/
static NSString* const CODE = @"RESPONSE_CODE";

/**
  The key value for error codes.
*/
static NSString* const ERROR = @"RESPONSE_ERROR";

/**
  URL to communicate with server with.
*/
static NSString* const URL = @"https://tracker.iqugroup.com/v3/";

#pragma mark - Initializers

/**
  Implements the init method.
*/
- (instancetype)init:(NSString*)anApiKey secretKey:(NSString*)aSecretKey {
  self = [super init];
  if (self != nil) {
    // initialize
    self.m_apiKey = anApiKey;
    self.m_secretKey = aSecretKey;
    self.m_cancel = false;
  }
  return self;
}

#pragma mark - Public methods

/**
  Implements the send method.
*/
- (bool)send:(IQUSDKMessageQueue*)aMessages {
  // send with signature
  NSDictionary* result = [self sendSigned:URL postContent:[aMessages toJSONString]];
  // result contains ERROR key then an error occurred
  if ([result valueForKey:ERROR] != nil) {
    return false;
  }
  // get status
  NSString* status = [result valueForKey:@"status"];
  // if it does not exists an error occurred
  if (status == nil) {
    return false;
  }
  // status should be 'ok' for a successful transaction
  return [status isEqualToString:@"ok"];
}

/**
  Implements the checkServer method.
*/
- (bool)checkServer {
  // just see if ?ping can be reached
  NSDictionary* result = [self send:[NSString stringWithFormat:@"%@?ping", URL] postContent:nil];
  return [result valueForKey:ERROR] == nil;
}

/**
  Implements the cancelSend method.
*/
- (void)cancelSend {
  self.m_cancel = true;
}

/**
  Implements the destroy method.
*/
- (void)destroy {
  // stop any io
  self.m_cancel = true;
  // clear reference to connection
  self.m_connection = nil;
  self.m_httpResponse = nil;
  self.m_responseData = nil;
  self.m_result = nil;
}

#pragma - Private methods

/**
  Implements the sleepThread method.
*/
- (void)sleepThread {
  for (int count = 0; count < 100; count++) {
    if (self.m_cancel)
      break;
    [NSThread sleepForTimeInterval:0.01f];
  }
}

/**
  Generates a SHA512 hash and returns as a hex string.
*/
- (NSString*)sha512:(NSString*)aText withKey:(NSString*)aKey {
  const char* key = [aKey cStringUsingEncoding:NSUTF8StringEncoding];
  const char* data = [aText cStringUsingEncoding:NSUTF8StringEncoding];
  unsigned char digest[CC_SHA512_DIGEST_LENGTH];
  CCHmac(kCCHmacAlgSHA512, key, strlen(key), data, strlen(data), digest);
  // convert digest to hex string
  NSMutableString* hash = [NSMutableString stringWithCapacity:CC_SHA512_DIGEST_LENGTH * 2];
  for (int i = 0; i < CC_SHA512_DIGEST_LENGTH; i++) {
    [hash appendFormat:@"%02x", digest[i]];
  }
  return hash;
}

/**
  Implements the simulateOffline method.
*/
- (NSDictionary*)simulateOffline:(NSString*)anURL postContent:(NSString*)aPostContent {
#ifdef IQUSDK_DEBUG
  [[IQUSDK instance] addLog:@"[Network] simulating offline state (server not available)"];
#endif
  // wait 1 second
  [self sleepThread];
  // return object with only error message
  NSDictionary* result = @{
    ERROR : @"simulating offline [IQUSDK instance].testMode == " @"IQUSDKTestModeSimulateOffline"
  };
  return result;
}

/**
  Implements the simulateServer method.
*/
- (NSDictionary*)simulateServer:(NSString*)anURL postContent:(NSString*)aPostContent {
#ifdef IQUSDK_DEBUG
  [[IQUSDK instance] addLog:@"[Network] simulating successful server response"];
#endif
  [self sleepThread];
  // create result
  NSDictionary* result = @{
    @"request_id" : @"2a7-558bf465ed65-b79a84",
    @"time" : @"2015-06-26 12:00:00 UTC",
    @"status" : @"ok",
    CODE : @(200)
  };
  return result;
}

/**
  Implements the createRequest method.
*/
- (NSURLRequest*)createRequest:(NSString*)anURL postContent:(NSString*)aPostContent {
  // create the request
  NSMutableURLRequest* request =
      [NSMutableURLRequest requestWithURL:[NSURL URLWithString:anURL]
                              cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                          timeoutInterval:((NSTimeInterval)[IQUSDK instance].sendTimeout) / 1000];
  // initialize request without or with POST content
  if (aPostContent == nil) {
    // no post content, so use GET
    request.HTTPMethod = @"GET";
  } else {
    // do post request for parameter passing
    request.HTTPMethod = @"POST";
    // set the content type to JSON
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    // set body
    request.HTTPBody = [aPostContent dataUsingEncoding:NSUTF8StringEncoding];
    // store length of POST data
    NSString* postLength = [NSString stringWithFormat:@"%d", request.HTTPBody.length];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
  }
  // set SDK version and type in header
  [request addValue:@IQUSDK_VERSION forHTTPHeaderField:@"SdkVersion"];
  [request addValue:@IQUSDK_TYPE forHTTPHeaderField:@"SdkType"];
  return request;
}

/**
  Implements the sendData method.
*/
- (void)sendData:(NSURLRequest*)aRequest {
  // reset vars (some will be set by the delegate callbacks)
  self.m_result = nil;
  self.m_responseData = nil;
  self.m_httpResponse = nil;
  self.m_connection = nil;
  // get end time
  int64_t endTime = [IQUSDKUtils currentTimeMillis] + (int64_t)[IQUSDK instance].sendTimeout;
  // create connection using a separate queue
  dispatch_queue_t downloadQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
  dispatch_async(downloadQueue, ^{
    // create connection and start sending data
    self.m_connection = [[NSURLConnection alloc] initWithRequest:aRequest delegate:self startImmediately:YES];
    // connection was not created?
    if (self.m_connection == nil) {
      // set result
      self.m_result = @{ ERROR : @"error: connection could not be created." };
    }
    [[NSRunLoop currentRunLoop] run];
  });
  // wait till either IO has finished, IO is cancelled or time-out has occurred
  while ((self.m_result == nil) && !self.m_cancel && ([IQUSDKUtils currentTimeMillis] < endTime)) {
    [NSThread sleepForTimeInterval:0.01f];
  }
  // connection was not reset while busy?
  if (self.m_connection != nil) {
    // cancel io
    [self.m_connection cancel];
  }
  // clear references
  self.m_connection = nil;
  self.m_responseData = nil;
  self.m_httpResponse = nil;
  // cancelled?
  if (self.m_cancel) {
    self.m_result = @{ ERROR : @"error: io was cancelled." };
  }
  // not finished?
  else if (self.m_result == nil) {
    self.m_result = @{ ERROR : @"error: io did not finish in time (timeout error)." };
  }
}

/**
  Implements the addStatusCode method.
*/
- (void)addStatusCode:(NSMutableDictionary*)aDictionary {
  // received http response?
  if (self.m_httpResponse != nil) {
    [aDictionary setObject:@(self.m_httpResponse.statusCode) forKey:CODE];
  }
}

/**
  Implements the send:postContent method.
*/
- (NSDictionary*)send:(NSString*)anURL postContent:(NSString*)aPostContent {
#ifdef IQUSDK_DEBUG
  // add info to debug
  [[IQUSDK instance] addLog:[NSString stringWithFormat:@"[Network][Sending] %@", anURL]];
  if (aPostContent != nil) {
    [[IQUSDK instance] addLog:[NSString stringWithFormat:@"[Network][Content] %@", aPostContent]];
  }
#endif
  // handle test mode
  switch ([IQUSDK instance].testMode) {
    case IQUSDKTestModeSimulateOffline:
      return [self simulateOffline:anURL postContent:aPostContent];
    case IQUSDKTestModeSimulateServer:
      return [self simulateServer:anURL postContent:aPostContent];
    default:
      break;
  }
  // create request
  NSURLRequest* request = [self createRequest:anURL postContent:aPostContent];
  // perform IO and wait for it to finish
  [self sendData:request];
#ifdef IQUSDK_DEBUG
  [[IQUSDK instance] addLog:[NSString stringWithFormat:@"[Network][Result] %@", self.m_result]];
#endif
  // reset cancel for next time
  self.m_cancel = false;
  // done
  return self.m_result;
}

/**
  Implements the sendSigned method.
*/
- (NSDictionary*)sendSigned:(NSString*)anURL postContent:(NSString*)aPostContent {
  // determine hash
  NSString* hash = [self sha512:aPostContent withKey:self.m_secretKey];
  // add api key and signature to url and continue with normal send action
  return [self send:[NSString stringWithFormat:@"%@?api_key=%@&signature=%@", anURL, self.m_apiKey, hash]
        postContent:aPostContent];
}

#pragma mark - NSURLConnection callbacks

/**
  Implements the connection:didReceiveResponse method.
*/
- (void)connection:(NSURLConnection*)aConnection didReceiveResponse:(NSURLResponse*)aResponse {
  // ignore if it is not the current connection
  if (aConnection != self.m_connection) {
    return;
  }
  // process response later
  self.m_httpResponse = (NSHTTPURLResponse*)aResponse;
  // with redirects this variable gets recreated (clearing any previous received
  // data)
  self.m_responseData = [[NSMutableData alloc] init];
#ifdef IQUSDK_DEBUG
  [[IQUSDK instance]
      addLog:[NSString
                 stringWithFormat:@"[Network][Response] code = %d (%@)", self.m_httpResponse.statusCode,
                                  [NSHTTPURLResponse localizedStringForStatusCode:self.m_httpResponse.statusCode]]];
  [[IQUSDK instance]
      addLog:[NSString stringWithFormat:@"[Network][Response] headers = %@", self.m_httpResponse.allHeaderFields]];
#endif
}

/**
  Implements the connection:didReceiveData method.
*/
- (void)connection:(NSURLConnection*)aConnection didReceiveData:(NSData*)aData {
  // ignore if it is not the current connection
  if (aConnection != self.m_connection) {
    return;
  }
  // Append the new data to the instance variable you declared
  [self.m_responseData appendData:aData];
}

/**
  Implements the connection:willCacheResponse method.
*/
- (NSCachedURLResponse*)connection:(NSURLConnection*)aConnection
                 willCacheResponse:(NSCachedURLResponse*)aCachedResponse {
  // Return nil to indicate not necessary to store a cached response for this
  // connection
  return nil;
}

/**
  Implements the connectionDidFinishLoading method.
*/
- (void)connectionDidFinishLoading:(NSURLConnection*)aConnection {
  // ignore if it is not the current connection
  if (aConnection != self.m_connection) {
    return;
  }
  // parse received data as JSON
  NSError* jsonError;
  NSMutableDictionary* result = [NSJSONSerialization JSONObjectWithData:self.m_responseData
                                                                options:NSJSONReadingMutableContainers
                                                                  error:&jsonError];
  if (result == nil) {
    result = [[NSMutableDictionary alloc] initWithCapacity:2];
    if (jsonError == nil) {
      [result setObject:@"error in json data received" forKey:ERROR];
    } else {
      [result setObject:jsonError.localizedDescription forKey:ERROR];
    }
  }
  // add status code from http response (if any)
  [self addStatusCode:result];
  // store
  self.m_result = result;
}

/**
  Implements the connection:didFailWithError method.
*/
- (void)connection:(NSURLConnection*)aConnection didFailWithError:(NSError*)anError {
  // ignore if it is not the current connection
  if (aConnection != self.m_connection) {
    return;
  }
  NSMutableDictionary* result = [[NSMutableDictionary alloc] initWithCapacity:2];
  if (anError == nil) {
    [result setObject:@"unknown error occured (error == nil)" forKey:ERROR];
  } else {
    [result setObject:anError.localizedDescription forKey:ERROR];
  }
  // add status code from http response (if any)
  [self addStatusCode:result];
  // store result
  self.m_result = result;
}

@end
