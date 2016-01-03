-- can use to set class method as an event callback
function bind(func, ...)
    if not func then
        if DEBUG then
            outputConsole(debug.traceback())
            outputServerLog(debug.traceback())
        end
        error("Bad function pointer @ bind. See console for more details")
    end

    local boundParams = {...}
    return
    function(...)
        local params = {}
        local boundParamSize = select("#", unpack(boundParams))
        for i = 1, boundParamSize do
            params[i] = boundParams[i]
        end

        local funcParams = {...}
        for i = 1, select("#", ...) do
            params[boundParamSize + i] = funcParams[i]
        end
        return func(unpack(params))
    end
end

-- like string.format() but with named parameters
-- http://lua-users.org/wiki/StringInterpolation
function interp(s, tab)
  return (s:gsub('($%b{})', function(w) return tab[w:sub(3, -2)] or w end))
end
  
function getRectangleEdges(xOffset, yOffset)
	local topLeftX = xOffset
	local topLeftY = yOffset
	local bottomY = topLeftY + 1
	local rightX = topLeftX + 1

	local topLeft = {topLeftX, topLeftY}
	local topRight = {rightX, topLeftY}
	local bottomLeft = {topLeftX, bottomY}
	local bottomRight = {rightX, bottomY}

	local topLine = {topLeft, topRight}
	local bottomLine = {bottomLeft, bottomRight}

	local rightLine = {topRight, bottomRight}
	local leftLine = {topLeft, bottomLeft}

	return topLine, rightLine, bottomLine, leftLine
end

function getShapeOutline(shape) 
	local allLines = {}
	for y, line in ipairs(shape) do
      for x, isFilled in ipairs(line) do
      	if isFilled == 1 then
      		local edges = {getRectangleEdges(x, y)}
          for i, edge in ipairs(edges) do
            table.insert(allLines, edge)
          end
      	end
      end
    end

    -- remove nonUniqueLines
    -- TODO: abstract deep table check or do something more sane...
    local uniqueLines = {}
    for i, line in ipairs(allLines) do
    	local thisFrom = line[1]
    	local thisTo = line[2]
    	local hasAlready = false
    	for q, uniqueLine in ipairs(uniqueLines) do
    		local uniqueFrom = uniqueLine[1]
    		local uniqueTo = uniqueLine[2]
    		local fromCheck = uniqueFrom[1] == thisFrom[1] and uniqueFrom[2] == thisFrom[2]
    		local toCheck = uniqueTo[1] == thisTo[1] and uniqueTo[2] == thisTo[2]
    		if fromCheck and toCheck then
    			table.remove(uniqueLines, q) -- remove existing line
    			hasAlready = true
    		end    		
    	end

    	if not hasAlready then
    		table.insert(uniqueLines, line)
    	end
    end
    return uniqueLines
end

function replaceBlipTexture(textureName, newImagePath)
	local textureReplaceShader = dxCreateShader("client/shaders/blip_texture_replace.fx", 0, 0, false, "world")
  local texture = dxCreateTexture(newImagePath)
	dxSetShaderValue(textureReplaceShader, "gTexture", texture)
	engineApplyShaderToWorldTexture(textureReplaceShader, textureName)
end

function capitalize(s)
  return s:sub(1,1):upper()..s:sub(2)
end

function log(msg)
  outputDebugString(tostring(msg))
end