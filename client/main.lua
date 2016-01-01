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

function startGame()
  -- bind keys to command without command handlers
  -- this allows player to customize controls without them currently being enabled
  bindCommand(Commands.START_STOP)
  
  bindCommand(Commands.LEFT, "down")
  bindCommand(Commands.LEFT, "up")

  bindCommand(Commands.RIGHT, "down")
  bindCommand(Commands.RIGHT, "up")
  
  bindCommand(Commands.DOWN, "down")
  bindCommand(Commands.DOWN, "up")
  
  bindCommand(Commands.HARD_DROP)
  bindCommand(Commands.ROTATE)
  bindCommand(Commands.HOLD)
  bindCommand(Commands.RESET)
  bindCommand(Commands.PAUSE)

	local game = Game:new()

	game.drawing = Drawing:new({state=game.state})
	game.controller = Controller:new({game=game})
  local gameMarker = GameMarker:new({game=game})
  gameMarker:createTetrisWall(2503, -1655, 11.55)

  
  local game2 = Game:new()
	game2.drawing = Drawing:new({state=game2.state})
	game2.controller = Controller:new({game=game2})
  local gameMarker2 = GameMarker:new({game=game2})
  gameMarker2:createTetrisWall(2508, -1660, 11.6)
end

addEventHandler("onClientResourceStart", resourceRoot, startGame)