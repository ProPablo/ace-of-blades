-- Run this to hot reload
-- nodemon --exec "love ." --ext lua --ignore node_modules


game = {}
menu = {}

isServer = false


local val = 0 -- establish a variable for later use
local x, y
valSpeed = 500

blocksWidth = 50

function love.load()
    if arg[#arg] == "-debug" then require("mobdebug").start() end
    require("util")
    Gamestate = require("libs/hump/gamestate")
    vector = require "libs.hump.vector"
    screen = {
        width = love.graphics.getWidth(),
        height = love.graphics.getHeight()
    }

    world = love.physics.newWorld(0, 1, true) -- create a world for the bodies to exist in with horizontal gravity of 0 and vertical gravity of 9.81


    Gamestate.registerEvents()
    Gamestate.switch(game)
end

function game:enter()
    setupBlocks()
end

function setupBlocks() 
    blocks = {}
      -- BOX
    blocks.block1 = {}
    blocks.block1.body = love.physics.newBody(world, screen.width / 2, 0, "static")
    blocks.block1.shape = love.physics.newRectangleShape(0, 0, screen.width, blocksWidth)
    blocks.block1.fixture = love.physics.newFixture(blocks.block1.body, blocks.block1.shape, 5)

    blocks.block2 = {}
    blocks.block2.body = love.physics.newBody(world, 0, screen.height / 2, "static")
    blocks.block2.shape = love.physics.newRectangleShape(0, 0, blocksWidth, screen.height)
    blocks.block2.fixture = love.physics.newFixture(blocks.block2.body, blocks.block2.shape, 5)

    blocks.block3 = {}
    blocks.block3.body = love.physics.newBody(world, screen.width / 2, screen.height, "static")
    blocks.block3.shape = love.physics.newRectangleShape(0, 0, screen.width, blocksWidth)
    blocks.block3.fixture = love.physics.newFixture(blocks.block3.body, blocks.block3.shape, 5) 

    blocks.block4 = {}
    blocks.block4.body = love.physics.newBody(world, screen.width, screen.height / 2, "static")
    blocks.block4.shape = love.physics.newRectangleShape(0, 0, blocksWidth, screen.height)
    blocks.block4.fixture = love.physics.newFixture(blocks.block4.body, blocks.block4.shape, 5)
end

function game:draw()
    love.graphics.print(val, 100, 200)
    love.graphics.print(x, 100, 300)
    love.graphics.print(y, 100, 400)
    for _, block in ipairs(blocks) do
        print(block)
        love.graphics.rectangle("fill", block.x, block.y, block.width, block.height)
    end
end

function game:update(dt)
    -- world:update(dt) -- this puts the world into motion
    x, y = love.mouse.getPosition()
    if love.mouse.isDown(1) then
        val = val + dt * valSpeed -- we will increase the variable by 1 for every second the button is held down
    end
end
