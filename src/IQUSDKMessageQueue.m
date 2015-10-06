#import "IQUSDKConfig.h"
#import "IQUSDK.h"
#import "IQUSDKMessageQueue.h"
#import "IQUSDKMessage.h"

#pragma mark - PRIVATE DEFINITIONS

@interface IQUSDKMessageQueue ()

#pragma mark - Private properties

/**
  First message in the chain.
*/
@property IQUSDKMessage* m_first;

/**
  Last message in the chain.
*/
@property IQUSDKMessage* m_last;

/**
  Cached JSON string.
*/
@property NSString* m_cachedJSONString;

/**
  When true recreate JSON string.
*/
@property bool m_dirtyJSON;

/**
  When true save messages to persistent storage.
*/
@property bool m_dirtyStored;

#pragma mark - Private methods

/**
  Reset queue to empty queue (but don't process and destroy the message instances).
*/
- (void)reset;

/**
  Deletes the storage file (if any).
*/
- (void)deleteFile;

/**
  Builds the JSON string.
 
  @return JSON formatted string.
*/
- (NSString*)buildJSONString;

@end

#pragma mark - IMPLEMENTATION

@implementation IQUSDKMessageQueue

#pragma mark - Private consts

/**
  Name of file where messages are stored.
*/
static NSString* const FileName = @"IQUSDK_messages.bin";

/**
  Version of file, increase if data structure changes.
*/
static const int FileVersion = 1;

/**
  Key used to store file version with.
*/
static NSString* const VersionKey = @"Version";

/**
  Key used to store messages with.
*/
static NSString* const ListKey = @"Messages";

#pragma mark - Private static variables

/**
  FileName including full path.
*/
static NSString* m_fileName = nil;

#pragma mark - Initializers

/**
  Initializes the instance.
*/
- (id)init {
  self = [super init];
  if (self != nil) {
    [self reset];
    // filename has not been determined yet?
    if (m_fileName == nil) {
      // yes, create it now
      NSArray* paths = NSSearchPathForDirectoriesInDomains(
          NSDocumentDirectory, NSUserDomainMask, YES);
      NSString* documentsDirectory = [paths objectAtIndex:0];
      m_fileName = [documentsDirectory stringByAppendingPathComponent:FileName];
    }
  }
  return self;
}

#pragma mark - Public methods

/**
  Implements isEmpty method.
*/
- (bool)isEmpty {
  return self.m_first == nil;
}

/**
  Implements add method.
*/
- (void)add:(IQUSDKMessage*)aMessage {
  if (self.m_last != nil) {
    self.m_last.next = aMessage;
  }
  self.m_last = aMessage;
  if (self.m_first == nil) {
    self.m_first = aMessage;
  }
  // message now belongs to this queue
  aMessage.queue = self;
  self.m_dirtyJSON = true;
  self.m_dirtyStored = true;
}

/**
  Implements prepend method.
*/
- (void)prepend:(IQUSDKMessageQueue*)aQueue changeQueue:(bool)aChangeQueue {
  if (![aQueue isEmpty]) {
    // if this queue is empty, copy cached JSON string and dirty state;
    // else reset it.
    if ([self isEmpty]) {
      self.m_cachedJSONString = aQueue.m_cachedJSONString;
      self.m_dirtyJSON = aQueue.m_dirtyJSON;
      self.m_dirtyStored = aQueue.m_dirtyStored;
    } else {
      self.m_cachedJSONString = nil;
      self.m_dirtyJSON = true;
      self.m_dirtyStored = true;
    }
    // get first and last
    IQUSDKMessage* first = aQueue.m_first;
    IQUSDKMessage* last = aQueue.m_last;
    // this queue is empty?
    if (self.m_last == nil) {
      // yes, just copy last
      self.m_last = last;
    } else {
      // add the first message in the chain to the chain in aQueue
      last.next = self.m_first;
    }
    // chain starts now with the first message in the chain of aQueue
    self.m_first = first;
    // update queue property?
    if (aChangeQueue) {
      for (IQUSDKMessage* message = first; message != nil;
           message = message.next) {
        message.queue = self;
      }
    }
    // aQueue is now empty
    [aQueue reset];
  }
}

/**
  Implements destroy method.
*/
- (void)destroy {
  [self clear:false];
  [self reset];
}

/**
  Implements getCount method.
*/
- (int)getCount {
  int result = 0;
  for (IQUSDKMessage* message = self.m_first; message != nil;
       message = message.next) {
    result++;
  }
  return result;
}

/**
  Implements clear method.
*/
- (void)clear:(bool)aClearStorage {
  IQUSDKMessage* message = self.m_first;
  while (message != nil) {
    IQUSDKMessage* next = message.next;
    [message destroy];
    message = next;
  }
  if (aClearStorage) {
    [self deleteFile];
  }
  [self reset];
}

