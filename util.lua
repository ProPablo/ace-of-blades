require("env")

local function setToSecondMonitor()
    local targetMonitor = 1 -- Change this to the desired monitor number

    if not desktopWidth or not desktopHeight then
        desktopWidth, desktopHeight = love.window.getDesktopDimensions(targetMonitor)
    end

    print("Setting window to second monitor with dimensions: " .. desktopWidth .. "x" .. desktopHeight)

    love.window.setMode(800, 600, {
        -- TEMP
        x = desktopWidth + 30,
        y = 30,
        resizable = true
    })
end

local function readArgs(args)
    for i, v in ipairs(args) do
        if v == "-s" then
            isServer = true
            print("Server mode enabled")
        end
        if v == "-d" then
            debugMode = true
            print("Debug mode disabled")
        end

        -- if v == "-f" then
        --     isFakePingEnabled = true
        --     print("Fake ping enabled")
        -- end
    end

    if not isServer then
        print("Client mode enabled")
    end
end

local function lerp(a, b, t) return a + (b - a) * t end

function love.load()
    os = love.system.getOS()

    if os == "Linux" then
        print("Running on Linux — doing Linux-specific stuff.")
        -- Linux-specific code here
    elseif os == "OS X" or os == "Windows" then
        print("Running on macOS or Windows — doing something else.")
        -- macOS/Windows-specific code here
    else
        print("Running on " .. os .. " — no special handling.")
    end
end

-- Remap a value from one range to another
local function remap(value, in_min, in_max, out_min, out_max)
    return (value - in_min) / (in_max - in_min) * (out_max - out_min) + out_min
end

local function flushUdpBuffer(udp)
    while true do
        local data, ip, port = udp:receive()
        if not data then
            -- nothing left to read, break
            break
        end
        -- optionally print/log discarded packets
        print("Flushed packet from", ip, port, ":", data)
    end
end

local function drawBackground()
    love.graphics.setShader(backgroundShader)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    love.graphics.setShader()
end

local function camShake(cam, shakeScalar)
    cam.x = cam.x + math.random(- shakeScalar, shakeScalar)
    cam.y = cam.y + math.random(- shakeScalar, shakeScalar)
end

return {
    setToSecondMonitor = setToSecondMonitor,
    readArgs = readArgs,
    remap = remap,
    lerp = lerp,
    flushUdpBuffer = flushUdpBuffer,
    drawBackground = drawBackground,
    camShake = camShake,
}

