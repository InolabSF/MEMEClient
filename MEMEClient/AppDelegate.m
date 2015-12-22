#import "AppDelegate.h"
#import <Foundation/Foundation.h>
#import "MEMELib.h"


@interface AppDelegate () <MEMELibDelegate>

@property (weak) IBOutlet NSWindow *window;
@property (nonatomic) NSButton *APITestButton;
@property (nonatomic) NSButton *connectWebSocketButton;
@property (nonatomic) NSButton *disconnectWebSocketButton;

@end


@implementation AppDelegate


#pragma mark - life cycle
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    self.APITestButton = [[NSButton alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
    self.APITestButton.title = @"test api";
    self.connectWebSocketButton = [[NSButton alloc] initWithFrame:CGRectMake(100, 0, 100, 100)];
    self.connectWebSocketButton.title = @"connect websocket";
    self.disconnectWebSocketButton = [[NSButton alloc] initWithFrame:CGRectMake(200, 0, 100, 100)];
    self.disconnectWebSocketButton.title = @"disconnect websocket";
    NSArray *buttons = @[self.APITestButton, self.connectWebSocketButton, self.disconnectWebSocketButton];
    for (NSButton *button in buttons) {
        [button setTarget:self];
        [button setAction:@selector(clickedWithButton:)];
        [self.window.contentView addSubview:button];
    }

    [MEMELib setAppClientId:@"YOUR_MEME_APP_CLIENT_ID"
               clientSecret:@"YOUR_MEME_CLIENT_SECRET"];
    [[MEMELib sharedInstance] setDelegate:self];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
}


#pragma mark - event listener
- (void)clickedWithButton:(NSButton *)button
{
    if (button == self.APITestButton) {
        [self testAPIs];
    }
    else if (button == self.connectWebSocketButton) {
        [[MEMELib sharedInstance] connectWebSocket];
    }
    else if (button == self.disconnectWebSocketButton) {
        [[MEMELib sharedInstance] disconnectWebSocket];
    }
}


#pragma mark - MEMELibDelegate
- (void) memeAppAuthorized: (MEMEStatus) status
{
    NSLog(@"status: %d", status);
}

- (void) memeFirmwareAuthorized: (MEMEStatus) status
{
    NSLog(@"status: %d", status);
}

- (void) memePeripheralFound: (CBPeripheral *) peripheral withDeviceAddress: (NSString *) address
{
    NSLog(@"UUIDString: %@\naddress: %@", [peripheral.identifier UUIDString], address);
}

- (void) memePeripheralConnected: (CBPeripheral *)peripheral
{
    NSLog(@"UUIDString: %@", [peripheral.identifier UUIDString]);
}

- (void) memePeripheralDisconnected: (CBPeripheral *)peripheral
{
    NSLog(@"UUIDString: %@", [peripheral.identifier UUIDString]);
}

- (void) memeRealTimeModeDataReceived: (MEMERealTimeData *) data
{
    NSLog(@"data:");
    NSLog(@"fitError        %d", data.fitError);
    NSLog(@"isWalking       %d", data.isWalking);
    NSLog(@"powerLeft       %d", data.powerLeft);
    NSLog(@"eyeMoveUp       %d", data.eyeMoveUp);
    NSLog(@"eyeMoveDown     %d", data.eyeMoveDown);
    NSLog(@"eyeMoveLeft     %d", data.eyeMoveLeft);
    NSLog(@"eyeMoveRight    %d", data.eyeMoveRight);
    NSLog(@"blinkSpeed      %d", data.blinkSpeed);
    NSLog(@"blinkStrength   %d", data.blinkStrength);
    NSLog(@"roll            %f", data.roll);
    NSLog(@"pitch           %f", data.pitch);
    NSLog(@"yaw             %f", data.yaw);
    NSLog(@"accX            %d", data.accX);
    NSLog(@"accY            %d", data.accY);
    NSLog(@"accZ            %d", data.accZ);
}

- (void) memeCommandResponse: (MEMEResponse) response
{
    NSLog(@"response:");
    NSLog(@"eventCode: %d", response.eventCode);
    NSLog(@"commandResult: %d", response.commandResult);
}


#pragma mark - private api
- (void)testAPIs
{
    NSLog(@"///////////////////////////////////////////////////////");
    NSLog(@"Calling MEMELib APIs");
    // APIs

    CBPeripheral *peripheral = [CBPeripheral new];
    //peripheral.identifier = [[NSUUID alloc] initWithUUIDString:@"PERIPHERAL_UUID_STRING"];
    peripheral.identifier = [NSUUID new];

    NSLog(@"[[MEMELib sharedInstance] isConnected]        %d", [[MEMELib sharedInstance] isConnected]);
    NSLog(@"[[MEMELib sharedInstance] isDataReceiving]    %d", [[MEMELib sharedInstance] isDataReceiving]);
    NSLog(@"[[MEMELib sharedInstance] isCalibrated]       %d", [[MEMELib sharedInstance] isCalibrated]);

    NSLog(@"[[MEMELib sharedInstance] startScanningPeripherals]       %d", [[MEMELib sharedInstance] startScanningPeripherals]);
    NSLog(@"[[MEMELib sharedInstance] stopScanningPeripherals]        %d", [[MEMELib sharedInstance] stopScanningPeripherals]);
    NSLog(@"[[MEMELib sharedInstance] connectPeripheral:peripheral]   %d", [[MEMELib sharedInstance] connectPeripheral:peripheral]);
    NSLog(@"[[MEMELib sharedInstance] disconnectPeripheral]           %d", [[MEMELib sharedInstance] disconnectPeripheral]);

    NSArray *peripherals = [[MEMELib sharedInstance] getConnectedByOthers];
    NSLog(@"[[MEMELib sharedInstance] getConnectedByOthers]");
    for (int i = 0; i < [peripherals count]; i++) {
        NSLog(@"UUID %d: %@", i, [[peripherals[i] identifier] UUIDString]);
    }

    NSLog(@"[[MEMELib sharedInstance] startDataReport]       %d", [[MEMELib sharedInstance] startDataReport]);
    NSLog(@"[[MEMELib sharedInstance] stopDataReport]        %d", [[MEMELib sharedInstance] stopDataReport]);

    NSLog(@"[[MEMELib sharedInstance] getSDKVersion]   %@", [[MEMELib sharedInstance] getSDKVersion]);
    NSLog(@"[[MEMELib sharedInstance] getFWVersion]    %@", [[MEMELib sharedInstance] getFWVersion]);
    NSLog(@"[[MEMELib sharedInstance] getHWVersion]    %d", [[MEMELib sharedInstance] getHWVersion]);
    NSLog(@"[[MEMELib sharedInstance] getConnectedDeviceType]       %d", [[MEMELib sharedInstance] getConnectedDeviceType]);
    NSLog(@"[[MEMELib sharedInstance] getConnectedDeviceSubType]    %d", [[MEMELib sharedInstance] getConnectedDeviceSubType]);
}

@end
