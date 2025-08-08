-- Run this to hot reload
-- nodemon --exec "love ." --ext lua --ignore node_modules

game = {}
menu = {}

isServer = false
port = 12345


local val = 0 -- establish a variable for later use
local x, y

valSpeed = 500
forceMod = 1000

function love.load(args)
    if arg[#arg] == "-debug" then require("mobdebug").start() end
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

    if isServer then
        require("server")
        setupServer()
    else
        require("client")
        setupClient()
    end

    world = love.physics.newWorld(0, 1, true) -- create a world for the bodies to exist in with horizontal gravity of 0 and vertical gravity of 9.81

    Gamestate.registerEvents()
    Gamestate.switch(game)
end

function game:enter()
    setupBlocks()
    setupBlade()
end

function game:draw()
    love.graphics.print(val, 100, 200)
    love.graphics.print(x, 100, 300)
    love.graphics.print(y, 100, 400)
    drawBlocks()
    drawBlade()
end

function game:update(dt)
    world:update(dt)
    x, y = love.mouse.getPosition()
    if love.mouse.isDown(1) then
        val = val + dt * valSpeed -- we will increase the variable by 1 for every second the button is held down
    end

    if not love.mouse.isDown(1) then
        beyblade.body:applyForce(val*forceMod, val*forceMod)
        val = 0
    end
end
