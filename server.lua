local socket = require("socket")
local updateRate = 1/ 30 -- 30 fps

client = {}
function setupServer() 
    udp = socket.udp()
    udp:setsockname("*", port) -- Bind to localhost and the specified port
    udp:settimeout(0) -- Set to non-blocking mode
    print("Server started on port " .. port)
    beyblades = {} -- Initialize the balls table
end

function acceptClient()
    -- Accept a new client connection
    local data, msg_or_ip, port = udp:receivefrom()
    if data then
        print("New client connected: " .. msg_or_ip .. ":" .. port .. " - " .. data)
        id = 2
        client = {
            id = id,
            ip = msg_or_ip,
            port = port,
            lastActive = love.timer.getTime()
        }

        print("Sending ack")
        udp:sendto("ack", client.ip, client.port)
        -- socket.sleep(0.01)
    elseif msg_or_ip ~= "timeout" then
        print("Error receiving from client: " .. err)
    end
end

local t = 0
local serverTime = love.timer.getTime( )
function sendServerUpdate(dt)
    serverTime = love.timer.getTime()
    t = t + dt 
	
	if t > updateRate then
        t = t - updateRate

        local data = ""
        for _, ball in ipairs(beyblades) do
            data = data .. string.format("ball %d %f %f;", ball.id, ball.body:getX(), ball.body:getY())
        end
        data = data .. string.format("serverTime %f", serverTime)

        if client then
            udp:sendto(data, client.ip, client.port)
            print("Sent update to client: " .. client.ip .. ":" .. client.port .. " - " .. data)
        end

    end

end

