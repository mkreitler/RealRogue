//
//  ActionTracker.cpp
//  RealRogueTest
//
//  Created by Mark Kreitler on 6/13/14.
//
//

#include "ActionTracker.h"
#include "Compass.h"
#include "Accelerometer.h"

#include "../Classes/SmoothingQueue.cpp"

#define COMPASS       ((id)pCompass)
#define ACCELEROMETER ((id)pAccelerometer)
#define PI            (3.1415926)

static const float kSlashStartTolerance(0.7f);
static const float kMinSlashStartDisplacement(60.f);
static const float kCutStartTolerance(0.7f);
static const float kMinCutStartDisplacement(0.33f);
static const float kSlashContinueTolerance(0.67f);
static const float kCutContinueTolerance(0.67f);
static const float kMinHeadingDiff(3.f);
static const float kGimbalLockThreshold(sinf(PI * 95.f / 180.f));
static const float kMinAccelDiff(0.01f);
static const float kMinSlashHeadingDiff(15.f);
static const float kMinCutAccelDiff(0.1f);
static const float kChopMaxTiltThresh(sinf(67.f * PI / 180.f));
static const float kChopMinTiltThresh(sinf(33.f * PI / 180.f));
static const int   kMinAccumSamples(5);

static char sStatus[256];

// =============================================================================
// Static Methods
// =============================================================================
ActionTracker* ActionTracker::create() {
    return new ActionTracker();
}

// =============================================================================
// Public Methods
// =============================================================================
void ActionTracker::start() {
    if (!pCompass) {
        pCompass = [[Compass alloc] init];
        pHeadings.setBranchCutValue(360.f);
    }

    [COMPASS activate];
    
    if (!pAccelerometer) {
        pAccelerometer = [[Accelerometer alloc] init];
    }
    
    [ACCELEROMETER activate];
    
    timer = 0.f;
    intervalDt = 0.f;
    iLastHeading = -1;
    bWantsNewGesture = true;
}

void ActionTracker::stop() {
    if (pCompass) {
        [COMPASS deactivate];
        [COMPASS release];
        
        pCompass = NULL;
    }
    
    if (pAccelerometer) {
        [ACCELEROMETER deactivate];
        [ACCELEROMETER release];
        
        pAccelerometer = NULL;
    }
}

int ActionTracker::computeMaxAccelSequence(int maxIndex, int offset) {
    int nLongestChain = 0;
    
    for (int i=offset; i<maxIndex; ++i) {
        float lastDiff = yAccelAnalyzer[(i + 1) % maxIndex] - yAccelAnalyzer[i];
        int nChain = 1;
        bool bMaxDiffReached = false;
        
        for (int j=i+1; j<i+maxIndex; ++j) {
            int iThis = j % maxIndex;
            int iNext = (iThis + 1) % maxIndex;
            
            float diff = yAccelAnalyzer[iNext] - yAccelAnalyzer[iThis];
            
            bMaxDiffReached |= fabs(diff) > kMinAccelDiff;
            
            if (lastDiff * diff > 0.f) {
                ++nChain;
            }
            
            lastDiff = diff;
        }
        
        bMaxDiffReached |= fabs(lastDiff) > kMinAccelDiff;
        
        if (nChain > nLongestChain && bMaxDiffReached) {
            nLongestChain = nChain;
        }
    }
    
    return nLongestChain;
}

// Computes the longest chain of differences with like sign in the
// headings array.
int ActionTracker::computeMaxHeadingSequence(int maxIndex, int offset) {
    int nLongestChain = 0;
    
    assert(offset < maxIndex);
    
    for (int i=offset; i<maxIndex; ++i) {
        float lastDiff = headingAnalyzer[(i + 1) % maxIndex] - headingAnalyzer[i];
        int nChain = 1;
        bool bMaxDiffReached = false;
        
        lastDiff = boundToBranchCut(lastDiff);
        
        for (int j=i+1; j<i+(maxIndex - offset); ++j) {
            int iThis = j % maxIndex;
            int iNext = (iThis + 1) % maxIndex;
            
            float diff = headingAnalyzer[iNext] - headingAnalyzer[iThis];

            diff = boundToBranchCut(diff);

            bMaxDiffReached |= fabs(diff) > kMinHeadingDiff;
            
            if (lastDiff * diff > 0.f) {
                ++nChain;
            }
            
            lastDiff = diff;
        }
        
        bMaxDiffReached |= fabs(lastDiff) > kMinHeadingDiff;
        
        if (nChain > nLongestChain && bMaxDiffReached) {
            nLongestChain = nChain;
        }
    }
    
    return nLongestChain;
}

