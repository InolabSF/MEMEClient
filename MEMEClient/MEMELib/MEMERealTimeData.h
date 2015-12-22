#import <Foundation/Foundation.h>


@interface MEMERealTimeData : NSObject


@property UInt8 fitError; // 0: 正常 1: 装着エラー
@property UInt8 isWalking;

@property UInt8 powerLeft; // 5: フル充電 0: 空

@property UInt8 eyeMoveUp;
@property UInt8 eyeMoveDown;
@property UInt8 eyeMoveLeft;
@property UInt8 eyeMoveRight;

@property UInt8 blinkSpeed;    // in ms
@property UInt8 blinkStrength;

@property float roll;
@property float pitch;
@property float yaw;

@property SInt8 accX;
@property SInt8 accY;
@property SInt8 accZ;


@end

