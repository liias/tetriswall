local screenWidth, screenHeight = guiGetScreenSize()
  
function drawTooltip(text)
	local font = "default"
	local padding_left, padding_right = 4, 4
	local padding_top, padding_bottom = 0, 2
	local scale = 2
	local colorCoded = false
	local height = dxGetFontHeight(scale, font) + padding_top + padding_bottom
	local width =  dxGetTextWidth(text, scale, font, colorCoded) + padding_left + padding_right

	local x = screenWidth - width 
	local y = screenHeight/2 - height/2

	dxDrawRectangle(x - padding_left, y - padding_top, width, height, tocolor(0, 0, 0, 180), false)
	dxDrawText(text, x, y, x, y, white, scale, font, "left", "top", false, false, false, colorCoded)
end

local introductionFunc 
function addTooltip(text)
	introductionFunc = function()
		drawTooltip(text)
	end

	addEventHandler("onClientRender", root, introductionFunc)
end

function removeTooltip()
	if not introductionFunc then 
		return
	end
	removeEventHandler("onClientRender", root, introductionFunc)
end