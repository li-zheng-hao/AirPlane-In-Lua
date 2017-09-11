--主角的飞机类
local size = cc.Director:getInstance():getWinSize()
local defaults = cc.UserDefault:getInstance()

local Fighter = class("Fighter",function()
    return cc.Sprite:create()
end)

function Fighter.create(spriteFrameName)
    local fighter = Fighter.new(spriteFrameName)
    return fighter
end

function Fighter:ctor(spriteFrameName)
    self.hitPoints = Fighter_hitPoints          --当前的生命值
    self:setSpriteFrame(spriteFrameName)
    --飞机屁股后面的火
    local ps = cc.ParticleSystemQuad:create("particle/fire.plist")
    --在飞机下面.
    ps:setPosition(cc.p(self:getContentSize().width / 2, 0))

    ps:setScale(0.5)
    self:addChild(ps)

    local verts = {
        cc.p(-43.5,15.5),
        cc.p(-23.5,33),
        cc.p(28.5,34),
        cc.p(48,17.5),
        cc.p(0,-39.5)}
    --创建一个多边形的物体
    local body = cc.PhysicsBody:createPolygon(verts)
    body:setCategoryBitmask(0x01)        --0001
    body:setCollisionBitmask(0x02)       --0010
    body:setContactTestBitmask(0x01)     --0001
    self:setPhysicsBody(body)
    

end

--重写setPosition
--用来判断飞机是否飞出了屏幕
function Fighter:setPos(newPosition)

    local halfWidth = self:getContentSize().width /2
    local halfHeight = self:getContentSize().height /2
    local pos_x = newPosition.x
    local  pos_y = newPosition.y

    if  pos_x < halfWidth then
        pos_x = halfWidth
    elseif  pos_x > (size.width - halfWidth) then
        pos_x = size.width - halfWidth
    end

    if  pos_y < halfHeight  then
        pos_y = halfHeight
    elseif pos_y > (size.height - halfHeight) then
        pos_y = size.height - halfHeight
    end

    self:setPosition(cc.p(pos_x,pos_y))
    self:setAnchorPoint(cc.p(0.5, 0.5))

end

return Fighter

