#import "MEMELib.h"
#import "RoutingHTTPServer.h"

#if TARGET_OS_IPHONE

#if __IPHONE_OS_VERSION_MIN_REQUIRED >= 60000 // iOS 6.0 or later
#define NEEDS_DISPATCH_RETAIN_RELEASE 0
#else                                        // iOS 5.X or earlier
#define NEEDS_DISPATCH_RETAIN_RELEASE 1
#endif

#else

#if MAC_OS_X_VERSION_MIN_REQUIRED >= 1080    // Mac OS X 10.8 or later
#define NEEDS_DISPATCH_RETAIN_RELEASE 0
#else
#define NEEDS_DISPATCH_RETAIN_RELEASE 1 // Mac OS X 10.7 or earlier
#endif

#endif

NSString * const MEMEErrDomain        = @"com.jins.mem.error";
NSString * const MEMEErrStatusCodeKey = @"com.jins.mem.error.statusCodeKey";


@interface MEMELib() {
    dispatch_queue_t _synchronizationQueue;
    BOOL _authorizationPending;
    BOOL _authorized;
}

@property (nonatomic) RoutingHTTPServer *server;
@property (nonatomic, assign) BOOL                   clientInitialized;
@property (nonatomic, strong) NSString              *clientID;
@property (nonatomic, strong) NSString              *clientSecret;

@end


@implementation MEMELib

#pragma mark - Authorization

- (BOOL) isAuthorizationPending
{
    __block BOOL result = NO;
    dispatch_sync(_synchronizationQueue, ^{
        result = _authorizationPending;
    });
    return result;
}

- (void) setAuthorizedPending:(BOOL)authorizedPending
{
    dispatch_sync(_synchronizationQueue, ^{
        _authorizationPending = authorizedPending;
    });
}

- (BOOL) isAuthorized
{
    __block BOOL result = NO;
    dispatch_sync(_synchronizationQueue, ^{
        result = _authorized;
    });
    return result;
}

- (void) setAuthorized:(BOOL)authorized
{
    dispatch_sync(_synchronizationQueue, ^{
        _authorized = authorized;
    });
}

