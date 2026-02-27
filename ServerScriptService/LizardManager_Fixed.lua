--[[
	LizardManager - FIXED VERSION
	Uses a simpler approach: lizards are Parts with a Script inside for escape behavior
	Place in ServerScriptService
]]

local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")

local LIZARD_COLORS = {
	Color3.fromRGB(34, 139, 34),   -- Green
	Color3.fromRGB(139, 90, 43),   -- Brown
	Color3.fromRGB(128, 128, 128), -- Gray
	Color3.fromRGB(210, 180, 140), -- Tan
	Color3.fromRGB(85, 107, 47),   -- Olive
	Color3.fromRGB(60, 179, 113),  -- Emerald
}

local LIZARD_NAMES = {"Green", "Brown", "Gray", "Tan", "Olive", "Emerald"}
local ESCAPE_DISTANCE = 14
local ESCAPE_SPEED = 16
local WANDER_SPEED = 5
local SPAWN_INTERVAL = 6
local IDLE_MIN = 2
local IDLE_MAX = 6
local WANDER_MIN = 1
local WANDER_MAX = 4
local JUMP_CHANCE = 0.008  -- Per frame when moving
local JUMP_POWER = 12  -- 3x higher jumps
local JUMP_GRAVITY = 18
local MAX_LIZARDS = 20
local SPAWN_RADIUS = 80
local WALL_CHECK_DISTANCE = 4  -- Raycast ahead to detect walls
local WALL_CHECK_HEIGHT = 0.5  -- Slight offset so ray starts at lizard height

local lizardsFolder = Workspace:FindFirstChild("Lizards") or Instance.new("Folder")
lizardsFolder.Name = "Lizards"
lizardsFolder.Parent = Workspace

local function deflectFromWall(bodyPos, moveDir)
	-- Raycast ahead; if wall/obstacle within range, deflect moveDir away from it
	if not moveDir or moveDir.Magnitude < 0.1 then return moveDir end
	local flatDir = Vector3.new(moveDir.X, 0, moveDir.Z).Unit
	local origin = bodyPos + Vector3.new(0, WALL_CHECK_HEIGHT, 0)
	local direction = flatDir * WALL_CHECK_DISTANCE
	local rayParams = RaycastParams.new()
	rayParams.FilterDescendantsInstances = {lizardsFolder}
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	local result = Workspace:Raycast(origin, direction, rayParams)
	if result then
		-- Reflect off wall surface (use horizontal component of normal)
		local n = result.Normal
		local nFlat = Vector3.new(n.X, 0, n.Z)
		if nFlat.Magnitude > 0.01 then
			nFlat = nFlat.Unit
			local reflected = flatDir - 2 * flatDir:Dot(nFlat) * nFlat
			if reflected.Magnitude > 0.1 then
				return reflected.Unit
			end
		end
		-- Fallback: turn 90 degrees away from wall
		return Vector3.new(-flatDir.Z, 0, flatDir.X).Unit
	end
	return moveDir
end

local function snapToGround(body, heightOffset)
	-- Raycast down to find ground, place body on surface (keeps X, Z, rotation)
	heightOffset = heightOffset or 0.5
	local pos = body.Position
	local origin = pos + Vector3.new(0, 10, 0)
	local rayParams = RaycastParams.new()
	rayParams.FilterDescendantsInstances = {lizardsFolder}
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	local result = Workspace:Raycast(origin, Vector3.new(0, -100, 0), rayParams)
	if result then
		local groundY = result.Position.Y + heightOffset
		local cf = body.CFrame
		body.CFrame = CFrame.new(pos.X, groundY, pos.Z) * (cf - cf.Position)
	end
end

local function getGroundPosition(nearPlayer)
	local x, z
	if nearPlayer then
		-- Spawn near player (or 0,0,0 if no player) so they're visible
		local player = game.Players:GetPlayers()[1]
		if player and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
			local pos = player.Character.HumanoidRootPart.Position
			x = pos.X + math.random(-25, 25)
			z = pos.Z + math.random(-25, 25)
		else
			x = math.random(-20, 20)
			z = math.random(-20, 20)
		end
	else
		x = math.random(-SPAWN_RADIUS, SPAWN_RADIUS)
		z = math.random(-SPAWN_RADIUS, SPAWN_RADIUS)
	end
	
	-- Raycast from HIGH above (300) so we hit terrain on hills - generated terrain can be tall
	local origin = Vector3.new(x, 300, z)
	local direction = Vector3.new(0, -600, 0)  -- Cast far down
	
	local rayParams = RaycastParams.new()
	rayParams.FilterDescendantsInstances = {lizardsFolder}
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	
	local result = Workspace:Raycast(origin, direction, rayParams)
	if result then
		-- Place 1.5 studs ABOVE surface so lizard sits on top (not inside terrain)
		return result.Position + Vector3.new(0, 1.5, 0)
	end
	return Vector3.new(x, 5, z)
