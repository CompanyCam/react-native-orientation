//
//  Orientation.h
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "CoreMotion/CoreMotion.h"
#if __has_include(<React/RCTBridgeModule.h>)
#import <React/RCTBridgeModule.h>
#import <React/RCTEventEmitter.h>
#else
#import "RCTBridgeModule.h"
#import "RCTEventEmitter.h"
#endif

typedef NS_ENUM( NSInteger, CCCameraOrientation ) {
    CCCameraOrientationPortrait,
    CCCameraOrientationLandscapeLeft,
    CCCameraOrientationLandscapeRight,
    CCCameraOrientationPortraitUpsideDown,
};

@interface Orientation : RCTEventEmitter <RCTBridgeModule>

@property (nonatomic, retain) CMMotionManager *motionManager;
@property (nonatomic, assign) CCCameraOrientation lastOrientation;

+ (void)setOrientation: (UIInterfaceOrientationMask)orientation;
+ (UIInterfaceOrientationMask)getOrientation;

@end

