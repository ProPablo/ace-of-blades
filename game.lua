function resetGameState()
  hasRipped = false
  hasSet = false
  for _, localblade in pairs(beyblades) do
    localblade.body:setPosition(originX, originY)
    localblade.body:applyForce(0, 0)
    localblade.body:setLinearVelocity(0, 0)
    localblade.body:setAngularVelocity(0, 0)
  end
end

function drawGameState()
  local setMsg = hasSet and "SET" or "READYING..."
  if hasRipped then setMsg = "RIPPED" end
  love.graphics.print(setMsg, screen.width / 2, 200, 0, 2, 2)
end
