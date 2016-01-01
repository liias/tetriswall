Drawing = {
	state = false,
	board = {
		width = 322,
		height = 642,
		gridColor = tocolor(255, 100, 255, 100),
		backgroundColor = tocolor(30, 30, 30, 180),
		rectangle = {
			length = 32
		},

		x = nil,
		y = nil,
		tetrominoX = nil,
		tetrominoY = nil,
	},
	renderFunc = false,

	-- these are for animations
	periodStartTimes = {},
	highlightedRows = {},
	hardDropPositions = {},
}


function Drawing:new(o)
	o = o or {}   -- create object if user does not provide one
	setmetatable(o, self)
	self.__index = self
  
  self.keyNamesDescription = self:manualFromKeyNames()
	return o
end

function Drawing:manualFromKeyNames()
  local k = {
    START_STOP = getCommandKeyName(Commands.START_STOP),
    LEFT = getCommandKeyName(Commands.LEFT),
    RIGHT = getCommandKeyName(Commands.RIGHT),
    DOWN = getCommandKeyName(Commands.DOWN),
    HARD_DROP = getCommandKeyName(Commands.HARD_DROP),
    ROTATE = getCommandKeyName(Commands.ROTATE),
    HOLD = getCommandKeyName(Commands.HOLD),
    RESET = getCommandKeyName(Commands.RESET),
    PAUSE = getCommandKeyName(Commands.PAUSE),
  }
  
  local template = [[Left: %s
	Right: %s
	Down: %s
	Rotate: %s
	Hard drop: %s
	Pause: %s
	Restart: %s
	Hold: %s
	Exit: %s]]
  
  return string.format(template, k.LEFT, k.RIGHT, k.DOWN, k.ROTATE, k.HARD_DROP, k.PAUSE, k.RESET, k.HOLD, k.START_STOP)
end

function Drawing:initDimensions(x, y)
	self.board.x = x
	self.board.y = y
	self.board.tetrominoX = self.board.x + 1
	self.board.tetrominoY = self.board.y + 1

	self.screenWidth, self.screenHeight = guiGetScreenSize()
end

function Drawing:drawScore()
	local x = self.board.x + 7
	local y = self.board.y + self.board.height + 10
	local txt = "Score: " .. self.state.score .. " Level: " .. self.state.level .. " Lines to clear: " .. self.state.linesForNextLevel
	dxDrawText(txt, x, y, x, y, white, 1.5)
end

function Drawing:startFourRowsClear()
	-- alternatively could set highlightedEndTime and highlightedCallback
	-- 200 + 200 + 200 + 200 + 100
	self:drawForPeriod("drawFourRowsClear", nil, 800)
end

function Drawing:drawFourRowsClear()
	local x = self.board.x + self.board.width/2 - 40
	local y = self.board.y + self.board.height/2 - 5
	dxDrawText("Tetris!", x, y, x, y, white, 3)
end

function Drawing:drawTetrominoQueue(nextTetrominoIds)
  self:drawTextOnTopOfTetromino(3, 0, "NEXT")
  
  local nextTetrominoId = nextTetrominoIds[1]
  if nextTetrominoId then
    local tetromino = IdTetrominoClassMap[nextTetrominoId]
    self:drawShapeAtOffset(tetromino:getActiveShape(), tetromino.color, 3, 0, 1, true)
  end
  
  local nextTetrominoId2 = nextTetrominoIds[2]
  if nextTetrominoId2 then
    local tetromino = IdTetrominoClassMap[nextTetrominoId2]
    self:drawShapeAtOffset(tetromino:getActiveShape(), tetromino.color, 10, 0, 0.8, true)
  end
  
  local nextTetrominoId3 = nextTetrominoIds[3]
  if nextTetrominoId3 then
    local tetromino = IdTetrominoClassMap[nextTetrominoId3]
    self:drawShapeAtOffset(tetromino:getActiveShape(), tetromino.color, 15, 0, 0.8, true)
  end
end

function Drawing:drawHeldTetromino(tetrominoId)
  self:drawTextOnTopOfTetromino(11, 5, "HOLD")
  
  if tetrominoId then
    local tetromino = IdTetrominoClassMap[tetrominoId]
    self:drawShapeAtOffset(tetromino:getActiveShape(), tetromino.color, 11, 5, 1, true)
  end
end

function Drawing:startTetrominoAlreadyHeld()
	-- alternatively could set highlightedEndTime and highlightedCallback
	-- 200 + 200 + 200 + 200 + 100
	self:drawForPeriod("drawTetrominoAlreadyHeld", nil, 800)
end

