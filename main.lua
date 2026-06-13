local vector = require("libraries/vector")

function love.load()
    shaders = require("shaders")

    wf = require("libraries/windfield")
    world = wf.newWorld(0, 0)

    camera = require("libraries/camera")
    cam = camera()

    anim8 = require("libraries/anim8")
    love.graphics.setDefaultFilter("nearest", "nearest") -- pixel art style

    sti = require("libraries/sti")
    gameMap = sti("maps/testMap.lua")

    player = {}
    player.collider = world:newBSGRectangleCollider(400, 250, 50, 100, 10)
    player.collider:setFixedRotation(true)
    player.x = 0
    player.y = 0
    player.speed = 300
    player.sprite = love.graphics.newImage("sprites/parrot.png")
    player.spriteSheet = love.graphics.newImage("sprites/player-sheet.png")
    player.grid = anim8.newGrid(12, 18, player.spriteSheet:getWidth(), player.spriteSheet:getHeight())
    
    player.animations = {}
    player.animations.down = anim8.newAnimation(player.grid("1-4", 1), 0.2)
    player.animations.left = anim8.newAnimation(player.grid("1-4", 2), 0.2)
    player.animations.right = anim8.newAnimation(player.grid("1-4", 3), 0.2)
    player.animations.up = anim8.newAnimation(player.grid("1-4", 4), 0.2)
    
    player.anim = player.animations.left

    walls = {}
    if gameMap.layers["Walls"] then
        for _, obj in pairs(gameMap.layers["Walls"].objects) do
            local wall = world:newRectangleCollider(obj.x, obj.y, obj.width, obj.height)
            wall:setType("static")
            table.insert(walls, wall)
        end
    end

    sounds = {
        blip = love.audio.newSource("sounds/blip.wav", "static"),
        music = love.audio.newSource("sounds/music.mp3", "stream"),
    }
    sounds.music:setLooping(true)
    sounds.music:play()
end

local dir = vector.new(0, 0)
function love.update(dt)
    dir.x = 0; dir.y = 0
    local extraSpeed = 0

    if love.window.isMinimized() then return end

    if love.keyboard.isDown("w") or love.keyboard.isDown("up") then dir.y = dir.y - 1; player.anim = player.animations.up end
    if love.keyboard.isDown("s") or love.keyboard.isDown("down") then dir.y = dir.y + 1; player.anim = player.animations.down end

    if love.keyboard.isDown("a") or love.keyboard.isDown("left") then dir.x = dir.x - 1; player.anim = player.animations.left end
    if love.keyboard.isDown("d") or love.keyboard.isDown("right") then dir.x = dir.x + 1; player.anim = player.animations.right end

    if love.keyboard.isDown("lshift") then extraSpeed = 200 end

    if dir:len() > 0 then
        player.anim:update(dt)
        dir = dir:normalized()
    else
        if player.anim.position ~= 2 then
            player.anim:gotoFrame(2)
        end
    end
    
    player.collider:setLinearVelocity(dir.x * (player.speed + extraSpeed), dir.y * (player.speed + extraSpeed))
    world:update(dt)
    player.x, player.y = player.collider:getPosition()

    cam:lookAt(player.x, player.y)
    local w = love.graphics.getWidth()
    local h = love.graphics.getHeight()

    if cam.x < w/2 then cam.x = w/2 end
    if cam.y < h/2 then cam.y = h/2 end

    local mapW = gameMap.width * gameMap.tilewidth
    local mapH = gameMap.height * gameMap.tileheight

    if cam.x > (mapW - w/2) then cam.x = mapW - w/2 end
    if cam.y > (mapH - h/2) then cam.y = mapH - h/2 end

    shaders.light:send("center", { cam:cameraCoords(player.x, player.y) })
end

function love.draw()
    cam:attach()
        love.graphics.setShader(shaders.light)
        shaders.light:send("radius", 100)

        gameMap:drawLayer(gameMap.layers["Ground"])
        gameMap:drawLayer(gameMap.layers["Trees"])

        player.anim:draw(player.spriteSheet, player.x, player.y, nil, 6, nil, 6, 9)
        love.graphics.setShader()
        --world:draw()
    cam:detach()
    love.graphics.print("FPS: " .. love.timer.getFPS(), 10, 10, nil, 1.5, 1.5)
end

function love.keypressed(key)
    if key == "space" then
        sounds.blip:play()
    elseif key == "f" then
        love.window.setFullscreen(not love.window.getFullscreen())
    end
end