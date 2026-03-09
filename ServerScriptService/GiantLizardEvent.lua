--[[
	GiantLizardEvent - A massive lizard (5x player size) that charges across the map
	Runs for ~15 seconds then vanishes. Reappears randomly every 1-3 minutes.
	Place in ServerScriptService
]]

local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local SCALE = 5
local RUN_DURATION = 15
local RESPAWN_MIN = 60
local RESPAWN_MAX = 180
local MAP_RADIUS = 120
local GROUND_OFFSET = 1.5 * SCALE

local GIANT_COLOR = Color3.fromRGB(80, 45, 20)
local GIANT_DARK = Color3.fromRGB(55, 30, 12)
local BELLY_COLOR = Color3.fromRGB(170, 140, 90)
local EYE_COLOR = Color3.fromRGB(220, 180, 30)

local giantFolder = Instance.new("Folder")
giantFolder.Name = "GiantLizard"
giantFolder.Parent = Workspace

local function snapToGroundY(x, z)
	local origin = Vector3.new(x, 300, z)
	local rayParams = RaycastParams.new()
	rayParams.FilterDescendantsInstances = {giantFolder}
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	local result = Workspace:Raycast(origin, Vector3.new(0, -600, 0), rayParams)
	if result then
		return result.Position.Y + GROUND_OFFSET
	end
	return GROUND_OFFSET
end

local function buildGiantLizard()
	local model = Instance.new("Model")
	model.Name = "GiantLizard"
	local s = SCALE

	local body = Instance.new("Part")
	body.Name = "Body"
	body.Shape = Enum.PartType.Block
	body.Size = Vector3.new(2.2 * s, 1.2 * s, 5.5 * s)
	body.Color = GIANT_COLOR
	body.Material = Enum.Material.SmoothPlastic
	body.Anchored = true
	body.CanCollide = false
	body.Parent = model

	local belly = Instance.new("Part")
	belly.Name = "Belly"
	belly.Shape = Enum.PartType.Block
	belly.Size = Vector3.new(1.8 * s, 0.3 * s, 5.0 * s)
	belly.Color = BELLY_COLOR
	belly.Material = Enum.Material.SmoothPlastic
	belly.Anchored = true
	belly.CanCollide = false
	belly.Parent = model

	local stripe = Instance.new("Part")
	stripe.Name = "Stripe"
	stripe.Shape = Enum.PartType.Block
	stripe.Size = Vector3.new(0.8 * s, 0.2 * s, 5.2 * s)
	stripe.Color = GIANT_DARK
	stripe.Material = Enum.Material.SmoothPlastic
	stripe.Anchored = true
	stripe.CanCollide = false
	stripe.Parent = model

	local head = Instance.new("WedgePart")
	head.Name = "Head"
	head.Size = Vector3.new(1.8 * s, 1.6 * s, 2.2 * s)
	head.Color = GIANT_COLOR
	head.Material = Enum.Material.SmoothPlastic
	head.Anchored = true
	head.CanCollide = false
	head.Orientation = Vector3.new(0, 90, 0)
	head.Parent = model

	local jaw = Instance.new("WedgePart")
	jaw.Name = "Jaw"
	jaw.Size = Vector3.new(1.6 * s, 0.6 * s, 1.8 * s)
	jaw.Color = BELLY_COLOR
	jaw.Material = Enum.Material.SmoothPlastic
	jaw.Anchored = true
	jaw.CanCollide = false
	jaw.Orientation = Vector3.new(0, 90, 0)
	jaw.Parent = model

	local eyeL = Instance.new("Part")
	eyeL.Name = "EyeL"
	eyeL.Shape = Enum.PartType.Ball
	eyeL.Size = Vector3.new(0.5 * s, 0.5 * s, 0.5 * s)
	eyeL.Color = EYE_COLOR
	eyeL.Material = Enum.Material.Neon
	eyeL.Anchored = true
	eyeL.CanCollide = false
	eyeL.Parent = model

	local eyeR = eyeL:Clone()
	eyeR.Name = "EyeR"
	eyeR.Parent = model

	local pupilL = Instance.new("Part")
	pupilL.Name = "PupilL"
	pupilL.Shape = Enum.PartType.Ball
	pupilL.Size = Vector3.new(0.25 * s, 0.3 * s, 0.25 * s)
	pupilL.Color = Color3.fromRGB(10, 10, 10)
	pupilL.Material = Enum.Material.SmoothPlastic
	pupilL.Anchored = true
	pupilL.CanCollide = false
	pupilL.Parent = model

	local pupilR = pupilL:Clone()
	pupilR.Name = "PupilR"
	pupilR.Parent = model

	local tail1 = Instance.new("Part")
	tail1.Name = "Tail1"
	tail1.Shape = Enum.PartType.Block
	tail1.Size = Vector3.new(1.6 * s, 1.0 * s, 3.5 * s)
	tail1.Color = GIANT_COLOR
	tail1.Material = Enum.Material.SmoothPlastic
	tail1.Anchored = true
	tail1.CanCollide = false
	tail1.Parent = model

	local tail2 = Instance.new("Part")
	tail2.Name = "Tail2"
	tail2.Shape = Enum.PartType.Block
	tail2.Size = Vector3.new(1.0 * s, 0.7 * s, 3.0 * s)
	tail2.Color = GIANT_DARK
	tail2.Material = Enum.Material.SmoothPlastic
	tail2.Anchored = true
	tail2.CanCollide = false
	tail2.Parent = model

	local tail3 = Instance.new("Part")
	tail3.Name = "Tail3"
	tail3.Shape = Enum.PartType.Block
	tail3.Size = Vector3.new(0.5 * s, 0.4 * s, 2.5 * s)
	tail3.Color = GIANT_COLOR
	tail3.Material = Enum.Material.SmoothPlastic
	tail3.Anchored = true
	tail3.CanCollide = false
	tail3.Parent = model

	for i = 1, 4 do
		local leg = Instance.new("Part")
		leg.Name = "Leg" .. i
		leg.Shape = Enum.PartType.Block
		leg.Size = Vector3.new(0.7 * s, 1.8 * s, 0.7 * s)
		leg.Color = GIANT_COLOR
		leg.Material = Enum.Material.SmoothPlastic
		leg.Anchored = true
		leg.CanCollide = false
		leg.Parent = model

		local foot = Instance.new("Part")
		foot.Name = "Foot" .. i
		foot.Shape = Enum.PartType.Block
		foot.Size = Vector3.new(0.9 * s, 0.3 * s, 1.0 * s)
		foot.Color = GIANT_DARK
		foot.Material = Enum.Material.SmoothPlastic
		foot.Anchored = true
		foot.CanCollide = false
		foot.Parent = model
	end

	for i = 1, 5 do
		local spike = Instance.new("WedgePart")
		spike.Name = "Spike" .. i
		spike.Size = Vector3.new(0.4 * s, 0.6 * s, 0.5 * s)
		spike.Color = GIANT_DARK
		spike.Material = Enum.Material.SmoothPlastic
		spike.Anchored = true
		spike.CanCollide = false
		spike.Parent = model
	end

	model.PrimaryPart = body
	return model
