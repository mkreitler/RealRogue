//
//  ActionTracker.h
//  RealRogueTest
//
//  Created by Mark Kreitler on 6/13/14.
//
//

#ifndef __RealRogueTest__ActionTracker__
#define __RealRogueTest__ActionTracker__

#include <iostream>
#include <array>
#include <string.h>
#include <list>

#include "SmoothingQueue.h"

#define SAMPLES_PER_SECOND      (20)

// =============================================================================
// ActionTracker
// =============================================================================
// The ActionTracker provides a C++ interface to compass and accelerometer
typedef enum {
    GT_UNKNOWN = 0,
    GT_CHOP,
    GT_CUT,
    GT_SLASH,
    NUM_GESTURES
} GestureType;

class ActionListener {
public:
    virtual void onGestureComplete(GestureType type) = 0;
};

class ActionTracker {
public:
    static ActionTracker* create();
    
    void start();
    void stop();
    virtual void update();
    virtual void analyze(float dt);
    void addListener(ActionListener* listener);
    void removeListener(ActionListener* listener);
    void removeAllListeners();
    
    virtual ~ActionTracker();
    
    // Accessors
    void setAnalysisInterval(float newInterval) { analysisInterval = newInterval; }
    char* getStatus();
    float getAverageHeading();
    
private:
    ActionTracker();
    
    int computeMaxHeadingSequence(int maxIndex, int offset);
    int computeMaxAccelSequence(int maxIndex, int offset);
    void resetHeadingGesture();
    void startGesture();
    void completeGesture();
    float maxHeadingDisplacement(int maxIndex);
    float maxAccelDisplacement(int maxIndex);
    void checkForGestureStart(int iFifthSec, int index);
    void checkForGestureContinue(int iHalfSec, int iFifthSec, int index);
    float rmsHeadingDisplacement(int maxIndex);
    float rmsAccelDisplacement(int maxIndex);
    float boundToBranchCut(float diff);
    float accumulateAccelZ(int iMaxIndex);
    void assessGesture();
    void notifyListeners(GestureType type);
    bool checkForHeadingStop(int index, int iFifthSec);
    bool checkForAccelStop(int index, int iFifthSec);
    
    void* pCompass;
    SmoothingQueue<float, 16> pHeadings;
    float aveHeading;
    float lastHeading;
    std::array<float, 20> headingAnalyzer;
    std::list<ActionListener*> listeners;
    int iLastHeading;
    float startHeading;
    float endHeading;
    
    void* pAccelerometer;
    SmoothingQueue<float, 16> pAccelX;
    SmoothingQueue<float, 16> pAccelY;
    SmoothingQueue<float, 16> pAccelZ;
    float aveAccelX;
    float aveAccelY;
    float aveAccelZ;
    std::array<float, SAMPLES_PER_SECOND>yAccelAnalyzer;
    std::array<float, SAMPLES_PER_SECOND>zAccelAnalyzer;
    int iLastAccelY;
    float startAccelY;
    float endAccelY;
    float zAccelAccum;
    
    bool bWantsNewGesture;
    float analysisInterval;
    float intervalDt;
    float timer;
    
    std::string strStatus;
};

#endif /* defined(__RealRogueTest__ActionTracker__) */