#if __MAC_OS_X_VERSION_MIN_REQUIRED >= 1011
- (NSData *)sendSynchronousRequest:(NSURLRequest *)request
                 returningResponse:(__autoreleasing NSURLResponse **)responsePtr
                             error:(__autoreleasing NSError **)errorPtr
{
    dispatch_semaphore_t    sem;
    __block NSData *        result;
    
    result = nil;
    
    sem = dispatch_semaphore_create(0);
    
    [[[NSURLSession sharedSession] dataTaskWithRequest:request
                                     completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                         if (errorPtr != NULL) {
                                             *errorPtr = error;
                                         }
                                         if (responsePtr != NULL) {
                                             *responsePtr = response;
                                         }  
                                         if (error == nil) {  
                                             result = data;  
                                         }  
                                         dispatch_semaphore_signal(sem);  
                                     }] resume];  
    
    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);  
    
    return result;  
}
#endif

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
        _authorizationPending = NO;
        _authorized = NO;
        _synchronizationQueue = dispatch_queue_create("MEMEBridge.peripheralManagingQueue", DISPATCH_QUEUE_SERIAL);

        // server
        self.server = [RoutingHTTPServer new];
        [self.server setPort:3000];
        [self.server setDefaultHeader:@"content-type" value:@"application/json"];

        [self.server get:@"/memeAppAuthorized"
               withBlock:^(RouteRequest *request, RouteResponse *response __unused) {
                   id<MEMELibDelegate> delegate = self.delegate;
                   if ([delegate respondsToSelector:@selector(memeAppAuthorized:)]) {
                       [delegate memeAppAuthorized:[request.params[@"arg0"] intValue]];
                   }
               }];
        [self.server get:@"/memeFirmwareAuthorized"
               withBlock:^(RouteRequest *request, RouteResponse *response __unused) {
                   id<MEMELibDelegate> delegate = self.delegate;
                   if ([delegate respondsToSelector:@selector(memeFirmwareAuthorized:)]) {
                       [delegate memeFirmwareAuthorized:[request.params[@"arg0"] intValue]];
                   }
               }];
        [self.server get:@"/memePeripheralFound:withDeviceAddress"
               withBlock:^(RouteRequest *request, RouteResponse *response __unused) {
                   id<MEMELibDelegate> delegate = self.delegate;
                   if ([delegate respondsToSelector:@selector(memePeripheralFound:withDeviceAddress:)]) {
                       ProxyCBPeripheral *peripheral = [ProxyCBPeripheral new];
                       NSString *arg0 = request.params[@"arg0"];
                       peripheral.identifier = [[NSUUID alloc] initWithUUIDString:arg0];
                       [delegate memePeripheralFound:peripheral
                                   withDeviceAddress:request.params[@"arg1"]];
                   }
               }];
        [self.server get:@"/memePeripheralConnected"
               withBlock:^(RouteRequest *request, RouteResponse *response __unused) {
                   id<MEMELibDelegate> delegate = self.delegate;
                   if ([delegate respondsToSelector:@selector(memePeripheralConnected:)]) {
                       ProxyCBPeripheral *peripheral = [ProxyCBPeripheral new];
                       NSString *arg0 = request.params[@"arg0"];
                       peripheral.identifier = [[NSUUID alloc] initWithUUIDString:arg0];
                       [delegate memePeripheralConnected:peripheral];
                   }
               }];
        [self.server get:@"/memePeripheralDisconnected"
               withBlock:^(RouteRequest *request, RouteResponse *response __unused) {
                   id<MEMELibDelegate> delegate = self.delegate;
                   if ([delegate respondsToSelector:@selector(memePeripheralDisconnected:)]) {
                       ProxyCBPeripheral *peripheral = [ProxyCBPeripheral new];
                       NSString *arg0 = request.params[@"arg0"];
                       peripheral.identifier = [[NSUUID alloc] initWithUUIDString:arg0];
                       [delegate memePeripheralDisconnected:peripheral];
                   }
               }];
        [self.server get:@"/memeRealTimeModeDataReceived"
               withBlock:^(RouteRequest *request, RouteResponse *response __unused) {
                   id<MEMELibDelegate> delegate = self.delegate;
                   if ([delegate respondsToSelector:@selector(memeRealTimeModeDataReceived:)]) {
                       MEMERealTimeData *data = [MEMERealTimeData new];
                       data.fitError = [request.params[@"arg0"]  unsignedCharValue];
                       data.isWalking = [request.params[@"arg1"] unsignedCharValue];
                       data.powerLeft = [request.params[@"arg2"] unsignedCharValue];
                       data.eyeMoveUp = [request.params[@"arg3"] unsignedCharValue];
                       data.eyeMoveDown = [request.params[@"arg4"] unsignedCharValue];
                       data.eyeMoveLeft = [request.params[@"arg5"] unsignedCharValue];
                       data.eyeMoveRight = [request.params[@"arg6"] unsignedCharValue];
                       data.blinkSpeed = [request.params[@"arg7"] unsignedCharValue];
                       data.blinkStrength = [request.params[@"arg8"] unsignedCharValue];
                       data.roll = [request.params[@"arg9"] floatValue];
                       data.pitch = [request.params[@"arg10"] floatValue];
                       data.yaw = [request.params[@"arg11"] floatValue];
                       data.accX = [request.params[@"arg12"] charValue];
                       data.accY = [request.params[@"arg13"] charValue];
                       data.accZ = [request.params[@"arg14"] charValue];
                       [delegate memeRealTimeModeDataReceived:data];
                   }
               }];
        [self.server get:@"/memeCommandResponse"
               withBlock:^(RouteRequest *request, RouteResponse *response __unused) {
                   id<MEMELibDelegate> delegate = self.delegate;
                   if ([delegate respondsToSelector:@selector(memePeripheralDisconnected:)]) {
                       MEMEResponse r;
                       r.eventCode = [request.params[@"arg0"] intValue];
                       r.commandResult = [request.params[@"arg1"] boolValue];
                       [delegate memeCommandResponse:r];
                   }
               }];

        NSError *error;
        if (![self.server start:&error]) {
        }
    }
    return self;
}

