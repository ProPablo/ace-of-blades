local ClientRpcCommands = {
  LAUNCH_VEC = "launchVec",

}
local ServerRpcCommands = {
  STATE_TRANSITION = "stateTransition",
}

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
    sendStateTransitionRpcFromServer(dt)
    Gamestate.switch(countdown)
  end
  if isServer then
    acceptRpcServer(dt)
    beyblade = beyblades[1]
    serverSendPosUpdate(dt)
  else
    -- acceptRpcClient(dt)
    acceptRpcClient(dt)
    beyblade = beyblades[2]
  end

  cursorX, cursorY = love.mouse.getPosition()

  if (love.keyboard.isDown("r")) then
    resetGameState()
  end

  -- If rip already set early return
  if isServer and serverHasSetLaunchVec then return end
  if not isServer and clientHasSetLaunchVec then return end

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
  local setMsg = ""
  if isServer then
    setMsg = serverHasSetLaunchVec and "SET" or "READYING..."
  else
    setMsg = clientHasSetLaunchVec and "SET" or "READYING..."
  end

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

function sendVectorRpcFromClient()
  local data = string.format(
    "%s %f %f",
    ClientRpcCommands.LAUNCH_VEC,
    beyblade.launchVec.x,
    beyblade.launchVec.y
  )
  udp:send(data)
end

function acceptRpcServer(dt)
  local data, msg_or_ip, port = udp:receivefrom()
  if (data) then
    local cmd, params = string.match(data, "^(%S+)%s*(.*)")
    print("Received command: " .. cmd)
    if cmd == ClientRpcCommands.LAUNCH_VEC then
      local x, y = string.match(params, "([%-%d%.]+)%s+([%-%d%.]+)")
      x = tonumber(x)
      y = tonumber(y)
      print("Parsed launch vector: x=%f, y=%f", x, y)
      beyblades[2].launchVec = { x = x, y = y }
      clientHasSetLaunchVec = true
    else
      print("Unknown command: " .. cmd)
    end
  end
end

function sendStateTransitionRpcFromServer(dt)
  udp:sendto(ServerRpcCommands.STATE_TRANSITION, client.ip, client.port)
  print("Sent state transition command to client: " .. ServerRpcCommands.STATE_TRANSITION)
end

function acceptRpcClient(dt)
  local data, err = udp:receive()
  if data then
    for segment in data:gmatch("([^;]+)") do
      -- Try matching a ball packet: id, x, y, vx, vy, av
      local cmd, id, x, y, vx, vy, av = segment:match(
        "^%s*(%S+)%s+(%d+)%s+(%S+)%s+(%S+)%s+(%S+)%s+(%S+)%s+(%S+)%s*$"
      )
      if cmd == "ball" then
        id = tonumber(id)
        x  = tonumber(x)
        y  = tonumber(y)
        vx = tonumber(vx)
        vy = tonumber(vy)
        av = tonumber(av)

        if not beyblades[id] then
          beyblades[id] = {
            id = id,
            body = love.physics.newBody(world, x, y, "dynamic")
          }
        end

        local body = beyblades[id].body
        body:setPosition(x, y)
        body:setLinearVelocity(vx, vy)
        body:setAngularVelocity(av)
      elseif cmd == ServerRpcCommands.STATE_TRANSITION then
        print("Received state transition command from server")
        Gamestate.switch(countdown)
      else
        -- TODO
        -- Handle serverTime
        local timeCmd, timeVal = segment:match("^%s*(%S+)%s+(%S+)%s*$")
        if timeCmd == "serverTime" then
          serverTime = tonumber(timeVal)
        end
      end
    end
  elseif err ~= "timeout" then
    print("Error receiving from server: " .. err)
  end
end

function ready:leave()
  -- if isServer then
  --   sendStateTransitionRpcFromServer()
  -- end
end
