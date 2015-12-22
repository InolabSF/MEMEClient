# JINS MEME OSX API Client


## Installation

[1] Download this project

```
$ git clone https://github.com/InolabSF/MEMEClient.git
$ cd MEMEClient
```

[2] Install [CocoaPods](https://guides.cocoapods.org/using/getting-started.html)

[3] Input the command

```
$ pod update
```

[4] Open workspace

```
$ open MEMEClient.xcworkspace
```

[5] Run codes


## Server

IP Address: your iPhone's IP Address

Port: 3000

Set your iPhone's IP address. /MEMEClient/MEMELib/MEMELib.h
```
// example
#define kMEMEServerURL @"http://10.2.2.28:3000/"
```

## Client

* Local files
```
/MEMEClient/MEMELib/MEMELib.h
/MEMEClient/MEMELib/MEMELib.m
/MEMEClient/MEMELib/CBPeripheral.h
/MEMEClient/MEMELib/CBPeripheral.m
/MEMEClient/MEMELib/MEMERealTimeData.h
/MEMEClient/MEMELib/MEMERealTimeData.m
```

* Third Party Library
```
SRWebSocket https://github.com/square/SocketRocket.git
```

* Code
```
    [MEMELib setAppClientId:YOUR_MEME_APP_CLIENT_ID
               clientSecret:YOUR_MEME_CLIENT_SECRET];
    [[MEMELib sharedInstance] setDelegate:self];
```
All MEMELib APIs and delegates are covered.

* It's implemented by web socket to receive the delegate events, so you should write web socket connection code before using...
```
    [[MEMELib sharedInstance] connectWebSocket];
    [[MEMELib sharedInstance] disconnectWebSocket];
```
