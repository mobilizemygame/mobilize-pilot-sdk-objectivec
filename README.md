# mobilize-pilot-sdk-objectivec
Mobilize Pilot ObjectiveC SDK

## Introduction

IQUSDK is a class that encapsulates the IQU SDK and offers various methods and properties to communicate with the IQU server.

## Installation

1. Clone or download the zip file (and unzip it to an appropriate location).
2. Within XCode, add a new group to the project and name it appropriately (for example IQU SDK)
3. Right click on the new group and select "Add files..."; add all the files from the *src/* folder 
4. To remove support for the advertising id edit the *IQUSDKConfig.h* and comment out the `IQUSDK_ADVERTISING_ID` define.

The *doc/html* folder contains html formatted help documents.

## Quick usage guide

1. Methods and properties can be accessed through the `[IQUSDK instance]` method.
2. Call `[[IQUSDK instance] start:secretKey:]` or `[[IQUSDK instance] start:secretKey:payable:]` or 
   `[[IQUSDK instance] start:secretKey:customID:]` or `[[IQUSDK instance] start:secretKey:payable:customID:]` to start the IQU SDK.
3. Add additional Ids via `[[IQUSDK instance] setFacebookID:]`, `[[IQUSDK instance] setGooglePlusID:]`, `[[IQUSDK instance] setTwitterID:]` or `[[IQUSDK instance] setCustomID:]`.
4. Start calling analytic tracking methods to send messages to the server.
5. Update the `[IQUSDK instance].payable` property to indicate the player is busy with a payable action.

## Network communication

The IQU SDK uses a separate thread to send messages to the server (to prevent blocking the main thread). This means that there might be a small delay
before messages are actually sent to the server. The maximum delay is determined by `[IQUSDK instance].updateInterval` property.

If the SDK fails to send a message to the IQU server, messages are queued and are sent when the server is available again. 
How often the SDK checks for the server is determines by the `[IQUSDK instance].checkServerInterval` property.

The queued messages are stored in persistent storage so they still can be resent after an application restart.

## Ids

The SDK supports various ids which are included with every tracking message sent to the server. See `IQUSDKIdType` for the types supported
by the SDK. Use `[[IQUSDK instance] getID:]` to get an id value.

Some ids are determined by the SDK itself, other ids must be set via one of
the following methods: `[[IQUSDK instance] setFacebookID:]`, `[[IQUSDK instance] setGooglePlusID:]`, `[[IQUSDK instance] setTwitterID:]` or `[[IQUSDK instance] setCustomID:]`

The SDK will try to obtain the advertising id and limited ad tracking. If limited ad tracking is enabled, the SDK will disable the tracking messages
and the `[IQUSDK instance].analyticsEnabled` property will return `false`. Calling any of the tracking methods will do nothing.

The SDK checks for the required classes and uses reflection to obtain the values so there are no errors when running the application on iOS versions 
that don't support the advertising ID.

To remove support for the advertising id edit the *IQUSDKConfig.h* and comment out the `IQUSDK_ADVERTISING_ID` define.

## Informational properties

The IQU SDK offers the following informational properties:

1. `[IQUSDK instance].analyticsEnabled` indicates if the IQU SDK analytics part is enabled. When disabled the tracking methods will do nothing.
   The analytics part is disabled when the user enabled limited ad tracking.
2. `[IQUSDK instance].serverAvailable` to get information if the messages were sent successfully or not.

## Testing

The IQU SDK contains the following properties to help with testing the SDK:

1. `[IQUSDK instance].logEnabled` property to turn logging on or off.
2. `[IQUSDK instance].log` property which will be filled with messages from various methods.
3. `[IQUSDK instance].testMode` property to test the SDK without any server interaction or to simulate an off-line situation 
   with the server not being available.
  
To turn on debug messages from various classes `IQUSDK_DEBUG` needs to be defined when building the application. See the *IQUSDKConfig.h* file to enable 
or disable this definition.

## Advance timing

The IQU SDK offers several properties to adjust the various timings:

 1. `[IQUSDK instance].updateInterval` property determines the time between the internal update calls.
 2. `[IQUSDK instance].sendTimeout` property determines the maximum time sending a message to the server may take.
 3. `[IQUSDK instance].checkServerInterval` property determines the time between checks for server availability. If sending of data fails, 
    the update thread  will wait the time, as set by this property, before trying to send the data again.
 
