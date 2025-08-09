
gameover = {}

function gameover:enter()
    -- Determine winner based on loserId
    if loserId == 1 then
        winnerText = isServer and "YOU LOST!" or "YOU WON!"
        winnerColor = isServer and { 0.8, 0.2, 0.2 } or { 0.2, 0.8, 0.2 }
    elseif loserId == 2 then
        winnerText = isServer and "YOU WON!" or "YOU LOST!"
        winnerColor = isServer and { 0.2, 0.8, 0.2 } or { 0.8, 0.2, 0.2 }
    else
        winnerText = "DRAW!"
        winnerColor = { 0.8, 0.8, 0.2 }
    end
end

function gameover:draw()
    -- Draw background with subtle gradient
    love.graphics.setColor(0.1, 0.1, 0.2, 0.8)
    love.graphics.rectangle("fill", 0, 0, screen.width, screen.height)
    
    -- Draw winner text
    love.graphics.setColor(winnerColor)
    local font = love.graphics.newFont(48)
    love.graphics.setFont(font)
    local textWidth = font:getWidth(winnerText)
    love.graphics.print(winnerText, (screen.width - textWidth) / 2, screen.height / 2 - 50)
    
    -- Draw sparkly border effect
    love.graphics.setColor(1, 1, 1, 0.3 + 0.2 * math.sin(love.timer.getTime() * 3))
    love.graphics.setLineWidth(3)
    love.graphics.rectangle("line", 20, 20, screen.width - 40, screen.height - 40)
    
    -- Reset graphics state
    love.graphics.reset()
end
