-- Run this to hot reload
-- nodemon --exec "love ." --ext lua --ignore node_modules
loserId = nil

isServer = false
port = 12345
udp = {}
isFakePingEnabled = false

-- FORCE VALUES
val = 0 -- establish a variable for later use
cursorX, cursorY = 0
startDragX = 0
startDragY = 0
endDragX = 0
endDragY = 0
forceMod = 100000

beyblades = {}
debugMode = false

serverTime = 0
startCountdownTime = 0
gamestartTime = 0
json = require("libs.dkjson.dkjson")
world = nil

function love.load(args)
    if arg[#arg] == "-debug" then
        require("mobdebug").start()
    end
    require("blade")
    require("lobby")
    require("blocks")
    require("prep")
    require("ready")
    require("countdown")
    require("ripped")
    require("game")
    require("gameover")
    UTIL = require("util")

    UTIL.readArgs(args)

    Gamestate = require("libs/hump/gamestate")
    vector = require "libs.hump.vector"
    screen = {
        width = love.graphics.getWidth(),
        height = love.graphics.getHeight()
    }

    -- https://stackoverflow.com/questions/15095909/from-rgb-to-hsv-in-opengl-glsl
    -- https://www.shadertoy.com/view/wXVXDK
    -- init shader
    backgroundShader = love.graphics.newShader [[
        extern number iTime = 0;
        vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords ){
            vec2 screen_size = vec2(love_ScreenSize.x, love_ScreenSize.y);
            vec2 norm_coords = (screen_coords / screen_size);
            vec3 col = 0.5 + 0.5 * cos(iTime + norm_coords.xyx + vec3(0.0, 2.0, 4.0));
            float gray = dot(col, vec3(0.299, 0.587, 0.114));
            col = mix(vec3(gray), col, 0.2);
            return vec4(col, 1.0);
            }
    ]]

    camera = require("libs/hump/camera")
    camera = camera()

    Gamestate.registerEvents()
    Gamestate.switch(lobby)

end

function love:update(dt)
    serverTime = love.timer.getTime()
    backgroundShader:send("iTime", serverTime)

    if isServer then 
        if love.keyboard.isDown("p") then
            isFakePingEnabled = not isFakePingEnabled
        end

    end
end
