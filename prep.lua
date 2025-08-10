local ClientRpcCommands = {
  HAS_SELECTED = "selected",
}

local ServerRpcCommands = {
  STATE_TRANSITION = "transitionfromPrep",
  HAS_SELECTED = "selected",
}

local selection = 0

local function prepBeyblade(newBlade)
  newBlade.hasUlt = true
  newBlade.health = beybladeMaxHealth

  if newBlade.id == 1 then
    newBlade.direction = 1  -- 1 for clockwise, -1 for counter-clockwise
  else
    newBlade.direction = -1 -- 1 for clockwise, -1 for counter-clockwise
  end
end

local function prepBladeVisual(newBlade)
  if newBlade.id == 1 then
    newBlade.color = serverBladeColor
  else
    newBlade.color = clientBladeColor
  end


  if newBlade.chosenShape == SHAPE.STICK then
    newBlade.stickShape = love.physics.newRectangleShape(0, circleRad, 20, 100, 0)
    newBlade.circleShape = love.physics.newCircleShape(circleRad)
  end
  if newBlade.chosenShape == SHAPE.CIRCLE then
    newBlade.circleShape = love.physics.newCircleShape(circleRad)
  end
  if newBlade.chosenShape == SHAPE.PENTAGON then
    -- This is hardcoded with a pentagon circumscribed around a circle of radius 35

    local pentPoints = {
      0, 17.5,
      16.64349, 5.40780,
      10.28624, -14.15780,
      -10.28624, -14.15780,
      -16.64349, 5.408
    }
    pentScale = 2.0 -- scale factor to adjust size
    for i = 1, #pentPoints do
      pentPoints[i] = pentPoints[i] * pentScale
    end

    newBlade.pentagonShape = love.physics.newPolygonShape(
      pentPoints
    )
  end
end

local function prepBladePhyics(newBlade)
  -- Based on the chosen shape and params setup the physics of the blade
  newBlade.body = love.physics.newBody(world, originX, originY, "dynamic")
  newBlade.body:setAngularDamping(0.5) -- slows spin over time
  newBlade.body:setLinearDamping(0.2)  -- slows movement over time
  newBlade.fixtures = {}

  -- Based on the chosen shape, set the shape of the beyblade
  if newBlade.chosenShape == SHAPE.STICK then
    table.insert(newBlade.fixtures, love.physics.newFixture(newBlade.body, newBlade.stickShape, 100))
    table.insert(newBlade.fixtures, love.physics.newFixture(newBlade.body, newBlade.circleShape, 100))
  elseif newBlade.chosenShape == SHAPE.CIRCLE then
    table.insert(newBlade.fixtures, love.physics.newFixture(newBlade.body, newBlade.circleShape, 100))
  elseif newBlade.chosenShape == SHAPE.PENTAGON then
    table.insert(newBlade.fixtures, love.physics.newFixture(newBlade.body, newBlade.pentagonShape, 100))
  end

  for index, fixture in ipairs(newBlade.fixtures) do
    fixture:setRestitution(1)
    fixture:setDensity(0)
    fixture:setFriction(friction)
    -- if newBlade.id == 1 then
    --   fixture:setCategory(PHYSICS_CATEGORIES.SERVER_BEYBLADE)
    -- else
    --   fixture:setCategory(PHYSICS_CATEGORIES.CLIENT_BEYBLADE)
    -- end
    fixture:setCategory(PHYSICS_CATEGORIES.BEYBLADE)

    fixture:setUserData(newBlade)
  end
end


function prep:enter()

  world = love.physics.newWorld(0, 0, true)
  beyblades = {}
  beyblades[1] = { id = 1 }
  beyblades[2] = { id = 2 }
  prepBeyblade(beyblades[1])
  prepBeyblade(beyblades[2])
  setupBlocks()

end

function prep:draw()
  -- Shape options (only text now)
  love.graphics.reset()

  love.graphics.setColor(1, 1, 1) -- Reset color to white
  local screenWidth = love.graphics.getWidth()
  local selectedName = "None"
  for _, shape in ipairs(shapesInfo) do
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


  local totalShapes = #shapesInfo
  local spacing = screenWidth / (totalShapes + 1)
  local textY = 100

  for i = 1, totalShapes do
    local shape = shapesInfo[i]
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
      print("Received state transition command from  to go to ready")
      Gamestate.switch(ready)
      return
    end

    if message.cmd == ServerRpcCommands.HAS_SELECTED then
      local selection = message.selection

      print("Received selection from server: " .. selection)
      beyblades[1].chosenShape = selection
    else
      print("Unknown command: " .. message.cmd)
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

local function sendSelectionFromServer()
  local message = {
    cmd = ServerRpcCommands.HAS_SELECTED,
    selection = beyblade.chosenShape,
  }
  print(message)

  local jsonData = json.encode(message)
  udp:sendto(jsonData, client.ip, client.port)
  print("Sent selection to client: " .. jsonData)
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
    if beyblades[1].chosenShape and beyblades[2].chosenShape then
      Gamestate.switch(ready)
    end
  else
    acceptRpcClient(dt)
    beyblade = beyblades[2]
  end
  if isServer and beyblades[1].chosenShape then return end
  if not isServer and beyblades[2].chosenShape then return end

  -- Handle keyboard input for shape selection if not selected
  if love.keyboard.isDown("1") then
    selection = SHAPE.STICK
  end
  if love.keyboard.isDown("2") then
    selection = SHAPE.CIRCLE
  end
  if love.keyboard.isDown("3") then
    selection = SHAPE.PENTAGON
  end

  if love.keyboard.isDown("return") then
    if (selection == 0) then return end
    if isServer then
      serverHasSelected = true
      beyblades[1].chosenShape = selection
      sendSelectionFromServer()
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

  prepBladeVisual(beyblades[1])
  prepBladePhyics(beyblades[1])


  prepBladeVisual(beyblades[2])
  prepBladePhyics(beyblades[2])
end
