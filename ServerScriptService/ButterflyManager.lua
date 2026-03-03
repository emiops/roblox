--[[
	ButterflyManager - Spawns butterflies that fly around the play area
	Butterflies stay within bounds, don't cross walls, max height 2x player height
	Max 20 butterflies, different types and sizes
	Place in ServerScriptService
]]

local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local MAX_BUTTERFLIES = 20
local SPAWN_RADIUS = 80
local SPAWN_INTERVAL = 6
local FLIGHT_SPEED = 4
local FLAP_SPEED = 12
local WALL_CHECK_DISTANCE = 3
local WALL_CHECK_HEIGHT = 0.5

-- Butterfly types: name, body color, wing color, scale range
local BUTTERFLY_TYPES = {
	{ name = "Monarch", body = Color3.fromRGB(30, 30, 30), wing = Color3.fromRGB(255, 140, 0) },
	{ name = "Blue", body = Color3.fromRGB(30, 30, 40), wing = Color3.fromRGB(65, 105, 225) },
	{ name = "White", body = Color3.fromRGB(50, 50, 50), wing = Color3.fromRGB(255, 255, 255) },
	{ name = "Yellow", body = Color3.fromRGB(40, 35, 35), wing = Color3.fromRGB(255, 215, 0) },
	{ name = "Orange", body = Color3.fromRGB(35, 35, 35), wing = Color3.fromRGB(255, 165, 0) },
	{ name = "Purple", body = Color3.fromRGB(45, 40, 50), wing = Color3.fromRGB(148, 0, 211) },
}

local butterfliesFolder = Workspace:FindFirstChild("Butterflies") or Instance.new("Folder")
butterfliesFolder.Name = "Butterflies"
butterfliesFolder.Parent = Workspace

local function deflectFromWall(pos, moveDir)
	if not moveDir or moveDir.Magnitude < 0.1 then return moveDir end
	local flatDir = Vector3.new(moveDir.X, 0, moveDir.Z).Unit
	local origin = pos + Vector3.new(0, WALL_CHECK_HEIGHT, 0)
	local direction = flatDir * WALL_CHECK_DISTANCE
	local rayParams = RaycastParams.new()
	local exclude = {butterfliesFolder}
	local rocks = Workspace:FindFirstChild("Rocks")
	local terrariums = Workspace:FindFirstChild("Terrariums")
	if rocks then table.insert(exclude, rocks) end
	if terrariums then table.insert(exclude, terrariums) end
	rayParams.FilterDescendantsInstances = exclude
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	local result = Workspace:Raycast(origin, direction, rayParams)
	if result then
		local n = result.Normal
		local nFlat = Vector3.new(n.X, 0, n.Z)
		if nFlat.Magnitude > 0.01 then
			nFlat = nFlat.Unit
			local reflected = flatDir - 2 * flatDir:Dot(nFlat) * nFlat
			if reflected.Magnitude > 0.1 then
				return reflected.Unit
			end
		end
		return Vector3.new(-flatDir.Z, 0, flatDir.X).Unit
	end
	return moveDir
end

local function getGroundPosition()
	local x = math.random(-SPAWN_RADIUS, SPAWN_RADIUS)
	local z = math.random(-SPAWN_RADIUS, SPAWN_RADIUS)
	local origin = Vector3.new(x, 300, z)
	local rayParams = RaycastParams.new()
	local exclude = {butterfliesFolder}
	local rocks = Workspace:FindFirstChild("Rocks")
	local rollies = Workspace:FindFirstChild("RolliePollies")
	if rocks then table.insert(exclude, rocks) end
	if rollies then table.insert(exclude, rollies) end
	rayParams.FilterDescendantsInstances = exclude
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	local result = Workspace:Raycast(origin, Vector3.new(0, -600, 0), rayParams)
	if result then
		return result.Position
	end
	return Vector3.new(x, 5, z)
end

local function getMaxHeight()
	local maxY = 0
	for _, p in pairs(Players:GetPlayers()) do
		local char = p.Character
		if char and char:FindFirstChild("HumanoidRootPart") then
			local py = char.HumanoidRootPart.Position.Y
			if py > maxY then maxY = py end
		end
	end
	if maxY > 0 then
		return maxY * 2
	end
	return 50
end

