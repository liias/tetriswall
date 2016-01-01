-- board

Settings = {
	rows = 22, -- the first two rows are "hidden"
	columns = 10,
	speed = 1000, -- in milliseconds
	linesForNewLevel = 5
}


StateConditions = {
	PAUSED = "paused",
	RUNNING = "running",
	NOT_STARTED = "not_started"
}

Game = {
}

function Game:new(o)
	o = o or {}   -- create object if user does not provide one
	setmetatable(o, self)
	self.__index = self
  
  o.state = {
		grid = false,
		activeTetromino = false,
		fallingTimer = nil,
		nextTetrominoIds = {},
    heldTetrominoId = nil,
    heldTetrominoInRound = false,
		score = 0,
		clearedLines = 0,
		level = 1,
		speed = Settings.speed,
		linesForNextLevel = Settings.linesForNewLevel,
		condition = StateConditions.NOT_STARTED,
    bag = false
	}
  o.drawing = nil
	return o
end

-- simple wall kick: try one place to the right, and then one place to the left
function Game:getColumnWithWallKick(shape, row, column)
  if self.state.grid:checkForCollision(shape, row, column) then
    return column
  end
  if self.state.grid:checkForCollision(shape, row, column + 1) then
    return column + 1
  end
  if self.state.grid:checkForCollision(shape, row, column - 1) then
    return column - 1
  end
  
  -- also try 2 places, because I tetromino needs this on the left side
  if self.state.grid:checkForCollision(shape, row, column + 2) then
    return column + 2
  end
  if self.state.grid:checkForCollision(shape, row, column - 2) then
    return column - 2
  end
  
  return column
end

-- simple floor kick: try one and two places to the top
function Game:getRowWithFloorKick(shape, row, column)
  if self.state.grid:checkForCollision(shape, row, column) then
    return row
  end
  if self.state.grid:checkForCollision(shape, row - 1, column) then
    return row - 1
  end
  if self.state.grid:checkForCollision(shape, row - 2, column) then
    return row - 2
  end
  
  return row
end

function Game:move(columnOffset, rowOffset, rotate)
  if not self:isRunning() then
    return false
  end
    
	local t = self.state.activeTetromino
	if not t then
		return
	end

	local row = t.yOffset+rowOffset
	local column = t.xOffset+columnOffset
	local rotationIndex = t.rotationIndex
  
	if rotate then
		rotationIndex = t:getNextRotationIndex()
    local shape = t.rotations[rotationIndex]
    column = self:getColumnWithWallKick(shape, row, column)
    row = self:getRowWithFloorKick(shape, row, column)
  end
  
  return self:setShapeAndPosition(rotationIndex, row, column)
end

-- no sound on automatic falling
function Game:moveDown(noSound)
	if self:move(0, 1) and not noSound then
    playAudioMove()
  end  
end

function Game:moveLeft()
	if self:move(-1, 0) then
    playAudioMove()
  end
end

function Game:moveRight()
	if self:move(1, 0) then
    playAudioMove()
  end
end

function Game:rotateRight()
	if self:move(0, 0, true) then
    playAudioRotate()
  end
end

function Game:hardDrop()
	if not self:isRunning() then
		return false
	end

	local t = self.state.activeTetromino
	if not t then
		return
	end
	local originalYOffset = t.yOffset
	local wasDropped = self:setShapeAndPosition(t.rotationIndex, t.lowestValidRow, t.xOffset)

	if wasDropped then
		self.drawing:drawHardDropEffect(t, originalYOffset)
		self:tryLanding(false)
    playAudioHardDrop()
	else
		log("ok, hard drop failed. how can that happen?")
	end
end

function Game:isRunning()
	return self.state.condition == StateConditions.RUNNING
end

function Game:setShapeAndPosition(rotationIndex, row, column)
	if not self:isRunning() then
		return false
	end

	local t = self.state.activeTetromino
	local shape = t.rotations[rotationIndex]
	if not self.state.grid:checkForCollision(shape, row, column) then
		--log("nope, cant move here")
		return false
	end
	t.xOffset = column
	t.yOffset = row
	t.rotationIndex = rotationIndex
	t.lowestValidRow = self.state.grid:getLowestValidRow(t)
  
  -- todo: perhaps dont do this if hard dropped?
  t:interruptLanding()
	return true
