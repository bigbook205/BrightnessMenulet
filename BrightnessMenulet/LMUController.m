//
//  LMUController.m
//  BrightnessMenulet
//
//  Created by Kalvin Loc on 1/29/16.
//
//

#import "LMUController.h"

@interface LMUController ()

@property CFRunLoopTimerRef updateTimer;

@property (weak) NSTimer* callbackTimer;

@end

@implementation LMUController

+ (LMUController*)singleton{
    static dispatch_once_t pred = 0;
    static LMUController* shared;
    dispatch_once(&pred, ^{
        shared = [[self alloc] init];
    });

    return shared;
}

- (instancetype)init {
    return self;
}

- (void)startMonitoring {
    // Check if timer already exists of if any screens exist
    if(_callbackTimer && ([controls.screens count] == 0)) return;

    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:-1 forKey:@"LMUOldPercent"];

    // NSTimer objects cannot be reused after invalidation
    _callbackTimer = [NSTimer scheduledTimerWithTimeInterval:[defaults floatForKey:@"LMUUpdateInterval"]
                                                      target:self
                                                    selector:@selector(updateTimerCallBack)
                                                    userInfo:nil
                                                     repeats:YES];
    self.monitoring = YES;
    [_delegate LMUControllerDidStartMonitoring];
    
    NSLog(@"LMUController: Started Monitoring");
}

- (void)stopMonitoring {
    [_callbackTimer invalidate];
    _callbackTimer = nil;

    self.monitoring = NO;
    [_delegate LMUControllerDidStopMonitoring];
    NSLog(@"LMUController: Stopped Monitoring");
}

- (float) getSystemBrightness {
    
    io_iterator_t iterator;
    kern_return_t result = IOServiceGetMatchingServices(kIOMasterPortDefault,
                                                        IOServiceMatching("IODisplayConnect"),
                                                        &iterator);
    
    // If we were successful
    if (result == kIOReturnSuccess)
    {
        io_object_t service;
        while ((service = IOIteratorNext(iterator))) {
            
            float level;
            IODisplayGetFloatParameter(service, kNilOptions, CFSTR(kIODisplayBrightnessKey), &level);
            // Let the object go
            IOObjectRelease(service);
            
            return level;
        }
    }
    return -1;
}


- (void)updateTimerCallBack {
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    int minvalue = [defaults integerForKey:@"LMUAutoMin"];
    int maxvalue = [defaults integerForKey:@"LMUAutoMax"];
    int oldPercent = [defaults integerForKey:@"LMUOldPercent"];
    float value = self.getSystemBrightness;

    int newPercent = value * (maxvalue - minvalue) + minvalue;
    
    if(newPercent <= 0 || newPercent > 100 || newPercent == oldPercent)
        return;
    
    for(Screen* screen in controls.screens) {
//        if( screen.currentBrightness != newPercent)
            [self doUpdate:screen:newPercent];
        
    }
    [defaults setInteger:newPercent forKey:@"LMUOldPercent"];
}

- (void)doUpdate: (Screen*)screen :(int)percent {
    
    if ([screen.currentAutoAttribute isEqualToString:@"BR"])
        [screen setBrightnessWithPercentage:percent byOutlet:nil];
    else
        [screen setContrastWithPercentage:percent byOutlet:nil];
}

/*+ (bool) monitoring {
    if (self.monitoring == YES)
        return YES;
    else
        return NO;
}*/

@end