end

local function positionParts(model, bodyCF, t, isRunning)
	local s = SCALE
	local body = model.PrimaryPart
	body.CFrame = bodyCF

	local sway = math.sin(t * 8) * 0.12

	local belly = model:FindFirstChild("Belly")
	if belly then
		belly.CFrame = bodyCF * CFrame.new(0, -0.55 * s, 0)
	end

	local stripe = model:FindFirstChild("Stripe")
	if stripe then
		stripe.CFrame = bodyCF * CFrame.new(0, 0.65 * s, 0)
	end

	local head = model:FindFirstChild("Head")
	if head then
		local bob = math.sin(t * 6) * 0.15 * s
		head.CFrame = bodyCF * CFrame.new(0, 0.1 * s + bob * 0.3, -3.2 * s) * CFrame.Angles(0, 0, sway * 0.3)
	end

	local jaw = model:FindFirstChild("Jaw")
	if jaw then
		local mouthOpen = math.max(0, math.sin(t * 4)) * 0.08 * s
		jaw.CFrame = bodyCF * CFrame.new(0, -0.4 * s - mouthOpen, -3.0 * s)
	end

	local headCF = head and head.CFrame or bodyCF
	local eyeL = model:FindFirstChild("EyeL")
	if eyeL then
		eyeL.CFrame = headCF * CFrame.new(0.55 * s, 0.45 * s, 0.3 * s)
	end
	local eyeR = model:FindFirstChild("EyeR")
	if eyeR then
		eyeR.CFrame = headCF * CFrame.new(0.55 * s, 0.45 * s, -0.3 * s)
	end
	local pupilL = model:FindFirstChild("PupilL")
	if pupilL and eyeL then
		pupilL.CFrame = eyeL.CFrame * CFrame.new(0.12 * s, 0, 0)
	end
	local pupilR = model:FindFirstChild("PupilR")
	if pupilR and eyeR then
		pupilR.CFrame = eyeR.CFrame * CFrame.new(0.12 * s, 0, 0)
	end

	local tail1 = model:FindFirstChild("Tail1")
	if tail1 then
		tail1.CFrame = bodyCF * CFrame.new(0, -0.1 * s, 3.8 * s) * CFrame.Angles(0, sway * 1.5, 0)
	end
	local tail2 = model:FindFirstChild("Tail2")
	local t1CF = tail1 and tail1.CFrame or bodyCF
	if tail2 then
		tail2.CFrame = t1CF * CFrame.new(0, -0.1 * s, 2.8 * s) * CFrame.Angles(0, sway * 2.0, 0)
	end
	local tail3 = model:FindFirstChild("Tail3")
	local t2CF = tail2 and tail2.CFrame or t1CF
	if tail3 then
		tail3.CFrame = t2CF * CFrame.new(0, -0.05 * s, 2.3 * s) * CFrame.Angles(0, sway * 2.5, 0)
	end

	local legData = {
		{side = 1, fwd = -1, idx = 1, phase = 0},
		{side = 1, fwd = 1, idx = 2, phase = math.pi},
		{side = -1, fwd = -1, idx = 3, phase = math.pi},
		{side = -1, fwd = 1, idx = 4, phase = 0},
	}
	for _, ld in ipairs(legData) do
		local leg = model:FindFirstChild("Leg" .. ld.idx)
		local foot = model:FindFirstChild("Foot" .. ld.idx)
		if leg then
			local stride = math.sin(t * 10 + ld.phase) * 0.6 * s
			local lift = math.max(0, math.sin(t * 10 + ld.phase)) * 0.4 * s
			local ox = ld.side * 1.3 * s
			local oz = ld.fwd * 1.8 * s + stride
			leg.CFrame = bodyCF * CFrame.new(ox, -1.1 * s + lift, oz)
				* CFrame.Angles(math.sin(t * 10 + ld.phase) * 0.4, 0, ld.side * -0.15)
			if foot then
				foot.CFrame = leg.CFrame * CFrame.new(0, -1.0 * s, 0.15 * s)
			end
		end
	end

	for i = 1, 5 do
		local spike = model:FindFirstChild("Spike" .. i)
		if spike then
			local zOff = (-2.0 + (i - 1) * 1.0) * s
			spike.CFrame = bodyCF * CFrame.new(0, 0.9 * s, zOff) * CFrame.Angles(0, 0, 0)
		end
	end
