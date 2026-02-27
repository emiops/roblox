--[[
	CatchController - Handles catching lizards when player presses E near them
	Adds lizards to player inventory
	Place this in ServerScriptService
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local CATCH_RANGE = 25  -- Generous range - lizards escape at 14 studs

-- Create RemoteEvents FIRST so client can connect even if require fails
local catchRequest = Instance.new("RemoteEvent")
catchRequest.Name = "CatchLizardRequest"
catchRequest.Parent = ReplicatedStorage

local catchEvent = Instance.new("RemoteEvent")
catchEvent.Name = "LizardCaught"
catchEvent.Parent = ReplicatedStorage

local LizardInventory = require(ReplicatedStorage:WaitForChild("LizardInventory"))

-- Normalize lizard type: "Green Lizard_1234" -> "GreenLizard", "GreenLizard" -> "GreenLizard"
local function normalizeLizardType(name)
	local base = name:match("^(.+)%_%d+$") or name  -- Strip _1234 suffix
	return base:gsub(" ", "")  -- Remove spaces: "Green Lizard" -> "GreenLizard"
end

local function catchLizard(player, lizard)
	if not lizard or not lizard.Parent then return false end
	
	local lizardType = normalizeLizardType(lizard.Name)
	LizardInventory.AddLizard(player, lizardType)
	catchEvent:FireClient(player, lizardType, LizardInventory.GetCount(player, lizardType))
	
	-- Notify terrarium to add lizard (score shows on banner only, not on screen)
	local onCaught = ReplicatedStorage:FindFirstChild("OnLizardCaught")
	if onCaught and onCaught:IsA("BindableEvent") then
		onCaught:Fire(player, lizardType)
	end
	
	lizard:Destroy()
	return true
end

-- When player presses E or taps CATCH (from client)
catchRequest.OnServerEvent:Connect(function(player)
	local character = player.Character
	if not character then return end
	
	local humanoid = character:FindFirstChild("Humanoid")
	if not humanoid or humanoid.Health <= 0 then return end
	
	local playerRoot = character:FindFirstChild("HumanoidRootPart")
	if not playerRoot then return end
	
	local lizardsFolder = Workspace:WaitForChild("Lizards", 5)
	if not lizardsFolder then return end
	
	local playerPos = playerRoot.Position
	
	-- Find nearest lizard in range (check Body part or PrimaryPart)
	local nearestLizard = nil
	local nearestDist = CATCH_RANGE
	
	for _, lizard in pairs(lizardsFolder:GetChildren()) do
		if not lizard:IsA("Model") then
			-- Skip non-models (folders, etc.)
		else
		-- Get position from PrimaryPart, Body, or any Part
		local rootPart = lizard.PrimaryPart or lizard:FindFirstChild("Body") or lizard:FindFirstChildWhichIsA("BasePart")
		if rootPart then
			local dist = (rootPart.Position - playerPos).Magnitude
			if dist < nearestDist then
				nearestDist = dist
				nearestLizard = lizard
			end
		end
		end
	end
	
	if nearestLizard then
		local ok, err = pcall(function()
			catchLizard(player, nearestLizard)
		end)
		if not ok then
			warn("[CatchController] Error catching:", err)
		end
	end
end)

print("CatchController: Ready! Press E near a lizard to catch it.")
