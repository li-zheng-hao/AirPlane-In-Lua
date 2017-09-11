
local size = cc.Director:getInstance():getWinSize()
local defaults = cc.UserDefault:getInstance()

--可以直接去看一下class的源码，第一个参数作为类名，第二个参数如果是function,那么就将function作为这个table的__create元方法
local Enemy = class("Enemy",function()
    return cc.Sprite:create()
end)

function Enemy.create(enemyType)
    local sprite = Enemy.new(enemyType)--new方法会自动调用构造函数 ctor
    return sprite
end

function Enemy:ctor(enemyType)--构造函数

    --精灵帧
    local enemyFramName = EnemyName.Enemy_Stone
    --得分值
    local hitPointsTemp = 0
    --速度
    local velocityTemp = nil

    --判断敌人的类型，不同的类型，所对应的属性也不一样
    if enemyType  == EnemyTypes.Enemy_Stone then
        enemyFramName = EnemyName.Enemy_Stone
        hitPointsTemp = Enemy_initialHitPoints.Enemy_Stone
        velocityTemp = Sprite_Velocity.Enemy_Stone
    elseif  enemyType  == EnemyTypes.Enemy_1 then
        enemyFramName = EnemyName.Enemy_1
        hitPointsTemp = Enemy_initialHitPoints.Enemy_1
        velocityTemp = Sprite_Velocity.Enemy_1
    elseif  enemyType  == EnemyTypes.Enemy_2 then
        enemyFramName = EnemyName.Enemy_2
        hitPointsTemp = Enemy_initialHitPoints.Enemy_2
        velocityTemp = Sprite_Velocity.Enemy_2
    elseif  enemyType  == EnemyTypes.Enemy_Planet then
        enemyFramName = EnemyName.Enemy_Planet
        hitPointsTemp = Enemy_initialHitPoints.Enemy_Planet
        velocityTemp = Sprite_Velocity.Enemy_Planet
    end

    self:setSpriteFrame(enemyFramName)
    self:setVisible(false)

    --设置敌人精灵的基本属性
    self.hitPoints = 0                         --当前的生命值
    self.initialHitPoints = hitPointsTemp      --初始的生命值
    self.velocity = velocityTemp               --速度
    self.enemyType = enemyType                 --敌人类型

    --创建一个物理引擎物体
    local body = cc.PhysicsBody:create()

    if enemyType == EnemyTypes.Enemy_Stone
        or enemyType == EnemyTypes.Enemy_Planet then
        --石头和行星都是圆形的
        body:addShape(cc.PhysicsShapeCircle:create(self:getContentSize().width / 2 - 5))
    elseif enemyType == EnemyTypes.Enemy_1 then
        --多边形要标出它们的突出的顶点
        local verts ={
            cc.p(-2.5,-45.75),
            cc.p(-29.5,-27.25),
            cc.p(-53, -0.25),
            cc.p(-34,43.25),
            cc.p(28, 44.25),
            cc.p(55,-2.25)}
        body:addShape(cc.PhysicsShapePolygon:create(verts))
    elseif enemyType ==EnemyTypes.Enemy_2  then
        local verts ={
            cc.p(1.25, 32.25),
            cc.p(36.75, -4.75),
            cc.p( 2.75, -31.75),
            cc.p(-35.75,-3.25)}
        body:addShape(cc.PhysicsShapePolygon:create(verts))
    end

    self:setPhysicsBody(body)             --将自身与这个物理引擎物体绑定
    body:setCategoryBitmask(0x01)         --0001
    body:setCollisionBitmask(0x02)        --0010
    body:setContactTestBitmask(0x01)      --0001

    self:spawn()--开始添加敌人

    --定时器调度
    local function update(delta)

        --设置陨石和行星旋转.
        if enemyType  == EnemyTypes.Enemy_Stone then
            self:setRotation(self:getRotation() - 0.5)
        elseif  enemyType  == EnemyTypes.Enemy_Planet then
            self:setRotation(self:getRotation() + 1)
        end

        --   local vx,vy = self.velocity
        local x,y = self:getPosition()

        self:setPosition(cc.p(x + self.velocity.x *delta,  y + self.velocity.y *delta))

        x,y = self:getPosition()
        --如果出去了屏幕，那么调用spwan函数添加敌人，也就是将自己的所有属性重置
        if  y + self:getContentSize().height /2 < 0  then
            self:spawn()
        end
    end
    --执行定时器
    self:scheduleUpdateWithPriorityLua(update, 0)
    --判断是否停止
    local function onNodeEvent(tag)
        if tag == "exit" then
            --停止游戏调度
            self:unscheduleUpdate()
        end
    end
    self:registerScriptHandler(onNodeEvent)

end


function Enemy:spawn()
    local yPos = size.height + self:getContentSize().height /2
    local rand = math.random()
    --随机位置
    local xPos = math.random() * (size.width - self:getContentSize().width) + self:getContentSize().width / 2
    self:setPosition(cc.p(xPos, yPos))
    self:setAnchorPoint(cc.p(0.5, 0.5))

    self.hitPoints =  self.initialHitPoints
    self:setVisible(true)

end

return Enemy

