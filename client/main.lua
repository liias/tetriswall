addEventHandler("onClientResourceStop", resourceRoot,
    function (stoppedRes)
      -- resetting controls and camera just in case if resource was restarted
      toggleAllControls(true, true, false)
      if not getCameraTarget() then
        setCameraTarget(localPlayer)
      end
      
      resetHeatHaze()
      setPedAnimation(localPlayer)
    end
);

function startGame()  
	local game = Game:new()
  local bindings = {
    START_STOP_KEY_NAME="right shift"
  }
	game.drawing = Drawing:new({state=game.state, bindings=bindings})
	game.controller = Controller:new({game=game})
  local gameMarker = GameMarker:new({game=game})
  gameMarker:createTetrisWall(2503, -1655, 11.55)

  
  local game2 = Game:new()
	game2.drawing = Drawing:new({state=game2.state, bindings=bindings})
	game2.controller = Controller:new({game=game2})
  local gameMarker2 = GameMarker:new({game=game2})
  gameMarker2:createTetrisWall(2508, -1660, 11.6)
end

addEventHandler("onClientResourceStart", resourceRoot, startGame)