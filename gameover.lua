local ServerRpcCommands = {
    RESTART = "restart",
}

gameover = {}

-- Debris system
local debris = {}
local debrisLifetime = 3.0 -- seconds before debris fades out

local function createDebrisParticle(x, y, vx, vy, particleType, baseColor)
    local particle = {
        x = x,
        y = y,
        vx = vx + (love.math.random() - 0.5) * 200, -- add some randomness
        vy = vy + (love.math.random() - 0.5) * 200,
        rotation = love.math.random() * math.pi * 2,
        rotationSpeed = (love.math.random() - 0.5) * 10,
        size = love.math.random(3, 8),
        lifetime = debrisLifetime,
        maxLifetime = debrisLifetime,
        type = particleType, -- "triangle", "circle", "rectangle"
        color = {
            math.max(0, math.min(1, baseColor[1] + (love.math.random() - 0.5) * 0.3)),
            math.max(0, math.min(1, baseColor[2] + (love.math.random() - 0.5) * 0.3)),
            math.max(0, math.min(1, baseColor[3] + (love.math.random() - 0.5) * 0.3))
        }
    }
    return particle
end

local function spawnDebrisFromBeyblade(beyblade)
    local x, y = beyblade.body:getX(), beyblade.body:getY()
    local vx, vy = beyblade.body:getLinearVelocity()
    
    -- Spawn multiple debris pieces
    local debrisCount = love.math.random(15, 25)
    local particleTypes = {"triangle", "circle", "rectangle"}
    
    for i = 1, debrisCount do
        local particleType = particleTypes[love.math.random(1, #particleTypes)]
        local particle = createDebrisParticle(x, y, vx * 0.3, vy * 0.3, particleType, beyblade.color)
        
        -- Add some spread around the original position
        particle.x = particle.x + (love.math.random() - 0.5) * circleRad
        particle.y = particle.y + (love.math.random() - 0.5) * circleRad
        
        table.insert(debris, particle)
    end
end

local function updateDebris(dt)
    for i = #debris, 1, -1 do
        local particle = debris[i]
        
        -- Update position
        particle.x = particle.x + particle.vx * dt
        particle.y = particle.y + particle.vy * dt
        
        -- Update rotation
        particle.rotation = particle.rotation + particle.rotationSpeed * dt
        
        -- Apply friction/damping
        particle.vx = particle.vx * 0.98
        particle.vy = particle.vy * 0.98
        
        -- Update lifetime
        particle.lifetime = particle.lifetime - dt
        
        -- Remove expired particles
        if particle.lifetime <= 0 then
            table.remove(debris, i)
        end
    end
end

local function drawDebris()
    for _, particle in ipairs(debris) do
        -- Calculate alpha based on remaining lifetime
        local alpha = particle.lifetime / particle.maxLifetime
        love.graphics.setColor(particle.color[1], particle.color[2], particle.color[3], alpha)
        
        love.graphics.push()
        love.graphics.translate(particle.x, particle.y)
        love.graphics.rotate(particle.rotation)
        
        if particle.type == "triangle" then
            local size = particle.size
            love.graphics.polygon("fill", 
                0, -size,
                -size * 0.866, size * 0.5,
                size * 0.866, size * 0.5
            )
        elseif particle.type == "circle" then
            love.graphics.circle("fill", 0, 0, particle.size)
        elseif particle.type == "rectangle" then
            local size = particle.size
            love.graphics.rectangle("fill", -size/2, -size/2, size, size)
        end
        
        love.graphics.pop()
    end
    
    -- Reset color
    love.graphics.setColor(1, 1, 1, 1)
end

local function acceptRpcClient(dt)
    local data, err = udp:receive()
    if data then
        local message = json.decode(data)
        print("Received data from server: " .. message.cmd)

        if message.cmd == ServerRpcCommands.RESTART then
            print("Received restart command from the server")
            Gamestate.switch(prep)
            return
        end
    elseif err ~= "timeout" then
        print("Error receiving from server: " .. err)
    end
end


local function sendStateTransitionRpcFromServer(dt)
    local message = {
        cmd = ServerRpcCommands.RESTART
    }
    local jsonData = json.encode(message)
    udp:sendto(jsonData, client.ip, client.port)
    print("Sent state transition command to client")
end


function gameover:enter()
    if isServer then
        beyblade = beyblades[1]
    else
        beyblade = beyblades[2]
    end

    if loserId == 1 then
        winnerText = isServer and "YOU LOST!" or "YOU WON!"
        winnerColor = isServer and { 0.8, 0.2, 0.2 } or { 0.2, 0.8, 0.2 }
        spawnDebrisFromBeyblade(beyblades[1])
    elseif loserId == 2 then
        winnerText = isServer and "YOU WON!" or "YOU LOST!"
        winnerColor = isServer and { 0.2, 0.8, 0.2 } or { 0.8, 0.2, 0.2 }

        spawnDebrisFromBeyblade(beyblades[2])
    else
        winnerText = "DRAW!"
        winnerColor = { 0.8, 0.8, 0.2 }
    end
end

function gameover:update(dt)

    updateDebris(dt)
    if isServer then
        if love.keyboard.isDown("r") then
            Gamestate.switch(prep)
        end
    else
        acceptRpcClient(dt)
    end
end

function gameover:leave()
    if isServer then
        sendStateTransitionRpcFromServer()
    end
end

function gameover:draw()
    -- Draw background with subtle gradient
    love.graphics.setColor(0.1, 0.1, 0.2, 0.8)
    love.graphics.rectangle("fill", 0, 0, screen.width, screen.height)


    -- Draw winner beyblade (intact)
    if loserId == 1 then
        -- Player 1 lost, so draw player 2's beyblade intact
        drawBlade(2)
    elseif loserId == 2 then
        -- Player 2 lost, so draw player 1's beyblade intact
        drawBlade(1)
    else
        -- Draw - don't draw either beyblade intact, just debris
    end
    
    -- Draw debris particles
    drawDebris()


    -- Draw winner text
    love.graphics.setColor(winnerColor)
    local font = love.graphics.newFont(48)
    love.graphics.setFont(font)
    local textWidth = font:getWidth(winnerText)
    love.graphics.print(winnerText, (screen.width - textWidth) / 2, screen.height / 2 - 50)

    -- Draw information about about what shape
    love.graphics.setColor(1, 1, 1)
    local infoText = "You were using: " .. (shapeType2String(beyblade.chosenShape))

    local infoFont = love.graphics.newFont(24)
    love.graphics.setFont(infoFont)
    local infoWidth = infoFont:getWidth(infoText)
    love.graphics.print(infoText, (screen.width - infoWidth) / 2, screen.height / 2 + 20)

    -- Draw sparkly border effect
    love.graphics.setColor(1, 1, 1, 0.3 + 0.2 * math.sin(love.timer.getTime() * 3))
    love.graphics.setLineWidth(3)
    love.graphics.rectangle("line", 20, 20, screen.width - 40, screen.height - 40)

    -- Reset graphics state
    love.graphics.reset()
end