void ActionTracker::resetHeadingGesture() {
    bWantsNewGesture = true;
    iLastHeading = -1;
    startHeading = 0.f;
    endHeading = 0.f;
    startAccelY = 0.f;
    endAccelY = 0.f;
}

void ActionTracker::completeGesture() {
    startHeading = 0.f;
    startAccelY = 0.f;

    // Compute traversal distance as RMS difference.
    endHeading = rmsHeadingDisplacement(iLastHeading);
    endAccelY = rmsAccelDisplacement(iLastHeading);
    zAccelAccum = accumulateAccelZ(iLastHeading);
    
    bWantsNewGesture = false;
    iLastHeading = -1;
    
    assessGesture();
}

float ActionTracker::accumulateAccelZ(int iMaxIndex) {
    float accum = 0.f;
    int iStartSample = (int)(0.2f * (float)SAMPLES_PER_SECOND + 0.5f);
    
    // Ignore the first few samples to reduce transients in the data.
    if (iMaxIndex - iStartSample + 1 < kMinAccumSamples) {
        iStartSample = iMaxIndex - kMinAccumSamples + 1;
        
        if (iStartSample < 0) {
            iStartSample = 0;
        }
    }
    
    float samples = (float)(iMaxIndex + 1 - iStartSample);
    
    // Compute average.
    for (int i=iStartSample; i<=iMaxIndex; ++i) {
        accum += zAccelAnalyzer[i];
    }
    float aveAccelZ = accum / samples;
    
    // Compute "signed RMS" differences about average.
    accum = 0.f;
    for (int i=iStartSample; i<=iMaxIndex; ++i) {
        float diff = aveAccelZ - zAccelAnalyzer[i];
        accum += diff * abs(diff);
    }
    accum = sqrtf(accum / samples);
    
    return aveAccelZ + accum * samples;
}

void ActionTracker::startGesture() {
    bWantsNewGesture = false;
    startHeading = aveHeading;
    endHeading = startHeading;
    startAccelY = aveAccelY;
    endAccelY = aveAccelY;
}

float ActionTracker::maxAccelDisplacement(int maxIndex) {
    // AveDisp = (signed root mean squared difference) * number of differences
    float aveDisp = 0.f;
    
    for (int i=1; i<= maxIndex; ++i) {
        float diff = yAccelAnalyzer[i] - yAccelAnalyzer[i - 1];
        aveDisp += diff * fabs(diff);
    }
    
    aveDisp = sqrtf(fabs(aveDisp) / maxIndex) * maxIndex;
    
    
    return aveDisp;
}

float ActionTracker::maxHeadingDisplacement(int maxIndex) {
    // AveDisp = (signed root mean squared difference) * number of differences
    float aveDisp = 0.f;
    
    for (int i=1; i<= maxIndex; ++i) {
        float diff = headingAnalyzer[i] - headingAnalyzer[i - 1];
        
        if (diff > 180.f) {
            diff = diff - 360.f;
        }
        else if (diff < -180.f) {
            diff = diff + 360.f;
        }
        
        aveDisp += diff * fabs(diff);
    }
    
    aveDisp = sqrtf(fabs(aveDisp) / maxIndex) * maxIndex;
    
    
    return aveDisp;
}

float ActionTracker::boundToBranchCut(float diff) {
    if (diff > 180.f) {
        diff -= 360.f;
    }
    else if (diff < -180.f) {
        diff += 360.f;
    }

    return diff;
}

float ActionTracker::rmsHeadingDisplacement(int maxIndex) {
    float diffStep = fabs(maxHeadingDisplacement(maxIndex) / (float)maxIndex);
    float aveDisp = 0.f;
    
    for (int i=1; i<= maxIndex; ++i) {
        float diff = boundToBranchCut(headingAnalyzer[i] - headingAnalyzer[i - 1]);
        
        if (diff < 0.f) {
            aveDisp -= diffStep;
        }
        else {
            aveDisp += diffStep;
        }
    }
    
    return aveDisp;
}

float ActionTracker::rmsAccelDisplacement(int maxIndex) {
    float diffStep = fabs(maxAccelDisplacement(maxIndex) / (float)maxIndex);
    float aveDisp = 0.f;
    
    for (int i=0; i<= maxIndex; ++i) {
        float diff = yAccelAnalyzer[i] - yAccelAnalyzer[i - 1];
        if (diff < 0.f) {
            aveDisp -= diffStep;
        }
        else {
            aveDisp += diffStep;
        }
    }
    
    return aveDisp;
}

