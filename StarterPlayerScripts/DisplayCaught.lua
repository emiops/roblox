--[[
	DisplayCaught - Shows a message when you catch a lizard
	Place in StarterPlayer > StarterPlayerScripts (as a LocalScript)
	Requires: ReplicatedStorage.LizardCaught RemoteEvent (created by CatchController)
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local catchEvent = ReplicatedStorage:WaitForChild("LizardCaught")

catchEvent.OnClientEvent:Connect(function(lizardName, variantName)
	-- You could show a GUI notification here
	print("Caught: " .. (variantName or lizardName))
end)