/**
  Implements save method.
*/
- (void)save {
  if (self.m_dirtyStored && ![self isEmpty]) {
    // store all messages in an array
    int count = [self getCount];
    NSMutableArray* list = [[NSMutableArray alloc] initWithCapacity:count];
    for (IQUSDKMessage* message = self.m_first; message != nil;
         message = message.next) {
      [list addObject:message];
    }
    NSMutableData* data = [[NSMutableData alloc] init];
    NSKeyedArchiver* archiver =
        [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
    if (archiver) {
      [archiver encodeInt:FileVersion forKey:VersionKey];
      [archiver encodeObject:list forKey:ListKey];
      [archiver finishEncoding];
      [data writeToFile:m_fileName atomically:YES];
#ifdef IQUSDK_DEBUG
      [[IQUSDK instance]
          addLog:[NSString
                     stringWithFormat:@"[Queue] saved %d messages.", count]];
#endif
    }
    // messages have been saved
    self.m_dirtyStored = false;
  }
}

/**
  Implements load method.
*/
- (void)load {
  [self clear:false];
  if ([[NSFileManager defaultManager] fileExistsAtPath:m_fileName]) {
    NSData* data = [NSData dataWithContentsOfFile:m_fileName];
    if (data != nil) {
      NSKeyedUnarchiver* unarchiver =
          [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
      if (unarchiver != nil) {
        int version = [unarchiver decodeIntForKey:VersionKey];
        if (version == FileVersion) {
          NSArray* list = (NSArray*)[unarchiver decodeObjectForKey:ListKey];
          // convert list back to linked list and set queue property
          if (list != nil) {
            for (int index = 0; index < list.count; index++) {
              IQUSDKMessage* message = [list objectAtIndex:index];
              message.queue = self;
              [self add:message];
            }
#ifdef IQUSDK_DEBUG
            [[IQUSDK instance]
                addLog:[NSString
                           stringWithFormat:@"[Queue] loaded %d messages.",
                                            list.count]];
#endif
          }
        } else {
          // unsupported version, so delete file
          [self deleteFile];
        }
        [unarchiver finishDecoding];
      }
    }
  }
  // no need to save the just loaded messages
  self.m_dirtyStored = false;
}

/**
  Implements toJSONString method.
*/
- (NSString*)toJSONString {
  if ((self.m_cachedJSONString == nil) || self.m_dirtyJSON) {
    self.m_cachedJSONString = [self buildJSONString];
    self.m_dirtyJSON = false;
  }
  return self.m_cachedJSONString;
}

/**
  Implements updateID method.
*/
- (void)updateID:(IQUSDKIDType)aType newValue:(NSString*)aNewValue {
  for (IQUSDKMessage* message = self.m_first; message != nil;
       message = message.next) {
    [message updateID:aType newValue:aNewValue];
  }
}

/**
  Implements hasEventType method.
*/
- (bool)hasEventType:(NSString*)aType {
  for (IQUSDKMessage* message = self.m_first; message != nil;
       message = message.next) {
    if ([aType isEqualToString:message.eventType])
      return true;
  }
  return false;
}

/**
  Implements the onMessageChanged method.
*/
- (void)onMessageChanged:(IQUSDKMessage*)aMessage {
  self.m_dirtyJSON = true;
  self.m_dirtyStored = true;
}

#pragma mark - Private methods

/**
  Implements buildJSONString method.
*/
- (NSString*)buildJSONString {
  NSMutableString* result = [[NSMutableString alloc] init];
  [result appendString:@"["];
  bool notEmpty = false;
  for (IQUSDKMessage* message = self.m_first; message != nil;
       message = message.next) {
    if (notEmpty) {
      [result appendString:@","];
    }
    [result appendString:[message toJSONString]];
    notEmpty = true;
  }
  [result appendString:@"]"];
  return result;
}

/**
  Implements reset method.
*/
- (void)reset {
  self.m_first = nil;
  self.m_last = nil;
  self.m_dirtyJSON = false;
  self.m_dirtyStored = false;
  self.m_cachedJSONString = nil;
}

/**
  Implements the deleteFile method.
*/
- (void)deleteFile {
  NSFileManager* manager = [NSFileManager defaultManager];
  if ([manager fileExistsAtPath:m_fileName]) {
    NSError* error;
    [manager removeItemAtPath:m_fileName error:&error];
#ifdef IQUSDK_DEBUG
    [[IQUSDK instance] addLog:@"[Queue] deleting persistent storage file."];
#endif
  }
}

@end
