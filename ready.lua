ready = {}

local ClientRpcCommands = {
  LAUNCH_VEC = "launchVec",

}
local ServerRpcCommands = {
  STATE_TRANSITION = "transitionFromReady",
  SERVER_TIME = "serverTime",
}

local isDragging = false
local clientHasSetLaunchVec = false
local serverHasSetLaunchVec = false


local function drawRip()
  local sx, sy, mx, my, mirrorX, mirrorY
  if isDragging then
    sx, sy = beyblade.body:getX(), beyblade.body:getY()
    mx, my = love.mouse.getX(), love.mouse.getY()
  end

  if sx and sy and mx and my then
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

local function sendStateTransitionRpcFromServer(dt)
  local message = {
    cmd = ServerRpcCommands.STATE_TRANSITION
  }
  local jsonData = json.encode(message)
  udp:sendto(jsonData, client.ip, client.port)
  print("Sent state transition command to client")
end


local function sendVectorRpcFromClient()
  local message = {
    cmd = ClientRpcCommands.LAUNCH_VEC,
    launchVec = {
      x = beyblade.launchVec.x,
      y = beyblade.launchVec.y
    },
    position = {
      x = beyblade.body:getX(),
      y = beyblade.body:getY()
    }
  }

  local jsonData = json.encode(message)
  print("Sending vector to server: " .. jsonData)
  udp:send(jsonData)
end

local function acceptRpcServer(dt)
  local data, msg_or_ip, port = udp:receivefrom()
  if data then
    local message = json.decode(data)
    print("Received command: " .. message.cmd)

    if message.cmd == ClientRpcCommands.LAUNCH_VEC then
      local launchVec = message.launchVec
      local position = message.position

      print(string.format("Parsed launch vector: x=%.2f, y=%.2f at position x=%.2f, y=%.2f",
        launchVec.x, launchVec.y, position.x, position.y))

      beyblades[2].launchVec = { x = launchVec.x, y = launchVec.y }
      beyblades[2].body:setPosition(position.x, position.y)
      clientHasSetLaunchVec = true
    else
      print("Unknown command: " .. message.cmd)
    end
  end
end

local function acceptRpcClient(dt)
  local data, err = udp:receive()
  if data then
    local message = json.decode(data)
    print("Received data from server: " .. message.cmd)

    if message.cmd == ServerRpcCommands.STATE_TRANSITION then
      print("Received state transition command to countdown server")
      Gamestate.switch(countdown)
      return
    end
  elseif err ~= "timeout" then
    print("Error receiving from server: " .. err)
  end
end


-- local function resetGameState()
--   setupBlocks()
--   clientHasSetLaunchVec = false

--   -- for _, blade in ipairs(beyblades) do
--   --   blade.body:destroy() -- optional in LÖVE 12.0+, else just nil it
--   -- end
--   -- beyblades = {}
--   beyblades[1] = setupBlade(1) -- Server's beyblade
--   beyblades[2] = setupBlade(2) -- Client's beyblade
-- end


function ready:enter()
  isDragging = false
  clientHasSetLaunchVec = false
  serverHasSetLaunchVec = false
end

function ready:update(dt)
  world:update(dt)
  cursorX, cursorY = love.mouse.getPosition()

  if isServer then
    beyblade = beyblades[1]
    acceptRpcServer(dt)
    -- serverSendPosUpdate(dt)
    if clientHasSetLaunchVec and serverHasSetLaunchVec then
      Gamestate.switch(countdown)
    end

    -- if (love.keyboard.isDown("r")) then
    --   resetGameState()
    -- end
    if serverHasSetLaunchVec then return end

    if (love.mouse.isDown(1) and isDragging == false) then
      beyblade.body:setPosition(cursorX, cursorY)
      startDragX = cursorX
      startDragY = cursorY
      isDragging = true
    end
  else
    acceptRpcClient(dt)
    beyblade = beyblades[2]
    if clientHasSetLaunchVec then return end

    if (love.mouse.isDown(1) and isDragging == false) then
      beyblade.body:setPosition(cursorX, cursorY)
      startDragX = cursorX
      startDragY = cursorY
      isDragging = true
    end
  end

  -- RELEASE
  if (not love.mouse.isDown(1) and isDragging == true) then
    endDragX = cursorX
    endDragY = cursorY
    if endDragX == startDragX and endDragY == startDragY then
      isDragging = false
      return
    end
    local dx = endDragX - startDragX
    local dy = endDragY - startDragY
    local length = math.sqrt(dx * dx + dy * dy)
    if length > 0 then
      -- Normalize direction
      local dirX = dx / length
      local dirY = dy / length
      local fx = -dirX * length * forceMod
      local fy = -dirY * length * forceMod
      beyblade.launchVec = { x = fx, y = fy }
      if isServer then
        serverHasSetLaunchVec = true
      else
        clientHasSetLaunchVec = true
        sendVectorRpcFromClient()
      end
      isDragging = false
    else
      print(length)
    end
  end
end

function ready:draw()
  UTIL.drawBackground()
  local setMsg = ""
  local showCursor = false
  if isServer then
    setMsg = serverHasSetLaunchVec and "SET" or "READYING..."
    if not isDragging and not serverHasSetLaunchVec then showCursor = true end
  else
    setMsg = clientHasSetLaunchVec and "SET" or "READYING..."
    if not isDragging and not clientHasSetLaunchVec then showCursor = true end
  end
  drawBlocks()
  drawBlade(beyblade.id)
  drawRip()

  -- Draw drag cursor
  if showCursor then
    love.graphics.circle("line", love.mouse.getX(), love.mouse.getY(), circleRad)
  end

  love.graphics.print(setMsg, screen.width / 2.5, 200, 0, 2, 2)
end

function ready:leave()
  if isServer then
    sendStateTransitionRpcFromServer()
  end
end
