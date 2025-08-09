-- Run this to hot reload
-- nodemon --exec "love ." --ext lua --ignore node_modules
lobby = {}
prep = {}
ready = {}
countdown = {}
ripped = {}
loserId = nil

isServer = false
port = 12345

-- FORCE VALUES
val = 0 -- establish a variable for later use
cursorX, cursorY = 0
startDragX = 0
startDragY = 0
endDragX = 0
endDragY = 0
forceMod = 100000

beyblades = {}
debugMode = false

currentTime = 0
startCountdownTime = 0
gamestartTime = 0

function love.load(args)
    if arg[#arg] == "-debug" then
        require("mobdebug").start()
    end
    require("util")
    require("blade")
    require("blocks")
    require("prep")
    require("ready")
    require("countdown")
    require("ripped")
    require("game")
    readArgs(args)
    
    Gamestate = require("libs/hump/gamestate")
    vector = require "libs.hump.vector"
    screen = {
        width = love.graphics.getWidth(),
        height = love.graphics.getHeight()
    }

    world = love.physics.newWorld(0, 0, true) -- create a world for the bodies to exist in with horizontal gravity of 0 and vertical gravity of 9.81
    world:setCallbacks(beginContact)

    Gamestate.registerEvents()


    if debugMode then
        if isServer then
            require("server")
            setupServer()
        else
            require("client")
            setupClient()
        end
        -- Gamestate.switch(ready)
        Gamestate.switch(prep)
    else
        Gamestate.switch(lobby)
    end
end

function lobby:enter()
    -- Initialize menu state
    love.graphics.setBackgroundColor(0.2, 0.2, 0.2)  -- Set background color
    love.graphics.setFont(love.graphics.newFont(20)) -- Set font size
    love.window.setTitle("Ace of Blades")
    if isServer then
        require("server")
        setupServer()
    else
        require("client")
        love.timer.sleep(0.1) 
        setupClient()
        setToSecondMonitor() 
    end
end

function lobby:draw()
    love.graphics.setColor(1, 1, 1) -- Set color to white
    love.graphics.print("Welcome to the Beyblade Game!" .. (isServer and " (Server Mode)" or " (Client Mode)"), 100, 150)
end

function lobby:update(dt)
    currentTime = currentTime + dt
    if isServer then
        acceptClient()
    else
    end
end