function Drawing:drawTetrominoAlreadyHeld()
	local x = self.board.x + self.board.width/2 - 40
	local y = self.board.y + self.board.height/2 - 5
	dxDrawText("Holding already used!", x, y, x, y, white, 1)
end


function Drawing:drawTextOnTopOfTetromino(xOffset, yOffset, text)
  yOffset = yOffset-2
  local length = self.board.rectangle.length
  local textX = self.board.tetrominoX+xOffset*length+length/2
	local textY = self.board.tetrominoY+(yOffset-1)*length
  
  dxDrawText(text, textX, textY, textX, textY, tocolor(255, 240, 135), 1.5, "default-bold")
end
  
function Drawing:drawButtons()
  local x = self.board.x + self.board.width + 10
	local y = self.board.y + 200
	dxDrawText(self.keyNamesDescription, x, y, x, y, white, 1.5, "default", "left", "top", false, false, false, true)
end

function Drawing:drawGameOver()
	local x = self.board.x + 10
	local y = self.board.y + self.board.height - 90
	
	dxDrawText("Game Over.\nPress R to restart.", x, y, x, y, white, 3)
end

function Drawing:getFullWidth()
  return self.board.x+self.board.width+200
end

function Drawing:getFullHeight()
  return self.board.y+self.board.height+50
end

function Drawing:drawBackground()
  local w = self:getFullWidth()
  local h = self:getFullHeight()
  dxDrawRectangle(0, 0, w, h, tocolor(0,0,0), false)
	dxDrawRectangle(self.board.x, self.board.y, self.board.width, self.board.height, self.board.backgroundColor, false)
	dxDrawImage(self.board.x, self.board.y, self.board.width, self.board.height, "client/img/grid322x642.png", 0, 0, 0, self.board.gridColor, false)
end

function Drawing:drawRectangle(x, y, color, scale, allowOutOfBoard)
  if not scale then
    scale = 1
  end
	
	y = y-2
	if not allowOutOfBoard and y < 0 then
		-- dont draw first two rows
		return
	end

  local length = self.board.rectangle.length
  length = length * scale

	local rectangleX = self.board.tetrominoX + x*length
	local rectangleY = self.board.tetrominoY + y*length
	dxDrawImage(rectangleX, rectangleY, length, length, "client/img/tetrominopiece32.png", 0, 0, 0, color, false)
end

function Drawing:drawShapeAtOffset(shape, color, xOffset, yOffset, scale, allowOutOfBoard)
  if not scale then
    scale = 1
  end

	xOffset = xOffset - 1
	yOffset = yOffset - 1

	for y, line in ipairs(shape) do
      for x, isFilled in ipairs(line) do
      	if isFilled == 1 then
          self:drawRectangle(x + xOffset, y + yOffset, color, scale, allowOutOfBoard)
      	end
      end
    end
end


function Drawing:drawDxRect(length, xOffset, yOffset, color)
	yOffset = yOffset-2
	if yOffset < 0 then
		-- dont draw first two rows
		return
	end

	local topLeftX = self.board.tetrominoX+xOffset*length
	local topLeftY = self.board.tetrominoY+yOffset*length

	local x = xOffset + 1
	local y = yOffset + 1

	local topLeft = {topLeftX, topLeftY}
	local topRight = {topLeftX + length, topLeftY}
	local bottomLeft = {topLeftX, topLeftY + length}
	local bottomRight = {topLeftX + length, topLeftY + length}

	dxDrawLine(topLeft[1], topLeft[2], topRight[1], topRight[2], color) -- top line
	dxDrawLine(topRight[1], topRight[2], bottomRight[1], bottomRight[2], color) -- right line
	dxDrawLine(bottomRight[1], bottomRight[2], bottomLeft[1], bottomLeft[2], color) -- bottom line
	dxDrawLine(bottomLeft[1], bottomLeft[2], topLeft[1], topLeft[2], color) -- left line

end


function Drawing:drawShapeOutlineAtOffset(shape, color, xOffset, yOffset)
	local xOffset = xOffset - 1
	local yOffset = yOffset - 1
	yOffset = yOffset-2
	if yOffset < 0 then
		-- dont draw first two rows
		return
	end
	local lines = getShapeOutline(shape)
    self:drawLines(lines, color, xOffset, yOffset)
end

function Drawing:drawLines(lines, color, xOffset, yOffset)
	local topLeftX = self.board.tetrominoX
	local topLeftY = self.board.tetrominoY
	local length = self.board.rectangle.length

	local x = topLeftX + xOffset*length
	local y = topLeftY + yOffset*length

	for i, line in ipairs(lines) do
		local from = line[1]
		local to = line[2]
		dxDrawLine(x + from[1] * length, y + from[2] * length, x + to[1] * length, y + to[2] * length, color, 2)	
	end
end


