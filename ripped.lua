local ServerRpcCommands = {
  SERVER_TIME = "serverTime",
  BALL_UPDATE = "ballUpdate",
  GAME_OVER = "gameOver",
}

local ClientRpcCommands = {
  ULT = "ult"
}

local function sendCommandFromClient()
  local message = {
    shape = beyblade[2].chosenShape
  }

  local jsonData = json.encode(message)
  print("Sending ult to server: " .. jsonData)
  udp:send(jsonData)
end

local function acceptRpcClient()
  local data, err = udp:receive()
  if data then
    local message = json.decode(data)

    if message.cmd == ServerRpcCommands.BALL_UPDATE then
      -- Update server time
      if message.serverTime then
        serverTime = message.serverTime
      end

      -- Process ball updates
      for _, ballData in ipairs(message.balls) do
        local id = ballData.id
        if not beyblades[id] then
          beyblades[id] = {
            id = id,
            body = love.physics.newBody(world, ballData.x, ballData.y, "dynamic")
          }
        end
        beyblades[id].health = ballData.health
        local body = beyblades[id].body
        body:setPosition(ballData.x, ballData.y)
        body:setLinearVelocity(ballData.vx, ballData.vy)
        body:setAngularVelocity(ballData.av)
        if ballData.angle then
          body:setAngle(ballData.angle)
        end
      end
    end

    if message.cmd == ServerRpcCommands.GAME_OVER then
      loserId = message.loserId
      Gamestate.switch(gameover)
      return
    end
  elseif err ~= "timeout" then
    print("Error receiving from server: " .. err)
  end
end

local t = 0
local serverTime = love.timer.getTime()
local function serverSendPosUpdate(dt)
  serverTime = love.timer.getTime()
  t = t + dt

  if t > updateRate then
    t = t - updateRate

    local ballData = {}
    for _, localBlade in ipairs(beyblades) do
      local vx, vy = localBlade.body:getLinearVelocity()
      local av = localBlade.body:getAngularVelocity()
      table.insert(ballData, {
        id = localBlade.id,
        x = localBlade.body:getX(),
        y = localBlade.body:getY(),
        vx = vx,
        vy = vy,
        av = av,
        angle = localBlade.body:getAngle(),
        health = localBlade.health
      })
    end

    local updateMessage = {
      cmd = ServerRpcCommands.BALL_UPDATE,
      balls = ballData,
      serverTime = serverTime
    }

    local jsonData = json.encode(updateMessage)

    if client then
      udp:sendto(jsonData, client.ip, client.port)
    end
  end
end


-- Collision callback
local function beginContact(a, b, coll)
  print("Collision detected between " .. a:getCategory() .. " and " .. b:getCategory())

  if a:getCategory() == PHYSICS_CATEGORIES.WALL and b:getCategory() == PHYSICS_CATEGORIES.BEYBLADE then
    local beyblade = b:getUserData()
    if beyblade then
      beyblade.direction = -beyblade.direction
      beyblade.health = beyblade.health - 1
    end
  elseif b:getCategory() == PHYSICS_CATEGORIES.WALL and a:getCategory() == PHYSICS_CATEGORIES.BEYBLADE then
    local beyblade = a:getUserData()
    if beyblade then
      beyblade.direction = -beyblade.direction
      beyblade.health = beyblade.health - 1
    end
  elseif a:getCategory() == PHYSICS_CATEGORIES.BEYBLADE and b:getCategory() == PHYSICS_CATEGORIES.BEYBLADE then
    local beybladeA = a:getUserData()
    local beybladeB = b:getUserData()
    if beybladeA and beybladeB then
      beybladeA.direction = -beybladeA.direction
      beybladeB.direction = -beybladeB.direction
      beybladeA.health = beybladeA.health - 1
      beybladeB.health = beybladeB.health - 1
    end
  end
end


function ripped:enter()
  loserId = nil
  if isServer then
    beyblades[1].body:applyForce(beyblades[1].launchVec.x, beyblades[1].launchVec.y)

    beyblades[2].body:applyForce(beyblades[2].launchVec.x, beyblades[2].launchVec.y)
    -- beyblades[2].health = 20

    world:setCallbacks(beginContact)
  else
  end
end

function ripped:draw()
  drawBlocks()

  drawBlade(1)
  drawBlade(2)
  local winWidth = love.graphics.getWidth()
  love.graphics.setColor(1, 0, 0)
  love.graphics.print(math.floor(beyblades[1].health + 0.5), winWidth / 4, 250, 0, 2, 2)
  love.graphics.setColor(0, 0, 1)
  love.graphics.print(math.floor(beyblades[2].health + 0.5), winWidth * (3 / 4), 250, 0, 2, 2)
  love.graphics.setColor(1, 1, 1)
end

beybladeDOT = 5
MAX_ANGULAR_VEL = 50

local function sendGameOverRpcFromServer()
  local message = {
    cmd = ServerRpcCommands.GAME_OVER,
    loserId = loserId
  }
  local jsonData = json.encode(message)
  udp:sendto(jsonData, client.ip, client.port)
  print("Sent game over command to client")
end

local function updateBeyblade(dt, id)
  local localBeyblade = beyblades[id]
  localBeyblade.health = localBeyblade.health - dt * beybladeDOT
  local remappedAv = remap(localBeyblade.health, 0, beybladeMaxHealth, 0, MAX_ANGULAR_VEL)
  localBeyblade.body:setAngularVelocity(remappedAv * localBeyblade.direction)

  if localBeyblade.health <= 0 then
    localBeyblade.loser = true
  end
end

local function checkLoseCondition()
  if not isServer then
    return
  end
  local beyblade1 = beyblades[1]
  local beyblade2 = beyblades[2]

  if beyblade1.health <= 0 and beyblade2.health <= 0 then
    loserId = 0 -- Draw
  elseif beyblade1.health <= 0 then
    loserId = 1 -- Player 1 lost
  elseif beyblade2.health <= 0 then
    loserId = 2 -- Player 2 lost
  end

  if loserId ~= nil then
    sendGameOverRpcFromServer()
    Gamestate.switch(gameover)
  end
end

local CHASE_FORCE = 5000 -- tweak for strength

local function moveTowardsOpponentInstant(b1, b2)
  local dx = b2.body:getX() - b1.body:getX()
  local dy = b2.body:getY() - b1.body:getY()
  local dist = math.sqrt(dx * dx + dy * dy)
  if dist > 0 then
    local fx = (dx / dist) * CHASE_FORCE
    local fy = (dy / dist) * CHASE_FORCE
    b1.body:applyLinearImpulse(fx, fy)
  end
end

function ripped:update(dt)
  world:update(dt)
  if isServer then
    updateBeyblade(dt, 1)
    updateBeyblade(dt, 2)

    moveTowardsOpponentInstant(beyblades[1], beyblades[2])
    moveTowardsOpponentInstant(beyblades[2], beyblades[1])

    checkLoseCondition()


    serverSendPosUpdate(dt)
  else
    -- sendCommandFromClient()
    acceptRpcClient()
  end
end
