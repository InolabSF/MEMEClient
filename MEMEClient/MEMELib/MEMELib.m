#import "MEMELib.h"
#import "RoutingHTTPServer.h"


@interface MEMELib()

    @property (nonatomic) RoutingHTTPServer *server;

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

- (id)init
{
    self = [super init];
    if (self) {
        // server
        self.server = [RoutingHTTPServer new];
        [self.server setPort:3000];
        [self.server setDefaultHeader:@"content-type" value:@"application/json"];

        __block __unsafe_unretained typeof(self) bself = self;
        [self.server get:@"/memeAppAuthorized:" withBlock:^ (RouteRequest *request, RouteResponse *response) {
            [bself.delegate memeAppAuthorized:[request.params[@"arg0"] intValue]];
        }];
        [self.server get:@"/memeFirmwareAuthorized:" withBlock:^ (RouteRequest *request, RouteResponse *response) {
            [bself.delegate memeFirmwareAuthorized:[request.params[@"arg0"] intValue]];
        }];
        [self.server get:@"/memePeripheralFound:withDeviceAddress:" withBlock:^ (RouteRequest *request, RouteResponse *response) {
            CBPeripheral *arg0 = [CBPeripheral new];
            arg0.identifier = [[NSUUID alloc] initWithUUIDString:request.params[@"arg0"]];
            [bself.delegate memePeripheralFound:arg0 withDeviceAddress:request.params[@"arg1"]];
        }];
        [self.server get:@"/memePeripheralConnected:" withBlock:^ (RouteRequest *request, RouteResponse *response) {
            CBPeripheral *arg0 = [CBPeripheral new];
            arg0.identifier = [[NSUUID alloc] initWithUUIDString:request.params[@"arg0"]];
            [bself.delegate memePeripheralConnected:arg0];
        }];
        [self.server get:@"/memePeripheralDisconnected:" withBlock:^ (RouteRequest *request, RouteResponse *response) {
            CBPeripheral *arg0 = [CBPeripheral new];
            arg0.identifier = [[NSUUID alloc] initWithUUIDString:request.params[@"arg0"]];
            [bself.delegate memePeripheralDisconnected:arg0];
        }];
        [self.server get:@"/memeRealTimeModeDataReceived:" withBlock:^ (RouteRequest *request, RouteResponse *response) {
            MEMERealTimeData *data = [MEMERealTimeData new];
            data.fitError = [request.params[@"arg0"] intValue];
            data.isWalking = [request.params[@"arg1"] intValue];
            data.powerLeft = [request.params[@"arg2"] intValue];
            data.eyeMoveUp = [request.params[@"arg3"] intValue];
            data.eyeMoveDown = [request.params[@"arg4"] intValue];
            data.eyeMoveLeft = [request.params[@"arg5"] intValue];
            data.eyeMoveRight = [request.params[@"arg6"] intValue];
            data.blinkSpeed = [request.params[@"arg7"] intValue];
            data.blinkStrength = [request.params[@"arg8"] intValue];
            data.roll = [request.params[@"arg9"] floatValue];
            data.pitch = [request.params[@"arg10"] floatValue];
            data.yaw = [request.params[@"arg11"] floatValue];
            data.accX = [request.params[@"arg12"] intValue];
            data.accY = [request.params[@"arg13"] intValue];
            data.accZ = [request.params[@"arg14"] intValue];

            [bself.delegate memeRealTimeModeDataReceived:data];
        }];
        [self.server get:@"/memeCommandResponse:" withBlock:^ (RouteRequest *request, RouteResponse *response) {
            MEMEResponse r;
            r.eventCode = [request.params[@"arg0"] intValue];
            r.commandResult = [request.params[@"arg1"] boolValue];
            [bself.delegate memeCommandResponse:r];
        }];

        NSError *error;
        if (![self.server start:&error]) {
        }
    }
    return self;
}

- (void)setDelegate:(id<MEMELibDelegate>)del
{
    _delegate = del;
}

#pragma mark AUTH

+ (void) setAppClientId: (NSString *) clientId clientSecret: (NSString *) clientSecret
{
    [MEMELib requestAPI:@"setAppClientId:clientSecret:"
              arguments:@[clientId, clientSecret]];
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
    return [[MEMELib requestAPI:@"connectPeripheral:" arguments:@[[[peripheral identifier] UUIDString]]] intValue];
}

- (MEMEStatus) disconnectPeripheral
{
    return [[MEMELib requestAPI:@"disconnectPeripheral" arguments:nil] intValue];
}

- (NSArray *) getConnectedByOthers
{
    NSArray *peripheralStrings = [[MEMELib requestAPI:@"getConnectedByOthers" arguments:nil] componentsSeparatedByString:@","];

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
    return (UInt8)[[MEMELib requestAPI:@"getHWVersion" arguments:nil] intValue];
}

- (int) getConnectedDeviceType
{
    return [[MEMELib requestAPI:@"getConnectedDeviceType" arguments:nil] intValue];
}

- (int) getConnectedDeviceSubType
{
    return [[MEMELib requestAPI:@"getConnectedDeviceSubType" arguments:nil] intValue];
}


#pragma mark - private api
+ (id)requestAPI:(NSString *)API
       arguments:(NSArray *)arguments
{
    NSMutableArray *queryItems = @[].mutableCopy;
    for (int i = 0; i < [arguments count]; i++) {
        [queryItems addObject:[NSURLQueryItem queryItemWithName:[NSString stringWithFormat:@"arg%d", i] value:arguments[i]]];
    }
    NSURLComponents *URLComponents = [NSURLComponents componentsWithString:[NSString stringWithFormat:@"%@%@", kMEMEServerURL, API]];
    URLComponents.queryItems = queryItems;

    NSMutableURLRequest *request = [NSMutableURLRequest new];
    [request setURL:URLComponents.URL];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];

    NSError *error = nil;
    NSData *result = [NSURLConnection sendSynchronousRequest:request
                                           returningResponse:nil
                                                       error:&error];
    if (error) {
        NSLog(@"!!!!!!!!!!!!!!!\nAPI:%@\narguments:%@\nerror:%@", API, arguments, error);
    }

    NSString *str = [[NSString alloc] initWithData:result encoding:NSUTF8StringEncoding];
    return str;
}


@end
