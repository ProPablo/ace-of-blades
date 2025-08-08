-- Run this to hot reload
-- nodemon --exec "love ." --ext lua --ignore node_modules
game = {}
menu = {}

isServer = false

-- GAME STATE
hasRipped = false

-- FORCE VALUES
val = 0 -- establish a variable for later use
cursorX, cursorY = 0
startDragX = 0
startDragY = 0
endDragX = 0
endDragY = 0

valSpeed = 500
forceMod = 10000

isDragging = false
hasRipped = false

function love.load()
    if arg[#arg] == "-debug" then
        require("mobdebug").start()
    end
    require("util")
    require("blade")
    require("blocks")
    Gamestate = require("libs/hump/gamestate")
    vector = require "libs.hump.vector"
    screen = {
        width = love.graphics.getWidth(),
        height = love.graphics.getHeight()
    }

    love.physics.setMeter(64)
    world = love.physics.newWorld(0, 1, true)

    Gamestate.registerEvents()
    Gamestate.switch(game)
end

function game:enter()
    setupBlocks()
    setupBlade()
end

function game:draw()
    drawDebug()
    drawBlocks()
    drawBlade()
    drawRip()
end

function game:update(dt)
    world:update(dt)
    cursorX, cursorY = love.mouse.getPosition()
    if (hasRipped) then
        return
    end

    if (love.mouse.isDown(1) and isDragging == false) then
        beyblade.body:setPosition(cursorX, cursorY)
        startDragX = cursorX
        startDragY = cursorY
        isDragging = true
    end

    -- RELEASE
    if (not love.mouse.isDown(1) and isDragging == true) then
        endDragX = cursorX
        endDragY = cursorY
        local dx = endDragX - startDragX
        local dy = endDragY - startDragY
        -- Distance between click down and release
        local length = dx + dy
        if length > 0 then -- Ignoring same spot start & end
            print(length)
            -- Normalize and apply force in the opposite direction
            -- dx / length is a direction vector 
            local fx = -dx * forceMod
            local fy = -dy * forceMod
            beyblade.body:applyForce(fx, fy)
        else
            print(length)
        end
        hasRipped = true
        isDragging = false
    end

end
