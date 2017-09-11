

local size = cc.Director:getInstance():getWinSize()
local defaults = cc.UserDefault:getInstance()

local Bullet = class("Bullet",function()
    return cc.Sprite:create()
end)

function Bullet.create(spriteFrameName)
    local sprite = Bullet.new(spriteFrameName)
    return sprite
end

function Bullet:ctor(spriteFrameName)

    self:setSpriteFrame(spriteFrameName)
    self:setVisible(false)
    self.velocity = Sprite_Velocity.Bullet                           --速度

    local body = cc.PhysicsBody:createBox(self:getContentSize())
    body:setCategoryBitmask(0x01)           --0001
    body:setCollisionBitmask(0x02)          --0010
    body:setContactTestBitmask(0x01)        --0001
    self:setPhysicsBody(body)

    local function onNodeEvent(tag)
        if tag == "exit" then
            --停止游戏调度
            self:unscheduleUpdate()
        end
    end
    self:registerScriptHandler(onNodeEvent)--没有tap的与layer配合使用

end

--  发射子弹
function Bullet:shootBulletFromFighter(fighter)

    local  fighterPosX,fighterPosY = fighter:getPosition()

    self:setPosition(cc.p(fighterPosX,  fighterPosY + fighter:getContentSize().height/2))
    self:setVisible(true)

    --子弹的位置刷新,如果超出了屏幕外，就停止刷新
    local function update(delta)
    
        local x,y = self:getPosition()
        self:setPosition(cc.p(x + self.velocity.x *delta,  y + self.velocity.y *delta))
        x,y = self:getPosition()

        if  y > size.height then
            self:setVisible(false)
            self:unscheduleUpdate()
            --self:removeFromParent()
        end

    end
    self:scheduleUpdateWithPriorityLua(update, 0)--优先级为0,数字越小越高

end

return Bullet

