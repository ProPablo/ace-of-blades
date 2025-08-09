shapes = {
    { name = "Stick...",  type = SHAPE.STICK },
    { name = "Rectangle", type = SHAPE.SQUARE },
    { name = "Pentagon",  type = SHAPE.PENTAGON }
  }

local ClientRpcCommands = {
  HAS_SELECTED = "selected",
}

local ServerRpcCommands = {
  STATE_TRANSITION = "stateTransition",
}

local selection = 0

clientHasSelected = false
serverHasSelected = false

function prep:enter()
  beyblades = {}
  beyblades[1] = setupBlade(1) -- Server's beyblade
  beyblades[2] = setupBlade(2) -- Client's beyblade
  setupBlocks()
end

function prep:draw()
  -- Shape options (only text now)
  
  love.graphics.setColor(1, 1, 1) -- Reset color to white
  local screenWidth = love.graphics.getWidth()
  local selectedName = "None"
  for _, shape in ipairs(shapes) do
    if shape.type == selection then
      selectedName = shape.name
      break
    end
  end

  -- Title and blade info
  if isServer then
    if not beyblades[1].chosenShape then
      love.graphics.print("use your keyboard to select a blade and press [ENTER]", 120, 50)
    else
      love.graphics.print(selectedName .. " selected, waiting for other player", 100, 150)

      return
    end
  else
    if not beyblades[2].chosenShape then
      love.graphics.print("use your keyboard to select a blade and press [ENTER]", 120, 50)
    else
      love.graphics.print(selectedName .. " selected, waiting for other player", 100, 150)
      return
    end
  end


  local totalShapes = #shapes
  local spacing = screenWidth / (totalShapes + 1)
  local textY = 100

  for i = 1, totalShapes do
    local shape = shapes[i]
    local centerX = spacing * i

    -- Determine selection color
    if selection == shape.type then
      love.graphics.setColor(1, 0, 0) -- selected = red
    else
      love.graphics.setColor(1, 1, 1) -- not selected = white
    end

    -- Draw only text, no shape
    love.graphics.printf("[" .. i .. "] " .. shape.name, centerX - 50, textY, 100, "center")
  end
end

local function acceptRpcClient(dt)
  local data, err = udp:receive()
  if data then
    local message = json.decode(data)
    print("Received data from server: " .. message.cmd)

    if message.cmd == ServerRpcCommands.STATE_TRANSITION then
      print("Received state transition command from server")
      Gamestate.switch(ready)
      return
    end
  elseif err ~= "timeout" then
    print("Error receiving from server: " .. err)
  end
end

local function acceptRpcServer(dt)
  local data, msg_or_ip, port = udp:receivefrom()
  if data then
    local message = json.decode(data)
    print("Received command: " .. message.cmd)

    if message.cmd == ClientRpcCommands.HAS_SELECTED then
      local selection = message.selection

      print("Received selection from client: " .. selection)
      beyblades[2].chosenShape = selection
      clientHasSelected = true
    else
      print("Unknown command: " .. message.cmd)
    end
  end
end

local function sendSelectionFromClient()
  local message = {
    cmd = ClientRpcCommands.HAS_SELECTED,
    selection = beyblade.chosenShape,
  }
  print(message)

  local jsonData = json.encode(message)
  print("Sending selection to server: " .. jsonData)
  udp:send(jsonData)
end


local function sendStateTransitionRpcFromServer(dt)
  local message = {
    cmd = ServerRpcCommands.STATE_TRANSITION
  }
  local jsonData = json.encode(message)
  udp:sendto(jsonData, client.ip, client.port)
  print("Sent state transition command to client")
end

function prep:update(dt)
  if isServer then
    beyblade = beyblades[1]
    acceptRpcServer(dt)
     if clientHasSelected and serverHasSelected then
      Gamestate.switch(ready)
    end
  else
    acceptRpcClient(dt)
    beyblade = beyblades[2]
  end
  if serverHasSelected then return end
  if love.keyboard.isDown("1") then
    selection = SHAPE.STICK
  end
  if love.keyboard.isDown("2") then
    selection = SHAPE.SQUARE
  end
  if love.keyboard.isDown("3") then
    selection = SHAPE.PENTAGON
  end

  if love.keyboard.isDown("return") then
    if (selection == 0) then return end
    if isServer then
      serverHasSelected = true
      beyblades[1].chosenShape = selection
    else  
      clientHasSelected = true
      beyblades[2].chosenShape = selection
      sendSelectionFromClient()
    end
  end
end

function prep:leave()
  if isServer then
    sendStateTransitionRpcFromServer()
  end
end
