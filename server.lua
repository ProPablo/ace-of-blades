local socket = require("socket")

function setupServer() 
    udp = socket.udp()
    udp:setsockname("localhost", port) -- Bind to localhost and the specified port
    udp:settimeout(0) -- Set to non-blocking mode
    print("Server started on port " .. port)
    balls = {} -- Initialize the balls table
    clients = {} -- Initialize the clients table

end

function acceptClient()
    -- Accept a new client connection
    local client, err = udp:receivefrom()
    if client then
        print("New client connected: " .. client)
        table.insert(clients, client)
    elseif err ~= "timeout" then
        print("Error receiving from client: " .. err)
    end
end

function sendServerUpdate()
    -- Send updates to the server
    for _, ball in ipairs(balls) do
        local data = string.format("ball %d %f %f", ball.id, ball.body:getX(), ball.body:getY())
        udp:sendto(data, "localhost", port)
    end
end

