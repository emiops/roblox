--[[
	FlowerSpawner - Scatters colorful flowers across the grass
	Place in ServerScriptService
]]

local Workspace = game:GetService("Workspace")

local FLOWER_COUNT = 120
local SPAWN_RADIUS = 80
local MIN_DISTANCE_BETWEEN = 3

local FLOWER_TYPES = {
	{name = "Daisy",    petalColor = Color3.fromRGB(255, 255, 255), centerColor = Color3.fromRGB(255, 220, 50),  petals = 6,  petalSize = 0.35},
	{name = "Poppy",    petalColor = Color3.fromRGB(220, 40, 40),   centerColor = Color3.fromRGB(30, 30, 30),    petals = 5,  petalSize = 0.4},
	{name = "Bluebell", petalColor = Color3.fromRGB(80, 120, 220),  centerColor = Color3.fromRGB(220, 220, 100), petals = 5,  petalSize = 0.3},
	{name = "Tulip",    petalColor = Color3.fromRGB(230, 80, 180),  centerColor = Color3.fromRGB(255, 230, 100), petals = 4,  petalSize = 0.45},
	{name = "Sunflower",petalColor = Color3.fromRGB(255, 200, 30),  centerColor = Color3.fromRGB(100, 60, 20),   petals = 10, petalSize = 0.3},
	{name = "Violet",   petalColor = Color3.fromRGB(140, 60, 200),  centerColor = Color3.fromRGB(255, 255, 150), petals = 5,  petalSize = 0.3},
	{name = "Rose",     petalColor = Color3.fromRGB(200, 30, 60),   centerColor = Color3.fromRGB(220, 180, 50),  petals = 7,  petalSize = 0.25},
	{name = "Buttercup",petalColor = Color3.fromRGB(255, 240, 60),  centerColor = Color3.fromRGB(200, 160, 30),  petals = 5,  petalSize = 0.3},
}

local flowersFolder = Instance.new("Folder")
flowersFolder.Name = "Flowers"
flowersFolder.Parent = Workspace

local spawnedPositions = {}

local function getGroundPosition(x, z)
	local origin = Vector3.new(x, 300, z)
	local rayParams = RaycastParams.new()
	rayParams.FilterDescendantsInstances = {flowersFolder}
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	local result = Workspace:Raycast(origin, Vector3.new(0, -600, 0), rayParams)
	if result then
		local terrariums = Workspace:FindFirstChild("Terrariums")
		if terrariums and result.Instance:IsDescendantOf(terrariums) then
			return nil
		end
		return result.Position
	end
	return nil
end

local function isTooClose(pos)
	for _, existing in ipairs(spawnedPositions) do
		if (pos - existing).Magnitude < MIN_DISTANCE_BETWEEN then
			return true
		end
	end
	return false
end

local function createFlower(groundPos)
	local flowerType = FLOWER_TYPES[math.random(1, #FLOWER_TYPES)]
	local scale = 0.6 + math.random() * 0.8
	local yaw = math.random() * math.pi * 2

	local model = Instance.new("Model")
	model.Name = flowerType.name

	local stemHeight = (0.4 + math.random() * 0.4) * scale
	local stem = Instance.new("Part")
	stem.Name = "Stem"
	stem.Shape = Enum.PartType.Cylinder
	stem.Size = Vector3.new(stemHeight, 0.08 * scale, 0.08 * scale)
	stem.Color = Color3.fromRGB(50, 140, 40)
	stem.Material = Enum.Material.SmoothPlastic
	stem.Anchored = true
	stem.CanCollide = false
	stem.CFrame = CFrame.new(groundPos + Vector3.new(0, stemHeight / 2, 0))
		* CFrame.Angles(0, 0, math.rad(90))
	stem.Parent = model

	local topPos = groundPos + Vector3.new(0, stemHeight, 0)

	local center = Instance.new("Part")
	center.Name = "Center"
	center.Shape = Enum.PartType.Ball
	local centerSize = 0.12 * scale
	center.Size = Vector3.new(centerSize, centerSize, centerSize)
	center.Color = flowerType.centerColor
	center.Material = Enum.Material.SmoothPlastic
	center.Anchored = true
	center.CanCollide = false
	center.CFrame = CFrame.new(topPos)
	center.Parent = model

	local petalCount = flowerType.petals
	for i = 1, petalCount do
		local angle = yaw + (i - 1) * (math.pi * 2 / petalCount)
		local petal = Instance.new("Part")
		petal.Name = "Petal" .. i
		petal.Shape = Enum.PartType.Ball
		local ps = flowerType.petalSize * scale
		petal.Size = Vector3.new(ps, ps * 0.4, ps)
		petal.Color = flowerType.petalColor
		petal.Material = Enum.Material.SmoothPlastic
		petal.Anchored = true
		petal.CanCollide = false
		local offset = ps * 0.55
		petal.CFrame = CFrame.new(
			topPos.X + math.cos(angle) * offset,
			topPos.Y,
			topPos.Z + math.sin(angle) * offset
		)
		petal.Parent = model
	end

	if math.random() < 0.5 then
		local leafScale = 0.2 * scale
		local leaf = Instance.new("Part")
		leaf.Name = "Leaf"
		leaf.Shape = Enum.PartType.Ball
		leaf.Size = Vector3.new(leafScale * 1.5, leafScale * 0.3, leafScale)
		leaf.Color = Color3.fromRGB(60, 160, 50)
		leaf.Material = Enum.Material.SmoothPlastic
		leaf.Anchored = true
		leaf.CanCollide = false
		local leafHeight = stemHeight * (0.3 + math.random() * 0.3)
		local leafAngle = math.random() * math.pi * 2
		leaf.CFrame = CFrame.new(
			groundPos.X + math.cos(leafAngle) * 0.1 * scale,
			groundPos.Y + leafHeight,
			groundPos.Z + math.sin(leafAngle) * 0.1 * scale
		) * CFrame.Angles(0, leafAngle, math.rad(30))
		leaf.Parent = model
	end

	model.PrimaryPart = center
	model.Parent = flowersFolder
	return model
end

local placed = 0
local attempts = 0
while placed < FLOWER_COUNT and attempts < FLOWER_COUNT * 5 do
	attempts = attempts + 1
	local x = math.random(-SPAWN_RADIUS, SPAWN_RADIUS)
	local z = math.random(-SPAWN_RADIUS, SPAWN_RADIUS)
	local ground = getGroundPosition(x, z)
	if ground and not isTooClose(ground) then
		createFlower(ground)
		table.insert(spawnedPositions, ground)
		placed = placed + 1
	end
end

print("[FlowerSpawner] Placed " .. placed .. " flowers across the grass!")
