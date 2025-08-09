local socket = require("socket")
serverAddress = "localhost"

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
        print("Failed to send join request:", err)
        love.event.quit()
        return
    end
    
    print("Waiting for server...")
    
    -- Wait for ack
    local response = udp:receive()
    if response == "ack" then
        connected = true
        udp:settimeout(0) -- Set to non-blocking
        print("Connected to server!")
    else
        print("No server response")
        love.event.quit()
    end

    beyblades = {} -- Initialize the balls table
end

function receiveClientUpdates()
    -- Receive updates from the server
    local data, err = udp:receive()
    if data then
        local command, id, x, y = data:match("^(%S+) (%d+) (%S+) (%S+)$")
        if command == "ball" then
            id = tonumber(id)
            x = tonumber(x)
            y = tonumber(y)
            -- Update or create the ball in the balls table
            if not beyblades[id] then
                beyblades[id] = { id = id, body = love.physics.newBody(world, x, y, "dynamic") }
            end
            beyblades[id].body:setPosition(x, y)
        end
    elseif err ~= "timeout" then
        print("Error receiving from server: " .. err)
    end
end
