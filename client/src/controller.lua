-- Descriptive command names for MTA Binds menu
Commands = {
  START_STOP = "Start/stop Tetris",
  LEFT = "Move tetromino left",
  RIGHT = "Move tetromino right",
  DOWN = "Soft drop tetromino",
  HARD_DROP = "Hard drop tetromino",
  ROTATE_RIGHT = "Rotate tetromino right",
  ROTATE_LEFT = "Rotate tetromino left",
  HOLD = "Hold tetromino",
  RESET = "Start new Tetris game",
  TOGGLE_PAUSE = "Toggle pause for Tetris game",
  
  PAUSE_CURRENT_GAME = "tetris_pause"
}


local DEFAULT_BINDINGS = {
  [Commands.START_STOP] = "rshift",
	[Commands.LEFT] = "arrow_l",
	[Commands.RIGHT] = "arrow_r",
	[Commands.DOWN] = "arrow_d",
	[Commands.HARD_DROP] = "space",
	[Commands.ROTATE_RIGHT] = "arrow_u",
  [Commands.ROTATE_LEFT] = "rctrl",
  [Commands.HOLD] = "lshift",
	[Commands.RESET] = "r",
	[Commands.TOGGLE_PAUSE] = "l"
}


local DAS_CONFIG = {
	-- min is 50 ms for setTimer
	nextAutoRepeatMs = 50,
	delayAutoRepeatMs = 200
}

-- dont use it to bind/unbind anything
local function getBoundKey(command)
  local key = getKeyBoundToCommand(command)
  if not key then
    key = DEFAULT_BINDINGS[command]
  end
  return key
end

-- readable key name of key currently bound for command
function getCommandKeyName(command)
  return KEY_NAMES[getBoundKey(command)]
end

function bindCommand(command, keyState)
  if not keyState then
    keyState = "down"
  end
  
  -- add commandKeyState only if "up", so that in MTA Binds menu there would be no arguments
  local commandKeyState = nil
  if keyState == "up" then
    commandKeyState = "up"
  end
  bindKey(DEFAULT_BINDINGS[command], keyState, command, commandKeyState)
end

function unbindCommand(command, keyState)
  if not keyState then
    keyState = "down"
  end
  unbindKey(DEFAULT_BINDINGS[command], keyState, command)
end

Controller = {
	game = nil
}

function Controller:new(o)
	o = o or {}   -- create object if user does not provide one
	setmetatable(o, self)
	self.__index = self
	return o
end

function Controller:hardDrop()
	self.game:hardDrop()
end

function Controller:rotateRight()
	self.game:rotateRight()
end

function Controller:rotateLeft()
	self.game:rotateLeft()
end

function Controller:hold()
  self.game:holdCurrentTetromino()
end

function Controller:reset()
	self.game:reset()
end

function Controller:togglePause()
	self.game:togglePause()
end

function Controller:pause()
	self.game:pause()
end

function Controller:moveLeft()
	self.game:moveLeft()
end

function Controller:moveRight()
	self.game:moveRight()
end

function Controller:moveDown()
	self.game:moveDown()
end
  
local GlobalMaps = {
	gTimers = {},
	-- needed for setTimer, as real function references would get lost if passed as additional argument to setTimer
	nameFunctionMap = {}
}

-- repeatable functions, used by setTimer
function Controller:initNameFunctionMap() 
	GlobalMaps.nameFunctionMap = {
		[Commands.LEFT] = function() self:moveLeft() end,
		[Commands.RIGHT] = function() self:moveRight() end,
		[Commands.DOWN] = function() self:moveDown() end
	}
end

-- if first keystroke, start next ones with a delay, else shorter time
function getNextCallInMs(alreadyRepeated)
  if alreadyRepeated then
    return DAS_CONFIG.nextAutoRepeatMs
  else
    return DAS_CONFIG.delayAutoRepeatMs
  end
end

function repeatFunctionUntilKeyUp(command, keyState)
	if command == nil then
    log("command is nil")
    return
  end

	local timer = GlobalMaps.gTimers[command]
  local alreadyRepeated = timer and isTimer(timer)

	if keyState == "up" then
    if alreadyRepeated then
      killTimer(timer)
    end
    GlobalMaps.gTimers[command] = nil
    return
  end

  local fn = GlobalMaps.nameFunctionMap[command]
	if fn == nil then
		log("fn is nil for mappingName" .. command)
		return
	end

	fn()

  local nextCallInMs = getNextCallInMs(alreadyRepeated)

  GlobalMaps.gTimers[command] = setTimer(repeatFunctionUntilKeyUp, nextCallInMs, 1, command, keyState)
end

function handleRepeatingCommand(command)
  addCommandHandler(command, function(command, keyState) repeatFunctionUntilKeyUp(command, keyState) end)
end

function Controller:handleCmd(command, methodReference)
  addCommandHandler(command, bind(methodReference, self))
end

function Controller:bindControls()
	self:initNameFunctionMap()
  
  handleRepeatingCommand(Commands.LEFT)
  handleRepeatingCommand(Commands.RIGHT)
  handleRepeatingCommand(Commands.DOWN)

  self:handleCmd(Commands.HARD_DROP, self.hardDrop)
  self:handleCmd(Commands.ROTATE_RIGHT, self.rotateRight)
  self:handleCmd(Commands.ROTATE_LEFT, self.rotateLeft)
  self:handleCmd(Commands.HOLD, self.hold)
  self:handleCmd(Commands.RESET, self.reset)
  self:handleCmd(Commands.TOGGLE_PAUSE, self.togglePause)
  
  self:handleCmd(Commands.PAUSE_CURRENT_GAME, self.pause)

end

function Controller:unbindControls()
  removeCommandHandler(Commands.LEFT)
  removeCommandHandler(Commands.RIGHT)
  removeCommandHandler(Commands.DOWN)
  removeCommandHandler(Commands.HARD_DROP)
  removeCommandHandler(Commands.ROTATE_RIGHT)
  removeCommandHandler(Commands.ROTATE_LEFT)
  removeCommandHandler(Commands.HOLD)
  removeCommandHandler(Commands.RESET)
  removeCommandHandler(Commands.TOGGLE_PAUSE)
  
  removeCommandHandler(Commands.PAUSE_CURRENT_GAME)
end