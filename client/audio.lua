local backgroundMusic = nil

local function randomFile()
  local n = math.random(1,2)
  return "client/audio/music/fast" .. tostring(n) .. ".mp3"
end

function startMusic()
   backgroundMusic = playSound(randomFile(), true)
end

function stopMusic()
  if backgroundMusic then
    stopSound(backgroundMusic)
    backgroundMusic = nil
  end
end

local function playAudioSfx(soundPath)
  playSound(soundPath)
end

function playAudioMove()
  playAudioSfx("client/audio/sfx/move.wav")
end

function playAudioRotate()
  playAudioSfx("client/audio/sfx/rotate.wav")
end

function playAudioHardDrop()
  playAudioSfx("client/audio/sfx/harddrop.wav")
end

function playAudioHold()
  playAudioSfx("client/audio/sfx/hold.wav")
end

function playAudioTheEnd()
  playAudioSfx("client/audio/sfx/theend.wav")
end

function playAudioClearRow()
  playAudioSfx("client/audio/sfx/rowclear.mp3")
end

function playAudioClearTetris()
  playAudioSfx("client/audio/sfx/tetrisclear.mp3")
end