local function createButterfly()
	local typeData = BUTTERFLY_TYPES[math.random(1, #BUTTERFLY_TYPES)]
	local scale = 0.3 + math.random() * 0.5
	local groundPos = getGroundPosition()
	local spawnY = groundPos.Y + 1 + math.random() * 4
	local pos = Vector3.new(groundPos.X, spawnY, groundPos.Z)

	local model = Instance.new("Model")
	model.Name = typeData.name .. "Butterfly"

	-- Body
	local body = Instance.new("Part")
	body.Name = "Body"
	body.Shape = Enum.PartType.Block
	body.Size = Vector3.new(0.08 * scale, 0.25 * scale, 0.08 * scale)
	body.Color = typeData.body
	body.Material = Enum.Material.SmoothPlastic
	body.Anchored = true
	body.CanCollide = false
	body.Parent = model

	-- Left wing (thin, extends sideways)
	local wingL = Instance.new("Part")
	wingL.Name = "WingL"
	wingL.Shape = Enum.PartType.Block
	wingL.Size = Vector3.new(0.02 * scale, 0.18 * scale, 0.4 * scale)
	wingL.Color = typeData.wing
	wingL.Material = Enum.Material.SmoothPlastic
	wingL.Anchored = true
	wingL.CanCollide = false
	wingL.Parent = model

	-- Right wing
	local wingR = Instance.new("Part")
	wingR.Name = "WingR"
	wingR.Shape = Enum.PartType.Block
	wingR.Size = Vector3.new(0.02 * scale, 0.18 * scale, 0.4 * scale)
	wingR.Color = typeData.wing
	wingR.Material = Enum.Material.SmoothPlastic
	wingR.Anchored = true
	wingR.CanCollide = false
	wingR.Parent = model

	model.Parent = butterfliesFolder

	-- Flight state
	local moveDir = Vector3.new(math.random() - 0.5, (math.random() - 0.5) * 0.3, math.random() - 0.5).Unit
	local phase = math.random() * 100
	local dirChangeTime = tick() + 2 + math.random() * 4

	RunService.Heartbeat:Connect(function(dt)
		if not model.Parent then return end

		local t = tick()
		local flapAngle = math.sin(t * FLAP_SPEED + phase) * 0.6

		-- Change direction occasionally
		if t > dirChangeTime then
			dirChangeTime = t + 2 + math.random() * 5
			moveDir = Vector3.new(math.random() - 0.5, (math.random() - 0.5) * 0.2, math.random() - 0.5).Unit
		end

		-- Deflect from walls
		moveDir = deflectFromWall(pos, moveDir)
		moveDir = Vector3.new(moveDir.X, moveDir.Y, moveDir.Z).Unit

		-- Move
		pos = pos + moveDir * FLIGHT_SPEED * dt

		-- Clamp X, Z to spawn radius
		pos = Vector3.new(
			math.clamp(pos.X, -SPAWN_RADIUS, SPAWN_RADIUS),
			pos.Y,
			math.clamp(pos.Z, -SPAWN_RADIUS, SPAWN_RADIUS)
		)

		-- Clamp Y: min 2 studs above base, max 2x player height
		local minY = math.max(2, groundPos.Y)
		local maxY = getMaxHeight()
		pos = Vector3.new(pos.X, math.clamp(pos.Y, minY, maxY), pos.Z)

		-- Slight vertical drift
		moveDir = moveDir + Vector3.new(0, (math.sin(t * 0.5 + phase) * 0.02), 0)
		if moveDir.Magnitude > 0.1 then
			moveDir = moveDir.Unit
		end

		-- Update body CFrame
		local lookDir = Vector3.new(moveDir.X, 0, moveDir.Z)
		if lookDir.Magnitude < 0.1 then
			lookDir = Vector3.new(1, 0, 0)
		else
			lookDir = lookDir.Unit
		end
		local bodyCF = CFrame.lookAt(pos, pos + lookDir)

		body.CFrame = bodyCF
		wingL.CFrame = bodyCF * CFrame.new(-0.15 * scale, 0, 0) * CFrame.Angles(flapAngle, 0, 0)
		wingR.CFrame = bodyCF * CFrame.new(0.15 * scale, 0, 0) * CFrame.Angles(-flapAngle, 0, 0)
	end)

	return model
end

-- Spawn loop
task.spawn(function()
	while true do
		local count = #butterfliesFolder:GetChildren()
		if count < MAX_BUTTERFLIES then
			createButterfly()
		end
		task.wait(SPAWN_INTERVAL)
	end
end)

-- Initial butterflies
for i = 1, 5 do
	task.wait(0.2)
	createButterfly()
end

print("[ButterflyManager] Butterflies flying! Max ~" .. MAX_BUTTERFLIES .. ", stay within bounds, max height 2x player.")
