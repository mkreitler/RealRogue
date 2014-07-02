//
//  Compass.mm
//  RealRogueTest
//
//  Created by Mark Kreitler on 6/13/14.
//
//

#include "Compass.h"

@implementation Compass 

@synthesize locationManager, lastMagneticHeading, lastTrueHeading;

- (id)init {
    self = [super init];
    if (self) {
        lastMagneticHeading = 0.f;
        lastTrueHeading = 0.f;
        locationManager = NULL;
    }
    return self;
}

-(void) locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading {
    lastMagneticHeading = newHeading.magneticHeading;
    lastTrueHeading = newHeading.trueHeading;
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    NSLog(@">>> Compass failed to initialize with error %@", [error localizedFailureReason]);
}

-(float) reportHeading: (BOOL) bMagnetic {
    return lastMagneticHeading;
}

 -(void) activate {
    if (!locationManager) {
        locationManager = [[CLLocationManager alloc] init];
        locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        locationManager.delegate = self;
    }
    
    //Start the compass updates.
    [locationManager startUpdatingHeading];
}

-(void) deactivate {
    [locationManager stopUpdatingHeading];
    [locationManager release];
    locationManager = NULL;
}

-(char*)getStatus {
    static char s_status[256];
    sprintf(s_status, "Mag Heading: %3.2f   True Heading: %3.2f", lastMagneticHeading, lastTrueHeading);
    return s_status;
}

@end

