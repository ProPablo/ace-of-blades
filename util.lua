function setToSecondMonitor()
    local targetMonitor = 1 -- Change this to the desired monitor number
    local desktopWidth, desktopHeight = love.window.getDesktopDimensions(targetMonitor)
    print("Setting window to second monitor with dimensions: " .. desktopWidth .. "x" .. desktopHeight)

    love.window.setMode(800, 600, {
        x = desktopWidth + 30,
        y = 30,
        resizable = true
    })
end

function readArgs(args)
    for i, v in ipairs(args) do
        if v == "-s" then
            isServer = true
            print("Server mode enabled")
        end
        if v == "-d" then
            debugMode = true
            print("Debug mode disabled")
        end
    end

    if not isServer then
        print("Client mode enabled")
    end
end

function drawDebug()
    love.graphics.print(val, 100, 200)
    love.graphics.print(timer, 100, 100)
end


function lerp(a, b, t) return a + (b - a) * t end