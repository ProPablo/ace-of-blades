-- Run this to hot reload
-- nodemon --exec "love ." --ext lua --ignore node_modules


local game = {}

function love.load()
    Camera = require("libs/hump/camera")
    Gamestate = require("libs/hump/gamestate")
    vector = require "libs.hump.vector"
    screen = {
        width = love.graphics.getWidth(),
        height = love.graphics.getHeight()
    }


    world = love.physics.newWorld(0, 1, true) -- create a world for the bodies to exist in with horizontal gravity of 0 and vertical gravity of 9.81

    setupBlocks()

    Gamestate.registerEvents()
    Gamestate.switch(game)
end

function setupBlocks() 
    blocks = {}
      -- BOX
    blocks.block1 = {}
    blocks.block1.body = love.physics.newBody(world, screen.width / 2, 0, "static")
    blocks.block1.shape = love.physics.newRectangleShape(0, 0, screen.width, blocksWidth)
    blocks.block1.fixture = love.physics.newFixture(blocks.block1.body, blocks.block1.shape, 5) -- A higher density gives it more mass.

    blocks.block2 = {}
    blocks.block2.body = love.physics.newBody(world, 0, screen.height / 2, "static")
    blocks.block2.shape = love.physics.newRectangleShape(0, 0, blocksWidth, screen.height)
    blocks.block2.fixture = love.physics.newFixture(blocks.block2.body, blocks.block2.shape, 5)

    blocks.block3 = {}
    blocks.block3.body = love.physics.newBody(world, screen.width / 2, screen.height, "static")
    blocks.block3.shape = love.physics.newRectangleShape(0, 0, screen.width, blocksWidth)
    blocks.block3.fixture = love.physics.newFixture(blocks.block3.body, blocks.block3.shape, 5) -- A higher density gives it more mass.

    blocks.block4 = {}
    blocks.block4.body = love.physics.newBody(world, screen.width, screen.height / 2, "static")
    blocks.block4.shape = love.physics.newRectangleShape(0, 0, blocksWidth, screen.height)
    blocks.block4.fixture = love.physics.newFixture(blocks.block4.body, blocks.block4.shape, 5)
end
