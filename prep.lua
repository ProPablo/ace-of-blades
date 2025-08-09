function prep:enter()
  resetGameState()
end

function prep:draw()
  love.graphics.print("Welcome to the Beyblade Game!" .. (isServer and " (Server Mode)" or " (Client Mode)"), 100, 150)
end

function prep:update()
  
end
