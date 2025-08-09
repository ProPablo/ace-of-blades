-- Run this to hot reload
-- nodemon --exec "love ." --ext lua --ignore node_modules
game = {}
lobby = {}

isServer = false
port = 12345


-- GAME STATE
hasRipped = false

-- FORCE VALUES
val = 0 -- establish a variable for later use
cursorX, cursorY = 0
startDragX = 0
startDragY = 0
endDragX = 0
endDragY = 0

forceMod = 30000

isDragging = false
hasRipped = false

function love.load(args)
    if arg[#arg] == "-debug" then
        require("mobdebug").start()
    end
    require("util")
    require("blade")
    require("blocks")
    readArgs(args)


    Gamestate = require("libs/hump/gamestate")
    vector = require "libs.hump.vector"
    screen = {
        width = love.graphics.getWidth(),
        height = love.graphics.getHeight()
    }


    world = love.physics.newWorld(0, 1, true) -- create a world for the bodies to exist in with horizontal gravity of 0 and vertical gravity of 9.81

    Gamestate.registerEvents()
    Gamestate.switch(lobby)
end

function lobby:enter()
    -- Initialize menu state
    love.graphics.setBackgroundColor(0.2, 0.2, 0.2) -- Set background color
    love.graphics.setFont(love.graphics.newFont(20)) -- Set font size

    if isServer then
        require("server")
        setupServer()
    else
        require("client")
        setupClient()
    end


end

function lobby:draw()
    love.graphics.setColor(1, 1, 1) -- Set color to white
    love.graphics.print("Welcome to the Beyblade Game!" .. (isServer and " (Server Mode)" or " (Client Mode)"), 100, 150)
end

function lobby:update(dt)
    if isServer then 
        acceptClient()
    else
    end
    
end

function game:enter()
    setupBlocks()
    beyblades[1] = setupBlade(1)     -- Server's beyblade
    beyblades[1].body:setPosition(100, 100) -- Set initial position for server's beyblade
    beyblades[2] = setupBlade(2)     -- Client's beyblade
end

function game:draw()
    drawDebug()
    drawBlocks()
    drawBlade()
    drawRip()
end

function game:update(dt)
    if isServer then
        beyblade = beyblades[1]
        sendServerUpdate(dt)
    else
        receiveClientUpdates()
        beyblade = beyblades[2]
    end

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
        local length = math.sqrt(dx * dx + dy * dy)
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
