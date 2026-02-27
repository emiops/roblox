--[[
	TerrariumBuilder - Creates an aquarium/box for caught lizards
	Place in ServerScriptService
	Creates a terrarium per player and displays their caught lizards inside
]]

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LizardInventory = require(ReplicatedStorage:WaitForChild("LizardInventory"))

-- Lizard type (e.g. "GreenLizard") -> color
local LIZARD_TYPE_COLORS = {
	GreenLizard = Color3.fromRGB(34, 139, 34),
	BrownLizard = Color3.fromRGB(139, 90, 43),
	GrayLizard = Color3.fromRGB(128, 128, 128),
	TanLizard = Color3.fromRGB(210, 180, 140),
	OliveLizard = Color3.fromRGB(85, 107, 47),
	EmeraldLizard = Color3.fromRGB(60, 179, 113),
}

-- U-shaped terrarium: left arm, right arm, back. Opening in front center.
local U_ARM_WIDTH = 10       -- Each arm width
local U_ARM_DEPTH = 12       -- Arm depth (front to back)
local U_BACK_WIDTH = 12      -- Back section width
local U_GAP_WIDTH = 8       -- Front center opening
local U_HEIGHT = 8
local TERRARIUM_BASE_POSITION = Vector3.new(0, 10, 30)
local DISPLAY_LIZARD_SCALE = 0.85
local LIZARD_SPACING = 2.0

-- Interior bounds (relative to terrarium center): lizards must stay inside U
-- Left arm: X [-14,-6], Z [-6,6]  |  Right arm: X [6,14], Z [-6,6]  |  Back: X [-6,6], Z [-6,-2]
local U_BOUNDS = {
	{ xMin = -14, xMax = -6, zMin = -6, zMax = 6 },   -- left arm
	{ xMin = 6, xMax = 14, zMin = -6, zMax = 6 },    -- right arm
	{ xMin = -6, xMax = 6, zMin = -6, zMax = -2 },   -- back
}

-- Create BindableEvent for catch notifications (CatchController fires this)
local onLizardCaught = ReplicatedStorage:FindFirstChild("OnLizardCaught")
if not onLizardCaught then
	onLizardCaught = Instance.new("BindableEvent")
	onLizardCaught.Name = "OnLizardCaught"
	onLizardCaught.Parent = ReplicatedStorage
end

local terrariumsFolder = Workspace:FindFirstChild("Terrariums") or Instance.new("Folder")
terrariumsFolder.Name = "Terrariums"
terrariumsFolder.Parent = Workspace

local function createDisplayLizard(lizardType, position, rotationY)
	local color = LIZARD_TYPE_COLORS[lizardType] or Color3.fromRGB(100, 100, 100)
	local darkColor = Color3.new(
		math.max(0, color.R - 0.15),
		math.max(0, color.G - 0.1),
		math.max(0, color.B - 0.05)
	)
	local scale = DISPLAY_LIZARD_SCALE
	
	local model = Instance.new("Model")
	model.Name = lizardType
	
	local body = Instance.new("Part")
	body.Name = "Body"
	body.Shape = Enum.PartType.Block
	body.Size = Vector3.new(0.45 * scale, 0.25 * scale, 1.1 * scale)
	body.Color = color
	body.Anchored = true
	body.CanCollide = false
	body.Parent = model
	
	local stripe = Instance.new("Part")
	stripe.Name = "Stripe"
	stripe.Shape = Enum.PartType.Block
	stripe.Size = Vector3.new(0.2 * scale, 0.08 * scale, 1.05 * scale)
	stripe.Color = darkColor
	stripe.Anchored = true
	stripe.CanCollide = false
	stripe.Parent = model
	
	local head = Instance.new("WedgePart")
	head.Name = "Head"
	head.Size = Vector3.new(0.35 * scale, 0.35 * scale, 0.4 * scale)
	head.Color = color
	head.Anchored = true
	head.CanCollide = false
	head.Orientation = Vector3.new(0, 90, 0)
	head.Parent = model
	
	local tail1 = Instance.new("Part")
	tail1.Name = "Tail1"
	tail1.Shape = Enum.PartType.Block
	tail1.Size = Vector3.new(0.3 * scale, 0.2 * scale, 0.7 * scale)
	tail1.Color = color
	tail1.Anchored = true
	tail1.CanCollide = false
	tail1.Parent = model
	
	local tail2 = Instance.new("Part")
	tail2.Name = "Tail2"
	tail2.Shape = Enum.PartType.Block
	tail2.Size = Vector3.new(0.22 * scale, 0.15 * scale, 0.5 * scale)
	tail2.Color = darkColor
	tail2.Anchored = true
	tail2.CanCollide = false
	tail2.Parent = model
	
	model.PrimaryPart = body
	local baseCF = CFrame.new(position) * CFrame.Angles(0, rotationY, 0)
	local cfValue = Instance.new("CFrameValue")
	cfValue.Name = "BaseCF"
	cfValue.Value = baseCF
	cfValue.Parent = model
	local phaseValue = Instance.new("NumberValue")
	phaseValue.Name = "Phase"
	phaseValue.Value = math.random() * 100
	phaseValue.Parent = model
	body.CFrame = baseCF
	stripe.CFrame = baseCF * CFrame.new(0, 0.16 * scale, 0)
	head.CFrame = baseCF * CFrame.new(0, 0.02 * scale, -0.6 * scale)
	tail1.CFrame = baseCF * CFrame.new(0, 0, 0.65 * scale)
	tail2.CFrame = baseCF * CFrame.new(0, 0, 1.0 * scale)
	
	return model
