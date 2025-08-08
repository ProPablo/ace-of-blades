local socket = require("socket")

function setupClient()
udp = socket.udp()
udp:settimeout(0) -- Non-blocking mode

    -- Connect to the server
    local success, err = udp:setpeername("localhost", port)
    if not success then
        print("Error connecting to server: " .. err)
    else
        print("Connected to server on port " .. port)
        -- send initial message to server
        udp:send("Hello from client")
    end

    -- Initialize client state
    balls = {} -- Initialize the balls table
    
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
            if not balls[id] then
                balls[id] = {id = id, body = love.physics.newBody(world, x, y, "dynamic")}
            end
            balls[id].body:setPosition(x, y)
        end
    elseif err ~= "timeout" then
        print("Error receiving from server: " .. err)
    end
end