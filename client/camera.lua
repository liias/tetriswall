CameraMover = {
	cancelled = false
}

function CameraMover:new(o)
	o = o or {}   -- create object if user does not provide one
	setmetatable(o, self)
	self.__index = self
	return o
end

function CameraMover:cancelMovement()
	self.cancelled = true
	self:removeEvent()
	self.cancelled = false
end

function CameraMover:removeEvent()
	removeEventHandler("onClientPreRender", root, frameMoveCam)
end

function CameraMover:moveCamera(toCameraX, toCameraY, toCameraZ, toTargetX, toTargetY, toTargetZ, duration, strEasingType)
    local fromCameraX, fromCameraY, fromCameraZ, fromTargetX, fromTargetY, fromTargetZ, roll, fov = getCameraMatrix()
    local startTime = getTickCount()
    if strEasingType == nil then
    	strEasingType = "OutQuad"
    end
	
	function frameMoveCam()
		if self.cancelled then
			return
		end

	    local elapsedTime = getTickCount() - startTime
	    if elapsedTime > duration then
	    	self:removeEvent()
		end

	    local progress = elapsedTime / duration
	    local px, py, pz = getElementPosition(localPlayer)
	    local cameraX, cameraY, cameraZ = interpolateBetween(fromCameraX, fromCameraY, fromCameraZ, toCameraX, toCameraY, toCameraZ, progress, strEasingType)
	    local targetX, targetY, targetZ = interpolateBetween(fromTargetX, fromTargetY, fromTargetZ, toTargetX, toTargetY, toTargetZ, progress, strEasingType)
    	setCameraMatrix(cameraX, cameraY, cameraZ, targetX, targetY, targetZ, 0, 70)
	end

    addEventHandler("onClientPreRender", root, frameMoveCam)
end