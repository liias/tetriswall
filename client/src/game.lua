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

local MoveType = {
  LEFT_RIGHT = 1,
  ROTATE = 2,
  SOFT_DROP = 3,
  HARD_DROP = 4,
  AUTO_DOWN = 5
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
  
  o.recording = false
  o.syncToServer = false
  o.history = {}
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

function Game:move(columnOffset, rowOffset, moveType)
  return self:moveOrRotate(columnOffset, rowOffset, false, moveType)
end

function Game:rotate(addedRotation)
  return self:moveOrRotate(0, 0, addedRotation, MoveType.ROTATE)
end


-- addedRotation should be nil, 1 or -1
function Game:moveOrRotate(columnOffset, rowOffset, addedRotation, moveType)
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
  
	if addedRotation then
		rotationIndex = t:getRotationIndexWithAdded(addedRotation)
    local shape = t.rotations[rotationIndex]
    column = self:getColumnWithWallKick(shape, row, column)
    row = self:getRowWithFloorKick(shape, row, column)
  end
  
  return self:setShapeAndPosition(rotationIndex, row, column, moveType)
end


-- no sound on automatic falling
function Game:moveDown()
	self:move(0, 1, MoveType.SOFT_DROP)
end

function Game:moveLeft()
	self:move(-1, 0, MoveType.LEFT_RIGHT)
end

function Game:moveRight()
	self:move(1, 0, MoveType.LEFT_RIGHT)
end

function Game:rotateRight()
	self:rotate(1)
end

function Game:rotateLeft()
	self:rotate(-1)
end

function Game:hardDrop()
	if not self:isRunning() then
		return false
	end

	local t = self.state.activeTetromino
	if not t then
		return
	end
	
	local wasDropped = self:setShapeAndPosition(t.rotationIndex, t.lowestValidRow, t.xOffset, MoveType.HARD_DROP)
end

function Game:isRunning()
	return self.state.condition == StateConditions.RUNNING
end

function Game:setShapeAndPosition(rotationIndex, row, column, moveType)
	if not self:isRunning() then
		return false
	end

	local t = self.state.activeTetromino
  local originalYOffset = t.yOffset

	local shape = t.rotations[rotationIndex]
  
  local success = false
  
	if self.state.grid:checkForCollision(shape, row, column) then
		success = true
    t.xOffset = column
    t.yOffset = row
    t.rotationIndex = rotationIndex
    t.lowestValidRow = self.state.grid:getLowestValidRow(t)
    
    if self.syncToServer then
      self:sendMoveToServer(moveType)
      
      -- send grid sync every 5 seconds
      local now = getTickCount()
      if getTickCount() - self.lastGridSync >= 5000 then
        self.lastGridSync = now
        -- send full grid update once-in-a-while to mitigate desync
        self:sendTetrisUpdateToServer("grid", self.state.grid.rectangles)
      end
      if getTickCount() - self.lastScoreSync >= 6000 then
        self.lastScoreSync = now
        self:sendTetrisUpdateToServer("score", self.state.score, self.state.clearedLines)
      end
    end
  
    if self.recording then
      self:recordMove(moveType)
    end
    
    if moveType == MoveType.HARD_DROP then
      self.drawing:drawHardDropEffect(t, originalYOffset)
      self:tryLanding(false)
      playAudioHardDrop()
    else
      t:interruptLanding()
      
      if moveType == MoveType.LEFT_RIGHT or moveType == MoveType.SOFT_DROP then
        playAudioMove()
      elseif moveType == MoveType.ROTATE then
        playAudioRotate()
      end
    end
  end

  if moveType == MoveType.AUTO_DOWN then
    self:tryLanding(true)
  end
      
	return success
end

-- todo: not sure if should send to server on every nth ms, or immediately on every move?
function Game:sendMoveToServer(moveType)
  local t = self.state.activeTetromino
  local delta = getTickCount()-self.historyStartTime
  local moveState = {delta, t.id, t.xOffset, t.yOffset, t.rotationIndex, moveType}

  triggerServerEvent("onSendMoveToServer", resourceRoot, moveState)
end

function Game:sendTetrisUpdateToServer(eventName, ...)
  local delta = getTickCount() - self.historyStartTime
  local packet = {eventName, delta, unpack(arg)}
  triggerServerEvent("onSendTetrisUpdateToServer", resourceRoot, packet)
end

function Game:recordMove(moveType)
  local t = self.state.activeTetromino
  local delta = getTickCount()-self.historyStartTime

  table.insert(self.history, {delta, t.id, t.xOffset, t.yOffset, t.rotationIndex, moveType})
  --table.insert(self.history, {delta, t.id, t.xOffset, t.yOffset, t.rotationIndex})
end

    --self:printHistoryToLog()
function Game:printHistoryToLog()
  for d, h in ipairs(self.history) do
    log(h[1], h[2], h[3], h[4], h[5])
    --{getTickCount(), t.id, t.xOffset, t.yOffset, t.rotationIndex})
  end
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
      if self:isLocal() then
        self:giveNewTetromino(true)
      end
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
    if self:isLocal() then
      --log("no filled lines, giving new tetromino")
      self:giveNewTetromino(true)
    end
	end
