--[[
	RockManager - Spawns rocks with rollie-pollies underneath
	Player hits rock (F key) to reveal rollie-pollie, which escapes. Catch with E.
	Place in ServerScriptService
]]

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Rock: 3-4x lizard size (lizard ~1 stud, so rock 3-4 studs)
local ROCK_MIN_SIZE = 2.5
local ROCK_MAX_SIZE = 4
local ROCK_SPAWN_INTERVAL = 12
local MAX_ROCKS = 15
local SPAWN_RADIUS = 80
local HIT_RANGE = 8
local ROLLIE_ESCAPE_DIST = 10
local ROLLIE_ESCAPE_SPEED = 12

-- 5 rock shapes with different proportions
local ROCK_SHAPES = {
	{ shape = Enum.PartType.Block, size = Vector3.new(1, 1, 1) },
	{ shape = Enum.PartType.Ball, size = Vector3.new(1, 1, 1) },
	{ shape = Enum.PartType.Cylinder, size = Vector3.new(1, 1.2, 1) },
	{ shape = Enum.PartType.Block, size = Vector3.new(1.2, 0.6, 1) },   -- Flat wide
	{ shape = Enum.PartType.Block, size = Vector3.new(1.5, 0.5, 1.2) }, -- Slab
}

-- Realistic gray stone colors
local ROCK_COLORS = {
	Color3.fromRGB(105, 102, 98),   -- Warm gray
	Color3.fromRGB(75, 72, 68),     -- Dark gray
	Color3.fromRGB(95, 92, 88),    -- Medium gray
	Color3.fromRGB(85, 82, 78),    -- Cool gray
	Color3.fromRGB(65, 63, 60),    -- Charcoal
}

local rocksFolder = Workspace:FindFirstChild("Rocks") or Instance.new("Folder")
rocksFolder.Name = "Rocks"
rocksFolder.Parent = Workspace

local rolliePolliesFolder = Workspace:FindFirstChild("RolliePollies") or Instance.new("Folder")
rolliePolliesFolder.Name = "RolliePollies"
rolliePolliesFolder.Parent = Workspace

-- Create RemoteEvent for hitting rocks
local hitRockRequest = ReplicatedStorage:FindFirstChild("HitRockRequest")
if not hitRockRequest then
	hitRockRequest = Instance.new("RemoteEvent")
	hitRockRequest.Name = "HitRockRequest"
	hitRockRequest.Parent = ReplicatedStorage
end

local function getGroundPosition()
	local x = math.random(-SPAWN_RADIUS, SPAWN_RADIUS)
	local z = math.random(-SPAWN_RADIUS, SPAWN_RADIUS)
	local origin = Vector3.new(x, 300, z)
	local rayParams = RaycastParams.new()
	rayParams.FilterDescendantsInstances = {rocksFolder, rolliePolliesFolder}
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	local result = Workspace:Raycast(origin, Vector3.new(0, -600, 0), rayParams)
	if result then
		return result.Position
	end
	return Vector3.new(x, 5, z)
end

