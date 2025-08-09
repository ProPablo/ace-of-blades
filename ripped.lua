ANGULAR_VEL = 100

function ripped:enter()
  timer = TIMER_CONST
  if beyblades then
    local beyblade = beyblades[2]
    if isServer then
      beyblade = beyblades[1]
    end
    beyblade.body:applyForce(beyblade.vec.x, beyblade.vec.y)
    -- Big spin-up
    -- beyblade.body:applyTorque(500000)
    -- Optional: give an immediate angular velocity boost (instant spin)
    beyblade.body:setAngularVelocity(ANGULAR_VEL) -- play with this number for instant "whip"
  end
end

function ripped:draw()
  drawDebug()
  drawBlocks()
  drawBlade()

  love.graphics.print("Ripped...", screen.width / 2, 200, 0, 2, 2)
  if loserId then
    love.graphics.print(string.format("Loser: %.2f", loserId), screen.width / 2, 220, 0, 2, 2)
  end
end

function ripped:update(dt)
  world:update(dt)
  if (loserId) then
    for _, localblade in pairs(beyblades) do
      localblade.body:setAngularVelocity(0)
      localblade.body:setLinearVelocity(0, 0)
    end
  end
  if (love.keyboard.isDown("r")) then
    Gamestate.switch(ready)
  end
  for _, localblade in pairs(beyblades) do
    local spin = localblade.body:getAngularVelocity()
    local vx, vy = localblade.body:getLinearVelocity()
    if vx == 0 then
      -- loserId = localblade.id
    end

    if math.abs(spin) > 0.1 then
      local speed = math.sqrt(vx * vx + vy * vy)
      local dirAngle = (speed > 1) and math.atan2(vy, vx) or localblade.body:getAngle()
      local moveAngle = dirAngle + (spin > 0 and math.pi / 2 or -math.pi / 2)

      local spinForce = spin * 5 -- start big to see effect
      local fx = math.cos(moveAngle) * spinForce
      local fy = math.sin(moveAngle) * spinForce

      localblade.body:applyForce(fx, fy)
    end

    local damping = 0.05
    if math.abs(spin) > 50 then
      damping = 0.02
    end
    localblade.body:setLinearDamping(damping)
  end

  if isServer then
    rippedSendServerUpdate(dt)
  else
    receiveClientUpdates()
  end
end