function Drawing:drawFallingTetromino(tetromino)
  self:drawGhost(tetromino)
  
  local shape = tetromino:getActiveShape()
	self:drawShapeAtOffset(shape, tetromino.color, tetromino.xOffset, tetromino.yOffset)
end

function Drawing:drawGhost(tetromino)
  local shape = tetromino:getActiveShape()
  self:drawShapeOutlineAtOffset(shape, tetromino.color, tetromino.xOffset, tetromino.lowestValidRow)
  self:drawShapeAtOffset(shape, tetromino.shadowColor, tetromino.xOffset, tetromino.lowestValidRow)
end

function Drawing:drawCurrentState()
	self:drawBackground()
	self:drawScore()
	self:drawButtons()

  self:drawHeldTetromino(self.state.heldTetrominoId)

  self:drawTetrominoQueue(self.state.nextTetrominoIds)

	if self.periodStartTimes.drawHardDropEffect ~= nil then
		self:drawHardDrop()
	end

	self:drawLandedRectangles(self.state.grid.rectangles)

	if self.state.activeTetromino then
		self:drawFallingTetromino(self.state.activeTetromino)
	end

	if self.periodStartTimes.drawFourRowsClear ~= nil then
		self:drawFourRowsClear()
	end
  
  if self.periodStartTimes.drawTetrominoAlreadyHeld ~= nil then
		self:drawTetrominoAlreadyHeld()
	end

	if self.gameOver then
		self:drawGameOver()
	end
end

function Drawing:drawHardDrop()
	local info = self.hardDropPositions
	local board = self.board
	local length = self.board.rectangle.length
	local x = board.tetrominoX+info.x*length
	local toY = info.toY -2
	local fromY = math.max(info.fromY - 2, 0)
	local height = toY - fromY + info.tHeight
	local y = board.tetrominoY + fromY*length

	local color = colorFromRgba(info.rgb, 60)
	-- todo: draw effect only to rectangles up of tetromino, and make tetromino brighter
	dxDrawRectangle(x, y, info.tWidth*length, height*length, color)
end

function contains(thelist, search)
	for i, v in ipairs(thelist) do
		if v == search then
			return true
		end
	end
	return false
end

function Drawing:drawLandedRectangles(rectangles)
	for y, row in ipairs(rectangles) do
      for x, rectangleId in ipairs(row) do
      	if rectangleId ~= 0 then
      		local rgb = IdColorMap[rectangleId].rgb
      		local color = colorFromRgba(rgb, NORMAL_ALPHA)

      		local startTime = self.periodStartTimes.flashRemovableRows
      		if startTime ~= nil and contains(self.highlightedRows, y) then
      			local duration = getTickCount() - startTime -- 1-900
            local animAlpha = getAnimAlpha(duration, 100)
            color = colorFromRgba(rgb, animAlpha)
      		end

          self:drawRectangle(x-1, y-1, color)
      	end
      end
    end
end

-- pulses from 255 to 0 in maxMs, and back from 0 to 255 in maxMs, so full pulse takes 2*maxMs
function getAnimAlpha(animationCurrentDuration, maxMs)
	local backToFull = 2 * maxMs
	local r = 255/maxMs
	local zeroToDoubleMaxMs = animationCurrentDuration % backToFull
	if zeroToDoubleMaxMs <= maxMs then
		return 255 - (zeroToDoubleMaxMs*r)
	else
		return (zeroToDoubleMaxMs-maxMs) * r
	end
end

function Drawing:drawForPeriod(funcName, endFunc, periodMs)
	self.periodStartTimes[funcName] = getTickCount()
	local onEndFunction = function()
		self.periodStartTimes[funcName] = nil
		if endFunc ~= nil then
			endFunc()
		end
	end
	setTimer(onEndFunction, periodMs, 1)
end


function Drawing:flashRemovableRows(rowIndexes, callback)
	self.highlightedRows = rowIndexes
	local endAnimation = function() 
		self.highlightedRows = {}
		callback()
	end
	-- alternatively could set highlightedEndTime and highlightedCallback
	-- 200 + 200 + 200 + 200 + 100
	self:drawForPeriod("flashRemovableRows", endAnimation, 500)
end

function Drawing:drawHardDropEffect(tetromino, fromYOffset)
	--log("Hard drop from " .. fromYOffset .. " to " .. tetromino.yOffset)
	local shape = tetromino:getActiveShape()
	local dim = tetromino:getRealDimensions()
	local realWidth = dim.x.max - dim.x.min + 1
	local realHeight = dim.y.max - dim.y.min + 1
	local rgb = IdColorMap[tetromino.id].rgb

	self.hardDropPositions = {
		x = tetromino.xOffset+dim.x.min-1,
		fromY = fromYOffset+dim.y.min-1,
		toY = tetromino.yOffset+dim.y.min-1,
		rgb = rgb,
		tWidth = realWidth,
		tHeight = realHeight 
	}
	local endAnimation = function() 
		self.hardDropPositions = {}
	end
	self:drawForPeriod("drawHardDropEffect", endAnimation, 200)
