function setToSecondMonitor()
    local targetMonitor = 0 -- Change this to the desired monitor number
    local desktopWidth, desktopHeight = love.window.getDesktopDimensions(targetMonitor)

    love.window.setMode(400, 400, {
        x = desktopWidth + 30,
        y = 30,
        resizable = true
    })
end

function drawDebug()
    love.graphics.print(val, 100, 200)
    love.graphics.print(cursorX, 100, 300)
    love.graphics.print(cursorY, 150, 300)
    love.graphics.print(startDragX, 100, 400)
    love.graphics.print(startDragY, 150, 400)
    love.graphics.print(endDragX, 100, 500)
    love.graphics.print(endDragY, 150, 500)
end
