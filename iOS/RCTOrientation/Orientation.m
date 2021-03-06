//
//  Orientation.m
//

#import "Orientation.h"
#if __has_include(<React/RCTEventDispatcher.h>)
#import <React/RCTEventDispatcher.h>
#else
#import "RCTEventDispatcher.h"
#endif

@implementation Orientation

static UIInterfaceOrientationMask _orientation = UIInterfaceOrientationMaskAllButUpsideDown;
+ (void)setOrientation: (UIInterfaceOrientationMask)orientation {
    _orientation = orientation;
}
+ (UIInterfaceOrientationMask)getOrientation {
    return _orientation;
}

- (instancetype)init
{
    if ((self = [super init])) {
        [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceOrientationDidChange:) name:@"UIDeviceOrientationDidChangeNotification" object:nil];
        [self initializeMotionManager];
    }
    return self;
}

// This method initializes the motionManager object
-(void)initializeMotionManager {
    
    self.motionManager = [[CMMotionManager alloc] init];
    self.motionManager.accelerometerUpdateInterval = .2;
    
    // If the accelerometer is available, then start getting updates.
    self.lastOrientation = CCCameraOrientationPortrait;
    if ([self.motionManager isAccelerometerAvailable]) {
        [self.motionManager startAccelerometerUpdatesToQueue:[NSOperationQueue currentQueue]
                                                 withHandler:^(CMAccelerometerData  *accelerometerData, NSError *error) {
                                                     if (!error) {
                                                         
                                                         // Handle the acceleration data
                                                         [self outputAccelertionData:accelerometerData.acceleration];
                                                     }
                                                     else{
                                                         NSLog(@"%@", error);
                                                     }
                                                 }];
        
    }
    
    // If the accelerometer isn't available, then set a default value for the lastOrientation
    else {
        self.lastOrientation = CCCameraOrientationPortrait;
    }
}

// This method processes acceleration data from the motionManager
-(void)outputAccelertionData:(CMAcceleration)acceleration {
    
    CCCameraOrientation orientationNew;
    
    // Determine the device orientation based on the accelerometer data
    if (acceleration.x >= 0.75) {
        orientationNew = CCCameraOrientationLandscapeRight;
    }
    else if (acceleration.x <= -0.75) {
        orientationNew = CCCameraOrientationLandscapeLeft;
    }
    else if (acceleration.y <= -0.75) {
        orientationNew = CCCameraOrientationPortrait;
    }
    else if (acceleration.y >= 0.75) {
        orientationNew = CCCameraOrientationPortraitUpsideDown;
    }
    else {
        // Consider same as last time
        return;
    }
    
    // Update the UI if the device orientation has changed
    if (orientationNew != self.lastOrientation && [self bridge] != nil) {
        self.lastOrientation = orientationNew;
        [self sendEventWithName:@"CCCameraOrientationChange"
                           body:@{@"orientation": [NSNumber numberWithInteger:self.lastOrientation]}];
    }
}