end


-- try moving down 1 from current
function Game:tryLanding(allowLockDelay)
	local t = self.state.activeTetromino
	if not t then
		return
	end

	if not self.state.grid:checkForCollision(t:getActiveShape(), t.yOffset + 1, t.xOffset) then
    if allowLockDelay then
      if not t:hasLockDelayStarted() then
        --log("starting lock delay")
        t:startLockDelay()
      end
      
      function handleLandingIfDelayed()
        if t:isLockDelayPassed(1000) or t:isInterruptedTooLate(500) then
          local tetromino = self.state.activeTetromino
          -- need to check again if it's really landed, otherwise we might "land" it in the air after wallkick
          if tetromino and not self.state.grid:checkForCollision(tetromino:getActiveShape(), tetromino.yOffset + 1, tetromino.xOffset) then
            self:handleLanding()
          end
        else
          --log("delaying")
        end
      end
      
      setTimer(handleLandingIfDelayed, 500, 1) 
    else
      self:handleLanding()
    end
  else
    if t:hasLockDelayStarted() then
      -- if tetromino is moved during lock delay so that it starts falling again 
      -- we remove the delay limit time until next landing
      --log("resetting total lock delay")
      t:resetLockDelay()
    end
	end
end

function Game:setLevelFromClearedLines()
	local clearedLines = self.state.clearedLines
	local oldLevel = self.state.level
	local levelUpdateLines = Settings.linesForNewLevel
  local level = (clearedLines - clearedLines % levelUpdateLines) / levelUpdateLines
  level = level + 1
  
	self.state.level = level
	self.state.linesForNextLevel = levelUpdateLines - clearedLines % levelUpdateLines
	if self.state.level ~= oldLevel then
		self.state.speed = self:getSpeedForLevel(self.state.level)
		self:initFallingTimer()
	end
end

-- min is 50ms for setTimer
local LEVEL_SPEED = {
	[1] = 1000,
	[2] = 793,
	[3] = 618,
	[4] = 473,
	[5] = 355,
	[6] = 262,
	[7] = 190,
	[8] = 135,
	[9] = 94,
	[10] = 64,
	[11] = 57, -- 43, 28, 18, 11, 7
	[12] = 50,
	default = 50
}
 
function Game:getSpeedForLevel(level)
	return LEVEL_SPEED[level] or LEVEL_SPEED.default
end


-- http://tetris.wikia.com/wiki/Scoring#Original_Nintendo_Scoring_System
function Game:manageScore(clearedLines)
	self.state.clearedLines = self.state.clearedLines + clearedLines

	self:setLevelFromClearedLines()

	local n = self.state.level

	local score = 0
	if clearedLines == 1 then
		score = 40 * n
	elseif clearedLines == 2 then
		score = 100 * n
	elseif clearedLines == 3 then
		score = 300 * n
	elseif clearedLines == 4 then
		score = 1200 * n
	end

	self.state.score = self.state.score + score
end

function Game:handleLanding()
	if not self.state.activeTetromino then
		return
	end
	self.state.grid:addTetrominoToGrid(self.state.activeTetromino)
	self.state.activeTetromino = nil

	local filledLines = self.state.grid:getFilledLines()
	local numberOfFilledLines = #filledLines
	
	if numberOfFilledLines > 0 then
		self:manageScore(numberOfFilledLines)
		local removeRowsAndGiveNewTetromino = function()
			--log("animation completed, giving new tetromino")
			self.state.grid:removeRows(filledLines)
			self:giveNewTetromino(true)
		end
    if numberOfFilledLines == 4 then
      playAudioClearTetris()
    else
      playAudioClearRow()
    end
		self.drawing:flashRemovableRows(filledLines, removeRowsAndGiveNewTetromino)
		if numberOfFilledLines == 4 then
			self.drawing:startFourRowsClear()
		end
	else
		--log("no filled lines, giving new tetromino")
		self:giveNewTetromino(true)
	end
