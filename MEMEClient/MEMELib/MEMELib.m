#import "MEMELib.h"
#import "RoutingHTTPServer.h"


NSString * const MEMEErrDomain        = @"com.jins.mem.error";
NSString * const MEMEErrStatusCodeKey = @"com.jins.mem.error.statusCodeKey";


@interface MEMELib()

@property (nonatomic) RoutingHTTPServer *server;
@property (nonatomic, assign) BOOL                   clientInitialized;
@property (nonatomic, strong) NSString              *clientID;
@property (nonatomic, strong) NSString              *clientSecret;
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
        _clientInitialized = NO;

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
    [[MEMELib sharedInstance] setClientID:clientId];
    [[MEMELib sharedInstance] setClientSecret:clientSecret];
}


#pragma mark property

- (BOOL) isConnected
{
    return [[self callValueAPI:@"isConnected"] boolValue];
}

- (BOOL) isDataReceiving
{
    return [[self callValueAPI:@"isDataReceiving"] boolValue];
}

- (MEMECalibStatus) isCalibrated
{
    return [[self callValueAPI:@"isCalibrated"] boolValue];
}


#pragma mark CONNECTION

- (MEMEStatus) startScanningPeripherals
{
    return [self callStatusAPI:@"startScanningPeripherals"];
}

- (MEMEStatus) stopScanningPeripherals
{
    return [self callStatusAPI:@"stopScanningPeripherals"];
}

- (MEMEStatus) connectPeripheral:(CBPeripheral *)peripheral
{
    return [self callStatusAPI:@"connectPeripheral:" withArguments:@[[[peripheral identifier] UUIDString]]];
}

- (MEMEStatus) disconnectPeripheral
{
    return [self callStatusAPI:@"disconnectPeripheral"];
}

- (NSArray *) getConnectedByOthers
{
    NSArray        *peripheralStrings = [self callValueAPI:@"getConnectedByOthers"];

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
    return [self callStatusAPI:@"startDataReport"];
}

- (MEMEStatus) stopDataReport
{
    return [self callStatusAPI:@"stopDataReport"];
}


#pragma mark DEVICE INFO

- (NSString *) getSDKVersion
{
    return [self callValueAPI:@"getSDKVersion"];
}

- (NSString *) getFWVersion
{
    return [self callValueAPI:@"getFWVersion"];
}

- (UInt8) getHWVersion
{
    return [[self callValueAPI:@"getHWVersion"] unsignedCharValue];
}

- (int) getConnectedDeviceType
{
    return [[self callValueAPI:@"getConnectedDeviceType"] intValue];
}

- (int) getConnectedDeviceSubType
{
    return [[self callValueAPI:@"getConnectedDeviceSubType"] intValue];
}


#pragma mark - private api
- (MEMEStatus) callStatusAPI:(NSString *)api withArguments:(NSArray *)args
{
    NSError *error     = nil;
    id       apiResult = [self callAPI:api withArguments:args error:&error];

    if (error == nil) {
        return (MEMEStatus) [apiResult intValue];
    }
    else if ([error.domain isEqualToString:MEMEErrDomain]) {
        return (MEMEStatus) [error.userInfo[MEMEErrStatusCodeKey] intValue];
    }
    return MEME_ERROR;
}

- (MEMEStatus)callStatusAPI:(NSString *)api
{
    return [self callStatusAPI:api withArguments:nil];
}

- (id) callValueAPI:(NSString *)api withArguments:(NSArray *)args
{
    NSError *error     = nil;
    id       apiResult = [self callAPI:api withArguments:args error:&error];

    if (error != nil) {
        NSLog(@"Unexpected error: %@", error.userInfo[NSLocalizedDescriptionKey]);
        return @"-1";
    }
    return apiResult;
}

- (id) callValueAPI:(NSString *)api
{
    return [self callValueAPI:api withArguments:nil];
}

- (id)    callAPI:(NSString *)api
    withArguments:(NSArray *)args
            error:(NSError * __autoreleasing *)error
{
    if (!self.clientInitialized) {
        NSAssert((self.clientID != nil) && (self.clientSecret != nil), @"Must set client id and secret first");
        self.clientInitialized = YES;

        id result = [self callValueAPI:@"setAppClientId:clientSecret:"
                         withArguments:@[ self.clientID, self.clientSecret ]];

        if ([result isEqualToString:@"-1"]) {
            self.clientInitialized = NO;
            return nil;
        }
    }

    NSMutableArray *queryItems = @[].mutableCopy;
    NSURLComponents *URLComponents = [NSURLComponents componentsWithString:[NSString stringWithFormat:@"%@%@", kMEMEServerURL, api]];
    if (args) {
        for (int i = 0; i < [args count]; i++) {
            [queryItems addObject:[NSURLQueryItem queryItemWithName:[NSString stringWithFormat:@"arg%d", i] value:args[i]]];
        }
        URLComponents.queryItems = queryItems;
    }

    NSMutableURLRequest *request = [NSMutableURLRequest new];
    [request setURL:URLComponents.URL];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];

    NSData *result = [NSURLConnection sendSynchronousRequest:request
                                           returningResponse:nil
                                                       error:error];
    if (*error) {
        NSLog(@"!!!!!!!!!!!!!!!\napi:%@\nargs:%@\nerror:%@", api, args, *error);
        return nil;
    }

    NSString *str = [[NSString alloc] initWithData:result encoding:NSUTF8StringEncoding];
    return str;
} /* callAPI */

/*
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
*/

@end
