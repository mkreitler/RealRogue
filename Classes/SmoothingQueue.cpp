//
//  SmoothingQueue.cpp
//  RealRogueTest
//
//  Created by Mark Kreitler on 6/15/14.
//
//

#include "SmoothingQueue.h"

template <class T, size_t N>
SmoothingQueue<T, N>::SmoothingQueue()
: bFirstUpdate(false)
, curIndex(0)
, branchCutValue((T)0)
, aveValue((T)0) {
    // No further initialization required.
}

template <class T, size_t N>
void SmoothingQueue<T, N>::append(T newValue) {
    int nValues = values.size();
    
    if (bFirstUpdate) {
        bFirstUpdate = false;
        
        for (int i=0; i<nValues; ++i) {
            values[nValues] = newValue;
        }
        
        curIndex = 1;
        aveValue = newValue;
    }
    else {
        values[curIndex] = newValue;
        curIndex = (curIndex + 1) % nValues;
        
        T total = (T)0;
        
        if (branchCutValue) {
            T maxCutDiff = branchCutValue / (T)2;
            
            T lastValue = values[0];
            total += lastValue;
            
            for (int i=1; i<nValues; ++i) {
                T diff = values[i] - lastValue;
                
                if (diff > maxCutDiff) {
                    lastValue = values[i] - branchCutValue;
                }
                else if (diff < -maxCutDiff) {
                    lastValue = values[i] + branchCutValue;
                }
                else {
                    lastValue = values[i];
                }
                
                total += lastValue;
            }
        }
        else {
            for (int i=0; i<nValues; ++i) {
                total += values[i];
            }
        }
        
        aveValue = (T)((double)total / (double)nValues);
    }
}

template <class T, size_t N>
void SmoothingQueue<T, N>::setBranchCutValue(T value) {
    branchCutValue = value;
}

template <class T, size_t N>
T SmoothingQueue<T, N>::getSmoothedValue() {
    return aveValue;
}
