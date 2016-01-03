local backgroundMusic = nil

local function randomFile()
  local n = math.random(1,2)
  return ASSETS_AUDIO .. "music/fast" .. tostring(n) .. ".mp3"
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
  playSound(ASSETS_AUDIO .. "sfx/" .. soundPath)
end

function playAudioMove()
  playAudioSfx("move.wav")
end

function playAudioRotate()
  playAudioSfx("rotate.wav")
end

function playAudioHardDrop()
  playAudioSfx("harddrop.wav")
end

function playAudioHold()
  playAudioSfx("hold.wav")
end

function playAudioTheEnd()
  playAudioSfx("theend.wav")
end

function playAudioClearRow()
  playAudioSfx("rowclear.mp3")
end

function playAudioClearTetris()
  playAudioSfx("tetrisclear.mp3")
end