beyblade = {
    width = 100,
    length = 100,
    asset,
    body, -- component that holds information about the body (vel, pos, accel etc.)
    shape, -- collision (one shape many fixtures, )
    fixture -- size, scallable, drag (one body many fixtures)
}

local friction = 0.01

function setupBlade() 
    -- beyblade.asset = love.graphics.newImage("bey.png")
    beyblade.body = love.physics.newBody(world, 650 / 2, 650 / 2, "dynamic") 
    beyblade.shape = love.physics.newCircleShape(20) 
    beyblade.fixture = love.physics.newFixture(beyblade.body, beyblade.shape, 100) 
    beyblade.fixture:setRestitution(1)
    beyblade.body:setLinearDamping(0.05) 
    beyblade.fixture:setFriction(friction)
end

function drawBlade()
  local angle = love.timer.getTime() * 2 * math.pi / 2.5 
  love.graphics.setColor(0.76, 0.18, 0.05)
  love.graphics.circle("fill", beyblade.body:getX(), beyblade.body:getY(), 20)
  love.graphics.reset()
end