void ActionTracker::analyze(float dt) {
    intervalDt += dt;
    
    while (intervalDt >= analysisInterval) {
        intervalDt -= analysisInterval;
        
        int index = (iLastHeading + 1) % headingAnalyzer.size();
        int iFifthSec = 0.2f / analysisInterval;
        int iHalfSec = 0.5f / analysisInterval;
        
        iLastHeading = index;
        
        yAccelAnalyzer[index] = aveAccelY;
        zAccelAnalyzer[index] = aveAccelZ;
        headingAnalyzer[index] = aveHeading;
        
        if (index == iFifthSec) {
            checkForGestureStart(iFifthSec, index);
        }
        else if (index > headingAnalyzer.size() / 2 && index < headingAnalyzer.size() - 1) {
            checkForGestureContinue(iHalfSec, iFifthSec, index);
        }
        else if (index == headingAnalyzer.size() - 1) {
            // Gesture timed out.
            completeGesture();
        }
    }
}

bool ActionTracker::checkForHeadingStop(int index, int iFifthSec) {
    float frontAve = 0.f;
    float backAve = 0.f;
    
    for (int i=0; i<index - iFifthSec; ++i) {
        float diff = headingAnalyzer[i + 1] - headingAnalyzer[i];
        
        diff = boundToBranchCut(diff);
        
        if (abs(diff) < kMinHeadingDiff) {
            diff = 0.f;
        }
        
        frontAve += diff;
    }
    
    frontAve /= (float)(index - iFifthSec);
    
    for (int i=index - iFifthSec; i<index; ++i) {
        float diff = headingAnalyzer[i + 1] - headingAnalyzer[i];
        
        diff = boundToBranchCut(diff);
        
        if (abs(diff) < kMinHeadingDiff) {
            diff = 0.f;
        }
        
        backAve += diff;
    }
    
    backAve /= (float)(iFifthSec);
    
    return frontAve * backAve <= kMinHeadingDiff * kMinHeadingDiff;
}

bool ActionTracker::checkForAccelStop(int index, int iFifthSec) {
    float frontAve = 0.f;
    float backAve = 0.f;
    
    for (int i=0; i<index - iFifthSec; ++i) {
        float diff = yAccelAnalyzer[i + 1] - yAccelAnalyzer[i];
        
        if (abs(diff) < kMinAccelDiff) {
            diff = 0.f;
        }
        
        frontAve += diff;
    }
    
    frontAve /= (float)(index - iFifthSec);
    
    for (int i=index - iFifthSec; i<index; ++i) {
        float diff = yAccelAnalyzer[i + 1] - yAccelAnalyzer[i];
        
        if (abs(diff) < kMinAccelDiff) {
            diff = 0.f;
        }
        
        backAve += diff;
    }
    
    backAve /= (float)(iFifthSec);
    
    return frontAve * backAve <= kMinAccelDiff * kMinAccelDiff;
}

void ActionTracker::checkForGestureContinue(int iHalfSec, int iFifthSec, int index) {
    int nMaxHeadingSequence = computeMaxHeadingSequence(index, 0);
    bool bSlashStopped = (float)nMaxHeadingSequence / (float)index < kSlashContinueTolerance;
    
    int nMaxAccelSequence = computeMaxAccelSequence(index, 0);
    bool bCutStopped = (float)nMaxAccelSequence / (float)index < kCutContinueTolerance;
    
    if (bSlashStopped && bCutStopped) {
        resetHeadingGesture();
    }
    else if (index - iFifthSec >= iFifthSec) {
        // Check for end of gesture.
        bool bSlashStopped = checkForHeadingStop(index, iFifthSec);
        bool bCutStopped = checkForAccelStop(index, iFifthSec);
        
        if (bSlashStopped && bCutStopped) {
            completeGesture();
            resetHeadingGesture();
        }
    }
}

void ActionTracker::checkForGestureStart(int iFifthSec, int index) {
    // Check for start of gesture.
    // TODO: include tolerance in function call to allow "early out"
    // if a sequence is found at or greater than the tolerance.
    
    int nMaxHeadingSequence = computeMaxHeadingSequence(index, 0);
    float maxDisp = maxHeadingDisplacement(iFifthSec);
    
    int nMaxAccelSequence = computeMaxAccelSequence(index, 0);
    float maxAccel = maxAccelDisplacement(iFifthSec);
    
    bool bNoSlash = (float)nMaxHeadingSequence / (float)iFifthSec < kSlashStartTolerance ||
    maxDisp < kMinSlashStartDisplacement;
    
    bool bNoCut = (float)nMaxAccelSequence / (float)iFifthSec < kCutStartTolerance ||
    maxAccel < kMinCutStartDisplacement;
    
    if (bNoSlash && bNoCut) {
        resetHeadingGesture();
    }
    else if (!bWantsNewGesture) {
        // Processing the tail end of the previous gesture. Loop
        // back to the start of the analysis until the user stops
        // this gesture.
        iLastHeading = -1;
    }
    else {
        startGesture();
    }
}

