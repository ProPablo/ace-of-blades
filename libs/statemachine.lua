-- StateMachine.lua
-- Simple State Machine for Love2D

StateMachine = {}
StateMachine.__index = StateMachine

function StateMachine:new()
    local sm = {
        currentState = nil,
        states = {},
    }
    setmetatable(sm, StateMachine)
    return sm
end

function StateMachine:addState(name, state)
    self.states[name] = state
    -- This kinda only works for person, not chicken
    state.stateMachine = self -- Give each state access to the state machine
end

function StateMachine:transitionTo(stateName, ...)
    if self.currentState and self.currentState.onExit then
        self.currentState:onExit()
    end
    
    self.currentState = self.states[stateName]
    if self.currentState and self.currentState.onEnter then
        self.currentState:onEnter(...)
    end
end

function StateMachine:update(dt)
    if self.currentState and self.currentState.update then
        self.currentState:update(dt)
    end
end

function StateMachine:draw()
    if self.currentState and self.currentState.draw then
        self.currentState:draw()
    end
end

-- Base State class
State = {}
State.__index = State

function State:new()
    local state = {}
    setmetatable(state, State)
    return state
end

function State:onEnter() end
function State:onExit() end
function State:update(dt) end
function State:draw()
    print("Drawing state: " .. self.__name)
end

return {
    StateMachine = StateMachine,
    State = State
}