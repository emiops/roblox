--[[
	LizardManager - Spawns and manages lizards with different sizes, colors, and escape behavior
	Place this in ServerScriptService
]]

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

-- Lizard configurations: different colors and size ranges
local LIZARD_VARIANTS = {
	{ color = Color3.fromRGB(34, 139, 34), sizeRange = {0.5, 1.2}, name = "Green Lizard" },      -- Forest green
	{ color = Color3.fromRGB(139, 90, 43), sizeRange = {0.4, 1.0}, name = "Brown Lizard" },      -- Saddle brown
	{ color = Color3.fromRGB(128, 128, 128), sizeRange = {0.6, 1.4}, name = "Gray Lizard" },     -- Gray
	{ color = Color3.fromRGB(210, 180, 140), sizeRange = {0.5, 1.1}, name = "Tan Lizard" },     -- Tan
	{ color = Color3.fromRGB(85, 107, 47), sizeRange = {0.4, 0.9}, name = "Olive Lizard" },     -- Dark olive
	{ color = Color3.fromRGB(60, 179, 113), sizeRange = {0.7, 1.3}, name = "Emerald Lizard" },   -- Medium sea green
}

local ESCAPE_DISTANCE = 12
local ESCAPE_SPEED = 14
local SPAWN_INTERVAL = 8
local MAX_LIZARDS = 25
local SPAWN_RADIUS = 80

local lizardsFolder
local lizardTemplate

-- Create lizard template (simple lizard shape - user can replace with custom model)
local function createLizardTemplate()
	local template = Instance.new("Model")
	template.Name = "Lizard"
	
	-- Body (main part)
	local body = Instance.new("Part")
	body.Name = "Body"
	body.Shape = Enum.PartType.Block
	body.Anchored = false
	body.CanCollide = true
	body.Size = Vector3.new(1.5, 0.4, 0.8)
	body.Parent = template
	
	-- Head
	local head = Instance.new("Part")
	head.Name = "Head"
	head.Shape = Enum.PartType.Block
	head.Anchored = false
	head.CanCollide = true
	head.Size = Vector3.new(0.5, 0.4, 0.5)
	head.Position = Vector3.new(0.9, 0, 0)
	head.Parent = template
	
	-- Tail
	local tail = Instance.new("Part")
	tail.Name = "Tail"
	tail.Shape = Enum.PartType.Block
	tail.Anchored = false
	tail.CanCollide = true
	tail.Size = Vector3.new(0.8, 0.3, 0.4)
	tail.Position = Vector3.new(-1.1, 0, 0)
	tail.Parent = template
	
	-- Weld parts together
	local function weld(part0, part1)
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = part0
		weld.Part1 = part1
		weld.Parent = part0
	end
	weld(body, head)
	weld(body, tail)
	
	-- HumanoidRootPart for movement (invisible)
	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Anchored = false
	root.CanCollide = false
	root.Transparency = 1
	root.Size = Vector3.new(0.2, 0.2, 0.2)
	root.Parent = template
	weld(body, root)
	
	-- PrimaryPart for model
	template.PrimaryPart = body
	
	return template
end

local function createLizard(variant, position)
	local lizard = lizardTemplate:Clone()
	local scale = variant.sizeRange[1] + (variant.sizeRange[2] - variant.sizeRange[1]) * math.random()
	
	-- Scale the lizard
	for _, part in pairs(lizard:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Size = part.Size * scale
			part.Color = variant.color
		end
	end
	
	lizard.Name = variant.name .. "_" .. math.random(1000, 9999)
	lizard:SetPrimaryPartCFrame(CFrame.new(position))
	
	-- Add escape script to each lizard
	local escapeScript = Instance.new("Script")
	escapeScript.Name = "EscapeBehavior"
	escapeScript.Source = [[
		local lizard = script.Parent
		local root = lizard.PrimaryPart
		local ESCAPE_DIST = 12
		local ESCAPE_SPD = 14
		
		while true do
			task.wait(0.1)
			if not root or not root.Parent then break end
			
			local nearestPlayer, nearestDist = nil, math.huge
			for _, player in pairs(game.Players:GetPlayers()) do
				local char = player.Character
				if char and char:FindFirstChild("HumanoidRootPart") then
					local dist = (char.HumanoidRootPart.Position - root.Position).Magnitude
					if dist < nearestDist then
						nearestDist = dist
						nearestPlayer = player
					end
				end
			end
			
			if nearestPlayer and nearestDist < ESCAPE_DIST then
				local runDir = (root.Position - nearestPlayer.Character.HumanoidRootPart.Position).Unit
				root.CFrame = root.CFrame + runDir * ESCAPE_SPD * 0.1
			end
		end
	]]
	escapeScript.Parent = lizard
	
	lizard.Parent = lizardsFolder
	return lizard
end

local function findSpawnPosition()
	local spawnPos = Vector3.new(
		math.random(-SPAWN_RADIUS, SPAWN_RADIUS),
		5,
		math.random(-SPAWN_RADIUS, SPAWN_RADIUS)
	)
	
	-- Raycast down to find ground
	local rayParams = RaycastParams.new()
	rayParams.FilterDescendantsInstances = {game.Players:GetPlayers()[1] and game.Players[1].Character or {}}
	
	local result = Workspace:Raycast(spawnPos, Vector3.new(0, -100, 0), rayParams)
	if result then
		return result.Position + Vector3.new(0, 1, 0)
	end
	return spawnPos
end

local function spawnLizard()
	if #lizardsFolder:GetChildren() >= MAX_LIZARDS then return end
	
	local variant = LIZARD_VARIANTS[math.random(1, #LIZARD_VARIANTS)]
	local position = findSpawnPosition()
	createLizard(variant, position)
end

-- Initialize
lizardsFolder = Workspace:FindFirstChild("Lizards") or Instance.new("Folder")
lizardsFolder.Name = "Lizards"
lizardsFolder.Parent = Workspace

lizardTemplate = createLizardTemplate()
lizardTemplate.Parent = nil

-- Spawn loop
task.spawn(function()
	while true do
		spawnLizard()
		task.wait(SPAWN_INTERVAL)
	end
end)

-- Initial spawns
for i = 1, 5 do
	task.wait(0.5)
	spawnLizard()
end

print("LizardManager: Lizards spawning!")
