function ripped:enter()
  timer = TIMER_CONST
  local beyblade = beyblades[1]
  beyblade.body:applyForce(beyblade.vec.x, beyblade.vec.y)
  -- Big spin-up
  beyblade.body:applyTorque(500000)
  -- Optional: give an immediate angular velocity boost (instant spin)
  beyblade.body:setAngularVelocity(30) -- play with this number for instant "whip"
end

function ripped:draw()
  drawDebug()
  drawBlocks()
  drawBlade()
  drawGameState(true)
end

function ripped:update(dt)
  world:update(dt)
  if (love.keyboard.isDown("r")) then
    Gamestate.switch(ready)
  end
  for _, blade in pairs(beyblades) do
    local spin = blade.body:getAngularVelocity()
    local vx, vy = blade.body:getLinearVelocity()

    if math.abs(spin) > 0.1 then
        local speed = math.sqrt(vx*vx + vy*vy)
        local dirAngle = (speed > 1) and math.atan2(vy, vx) or blade.body:getAngle()
        local moveAngle = dirAngle + (spin > 0 and math.pi/2 or -math.pi/2)

        local spinForce = spin * 5  -- start big to see effect
        local fx = math.cos(moveAngle) * spinForce
        local fy = math.sin(moveAngle) * spinForce

        blade.body:applyForce(fx, fy)
    end

    local damping = 0.05
    if math.abs(spin) > 50 then
        damping = 0.02
    end
    blade.body:setLinearDamping(damping)
end

end
