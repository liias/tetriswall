

function clientSentMove(moveState)
  local delta = moveState[1]
  local id = moveState[2]
  local column = moveState[3]
  local row = moveState[4]
  local rotationIndex = moveState[5]
  local moveType = moveState[6]

  local opponent = client
  triggerClientEvent(opponent, "onSendMoveToClient", client, moveState)

  
  --   local moveState = {delta, t.id, t.xOffset, t.yOffset, t.rotationIndex, moveType}

	-- the predefined variable 'client' points to the player who triggered the event and should be used due to security issues   
	--outputChatBox("You sent to server: " .. moveType, client)
end

addEvent("onSendMoveToServer", true)
addEventHandler("onSendMoveToServer", resourceRoot, clientSentMove)


local function clientSentUpdate(packet)
  local opponent = client
  triggerClientEvent(opponent, "onSendTetrisUpdateToClient", client, packet)
end
addEvent("onSendTetrisUpdateToServer", true)
addEventHandler("onSendTetrisUpdateToServer", resourceRoot, clientSentUpdate)
