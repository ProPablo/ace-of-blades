local ServerRpcCommands = {
    RESTART = "restart",
}

gameover = {}


local function acceptRpcClient(dt)
    local data, err = udp:receive()
    if data then
        local message = json.decode(data)
        print("Received data from server: " .. message.cmd)

        if message.cmd == ServerRpcCommands.RESTART then
            print("Received state transition command from server")
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
    elseif loserId == 2 then
        winnerText = isServer and "YOU WON!" or "YOU LOST!"
        winnerColor = isServer and { 0.2, 0.8, 0.2 } or { 0.8, 0.2, 0.2 }
    else
        winnerText = "DRAW!"
        winnerColor = { 0.8, 0.8, 0.2 }
    end
end

function gameover:update(dt)
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
