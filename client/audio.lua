local backgroundMusic = nil

function randomFile()
  local n = math.random(1,2)
  return "client/audio/music/fast" .. tostring(n) .. ".mp3"
end

function startMusic()
   backgroundMusic = playSound(randomFile(), true)
end

function stopMusic()
  if backgroundMusic then
    stopSound(backgroundMusic)
  end
end
