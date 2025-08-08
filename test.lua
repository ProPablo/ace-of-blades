local start = love.timer.getTime()

-- Concatenate "bar" 1000 times.
local foo = ""
for _ = 1, 1000 do
	foo = foo .. "bar"
end

-- Resulting time difference in seconds. Multiplying it by 1000 gives us the value in milliseconds.
local result = love.timer.getTime() - start
print( string.format( "It took %.3f milliseconds to concatenate 'bar' 1000 times!", result * 1000 ))