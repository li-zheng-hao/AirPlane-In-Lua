--主游戏层
local mainLayer

local Enemy = require("Enemy")
local Fighter = require("Fighter")
local Bullet = require("Bullet")

--定时器的ID
local schedulerId = nil
local scheduler = cc.Director:getInstance():getScheduler()

local size = cc.Director:getInstance():getWinSize()
local defaults = cc.UserDefault:getInstance()

local touchFighterlistener
local contactListener

local fighter
--暂停菜单
local menu

--分数
local score = 0
--记录0~999分数
local scorePlaceholder = 0

local GamePlayScene = class("GamePlayScene", function()
    local scene = cc.Scene:createWithPhysics()
    --scene:getPhysicsWorld():setDebugDrawMask(cc.PhysicsWorld.DEBUGDRAW_ALL)
    --0,0不受到重力的影响
    scene:getPhysicsWorld():setGravity(cc.p(0, 0))

    return scene
end)

function GamePlayScene.create()
    local scene = GamePlayScene.new()

    return scene
end

function GamePlayScene:ctor()
    cclog("GamePlayScene init")

    self:addChild(self:createInitBGLayer())
    --场景生命周期事件处理
    local function onNodeEvent(event)
        if event == "enter" then
            self:onEnter()
        elseif event == "enterTransitionFinish" then
            self:onEnterTransitionFinish()
        elseif event == "exit" then
            self:onExit()
        elseif event == "exitTransitionStart" then
            self:onExitTransitionStart()
        elseif event == "cleanup" then
            self:cleanup()
        end
    end

    self:registerScriptHandler(onNodeEvent)
end

-- 创建背景层
function GamePlayScene:createInitBGLayer()
    cclog("背景层初始化")
    local bgLayer = cc.Layer:create()
    --添加背景层，以瓦片地图为背景
    local bg = cc.TMXTiledMap:create("map/blue_bg.tmx")
    bgLayer:addChild(bg, 0, GameSceneNodeTag.BatchBackground)

    --放置发光粒子背景
    local ps = cc.ParticleSystemQuad:create("particle/light.plist")
    ps:setPosition(cc.p(size.width / 2, size.height / 2))
    bgLayer:addChild(ps, 0, GameSceneNodeTag.BatchBackground)

    --添加背景精灵1.
    local sprite1 = cc.Sprite:createWithSpriteFrameName("gameplay.bg.sprite-1.png")
    sprite1:setPosition(cc.p(-50, -50))
    bgLayer:addChild(sprite1, 0, GameSceneNodeTag.BatchBackground)

    --背景层有两个精灵，让他们反复执行两个移动的动作
    local ac1 = cc.MoveBy:create(20, cc.p(500, 600))
    local ac2 = ac1:reverse()
    local as1 = cc.Sequence:create(ac1, ac2)
    sprite1:runAction(cc.RepeatForever:create(cc.EaseSineInOut:create(as1)))

    --添加背景精灵2.
    local sprite2 = cc.Sprite:createWithSpriteFrameName("gameplay.bg.sprite-2.png")
    sprite2:setPosition(cc.p(size.width, 0))
    bgLayer:addChild(sprite2, 0, GameSceneNodeTag.BatchBackground)

    local ac3 = cc.MoveBy:create(10, cc.p(-500, 600))
    local ac4 = ac3:reverse()
    local as2 = cc.Sequence:create(ac3, ac4)
    sprite2:runAction(cc.RepeatForever:create(cc.EaseExponentialInOut:create(as2)))

    return bgLayer
end

