beyblade = {
  width = 200,
  length = 200,
  asset,
  body,    -- component that holds information about the body (vel, pos, accel etc.)
  shape,   -- collision (one shape many fixtures, )
  fixture, -- size, scallable, drag (one body many fixtures)
  spin = 20,
  vec = {
    x = 0,
    y = 0,
  },
}

originX = 325
originY = 325

local friction = 0.01
local circleRad = 35

function setupBlade(id)
  local newBlade = {}
  newBlade.id = id
  -- beyblade.asset = love.graphics.newImage("bey.png")
  newBlade.body = love.physics.newBody(world, originX, originY, "dynamic")
  newBlade.shape = love.physics.newCircleShape(circleRad)
  newBlade.fixture = love.physics.newFixture(newBlade.body, newBlade.shape, 100)
  newBlade.fixture:setRestitution(1)
  newBlade.fixture:setDensity(0)
  newBlade.body:setLinearDamping(0.05)
  newBlade.fixture:setFriction(friction)
  return newBlade
end

function drawBlade()
  for _, localblade in pairs(beyblades) do
    local x = localblade.body:getX()
    local y = localblade.body:getY()
    local angle = localblade.body:getAngle()
    love.graphics.setColor(0.76, 0.18, 0.05)
    love.graphics.circle("fill", localblade.body:getX(), localblade.body:getY(), circleRad)

    -- localised spiral parameters (slightly protruding from beyblade)
    local mode = 1              -- Archimedes spiral
    local protrudeFactor = 1.3 -- 1.0 = inside, >1.0 = slight protrusion
    local maxRadius = circleRad * protrudeFactor
    local dep = 80
    local angularStep = 0.2
    local K = maxRadius / (dep * angularStep) -- scale so spiral ends just beyond blade


    -- store drawing state
    love.graphics.push()
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


    love.graphics.pop()


    -- Show angular velocity above each beyblade
    local av = localblade.body:getAngularVelocity()
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(string.format("Spin: %.2f", av), localblade.body:getX() - 20,
      localblade.body:getY() - circleRad - 20)
  end
  if not isDragging and not hasRipped then
    love.graphics.circle("line", love.mouse.getX(), love.mouse.getY(), circleRad)
  end
  love.graphics.reset() -- Reset color to white
end

function drawRip()
  local sx, sy, mx, my, mirrorX, mirrorY
  if isDragging then
    sx, sy = beyblade.body:getX(), beyblade.body:getY()
    mx, my = love.mouse.getX(), love.mouse.getY()
  end

  if sx and sy and mx and my then
    -- Draw drag line (start to mouse)
    love.graphics.setColor(0, 0.4, 0) -- dark green
    love.graphics.line(sx, sy, mx, my)

    -- Calculate mirror point
    local dx = mx - sx
    local dy = my - sy
    mirrorX = sx - dx
    mirrorY = sy - dy

    -- Draw force direction arrow (start to mirror)
    love.graphics.setColor(0, 1, 0) -- bright green
    love.graphics.line(sx, sy, mirrorX, mirrorY)

    -- Draw arrowhead at mirror point
    local arrowLength = 20
    local arrowAngle = math.rad(30)
    local dir = vector(sx - mirrorX, sy - mirrorY):normalized() -- direction from mirror to start

    local left = dir:rotated(arrowAngle) * arrowLength
    local right = dir:rotated(-arrowAngle) * arrowLength

    love.graphics.line(mirrorX, mirrorY, mirrorX + left.x, mirrorY + left.y)
    love.graphics.line(mirrorX, mirrorY, mirrorX + right.x, mirrorY + right.y)
  end


  love.graphics.setColor(1, 1, 1)
end
