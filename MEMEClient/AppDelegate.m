#import "AppDelegate.h"
#import <Foundation/Foundation.h>
#import "MEMELib.h"


#pragma mark - interface
@interface AppDelegate () <MEMELibDelegate>


#pragma mark - properties

@property (weak) IBOutlet NSWindow *window;
@property (nonatomic) NSMutableArray *buttons;
@property (nonatomic) NSTextView *textView;
@property (nonatomic) NSPopUpButton *popupButton;

@property (nonatomic) NSMutableArray *peripherals;

@end


#pragma mark - AppDelegate
@implementation AppDelegate


#pragma mark - destruction
- (void)dealloc
{
}


#pragma mark - life cycle
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    self.peripherals = @[].mutableCopy;

    // button
    NSArray *APIs = @[
        @"setAppClientId",
        @"isConnected",
        @"isDataReceiving",
        @"isCalibrated",
        @"startScanningPeripherals",
        @"stopScanningPeripherals",
        @"connectPeripheral",
        @"disconnectPeripheral",
        @"getConnectedByOthers",
        @"startDataReport",
        @"stopDataReport",
        @"getSDKVersion",
        @"getFWVersion",
        @"getHWVersion",
        @"getConnectedDeviceType",
        @"getConnectedDeviceSubType",
    ];
    self.buttons = @[].mutableCopy;
    for (int i = 0; i < APIs.count; i++) {
        NSButton *button = [[NSButton alloc] initWithFrame:CGRectMake(0, 20*i, 200, 20)];
        button.title = APIs[i];
        [button setTarget:self];
        [button setAction:@selector(clickedWithButton:)];
        [self.window.contentView addSubview:button];
    }

    // textview
    self.textView = [[NSTextView alloc] initWithFrame:CGRectMake(200, 0, 320, 320)];
    [self.window.contentView addSubview:self.textView];

    // popup button
    self.popupButton = [[NSPopUpButton alloc] initWithFrame:CGRectMake(200, 320, 200, 20)];
    [self.window.contentView addSubview:self.popupButton];
    [self.popupButton selectItemAtIndex:0];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
}