void ActionTracker::update() {
    // Acceleration
    float accel = MIN(1.f, MAX(-1.f, [ACCELEROMETER reportAcceleration: y]));
    pAccelY.append(accel);
    aveAccelY = pAccelY.getSmoothedValue();
    
    accel = MIN(1.f, MAX(-1.f, [ACCELEROMETER reportAcceleration: x]));
    pAccelX.append(accel);
    aveAccelX = pAccelX.getSmoothedValue();
    
    accel = MIN(1.f, MAX(-1.f, [ACCELEROMETER reportAcceleration: z]));
    pAccelZ.append(accel);
    aveAccelZ = pAccelZ.getSmoothedValue();

    // Heading
    float newHeading = [COMPASS reportHeading: NO];
    if (fabs(aveAccelY) > kGimbalLockThreshold) {
        if (lastHeading >= 0) {
            newHeading = lastHeading;
        }
        else {
            // TODO: make sure this doesn't screw up the gestures if the
            // controller starts in the gimbal lock position.
            newHeading = 0.f;
        }
    }
    lastHeading = newHeading;
    
    pHeadings.append(newHeading);
    aveHeading = pHeadings.getSmoothedValue();
}

char* ActionTracker::getStatus() {

//  sprintf(sStatus, "Heading: %3.2f   AccelX: %3.2f   AccelY: %3.2f   AccelZ: %3.2f", aveHeading, aveAccelX, aveAccelY, aveAccelZ);
//  return sStatus;
    
    return sStatus;
}

void ActionTracker::addListener(ActionListener* listener) {
    if (listener) {
        listeners.push_back(listener);
    }
}

void ActionTracker::removeListener(ActionListener* listener) {
    listeners.remove(listener);
}

void ActionTracker::removeAllListeners() {
    while (listeners.size()) {
        listeners.pop_front();
    }
}

void ActionTracker::notifyListeners(GestureType type) {
    std::list<ActionListener*>::iterator iter;
    
    for (iter = listeners.begin(); iter != listeners.end(); ++iter) {
        (*iter)->onGestureComplete(type);
    }
}

void ActionTracker::assessGesture() {
    float headingDiff = fabs(endHeading - startHeading);
    if (headingDiff > 180.f) {
        headingDiff -= 360.f;
    }
    
    float accelDiff = endAccelY - startAccelY;
    
    bool bMoved = fabs(headingDiff) > kMinSlashHeadingDiff || fabs(accelDiff) > kMinCutAccelDiff;
    bool bSlash = bMoved && fabs(zAccelAccum) > kChopMaxTiltThresh;
    bool bCut = bMoved && fabs(zAccelAccum) < kChopMinTiltThresh;
    
    if (bSlash) {
        //        int damage = abs(endHeading - startHeading);
        sprintf(sStatus, "!!! Slash !!! dHeading: %3.2f   dAcc: %3.2f %1.4f", headingDiff, accelDiff, zAccelAccum);
        notifyListeners(GT_SLASH);
    }
    else if (bCut) {
        //        int damage = (int)(fabs(endAccelY - startAccelY) * 180.f + 0.5f);
        sprintf(sStatus, "*** Cut *** dHeading: %3.2f   dAcc: %3.2f %1.4f", headingDiff, accelDiff, zAccelAccum);
        notifyListeners(GT_CUT);
    }
    else if (bMoved) {
        //        int damageSlash = abs(endHeading - startHeading);
        //        int damageCut = (int)(fabs(endAccelY - startAccelY) * 180.f + 0.5f);
        //        int damage = (int)(sqrtf(damageSlash * damageSlash + damageCut * damageCut) + 0.5f);
        
        sprintf(sStatus, "<<< Chop >>> dHeading: %3.2f   dAcc: %3.2f %1.4f", headingDiff, accelDiff, zAccelAccum);
        notifyListeners(GT_CHOP);
    }
    else {
        sprintf(sStatus, "dHeading: %3.2f   dAcc: %3.2f   %1.4f", headingDiff, accelDiff, zAccelAccum);
    }
}

float ActionTracker::getAverageHeading() {
    return aveHeading;
}

ActionTracker::~ActionTracker() {
    stop();
}

// =============================================================================
// Private Methods
// =============================================================================
ActionTracker::ActionTracker()
: pCompass(NULL)
, aveHeading(0.f)
, lastHeading(-1.f)
, pAccelerometer(NULL)
, aveAccelX(0.f)
, aveAccelY(0.f)
, aveAccelZ(0.f)
, analysisInterval(1.f / (float)SAMPLES_PER_SECOND) {
}
