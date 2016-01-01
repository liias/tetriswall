
Commands = {
  START_STOP = "tetris_start_stop",
  LEFT = "tetris_left",
  RIGHT = "tetris_right",
  DOWN = "tetris_down",
  HARD_DROP = "tetris_hard_drop",
  ROTATE = "tetris_rotate",
  HOLD = "tetris_hold",
  RESET = "tetris_reset",
  PAUSE = "tetris_pause",
}
    
local DEFAULT_BINDINGS = {
  [Commands.START_STOP] = "rshift",
	[Commands.LEFT] = "arrow_l",
	[Commands.RIGHT] = "arrow_r",
	[Commands.DOWN] = "arrow_d",
	[Commands.HARD_DROP] = "space",
	[Commands.ROTATE] = "arrow_u",
  [Commands.HOLD] = "lshift",
	[Commands.RESET] = "r",
	[Commands.PAUSE] = "l"
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
  bindKey(DEFAULT_BINDINGS[command], keyState, command, keyState)
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

CONFIG = {
	-- min is 50 ms for setTimer
	nextAutoScrollMs = 50,
	delayAutoScrollMs = 200
}



local GlobalMaps = {
	gTimers = {},
	-- needed for setTimer, as real function references would get lost if passed as additional argument to setTimer
	nameFunctionMap = {}
}

function repeatFunctionUntilKeyUp(mappingName, endRepeating)
	if mappingName == nil then
    log("mappingName is nil")
    return
  end

	local timer = GlobalMaps.gTimers[mappingName]

	if endRepeating then
    if isTimer(timer) then
      killTimer(timer)
    end
    return
  end

	local fn = GlobalMaps.nameFunctionMap[mappingName]
	if fn == nil then
		log("fn is nil for mappingName" .. mappingName)
		return
	end

	fn()

	-- if first keystroke, start next ones with a delay
  local nextCallInMs = CONFIG.delayAutoScrollMs
  -- else shorter time
  if isTimer(timer) then
    nextCallInMs = CONFIG.nextAutoScrollMs
  end

  --fn = function() log(fnName) end
  GlobalMaps.gTimers[mappingName] = setTimer(repeatFunctionUntilKeyUp, nextCallInMs, 1, mappingName, false)
end

function Controller:hardDrop()
	self.game:hardDrop()
end

function Controller:rotate()
	self.game:rotateRight()
end

function Controller:hold()
  self.game:holdCurrentTetromino()
end

function Controller:reset()
	self.game:reset()
end

function Controller:pause()
	self.game:togglePause()
end


-- repeatable functions, used by setTimer
function Controller:initNameFunctionMap() 
	GlobalMaps.nameFunctionMap = {
		[Commands.LEFT] = function() 
      self.game:moveLeft() 
    end,
		[Commands.RIGHT] = function()
      self.game:moveRight() 
    end,
		[Commands.DOWN] = function() 
      self.game:moveDown() 
    end
	}
end

function Controller:repeatFunc(command, keyState)
  repeatFunctionUntilKeyUp(command, keyState == "up") 
end
  
function Controller:handleCmd(command, methodReference)
  addCommandHandler(command, bind(methodReference, self))
end
  
function Controller:bindControls()
	self:initNameFunctionMap()
  
  self:handleCmd(Commands.LEFT, self.repeatFunc)
  self:handleCmd(Commands.RIGHT, self.repeatFunc)
  self:handleCmd(Commands.DOWN, self.repeatFunc)

  self:handleCmd(Commands.HARD_DROP, self.hardDrop)
  self:handleCmd(Commands.ROTATE, self.rotate)
  self:handleCmd(Commands.HOLD, self.hold)
  self:handleCmd(Commands.RESET, self.reset)
  self:handleCmd(Commands.PAUSE, self.pause)
end

function Controller:unbindControls()
  removeCommandHandler(Commands.LEFT)
  removeCommandHandler(Commands.RIGHT)
  removeCommandHandler(Commands.DOWN)
  removeCommandHandler(Commands.HARD_DROP)
  removeCommandHandler(Commands.ROTATE)
  removeCommandHandler(Commands.HOLD)
  removeCommandHandler(Commands.RESET)
  removeCommandHandler(Commands.PAUSE)
end