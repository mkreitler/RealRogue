//
//  Accelerometer.h
//  RealRogueTest
//
//  Created by Mark Kreitler on 6/15/14.
//
//

#ifndef __RealRogueTest__Accelerometer__
#define __RealRogueTest__Accelerometer__

#include <iostream>
#include <CoreMotion/CoreMotion.h>

typedef enum eAccelAxis {
    x,
    y,
    z
} accelAxis;

// =============================================================================
// Compass
// =============================================================================
@interface Accelerometer : NSObject {
}

-(id) init;
-(void) activate;
-(void) deactivate;
-(char*) getStatus;
-(float) reportAcceleration: (accelAxis)axis;

@property(nonatomic, retain)        CMMotionManager*  motionManager;

@end

#endif /* defined(__RealRogueTest__Accelerometer__) */
