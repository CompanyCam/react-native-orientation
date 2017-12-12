//
//  Orientation.m
//

#import "Orientation.h"

@implementation Orientation
@synthesize bridge = _bridge;

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
    }
    return self;
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

- (void)deviceOrientationDidChange:(NSNotification *)notification
{
    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
    [self sendEventWithName:@"specificOrientationDidChange"
                       body:@{@"specificOrientation": [self getSpecificOrientationStr:orientation]}];
    
    [self sendEventWithName:@"orientationDidChange"
                       body:@{@"orientation": [self getOrientationStr:orientation]}];
    
    switch (orientation) {
        case UIDeviceOrientationPortrait:
            self.camOrientation = CCCameraOrientationPortrait;
            break;
        case UIDeviceOrientationLandscapeLeft:
            self.camOrientation = CCCameraOrientationLandscapeLeft;
            break;
        case UIDeviceOrientationLandscapeRight:
            self.camOrientation = CCCameraOrientationLandscapeRight;
            break;
        case UIDeviceOrientationPortraitUpsideDown:
            self.camOrientation = CCCameraOrientationPortraitUpsideDown;
            break;
        default:
            // use last known orientation (if FaceUp or FaceDown, or unknown)
            break;
    }
    
    [self sendEventWithName:@"CCCameraOrientationChange"
                       body:@{@"orientation": [NSNumber numberWithInteger:self.camOrientation]}];
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
            [[UIDevice currentDevice] setValue:[NSNumber numberWithInteger: UIInterfaceOrientationLandscapeRight] forKey:@"orientation"];
        }];
    } else {
        [Orientation setOrientation:UIInterfaceOrientationMaskLandscape];
        [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
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
             @"Orientation": @{
                     @"portrait": @(CCCameraOrientationPortrait),
                     @"landscapeleft": @(CCCameraOrientationLandscapeLeft),
                     @"landscaperight": @(CCCameraOrientationLandscapeRight),
                     @"portraitupsidedown": @(CCCameraOrientationPortraitUpsideDown),
                     },
             };
}

+ (BOOL)requiresMainQueueSetup
{
    return YES;
}

@end