end

local function getTerrariumPosition(player)
	local idx = 0
	for i, p in pairs(Players:GetPlayers()) do
		if p == player then idx = i - 1 break end
	end
	return TERRARIUM_BASE_POSITION + Vector3.new(idx * 32, 0, 0)
end

-- Clamp position (local XZ relative to center) to stay inside U bounds
local function clampToUBounds(localX, localZ)
	for _, b in ipairs(U_BOUNDS) do
		if localX >= b.xMin and localX <= b.xMax and localZ >= b.zMin and localZ <= b.zMax then
			return localX, localZ  -- Already inside
		end
	end
	-- Outside: clamp to nearest point on U boundary
	local bestX, bestZ = localX, localZ
	local bestDist = math.huge
	for _, b in ipairs(U_BOUNDS) do
		local cx = math.clamp(localX, b.xMin, b.xMax)
		local cz = math.clamp(localZ, b.zMin, b.zMax)
		local d = (cx - localX)^2 + (cz - localZ)^2
		if d < bestDist then bestDist = d bestX, bestZ = cx, cz end
	end
	return bestX, bestZ
end

-- Get valid U positions for lizard placement (grid)
local function getUPlacementPositions(center, groundY, count)
	local positions = {}
	for _, b in ipairs(U_BOUNDS) do
		for x = b.xMin + 1, b.xMax - 1, LIZARD_SPACING do
			for z = b.zMin + 1, b.zMax - 1, LIZARD_SPACING do
				table.insert(positions, center + Vector3.new(x, groundY - center.Y, z))
			end
		end
	end
	return positions
end

