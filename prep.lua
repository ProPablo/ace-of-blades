local selection = 0

function prep:enter()
  beyblades = {}
  beyblades[1] = setupBlade(1) -- Server's beyblade
  beyblades[2] = setupBlade(2) -- Client's beyblade
  beyblades[1].shape = SHAPE.STICK
end

function prep:draw()
  local screenWidth = love.graphics.getWidth()

  -- Title and blade info
  if isServer then
    love.graphics.print(beyblades[1].id, 100, 50)
  else
    love.graphics.print(beyblades[2].id, 100, 50)
  end
  love.graphics.print("Select your blade!!", 120, 50)

  -- Shape options
  local shapes = {
    { name = "1. Stick",    type = SHAPE.STICK },
    { name = "2. Square",   type = SHAPE.SQUARE },
    { name = "3. Pentagon", type = SHAPE.PENTAGON }
  }

  -- Calculate equal spacing
  local totalShapes = #shapes
  local spacing = screenWidth / (totalShapes + 1)
  local yPos = 100

  for i = 1, totalShapes do
    local shape = shapes[i]
    if selection == shape.type then
      love.graphics.setColor(1, 0, 0)
    else
      love.graphics.setColor(1, 1, 1)
    end
    love.graphics.printf(shape.name, spacing * i - 50, yPos, 100, "center")
    love.graphics.setColor(1, 1, 1)
  end
end

function prep:update(dt)
  if isServer then
    beyblade = beyblades[1]
  else
    beyblade = beyblades[2]
  end
  if love.keyboard.isDown("1") then
    selection = SHAPE.STICK
  end
  if love.keyboard.isDown("2") then
    selection = SHAPE.SQUARE
  end
  if love.keyboard.isDown("3") then
    selection = SHAPE.PENTAGON
  end

  if love.keyboard.isDown("return") then
    if beyblade.shape ~= selection then
      beyblade.shape = selection
      print("Shape changed to: " .. selection)
    end
    Gamestate.switch(ready)
  end
end
