-------------------------

function startGame()
	local game = Game:new()
	local drawing = Drawing:new({state=game.state})
	game.drawing = drawing
	game.controller = Controller:new({state=game.state, game=game})

	createTetrisWall(game)
end

function createTetrisWallObject()
	-- Create object with model 4729 (billboard)
	local tetrisObject = createObject(4729, 2505, -1653, 11.6, 70, 270, 326)
  setObjectBreakable(tetrisObject, false)
	setElementDoubleSided(tetrisObject, true)
	setObjectScale(tetrisObject, 0.5)
  -- setObjectScale does not effect collisions, so remove the collision
  setElementCollisionsEnabled(tetrisObject, false)
	return tetrisObject
end

function createTetrisWall(game)
	local tetrisObject = createTetrisWallObject()
	game.drawing:initDrawing("bobo_2", tetrisObject)
	setupMarker(game)
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

local isLocalPlayerInMarker = false
local isRunning = false

function setupMarker(game)
	local markerX, markerY, markerZ = 2506, -1655, 12.5

	local cameraMover = CameraMover:new()

  function stopTetris()
    isRunning = false
    game.drawing:removeIntroduction()
    game.drawing:addIntroduction("Tetris paused. Press " .. START_STOP_KEY_NAME .. " to resume.")
    game:stopTetris()
    toggleAllControls(true, true, false)
    cameraMover:cancelMovement()
    setCameraTarget(localPlayer)
    
    resetHeatHaze()
  end
  
  function startTetris()
    isRunning = true
    toggleAllControls(false, true, false)
    game.drawing:removeIntroduction()
    game:startTetris()
    cameraMover:moveCamera(2501, -1659, 15.5, 2505, -1653, 15.3, 700, "OutQuad")
    
    setHeatHaze(0)
  end
  
	function startOrStopTetris(key, keyState)
		if isRunning then
			stopTetris()
		else
			startTetris()
		end
	end

	local marker = createMarker(markerX, markerY, markerZ, "cylinder", 1.0, 132, 4, 16, 200)

  replaceBlipTexture("radar_TorenoRanch")
	createBlipAttachedTo(marker, 42) 	-- Toreno_ranch 

	function tetrisMarkerHit(hitPlayer, matchingDimension)
		if hitPlayer ~= localPlayer or not matchingDimension then
			return
		end

		if game == nil then
			log("tetrisMarkerHit: game is nil")
			return
		end

    isLocalPlayerInMarker = true
		bindKey(START_STOP_KEY, "down", startOrStopTetris)
		local txt
		if game.state.condition == StateConditions.PAUSED then
			txt = "Tetris paused. Press " .. START_STOP_KEY_NAME .. " to resume."
		else
			txt = "Start playing Tetris by pressing " .. START_STOP_KEY_NAME
		end
		game.drawing:addIntroduction(txt)

	end
	addEventHandler("onClientMarkerHit", marker, tetrisMarkerHit)
  
  -- when (re)starting tetriswall and player is already inside marker, 
  -- there would be no markerHit event, so calling it manually
  -- btw, the radius is way too large atm for marker with this method, but let it be
  if isElementWithinMarker(localPlayer, marker) then
    tetrisMarkerHit(localPlayer, true)
  end

	function tetrisMarkerLeave(leavePlayer, matchingDimension)
		if leavePlayer ~= localPlayer or not matchingDimension then
			return
		end
		if game == nil then
			log("tetrisMarkerLeave: game is nil")
			return
		end
    isLocalPlayerInMarker = false
		unbindKey(START_STOP_KEY, "down", startOrStopTetris)
		game.drawing:removeIntroduction()
	end
	addEventHandler("onClientMarkerLeave", marker, tetrisMarkerLeave)

  function localPlayerWasted(killer, weapon, bodypart)
    if isRunning then
      stopTetris()
    end
    if isLocalPlayerInMarker then
      tetrisMarkerLeave(localPlayer, true)
    end
  end
  addEventHandler("onClientPlayerWasted", localPlayer, localPlayerWasted)
end

function replaceBlipTexture(textureName)
	local textureReplaceShader = dxCreateShader("client/shaders/blip_texture_replace.fx", 0, 0, false, "world")
	local texture = dxCreateTexture("client/img/blip_tetris.png")
	dxSetShaderValue(textureReplaceShader, "gTexture", texture)
	engineApplyShaderToWorldTexture(textureReplaceShader, textureName)
end

addEventHandler("onClientResourceStart", resourceRoot, startGame)