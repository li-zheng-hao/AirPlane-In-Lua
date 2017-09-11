
require "cocos.init"

--设计分辨率大小
local designResolutionSize=cc.size(320,568)

--两种资源大小
local smallResolutionSize=cc.size(640,1136)
local largeResolutionSize=cc.size(750,1134)

--cclog
cclog=function(...)
  print(string.format(...))
end

local function main()

    --垃圾回收机制
    --原理：lua采用的是标记-清除机制，在标记阶段将程序中所有有引用到的变量进行标记，在清除阶段将没有被
    --标记的变量进行清除

    --setpause参数用来设置两次启动的等待时间，为百分比制
    --setstepmul参数为步长，为百分比制，相对于内存分配的速度
    collectgarbage("collect")
    collectgarbage("setpause",100)
    collectgarbage("setstepmul",5000)

    local director=cc.Director:getInstance()
    local glview=director:getOpenGLView()
    local sharedFileUtils=cc.FileUtils:getInstance()
    --添加文件搜索路径
    cc.FileUtils:getInstance():addSearchPath("src")
    cc.FileUtils:getInstance():addSearchPath("res")


    local searchPaths=sharedFileUtils:getSearchPaths()
    local resPrefix="res/"

    --屏幕大小

    local framesize=glview:getFrameSize()

    --如果屏幕分辨率高度大于small尺寸的资源分辨率高度，选择large资源
    if framesize.height>smallResolutionSize.height then
      director:setContentScaleFactor(math.min(largeResolutionSize.height/designResolutionSize.height
        ,largeResolutionSize.width/designResolutionSize.width))
        --table.insert(table, pos, value)
        --table.insert()函数在table的数组部分指定位置(pos)插入值为value的一个元素. pos参数可选, 默认为数组部分末尾.
        table.insert(searchPaths,1,resPrefix.."large")
    else--如果分辨率小于small尺寸的资源分辨率高度，选择small资源
      director:setContentScaleFactor(math.min(smallResolutionSize.height/designResolutionSize.height
        ,smallResolutionSize.width/designResolutionSize.width))
        table.insert(searchPaths,1,resPrefix.."small")
    end

    --设置资源搜索路径
    sharedFileUtils:setSearchPaths(searchPaths)

    --设计分辨率策略
    glview:setDesignResolutionSize(designResolutionSize.width,designResolutionSize.height,cc.ResolutionPolicy.FIXED_WIDTH)

    --创建场景
    local scene=require("LoadingScene")
    local loadingScene=scene.create()

    --如果有运行的场景，那么用repalce，如果没有就用run
    if director:getRunningScene() then
      director:replaceScene(loadingScene)
    else
      director:runWithScene(loadingScene)
    end

end
--用来debug
local status, msg = xpcall(main, __G__TRACKBACK__)
if not status then
    print(msg)
end
