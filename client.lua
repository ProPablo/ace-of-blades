local socket = require("socket")
serverAddress = "127.0.0.1"

function setupClient()
    udp = socket.udp()
    udp:settimeout(5) -- Block for up to 5 seconds
    local success, err = udp:setpeername(serverAddress, port)
     if not success then
        error("Error connecting to server: " .. err)
        return 
     end
     -- Send join request
    local success, err = udp:send("join")
    if not success then
        error("Failed to send join request:", err)
        return
    end
    love.timer.sleep(0.1) 
    
    print("Waiting for server...")
    
    -- Wait for ack
    local response = udp:receive()
    if response == "ack" then
        udp:settimeout(0) -- Set to non-blocking
        print("Connected to server!")
        Gamestate.switch(ready)
    else
        error("No server response")
    end
end


function receiveClientUpdates()
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
