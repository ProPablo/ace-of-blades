SHAPE = {
  STICK = 1,
  SQUARE = 2,
  PENTAGON = 3,
}

beyblade = {
  width = 200,
  length = 200,
  asset,
  body,    -- component that holds information about the body (vel, pos, accel etc.)
  shape,   -- collision (one shape many fixtures, )
  fixture, -- size, scallable, drag (one body many fixtures)
  launchVec = {
    x = 0,
    y = 0,
  },
  chosenShape = 0
}
beybladeMaxHealth = 100

originX = 325
originY = 325

local friction = 0.0
circleRad = 35

function setupBlade(id)
  local newBlade = {}
  newBlade.id = id
  -- beyblade.asset = love.graphics.newImage("bey.png")
  newBlade.body = love.physics.newBody(world, originX, originY, "dynamic")
  newBlade.shape = love.physics.newCircleShape(circleRad)
  newBlade.fixture = love.physics.newFixture(newBlade.body, newBlade.shape, 100)
  newBlade.fixture:setRestitution(1)
  newBlade.fixture:setDensity(0)
  newBlade.body:setAngularDamping(0.5) -- slows spin over time
  newBlade.body:setLinearDamping(0.2)  -- slows movement over time
  newBlade.fixture:setFriction(friction)

  newBlade.health = beybladeMaxHealth
  newBlade.direction = 1 -- 1 for clockwise, -1 for counter-clockwise
  return newBlade
end

local serverBladeColor = { 0.76, 0.18, 0.05 } -- Red
local clientBladeColor = { 0.05, 0.18, 0.76 } -- Blue

function drawBlade(id)
  local localblade = beyblades[id]
  love.graphics.print("selection " .. localblade.chosenShape , screen.width / 2, 300, 0, 2, 2)
  
  local x = localblade.body:getX()
  local y = localblade.body:getY()
  local angle = localblade.body:getAngle()


    -- Show angular velocity above each beyblade
    local av = localblade.body:getAngularVelocity()
    local lv = localblade.body:getLinearVelocity()
    love.graphics.setColor(1, 1, 1)

    love.graphics.print(string.format("Spin: %.2f", localblade.health), localblade.body:getX() - 20,
      localblade.body:getY() - circleRad - 20)
    love.graphics.print(string.format("Speed: %.2f", lv), localblade.body:getX() - 20,
      localblade.body:getY() - circleRad - 30)

  if localblade.id == 1 then
    love.graphics.setColor(serverBladeColor)
  else
    love.graphics.setColor(clientBladeColor)
  end

  love.graphics.circle("fill", localblade.body:getX(), localblade.body:getY(), circleRad)

  -- localised spiral parameters (slightly protruding from beyblade)
  local mode = 1             -- Archimedes spiral
  local protrudeFactor = 1.3 -- 1.0 = inside, >1.0 = slight protrusion
  local maxRadius = circleRad * protrudeFactor
  local dep = 80
  local angularStep = 0.15
  local K = maxRadius / (dep * angularStep) -- scale so spiral ends just beyond blade

  -- store drawing state
  -- love.graphics.push()
  love.graphics.translate(x, y)
  love.graphics.rotate(angle)

  -- reset local spiral state
  local A = 0
  local lx, ly = 0, 0
  for s = 0, dep do
    local R
    if mode == 1 then
      R = K * A
    elseif mode == 2 then
      R = K ^ A
    elseif mode == 3 then
      R = math.sqrt(A) * K
    end

    if R > maxRadius then R = maxRadius end

    local xpos = R * math.cos(A)
    local ypos = R * math.sin(A)

    love.graphics.setColor(1, 1 - s / dep, s / dep)
    love.graphics.setLineWidth(1.5)
    love.graphics.line(lx, ly, xpos, ypos)

    lx, ly = xpos, ypos
    A = A + angularStep


  end

  love.graphics.reset() -- Reset color to white
end
