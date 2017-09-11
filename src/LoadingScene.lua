--第一个游戏界面，用来进行游戏资源的异步加载
require"SystemConst"

local size=cc.Director:getInstance():getWinSize()
local frameCache=cc.SpriteFrameCache:getInstance()
local textureCache=cc.Director:getInstance():getTextureCache()

local LoadingScene=class("LoadingScene",function()
	return cc.Scene:create()
end)

function LoadingScene.create()
	local scene=LoadingScene.new()
	scene:addChild(scene:createLayer())
	return scene
end

function LoadingScene:ctor()
	--场景生命周期事件处理
	local function onNodeEvent(event)
		if event=="enter" then
			self:onEnter()
		elseif event=="enterTransitionFinish" then
			self:onEnterTransitionFinish()
		elseif event=="exit" then
			self:onExit()
		elseif event=="exitTransitionStart" then
			self:onExitTransitionStart()
		elseif event=="cleanup" then
			self:cleanup()
		end
	end
	self:registerScriptHandler(onNodeEvent)
end

--创建层
function LoadingScene:createLayer()
	cclog("LoadingScene init")
	local layer=cc.Layer:create()
	

	frameCache:addSpriteFrames(loading_texture_plist)
	local bg=cc.TMXTiledMap:create("map/red_bg.tmx")
	layer:addChild(bg)

	local logo=cc.Sprite:createWithSpriteFrameName("logo.png")
	layer:addChild(logo)
	logo:setPosition(cc.p(size.width/2,size.height/2))

	local sprite=cc.Sprite:createWithSpriteFrameName("loding4.png")
	layer:addChild(sprite)
	local logoX,logoY=logo:getPosition()
	sprite:setPosition(cc.p(logoX,logoY-130))

	----------------动画开始-------------------------------
	local animation=cc.Animation:create()
	for i=1,4 do
		local frameName=string.format("loding%d.png",i)
		cclog("frameName=%s",frameName)
		local spriteFrame=frameCache:getSpriteFrameByName(frameName)
		animation:addSpriteFrame(spriteFrame)
	end

	animation:setDelayPerUnit(0.5)
	animation:setRestoreOriginalFrame(true)

	local action=cc.Animate:create(animation)
	sprite:runAction(cc.RepeatForever:create(action))
	----------------动画结束-----------------------------


	----------------资源加载-----------------------------
	local function loadingTextureCallBack( texture )
		-- body
		frameCache:addSpriteFrames(texture_plist)
		cclog("loading texture ok")
		--初始化音乐
		AudioEngine.preloadMusic(bg_music_1)
		AudioEngine.preloadMusic(bg_music_2)
		--初始化音效
		AudioEngine.preloadEffect(sound_1)
		AudioEngine.preloadEffect(sound_2)
		--资源加载完成之后就进入游戏菜单界面
		local HomeScene=require("HomeScene")
		local scene=HomeScene:create()

		cc.Director:getInstance():pushScene(scene)
	end
	--纹理缓存异步加载纹理图片，加载完成之后调用完成函数
	textureCache:addImageAsync(texture_res,loadingTextureCallBack)
	----------------资源加载结束------------------------

	return layer
end
--以下为调试使用函数
function LoadingScene:onEnter()
	cclog("LoadingScene onEnter")
end

function LoadingScene:onEnterTransitionFinish( )
	-- body
	cclog("LoadingScene onEnterTransitionFinish")
end

function LoadingScene:onExit(  )
	-- body
	cclog("LoadingScene onExit")
end

function LoadingScene:onExitTransitionStart(  )
	-- body
	cclog("LoadingScene cleanup")
end

return LoadingScene