-- 创建Main层
function GamePlayScene:createLayer()

    mainLayer = cc.Layer:create()

    --添加陨石1.
    local stone1 = Enemy.create(EnemyTypes.Enemy_Stone)
    mainLayer:addChild(stone1, 10, GameSceneNodeTag.Enemy)

    --添加行星.
    local planet = Enemy.create(EnemyTypes.Enemy_Planet)
    mainLayer:addChild(planet, 10, GameSceneNodeTag.Enemy)

    --添加敌机1.
    local enemyFighter1 = Enemy.create(EnemyTypes.Enemy_1)
    mainLayer:addChild(enemyFighter1, 10, GameSceneNodeTag.Enemy)

    --添加敌机2.
    local enemyFighter2 = Enemy.create(EnemyTypes.Enemy_2)
    mainLayer:addChild(enemyFighter2, 10, GameSceneNodeTag.Enemy)

    fighter = Fighter.create("gameplay.fighter.png")
    fighter:setPos(cc.p(size.width / 2, 70))
    mainLayer:addChild(fighter, 10, GameSceneNodeTag.Fighter)


    --子弹射击的定时器
    local function shootBullet(delta)
        --如果主角存在且主角可视
        if nil ~= fighter and fighter:isVisible() then
            --创建子弹，场景层添加子弹
            local bullet = Bullet.create("gameplay.bullet.png")
            mainLayer:addChild(bullet, 0, GameSceneNodeTag.Bullet)
            --调用子弹的射击按钮，将fighter参数传入以便设置子弹的位置
            bullet:shootBulletFromFighter(fighter)
        end
    end

    --物理世界物体发生接触时候的接触事件监测
    local function onContactBegin(contact)
        local spriteA = contact:getShapeA():getBody():getNode()
        local spriteB = contact:getShapeB():getBody():getNode()

        local enemy1 = nil
        ---------------------------- 检测 飞机与敌人的接触 start----------------------------------
        --如果第一个是主角，第二个是敌人
        if spriteA:getTag() == GameSceneNodeTag.Fighter
                and spriteB:getTag() == GameSceneNodeTag.Enemy then
            enemy1 = spriteB
        end
        if spriteA:getTag() == GameSceneNodeTag.Enemy
                and spriteB:getTag() == GameSceneNodeTag.Fighter then
            enemy1 = spriteA
        end
        --如果发生接触，那么进行处理接触
        if nil ~= enemy1 then 
            self:handleFighterCollidingWithEnemy(enemy1)
            return false
        end
        -------------------------- 检测 飞机与敌人的接触 end-----------------------------------

        -------------------------- 检测 炮弹与敌人的接触 start--------------------------------
        --如果第一个是子弹，第二个是敌人
        local enemy2 = nil
        if spriteA:getTag() == GameSceneNodeTag.Bullet
                and spriteB:getTag() == GameSceneNodeTag.Enemy then
            --不可见的炮弹不发生接触
            if spriteA:isVisible() == false then
                return false
            end
            --使得炮弹消失
            spriteA:setVisible(false)
            enemy2 = spriteB
        end
        --如果第一个是敌人，第二个是子弹
        if spriteA:getTag() == GameSceneNodeTag.Enemy
                and spriteB:getTag() == GameSceneNodeTag.Bullet then
            --不可见的炮弹不发生接触
            if spriteB:isVisible() == false then
                return false
            end
            --使得炮弹消失
            spriteB:setVisible(false)
            enemy2 = spriteA
        end
        --发生了接触
        if nil ~= enemy2 then 
            self:handleBulletCollidingWithEnemy(enemy2)
        end
        ------------------------ 检测 炮弹与敌人的接触 end-----------------------------------
        return false
    end

    ------------------------------玩家触摸事件的监听 start----------------------------------
    --接触事件回调函数
    local function touchBegan(touch, event)
        return true
    end

    --接触事件回调函数
    local function touchMoved(touch, event)
        --cclog("touchMoved")
        -- 获取事件所绑定的 node
        local node = event:getCurrentTarget()

        local currentPosX, currentPosY = node:getPosition()
        --坐标的差值获取
        local diff = touch:getDelta()
        -- 移动当前按钮精灵的坐标位置
        node:setPos(cc.p(currentPosX + diff.x, currentPosY + diff.y))
    end

    ------------------------------玩家触摸事件的监听 end----------------------------------




    ------------------------------菜单按钮的回调函数 start----------------------------------

    --返回主页菜单回调函数
    local function menuBackCallback(sender)
        cc.Director:getInstance():popScene()
        if defaults:getBoolForKey(SOUND_KEY) then
            AudioEngine.playEffect(sound_1)
        end
    end

    --继续菜单回调函数
    local function menuResumeCallback(sender)

        if defaults:getBoolForKey(SOUND_KEY) then
            AudioEngine.playEffect(sound_1)
        end

        mainLayer:resume()
        schedulerId = nil
        --继续定时器的调用
        schedulerId = scheduler:scheduleScriptFunc(shootBullet, 0.2, false)

        --将它的所有结点继续
        local pChildren = mainLayer:getChildren()
        for i = 1, #pChildren, 1 do
            local child = pChildren[i]
            child:resume()
        end
        mainLayer:removeChild(menu)
    end

    --暂停菜单回调函数
    local function menuPauseCallback(sender)
        cclog("menuPauseCallback")
        if defaults:getBoolForKey(SOUND_KEY) then
            AudioEngine.playEffect(sound_1)
        end

        --暂停当前层中的node
        mainLayer:pause()
        --停止定时器的调用
        if (schedulerId ~= nil) then
            scheduler:unscheduleScriptEntry(schedulerId)
        end

        --layer子节点暂停
        local pChildren = mainLayer:getChildren()
        for i = 1, #pChildren, 1 do
            local child = pChildren[i]
            child:pause()
        end

        --返回主菜单
        local backNormal = cc.Sprite:createWithSpriteFrameName("button.back.png")
        local backSelected = cc.Sprite:createWithSpriteFrameName("button.back-on.png")
        local backMenuItem = cc.MenuItemSprite:create(backNormal, backSelected)
        --当菜单回调函数时，使用的是带tap的注册
        backMenuItem:registerScriptTapHandler(menuBackCallback)

        --继续游戏菜单
        local resumeNormal = cc.Sprite:createWithSpriteFrameName("button.resume.png")
        local resumeSelected = cc.Sprite:createWithSpriteFrameName("button.resume-on.png")
        local resumeMenuItem = cc.MenuItemSprite:create(resumeNormal, resumeSelected)
        resumeMenuItem:registerScriptTapHandler(menuResumeCallback)

        menu = cc.Menu:create(backMenuItem, resumeMenuItem)
        menu:alignItemsVertically()
        menu:setPosition(cc.p(size.width / 2, size.height / 2))

        mainLayer:addChild(menu, 50, 1000)
    end

    ------------------------------菜单按钮的回调函数 end----------------------------------




    ------------------------------ 事件监听器的注册 start---------------------------------
    -- 创建一个事件监听器 OneByOne 为单点触摸
    touchFighterlistener = cc.EventListenerTouchOneByOne:create()
    -- 设置是否吞没事件，在 onTouchBegan 方法返回 true 时吞没
    touchFighterlistener:setSwallowTouches(true)
    -- EVENT_TOUCH_BEGAN事件回调函数
    touchFighterlistener:registerScriptHandler(touchBegan, cc.Handler.EVENT_TOUCH_BEGAN)
    -- EVENT_TOUCH_MOVED事件回调函数
    touchFighterlistener:registerScriptHandler(touchMoved, cc.Handler.EVENT_TOUCH_MOVED)

    -- 创建一个接触事件监听器
    contactListener = cc.EventListenerPhysicsContact:create()
    contactListener:registerScriptHandler(onContactBegin, cc.Handler.EVENT_PHYSICS_CONTACT_BEGIN)

    local eventDispatcher = cc.Director:getInstance():getEventDispatcher()
    -- 添加监听器
    eventDispatcher:addEventListenerWithSceneGraphPriority(touchFighterlistener, fighter)
    eventDispatcher:addEventListenerWithSceneGraphPriority(contactListener, mainLayer)


    ------------------------------ 事件监听器的注册 end---------------------------------




    --初始化暂停按钮.
    local pauseSprite = cc.Sprite:createWithSpriteFrameName("button.pause.png")
    local pauseMenuItem = cc.MenuItemSprite:create(pauseSprite, pauseSprite)
    pauseMenuItem:registerScriptTapHandler(menuPauseCallback)

    local pauseMenu = cc.Menu:create(pauseMenuItem)
    pauseMenu:setPosition(cc.p(30, size.height - 28))

    mainLayer:addChild(pauseMenu, 300, 999)

    --每0.2秒调用shootBullet函数发射1发炮弹
    schedulerId = scheduler:scheduleScriptFunc(shootBullet, 0.2, false)

    --分数
    score = 0
    --记录0~999分数
    scorePlaceholder = 0

    --在状态栏中设置玩家的生命值
    self:updateStatusBarFighter()
    --在状态栏中显示得分
    self:updateStatusBarScore()

    return mainLayer
