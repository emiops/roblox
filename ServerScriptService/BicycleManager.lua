--[[
	BicycleManager - Creates a pink bicycle with basket and rabbit for player to ride
	Place in ServerScriptService
]]

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local BICYCLE_SPAWN_POSITION = Vector3.new(8, 0, 8)
local PINK_COLOR = Color3.fromRGB(255, 105, 180)
local PINK_DARK = Color3.fromRGB(220, 80, 150)

local function getGroundPosition()
	local origin = BICYCLE_SPAWN_POSITION + Vector3.new(0, 50, 0)
	local rayParams = RaycastParams.new()
	local result = Workspace:Raycast(origin, Vector3.new(0, -100, 0), rayParams)
	if result then
		return result.Position + Vector3.new(0, 0.5, 0)
	end
	return BICYCLE_SPAWN_POSITION + Vector3.new(0, 2, 0)
end

local function weld(a, b)
	local w = Instance.new("WeldConstraint")
	w.Part0 = a
	w.Part1 = b
	w.Parent = a
	return w
end

local function createRabbit()
	local model = Instance.new("Model")
	model.Name = "Rabbit"
	
	local scale = 0.4
	-- Body
	local body = Instance.new("Part")
	body.Name = "Body"
	body.Shape = Enum.PartType.Block
	body.Size = Vector3.new(0.5 * scale, 0.35 * scale, 0.6 * scale)
	body.Color = Color3.fromRGB(240, 235, 230)
	body.Material = Enum.Material.SmoothPlastic
	body.Anchored = false
	body.CanCollide = false
	body.Parent = model
	
	-- Head
	local head = Instance.new("Part")
	head.Name = "Head"
	head.Shape = Enum.PartType.Ball
	head.Size = Vector3.new(0.35 * scale, 0.35 * scale, 0.35 * scale)
	head.Color = Color3.fromRGB(245, 240, 235)
	head.Material = Enum.Material.SmoothPlastic
	head.Anchored = false
	head.CanCollide = false
	head.Parent = model
	
	-- Ears
	local earL = Instance.new("Part")
	earL.Name = "EarL"
	earL.Shape = Enum.PartType.Block
	earL.Size = Vector3.new(0.08 * scale, 0.4 * scale, 0.08 * scale)
	earL.Color = Color3.fromRGB(245, 240, 235)
	earL.Material = Enum.Material.SmoothPlastic
	earL.Anchored = false
	earL.CanCollide = false
	earL.Parent = model
	
	local earR = earL:Clone()
	earR.Name = "EarR"
	earR.Parent = model
	
	model.PrimaryPart = body
	body.CFrame = CFrame.new(0, 0, 0)
	head.CFrame = body.CFrame * CFrame.new(0, 0.2, 0.35)
	earL.CFrame = head.CFrame * CFrame.new(-0.12, 0.2, 0)
	earR.CFrame = head.CFrame * CFrame.new(0.12, 0.2, 0)
	
	weld(body, head)
	weld(head, earL)
	weld(head, earR)
	
	return model
end

