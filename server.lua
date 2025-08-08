local socket = require("socket")
local updateRate = 1000/ 30 -- 30 fps

function setupServer() 
    udp = socket.udp()
    udp:setsockname("*", port) -- Bind to localhost and the specified port
    udp:settimeout(0) -- Set to non-blocking mode
    print("Server started on port " .. port)
    balls = {} -- Initialize the balls table
    -- clients = {} -- Initialize the clients table
    client = nil

end

function acceptClient()
    -- Accept a new client connection
    local data, msg_or_ip, port = udp:receivefrom()
    if data then
        print("New client connected: " .. msg_or_ip .. ":" .. port .. " - " .. data)
        -- id = #clients + 1 -- Assign a new ID to the client
        id = 2
        client = {
            id = id,
            ip = msg_or_ip,
            port = port,
            lastActive = love.timer.getTime()
        }
        -- table.insert(clients, client)
    elseif msg_or_ip ~= "timeout" then
        print("Error receiving from client: " .. err)
    end
end

local t = 0
local serverTime = love.timer.getTime( )
function sendServerUpdate(dt)
    -- update beyblade from her fore now
    -- TODO fix
    balls[1] = {
        id = 1,
        x = beyblade.body:getX(),
        y  = beyblade.body:getY(),
    }
    
    serverTime = love.timer.getTime()
    t = t + dt 
	
	if t > updateRate then
        local data = ""
        for _, ball in ipairs(balls) do
            data = data .. string.format("ball %d %f %f;", ball.id, ball.x, ball.y)
        end
        data = data .. string.format("serverTime %f", serverTime)

        if client then
            udp:sendto(data, client.ip, client.port)
            print("Sent update to client: " .. client.ip .. ":" .. client.port .. " - " .. data)
        end

    end

end