-(void)dealloc
{
#if NEEDS_DISPATCH_RETAIN_RELEASE
    dispatch_release(_synchronizationQueue);
#endif
}

- (void)setDelegate:(id<MEMELibDelegate>)del
{
    _delegate = del;
}

- (void) setAppClientId:(NSString *)clientId
           clientSecret:(NSString *)clientSecret
{
    if ([self isAuthorizationPending]) {
        NSLog(@"Authorization already pending; ignored");
    }
    else if ([self isAuthorized]) {
        NSLog(@"Authorization already done; ignored");
    }
    else {
        self.clientID     = clientId;
        self.clientSecret = clientSecret;
        
        [self setAuthorizedPending:YES];
        id result = [self callValueAPI:@"setAppClientId:clientSecret"
                         withArguments:@[ self.clientID, self.clientSecret ]];
        
        if ([result isEqualToString:@"-1"]) {
            NSLog(@"Setting client id/secret failed");
            [self setAuthorizedPending:NO];
        }
    }
}

#pragma mark AUTH

+ (void) setAppClientId:(NSString *)clientId clientSecret:(NSString *)clientSecret
{
    [[self sharedInstance] setAppClientId:clientId clientSecret:clientSecret];
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
    return [[self callValueAPI:@"isCalibrated"] intValue];
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

- (MEMEStatus) connectPeripheral:(ProxyCBPeripheral *)peripheral
{
    return [self callStatusAPI:@"connectPeripheral" withArguments:@[[[peripheral identifier] UUIDString]]];
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
        ProxyCBPeripheral *peripheral = [ProxyCBPeripheral new];
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
    NSString *str = [self callValueAPI:@"getHWVersion"];
    
    return (UInt8) [NSNumber numberWithLongLong:str.longLongValue].unsignedIntegerValue;
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
- (id)    callAPI:(NSString *)api
    withArguments:(NSArray *)args
            error:(NSError * __autoreleasing *)error
{
    NSAssert([self isAuthorized] || [api isEqualToString:@"setAppClientId:clientSecret"],
                                        @"Client is not initialized/authorized");
 
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
    NSLog(@"Sending request url: %@", URLComponents.URL.absoluteString);
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    NSHTTPURLResponse *response = nil;
    
#if __MAC_OS_X_VERSION_MIN_REQUIRED >= 1011
    NSData *resultData = [self sendSynchronousRequest:request
                                returningResponse:&response
                                            error:error];
#else
    NSData *resultData = [NSURLConnection sendSynchronousRequest:request
                                           returningResponse:&response
                                                       error:error];
#endif
    
    NSString *result = [[NSString alloc] initWithData:resultData encoding:NSUTF8StringEncoding];
    if (*error) {
        NSLog(@"!!!!!!!!!!!!!!!\napi:%@\nargs:%@\nerror:%@", api, args, *error);
        return nil;
    }
    else if (response.statusCode != 200) {
        NSLog(@"API call returned status: %ld: Response: %@, Body: \"%@\"", (long)response.statusCode, response, result);
        if (error != nil) {
            *error = [NSError errorWithDomain:MEMEErrDomain code:response.statusCode userInfo:@{ MEMEErrStatusCodeKey: @(MEME_ERROR) }];
        }
    }
    else {
        NSLog(@"Received response: %@", result);
    }
    return result;
} /* callAPI */

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