end

function Drawing:setGameOver(isOver)
	self.gameOver = isOver
end

--local tetrisRenderTarget = nil
--local shader = nil


function Drawing:drawComePlay()
	local x = self.board.x + 10
	local y = self.board.y + self.board.height - 90 - 100
	
	local playerName = getPlayerName(localPlayer)
	dxDrawText("Hey, " .. playerName .. "." .. "\nCome play with me.", x, y, x, y, white, 4)
end


function Drawing:initDrawing(textureName, targetObject)
	self:initDimensions(10, 100)
  
  local w = self:getFullWidth()
  local h = self:getFullHeight()
  
	self.tetrisRenderTarget = dxCreateRenderTarget(w, h, false)
	initShader(self.tetrisRenderTarget, textureName, targetObject)

	-- draw come play until tetris has been started
	self:drawComePlayOnTarget()
	self:enableClientRestore()
end

-- draw come play until tetris has been started and after client restore from alt+tab
function Drawing:drawComePlayOnTarget()
	dxSetRenderTarget(self.tetrisRenderTarget, true)
	self:drawComePlay()
	dxSetRenderTarget()
end

function Drawing:drawCurrentStateOnTarget()
	dxSetRenderTarget(self.tetrisRenderTarget, true)
	self:drawCurrentState()
	dxSetRenderTarget()
  
  -- for debugging on screen:
  --local w = self:getFullWidth()
  --local h = self:getFullHeight()
  --dxDrawImage(0,  0,  w, h, self.tetrisRenderTarget)
end

function Drawing:startDrawing()
	self.renderFunc = function()
		self:drawCurrentStateOnTarget()
	end

	addEventHandler("onClientRender", root, self.renderFunc)
end

function Drawing:drawOnceCurrentStateOrComePlay()
	if self.state.condition == StateConditions.PAUSED  
		or self.state.condition == StateConditions.RUNNING then
		
		self:drawCurrentStateOnTarget()
	else
		self:drawComePlayOnTarget()
	end
end

-- targetObject can be 0
function initShader(texture, textureName, targetObject)
	local SHADER_FILE_PATH = "client/shaders/texture_replace.fx"
	local SHADER_TEXTURE_VAR_NAME = "tetrisTexture"

	local shader, technique = dxCreateShader(SHADER_FILE_PATH, 0, 0, false, "object")
	if not shader then
		outputChatBox("Tetris: Could not create shader. Please use debugscript 3")
	else
		--log(technique)
		dxSetShaderValue(shader, SHADER_TEXTURE_VAR_NAME, texture)
		engineApplyShaderToWorldTexture(shader, textureName, targetObject)
	end
end

function Drawing:stopDrawing()
	-- engineRemoveShaderFromWorldTexture(shader, SHADER_TEXTURE_VAR_NAME, targetObject)
	removeEventHandler("onClientRender", root, self.renderFunc)
end

function Drawing:enableClientRestore()
	function handleRestore(didClearRenderTargets)
	    if didClearRenderTargets then
	    	self:drawOnceCurrentStateOrComePlay()
	    	--self:drawComePlayOnTarget()
	    	-- log("render targets were cleared")
	        -- Do any work here to restore render target contents as required
	    end
	end
	addEventHandler("onClientRestore", root, handleRestore)
end

function Drawing:drawTooltip(text)
	local font = "default"
	local padding_left, padding_right = 4, 4
	local padding_top, padding_bottom = 0, 2
	local scale = 2
	local colorCoded = false
	local height = dxGetFontHeight(scale, font) + padding_top + padding_bottom
	local width =  dxGetTextWidth(text, scale, font, colorCoded) + padding_left + padding_right

	local x = self.screenWidth - width 
	local y = self.screenHeight/2 - height/2

	dxDrawRectangle(x - padding_left, y - padding_top, width, height, tocolor(0, 0, 0, 180), false)
	dxDrawText(text, x, y, x, y, white, scale, font, "left", "top", false, false, false, colorCoded)
end

local introductionFunc 
function Drawing:addIntroduction(text)
	introductionFunc = function()
		self:drawTooltip(text)
	end

	addEventHandler("onClientRender", root, introductionFunc)
end

function Drawing:removeIntroduction()
	if not introductionFunc then 
		return
	end
	removeEventHandler("onClientRender", root, introductionFunc)
end