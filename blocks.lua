blocksWidth = 50

local friction = 0.01

function setupBlocks() 
  -- BOX
  blocks = {}
  -- LEFT
  blocks.block1 = {}
  blocks.block1.body = love.physics.newBody(world, screen.width / 2, 0, "static")
  blocks.block1.shape = love.physics.newRectangleShape(0, 0, screen.width, blocksWidth)
  blocks.block1.fixture = love.physics.newFixture(blocks.block1.body, blocks.block1.shape, 5)

  -- RIGHT
  blocks.block2 = {}
  blocks.block2.body = love.physics.newBody(world, 0, screen.height / 2, "static")
  blocks.block2.shape = love.physics.newRectangleShape(0, 0, blocksWidth, screen.height)
  blocks.block2.fixture = love.physics.newFixture(blocks.block2.body, blocks.block2.shape, 5)
  
  -- BOTTOM
  blocks.block3 = {}
  blocks.block3.body = love.physics.newBody(world, screen.width / 2, screen.height, "static")
  blocks.block3.shape = love.physics.newRectangleShape(0, 0, screen.width, blocksWidth)
  blocks.block3.fixture = love.physics.newFixture(blocks.block3.body, blocks.block3.shape, 5) 

  -- RIGHT
  blocks.block4 = {}
  blocks.block4.body = love.physics.newBody(world, screen.width, screen.height / 2, "static")
  blocks.block4.shape = love.physics.newRectangleShape(0, 0, blocksWidth, screen.height)
  blocks.block4.fixture = love.physics.newFixture(blocks.block4.body, blocks.block4.shape, 5)

  -- Friction
  blocks.block1.fixture:setFriction(friction)
  blocks.block2.fixture:setFriction(friction)
  blocks.block3.fixture:setFriction(friction)
  blocks.block4.fixture:setFriction(friction)
  
end

function drawBlocks() 
  love.graphics.polygon("fill", blocks.block1.body:getWorldPoints(blocks.block1.shape:getPoints()))
  love.graphics.polygon("fill", blocks.block2.body:getWorldPoints(blocks.block2.shape:getPoints()))
  love.graphics.polygon("fill", blocks.block3.body:getWorldPoints(blocks.block3.shape:getPoints()))
  love.graphics.polygon("fill", blocks.block4.body:getWorldPoints(blocks.block4.shape:getPoints()))
end
