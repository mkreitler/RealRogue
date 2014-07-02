#include "HelloWorldScene.h"
#include "ActionTracker.h"

USING_NS_CC;

#define SPRITE_WIDTH        (100)

Scene* HelloWorld::createScene(ActionTracker* pTracker)
{
    // 'scene' is an autorelease object
    auto scene = Scene::create();
    
    // 'layer' is an autorelease object
    auto layer = HelloWorld::create();

    // add layer as a child to scene
    scene->addChild(layer);

    layer->pTracker = pTracker;
    pTracker->addListener(layer);
    
    // return the scene
    return scene;
}

// on "init" you need to initialize your instance
bool HelloWorld::init()
{
    //////////////////////////////
    // 1. super init first
    if ( !Layer::init() )
    {
        return false;
    }
    
    Size visibleSize = Director::getInstance()->getVisibleSize();
    Vec2 origin = Director::getInstance()->getVisibleOrigin();

    /////////////////////////////
    // 2. add a menu item with "X" image, which is clicked to quit the program
    //    you may modify it.

    // add a "close" icon to exit the progress. it's an autorelease object
    auto closeItem = MenuItemImage::create(
                                           "CloseNormal.png",
                                           "CloseSelected.png",
                                           CC_CALLBACK_1(HelloWorld::menuCloseCallback, this));
    
	closeItem->setPosition(Vec2(origin.x + visibleSize.width - closeItem->getContentSize().width/2 ,
                                origin.y + closeItem->getContentSize().height/2));

    // create menu, it's an autorelease object
    auto menu = Menu::create(closeItem, NULL);
    menu->setPosition(Vec2::ZERO);
    this->addChild(menu, 1);

    /////////////////////////////
    // 3. add your codes below...

    // add a label shows "Hello World"
    // create and initialize a label
    
    pLabel = Label::createWithSystemFont("Hello World", "Arial", 24);
    
    // position the label on the center of the screen
    pLabel->setPosition(Vec2(origin.x + visibleSize.width/2,
                            origin.y + visibleSize.height - pLabel->getContentSize().height));

    // add the label as a child to this layer
    this->addChild(pLabel, 1);

    // add "HelloWorld" splash screen"
//    auto sprite = Sprite::create("HelloWorld.png");
//
//    // position the sprite on the center of the screen
//    sprite->setPosition(Vec2(visibleSize.width/2 + origin.x, visibleSize.height/2 + origin.y));
//
//    // add the sprite as a child to this layer
//    this->addChild(sprite, 0);
    
    // --- CUSTOM CODE ---
    scheduleUpdate();
    
    initSprites();
    
    return true;
}

void HelloWorld::initSprites() {
    for (int i=0; i<sprites.size(); ++i) {
        sprites[i] = NULL;
    }
}

int HelloWorld::countSprites() {
    int nSprites = 0;
    
    for (int i=0; i<sprites.size(); ++i) {
        if (sprites[i] == NULL) {
            break;
        }
        
        ++nSprites;
    }
    
    return nSprites;
}

void HelloWorld::freeGestureSprites() {
    // Flush the array.
    for (int i=0; i<sprites.size(); ++i) {
        removeChild(sprites[i]);
        sprites[i] = NULL;
    }
}

void HelloWorld::onGestureComplete(GestureType type) {
    int nSprites = countSprites();
    
    if (nSprites == sprites.size()) {
        freeGestureSprites();
    }

    const char* spriteFile = NULL;
    
    switch(type) {
        case GT_CHOP:
            spriteFile = "GestureChop.png";
            break;
            
        case GT_CUT:
            spriteFile = "GestureCut.png";
            break;
            
        case GT_SLASH:
            spriteFile = "GestureSlash.png";
            break;
            
        default:
            break;
    }
    
    if (spriteFile) {
        Size visibleSize = Director::getInstance()->getVisibleSize();
        Vec2 origin = Director::getInstance()->getVisibleOrigin();
        int nSprites = countSprites();
        
        auto sprite = Sprite::create(spriteFile);
        
        if (sprite) {
            // position the sprite on the center of the screen
            sprite->setPosition(Vec2(origin.x + (nSprites + 0.5f) * SPRITE_WIDTH , visibleSize.height/2 + origin.y));
            
            // add the sprite as a child to this layer
            this->addChild(sprite, 0);
            sprites[nSprites] = sprite;
        }
    }
}

void HelloWorld::update(float delta) {
    if (pLabel && pTracker) {
        pTracker->update();
        pTracker->analyze(delta);
        pLabel->setString(pTracker->getStatus());
    }
}

void HelloWorld::menuCloseCallback(Ref* pSender)
{
#if (CC_TARGET_PLATFORM == CC_PLATFORM_WP8) || (CC_TARGET_PLATFORM == CC_PLATFORM_WINRT)
	MessageBox("You pressed the close button. Windows Store Apps do not implement a close button.","Alert");
    return;
#endif

    pTracker = NULL;
    
    unscheduleUpdate();
    Director::getInstance()->end();
    freeGestureSprites();
    
#if (CC_TARGET_PLATFORM == CC_PLATFORM_IOS)
    exit(0);
#endif
}