local function buildTerrariumStructure(player)
	local pos = getTerrariumPosition(player)
	local terrarium = Instance.new("Model")
	terrarium.Name = "Terrarium"
	
	local centerVal = Instance.new("Vector3Value")
	centerVal.Name = "Center"
	centerVal.Value = pos
	centerVal.Parent = terrarium
	
	-- U-shaped floor: 3 wood segments
	local floorLeft = Instance.new("Part")
	floorLeft.Name = "FloorLeft"
	floorLeft.Size = Vector3.new(U_ARM_WIDTH + 0.5, 0.5, U_ARM_DEPTH + 1)
	floorLeft.Position = pos + Vector3.new(-10, 0, 0)
	floorLeft.Color = Color3.fromRGB(80, 60, 40)
	floorLeft.Material = Enum.Material.Wood
	floorLeft.Anchored = true
	floorLeft.CanCollide = true
	floorLeft.Parent = terrarium
	
	local floorRight = Instance.new("Part")
	floorRight.Name = "FloorRight"
	floorRight.Size = Vector3.new(U_ARM_WIDTH + 0.5, 0.5, U_ARM_DEPTH + 1)
	floorRight.Position = pos + Vector3.new(10, 0, 0)
	floorRight.Color = Color3.fromRGB(80, 60, 40)
	floorRight.Material = Enum.Material.Wood
	floorRight.Anchored = true
	floorRight.CanCollide = true
	floorRight.Parent = terrarium
	
	local floorBack = Instance.new("Part")
	floorBack.Name = "FloorBack"
	floorBack.Size = Vector3.new(U_BACK_WIDTH + 1, 0.5, 5)
	floorBack.Position = pos + Vector3.new(0, 0, -U_ARM_DEPTH/2 - 0.5)
	floorBack.Color = Color3.fromRGB(80, 60, 40)
	floorBack.Material = Enum.Material.Wood
	floorBack.Anchored = true
	floorBack.CanCollide = true
	floorBack.Parent = terrarium
	
	-- U-shaped interior ground (grass)
	local groundLeft = Instance.new("Part")
	groundLeft.Size = Vector3.new(U_ARM_WIDTH - 0.5, 0.4, U_ARM_DEPTH - 0.5)
	groundLeft.Position = pos + Vector3.new(-10, 0.7, 0)
	groundLeft.Color = Color3.fromRGB(60, 90, 50)
	groundLeft.Material = Enum.Material.Grass
	groundLeft.Anchored = true
	groundLeft.CanCollide = true
	groundLeft.Parent = terrarium
	
	local groundRight = Instance.new("Part")
	groundRight.Size = Vector3.new(U_ARM_WIDTH - 0.5, 0.4, U_ARM_DEPTH - 0.5)
	groundRight.Position = pos + Vector3.new(10, 0.7, 0)
	groundRight.Color = Color3.fromRGB(60, 90, 50)
	groundRight.Material = Enum.Material.Grass
	groundRight.Anchored = true
	groundRight.CanCollide = true
	groundRight.Parent = terrarium
	
	local groundBack = Instance.new("Part")
	groundBack.Size = Vector3.new(U_BACK_WIDTH - 0.5, 0.4, 4)
	groundBack.Position = pos + Vector3.new(0, 0.7, -U_ARM_DEPTH/2 - 0.5)
	groundBack.Color = Color3.fromRGB(60, 90, 50)
	groundBack.Material = Enum.Material.Grass
	groundBack.Anchored = true
	groundBack.CanCollide = true
	groundBack.Parent = terrarium
	
	-- Grass tufts in U
	for _, region in ipairs(U_BOUNDS) do
		for _ = 1, 15 do
			local rx = region.xMin + math.random() * (region.xMax - region.xMin)
			local rz = region.zMin + math.random() * (region.zMax - region.zMin)
			local tuft = Instance.new("Part")
			tuft.Name = "GrassTuft"
			tuft.Size = Vector3.new(0.15, 0.4 + math.random() * 0.3, 0.15)
			tuft.Position = pos + Vector3.new(rx, 0.9 + tuft.Size.Y/2, rz)
			tuft.Color = Color3.fromRGB(40, 120, 50)
			tuft.Material = Enum.Material.Grass
			tuft.Anchored = true
			tuft.CanCollide = false
			tuft.Parent = terrarium
		end
	end
	
	-- Back wall (full width)
	local backWall = Instance.new("Part")
	backWall.Name = "BackWall"
	backWall.Size = Vector3.new(U_BACK_WIDTH + U_ARM_WIDTH*2 + 2, U_HEIGHT + 1, 0.5)
	backWall.Position = pos + Vector3.new(0, U_HEIGHT/2, -U_ARM_DEPTH/2 - 1)
	backWall.Color = Color3.fromRGB(100, 80, 60)
	backWall.Material = Enum.Material.Wood
	backWall.Anchored = true
	backWall.CanCollide = true
	backWall.Parent = terrarium
	
	-- Glass walls OUTSIDE the U (perimeter) - you enter from front center (no glass there)
	-- Left arm: glass on outer edge
	local leftGlass = Instance.new("Part")
	leftGlass.Name = "LeftGlass"
	leftGlass.Size = Vector3.new(0.3, U_HEIGHT + 1, U_ARM_DEPTH + 1)
	leftGlass.Position = pos + Vector3.new(-14, U_HEIGHT/2, 0)
	leftGlass.Color = Color3.fromRGB(200, 230, 255)
	leftGlass.Material = Enum.Material.Glass
	leftGlass.Transparency = 0.3
	leftGlass.Anchored = true
	leftGlass.CanCollide = true
	leftGlass.Parent = terrarium
	
	-- Right arm: glass on outer edge
	local rightGlass = Instance.new("Part")
	rightGlass.Name = "RightGlass"
	rightGlass.Size = Vector3.new(0.3, U_HEIGHT + 1, U_ARM_DEPTH + 1)
	rightGlass.Position = pos + Vector3.new(14, U_HEIGHT/2, 0)
	rightGlass.Color = Color3.fromRGB(200, 230, 255)
	rightGlass.Material = Enum.Material.Glass
	rightGlass.Transparency = 0.3
	rightGlass.Anchored = true
	rightGlass.CanCollide = true
	rightGlass.Parent = terrarium
	
	-- Top/roof (curved over U - 3 glass parts)
	for i, offset in ipairs({{-10, 0}, {10, 0}, {0, -U_ARM_DEPTH/2}}) do
		local top = Instance.new("Part")
		top.Size = Vector3.new(i <= 2 and U_ARM_WIDTH or U_BACK_WIDTH, 0.3, i <= 2 and U_ARM_DEPTH or 5)
		top.Position = pos + Vector3.new(offset[1], U_HEIGHT + 0.65, offset[2])
		top.Color = Color3.fromRGB(200, 230, 255)
		top.Material = Enum.Material.Glass
		top.Transparency = 0.3
		top.Anchored = true
		top.CanCollide = true
		top.Parent = terrarium
	end
	
	return terrarium
