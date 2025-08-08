function setToSecondMonitor()
    local targetMonitor = 0 -- Change this to the desired monitor number
    local desktopWidth, desktopHeight = love.window.getDesktopDimensions(targetMonitor)

    love.window.setMode(400, 400, {
        x = desktopWidth + 30,
        y = 30,
        resizable = true,
    })
end
