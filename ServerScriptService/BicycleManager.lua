--[[
	BicycleManager - Creates a pink bicycle with basket and rabbit for player to ride
	Realistic frame, seat, and steerable handlebar
	Place in ServerScriptService
]]

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local BICYCLE_SPAWN_POSITION = Vector3.new(8, 0, 8)
local PINK_COLOR = Color3.fromRGB(255, 105, 180)
local PINK_DARK = Color3.fromRGB(220, 80, 150)
local STEER_MAX_ANGLE = 35

local function getGroundPosition()
	local origin = BICYCLE_SPAWN_POSITION + Vector3.new(0, 50, 0)
	local rayParams = RaycastParams.new()
	local result = Workspace:Raycast(origin, Vector3.new(0, -100, 0), rayParams)
	if result then
		-- Wheel bottom ~1.1 studs below pivot; place pivot so wheels sit on ground
		return result.Position + Vector3.new(0, 1.2, 0)
	end
	return BICYCLE_SPAWN_POSITION + Vector3.new(0, 3, 0)
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
	
	-- Realistic saddle seat (elongated, slightly curved top)
	local seat = Instance.new("VehicleSeat")
	seat.Name = "Seat"
	seat.Size = Vector3.new(0.45, 0.12, 0.65)
	seat.Color = Color3.fromRGB(80, 50, 40)
	seat.Material = Enum.Material.SmoothPlastic
	seat.MaxSpeed = 25
	seat.Torque = 80
	seat.TurnSpeed = 2
	seat.Parent = model
	
	-- Frame: bottom bracket (center of bike)
	local bottomBracket = Instance.new("Part")
	bottomBracket.Name = "BottomBracket"
	bottomBracket.Shape = Enum.PartType.Cylinder
	bottomBracket.Size = Vector3.new(0.2, 0.25, 0.25)
	bottomBracket.Color = PINK_DARK
	bottomBracket.Material = Enum.Material.SmoothPlastic
	bottomBracket.Orientation = Vector3.new(0, 0, 90)
	bottomBracket.Parent = model
	
	-- Top tube (horizontal bar seat to head) - cylinder axis along Z
	local topTube = Instance.new("Part")
	topTube.Name = "TopTube"
	topTube.Shape = Enum.PartType.Cylinder
	topTube.Size = Vector3.new(0.08, 0.9, 0.08)
	topTube.Color = PINK_DARK
	topTube.Material = Enum.Material.SmoothPlastic
	topTube.Orientation = Vector3.new(90, 0, 0)
	topTube.Parent = model
	
	-- Down tube (angled head to bottom bracket)
	local downTube = Instance.new("Part")
	downTube.Name = "DownTube"
	downTube.Shape = Enum.PartType.Cylinder
	downTube.Size = Vector3.new(0.08, 0.85, 0.08)
	downTube.Color = PINK_DARK
	downTube.Material = Enum.Material.SmoothPlastic
	downTube.Orientation = Vector3.new(90, 0, 0)
	downTube.Parent = model
	
	-- Seat tube (vertical, seat to bottom bracket)
	local seatTube = Instance.new("Part")
	seatTube.Name = "SeatTube"
	seatTube.Shape = Enum.PartType.Cylinder
	seatTube.Size = Vector3.new(0.08, 0.5, 0.08)
	seatTube.Color = PINK_DARK
	seatTube.Material = Enum.Material.SmoothPlastic
	seatTube.Orientation = Vector3.new(90, 0, 0)
	seatTube.Parent = model
	
	-- Seat stays (rear triangle to back wheel)
	local seatStayL = Instance.new("Part")
	seatStayL.Name = "SeatStayL"
	seatStayL.Shape = Enum.PartType.Cylinder
	seatStayL.Size = Vector3.new(0.06, 0.55, 0.06)
	seatStayL.Color = PINK_DARK
	seatStayL.Material = Enum.Material.SmoothPlastic
	seatStayL.Orientation = Vector3.new(90, 0, 0)
	seatStayL.Parent = model
	
	local seatStayR = seatStayL:Clone()
	seatStayR.Name = "SeatStayR"
	seatStayR.Parent = model
	
	-- Chain stays (bottom bracket to back wheel)
	local chainStayL = Instance.new("Part")
	chainStayL.Name = "ChainStayL"
	chainStayL.Shape = Enum.PartType.Cylinder
	chainStayL.Size = Vector3.new(0.06, 0.5, 0.06)
	chainStayL.Color = PINK_DARK
	chainStayL.Material = Enum.Material.SmoothPlastic
	chainStayL.Orientation = Vector3.new(90, 0, 0)
	chainStayL.Parent = model
	
	local chainStayR = chainStayL:Clone()
	chainStayR.Name = "ChainStayR"
	chainStayR.Parent = model
	
	-- Head tube (front, vertical - fork pivots here)
	local headTube = Instance.new("Part")
	headTube.Name = "HeadTube"
	headTube.Shape = Enum.PartType.Cylinder
	headTube.Size = Vector3.new(0.12, 0.22, 0.12)
	headTube.Color = PINK_DARK
	headTube.Material = Enum.Material.SmoothPlastic
	headTube.Orientation = Vector3.new(90, 0, 0)
	headTube.Parent = model
	
	-- Back wheel
	local wheelBack = Instance.new("Part")
	wheelBack.Name = "WheelBack"
	wheelBack.Shape = Enum.PartType.Cylinder
	wheelBack.Size = Vector3.new(0.1, 1.2, 1.2)
	wheelBack.Color = Color3.fromRGB(40, 40, 40)
	wheelBack.Material = Enum.Material.SmoothPlastic
	wheelBack.Orientation = Vector3.new(90, 0, 0)
	wheelBack.Parent = model
	
	-- Basket (on rear rack)
	local basket = Instance.new("Part")
	basket.Name = "Basket"
	basket.Shape = Enum.PartType.Block
	basket.Size = Vector3.new(0.55, 0.35, 0.45)
	basket.Color = Color3.fromRGB(255, 182, 193)
	basket.Material = Enum.Material.SmoothPlastic
	basket.Parent = model
	
	local basketRim = Instance.new("Part")
	basketRim.Name = "BasketRim"
	basketRim.Shape = Enum.PartType.Block
	basketRim.Size = Vector3.new(0.6, 0.06, 0.5)
	basketRim.Color = Color3.fromRGB(200, 150, 160)
	basketRim.Material = Enum.Material.SmoothPlastic
	basketRim.Parent = model
	
	-- FRONT ASSEMBLY (steers) - fork, handlebar, front wheel
	local forkCrown = Instance.new("Part")
	forkCrown.Name = "ForkCrown"
	forkCrown.Shape = Enum.PartType.Block
	forkCrown.Size = Vector3.new(0.15, 0.2, 0.15)
	forkCrown.Color = PINK_DARK
	forkCrown.Material = Enum.Material.SmoothPlastic
	forkCrown.Parent = model
	
	-- Fork legs (vertical, down to wheel)
	local forkLegL = Instance.new("Part")
	forkLegL.Name = "ForkLegL"
	forkLegL.Shape = Enum.PartType.Cylinder
	forkLegL.Size = Vector3.new(0.06, 0.5, 0.06)
	forkLegL.Color = PINK_DARK
	forkLegL.Material = Enum.Material.SmoothPlastic
	forkLegL.Parent = model
	
	local forkLegR = forkLegL:Clone()
	forkLegR.Name = "ForkLegR"
	forkLegR.Parent = model
	
	-- Handlebar stem (vertical up) + bar (horizontal)
	local handlebarStem = Instance.new("Part")
	handlebarStem.Name = "HandlebarStem"
	handlebarStem.Shape = Enum.PartType.Cylinder
	handlebarStem.Size = Vector3.new(0.06, 0.3, 0.06)
	handlebarStem.Color = PINK_DARK
	handlebarStem.Material = Enum.Material.SmoothPlastic
	handlebarStem.Parent = model
	
	local handlebar = Instance.new("Part")
	handlebar.Name = "Handlebar"
	handlebar.Shape = Enum.PartType.Cylinder
	handlebar.Size = Vector3.new(0.05, 0.55, 0.05)
	handlebar.Color = PINK_DARK
	handlebar.Material = Enum.Material.SmoothPlastic
	handlebar.Orientation = Vector3.new(0, 0, 90)
	handlebar.Parent = model
	
	local wheelFront = Instance.new("Part")
	wheelFront.Name = "WheelFront"
	wheelFront.Shape = Enum.PartType.Cylinder
	wheelFront.Size = Vector3.new(0.1, 1.2, 1.2)
	wheelFront.Color = Color3.fromRGB(40, 40, 40)
	wheelFront.Material = Enum.Material.SmoothPlastic
	wheelFront.Orientation = Vector3.new(90, 0, 0)
	wheelFront.Parent = model
	
	-- Position REAR assembly (origin at bottom bracket)
	bottomBracket.CFrame = CFrame.new(0, 0, 0)
	seat.CFrame = CFrame.new(0, 0.38, 0.22)
	topTube.CFrame = CFrame.new(0, 0.28, -0.15) * CFrame.Angles(math.rad(90), 0, 0)
	downTube.CFrame = CFrame.new(0, 0.14, -0.28) * CFrame.Angles(math.rad(55), 0, 0)
	seatTube.CFrame = CFrame.new(0, 0.19, 0.11) * CFrame.Angles(math.rad(75), 0, 0)
	headTube.CFrame = CFrame.new(0, 0.28, -0.5) * CFrame.Angles(math.rad(90), 0, 0)
	
	seatStayL.CFrame = CFrame.new(-0.06, 0.2, 0.35) * CFrame.Angles(math.rad(-30), 0, 0)
	seatStayR.CFrame = CFrame.new(0.06, 0.2, 0.35) * CFrame.Angles(math.rad(-30), 0, 0)
	chainStayL.CFrame = CFrame.new(-0.06, -0.05, 0.32) * CFrame.Angles(math.rad(-20), 0, 0)
	chainStayR.CFrame = CFrame.new(0.06, -0.05, 0.32) * CFrame.Angles(math.rad(-20), 0, 0)
	
	wheelBack.CFrame = CFrame.new(0, -0.45, 0.52) * CFrame.Angles(math.rad(90), 0, 0)
	basket.CFrame = CFrame.new(0.22, 0.25, 0.48)
	basketRim.CFrame = basket.CFrame * CFrame.new(0, 0.2, 0)
	
	-- Position FRONT assembly (fork pivots at head tube)
	forkCrown.CFrame = CFrame.new(0, 0.28, -0.62)
	forkLegL.CFrame = forkCrown.CFrame * CFrame.new(-0.05, -0.22, -0.08)
	forkLegR.CFrame = forkCrown.CFrame * CFrame.new(0.05, -0.22, -0.08)
	handlebarStem.CFrame = forkCrown.CFrame * CFrame.new(0, 0.18, 0)
	handlebar.CFrame = handlebarStem.CFrame * CFrame.new(0, 0.18, 0) * CFrame.Angles(0, 0, math.rad(90))
	wheelFront.CFrame = forkCrown.CFrame * CFrame.new(0, -0.5, -0.2) * CFrame.Angles(math.rad(90), 0, 0)
	
	-- Weld rear assembly (seat is primary for VehicleSeat)
	weld(seat, bottomBracket)
	weld(seat, topTube)
	weld(seat, downTube)
	weld(seat, seatTube)
	weld(seat, seatStayL)
	weld(seat, seatStayR)
	weld(seat, chainStayL)
	weld(seat, chainStayR)
	weld(topTube, headTube)
	weld(downTube, headTube)
	weld(seat, wheelBack)
	weld(seat, basket)
	weld(basket, basketRim)
	
	-- Weld front assembly
	weld(forkCrown, forkLegL)
	weld(forkCrown, forkLegR)
	weld(forkCrown, handlebarStem)
	weld(handlebarStem, handlebar)
	weld(forkCrown, wheelFront)
	
	-- Hinge for steering (front assembly rotates around head tube)
	-- HingeConstraint uses Attachment0/Attachment1; attachment X-axis = hinge rotation axis
	local att0 = Instance.new("Attachment")
	att0.Name = "SteerAtt0"
	att0.Orientation = Vector3.new(0, 0, 90)  -- X-axis up for vertical steering
	att0.Parent = headTube
	
	local att1 = Instance.new("Attachment")
	att1.Name = "SteerAtt1"
	att1.Orientation = Vector3.new(0, 0, 90)
	att1.Parent = forkCrown
	
	local hinge = Instance.new("HingeConstraint")
	hinge.Name = "SteerHinge"
	hinge.Attachment0 = att0
	hinge.Attachment1 = att1
	hinge.ActuatorType = Enum.ActuatorType.Servo
	hinge.ServoMaxTorque = 2000
	hinge.LimitsEnabled = true
	hinge.LowerAngle = math.rad(-35)
	hinge.UpperAngle = math.rad(35)
	hinge.Parent = headTube
	
	-- Rabbit in basket
	local rabbit = createRabbit()
	rabbit.Parent = model
	rabbit.PrimaryPart.CFrame = basket.CFrame * CFrame.new(0, 0.1, 0) * CFrame.Angles(0, math.rad(-15), 0)
	weld(basket, rabbit.PrimaryPart)
	
	model.PrimaryPart = seat
	model:SetAttribute("IsBicycle", true)
	
	-- Script: sync steering to VehicleSeat SteerFloat
	local steerConnection
	steerConnection = RunService.Heartbeat:Connect(function()
		if not model.Parent then steerConnection:Disconnect() return end
		local steer = seat.SteerFloat
		local targetAngle = math.rad(-steer * STEER_MAX_ANGLE)
		hinge.TargetAngle = targetAngle
	end)
	
	return model
end

-- Spawn bicycle
local function spawnBicycle()
	local bike = createBicycle()
	local groundPos = getGroundPosition()
	
	-- Ensure upright: wheels down (Y-), seat up (Y+). Bike built with +Y up.
	local spawnCF = CFrame.new(groundPos)
	bike:PivotTo(spawnCF)
	
	local bikesFolder = Workspace:FindFirstChild("Bicycles")
	if not bikesFolder then
		bikesFolder = Instance.new("Folder")
		bikesFolder.Name = "Bicycles"
		bikesFolder.Parent = Workspace
	end
	bike.Parent = bikesFolder
	
	-- Zero velocity so bike doesn't tumble on spawn
	task.defer(function()
		task.wait(0.05)
		if bike.Parent and bike.PrimaryPart then
			local assem = bike.PrimaryPart:GetRootPart()
			if assem then
				assem.AssemblyLinearVelocity = Vector3.zero
				assem.AssemblyAngularVelocity = Vector3.zero
			end
		end
	end)
	
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
