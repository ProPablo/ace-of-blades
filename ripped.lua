ANGULAR_VEL = 100

function ripped:enter()
  timer = TIMER_CONST
  local beyblade = beyblades[1]
  beyblade.body:applyForce(beyblade.vec.x, beyblade.vec.y)
  -- Big spin-up
  -- beyblade.body:applyTorque(500000)
  -- Optional: give an immediate angular velocity boost (instant spin)
  beyblade.body:setAngularVelocity(ANGULAR_VEL) -- play with this number for instant "whip"
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
  for _, localblade in pairs(beyblades) do
    local lv = localblade.body:getLinearVelocity()
    if lv == 0 then
      loserId = localblade.id
    end
  end
  
end
