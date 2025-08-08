beyblade = {
    width = 200,
    length = 200,
    asset,
    body,   -- component that holds information about the body (vel, pos, accel etc.)
    shape,  -- collision (one shape many fixtures, )
    fixture -- size, scallable, drag (one body many fixtures)
}

local friction = 0.01

local circleRad = 35

function setupBlade(id)
    local newBlade = {}
    newBlade.id = id
    -- beyblade.asset = love.graphics.newImage("bey.png")
    newBlade.body = love.physics.newBody(world, 650 / 2, 650 / 2, "dynamic")
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
        love.graphics.setColor(0.76, 0.18, 0.05)
        love.graphics.circle("fill", localblade.body:getX(), localblade.body:getY(), circleRad)
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
    love.graphics.setColor(0, 0.4, 0)     -- dark green
    love.graphics.line(sx, sy, mx, my)

    -- Calculate mirror point
    local dx = mx - sx
    local dy = my - sy
    mirrorX = sx - dx
    mirrorY = sy - dy

    -- Draw force direction arrow (start to mirror)
    love.graphics.setColor(0, 1, 0)     -- bright green
    love.graphics.line(sx, sy, mirrorX, mirrorY)

    -- Draw arrowhead at mirror point
    local angle = math.atan2(mirrorY - sy, mirrorX - sx)
    local arrowLength = 20
    local arrowAngle = math.rad(30)

    local ax1 = mirrorX - arrowLength * math.cos(angle - arrowAngle)
    local ay1 = mirrorY - arrowLength * math.sin(angle - arrowAngle)
    local ax2 = mirrorX - arrowLength * math.cos(angle + arrowAngle)
    local ay2 = mirrorY - arrowLength * math.sin(angle + arrowAngle)

    love.graphics.line(mirrorX, mirrorY, ax1, ay1)
    love.graphics.line(mirrorX, mirrorY, ax2, ay2)
  end


  love.graphics.setColor(1, 1, 1)
end
