Grid = {
	rows = 22, -- the first two rows are "hidden"
	columns = 10,
	rectangles = false,
}

function Grid:new(o)
	o = o or {}   -- create object if user does not provide one
	setmetatable(o, self)
	self.__index = self
	self:createEmptyGrid()
	return o
end

function Grid:emptyLine()
	local line = {}
	for c = 1, self.columns do
		line[c] = 0
	end
	return line
end

function Grid:createEmptyGrid()
	local rectangles = {}
	for r = 1, self.rows do
		table.insert(rectangles, self:emptyLine())
	end
	self.rectangles = rectangles
end

function Grid:addTetrominoToGrid(tetromino)
	local shape = tetromino:getActiveShape()
	local column = tetromino.xOffset
	local row = tetromino.yOffset
	for y, line in ipairs(shape) do
      for x, isFilled in ipairs(line) do
      	if isFilled == 1 then
      		self.rectangles[y+row][x+column] = tetromino.id
      	end
      end
    end
end

function Grid:getFilledLines()
	local filledLines = {}
	for y, gridLine in ipairs(self.rectangles) do
		local isLineFilled = true
		for x, rectangle in ipairs(gridLine) do
			if rectangle == 0 then
				isLineFilled = false
				break
			end
		end
		if isLineFilled then
			table.insert(filledLines, y)
		end
	end
	return filledLines
end

function Grid:removeRows(rows)
	for _, removableLineIndex in ipairs(rows) do
		table.remove(self.rectangles, removableLineIndex)
		table.insert(self.rectangles, 1, self:emptyLine())
	end
end

-- returns false if collides
function Grid:checkForCollision(shape, row, column)
	-- topleft.row, topleft.column
	-- y=1,2,3; x=1,2,3
	for y, shapeLine in ipairs(shape) do
      for x, isFilled in ipairs(shapeLine) do
      	if isFilled == 1 then
      		local r = y + row
      		local c = x + column

      		if r > self.rows then
      			-- rectangle would be out of grid
      			return false
      		end
      		if c < 1 or c > self.columns then
      			return false
      		end

      		local gridRectangle = self.rectangles[r][c]
      		-- log(y+row .. " " .. x+column .. " " .. gridRectangle)
      		if gridRectangle ~= 0 then
      			return false
      		end
      	end
      end
    end
    return true
end

-- returns tetromino's topLeft.x and y
function Grid:getLowestValidRow(tetromino)
	local tCol = tetromino.xOffset
	local shape = tetromino:getActiveShape()

	for tRow = tetromino.yOffset, self.rows do
		if not self:checkForCollision(shape, tRow, tCol) then
			-- log(tRow)
			return tRow - 1 -- minus one, because previous row was last valid one
		end
	end

	log("should not get here, or game is over or sth")
end