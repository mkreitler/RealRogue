//
//  SmoothingQueue.h
//  RealRogueTest
//
//  Created by Mark Kreitler on 6/15/14.
//
//

#ifndef __RealRogueTest__SmoothingQueue__
#define __RealRogueTest__SmoothingQueue__

#include <iostream>

template <class T, size_t N>
class SmoothingQueue {
public:
    SmoothingQueue();
    virtual ~SmoothingQueue() {}
    
    void append(T newValue);
    T getSmoothedValue();
    void setBranchCutValue(T value);
    
    size_t size() { return values.size(); }
    
private:
    bool bFirstUpdate;
    int curIndex;
    T aveValue;
    T branchCutValue;
    std::array<T, N> values;
};

#endif /* defined(__RealRogueTest__SmoothingQueue__) */