local function createRolliePollie(position)
	local model = Instance.new("Model")
	model.Name = "RolliePollie"
	
	-- Pill bug: oval body (gray, segmented look)
	local scale = 0.6
	local body = Instance.new("Part")
	body.Name = "Body"
	body.Shape = Enum.PartType.Ball
	body.Size = Vector3.new(0.5 * scale, 0.35 * scale, 0.7 * scale)
	body.Color = Color3.fromRGB(90, 88, 82)
	body.Material = Enum.Material.SmoothPlastic
	body.Anchored = true
	body.CanCollide = true
	body.Parent = model
	
	-- Segments (darker bands)
	for i = 1, 3 do
		local seg = Instance.new("Part")
		seg.Name = "Segment" .. i
		seg.Shape = Enum.PartType.Block
		seg.Size = Vector3.new(0.15 * scale, 0.25 * scale, 0.1 * scale)
		seg.Color = Color3.fromRGB(70, 68, 65)
		seg.Anchored = true
		seg.CanCollide = false
		seg.Parent = model
	end
	
	model.PrimaryPart = body
	model:SetPrimaryPartCFrame(CFrame.new(position + Vector3.new(0, 0.2, 0)))
	model.Parent = rolliePolliesFolder
	
	-- Position segments
	local bodyPos = body.Position
	model:FindFirstChild("Segment1").CFrame = CFrame.new(bodyPos + Vector3.new(-0.15, 0, 0))
	model:FindFirstChild("Segment2").CFrame = CFrame.new(bodyPos)
	model:FindFirstChild("Segment3").CFrame = CFrame.new(bodyPos + Vector3.new(0.15, 0, 0))
	
	-- Escape behavior (runs from player, no jump)
	local t = math.random() * 100
	RunService.Heartbeat:Connect(function(dt)
		if not body.Parent then return end
		t = t + dt
		
		local nearestDist = math.huge
		local runDir = nil
		for _, p in pairs(game.Players:GetPlayers()) do
			local char = p.Character
			if char and char:FindFirstChild("HumanoidRootPart") then
				local d = (char.HumanoidRootPart.Position - body.Position).Magnitude
				if d < nearestDist and d < ROLLIE_ESCAPE_DIST then
					nearestDist = d
					runDir = (body.Position - char.HumanoidRootPart.Position).Unit
				end
			end
		end
		
		if runDir then
			local flatDir = Vector3.new(runDir.X, 0, runDir.Z).Unit
			local newPos = body.Position + flatDir * ROLLIE_ESCAPE_SPEED * dt
			model:SetPrimaryPartCFrame(CFrame.new(newPos))
			-- Update segments
			model:FindFirstChild("Segment1").CFrame = CFrame.new(newPos + Vector3.new(-0.15, 0, 0))
			model:FindFirstChild("Segment2").CFrame = CFrame.new(newPos)
			model:FindFirstChild("Segment3").CFrame = CFrame.new(newPos + Vector3.new(0.15, 0, 0))
		end
	end)
	
	return model
end

local function createRock()
	local shapeIdx = math.random(1, #ROCK_SHAPES)
	local colorIdx = math.random(1, #ROCK_COLORS)
	local shapeData = ROCK_SHAPES[shapeIdx]
	local size = ROCK_MIN_SIZE + math.random() * (ROCK_MAX_SIZE - ROCK_MIN_SIZE)
	
	local rock = Instance.new("Part")
	rock.Name = "Rock"
	rock.Shape = shapeData.shape
	rock.Size = Vector3.new(size, size, size) * shapeData.size
	rock.Color = ROCK_COLORS[colorIdx]
	rock.Material = Enum.Material.Rock
	rock.Anchored = true
	rock.CanCollide = true
	
	local pos = getGroundPosition()
	rock.Position = pos + Vector3.new(0, rock.Size.Y / 2, 0)
	rock.Parent = rocksFolder
	
	-- Store rollie-pollie spawn position (under rock)
	rock:SetAttribute("RollieSpawnPos", pos)
	
	return rock
end

-- When player hits rock
hitRockRequest.OnServerEvent:Connect(function(player)
	local character = player.Character
	if not character or not character:FindFirstChild("HumanoidRootPart") then return end
	
	local playerPos = character.HumanoidRootPart.Position
	local nearestRock = nil
	local nearestDist = HIT_RANGE
	
	for _, rock in pairs(rocksFolder:GetChildren()) do
		if rock:IsA("BasePart") then
			local dist = (rock.Position - playerPos).Magnitude
			if dist < nearestDist then
				nearestDist = dist
				nearestRock = rock
			end
		end
	end
	
	if nearestRock then
		local spawnPos = nearestRock:GetAttribute("RollieSpawnPos") or nearestRock.Position
		nearestRock:Destroy()
		createRolliePollie(spawnPos)
	end
end)

-- Spawn loop
task.spawn(function()
	while true do
		if #rocksFolder:GetChildren() < MAX_ROCKS then
			createRock()
		end
		task.wait(ROCK_SPAWN_INTERVAL)
	end
end)

-- Initial rocks
for i = 1, 5 do
	task.wait(0.3)
	createRock()
end

print("[RockManager] Rocks with rollie-pollies spawning! Press F to hit rock, E to catch rollie-pollie.")
