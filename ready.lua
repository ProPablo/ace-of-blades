isDragging = false
clientHasSetLaunchVec = false
serverHasSetLaunchVec = false

function resetGameState()
  setupBlocks()
  clientHasSetLaunchVec = false

  for _, blade in ipairs(beyblades) do
    blade.body:destroy() -- optional in LÖVE 12.0+, else just nil it
  end
  beyblades = {}
  beyblades[1] = setupBlade(1) -- Server's beyblade
  beyblades[2] = setupBlade(2) -- Client's beyblade
end

function ready:enter()
  resetGameState()
end

function ready:update(dt)
  world:update(dt)
  -- Rip it whether by timer or by user input
  if clientHasSetLaunchVec and serverHasSetLaunchVec then
    gamestartTime = serverTime + 5 -- start game 5 seconds from now
    Gamestate.switch(countdown)
  end
  if isServer then
    beyblade = beyblades[1]
    ready:acceptRpcServer(dt)
    rippedSendServerUpdate(dt)
  else
    receiveClientUpdates()
    beyblade = beyblades[2]
  end

  cursorX, cursorY = love.mouse.getPosition()

  if (love.keyboard.isDown("r")) then
    resetGameState()
  end


  if (love.keyboard.isDown("space") and clientHasSetLaunchVec) then
    Gamestate.push(ripped)
  end

  -- If rip already set early return
  if (clientHasSetLaunchVec) then return end

  -- HOLD
  if (love.mouse.isDown(1) and isDragging == false) then
    beyblade.body:setPosition(cursorX, cursorY)
    startDragX = cursorX
    startDragY = cursorY
    isDragging = true
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
  drawDebug()
  drawBlocks()
  drawBlade()
  drawRip()
  local setMsg = clientHasSetLaunchVec and "SET" or "READYING..."
  love.graphics.print(setMsg, screen.width / 2, 200, 0, 2, 2)
end

function drawRip()
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

local RpcCommands = {
  LAUNCH_VEC = "launchVec",
}

function sendVectorRpcFromClient()
  local data = string.format(
    "%s %f %f",
    RpcCommands.LAUNCH_VEC,
    beyblade.launchVec.x,
    beyblade.launchVec.y
  )
  udp:send(data)
end

function ready:acceptRpcServer(dt)
  local data, msg_or_ip, port = udp:receiveFrom()
  if (data) then
    local cmd, params = string.match(data, "^(%S+)%s*(.*)")
    printf("Received command: " .. cmd)
    if cmd == RpcCommands.LAUNCH_VEC then
      local x, y = string.match(params, "([%-%d%.]+)%s+([%-%d%.]+)")
      x = tonumber(x)
      y = tonumber(y)
      printf("Parsed launch vector: x=%f, y=%f", x, y)
      beyblades[2].launchVec.x = x
      beyblades[2].launchVec.y = y
    else
      printf("Unknown command: " .. cmd)
    end
  end
end

function ready:acceptRpcClient(dt)

end
