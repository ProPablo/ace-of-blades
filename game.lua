local MIN_ANGV = 1

function transferSpin(fromBody, toBody)
  local fromAngularVelocity = fromBody:getAngularVelocity()
  local minBoost = 10 -- minimum spin boost to give on collision

  -- Calculate lost spin
  local lostSpin = fromAngularVelocity * 0.3 -- xfer percent
  local newFromAngularVelocity = fromAngularVelocity * 0.7

  if math.abs(newFromAngularVelocity) < MIN_ANGV then
    newFromAngularVelocity = 0
  end
  fromBody:setAngularVelocity(math.abs(newFromAngularVelocity) < MIN_ANGV and 0 or newFromAngularVelocity)

  -- Add transferred spin to toBody
  local toAngularVelocity = toBody:getAngularVelocity()
  local spinToAdd = lostSpin * transferFactor

  -- If the spin to add is very small (or zero), add a minimum boost
  if math.abs(spinToAdd) < minBoost then
    -- Keep the sign consistent with lostSpin direction
    spinToAdd = (spinToAdd >= 0) and minBoost or -minBoost
  end

  local newToAngularVelocity = toAngularVelocity + spinToAdd
  toBody:setAngularVelocity(newToAngularVelocity)
end
