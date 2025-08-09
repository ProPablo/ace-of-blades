ANGULAR_VEL = 10000



local function acceptRpcClient()
    local data, err = udp:receive()
    if data then
        for segment in data:gmatch("([^;]+)") do
            -- Try matching a ball packet: id, x, y, vx, vy, av
            local cmd, id, x, y, vx, vy, av, ap = segment:match(
                "^%s*(%S+)%s+(%d+)%s+(%S+)%s+(%S+)%s+(%S+)%s+(%S+)%s+(%S+)%s*$"
            )
            if cmd == "ball" then
                id = tonumber(id)
                x  = tonumber(x)
                y  = tonumber(y)
                vx = tonumber(vx)
                vy = tonumber(vy)
                av = tonumber(av)
                ap = tonumber(ap)
                print(string.format("Received ball: id=%d, x=%.2f, y=%.2f, vx=%.2f, vy=%.2f, av=%.2f, ap=%.2f", id, x, y, vx, vy, av, ap))

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
                body:setAngle(ap)

            else
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
