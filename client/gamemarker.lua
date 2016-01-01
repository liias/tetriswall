GameMarker = {
  game = false,
  pos = {x=0, y=0, z=0},
  isLocalPlayerInMarker = false,
  isRunning = false,
}

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
  addCommandHandler(Commands.START_STOP, bind(self.startOrStopTetris, self))
  local txt
  if self.game.state.condition == StateConditions.PAUSED then
    txt = "Tetris paused. Press " .. getCommandKeyName(Commands.START_STOP) .. " to resume."
  else
    txt = "Start playing Tetris by pressing " .. getCommandKeyName(Commands.START_STOP)
  end
  addTooltip(txt)
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
  removeCommandHandler(Commands.START_STOP)
  removeTooltip()
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
  removeTooltip()
  addTooltip("Tetris paused. Press " .. getCommandKeyName(Commands.START_STOP) .. " to resume.")
  self.game:stopTetris()
  toggleAllControls(true, true, false)
  self.cameraMover:cancelMovement()
  setCameraTarget(localPlayer)
  
  resetHeatHaze()
  setPedAnimation(localPlayer)
end



function GameMarker:startTetris()
  if isPedInVehicle(localPlayer) then
    log("cant be in vehicle")
    return
  end
  
  self.isRunning = true
  toggleAllControls(false, true, false)
  removeTooltip()
  self.game:startTetris()
  -- 2505, -1653, 11.6
  local x, y, z = self.pos.x, self.pos.y, self.pos.z
  self.cameraMover:moveCamera(x-4, y-6, z+3.9, x, y, z+3.7, 700, "OutQuad")
  --cameraMover:moveCamera(2501, -1659, 15.5, 2505, -1653, 15.3, 700, "OutQuad")
  
  setHeatHaze(0)
  faceLocalPlayerTo(x, y)
  setPedAnimation(localPlayer, "attractors", "Stepsit_in", -1, false, false, true, true)
end

function faceLocalPlayerTo(x, y)
  local px, py, pz = getElementPosition(localPlayer)
  local rotZ = findRotation(px, py, x, y)
  local rotX, rotY, _ = getElementRotation(localPlayer)
  setElementRotation(localPlayer, rotX, rotY, rotZ, "default", true)
end
-- from MTA wiki Useful functions
function findRotation(x1, y1, x2, y2) 
    local t = -math.deg( math.atan2( x2 - x1, y2 - y1 ) )
    return t < 0 and t + 360 or t
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
  replaceBlipTexture("radar_TorenoRanch", "client/img/blip_tetris.png")
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