TIMER_CONST = 5 -- 1s Ready + 3s countdown + 1s Let it rip

local displayTime = 0
local phase = "ready"
local bigNumber = 0

function countdown:enter()
  gamestartTime = serverTime + TIMER_CONST
end

function countdown:draw()
  local text = ""

  if phase == "ready" then
    text = "Ready?"
  elseif phase == "countdown" then
    text = tostring(bigNumber)
  elseif phase == "letitrip" then
    text = "LET IT RIP!"
  end

  if text ~= "" then
    local winWidth = love.graphics.getWidth()
    local winHeight = love.graphics.getHeight()

    local font = love.graphics.getFont()
    local textWidth = font:getWidth(text) * 10
    local textHeight = font:getHeight() * 10

    love.graphics.print(
      text,
      (winWidth / 2) - (textWidth / 2),
      (winHeight / 2) - (textHeight / 2),
      0,
      10, 10
    )
  end
end

function countdown:update(dt)
  displayTime = gamestartTime - serverTime

  if displayTime > 4 then
    phase = "ready"         -- 1 second
  elseif displayTime > 1 then
    phase = "countdown"     -- 3, 2, 1
    bigNumber = math.ceil(displayTime - 1)
  elseif displayTime > 0 then
    phase = "letitrip"           -- 1 second
  else
    Gamestate.switch(ripped)     -- go immediately, no buffer
  end
end
