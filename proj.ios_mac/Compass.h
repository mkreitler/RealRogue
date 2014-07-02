//
//  Compass.h
//  RealRogueTest
//
//  Created by Mark Kreitler on 6/13/14.
//
//

#ifndef __RealRogueTest__Compass__
#define __RealRogueTest__Compass__

#include <iostream>
#include <CoreLocation/CoreLocation.h>

// =============================================================================
// Compass
// =============================================================================
@interface Compass : NSObject <CLLocationManagerDelegate> {
}

-(id) init;
-(void) activate;
-(void) deactivate;
-(char*) getStatus;
-(float) reportHeading: (BOOL)bMagnetic;

@property(nonatomic, retain)        CLLocationManager*  locationManager;
@property(atomic, assign)           float               lastMagneticHeading;
@property(atomic, assign)           float               lastTrueHeading;

@end

#endif /* defined(__RealRogueTest__Compass__) */
