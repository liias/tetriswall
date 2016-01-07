

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
  -- bind keys to command without command handlers
  -- this allows player to customize controls without them currently being enabled
  bindCommand(Commands.START_STOP)
  
  bindCommand(Commands.LEFT)
  bindCommand(Commands.LEFT, "up")

  bindCommand(Commands.RIGHT)
  bindCommand(Commands.RIGHT, "up")
  
  bindCommand(Commands.DOWN)
  bindCommand(Commands.DOWN, "up")
  
  bindCommand(Commands.HARD_DROP)
  bindCommand(Commands.ROTATE_RIGHT)
  bindCommand(Commands.ROTATE_LEFT)
  bindCommand(Commands.HOLD)
  bindCommand(Commands.RESET)
  bindCommand(Commands.TOGGLE_PAUSE)

	local game = Game:new()
	game.drawing = Drawing:new({state=game.state})
	game.controller = Controller:new({game=game})
  local gameMarker = GameMarker:new({game=game})
  gameMarker:createTetrisWall(2503, -1655, 11.55)
  
  local game2 = Game:new({multiplayer=true})
	game2.drawing = Drawing:new({state=game2.state})
	game2.controller = Controller:new({game=game2})
  local gameMarker2 = GameMarker:new({game=game2})
  gameMarker2:createTetrisWall(2506, -1656, 11.6)
end


function handleMinimize()
  executeCommandHandler(Commands.PAUSE_CURRENT_GAME)
end
addEventHandler("onClientMinimize", root, handleMinimize)


addEventHandler("onClientResourceStart", resourceRoot, startGame)