local function createBicycle()
	local model = Instance.new("Model")
	model.Name = "PinkBicycle"
	
	-- VehicleSeat (main seat - player sits here)
	local seat = Instance.new("VehicleSeat")
	seat.Name = "Seat"
	seat.Size = Vector3.new(0.8, 0.3, 1.2)
	seat.Color = PINK_COLOR
	seat.Material = Enum.Material.SmoothPlastic
	seat.MaxSpeed = 25
	seat.Torque = 80
	seat.TurnSpeed = 2
	seat.Parent = model
	
	-- Frame (main body bars)
	local frameBar = Instance.new("Part")
	frameBar.Name = "FrameBar"
	frameBar.Shape = Enum.PartType.Block
	frameBar.Size = Vector3.new(0.15, 0.15, 2.2)
	frameBar.Color = PINK_DARK
	frameBar.Material = Enum.Material.SmoothPlastic
	frameBar.Parent = model
	
	local frameDown = Instance.new("Part")
	frameDown.Name = "FrameDown"
	frameDown.Shape = Enum.PartType.Block
	frameDown.Size = Vector3.new(0.12, 0.12, 1.2)
	frameDown.Color = PINK_DARK
	frameDown.Material = Enum.Material.SmoothPlastic
	frameDown.Parent = model
	
	-- Handlebars
	local handlebar = Instance.new("Part")
	handlebar.Name = "Handlebar"
	handlebar.Shape = Enum.PartType.Cylinder
	handlebar.Size = Vector3.new(0.08, 0.8, 0.08)
	handlebar.Color = PINK_DARK
	handlebar.Material = Enum.Material.SmoothPlastic
	handlebar.Orientation = Vector3.new(0, 0, 90)
	handlebar.Parent = model
	
	-- Front wheel
	local wheelFront = Instance.new("Part")
	wheelFront.Name = "WheelFront"
	wheelFront.Shape = Enum.PartType.Cylinder
	wheelFront.Size = Vector3.new(0.1, 1.2, 1.2)
	wheelFront.Color = Color3.fromRGB(40, 40, 40)
	wheelFront.Material = Enum.Material.SmoothPlastic
	wheelFront.Orientation = Vector3.new(0, 0, 90)
	wheelFront.Parent = model
	
	-- Back wheel
	local wheelBack = Instance.new("Part")
	wheelBack.Name = "WheelBack"
	wheelBack.Shape = Enum.PartType.Cylinder
	wheelBack.Size = Vector3.new(0.1, 1.2, 1.2)
	wheelBack.Color = Color3.fromRGB(40, 40, 40)
	wheelBack.Material = Enum.Material.SmoothPlastic
	wheelBack.Orientation = Vector3.new(0, 0, 90)
	wheelBack.Parent = model
	
	-- Basket
	local basket = Instance.new("Part")
	basket.Name = "Basket"
	basket.Shape = Enum.PartType.Block
	basket.Size = Vector3.new(0.6, 0.4, 0.5)
	basket.Color = Color3.fromRGB(255, 182, 193)  -- Light pink
	basket.Material = Enum.Material.SmoothPlastic
	basket.Parent = model
	
	-- Basket front (woven look - optional rim)
	local basketRim = Instance.new("Part")
	basketRim.Name = "BasketRim"
	basketRim.Shape = Enum.PartType.Block
	basketRim.Size = Vector3.new(0.65, 0.08, 0.55)
	basketRim.Color = Color3.fromRGB(200, 150, 160)
	basketRim.Material = Enum.Material.SmoothPlastic
	basketRim.Parent = model
	
	-- Position parts relative to seat (seat at origin)
	seat.CFrame = CFrame.new(0, 0, 0)
	frameBar.CFrame = seat.CFrame * CFrame.new(0, -0.2, 0)
	frameDown.CFrame = seat.CFrame * CFrame.new(0, -0.5, 0.6) * CFrame.Angles(0.4, 0, 0)
	handlebar.CFrame = seat.CFrame * CFrame.new(0, 0.3, -0.8) * CFrame.Angles(0, 0, math.rad(90))
	wheelFront.CFrame = seat.CFrame * CFrame.new(0, -0.7, -1) * CFrame.Angles(0, 0, math.rad(90))
	wheelBack.CFrame = seat.CFrame * CFrame.new(0, -0.7, 1) * CFrame.Angles(0, 0, math.rad(90))
	basket.CFrame = seat.CFrame * CFrame.new(0.5, 0.1, 0.5)
	basketRim.CFrame = basket.CFrame * CFrame.new(0, 0.25, 0)
	
	-- Weld all to seat
	weld(seat, frameBar)
	weld(seat, frameDown)
	weld(seat, handlebar)
	weld(seat, wheelFront)
	weld(seat, wheelBack)
	weld(seat, basket)
	weld(basket, basketRim)
	
	-- Rabbit in basket
	local rabbit = createRabbit()
	rabbit.Parent = model
	rabbit.PrimaryPart.CFrame = basket.CFrame * CFrame.new(0, 0.12, 0) * CFrame.Angles(0, math.rad(-15), 0)
	weld(basket, rabbit.PrimaryPart)
	
	model.PrimaryPart = seat
	model:SetAttribute("IsBicycle", true)
	
	return model
end

-- Spawn bicycle
local function spawnBicycle()
	local bike = createBicycle()
	local groundPos = getGroundPosition()
	bike:PivotTo(CFrame.new(groundPos))
	
	local bikesFolder = Workspace:FindFirstChild("Bicycles")
	if not bikesFolder then
		bikesFolder = Instance.new("Folder")
		bikesFolder.Name = "Bicycles"
		bikesFolder.Parent = Workspace
	end
	bike.Parent = bikesFolder
	
	return bike
end

-- Spawn on server start
spawnBicycle()

-- Spawn for each player when they join (optional - one bike for all, or one per player)
Players.PlayerAdded:Connect(function()
	task.wait(1)
	-- Uncomment to spawn a bike per player:
	-- spawnBicycle()
end)

-- Spawn for players already in game
for _, _ in pairs(Players:GetPlayers()) do
	-- Bike already spawned
end

print("[BicycleManager] Pink bicycle with basket and rabbit ready! Sit on it to ride. WASD to drive.")
