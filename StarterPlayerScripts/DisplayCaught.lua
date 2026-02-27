--[[
	DisplayCaught - Shows a message when you catch a lizard
	Place in StarterPlayer > StarterPlayerScripts (as a LocalScript)
	Requires: ReplicatedStorage.LizardCaught RemoteEvent (created by CatchController)
	CatchController sends: (lizardType, newCount)
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local catchEvent = ReplicatedStorage:WaitForChild("LizardCaught")

catchEvent.OnClientEvent:Connect(function(lizardType, newCount)
	-- Brief feedback - full count is on terrarium banner
	print("Caught: " .. tostring(lizardType))
end)
