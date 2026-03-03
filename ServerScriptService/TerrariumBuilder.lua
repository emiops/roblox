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

-- Lizard/creature type -> color
local LIZARD_TYPE_COLORS = {
	GreenLizard = Color3.fromRGB(34, 139, 34),
	BrownLizard = Color3.fromRGB(139, 90, 43),
	GrayLizard = Color3.fromRGB(128, 128, 128),
	TanLizard = Color3.fromRGB(210, 180, 140),
	OliveLizard = Color3.fromRGB(85, 107, 47),
	EmeraldLizard = Color3.fromRGB(60, 179, 113),
	RolliePollie = Color3.fromRGB(90, 88, 82),
}

-- U-shaped terrarium: left arm, right arm, back. Opening in front center.
local U_ARM_WIDTH = 10       -- Each arm width
local U_ARM_DEPTH = 12       -- Arm depth (front to back)
local U_BACK_WIDTH = 12      -- Back section width
local U_GAP_WIDTH = 8       -- Front center opening
local U_HEIGHT = 8
local TERRARIUM_BASE_POSITION = Vector3.new(0, 10, 30)  -- Near spawn, visible
local DISPLAY_LIZARD_SCALE = 0.8  -- 2x bigger (was 0.4)
local LIZARD_SPACING = 2.0