end

function GamePlayScene:onEnter()
    cclog("GamePlayScene onEnter")

    self:addChild(self:createLayer())
end

--处理玩家与敌人的接触检测
function GamePlayScene:handleFighterCollidingWithEnemy(enemy)

    --移除之前的爆炸结点    
    self:removeChildByTag(GameSceneNodeTag.ExplosionParticleSystem)

    --添加爆炸的粒子特效结点
    local explosion = cc.ParticleSystemQuad:create("particle/explosion.plist")
    explosion:setPosition(fighter:getPosition())
    self:addChild(explosion, 2, GameSceneNodeTag.ExplosionParticleSystem)
    if defaults:getBoolForKey(SOUND_KEY) then
        AudioEngine.playEffect(sound_2)
    end
    --设置敌人消失
    enemy:setVisible(false)
    --消失之后又要创建新的敌人
    enemy:spawn()

    --设置玩家消失
    fighter.hitPoints = fighter.hitPoints - 1
    --更新生命值
    self:updateStatusBarFighter()
    --游戏结束
    if fighter.hitPoints <= 0 then
        cclog("GameOver")
        local GameOverScene = require("GameOverScene")
        local scene = GameOverScene.create(score)
        local tsc = cc.TransitionFade:create(1.0, scene)
        cc.Director:getInstance():pushScene(tsc)
    else
        fighter:setPosition(cc.p(size.width / 2, 70))
        local ac1 = cc.Show:create()
        local ac2 = cc.FadeIn:create(1.0)
        local seq = cc.Sequence:create(ac1, ac2)
        fighter:runAction(seq)
    end
