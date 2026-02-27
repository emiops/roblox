--[[
	BackgroundMusic - Plays low-volume funk music in the background
	Place in ServerScriptService
]]

local SoundService = game:GetService("SoundService")

-- Funk music from Roblox library (replace with your preferred ID if needed)
-- "Funky Funk" - upbeat funk style
local MUSIC_ID = "rbxassetid://1846718408"
local VOLUME = 0.25  -- Not loud, subtle background
local FADE_IN_TIME = 2  -- Seconds to fade in

local sound = Instance.new("Sound")
sound.Name = "BackgroundMusic"
sound.SoundId = MUSIC_ID
sound.Volume = 0
sound.Looped = true
sound.Parent = SoundService

-- Fade in gently so it doesn't startle
task.spawn(function()
	sound:Play()
	local start = tick()
	while tick() - start < FADE_IN_TIME do
		task.wait(0.1)
		sound.Volume = math.min(VOLUME * ((tick() - start) / FADE_IN_TIME), VOLUME)
	end
	sound.Volume = VOLUME
end)

print("[BackgroundMusic] Funk music playing at low volume.")