end

-- 3D score banner: tall pole with big text (player name + lizards caught), placed high
local BANNER_HEIGHT = 28
local function buildScoreBanner(player, terrarium)
	local pos = getTerrariumPosition(player) + Vector3.new(0, BANNER_HEIGHT, U_ARM_DEPTH/2 + 4)
	local banner = Instance.new("Model")
	banner.Name = "ScoreBanner_" .. player.Name
	
	local pole = Instance.new("Part")
	pole.Name = "Pole"
	pole.Size = Vector3.new(1.1, BANNER_HEIGHT, 1.1)
	pole.Position = pos - Vector3.new(0, BANNER_HEIGHT/2, 0)
	pole.Color = Color3.fromRGB(80, 80, 90)
	pole.Material = Enum.Material.Metal
	pole.Anchored = true
	pole.CanCollide = true
	pole.Parent = banner
	
	local sign = Instance.new("Part")
	sign.Name = "Sign"
	sign.Size = Vector3.new(18, 9, 0.5)
	sign.Position = pos
	sign.Color = Color3.fromRGB(50, 60, 75)
	sign.Anchored = true
	sign.CanCollide = false
	sign.Parent = banner
	
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "BannerGui"
	billboard.Size = UDim2.new(18, 0, 9, 0)
	billboard.StudsOffset = Vector3.new(0, 0, 0)
	billboard.AlwaysOnTop = false
	billboard.Parent = sign
	
	local label = Instance.new("TextLabel")
	label.Name = "ScoreLabel"
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = player.Name .. "\n0 lizards caught"
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextSize = 96
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.Parent = billboard
	
	banner.Parent = terrarium
	return label
end

local function updateScoreBanner(player)
	local terrarium = terrariumsFolder:FindFirstChild("Terrarium_" .. player.Name)
	if not terrarium then return end
	local banner = terrarium:FindFirstChild("ScoreBanner_" .. player.Name)
	if not banner then return end
	local sign = banner:FindFirstChild("Sign")
	if not sign then return end
	local gui = sign:FindFirstChild("BannerGui")
	if not gui then return end
	local label = gui:FindFirstChild("ScoreLabel")
	if not label then return end
	local total = LizardInventory.GetTotal(player)
	label.Text = player.Name .. "\n" .. total .. " lizard" .. (total == 1 and "" or "s") .. " caught"
end

local function refreshTerrariumLizards(terrarium, player)
	local displayFolder = terrarium:FindFirstChild("DisplayLizards")
	if displayFolder then
		displayFolder:Destroy()
	end
	
	displayFolder = Instance.new("Folder")
	displayFolder.Name = "DisplayLizards"
	displayFolder.Parent = terrarium
	
	local center = terrarium:FindFirstChild("Center") and terrarium.Center.Value or getTerrariumPosition(player)
	local groundY = center.Y + 1.02
	local positions = getUPlacementPositions(center, groundY, 999)
	
	local index = 0
	local all = LizardInventory.GetAll(player)
	for lizardType, count in pairs(all) do
		for _ = 1, count do
			index = index + 1
			local pos = positions[index] or (center + Vector3.new((index % 5 - 2) * 2, 1.02, math.floor(index / 5) * 2))
			local rotY = math.random() * math.pi * 2
			local display = createDisplayLizard(lizardType, pos, rotY)
			display.Parent = displayFolder
		end
	end