end

function Game:initFallingTimer()
  if self:isRemote() then
    return
  end
  
  self:killFallingTimer()
  
	local tickFunc = function()
    self:move(0, 1, MoveType.AUTO_DOWN)
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
    local resetKeyName = capitalize(getCommandKeyName(Commands.RESET))
		outputChatBox("Tetris: GAME OVER! Press ".. resetKeyName .." to restart the game")
    playAudioTheEnd()
    
    if self:isLocal() then
      local wasRecording = self.recording
      -- to be sure we are not recording the replay itself
      self.recording = false
      if wasRecording then
        self:saveHistoryToFile()
      end
    end
    --self:replayFromHistory()
		return false
	end

	self.state.activeTetromino = t
end




function Game:playHistoryItem(h)
  local id = h[2]
  local column = h[3]
  local row = h[4]
  local rotationIndex = h[5]
  local moveType = h[6]
  --log(h[1], h[2], h[3], h[4], h[5])

  -- todo
  t = self.state.activeTetromino
  if not t or t.id ~= id then
    t = self:newTetrominoForId(id)
    t.lowestValidRow = self.state.grid:getLowestValidRow(t)
    self.state.activeTetromino = t
  end

  self:setShapeAndPosition(rotationIndex, row, column, moveType)
end

  
function Game:replayFromHistory()
  -- to be sure we are not recording the replay itself
  self.recording = false
  self.syncToServer = false
  self:initState()
  
  log("starting to replay")
  local replayStartTime = getTickCount()
  local i = 0
  
  local function renderReplay()
    local delta = getTickCount() - replayStartTime
    
    if i < #self.history then
      local nextH = self.history[i+1]
      local nextDelta = nextH[1]
      if delta >= nextDelta then
        local h = nextH
        self:playHistoryItem(h)
        i = i + 1
      end
    else
      log("trying to stop")
      removeEventHandler("onClientRender", root, renderReplay)
      return
    end
  end
  
  addEventHandler("onClientRender", root, renderReplay)
end



function Game:saveHistoryToFile()
  if self.history then
    local historyAsJson = toJSON(self.history, true)
    local timestamp = formatTime(getRealTime())
    local filename = "replays/history-" .. timestamp .. ".json"
    local fileHandle = fileCreate(filename)
    if fileHandle then
      fileWrite(fileHandle, historyAsJson)
      fileClose(fileHandle)
      log("wrote Tetris replay to file " .. filename)
    end
  end
end

function Game:giveNewTetromino(resetHeldTetrominoUsed)
	local nextTetrominoId = table.remove(self.state.nextTetrominoIds, 1)
  if self:isLocal() then
    self:addRandomTetrominoIdsToQueue(1)
  end
	self:spawnById(nextTetrominoId)
  
  if resetHeldTetrominoUsed then
    -- allow holding (or switching) again (once per round)
    self.state.heldTetrominoInRound = false
  end
  
  if self.syncToServer then
    self:sendTetrisUpdateToServer("give", self.state.nextTetrominoIds)
  end
end

function Game:addRandomTetrominoIdsToQueue(n)
  if not n then
    n = 1
  end
  for i=1, n do
    local randomTetrominoId = self.state.bag:takeNext()
    table.insert(self.state.nextTetrominoIds, randomTetrominoId)
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
      
      if self.syncToServer then
        self:sendTetrisUpdateToServer("hold", self.state.activeTetromino.id)
      end
    
      if tetrominoIdHeldBefore then
        self:spawnById(tetrominoIdHeldBefore)
      else
        self:giveNewTetromino(false)
      end
      playAudioHold()
    end
	end
