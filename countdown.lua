local ServerRpcCommands = {
  BALL_UPDATE_FROM_COUNTDOWN = "ballUpdateFromCountdown",
}
TIMER_CONST = 5 -- 1s Ready + 3s countdown + 1s Let it rip

local displayTime = 0
local phase = "ready"
local bigNumber = 0

local t = 0
local function serverSendPosUpdate(dt)
  t = t + dt

  if t > updateRate then
    t = t - updateRate

    local ballData = {}
    for _, localBlade in ipairs(beyblades) do
      table.insert(ballData, {
        id = localBlade.id,
        x = localBlade.body:getX(),
        y = localBlade.body:getY(),
      })
    end

    local updateMessage = {
      cmd = ServerRpcCommands.BALL_UPDATE_FROM_COUNTDOWN,
      balls = ballData,
    }

    local jsonData = json.encode(updateMessage)

    if client then
      udp:sendto(jsonData, client.ip, client.port)
    end
  end
end

local function acceptRpcClient()
  local data, err = udp:receive()
  if data then
    local message = json.decode(data)

    if message.cmd == ServerRpcCommands.BALL_UPDATE_FROM_COUNTDOWN then
      -- Process ball updates
      for _, ballData in ipairs(message.balls) do
        local id = ballData.id
        if not beyblades[id] then
          -- TODO: ensure safe, commit:b5750a371be6f7b501bbc80fa8b1e7c631f2db3b brokey this
          error("fucgma")
          -- beyblades[id] = {
          --   id = id,
          --   body = love.physics.newBody(world, ballData.x, ballData.y, "dynamic"),
          -- }
        end
        local body = beyblades[id].body
        body:setPosition(ballData.x, ballData.y)
      end
    end
  elseif err ~= "timeout" then
    print("Error receiving from server: " .. err)
  end
end


function countdown:enter()
  gamestartTime = serverTime + TIMER_CONST
end

function countdown:draw()
  drawBlade(1)
  drawBlade(2)
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
    phase = "ready"     -- 1 second
  elseif displayTime > 1 then
    phase = "countdown" -- 3, 2, 1
    bigNumber = math.ceil(displayTime - 1)
  elseif displayTime > 0 then
    phase = "letitrip"       -- 1 second
  else
    Gamestate.switch(ripped) -- go immediately, no buffer
  end
  if isServer then
    serverSendPosUpdate(dt)
  else
    acceptRpcClient()
  end
end