end

local function getOrCreateTerrarium(player)
	local terrarium = terrariumsFolder:FindFirstChild("Terrarium_" .. player.Name)
	if not terrarium then
		terrarium = buildTerrariumStructure(player)
		terrarium.Name = "Terrarium_" .. player.Name
		terrarium.Parent = terrariumsFolder
		buildScoreBanner(player, terrarium)
		updateScoreBanner(player)
	end
	return terrarium
end

-- When a lizard is caught, add it to the terrarium and update banner
onLizardCaught.Event:Connect(function(player, lizardType)
	local terrarium = getOrCreateTerrarium(player)
	refreshTerrariumLizards(terrarium, player)
	updateScoreBanner(player)
end)

-- Create terrarium for each player on join, and sync existing inventory
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Wait()
	task.wait(1)  -- Let inventory load
	local terrarium = getOrCreateTerrarium(player)
	refreshTerrariumLizards(terrarium, player)
	updateScoreBanner(player)
end)

-- Existing players
for _, player in pairs(Players:GetPlayers()) do
	task.spawn(function()
		task.wait(1)
		local terrarium = getOrCreateTerrarium(player)
		refreshTerrariumLizards(terrarium, player)
		updateScoreBanner(player)
	end)
end

-- Animate display lizards (tail sway, head bob, slight wander) - clamped to U bounds
local t = 0
RunService.Heartbeat:Connect(function(dt)
	t = t + dt
	for _, terrarium in pairs(terrariumsFolder:GetChildren()) do
		local centerVal = terrarium:FindFirstChild("Center")
		if centerVal then
		local center = centerVal.Value
		local displayFolder = terrarium:FindFirstChild("DisplayLizards")
		if displayFolder then
			for _, model in pairs(displayFolder:GetChildren()) do
				if model:IsA("Model") then
					local body = model:FindFirstChild("Body")
					local head = model:FindFirstChild("Head")
					local tail1 = model:FindFirstChild("Tail1")
					local tail2 = model:FindFirstChild("Tail2")
					local stripe = model:FindFirstChild("Stripe")
					local baseCFVal = model:FindFirstChild("BaseCF")
					local phaseVal = model:FindFirstChild("Phase")
					if body and head and tail1 and tail2 and stripe and baseCFVal then
						local baseCF = baseCFVal.Value
						local phase = phaseVal and phaseVal.Value or 0
						local scale = DISPLAY_LIZARD_SCALE
						local sway = math.sin(t * 4 + phase) * 0.12
						local wander = math.sin(t * 1.2 + phase * 0.5) * 0.15
						local localX = baseCF.Position.X - center.X + math.sin(t * 0.6 + phase) * wander
						local localZ = baseCF.Position.Z - center.Z + math.cos(t * 0.5 + phase) * wander
						local clampedX, clampedZ = clampToUBounds(localX, localZ)
						local rotY = math.sin(t * 0.8 + phase) * 0.25
						local worldPos = center + Vector3.new(clampedX, baseCF.Position.Y - center.Y, clampedZ)
						local bodyCF = CFrame.new(worldPos) * (baseCF - baseCF.Position) * CFrame.Angles(0, rotY, 0)
						body.CFrame = bodyCF
						stripe.CFrame = bodyCF * CFrame.new(0, 0.16 * scale, 0)
						head.CFrame = bodyCF * CFrame.new(0, 0.02 * scale, -0.6 * scale) * CFrame.Angles(0, 0, sway * 0.5)
						tail1.CFrame = bodyCF * CFrame.new(0, 0, 0.65 * scale) * CFrame.Angles(0, 0, sway * 1.2)
						tail2.CFrame = bodyCF * CFrame.new(0, 0, 1.0 * scale) * CFrame.Angles(0, 0, sway * 1.8)
					end
				end
			end
		end
		end
	end
end)

print("[TerrariumBuilder] Terrarium ready! Caught lizards will appear inside.")