end

function Game:fallingTick()
	self:moveDown(true)
  self:tryLanding(true)
end

function Game:initFallingTimer()
  if self.state.fallingTimer then
		killTimer(self.state.fallingTimer)
		self.state.fallingTimer = nil
	end
  
	local tickFunc = function()
		self:fallingTick()
	end
	self.state.fallingTimer = setTimer(tickFunc, self.state.speed, 0)
end

function Game:newTetrominoForId(id)
	return IdTetrominoClassMap[id]:new()
end

function Game:spawnById(id)
	self.state.activeTetromino = nil

	local t = self:newTetrominoForId(id)
	t.lowestValidRow = self.state.grid:getLowestValidRow(t)

	if not self.state.grid:checkForCollision(t:getActiveShape(), t.yOffset, t.xOffset) then
		self.drawing:setGameOver(true)
		outputChatBox("Tetris: GAME OVER! Press R to restart the game")
    playAudioTheEnd()
		return false
	end

	self.state.activeTetromino = t
end

function Game:giveNewTetromino(resetHeldTetrominoUsed)
	local nextTetrominoId = table.remove(self.state.nextTetrominoIds, 1)
	self:addRandomTetrominoIdToQueue()
	self:spawnById(nextTetrominoId)
  
  if resetHeldTetrominoUsed then
    -- allow holding (or switching) again (once per round)
    self.state.heldTetrominoInRound = false
  end
end

function Game:addRandomTetrominoIdToQueue()
	local randomTetrominoId = self.state.bag:takeNext()
	table.insert(self.state.nextTetrominoIds, randomTetrominoId)
end

function Game:generateRandomTetrominoIds(n)
	for i=1, n do
		self:addRandomTetrominoIdToQueue()
	end
end

function Game:setHeldTetrominoId(tetrominoId)
  self.state.heldTetrominoId = tetrominoId
  self.state.heldTetrominoInRound = true
end

function Game:holdCurrentTetromino()
  if not self:isRunning() then
    return false
  end
  
  if self.state.activeTetromino then
    if self.state.heldTetrominoInRound then
      self.drawing:startTetrominoAlreadyHeld()
    else
      local tetrominoIdHeldBefore = self.state.heldTetrominoId
      self:setHeldTetrominoId(self.state.activeTetromino.id)
      if tetrominoIdHeldBefore then
        self:spawnById(tetrominoIdHeldBefore)
      else
        self:giveNewTetromino(false)
      end
      playAudioHold()
    end
	end
end

function Game:reset()
	self.drawing:setGameOver(false)

  self.state.heldTetrominoId = nil
	self.state.score = 0
  self.state.clearedLines = 0
  self.state.level = 1
  self.state.speed = Settings.speed
  self.state.linesForNextLevel = Settings.linesForNewLevel
  self:initFallingTimer()
  
  self.state.bag = Bag:new()
  
	self:generateRandomTetrominoIds(3)

	if self.state.activeTetromino then
		self.state.activeTetromino = false
	end
	self.state.grid = Grid:new({rows=Settings.rows, columns=Settings.columns})

	self:giveNewTetromino(true)
end

function Game:togglePause()
	if self.state.fallingTimer then
		self:pause()
	else
		self:resume()
	end
end

function Game:pause()
	self.state.condition = StateConditions.PAUSED
	if self.state.fallingTimer then
		killTimer(self.state.fallingTimer)
		self.state.fallingTimer = nil
	end
  stopMusic()
end

function Game:resume()
	self:initFallingTimer()
  self.state.condition = StateConditions.RUNNING
  startMusic()
end

function Game:resumeOrStart()
  if not self.state.activeTetromino then
    self:reset()
  end
  self:resume()
end


-- for blip
function Game:startTetris()
	self.controller:bindControls()	
	self:resumeOrStart()
	self.drawing:startDrawing()
end

function Game:stopTetris()
	self.drawing:stopDrawing()
	self:pause()
	self.controller:unbindControls()
end