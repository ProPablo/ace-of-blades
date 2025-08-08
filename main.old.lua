blocks = {}
local beyblade = {

    width = 100,
    length = 100,
    asset,
    body, -- component that holds information about the body (vel, pos, accel etc.)
    shape, -- collision (one shape many fixtures, )
    fixture -- size, scallable, drag (one body many fixtures)
}
local val = 0 -- establish a variable for later use
local x, y
-- CONSTANTS
blocksWidth = 50
valSpeed = 500
forceMod = 1000
screen = {
    height = 600,
    width = 800
}

function love.load()
    love.window.setMode(screen.width, screen.height, {
        resizable = true,
        vsync = 0,
        minwidth = screen.width,
        minheight = screen.height
    })

    love.physics.setMeter(64) -- the height of a meter our worlds will be 64px
    world = love.physics.newWorld(0, 1, true) -- create a world for the bodies to exist in with horizontal gravity of 0 and vertical gravity of 9.81

    beyblade.asset = love.graphics.newImage("bey.png")
    beyblade.body = love.physics.newBody(world, 650 / 2, 650 / 2, "dynamic") -- place the body in the center of the world and make it dynamic, so it can move around
    beyblade.shape = love.physics.newCircleShape(20) -- the ball's shape has a radius of 20
    beyblade.fixture = love.physics.newFixture(beyblade.body, beyblade.shape, 100) -- Attach fixture to body and give it a density of 1.
    beyblade.fixture:setRestitution(1) -- let the ball bounce

    -- BOX
    blocks.block1 = {}
    blocks.block1.body = love.physics.newBody(world, screen.width / 2, 0, "static")
    blocks.block1.shape = love.physics.newRectangleShape(0, 0, screen.width, blocksWidth)
    blocks.block1.fixture = love.physics.newFixture(blocks.block1.body, blocks.block1.shape, 5) -- A higher density gives it more mass.

    blocks.block2 = {}
    blocks.block2.body = love.physics.newBody(world, 0, screen.height / 2, "static")
    blocks.block2.shape = love.physics.newRectangleShape(0, 0, blocksWidth, screen.height)
    blocks.block2.fixture = love.physics.newFixture(blocks.block2.body, blocks.block2.shape, 5)

    blocks.block3 = {}
    blocks.block3.body = love.physics.newBody(world, screen.width / 2, screen.height, "static")
    blocks.block3.shape = love.physics.newRectangleShape(0, 0, screen.width, blocksWidth)
    blocks.block3.fixture = love.physics.newFixture(blocks.block3.body, blocks.block3.shape, 5) -- A higher density gives it more mass.

    blocks.block4 = {}
    blocks.block4.body = love.physics.newBody(world, screen.width, screen.height / 2, "static")
    blocks.block4.shape = love.physics.newRectangleShape(0, 0, blocksWidth, screen.height)
    blocks.block4.fixture = love.physics.newFixture(blocks.block4.body, blocks.block4.shape, 5)
end

function love.draw()

    local width = beyblade.asset:getWidth()
    local height = beyblade.asset:getHeight()
    local angle = love.timer.getTime() * 2 * math.pi / 2.5 -- Rotate one turn per 2.5 seconds.
    love.graphics.draw(beyblade.asset, beyblade.body:getX(), beyblade.body:getY(), angle, 0.1, 0.1, width / 2,
        height / 2)
    love.graphics.print(val, 100, 200)
    love.graphics.print(x, 100, 300)
    love.graphics.print(y, 100, 400)

    -- set the drawing color to grey for the blocks
    love.graphics.polygon("fill", blocks.block1.body:getWorldPoints(blocks.block1.shape:getPoints()))
    love.graphics.polygon("fill", blocks.block2.body:getWorldPoints(blocks.block2.shape:getPoints()))
    love.graphics.polygon("fill", blocks.block3.body:getWorldPoints(blocks.block3.shape:getPoints()))
    love.graphics.polygon("fill", blocks.block4.body:getWorldPoints(blocks.block4.shape:getPoints()))
    -- set the drawing color to red for the ball
    love.graphics.setColor(0.76, 0.18, 0.05)
    love.graphics.circle("fill", beyblade.body:getX(), beyblade.body:getY(), 20)
    love.graphics.reset()
end

function love.update(dt)
    world:update(dt) -- this puts the world into motion
    x, y = love.mouse.getPosition()
    if love.mouse.isDown(1) then
        val = val + dt * valSpeed -- we will increase the variable by 1 for every second the button is held down
    end
    if not love.mouse.isDown(1) then
        beyblade.body:applyForce(val*forceMod, val*forceMod)
        val = 0
    end
end
