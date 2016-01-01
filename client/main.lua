-------------------------



GameMarker = {
  game = false,
  pos = {x=0, y=0, z=0},
  isLocalPlayerInMarker = false,
  isRunning = false,
  TETRIS_START_STOP_CMD = "whatever"
}

local START_STOP_KEY_NAME = "right shift"
local START_STOP_KEY = "rshift"

function GameMarker:new(o)
	o = o or {}   -- create object if user does not provide one
	setmetatable(o, self)
	self.__index = self
	return o
end

function GameMarker:createTetrisWall(x, y, z)
  self.pos = {x=x, y=y,z=z}
	local tetrisObject = self:createTetrisWallObject()
	self.game.drawing:initDrawing("bobo_2", tetrisObject)
	self:setupMarker()
end

function GameMarker:createTetrisWallObject()
  local x, y, z = self.pos.x, self.pos.y, self.pos.z
	-- Create object with model 4729 (billboard)
	local tetrisObject = createObject(4729, x, y, z, 70, 270, 326)
  setObjectBreakable(tetrisObject, false)
	setElementDoubleSided(tetrisObject, true)
	setObjectScale(tetrisObject, 0.5)
  -- setObjectScale does not effect collisions, so remove the collision
  setElementCollisionsEnabled(tetrisObject, false)
	return tetrisObject
end




function GameMarker:tetrisMarkerHit(hitPlayer, matchingDimension)
  if hitPlayer ~= localPlayer or not matchingDimension then
    return
  end

  if self.game == nil then
    log("tetrisMarkerHit: game is nil")
    return
  end

  self.isLocalPlayerInMarker = true
  addCommandHandler(self.TETRIS_START_STOP_CMD, function() self:startOrStopTetris() end)
  bindKey(START_STOP_KEY, "down", self.TETRIS_START_STOP_CMD)
  local txt
  if self.game.state.condition == StateConditions.PAUSED then
    txt = "Tetris paused. Press " .. START_STOP_KEY_NAME .. " to resume."
  else
    txt = "Start playing Tetris by pressing " .. START_STOP_KEY_NAME
  end
  self.game.drawing:addIntroduction(txt)
end



function GameMarker:tetrisMarkerLeave(leavePlayer, matchingDimension)
  if leavePlayer ~= localPlayer or not matchingDimension then
    return
  end

  if self.game == nil then
    log("tetrisMarkerLeave: game is nil")
    return
  end
  self.isLocalPlayerInMarker = false
  unbindKey(START_STOP_KEY, "down", self.TETRIS_START_STOP_CMD)
  removeCommandHandler(self.TETRIS_START_STOP_CMD)
  self.game.drawing:removeIntroduction()
end

function GameMarker:localPlayerWasted(killer, weapon, bodypart)
  if self.isRunning then
    self:stopTetris()
  end
  if self.isLocalPlayerInMarker then
    self:tetrisMarkerLeave(localPlayer, true)
  end
end

function GameMarker:stopTetris()
  self.isRunning = false
  self.game.drawing:removeIntroduction()
  self.game.drawing:addIntroduction("Tetris paused. Press " .. START_STOP_KEY_NAME .. " to resume.")
  self.game:stopTetris()
  toggleAllControls(true, true, false)
  self.cameraMover:cancelMovement()
  setCameraTarget(localPlayer)
  
  resetHeatHaze()
end

function GameMarker:startTetris()
  local x, y, z = self.pos.x, self.pos.y, self.pos.z
  self.isRunning = true
  toggleAllControls(false, true, false)
  self.game.drawing:removeIntroduction()
  self.game:startTetris()
  -- 2505, -1653, 11.6
  self.cameraMover:moveCamera(x-4, y-6, z+3.9, x, y, z+3.7, 700, "OutQuad")
  --cameraMover:moveCamera(2501, -1659, 15.5, 2505, -1653, 15.3, 700, "OutQuad")
  
  setHeatHaze(0)
end

function GameMarker:startOrStopTetris()
  if self.isRunning then
    self:stopTetris()
  else
    self:startTetris()
  end
end

function GameMarker:setupMarker()
  self.isRunning = false
  self.isLocalPlayerInMarker = false
	self.cameraMover = CameraMover:new()
  
  local x, y, z = self.pos.x, self.pos.y, self.pos.z
  local markerX, markerY, markerZ = x+1, y-2, z+0.9
	self.marker = createMarker(markerX, markerY, markerZ, "cylinder", 1.0, 132, 4, 16, 200)
  replaceBlipTexture("radar_TorenoRanch")
	createBlipAttachedTo(self.marker, 42) 	-- Toreno_ranch
  
  addEventHandler("onClientMarkerHit", self.marker, bind(self.tetrisMarkerHit, self))
  -- when (re)starting tetriswall and player is already inside marker, 
  -- there would be no markerHit event, so calling it manually
  -- btw, the radius is way too large atm for marker with this method, but let it be
  if isElementWithinMarker(localPlayer, self.marker) then
    self:tetrisMarkerHit(localPlayer, true)
  end
  
  addEventHandler("onClientMarkerLeave", self.marker, bind(self.tetrisMarkerLeave, self))
  addEventHandler("onClientPlayerWasted", localPlayer, bind(self.localPlayerWasted, self))
end



function replaceBlipTexture(textureName)
	local textureReplaceShader = dxCreateShader("client/shaders/blip_texture_replace.fx", 0, 0, false, "world")
	local texture = dxCreateTexture("client/img/blip_tetris.png")
	dxSetShaderValue(textureReplaceShader, "gTexture", texture)
	engineApplyShaderToWorldTexture(textureReplaceShader, textureName)
end

function startGame()
	local game = Game:new()
  local bindings = {
    START_STOP_KEY_NAME=START_STOP_KEY_NAME
  }
	game.drawing = Drawing:new({state=game.state, bindings=bindings})
	game.controller = Controller:new({game=game})
  local gameMarker = GameMarker:new({game=game})
	gameMarker:createTetrisWall(2510, -1650, 11.6)
  
  
  local game2 = Game:new()
	game2.drawing = Drawing:new({state=game2.state, bindings=bindings})
	game2.controller = Controller:new({state=game2.state, game=game2})
  local gameMarker2 = GameMarker:new({game=game2})
  gameMarker2:createTetrisWall(2503, -1655, 11.6)
end


addEventHandler("onClientResourceStop", resourceRoot,
    function (stoppedRes)
      -- resetting controls and camera just in case if resource was restarted
      toggleAllControls(true, true, false)
      if not getCameraTarget() then
        setCameraTarget(localPlayer)
      end
    end
);


addEventHandler("onClientResourceStart", resourceRoot, startGame)