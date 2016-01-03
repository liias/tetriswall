
Tetromino = {
	id = false, -- to separate colours of rectangles after landing
 	rotations = {},
 	color = white,
 	shadowColor = white,

 	rotationIndex = 1, -- can be 1, 2, 3 or 4
 	xOffset = 3,
 	yOffset = 1,
 	lowestValidRow = 0,
  
  lastLandingInterruption = nil,
  lockDelayStartTimeMs = nil,
}

function Tetromino:new(o)
	o = o or {}   -- create object if user does not provide one
	setmetatable(o, self)
	self.__index = self
	return o
end

function Tetromino:setId(id)
	self.id = id
	local rgb = IdColorMap[id].rgb
	self.color = colorFromRgba(rgb, NORMAL_ALPHA)
	self.shadowColor = colorFromRgba(rgb, SHADOW_ALPHA)
end

function Tetromino:getRotationIndexWithAdded(addedRotation)
  local newRotationIndex = self.rotationIndex + addedRotation
	if newRotationIndex > 4 then
		newRotationIndex = 1
  elseif newRotationIndex < 1 then
    newRotationIndex = 4
	end
	return newRotationIndex
end

function Tetromino:getActiveShape()
	return self.rotations[self.rotationIndex]
end

function Tetromino:getRealDimensions()
	local shape = self:getActiveShape()
	local minX = 100
	local maxX = 0
	local minY = 100
	local maxY = 0
	for y, line in ipairs(shape) do
		for x, rectangle in ipairs(line) do
			if rectangle ~= 0 then
				minX = math.min(x, minX)
				maxX = math.max(x, maxX)
				minY = math.min(y, minY)
				maxY = math.max(y, maxY)
			end
		end
	end

	return {
		x = {min=minX, max=maxX}, 
		y = {min=minY, max=maxY}
	}
end

function Tetromino:interruptLanding()
  self.lastLandingInterruption = getTickCount()
end

function Tetromino:isInterruptedTooLate(timeoutMs)
  if not self.lastLandingInterruption then
    return true
  end
  
  return (getTickCount() - self.lastLandingInterruption) > timeoutMs
end

function Tetromino:hasLockDelayStarted()
  return self.lockDelayStartTimeMs ~= nil
end

function Tetromino:startLockDelay()
  self.lockDelayStartTimeMs = getTickCount()
end

-- e.g when tetromino is moved and it starts falling again
function Tetromino:resetLockDelay()
  self.lockDelayStartTimeMs = nil
end

function Tetromino:isLockDelayPassed(timeoutMs)
  if not self:hasLockDelayStarted() then
    return false
  end

  return (getTickCount() - self.lockDelayStartTimeMs) > timeoutMs
end

-- w 32 * 10 = 320
-- h 32 * 20 = 640
-- h 32 * 22 = 704

-- http://tetris.wikia.com/wiki/Tetris_Guideline
-- http://tetris.wikia
I = Tetromino:new()
I:setId(TetrominoId.I)
I.rotations = {
	{{0,0,0,0}, {1,1,1,1}, {0,0,0,0}, {0,0,0,0}},
	{{0,0,1,0}, {0,0,1,0}, {0,0,1,0}, {0,0,1,0}},
	{{0,0,0,0}, {0,0,0,0}, {1,1,1,1}, {0,0,0,0}},
	{{0,1,0,0}, {0,1,0,0}, {0,1,0,0}, {0,1,0,0}}
}


J = Tetromino:new()
J:setId(TetrominoId.J)
J.rotations = {
	{{1,0,0}, {1,1,1}, {0,0,0}},
	{{0,1,1}, {0,1,0}, {0,1,0}},
	{{0,0,0}, {1,1,1}, {0,0,1}},
	{{0,1,0}, {0,1,0}, {1,1,0}}
}

L = Tetromino:new()
L:setId(TetrominoId.L)
L.rotations = {
	{{0,0,1}, {1,1,1}, {0,0,0}},
	{{0,1,0}, {0,1,0}, {0,1,1}},
	{{0,0,0}, {1,1,1}, {1,0,0}},
	{{1,1,0}, {0,1,0}, {0,1,0}}
}

O = Tetromino:new()
O:setId(TetrominoId.O)
O.rotations = {
	{{0,1,1,0}, {0,1,1,0}, {0,0,0,0}},
	{{0,1,1,0}, {0,1,1,0}, {0,0,0,0}},
	{{0,1,1,0}, {0,1,1,0}, {0,0,0,0}},
	{{0,1,1,0}, {0,1,1,0}, {0,0,0,0}},
}

S = Tetromino:new()
S:setId(TetrominoId.S)
S.rotations = {
	{{0,1,1}, {1,1,0}, {0,0,0}},
	{{0,1,0}, {0,1,1}, {0,0,1}},
	{{0,0,0}, {0,1,1}, {1,1,0}},
	{{1,0,0}, {1,1,0}, {0,1,0}}
}

T = Tetromino:new()
T:setId(TetrominoId.T)
T.rotations = {
	{{0,1,0}, {1,1,1}, {0,0,0}},
	{{0,1,0}, {0,1,1}, {0,1,0}},
	{{0,0,0}, {1,1,1}, {0,1,0}},
	{{0,1,0}, {1,1,0}, {0,1,0}}
}

Z = Tetromino:new()
Z:setId(TetrominoId.Z)
Z.rotations = {
	{{1,1,0}, {0,1,1}, {0,0,0}},
	{{0,0,1}, {0,1,1}, {0,1,0}},
	{{0,0,0}, {1,1,0}, {0,1,1}},
	{{0,1,0}, {1,1,0}, {1,0,0}}
}


IdTetrominoClassMap = {
	[TetrominoId.I] = I,
	[TetrominoId.J] = J,
	[TetrominoId.L] = L,
	[TetrominoId.O] = O,
	[TetrominoId.S] = S,
	[TetrominoId.T] = T,
	[TetrominoId.Z] = Z
}

