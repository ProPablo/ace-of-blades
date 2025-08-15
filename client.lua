require("util")
local socket = require("socket")
require("env")

function setupClient()
    love.window.setTitle("Ace of Blades Client")

    if not serverAddress then
        serverAddress = "localhost"
    end
    print("Connecting to server at " .. serverAddress .. ":" .. port)
    udp = socket.udp()
    udp:settimeout(5) -- Block for up to 5 seconds
    local success, err = udp:setpeername(serverAddress, port)
    if not success then
        error("Error connecting to server: " .. err)
        return
    end
    -- Send join request
    local success, err = udp:send("join")
    if not success then
        error("Failed to send join request:", err)
        return
    end
    love.timer.sleep(0.5)


    print("Waiting for server...")

    -- Wait for ack
    local response = udp:receive()
    if response == "ack" then
        udp:settimeout(0) -- Set to non-blocking
        print("Connected to server!")
    else
        error("No server response")
        return
    end

    if debugMode then
        Gamestate.switch(ready)
    else
        Gamestate.switch(prep)
    end
end

-- Client-side prediction with interpolation buffering
local interpolationBuffer = {}
local updateRate = 1 / 30 -- 30 FPS
local minBufferDelay = updateRate * 2 -- Keep at least 2 updates in buffer
local bufferDelay = 0.1 -- 100ms delay
local currentTime = 0
ping = 10000

local function addToBuffer(bufferedState)
    table.insert(interpolationBuffer, bufferedState)

    -- Sort buffer by timestamp (should already be in order, but just in case)
    table.sort(interpolationBuffer, function(a, b) return a.timestamp < b.timestamp end)

    -- Remove old states (keep states within reasonable window)
    local cutoffTime = serverTime - (bufferDelay * 3) -- Keep 300ms worth
    for i = #interpolationBuffer, 1, -1 do
        if interpolationBuffer[i].timestamp < cutoffTime then
            table.remove(interpolationBuffer, i)
        end
    end
end


local function interpolateBallState(state1, state2, t)
    return {
        id = state1.id,
        health = UTIL.lerp(state1.health, state2.health, t),
        angle = UTIL.lerp(state1.angle, state2.angle, t),
        x = UTIL.lerp(state1.x, state2.x, t),
        y = UTIL.lerp(state1.y, state2.y, t),
        vx = UTIL.lerp(state1.vx, state2.vx, t),
        vy = UTIL.lerp(state1.vy, state2.vy, t),
        av = UTIL.lerp(state1.av, state2.av, t)
    }
end

local function getInterpolatedState(targetTime)
    if #interpolationBuffer < 2 then
        if #interpolationBuffer == 1 then
            return interpolationBuffer[1].balls
        else
            return {}
        end
    end

    -- Find the two states to interpolate between
    local beforeState, afterState

    for i = 1, #interpolationBuffer - 1 do
        if interpolationBuffer[i].timestamp <= targetTime and
            interpolationBuffer[i + 1].timestamp >= targetTime then
            beforeState = interpolationBuffer[i]
            afterState = interpolationBuffer[i + 1]
            break
        end
    end

    -- If no suitable pair found, use the most recent state
    if not beforeState or not afterState then
        return interpolationBuffer[#interpolationBuffer].balls
    end

    local timeDiff = afterState.timestamp - beforeState.timestamp
    if timeDiff == 0 then
        return beforeState.balls
    end

    local t = (targetTime - beforeState.timestamp) / timeDiff
    t = math.max(0, math.min(1, t)) -- Clamp between 0 and 1

    -- Interpolate all ball states
    local interpolatedBalls = {}

    -- Iterate through balls in the before state
    for ballId, beforeBall in pairs(beforeState.balls) do
        local afterBall = afterState.balls[ballId]
        if afterBall then
            interpolatedBalls[ballId] = interpolateBallState(beforeBall, afterBall, t)
        else
            -- Ball doesn't exist in after state, use before state
            interpolatedBalls[ballId] = beforeBall
        end
    end

    -- Add any balls that only exist in after state
    for ballId, afterBall in pairs(afterState.balls) do
        if not interpolatedBalls[ballId] then
            interpolatedBalls[ballId] = afterBall
        end
    end

    return interpolatedBalls
end


-- Update function to be called each frame
function updateClientPrediction(dt)
    currentTime = love.timer.getTime()

    -- Calculate target time (current time minus buffer delay)
    local targetTime = currentTime - bufferDelay
    -- currentTime = targetTime
    -- todo set this properly

    -- Get interpolated state
    local interpolatedState = getInterpolatedState(targetTime)

    -- Apply interpolated state to physics bodies
    for ballId, ballState in pairs(interpolatedState) do
        if not beyblades[ballId] then
            -- Create new ball if it doesn't exist
            beyblades[ballId] = {
                id = ballId,
                body = love.physics.newBody(world, ballState.x, ballState.y, "dynamic")
            }
        end

        local body = beyblades[ballId].body

        -- Apply interpolated state
        body:setPosition(ballState.x, ballState.y)
        body:setLinearVelocity(ballState.vx, ballState.vy)
        body:setAngularVelocity(ballState.av)
    end
end

-- Debug function to visualize buffer state
function debugBuffer()
    print("Buffer size: " .. #interpolationBuffer)
    if #interpolationBuffer > 0 then
        local oldest = interpolationBuffer[1].timestamp
        local newest = interpolationBuffer[#interpolationBuffer].timestamp
        local target = currentTime - bufferDelay
        print(string.format("Buffer range: %.3f to %.3f, target: %.3f",
            oldest, newest, target))
    end
end

function rippedAcceptBallUpdate(message)
    if not lastServerTime then
        lastServerTime = message.serverTime
        print("First server time received: " .. message.serverTime)
    end

    serverTime = message.serverTime
    ping = serverTime - lastServerTime
    bufferDelay = math.max(minBufferDelay, ping *2 ) -- Ensure we have at least 2 updates in buffer

    -- Process ball updates
    for _, ballData in ipairs(message.balls) do
        local id = ballData.id
        if not beyblades[id] then
            beyblades[id] = {
                id = id,
                body = love.physics.newBody(world, ballData.x, ballData.y, "dynamic")
            }
        end
        beyblades[id].health = ballData.health
        local body = beyblades[id].body
        body:setPosition(ballData.x, ballData.y)
        body:setLinearVelocity(ballData.vx, ballData.vy)
        body:setAngularVelocity(ballData.av)
        if ballData.angle then
            body:setAngle(ballData.angle)
        end
    end
    lastServerTime = serverTime
end