- (NSArray<NSString *> *)supportedEvents
{
    return @[@"specificOrientationDidChange",
             @"orientationDidChange",
             @"CCCameraOrientationChange"];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

+ (BOOL)requiresMainQueueSetup
{
    return YES;
}

- (void)deviceOrientationDidChange:(NSNotification *)notification
{
    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
    
    if ([self bridge] != nil) {
        [self sendEventWithName:@"specificOrientationDidChange" body:@{@"specificOrientation": [self getSpecificOrientationStr:orientation]}];
        [self sendEventWithName:@"orientationDidChange" body:@{@"orientation": [self getOrientationStr:orientation]}];
    }
    
    
    
    
    // these are needed because no accelerometer in the simulator
    
    CCCameraOrientation orientationNew;
    switch (orientation) {
        case UIDeviceOrientationPortrait:
            orientationNew = CCCameraOrientationPortrait;
            break;
        case UIDeviceOrientationLandscapeLeft:
            orientationNew = CCCameraOrientationLandscapeLeft;
            break;
        case UIDeviceOrientationLandscapeRight:
            orientationNew = CCCameraOrientationLandscapeRight;
            break;
        case UIDeviceOrientationPortraitUpsideDown:
            orientationNew = CCCameraOrientationPortraitUpsideDown;
            break;
        default:
            // use last known orientation (if FaceUp or FaceDown, or unknown)
            orientationNew = self.lastOrientation;
            break;
    }
    
    // Update the UI if the device orientation has changed
    if (orientationNew != self.lastOrientation && [self bridge] != nil) {
        self.lastOrientation = orientationNew;
        [self sendEventWithName:@"CCCameraOrientationChange"
                           body:@{@"orientation": [NSNumber numberWithInteger:self.lastOrientation]}];
    }
}

- (NSString *)getOrientationStr: (UIDeviceOrientation)orientation {
    NSString *orientationStr;
    switch (orientation) {
        case UIDeviceOrientationPortrait:
            orientationStr = @"PORTRAIT";
            break;
        case UIDeviceOrientationLandscapeLeft:
        case UIDeviceOrientationLandscapeRight:
            
            orientationStr = @"LANDSCAPE";
            break;
            
        case UIDeviceOrientationPortraitUpsideDown:
            orientationStr = @"PORTRAITUPSIDEDOWN";
            break;
            
        default:
            // orientation is unknown, we try to get the status bar orientation
            switch ([[UIApplication sharedApplication] statusBarOrientation]) {
                case UIInterfaceOrientationPortrait:
                    orientationStr = @"PORTRAIT";
                    break;
                case UIInterfaceOrientationLandscapeLeft:
                case UIInterfaceOrientationLandscapeRight:
                    
                    orientationStr = @"LANDSCAPE";
                    break;
                    
                case UIInterfaceOrientationPortraitUpsideDown:
                    orientationStr = @"PORTRAITUPSIDEDOWN";
                    break;
                    
                default:
                    orientationStr = @"UNKNOWN";
                    break;
            }
            break;
    }
    return orientationStr;
}

- (NSString *)getSpecificOrientationStr: (UIDeviceOrientation)orientation {
    NSString *orientationStr;
    switch (orientation) {
        case UIDeviceOrientationPortrait:
            orientationStr = @"PORTRAIT";
            break;
            
        case UIDeviceOrientationLandscapeLeft:
            orientationStr = @"LANDSCAPE-LEFT";
            break;
            
        case UIDeviceOrientationLandscapeRight:
            orientationStr = @"LANDSCAPE-RIGHT";
            break;
            
        case UIDeviceOrientationPortraitUpsideDown:
            orientationStr = @"PORTRAITUPSIDEDOWN";
            break;
            
        default:
            // orientation is unknown, we try to get the status bar orientation
            switch ([[UIApplication sharedApplication] statusBarOrientation]) {
                case UIInterfaceOrientationPortrait:
                    orientationStr = @"PORTRAIT";
                    break;
                case UIInterfaceOrientationLandscapeLeft:
                case UIInterfaceOrientationLandscapeRight:
                    
                    orientationStr = @"LANDSCAPE";
                    break;
                    
                case UIInterfaceOrientationPortraitUpsideDown:
                    orientationStr = @"PORTRAITUPSIDEDOWN";
                    break;
                    
                default:
                    orientationStr = @"UNKNOWN";
                    break;
            }
            break;
    }
    return orientationStr;
}

RCT_EXPORT_MODULE();

RCT_EXPORT_METHOD(getOrientation:(RCTResponseSenderBlock)callback)
{
    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
    NSString *orientationStr = [self getOrientationStr:orientation];
    callback(@[[NSNull null], orientationStr]);
}

RCT_EXPORT_METHOD(getSpecificOrientation:(RCTResponseSenderBlock)callback)
{
    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
    NSString *orientationStr = [self getSpecificOrientationStr:orientation];
    callback(@[[NSNull null], orientationStr]);
}

RCT_EXPORT_METHOD(lockToPortrait)
{
#if DEBUG
    NSLog(@"Locked to Portrait");
#endif
    [Orientation setOrientation:UIInterfaceOrientationMaskPortrait];
    [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
        [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
        [[UIDevice currentDevice] setValue:[NSNumber numberWithInteger: UIInterfaceOrientationPortrait] forKey:@"orientation"];
    }];
    
}

RCT_EXPORT_METHOD(lockToLandscape)
{
#if DEBUG
    NSLog(@"Locked to Landscape");
#endif
    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
    NSString *orientationStr = [self getSpecificOrientationStr:orientation];
    if ([orientationStr isEqualToString:@"LANDSCAPE-LEFT"]) {
        [Orientation setOrientation:UIInterfaceOrientationMaskLandscape];
        [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
            [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
            [[UIDevice currentDevice] setValue:[NSNumber numberWithInteger: UIInterfaceOrientationLandscapeRight] forKey:@"orientation"];
        }];
    } else {
        [Orientation setOrientation:UIInterfaceOrientationMaskLandscape];
        [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
            [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
            [[UIDevice currentDevice] setValue:[NSNumber numberWithInteger: UIInterfaceOrientationLandscapeLeft] forKey:@"orientation"];
        }];
    }
}

RCT_EXPORT_METHOD(lockToLandscapeLeft)
{
#if DEBUG
    NSLog(@"Locked to Landscape Left");
#endif
    [Orientation setOrientation:UIInterfaceOrientationMaskLandscapeLeft];
    [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
        [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
        [[UIDevice currentDevice] setValue:[NSNumber numberWithInteger: UIInterfaceOrientationLandscapeLeft] forKey:@"orientation"];
    }];
    
}

RCT_EXPORT_METHOD(lockToLandscapeRight)
{
#if DEBUG
    NSLog(@"Locked to Landscape Right");
#endif
    [Orientation setOrientation:UIInterfaceOrientationMaskLandscapeRight];
    [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
        // this seems counter intuitive
        [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
        [[UIDevice currentDevice] setValue:[NSNumber numberWithInteger: UIInterfaceOrientationLandscapeRight] forKey:@"orientation"];
    }];
    
}

RCT_EXPORT_METHOD(unlockAllOrientations)
{
#if DEBUG
    NSLog(@"Unlock All Orientations");
#endif
    [Orientation setOrientation:UIInterfaceOrientationMaskAllButUpsideDown];
}

- (NSDictionary *)constantsToExport
{
    
    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
    NSString *orientationStr = [self getOrientationStr:orientation];
    
    return @{
             @"initialOrientation": orientationStr,
             @"orientationEnum": @{
                     @"portrait": @(CCCameraOrientationPortrait),
                     @"landscapeleft": @(CCCameraOrientationLandscapeLeft),
                     @"landscaperight": @(CCCameraOrientationLandscapeRight),
                     @"portraitupsidedown": @(CCCameraOrientationPortraitUpsideDown),
                     },
             };
}

@end

