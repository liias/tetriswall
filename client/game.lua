-- board

Settings = {
	rows = 22, -- the first two rows are "hidden"
	columns = 10,
	speed = 800, -- in milliseconds
	linesForNewLevel = 10
}


StateConditions = {
	PAUSED = "paused",
	RUNNING = "running",
	NOT_STARTED = "not_started"
}

Game = {
	state = {
		grid = false,
		activeTetromino = false,
		fallingTimer = nil,
		nextTetrominoIds = {},
    heldTetrominoId = nil,
    heldTetrominoInRound = false,
		score = 0,
		clearedLines = 0,
		level = 0,
		speed = 800,
		linesForNextLevel = Settings.linesForNewLevel,
		condition = StateConditions.NOT_STARTED
	},
	drawing = nil
}

function Game:new(o)
	o = o or {}   -- create object if user does not provide one
	setmetatable(o, self)
	self.__index = self
	return o
end

function Game:move(columnOffset, rowOffset, rotate)
	local t = self.state.activeTetromino
	if not t then
		return
	end

	local rotationIndex = t.rotationIndex
	if rotate then
		rotationIndex = t:getNextRotationIndex()
	end
	local row = t.yOffset+rowOffset
	local column = t.xOffset+columnOffset
	self:setShapeAndPosition(rotationIndex, row, column)
end

function Game:moveDown()
	self:move(0, 1)
end

function Game:moveLeft()
	self:move(-1, 0)
end

function Game:moveRight()
	self:move(1, 0)
end

function Game:rotateRight()
	self:move(0, 0, true)
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
		self:tryLanding()
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
	t.lowestValidRow = self.state.grid:getLowermostValidRow(t)
	return true
end

-- try moving down 1 from current
function Game:tryLanding()
	local t = self.state.activeTetromino
	if not t then
		return
	end
	local shape = t:getActiveShape()
	local nextRow = t.yOffset + 1

	if not self.state.grid:checkForCollision(shape, nextRow, t.xOffset) then
		self:handleLanding()
	end
end

function Game:setLevelFromClearedLines()
	local lines = self.state.clearedLines
	local oldLevel = self.state.level
	local levelUpdateLines = Settings.linesForNewLevel
	self.state.level = (lines - lines % levelUpdateLines) / levelUpdateLines
	self.state.linesForNextLevel = levelUpdateLines - lines % levelUpdateLines

	if self.state.level ~= oldLevel then
		self.state.speed = self:getSpeedForLevel(self.state.level)
		self:updateSpeed()
	end
end

local LEVEL_SPEED = {
	[0] = 800,
	[1] = 700,
	[2] = 600,
	[3] = 500,
	[4] = 400,
	[5] = 300,
	[6] = 200,
	[7] = 150,
	[8] = 125,
	[9] = 100,
	[10] = 75,
	[11] = 50,
	default = 50
}

function Game:getSpeedForLevel(level)
	return LEVEL_SPEED[level] or LEVEL_SPEED.default
end


-- http://tetris.wikia.com/wiki/Scoring#Original_Nintendo_Scoring_System
function Game:manageScore(clearedLines)
	self.state.clearedLines = self.state.clearedLines + clearedLines

	self:setLevelFromClearedLines()

	local n = self.state.level + 1

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
	self:tryLanding()
	self:moveDown()
end

function Game:initFallingTimer()
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
	t.lowestValidRow = self.state.grid:getLowermostValidRow(t)

	if not self.state.grid:checkForCollision(t:getActiveShape(), t.yOffset, t.xOffset) then
		self.drawing:setGameOver(true)
		outputChatBox("Tetris: GAME OVER! Press R to restart the game")
		--log("cant move already in the beginning. todo: End the game")
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
	local randomTetrominoId = math.random(1, 7)
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
    end
	end
end

function Game:reset()
	self.drawing:setGameOver(false)

	self.state.score = 0
	self:generateRandomTetrominoIds(2)

	if self.state.activeTetromino then
		self.state.activeTetromino = false
	end
	self.state.grid = Grid:new({rows=Settings.rows, columns=Settings.columns})

	self:giveNewTetromino(true)
end

function Game:updateSpeed()
	if self.state.fallingTimer then
		killTimer(self.state.fallingTimer)
		self.state.fallingTimer = nil
	end
	self:initFallingTimer()
end


function Game:start()
	self:reset()
	self:initFallingTimer()
	self.state.condition = StateConditions.RUNNING
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
end

function Game:resume()
	self.state.condition = StateConditions.RUNNING
	self:initFallingTimer()
end

function Game:resumeOrStart()
	if self.state.activeTetromino then
		self:resume()
	else
		self:start()
	end
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