//
//  Accelerometer.mm
//  RealRogueTest
//
//  Created by Mark Kreitler on 6/15/14.
//
//

#include "Accelerometer.h"

@implementation Accelerometer

@synthesize motionManager;

- (id)init {
    self = [super init];
    if (self) {
        // Initialize self.
        motionManager = nil;
    }
    return self;
}

-(void) activate {
    if (!motionManager) {
        motionManager = [[CMMotionManager alloc] init];
    }
    
    [motionManager startAccelerometerUpdates];
}

-(void) deactivate {
    if (motionManager != nil) {
        [motionManager stopAccelerometerUpdates];
        
        [motionManager release];
        motionManager = nil;
    }
}

-(char *) getStatus {
    static char sStatus[256];
    
    sprintf(sStatus, "Accel: %3.2f, %3.2f, %3.2f", [self reportAcceleration: x], [self reportAcceleration: y], [self reportAcceleration: z]);
    
    return sStatus;
}

-(float) reportAcceleration: (accelAxis)axis {
    float value = 0.f;
    
    if (motionManager != nil) {
        CMAccelerometerData *accelerometerData = motionManager.accelerometerData;
        CMAcceleration acceleration = accelerometerData.acceleration;
        
        switch (axis) {
            case x:
                value = (float)acceleration.x;
            break;
                
            case y:
                value = (float)acceleration.y;
            break;
                
            default: // z
                value = (float)acceleration.z;
            break;
        }
    }
    
    return value;
}


@end