end

--子弹与敌人的接触检测
function GamePlayScene:handleBulletCollidingWithEnemy(enemy)

    enemy.hitPoints = enemy.hitPoints - 1

    if enemy.hitPoints <= 0 then
        --爆炸和音效
        local node = mainLayer:getChildByTag(GameSceneNodeTag.ExplosionParticleSystem)
        if nil ~= node then
            self:removeChild(node)
        end
        local explosion = cc.ParticleSystemQuad:create("particle/explosion.plist")
        explosion:setPosition(enemy:getPosition())
        self:addChild(explosion, 2, GameSceneNodeTag.ExplosionParticleSystem)
        if defaults:getBoolForKey(SOUND_KEY) then
            AudioEngine.playEffect(sound_2)
        end

        if enemy.enemyType == EnemyTypes.Enemy_Stone then
            score = EnemyScores.Enemy_Stone + score
            scorePlaceholder = EnemyScores.Enemy_Stone + scorePlaceholder
        elseif enemy.enemyType == EnemyTypes.Enemy_1 then
            score = EnemyScores.Enemy_1 + score
            scorePlaceholder = EnemyScores.Enemy_1 + scorePlaceholder
        elseif enemy.enemyType == EnemyTypes.Enemy_2 then
            score = EnemyScores.Enemy_2 + score
            scorePlaceholder = EnemyScores.Enemy_2 + scorePlaceholder
        else
            score = EnemyScores.Enemy_Planet + score
            scorePlaceholder = EnemyScores.Enemy_Planet + scorePlaceholder
        end

        --每次获得1000分数，生命值 加一，scorePlaceholder恢复0.
        if scorePlaceholder >= 1000 then
            fighter.hitPoints = fighter.hitPoints + 1
            self:updateStatusBarFighter()
            scorePlaceholder = scorePlaceholder - 1000
        end

        self:updateStatusBarScore()
        --设置敌人消失
        enemy:setVisible(false)
        enemy:spawn()
    end
end

--在状态栏中显示得分
function GamePlayScene:updateStatusBarScore()

    mainLayer:removeChildByTag(GameSceneNodeTag.StatusBarScore)

    if score < 0 then
        score = 0
    end

    local strScore = string.format("%d", score)
    local lblScore = cc.Label:createWithTTF(strScore, "fonts/hanyi.ttf", 18)

    lblScore:setPosition(cc.p(size.width / 2, size.height - 28))
    mainLayer:addChild(lblScore, 20, GameSceneNodeTag.StatusBarScore)
end

--在状态栏中设置玩家的生命值
function GamePlayScene:updateStatusBarFighter()

    --先移除上次的精灵
    mainLayer:removeChildByTag(GameSceneNodeTag.StatusBarFighterNode)

    local fg = cc.Sprite:createWithSpriteFrameName("gameplay.life.png")
    fg:setPosition(cc.p(size.width - 60, size.height - 28))
    mainLayer:addChild(fg, 20, GameSceneNodeTag.StatusBarFighterNode)

    --添加生命值 x 5
    mainLayer:removeChildByTag(GameSceneNodeTag.StatusBarLifeNode)

    if fighter.hitPoints < 0 then
        fighter.hitPoints = 0
    end
    local life = string.format("x %d", fighter.hitPoints)
    local lblLife = cc.Label:createWithTTF(life, "fonts/hanyi.ttf", 18)
    local fgX, fgY = fg:getPosition()
    lblLife:setPosition(cc.p(fgX + 30, fgY))
    mainLayer:addChild(lblLife, 20, GameSceneNodeTag.StatusBarLifeNode)
end


function GamePlayScene:onEnterTransitionFinish()
    cclog("GamePlayScene onEnterTransitionFinish")
    if defaults:getBoolForKey(MUSIC_KEY) then
        AudioEngine.playMusic(bg_music_2, true)
    end
end

function GamePlayScene:onExit()

    cclog("GamePlayScene onExit")
    --停止游戏调度
    if (schedulerId ~= nil) then
        scheduler:unscheduleScriptEntry(schedulerId)
    end
    --注销事件监听器.
    local eventDispatcher = cc.Director:getInstance():getEventDispatcher()
    if nil ~= touchFighterlistener then
        eventDispatcher:removeEventListener(touchFighterlistener)
    end
    if nil ~= contactListener then
        eventDispatcher:removeEventListener(contactListener)
    end

    --删除layer节点以及其子节点
    mainLayer:removeAllChildren()
    mainLayer:removeFromParent()
    mainLayer = nil
end

function GamePlayScene:onExitTransitionStart()
    cclog("GamePlayScene onExitTransitionStart")
end

function GamePlayScene:cleanup()
    cclog("GamePlayScene cleanup")
end

return GamePlayScene
