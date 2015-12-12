Controller = {
	state = false,
	bindFuncs = {},
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

Bindings = {
	LEFT = "arrow_l",
	RIGHT = "arrow_r",
	DOWN = "arrow_d",
	HARD_DROP = "space",
	ROTATE = "arrow_u",
  HOLD = "lshift",
	RESET = "r",
	PAUSE = "l"
}


local GlobalMaps = {
	gTimers = {},
	-- needed for setTimer, as real function references would get lost if passed as additional argument to setTimer
	nameFunctionMap = {}
}

function repeatFunctionUntilKeyUp(keyState, mappingName)
	if mappingName == nil then
  		log("mappingName is nil")
  		return
  	end

	local timer = GlobalMaps.gTimers[mappingName]

	if keyState == "up" then
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
  	GlobalMaps.gTimers[mappingName] = setTimer(repeatFunctionUntilKeyUp, nextCallInMs, 1, keyState, mappingName)
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
		moveLeft = function() 
      self.game:moveLeft() 
    end,
		moveRight = function()
      self.game:moveRight() 
    end,
		moveDown = function() 
      self.game:moveDown() 
    end
	}
end

function Controller:bindControls()
	self:initNameFunctionMap()

	self.bindFuncs.left = function(key, keyState)
		repeatFunctionUntilKeyUp(keyState, "moveLeft")
	end
	self.bindFuncs.right = function(key, keyState)
		repeatFunctionUntilKeyUp(keyState, "moveRight")
	end
	self.bindFuncs.down = function(key, keyState)
		repeatFunctionUntilKeyUp(keyState, "moveDown")
	end

	self.bindFuncs.hardDrop = function(key, keyState) 
		self:hardDrop()
	end
	self.bindFuncs.rotate = function(key, keyState) 
		self:rotate()
	end
  self.bindFuncs.hold = function(key, keyState) 
		self:hold()
	end
	self.bindFuncs.reset = function(key, keyState) 
		self:reset()
	end
	self.bindFuncs.pause = function(key, keyState) 
		self:pause()
	end

	bindKey(Bindings.LEFT, "both", self.bindFuncs.left)
	bindKey(Bindings.RIGHT, "both", self.bindFuncs.right)
	bindKey(Bindings.DOWN, "both", self.bindFuncs.down)

	bindKey(Bindings.HARD_DROP, "down", self.bindFuncs.hardDrop)
	bindKey(Bindings.ROTATE, "down", self.bindFuncs.rotate)
  bindKey(Bindings.HOLD, "down", self.bindFuncs.hold)
	bindKey(Bindings.RESET, "down", self.bindFuncs.reset)
	bindKey(Bindings.PAUSE, "down", self.bindFuncs.pause)
end

function Controller:unbindControls()
	unbindKey(Bindings.LEFT, "both", self.bindFuncs.left)
	unbindKey(Bindings.RIGHT, "both", self.bindFuncs.right)
	unbindKey(Bindings.DOWN, "both", self.bindFuncs.down)
  
	unbindKey(Bindings.HARD_DROP, "down", self.bindFuncs.hardDrop)
	unbindKey(Bindings.ROTATE, "down", self.bindFuncs.rotate)
  unbindKey(Bindings.HOLD, "down", self.bindFuncs.hold)
	unbindKey(Bindings.RESET, "down", self.bindFuncs.reset)
	unbindKey(Bindings.PAUSE, "down", self.bindFuncs.pause)
end