-- Interior bounds: lizards live in GREEN areas only, cannot pass through glass into white walkable area
-- Left arm: X [-14,-6.5], Z [-6,5]  |  Right arm: X [6.5,14], Z [-6,5]  |  Back: X [-6,6], Z [-6,-2.5]
local U_BOUNDS = {
	{ xMin = -14, xMax = -6.5, zMin = -6, zMax = 5 },   -- left green arm (lizard habitat)
	{ xMin = 6.5, xMax = 14, zMin = -6, zMax = 5 },    -- right green arm (lizard habitat)
	{ xMin = -6, xMax = 6, zMin = -6, zMax = -2.5 },   -- back green (lizard habitat)
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

local function createDisplayRolliePollie(position, rotationY)
	-- Same size as lizards (caterpillar shape)
	local scale = DISPLAY_LIZARD_SCALE
	local segW, segH, segL = 0.22 * scale, 0.2 * scale, 0.35 * scale
	
	local model = Instance.new("Model")
	model.Name = "RolliePollie"
	
	for i = 1, 5 do
		local seg = Instance.new("Part")
		seg.Name = "Segment" .. i
		seg.Shape = Enum.PartType.Block
		seg.Size = Vector3.new(segW, segH, segL)
		seg.Color = (i % 2 == 1) and Color3.fromRGB(90, 88, 82) or Color3.fromRGB(75, 73, 68)
		seg.Anchored = true
		seg.CanCollide = false
		seg.Parent = model
	end
	
	-- Ball for rolled-up state (like real life)
	local ball = Instance.new("Part")
	ball.Name = "Ball"
	ball.Shape = Enum.PartType.Ball
	ball.Size = Vector3.new(0.4 * scale, 0.4 * scale, 0.4 * scale)
	ball.Color = Color3.fromRGB(85, 83, 78)
	ball.Anchored = true
	ball.CanCollide = false
	ball.Transparency = 1
	ball.Parent = model
	
	model.PrimaryPart = model:FindFirstChild("Segment3")
	local baseCF = CFrame.new(position) * CFrame.Angles(0, rotationY, 0)
	local cfValue = Instance.new("CFrameValue")
	cfValue.Name = "BaseCF"
	cfValue.Value = baseCF
	cfValue.Parent = model
	local phaseValue = Instance.new("NumberValue")
	phaseValue.Name = "Phase"
	phaseValue.Value = math.random() * 100
	phaseValue.Parent = model
	model:SetAttribute("IsRolliePollie", true)
	
	for i = 1, 5 do
		local seg = model:FindFirstChild("Segment" .. i)
		if seg then
			local offset = (i - 3) * segL * 0.85
			seg.CFrame = baseCF * CFrame.new(0, 0, offset)
		end
	end
	local ball = model:FindFirstChild("Ball")
	if ball then ball.CFrame = baseCF end
	
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
	
	-- Center floor (under walkable area - gap between left/right arms)
	local floorCenter = Instance.new("Part")
	floorCenter.Name = "FloorCenter"
	floorCenter.Size = Vector3.new(U_GAP_WIDTH + 1, 0.5, U_ARM_DEPTH - 2)
	floorCenter.Position = pos + Vector3.new(0, 0, 2)
	floorCenter.Color = Color3.fromRGB(90, 85, 80)
	floorCenter.Material = Enum.Material.Concrete
	floorCenter.Anchored = true
	floorCenter.CanCollide = true
	floorCenter.Parent = terrarium
	
	-- U-shaped interior ground (grass) - GREEN lizard habitat
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
	leftGlass.Transparency = 0.7  -- More transparent to see through
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
	rightGlass.Transparency = 0.7  -- More transparent to see through
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
		top.Transparency = 0.7  -- More transparent to see through
		top.Anchored = true
		top.CanCollide = true
		top.Parent = terrarium
	end
	
	-- Front outer glass walls (where banner stands): complete the terrarium enclosure. Center gap remains as entrance.
	local frontGlassLeft = Instance.new("Part")
	frontGlassLeft.Name = "FrontGlassLeft"
	frontGlassLeft.Size = Vector3.new(8, U_HEIGHT + 1, 0.3)
	frontGlassLeft.Position = pos + Vector3.new(-10, U_HEIGHT/2, U_ARM_DEPTH/2 + 0.5)
	frontGlassLeft.Color = Color3.fromRGB(200, 230, 255)
	frontGlassLeft.Material = Enum.Material.Glass
	frontGlassLeft.Transparency = 0.7
	frontGlassLeft.Anchored = true
	frontGlassLeft.CanCollide = true
	frontGlassLeft.Parent = terrarium
	
	local frontGlassRight = Instance.new("Part")
	frontGlassRight.Name = "FrontGlassRight"
	frontGlassRight.Size = Vector3.new(8, U_HEIGHT + 1, 0.3)
	frontGlassRight.Position = pos + Vector3.new(10, U_HEIGHT/2, U_ARM_DEPTH/2 + 0.5)
	frontGlassRight.Color = Color3.fromRGB(200, 230, 255)
	frontGlassRight.Material = Enum.Material.Glass
	frontGlassRight.Transparency = 0.7
	frontGlassRight.Anchored = true
	frontGlassRight.CanCollide = true
	frontGlassRight.Parent = terrarium
	
	-- Inner glass walls: separate green (lizard habitat) from white (walkable). Lizards cannot pass through.
	-- Left inner wall (between left green arm and white center)
	local innerGlassLeft = Instance.new("Part")
	innerGlassLeft.Name = "InnerGlassLeft"
	innerGlassLeft.Size = Vector3.new(0.3, U_HEIGHT + 1, 8)
	innerGlassLeft.Position = pos + Vector3.new(-6, U_HEIGHT/2, 2)
	innerGlassLeft.Color = Color3.fromRGB(200, 230, 255)
	innerGlassLeft.Material = Enum.Material.Glass
	innerGlassLeft.Transparency = 0.7
	innerGlassLeft.Anchored = true
	innerGlassLeft.CanCollide = true
	innerGlassLeft.Parent = terrarium
	
	-- Right inner wall
	local innerGlassRight = Instance.new("Part")
	innerGlassRight.Name = "InnerGlassRight"
	innerGlassRight.Size = Vector3.new(0.3, U_HEIGHT + 1, 8)
	innerGlassRight.Position = pos + Vector3.new(6, U_HEIGHT/2, 2)
	innerGlassRight.Color = Color3.fromRGB(200, 230, 255)
	innerGlassRight.Material = Enum.Material.Glass
	innerGlassRight.Transparency = 0.7
	innerGlassRight.Anchored = true
	innerGlassRight.CanCollide = true
	innerGlassRight.Parent = terrarium
	
	-- Back inner wall (between back green and white center)
	local innerGlassBack = Instance.new("Part")
	innerGlassBack.Name = "InnerGlassBack"
	innerGlassBack.Size = Vector3.new(12, U_HEIGHT + 1, 0.3)
	innerGlassBack.Position = pos + Vector3.new(0, U_HEIGHT/2, -2)
	innerGlassBack.Color = Color3.fromRGB(200, 230, 255)
	innerGlassBack.Material = Enum.Material.Glass
	innerGlassBack.Transparency = 0.7
	innerGlassBack.Anchored = true
	innerGlassBack.CanCollide = true
	innerGlassBack.Parent = terrarium
	
	-- White walkable floor (center area where players walk)
	local walkableFloor = Instance.new("Part")
	walkableFloor.Name = "WalkableFloor"
	walkableFloor.Size = Vector3.new(U_GAP_WIDTH - 0.5, 0.4, 8)
	walkableFloor.Position = pos + Vector3.new(0, 0.7, 2)
	walkableFloor.Color = Color3.fromRGB(240, 240, 235)
	walkableFloor.Material = Enum.Material.Concrete
	walkableFloor.Anchored = true
	walkableFloor.CanCollide = true
	walkableFloor.Parent = terrarium
	
	-- Rocks in green lizard habitat areas
	for _, region in ipairs(U_BOUNDS) do
		for _ = 1, 8 do
			local rx = region.xMin + 0.5 + math.random() * (region.xMax - region.xMin - 1)
			local rz = region.zMin + 0.5 + math.random() * (region.zMax - region.zMin - 1)
			local rock = Instance.new("Part")
			rock.Name = "Rock"
			rock.Shape = Enum.PartType.Ball
			rock.Size = Vector3.new(0.3 + math.random() * 0.5, 0.2 + math.random() * 0.4, 0.3 + math.random() * 0.5)
			rock.Position = pos + Vector3.new(rx, 0.7 + rock.Size.Y/2, rz)
			rock.Color = Color3.fromRGB(100, 95, 85)
			rock.Material = Enum.Material.Slate
			rock.Anchored = true
			rock.CanCollide = true
			rock.Parent = terrarium
		end
	end
	
	-- Small trees in green lizard habitat areas
	for _, region in ipairs(U_BOUNDS) do
		for _ = 1, 4 do
			local rx = region.xMin + 1 + math.random() * (region.xMax - region.xMin - 2)
			local rz = region.zMin + 1 + math.random() * (region.zMax - region.zMin - 2)
			-- Trunk
			local trunk = Instance.new("Part")
			trunk.Name = "TreeTrunk"
			trunk.Size = Vector3.new(0.4, 1.2, 0.4)
			trunk.Position = pos + Vector3.new(rx, 1.3, rz)
			trunk.Color = Color3.fromRGB(80, 55, 35)
			trunk.Material = Enum.Material.Wood
			trunk.Anchored = true
			trunk.CanCollide = true
			trunk.Parent = terrarium
			-- Foliage (small bush/tree top)
			local foliage = Instance.new("Part")
			foliage.Name = "TreeFoliage"
			foliage.Shape = Enum.PartType.Ball
			foliage.Size = Vector3.new(1.2, 1.2, 1.2)
			foliage.Position = pos + Vector3.new(rx, 2.2, rz)
			foliage.Color = Color3.fromRGB(40, 100, 50)
			foliage.Material = Enum.Material.Grass
			foliage.Anchored = true
			foliage.CanCollide = false
			foliage.Parent = terrarium
		end
	end
	
	return terrarium
end

-- Street-style banner: two poles, horizontal banner between them above the terrarium (player name + score)
local BANNER_SPAN = 20
local BANNER_HEIGHT = U_HEIGHT + 3
local function buildScoreBanner(player, terrarium)
	local terrariumPos = getTerrariumPosition(player)
	local pos = terrariumPos + Vector3.new(0, BANNER_HEIGHT, U_ARM_DEPTH/2 + 2)
	local banner = Instance.new("Model")
	banner.Name = "ScoreBanner_" .. player.Name
	
	-- Left pole
	local poleLeft = Instance.new("Part")
	poleLeft.Name = "PoleLeft"
	poleLeft.Size = Vector3.new(0.6, BANNER_HEIGHT, 0.6)
	poleLeft.Position = terrariumPos + Vector3.new(-BANNER_SPAN/2, BANNER_HEIGHT/2, U_ARM_DEPTH/2 + 2)
	poleLeft.Color = Color3.fromRGB(60, 60, 65)
	poleLeft.Material = Enum.Material.Metal
	poleLeft.Anchored = true
	poleLeft.CanCollide = true
	poleLeft.Parent = banner
	
	-- Right pole
	local poleRight = Instance.new("Part")
	poleRight.Name = "PoleRight"
	poleRight.Size = Vector3.new(0.6, BANNER_HEIGHT, 0.6)
	poleRight.Position = terrariumPos + Vector3.new(BANNER_SPAN/2, BANNER_HEIGHT/2, U_ARM_DEPTH/2 + 2)
	poleRight.Color = Color3.fromRGB(60, 60, 65)
	poleRight.Material = Enum.Material.Metal
	poleRight.Anchored = true
	poleRight.CanCollide = true
	poleRight.Parent = banner
	
	-- Horizontal banner sign (street-style, suspended between poles)
	-- Rotate 180° so text faces entrance (positive Z)
	local sign = Instance.new("Part")
	sign.Name = "Sign"
	sign.Size = Vector3.new(BANNER_SPAN - 2, 2.5, 0.4)  -- Wide horizontal street banner
	sign.CFrame = CFrame.new(pos) * CFrame.Angles(0, math.pi, 0)
	sign.Color = Color3.fromRGB(45, 55, 70)
	sign.Material = Enum.Material.Metal
	sign.Anchored = true
	sign.CanCollide = false
	sign.Parent = banner
	
	-- SurfaceGui: player name + score on banner face (visible on terrarium, not on screen)
	local surfaceGui = Instance.new("SurfaceGui")
	surfaceGui.Name = "BannerGui"
	surfaceGui.Face = Enum.NormalId.Front
	surfaceGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	surfaceGui.PixelsPerStud = 50
	surfaceGui.LightInfluence = 0  -- Always readable in any lighting
	surfaceGui.Parent = sign
	
	local label = Instance.new("TextLabel")
	label.Name = "ScoreLabel"
	label.Size = UDim2.new(1, 0, 1, 0)
	label.Position = UDim2.new(0, 0, 0, 0)
	label.BackgroundTransparency = 1
	label.Text = player.Name .. "\n0 creatures caught"
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextSize = 48
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.TextWrapped = true
	label.Rotation = 0
	label.Parent = surfaceGui
	
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
	local gui = sign:FindFirstChild("BannerGui")  -- SurfaceGui or BillboardGui
	if not gui then return end
	local label = gui:FindFirstChild("ScoreLabel")
	if not label then return end
	local total = LizardInventory.GetTotal(player)
	label.Text = player.Name .. "\n" .. total .. " creature" .. (total == 1 and "" or "s") .. " caught"
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
	for creatureType, count in pairs(all) do
		for _ = 1, count do
			index = index + 1
			local pos = positions[index] or (center + Vector3.new((index % 5 - 2) * 2, 1.02, math.floor(index / 5) * 2))
			local rotY = math.random() * math.pi * 2
			local display = (creatureType == "RolliePollie") and createDisplayRolliePollie(pos, rotY) or createDisplayLizard(creatureType, pos, rotY)
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

-- Create terrarium for each player on join (don't wait for character - spawn immediately)
local function setupTerrariumForPlayer(player)
	local ok, err = pcall(function()
		local terrarium = getOrCreateTerrarium(player)
		refreshTerrariumLizards(terrarium, player)
		updateScoreBanner(player)
	end)
	if not ok then
		warn("[TerrariumBuilder] Error for", player.Name, ":", err)
	end
end

Players.PlayerAdded:Connect(function(player)
	task.spawn(function()
		task.wait(0.5)  -- Brief delay for inventory
		setupTerrariumForPlayer(player)
	end)
end)

-- Existing players - create terrarium immediately
for _, player in pairs(Players:GetPlayers()) do
	task.spawn(function()
		setupTerrariumForPlayer(player)
	end)
end

-- Animate display lizards (tail sway, head bob, slight wander) - clamped to U bounds
local t = 0
local function onHeartbeat(dt)
	t = t + dt
	for _, terrarium in pairs(terrariumsFolder:GetChildren()) do
		local centerVal = terrarium:FindFirstChild("Center")
		if centerVal then
			local center = centerVal.Value
			local displayFolder = terrarium:FindFirstChild("DisplayLizards")
			if displayFolder then
				for _, model in pairs(displayFolder:GetChildren()) do
					if model:IsA("Model") then
						local body = model:FindFirstChild("Body") or model:FindFirstChild("Segment3")
						local baseCFVal = model:FindFirstChild("BaseCF")
						local phaseVal = model:FindFirstChild("Phase")
						if body and baseCFVal then
							local baseCF = baseCFVal.Value
							local phase = phaseVal and phaseVal.Value or 0
							local scale = DISPLAY_LIZARD_SCALE
							local isRolliePollie = model:GetAttribute("IsRolliePollie")
							
							if isRolliePollie then
								-- Rollie-pollie (caterpillar): move, NO jump, sometimes roll into ball
								local segL = 0.35 * scale
								local wander = math.sin(t * 1 + phase * 0.5) * 0.1
								local localX = baseCF.Position.X - center.X + math.sin(t * 0.5 + phase) * wander
								local localZ = baseCF.Position.Z - center.Z + math.cos(t * 0.4 + phase) * wander
								local clampedX, clampedZ = clampToUBounds(localX, localZ)
								local rotY = math.sin(t * 0.6 + phase) * 0.15
								local worldPos = center + Vector3.new(clampedX, baseCF.Position.Y - center.Y, clampedZ)
								local bodyCF = CFrame.new(worldPos) * (baseCF - baseCF.Position) * CFrame.Angles(0, rotY, 0)
								
								-- Sometimes roll into ball (like real life) - use phase for consistent per-creature timing
								local rollCycle = math.sin(t * 0.4 + phase * 2) 
								local isRolled = rollCycle > 0.7
								
								local ball = model:FindFirstChild("Ball")
								for i = 1, 5 do
									local seg = model:FindFirstChild("Segment" .. i)
									if seg then
										seg.Transparency = isRolled and 1 or 0
										if not isRolled then
											local offset = (i - 3) * segL * 0.85
											seg.CFrame = bodyCF * CFrame.new(0, 0, offset)
										end
									end
								end
								if ball then
									ball.Transparency = isRolled and 0 or 1
									ball.CFrame = bodyCF
								end
							else
								-- Lizard: move + jump
								local head = model:FindFirstChild("Head")
								local tail1 = model:FindFirstChild("Tail1")
								local tail2 = model:FindFirstChild("Tail2")
								local stripe = model:FindFirstChild("Stripe")
								if body and head and tail1 and tail2 and stripe then
									local sway = math.sin(t * 3 + phase) * 0.1
									local wander = math.sin(t * 1 + phase * 0.5) * 0.12
									local localX = baseCF.Position.X - center.X + math.sin(t * 0.5 + phase) * wander
									local localZ = baseCF.Position.Z - center.Z + math.cos(t * 0.4 + phase) * wander
									local clampedX, clampedZ = clampToUBounds(localX, localZ)
									local rotY = math.sin(t * 0.6 + phase) * 0.2
									local jumpOffset = math.max(0, math.sin(t * 2.5 + phase * 1.3)) * 0.25
									local worldPos = center + Vector3.new(clampedX, baseCF.Position.Y - center.Y + jumpOffset, clampedZ)
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
	end
end
RunService.Heartbeat:Connect(onHeartbeat)

print("[TerrariumBuilder] Terrarium ready! Caught lizards will appear inside.")