end

local function createLizard(nearPlayer)
	nearPlayer = nearPlayer or false
	local idx = math.random(1, #LIZARD_COLORS)
	local scale = 0.8 + math.random() * 0.9
	local color = LIZARD_COLORS[idx]
	local darkColor = Color3.new(
		math.max(0, color.R - 0.15),
		math.max(0, color.G - 0.1),
		math.max(0, color.B - 0.05)
	)
	
	local model = Instance.new("Model")
	model.Name = LIZARD_NAMES[idx] .. "Lizard"
	
	-- Body: long, flat, lizard-like (main mass) - length along Z (forward/back)
	local body = Instance.new("Part")
	body.Name = "Body"
	body.Shape = Enum.PartType.Block
	body.Size = Vector3.new(0.45 * scale, 0.25 * scale, 1.1 * scale)  -- Long along Z, flat
	body.Color = color
	body.Anchored = true
	body.CanCollide = true
	body.Parent = model
	
	-- Back stripe (darker band - some lizards have this)
	local stripe = Instance.new("Part")
	stripe.Name = "Stripe"
	stripe.Shape = Enum.PartType.Block
	stripe.Size = Vector3.new(0.2 * scale, 0.08 * scale, 1.05 * scale)
	stripe.Color = darkColor
	stripe.Anchored = true
	stripe.CanCollide = false
	stripe.Parent = model
	
	-- Head: wedge for snout, pointed forward (-Z)
	local head = Instance.new("WedgePart")
	head.Name = "Head"
	head.Size = Vector3.new(0.35 * scale, 0.35 * scale, 0.4 * scale)
	head.Color = color
	head.Anchored = true
	head.CanCollide = false
	head.Orientation = Vector3.new(0, 90, 0)  -- Wedge point faces -Z (forward)
	head.Parent = model
	
	-- Eye dots (small dark spots)
	local eyeL = Instance.new("Part")
	eyeL.Name = "EyeL"
	eyeL.Shape = Enum.PartType.Ball
	eyeL.Size = Vector3.new(0.08 * scale, 0.08 * scale, 0.08 * scale)
	eyeL.Color = Color3.fromRGB(20, 20, 20)
	eyeL.Anchored = true
	eyeL.CanCollide = false
	eyeL.Parent = model
	
	local eyeR = Instance.new("Part")
	eyeR.Name = "EyeR"
	eyeR.Shape = Enum.PartType.Ball
	eyeR.Size = Vector3.new(0.08 * scale, 0.08 * scale, 0.08 * scale)
	eyeR.Color = Color3.fromRGB(20, 20, 20)
	eyeR.Anchored = true
	eyeR.CanCollide = false
	eyeR.Parent = model
	
	-- Tail: long, tapered (2 segments) - length along Z
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
	
	-- Legs: 4 wedge parts, angled like lizard legs
	local legOffsets = {{0.35, 0.15}, {0.35, -0.15}, {-0.35, 0.15}, {-0.35, -0.15}}
	for i, offset in pairs(legOffsets) do
		local leg = Instance.new("WedgePart")
		leg.Name = "Leg" .. i
		leg.Size = Vector3.new(0.12 * scale, 0.2 * scale, 0.15 * scale)
		leg.Color = color
		leg.Anchored = true
		leg.CanCollide = false
		leg.Parent = model
	end
	
	model.PrimaryPart = body
	model.Parent = lizardsFolder
	
	local pos = getGroundPosition(nearPlayer)
	model:SetPrimaryPartCFrame(CFrame.new(pos))
	
	-- Behavior state: "idle" | "wandering" | "escaping"
	local t = math.random() * 100
	local state = "idle"
	local idleUntil = tick() + math.random() * IDLE_MAX  -- When to start wandering
	local wanderDir = Vector3.new(1, 0, 0)
	local wanderTimer = 0
	local wanderDuration = 0
	local runDir = nil
	local jumpVelocity = 0
	
	game:GetService("RunService").Heartbeat:Connect(function(dt)
		if not body.Parent then return end
		
		t = t + dt
		
		-- Check for nearby players (escaping overrides everything)
		local nearestDist = math.huge
		runDir = nil
		for _, p in pairs(game.Players:GetPlayers()) do
			if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
				local diff = body.Position - p.Character.HumanoidRootPart.Position
				local d = diff.Magnitude
				if d < ESCAPE_DISTANCE and d < nearestDist then
					nearestDist = d
					runDir = diff.Unit
				end
			end
		end
		
		if runDir then
			state = "escaping"
		elseif state == "escaping" then
			-- Just stopped escaping, go back to idle
			state = "idle"
			idleUntil = tick() + math.random() * 2
		end
		
		-- Movement direction and speed
		local moveDir = nil
		local speed = 0
		if runDir then
			moveDir = Vector3.new(runDir.X, 0, runDir.Z).Unit
			if moveDir.Magnitude < 0.1 then moveDir = Vector3.new(1, 0, 0) end
			speed = ESCAPE_SPEED
		elseif state == "wandering" then
			moveDir = wanderDir
			speed = WANDER_SPEED
			wanderTimer = wanderTimer + dt
			if wanderTimer >= wanderDuration then
				state = "idle"
				idleUntil = tick() + IDLE_MIN + math.random() * (IDLE_MAX - IDLE_MIN)
			end
		else
			-- Idle - wait until idleUntil then start wandering
			if tick() >= idleUntil then
				state = "wandering"
				local angle = math.random() * math.pi * 2
				wanderDir = Vector3.new(math.cos(angle), 0, math.sin(angle)).Unit
				wanderDuration = WANDER_MIN + math.random() * (WANDER_MAX - WANDER_MIN)
				wanderTimer = 0
			end
		end
		
		-- Deflect away from walls (perimeter, terrain, etc.)
		if moveDir then
			moveDir = deflectFromWall(body.Position, moveDir)
		end
		
		local isRunning = moveDir ~= nil
		
		-- Random jump when moving
		if isRunning and jumpVelocity <= 0 and math.random() < JUMP_CHANCE then
			jumpVelocity = JUMP_POWER
		end
		
		-- Apply jump (vertical arc)
		if jumpVelocity > 0 then
			local pos = body.Position
			body.CFrame = CFrame.new(pos.X, pos.Y + jumpVelocity * dt, pos.Z) * (body.CFrame - body.CFrame.Position)
			jumpVelocity = jumpVelocity - JUMP_GRAVITY * dt
		end
		
		-- Move body horizontally
		if moveDir then
			body.CFrame = body.CFrame + moveDir * (speed * dt)
		end
		
		-- Snap to ground (unless mid-jump)
		if jumpVelocity <= 0 then
			snapToGround(body, 0.2 * scale)
		end
		
		-- Rotate body to face movement direction when moving
		if moveDir and moveDir.Magnitude > 0.1 then
			body.CFrame = CFrame.new(body.Position) * CFrame.Angles(0, math.atan2(-moveDir.X, -moveDir.Z), 0)
		end
		
		local bodyCF = body.CFrame
		
		-- Idle: tail sway, head bob. Running: faster sway
		local sway = math.sin(t * (isRunning and 12 or 3)) * (isRunning and 0.15 or 0.08)
		
			-- Head (wedge snout): in front (-Z), slight bob
		head.CFrame = bodyCF * CFrame.new(0, 0.02 * scale, -0.6 * scale) * CFrame.Angles(0, 0, sway * 0.5)
		
		-- Eyes on head
		eyeL.CFrame = head.CFrame * CFrame.new(0.05 * scale, 0.08 * scale, 0.12 * scale)
		eyeR.CFrame = head.CFrame * CFrame.new(0.05 * scale, 0.08 * scale, -0.12 * scale)
		
		-- Back stripe (on top of body)
		stripe.CFrame = bodyCF * CFrame.new(0, 0.16 * scale, 0)
		
		-- Tail segments: behind (+Z), sways more (tapered)
		tail1.CFrame = bodyCF * CFrame.new(0, 0, 0.65 * scale) * CFrame.Angles(0, 0, sway * 1.2)
		tail2.CFrame = bodyCF * CFrame.new(0, 0, 1.0 * scale) * CFrame.Angles(0, 0, sway * 1.8)
		
		-- Legs: wedge parts, run cycle when running (X=side, Z=front/back)
		local legPositions = {{0.18, -0.35}, {0.18, 0.35}, {-0.18, -0.35}, {-0.18, 0.35}}
		for i = 1, 4 do
			local leg = model:FindFirstChild("Leg" .. i)
			if leg then
				local ox, oz = legPositions[i][1], legPositions[i][2]
				local legSway = math.sin(t * 18 + i * 1.6) * (isRunning and 0.5 or 0.2)
				-- Wedge legs: angled out and down
				leg.CFrame = bodyCF * CFrame.new(ox * scale, -0.15 * scale, oz * scale)
					* CFrame.Angles(legSway + 0.4, 0, (ox > 0 and -0.3 or 0.3))
			end
		end
	end)
	
	return model
end

-- Spawn loop
task.spawn(function()
	while true do
		if #lizardsFolder:GetChildren() < MAX_LIZARDS then
			createLizard(false)
		end
		task.wait(SPAWN_INTERVAL)
	end
end)

-- First 6 spawn NEAR PLAYER so they're visible when game starts
task.spawn(function()
	task.wait(1.5)  -- Wait for player to load
	for i = 1, 6 do
		createLizard(true)
		task.wait(0.4)
	end
end)

print("[LizardManager] Lizards are spawning!")
