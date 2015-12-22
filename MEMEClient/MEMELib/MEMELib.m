#import "MEMELib.h"
#import <SocketRocket/SRWebSocket.h>


@interface MEMELib() <SRWebSocketDelegate>

@property (nonatomic) SRWebSocket *webSocket;

@end


@implementation MEMELib


+ (MEMELib *)sharedInstance
{
    static MEMELib *lib  = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^ {
        lib = [MEMELib new];
    });
    return lib;
}


#pragma mark AUTH

+ (void) setAppClientId: (NSString *) clientId clientSecret: (NSString *) clientSecret
{
    [MEMELib requestAPI:@"set"
              arguments:@{@"appClientId":clientId, @"clientSecret":clientSecret,}];
}


#pragma mark property

- (BOOL) isConnected
{
    return [[MEMELib requestAPI:@"isConnected" arguments:nil] boolValue];
}

- (BOOL) isDataReceiving
{
    return [[MEMELib requestAPI:@"isDataReceiving" arguments:nil] boolValue];
}

- (MEMECalibStatus) isCalibrated
{
    return [[MEMELib requestAPI:@"isCalibrated" arguments:nil] intValue];
}


#pragma mark CONNECTION

- (MEMEStatus) startScanningPeripherals
{
    return [[MEMELib requestAPI:@"startScanningPeripherals" arguments:nil] intValue];
}

- (MEMEStatus) stopScanningPeripherals
{
    return [[MEMELib requestAPI:@"stopScanningPeripherals" arguments:nil] intValue];
}

- (MEMEStatus) connectPeripheral:(CBPeripheral *)peripheral
{
    return [[MEMELib requestAPI:@"connect" arguments:@{@"peripheral":[[peripheral identifier] UUIDString],}] intValue];
}

- (MEMEStatus) disconnectPeripheral
{
    return [[MEMELib requestAPI:@"disconnectPeripheral" arguments:nil] intValue];
}

- (NSArray *) getConnectedByOthers
{
    NSArray *peripheralStrings = [MEMELib requestAPI:@"getConnectedByOthers" arguments:nil];

    NSMutableArray *others = @[].mutableCopy;
    for (NSString *uuidString in peripheralStrings) {
        CBPeripheral *peripheral = [CBPeripheral new];
        peripheral.identifier = [[NSUUID alloc] initWithUUIDString:uuidString];
        [others addObject:peripheral];
    }
    return others;
}


#pragma mark DEVICE

- (MEMEStatus) startDataReport
{
    return [[MEMELib requestAPI:@"startDataReport" arguments:nil] intValue];
}

- (MEMEStatus) stopDataReport
{
    return [[MEMELib requestAPI:@"stopDataReport" arguments:nil] intValue];
}


#pragma mark DEVICE INFO

- (NSString *) getSDKVersion
{
    return [MEMELib requestAPI:@"getSDKVersion" arguments:nil];
}

- (NSString *) getFWVersion
{
    return [MEMELib requestAPI:@"getFWVersion" arguments:nil];
}

- (UInt8) getHWVersion
{
    return [[MEMELib requestAPI:@"getHWVersion" arguments:nil] unsignedIntegerValue];
}

- (int) getConnectedDeviceType
{
    return [[MEMELib requestAPI:@"getConnectedDeviceType" arguments:nil] intValue];
}

- (int) getConnectedDeviceSubType
{
    return [[MEMELib requestAPI:@"getConnectedDeviceSubType" arguments:nil] intValue];
}


#pragma mark - websocket
- (void)connectWebSocket
{
    [self disconnectWebSocket];
    self.webSocket = [[SRWebSocket alloc] initWithURLRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:kMEMEServerURL]]];
    self.webSocket.delegate = self;
    [self.webSocket open];
}

- (void)disconnectWebSocket
{
    if (self.webSocket) {
        self.webSocket.delegate = nil;
        [self.webSocket close];
    }
}


#pragma mark - SRWebSocketDelegate
- (void)webSocketDidOpen:(SRWebSocket *)webSocket;
{
    NSLog(@"Websocket Connected");
}

- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error;
{
    NSLog(@":( Websocket Failed With Error %@", error);
    self.webSocket = nil;
}

- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message;
{
    NSLog(@"Received \"%@\"", message);
    if ([message isKindOfClass:[NSString class]] == NO) { return; }

    // check if message means delegate
    if (self.delegate == nil) { return; }
    NSError *error = nil;
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:[message dataUsingEncoding:NSUTF8StringEncoding]
                                                         options:NSJSONReadingMutableContainers
                                                           error:&error];
    if (error) { return; }
    NSString *delegateMethodName = json[@"delegate"];
    if ([delegateMethodName isKindOfClass:[NSString class]] == NO) { return; }
    SEL selector = NSSelectorFromString(json[@"delegate"]);
    if ([self.delegate respondsToSelector:selector] == NO) { return; }
    NSArray *args = json[@"args"];
    if ([args isKindOfClass:[NSArray class]] == NO) { return; }

    // call delegate method
    if ([delegateMethodName isEqualToString:@"memeAppAuthorized:"] && [args count] > 0) {
        [self.delegate memeAppAuthorized:[args[0] intValue]];
    }
    else if ([delegateMethodName isEqualToString:@"memeFirmwareAuthorized:"] && [args count] > 0) {
        [self.delegate memeFirmwareAuthorized:[args[0] intValue]];
    }
    else if ([delegateMethodName isEqualToString:@"memePeripheralFound:withDeviceAddress:"] && [args count] > 1) {
        CBPeripheral *peripheral = [CBPeripheral new];
        peripheral.identifier = [[NSUUID alloc] initWithUUIDString:args[0]];
        [self.delegate memePeripheralFound:peripheral
                         withDeviceAddress:args[1]];
    }
    else if ([delegateMethodName isEqualToString:@"memePeripheralConnected:"] && [args count] > 0) {
        CBPeripheral *peripheral = [CBPeripheral new];
        peripheral.identifier = [[NSUUID alloc] initWithUUIDString:args[0]];
        [self.delegate memePeripheralConnected:peripheral];
    }
    else if ([delegateMethodName isEqualToString:@"memePeripheralDisconnected:"] && [args count] > 0) {
        CBPeripheral *peripheral = [CBPeripheral new];
        peripheral.identifier = [[NSUUID alloc] initWithUUIDString:args[0]];
        [self.delegate memePeripheralDisconnected:peripheral];
    }
    else if ([delegateMethodName isEqualToString:@"memeRealTimeModeDataReceived:"] && [args count] > 0) {
        NSDictionary *d = args[0];
        MEMERealTimeData *data = [MEMERealTimeData new];
        data.fitError = [d[@"fitError"] unsignedIntegerValue];
        data.isWalking = [d[@"isWalking"] unsignedIntegerValue];
        data.powerLeft = [d[@"powerLeft"] unsignedIntegerValue];
        data.eyeMoveUp = [d[@"eyeMoveUp"] unsignedIntegerValue];
        data.eyeMoveDown = [d[@"eyeMoveDown"] unsignedIntegerValue];
        data.eyeMoveLeft = [d[@"eyeMoveLeft"] unsignedIntegerValue];
        data.eyeMoveRight = [d[@"eyeMoveRight"] unsignedIntegerValue];
        data.blinkSpeed = [d[@"blinkSpeed"] unsignedIntegerValue];
        data.blinkStrength = [d[@"blinkStrength"] unsignedIntegerValue];
        data.roll = [d[@"roll"] floatValue];
        data.pitch = [d[@"pitch"] floatValue];
        data.yaw = [d[@"yaw"] floatValue];
        data.accX = [d[@"accX"] charValue];
        data.accY = [d[@"accY"] charValue];
        data.accZ = [d[@"accZ"] charValue];

        [self.delegate memeRealTimeModeDataReceived:data];
    }
    else if ([delegateMethodName isEqualToString:@"memeCommandResponse:"] && [args count] > 0) {
        NSDictionary *d = args[0];
        MEMEResponse response;
        response.eventCode = [d[@"eventCode"] intValue];
        response.commandResult = [d[@"commandResult"] boolValue];
        [self.delegate memeCommandResponse:response];
    }

}

- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean;
{
    NSLog(@"WebSocket closed");
    self.webSocket = nil;
}

- (void)webSocket:(SRWebSocket *)webSocket didReceivePong:(NSData *)pongPayload;
{
    NSLog(@"Websocket received pong");
}


#pragma mark - private api
+ (id)requestAPI:(NSString *)API
       arguments:(NSDictionary *)arguments
{
    NSMutableArray *queryItems = @[].mutableCopy;
    for (NSString *key in arguments) {
        [queryItems addObject:[NSURLQueryItem queryItemWithName:key value:arguments[key]]];
    }
    NSURLComponents *URLComponents = [NSURLComponents componentsWithString:[NSString stringWithFormat:@"%@%@", kMEMEServerURL, API]];
    URLComponents.queryItems = queryItems;

    NSMutableURLRequest *request = [NSMutableURLRequest new];
    [request setURL:URLComponents.URL];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];

    NSURLResponse *response;
    NSError *error = nil;
    NSData *result = [NSURLConnection sendSynchronousRequest:request
                                           returningResponse:&response
                                                       error:&error];
    if (error) { }

    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:result
                                                     options:NSJSONReadingMutableContainers
                                                           error:&error];
    if (error) { }

    if (json[@"return"] != nil) { return json[@"return"]; }
    return @"-1";
}


@end
