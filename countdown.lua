TIMER_CONST = 5 -- 3,2,1

local displayTime = 0
local bigNumber = 0
local hasNumberDisplayed = {
  one = false,
  two = false,
  three = false,
}

function countdown:enter()
  gamestartTime = serverTime + 5
  displayTime = serverTime - gamestartTime
end

function countdown:draw()
  local showDisplayTime = string.format("%f.2", displayTime)
  love.graphics.print(showDisplayTime, screen.width / 2, 200, 0, 2, 2)
  love.graphics.print(bigNumber, screen.width / 2, 300, 0, 10, 10)

end

function countdown:update(dt)
  displayTime = serverTime - gamestartTime
  if displayTime <= 3 and hasNumberDisplayed.three == false then
    hasNumberDisplayed.three = true
    bigNumber = 3
  end
  if displayTime <= 2 and hasNumberDisplayed.two == false then
    hasNumberDisplayed.two = true
    bigNumber = 2
  end
  if displayTime <= 1 and hasNumberDisplayed.one == false then
    hasNumberDisplayed.one = true
    bigNumber = 1
  end
  -- if (displayTime < 0) then

  --   Gamestate.switch(ripped)
  -- end
end

function sendRpcFromServer() 

end
