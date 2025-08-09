ANGULAR_VEL = 10000

local ServerRpcCommands = {
  SERVER_TIME = "serverTime",
  BALL_UPDATE = "ballUpdate",
}

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

        local body = beyblades[id].body
        body:setPosition(ballData.x, ballData.y)
        body:setLinearVelocity(ballData.vx, ballData.vy)
        body:setAngularVelocity(ballData.av)
        if ballData.angle then
          body:setAngle(ballData.angle)
        end
      end
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
        for _, ball in ipairs(beyblades) do
            local vx, vy = ball.body:getLinearVelocity()
            local av = ball.body:getAngularVelocity()
            table.insert(ballData, {
                id = ball.id,
                x = ball.body:getX(),
                y = ball.body:getY(),
                vx = vx,
                vy = vy,
                av = av,
                angle = ball.body:getAngle()
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


function ripped:enter()
  if isServer then
    beyblades[1].body:applyForce(beyblades[1].launchVec.x, beyblades[1].launchVec.y)
    beyblades[1].body:setAngularVelocity(ANGULAR_VEL)

    beyblades[2].body:applyForce(beyblades[2].launchVec.x, beyblades[2].launchVec.y)
    beyblades[2].body:setAngularVelocity(ANGULAR_VEL)
  else
  end
end

function ripped:draw()
  drawDebug()
  drawBlocks()

  drawBlade(1)
  drawBlade(2)

  love.graphics.print("Ripped...", screen.width / 2, 200, 0, 2, 2)
  if loserId then
    love.graphics.print(string.format("Loser: %.2f", loserId), screen.width / 2, 220, 0, 2, 2)
  end
end

function ripped:update(dt)
  world:update(dt)
  if (loserId) then
    for _, localblade in pairs(beyblades) do
      localblade.body:setAngularVelocity(0)
      localblade.body:setLinearVelocity(0, 0)
    end
  end
  if (love.keyboard.isDown("r")) then
    Gamestate.switch(ready)
  end
  for _, localblade in pairs(beyblades) do
    local spin = localblade.body:getAngularVelocity()
    local vx, vy = localblade.body:getLinearVelocity()
    if vx == 0 then
      -- loserId = localblade.id
    end

    if math.abs(spin) > 0.1 then
      local speed = math.sqrt(vx * vx + vy * vy)
      local dirAngle = (speed > 1) and math.atan2(vy, vx) or localblade.body:getAngle()
      local moveAngle = dirAngle + (spin > 0 and math.pi / 2 or -math.pi / 2)

      local spinForce = spin * 5 -- start big to see effect
      local fx = math.cos(moveAngle) * spinForce
      local fy = math.sin(moveAngle) * spinForce

      localblade.body:applyForce(fx, fy)
    end

    local damping = 0.05
    if math.abs(spin) > 50 then
      damping = 0.02
    end
    localblade.body:setLinearDamping(damping)
  end

  if isServer then
    serverSendPosUpdate(dt)
  else
    acceptRpcClient()
  end
end