#pragma mark - event listener
- (void)clickedWithButton:(NSButton *)button
{
    NSString *title = [button title];
    if ([title isEqualToString:@"setAppClientId"]) {
        [MEMELib setAppClientId:@"775649328784742"
                   clientSecret:@"7pir5husrqk4o8zh2z6tdszncpzk7g2w"];
        [[MEMELib sharedInstance] setDelegate:self];

        [self.textView setString:@"[MEMELib setAppClientId:@\"775649328784742\" clientSecret:@\"7pir5husrqk4o8zh2z6tdszncpzk7g2w\"]"];
    }
    else if ([title isEqualToString:@"isConnected"]) {
        [self.textView setString:[NSString stringWithFormat:@"[[MEMELib sharedInstance] isConnected] = %d", [[MEMELib sharedInstance] isConnected]]];
    }
    else if ([title isEqualToString:@"isDataReceiving"]) {
        [self.textView setString:[NSString stringWithFormat:@"[[MEMELib sharedInstance] isDataReceiving] = %d", [[MEMELib sharedInstance] isDataReceiving]]];
    }
    else if ([title isEqualToString:@"isCalibrated"]) {
        [self.textView setString:[NSString stringWithFormat:@"[[MEMELib sharedInstance] isCalibrated] = %d", [[MEMELib sharedInstance] isCalibrated]]];
    }
    else if ([title isEqualToString:@"startScanningPeripherals"]) {
        [self.textView setString:[NSString stringWithFormat:@"[[MEMELib sharedInstance] startScanningPeripherals] = %d", [[MEMELib sharedInstance] startScanningPeripherals]]];
    }
    else if ([title isEqualToString:@"stopScanningPeripherals"]) {
        [self.textView setString:[NSString stringWithFormat:@"[[MEMELib sharedInstance] stopScanningPeripherals] = %d", [[MEMELib sharedInstance] stopScanningPeripherals]]];
    }
    else if ([title isEqualToString:@"connectPeripheral"]) {
        NSString *UUIDString = [self.popupButton itemTitleAtIndex:[self.popupButton indexOfSelectedItem]];
        if (UUIDString == nil) {
            [self.textView setString:@"[[MEMELib sharedInstance] connectPeripheral:] failed because of no selected peripherals"];
            return;
        }

        CBPeripheral *peripheral = [CBPeripheral new];
        peripheral.identifier = [[NSUUID alloc] initWithUUIDString:UUIDString];
        [self.textView setString:[NSString stringWithFormat:@"[[MEMELib sharedInstance] connectPeripheral:peripheral] = %d", [[MEMELib sharedInstance] connectPeripheral:peripheral]]];
    }
    else if ([title isEqualToString:@"disconnectPeripheral"]) {
        [self.textView setString:[NSString stringWithFormat:@"[[MEMELib sharedInstance] disconnectPeripheral] = %d", [[MEMELib sharedInstance] disconnectPeripheral]]];
    }
    else if ([title isEqualToString:@"getConnectedByOthers"]) {
        NSArray *ps = [[MEMELib sharedInstance] getConnectedByOthers];
        NSString *text = [NSString stringWithFormat:@"[[MEMELib sharedInstance] getConnectedByOthers]\n"];
        for (int i = 0; i < [ps count]; i++) {
            text = [NSString stringWithFormat:@"%@UUID %d: %@\n", text, i, [[ps[i] identifier] UUIDString]];
        }
        [self.textView setString:text];
    }
    else if ([title isEqualToString:@"startDataReport"]) {
        [self.textView setString:[NSString stringWithFormat:@"[[MEMELib sharedInstance] startDataReport] = %d", [[MEMELib sharedInstance] startDataReport]]];
    }
    else if ([title isEqualToString:@"stopDataReport"]) {
        [self.textView setString:[NSString stringWithFormat:@"[[MEMELib sharedInstance] stopDataReport] = %d", [[MEMELib sharedInstance] stopDataReport]]];
    }
    else if ([title isEqualToString:@"getSDKVersion"]) {
        [self.textView setString:[NSString stringWithFormat:@"[[MEMELib sharedInstance] getSDKVersion] = %@", [[MEMELib sharedInstance] getSDKVersion]]];
    }
    else if ([title isEqualToString:@"getFWVersion"]) {
        [self.textView setString:[NSString stringWithFormat:@"[[MEMELib sharedInstance] getFWVersion] = %@", [[MEMELib sharedInstance] getFWVersion]]];
    }
    else if ([title isEqualToString:@"getHWVersion"]) {
        [self.textView setString:[NSString stringWithFormat:@"[[MEMELib sharedInstance] getHWVersion] = %d", [[MEMELib sharedInstance] getHWVersion]]];
    }
    else if ([title isEqualToString:@"getConnectedDeviceType"]) {
        [self.textView setString:[NSString stringWithFormat:@"[[MEMELib sharedInstance] getConnectedDeviceType] = %d", [[MEMELib sharedInstance] getConnectedDeviceType]]];
    }
    else if ([title isEqualToString:@"getConnectedDeviceSubType"]) {
        [self.textView setString:[NSString stringWithFormat:@"[[MEMELib sharedInstance] getConnectedDeviceSubType] = %d", [[MEMELib sharedInstance] getConnectedDeviceSubType]]];
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
    NSString *UUIDString = [peripheral.identifier UUIDString];
    NSLog(@"UUIDString: %@\naddress: %@", UUIDString, address);

    BOOL alreadyFound = FALSE;
    for (CBPeripheral *peripheral in self.peripherals) {
        if ([[peripheral.identifier UUIDString] isEqualToString:UUIDString]) { alreadyFound = TRUE; break; }
    }
    if (alreadyFound) { return; }
    [self.peripherals addObject:peripheral];

    [self.popupButton addItemWithTitle:UUIDString];
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
/*
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
*/


@end