end

local function runGiantLizard()
	local model = buildGiantLizard()
	model.Parent = giantFolder

	local angle = math.random() * math.pi * 2
	local startX = math.cos(angle) * MAP_RADIUS
	local startZ = math.sin(angle) * MAP_RADIUS
	local endX = -startX
	local endZ = -startZ

	local startY = snapToGroundY(startX, startZ)

	local dir = Vector3.new(endX - startX, 0, endZ - startZ).Unit
	local totalDist = Vector3.new(endX - startX, 0, endZ - startZ).Magnitude
	local speed = totalDist / RUN_DURATION

	local elapsed = 0
	local t = math.random() * 100
	local connection

	local shakeConnection
	shakeConnection = RunService.Heartbeat:Connect(function(dt)
		if not model.Parent then
			shakeConnection:Disconnect()
			return
		end
		for _, player in ipairs(game.Players:GetPlayers()) do
			if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
				local dist = (player.Character.HumanoidRootPart.Position - model.PrimaryPart.Position).Magnitude
				if dist < 50 then
					local hum = player.Character:FindFirstChildOfClass("Humanoid")
					if hum then
						hum.CameraOffset = Vector3.new(
							(math.random() - 0.5) * 0.3 * math.clamp(1 - dist / 50, 0, 1),
							(math.random() - 0.5) * 0.3 * math.clamp(1 - dist / 50, 0, 1),
							0
						)
					end
				else
					local hum = player.Character:FindFirstChildOfClass("Humanoid")
					if hum then
						hum.CameraOffset = Vector3.zero
					end
				end
			end
		end
	end)

	connection = RunService.Heartbeat:Connect(function(dt)
		if not model.Parent then
			connection:Disconnect()
			return
		end

		elapsed = elapsed + dt
		t = t + dt

		if elapsed >= RUN_DURATION then
			for _, player in ipairs(game.Players:GetPlayers()) do
				if player.Character then
					local hum = player.Character:FindFirstChildOfClass("Humanoid")
					if hum then hum.CameraOffset = Vector3.zero end
				end
			end
			shakeConnection:Disconnect()
			connection:Disconnect()
			model:Destroy()
			return
		end

		local dist = speed * elapsed
		local x = startX + dir.X * dist
		local z = startZ + dir.Z * dist
		local y = snapToGroundY(x, z)

		local facingCF = CFrame.new(Vector3.new(x, y, z), Vector3.new(x + dir.X, y, z + dir.Z))
		positionParts(model, facingCF, t, true)
	end)
end

task.spawn(function()
	task.wait(5)
	while true do
		runGiantLizard()
		local waitTime = RESPAWN_MIN + math.random() * (RESPAWN_MAX - RESPAWN_MIN)
		task.wait(waitTime)
	end
end)

print("[GiantLizardEvent] The giant lizard stalks the land! Watch out!")
