#ifndef __HELLOWORLD_SCENE_H__
#define __HELLOWORLD_SCENE_H__

#include "cocos2d.h"
#include <array>
#include "ActionTracker.h"

class HelloWorld : public cocos2d::Layer, public ActionListener
{
public:
    // there's no 'id' in cpp, so we recommend returning the class instance pointer
    static cocos2d::Scene* createScene(ActionTracker* pTracker);

    // Here's a difference. Method 'init' in cocos2d-x returns bool, instead of returning 'id' in cocos2d-iphone
    virtual bool init();  
    
    // a selector callback
    void menuCloseCallback(cocos2d::Ref* pSender);
    
    // implement the "static create()" method manually
    CREATE_FUNC(HelloWorld);
    
    void update(float delta);
    
    virtual void onGestureComplete(GestureType type);
    
private:
    void initSprites();
    int countSprites();
    void freeGestureSprites();
    
    cocos2d::Label* pLabel;
    std::array<cocos2d::Sprite*, 5>sprites;
    ActionTracker* pTracker;
};

#endif // __HELLOWORLD_SCENE_H__
