ServerRpcCommands = {
  STATE_TRANSITION = "stateTransition",
}
local socket = require("socket")
updateRate = 1 / 30 -- 30 fps

client = nil
function setupServer()
    love.window.setTitle("Ace of Blades Server")
    print(udp)
    udp = socket.udp()
    udp:setsockname("*", port) -- Bind to localhost and the specified port
    udp:settimeout(0)          -- Set to non-blocking mode
    print("Server started on port " .. port)
end

function acceptClient()
    -- Accept a new client connection
    local data, msg_or_ip, port = udp:receivefrom()
    if data then
        print("New client connected: " .. msg_or_ip .. ":" .. port .. " - " .. data .. "Switching to ready state")
        id = 2
        client = {
            id = id,
            ip = msg_or_ip,
            port = port,
            lastActive = love.timer.getTime()
        }

        udp:sendto("ack", client.ip, client.port)
        Gamestate.switch(ready)
    elseif msg_or_ip ~= "timeout" then
        print("Error receiving from client: " .. err)
    end
end