end

function Game:initState()
  self.state.heldTetrominoId = nil
	self.state.score = 0
  self.state.clearedLines = 0
  self.state.level = 1
  self.state.speed = Settings.speed
  self.state.linesForNextLevel = Settings.linesForNewLevel
  self.state.activeTetromino = false
  self.state.bag = Bag:new()
  self.state.grid = Grid:new({rows=Settings.rows, columns=Settings.columns})
end

function Game:reset()
	self.drawing:setGameOver(false)

  self:initState()
  self:initFallingTimer()
  
  --self.recording = true
  self.recording = false
  self.syncToServer = true
  
  self.history = {}
  self.historyStartTime = getTickCount()
  self.lastGridSync = 0
  self.lastScoreSync = 0
  
  if self.state.condition == StateConditions.PAUSED then
    self.state.condition = StateConditions.RUNNING
    if self:isLocal() then
      startMusic()
    end
  end
  
	self:addRandomTetrominoIdsToQueue(3)
  if self.syncToServer then
    self:sendTetrisUpdateToServer("start", self.state.nextTetrominoIds)
  end

	self:giveNewTetromino(true)
end

function Game:togglePause()
	if self.state.fallingTimer then
		self:pause()
	else
		self:resume()
	end
end

function Game:killFallingTimer()
  if self.state.fallingTimer then
		killTimer(self.state.fallingTimer)
		self.state.fallingTimer = nil
  end
end

function Game:pause()
  self.state.condition = StateConditions.PAUSED
  
	if self:isLocal() and self.state.fallingTimer then
		self:killFallingTimer()
    stopMusic()
	end
  
  if self.syncToServer then
    self:sendTetrisUpdateToServer("pause")
  end
end

function Game:isRemote()
  return self.multiplayer
end

function Game:isLocal()
  return not self:isRemote()
end

function Game:resume()
	self:initFallingTimer()
  self.state.condition = StateConditions.RUNNING
  if self:isLocal() then
    startMusic()
  end
  
  if self.syncToServer then
    self:sendTetrisUpdateToServer("resume")
  end
end

function Game:resumeOrStart()
  if not self.state.activeTetromino then
    self:reset()
  end
  self:resume()
end

-- for blip
function Game:startTetris()
  if self:isLocal() then
    self.controller:bindControls()
  end
  
	self:resumeOrStart()
	self.drawing:startDrawing()
end

function Game:stopTetris()
  self:pause()
	self.drawing:stopDrawing()
	self.controller:unbindControls()
end


function Game:initDrawingOnObject(textureName, targetObject)
	self.drawing:initDrawing(textureName, targetObject)
  
  if self:isRemote() then
    log("adding remote playfield")
    function serverSentMove(moveState)
      --log("Server sent: " .. moveState[6])
      self:playHistoryItem(moveState)
    end
    addEventHandler("onSendMoveToClient", localPlayer, serverSentMove)  
    
    function handleUpdate(eventName, packet)
      if eventName == "start" then
        local nextTetrominoIds = packet[1]
        
        self.recording = false
        self.syncToServer = false        
        self:killFallingTimer()
        self:initState()
        self.state.condition = StateConditions.RUNNING    
        self.state.nextTetrominoIds = nextTetrominoIds
        self.drawing:startDrawing()
      elseif eventName == "pause" then
        self:pause()
      elseif eventName == "resume" then
        self:resume()
      elseif eventName == "give" then
        local nextTetrominoIds = packet[1]
        self:giveNewTetromino(true)
        self.state.nextTetrominoIds = nextTetrominoIds
      elseif eventName == "hold" then
        self:holdCurrentTetromino()
      elseif eventName == "grid" then
        local rectangles = packet[1]
        self.state.grid.rectangles = rectangles
      elseif eventName == "score" then
        local score = packet[1]
        local clearedLines = packet[2]
        self.state.score = score
        self.state.clearedLines = clearedLines
        self:setLevelFromClearedLines()
      end
    end
    
    function serverSentUpdate(packet)
      local eventName = table.remove(packet, 1)
      local delta = table.remove(packet, 1)
      log("Server sent update ", eventName)
      handleUpdate(eventName, packet)
    end
    addEventHandler("onSendTetrisUpdateToClient", localPlayer, serverSentUpdate)
  end
end


addEvent("onSendMoveToClient", true)
addEvent("onSendTetrisUpdateToClient", true)
