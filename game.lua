local MIN_ANGV = 1

function bladeHitWall(localblade)
  local currentAngularVelocity = localblade:getAngularVelocity()
  local reductionFactor = 0.99 -- for wall
  local newAngularVelocity = currentAngularVelocity * reductionFactor
  if (math.abs(newAngularVelocity) < MIN_ANGV) then
    newAngularVelocity = 0
  else
    localblade:setAngularVelocity(newAngularVelocity)
  end
end

function transferSpin(fromBody, toBody)
  local fromAngularVelocity = fromBody:getAngularVelocity()
  local minBoost = 10           -- minimum spin boost to give on collision

  -- Calculate lost spin
  local lostSpin = fromAngularVelocity * 0.3  -- xfer percent
  local newFromAngularVelocity = fromAV * 0.7

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

-- Collision callback
function beginContact(a, b, coll)
  local bodyA = a:getBody()
  local bodyB = b:getBody()
  -- Check if either body is a Beyblade
  local isBodyABeyblade = (bodyA == beyblade.body)
  local isBodyBBeyblade = (bodyB == beyblade.body)

  if isBodyABeyblade and isBodyBBeyblade then
    -- Both are beyblades, transfer spin both ways
    transferSpin(bodyA, bodyB)
    transferSpin(bodyB, bodyA)
  elseif isBodyABeyblade then
    bladeHitWall(bodyA)
  elseif isBodyBBeyblade then
    bladeHitWall(bodyB)
  end
end
