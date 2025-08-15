lobby = {}

function lobby:enter()
  -- Initialize menu state
  love.graphics.setBackgroundColor(0.2, 0.2, 0.2)  -- Set background color
  love.graphics.setFont(love.graphics.newFont(20)) -- Set font size
  love.window.setTitle("Ace of Blades")
  if isServer then
    require("server")
    setupServer()
  else
    require("client")
    love.timer.sleep(0.1)
    setupClient()
    UTIL.setToSecondMonitor()
  end

  UTIL.flushUdpBuffer(udp)
end

function lobby:draw()
  love.graphics.setColor(1, 1, 1) -- Set color to white
  love.graphics.print("Welcome to Ace of Blades!" .. (isServer and " (Server Mode)" or " (Client Mode)"), 100, 150)
end

function lobby:update(dt)
  if isServer then
    acceptClient()
  else
  end
end
