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
local ROLLIE_WANDER_SPEED = 3
local WALL_CHECK_DISTANCE = 4
local WALL_CHECK_HEIGHT = 0.3

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

local terrariumsFolder = Workspace:FindFirstChild("Terrariums")

local function deflectFromWall(pos, moveDir)
	if not moveDir or moveDir.Magnitude < 0.1 then return moveDir end
	local flatDir = Vector3.new(moveDir.X, 0, moveDir.Z).Unit
	local origin = pos + Vector3.new(0, WALL_CHECK_HEIGHT, 0)
	local direction = flatDir * WALL_CHECK_DISTANCE
	local rayParams = RaycastParams.new()
	rayParams.FilterDescendantsInstances = {rocksFolder, rolliePolliesFolder}
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	local result = Workspace:Raycast(origin, direction, rayParams)
	if result then
		local n = result.Normal
		local nFlat = Vector3.new(n.X, 0, n.Z)
		if nFlat.Magnitude > 0.01 then
			nFlat = nFlat.Unit
			local reflected = flatDir - 2 * flatDir:Dot(nFlat) * nFlat
			if reflected.Magnitude > 0.1 then
				return Vector3.new(reflected.X, moveDir.Y, reflected.Z).Unit
			end
		end
		return Vector3.new(-flatDir.Z, moveDir.Y, flatDir.X).Unit
	end
	return moveDir
end

local function getGroundPosition()
	local maxAttempts = 15
	for _ = 1, maxAttempts do
		local x = math.random(-SPAWN_RADIUS, SPAWN_RADIUS)
		local z = math.random(-SPAWN_RADIUS, SPAWN_RADIUS)
		local origin = Vector3.new(x, 300, z)
		local rayParams = RaycastParams.new()
		rayParams.FilterDescendantsInstances = {rocksFolder, rolliePolliesFolder}
		rayParams.FilterType = Enum.RaycastFilterType.Exclude
		local result = Workspace:Raycast(origin, Vector3.new(0, -600, 0), rayParams)
		if result then
			local terrariums = terrariumsFolder or Workspace:FindFirstChild("Terrariums")
			-- Reject: hit terrarium (walls, floors, glass - don't spawn on or inside)
			if terrariums and result.Instance:IsDescendantOf(terrariums) then
				-- try next position
			elseif result.Normal.Y >= 0.6 then
				-- Accept: hit floor (surface pointing up), not a wall
				return result.Position
			end
		end
	end
	-- Fallback after max attempts
	local x = math.random(-SPAWN_RADIUS, SPAWN_RADIUS)
	local z = math.random(-SPAWN_RADIUS, SPAWN_RADIUS)
	return Vector3.new(x, 5, z)
end

-- 2x lizard size (was 0.8)
local ROLLIE_SCALE = 1.6

local function createRolliePollie(spawnPos)
	local model = Instance.new("Model")
	model.Name = "RolliePollie"
	
	-- Caterpillar shape: long body with 5 segments (like real pill bug elongated)
	local scale = ROLLIE_SCALE
	local segW = 0.22 * scale
	local segH = 0.2 * scale
	local segL = 0.35 * scale
	
	local segments = {}
	for i = 1, 5 do
		local seg = Instance.new("Part")
		seg.Name = "Segment" .. i
		seg.Shape = Enum.PartType.Block
		seg.Size = Vector3.new(segW, segH, segL)
		-- Zebra-style: alternating light grey and dark grey stripes
		seg.Color = (i % 2 == 1) and Color3.fromRGB(220, 220, 218) or Color3.fromRGB(85, 85, 82)
		seg.Material = Enum.Material.SmoothPlastic
		seg.Anchored = true
		seg.CanCollide = true
		seg.Parent = model
		segments[i] = seg
	end
	
	-- Rolled-up ball (hidden when elongated)
	local ball = Instance.new("Part")
	ball.Name = "Ball"
	ball.Shape = Enum.PartType.Ball
	ball.Size = Vector3.new(0.4 * scale, 0.4 * scale, 0.4 * scale)
	ball.Color = Color3.fromRGB(150, 150, 148)  -- Medium grey for rolled ball (zebra stripes blend)
	ball.Material = Enum.Material.SmoothPlastic
	ball.Anchored = true
	ball.CanCollide = true
	ball.Transparency = 1  -- Hidden until rolled
	ball.Parent = model
	
	model.PrimaryPart = segments[3]
	-- Spawn 1 stud above ground so visible (was spawning underground)
	local pos = spawnPos + Vector3.new(0, 1, 0)
	model:SetPrimaryPartCFrame(CFrame.new(pos))
	
	-- Position caterpillar segments in a line
	local baseCF = CFrame.new(pos)
	for i, seg in ipairs(segments) do
		local offset = (i - 3) * segL * 0.85
		seg.CFrame = baseCF * CFrame.new(0, 0, offset)
	end
	ball.CFrame = baseCF
	
	model.Parent = rolliePolliesFolder
	
	-- States: "wander" | "roll" | "underground" | "escape"
	local isRolled = false
	local state = "wander"
	local stateStart = tick()
	local stateDuration = 1 + math.random() * 0.5  -- For roll/underground
	local randomDir = Vector3.new(math.random() - 0.5, 0, math.random() - 0.5).Unit
	local dirChangeTime = tick() + 3 + math.random() * 4
	local nextRollTime = tick() + 6 + math.random() * 6
	local nextUndergroundTime = tick() + 18 + math.random() * 15
	local groundY = pos.Y
	
	-- Get ground Y at current X,Z (for underground and clamping)
	local function getGroundYAtPos(x, z)
		local origin = Vector3.new(x, pos.Y + 20, z)
		local rayParams = RaycastParams.new()
		local exclude = {rocksFolder, rolliePolliesFolder}
		local terrariums = terrariumsFolder or Workspace:FindFirstChild("Terrariums")
		if terrariums then table.insert(exclude, terrariums) end
		rayParams.FilterDescendantsInstances = exclude
		rayParams.FilterType = Enum.RaycastFilterType.Exclude
		local result = Workspace:Raycast(origin, Vector3.new(0, -50, 0), rayParams)
		if result then
			return result.Position.Y
		end
		return pos.Y
	end
	
	RunService.Heartbeat:Connect(function(dt)
		if not model.Parent then return end
		
		local t = tick()
		local nearestDist = math.huge
		local nearestPlayer = nil
		for _, p in pairs(game.Players:GetPlayers()) do
			local char = p.Character
			if char and char:FindFirstChild("HumanoidRootPart") then
				local d = (char.HumanoidRootPart.Position - pos).Magnitude
				if d < nearestDist then
					nearestDist = d
					nearestPlayer = p
				end
			end
		end
		
		-- Escape when player near
		if nearestPlayer and nearestDist < ROLLIE_ESCAPE_DIST then
			state = "escape"
			stateStart = t
			local awayDir = (pos - nearestPlayer.Character.HumanoidRootPart.Position).Unit
			local escapeDir = (Vector3.new(awayDir.X, 0, awayDir.Z) + randomDir * 0.5).Unit
			local flatDir = Vector3.new(escapeDir.X, 0, escapeDir.Z).Unit
			flatDir = deflectFromWall(pos, flatDir)
			flatDir = Vector3.new(flatDir.X, 0, flatDir.Z).Unit
			
			local RUN_DURATION, ROLL_DURATION = 1.5, 1.0
			local phaseOffset = math.random() * 2
			local cycleTime = (t - stateStart + phaseOffset) % (RUN_DURATION + ROLL_DURATION)
			if cycleTime < RUN_DURATION then
				if isRolled then
					isRolled = false
					for _, seg in ipairs(segments) do seg.Transparency = 0 end
					ball.Transparency = 1
					randomDir = Vector3.new(math.random() - 0.5, 0, math.random() - 0.5).Unit
				end
				pos = pos + flatDir * ROLLIE_ESCAPE_SPEED * dt
				local lookCF = CFrame.lookAt(pos, pos + flatDir)
				for i, seg in ipairs(segments) do
					seg.CFrame = lookCF * CFrame.new(0, 0, (i - 3) * segL * 0.85)
				end
				ball.CFrame = CFrame.new(pos)
			else
				if not isRolled then
					isRolled = true
					for _, seg in ipairs(segments) do seg.Transparency = 1 end
					ball.Transparency = 0
				end
				ball.CFrame = CFrame.new(pos)
				pos = pos + flatDir * (ROLLIE_ESCAPE_SPEED * 0.5) * dt
			end
		else
			-- Idle: wander, roll, or underground
			if state == "escape" then
				state = "wander"
				stateStart = t
				dirChangeTime = t + 3 + math.random() * 4
				if isRolled then
					isRolled = false
					for _, seg in ipairs(segments) do seg.Transparency = 0 end
					ball.Transparency = 1
				end
			end
			
			local stateElapsed = t - stateStart
			
			if state == "wander" then
				-- Check for roll (every ~6-12s)
				if t >= nextRollTime then
					state = "roll"
					stateStart = t
					stateDuration = 1 + math.random() * 0.5
					nextRollTime = t + 6 + math.random() * 6
				else
					if t > dirChangeTime then
						dirChangeTime = t + 2 + math.random() * 5
						randomDir = Vector3.new(math.random() - 0.5, 0, math.random() - 0.5).Unit
					end
					local flatDir = deflectFromWall(pos, randomDir)
					flatDir = Vector3.new(flatDir.X, 0, flatDir.Z).Unit
					if flatDir.Magnitude > 0.1 then
						pos = pos + flatDir * ROLLIE_WANDER_SPEED * dt
						if isRolled then
							isRolled = false
							for _, seg in ipairs(segments) do seg.Transparency = 0 end
							ball.Transparency = 1
						end
						local lookCF = CFrame.lookAt(pos, pos + flatDir)
						for i, seg in ipairs(segments) do
							seg.CFrame = lookCF * CFrame.new(0, 0, (i - 3) * segL * 0.85)
						end
						ball.CFrame = CFrame.new(pos)
					end
				end
			elseif state == "roll" then
				-- Roll for 1-1.5s (duration fixed when entering)
				if not isRolled then
					isRolled = true
					for _, seg in ipairs(segments) do seg.Transparency = 1 end
					ball.Transparency = 0
				end
				ball.CFrame = CFrame.new(pos)
				if stateElapsed > stateDuration then
					state = "wander"
					stateStart = t
					isRolled = false
					for _, seg in ipairs(segments) do seg.Transparency = 0 end
					ball.Transparency = 1
					randomDir = Vector3.new(math.random() - 0.5, 0, math.random() - 0.5).Unit
				end
			elseif state == "underground" then
				-- Stay underground 2-3s
				if stateElapsed > stateDuration then
					state = "wander"
					stateStart = t
					pos = Vector3.new(pos.X, groundY, pos.Z)
					for _, seg in ipairs(segments) do seg.Transparency = 0 end
					ball.Transparency = 1
					isRolled = false
					randomDir = Vector3.new(math.random() - 0.5, 0, math.random() - 0.5).Unit
					nextUndergroundTime = t + 18 + math.random() * 15
				end
			end
			
			-- Go underground periodically (every ~18-33s)
			if state == "wander" and t >= nextUndergroundTime then
				state = "underground"
				stateStart = t
				stateDuration = 2 + math.random() * 1
				groundY = getGroundYAtPos(pos.X, pos.Z)
				for _, seg in ipairs(segments) do seg.Transparency = 1 end
				ball.Transparency = 1
				pos = Vector3.new(pos.X, groundY - 1.5, pos.Z)
			end
		end
		
		-- Clamp to bounds (don't go through walls / out of area)
		pos = Vector3.new(
			math.clamp(pos.X, -SPAWN_RADIUS, SPAWN_RADIUS),
			pos.Y,
			math.clamp(pos.Z, -SPAWN_RADIUS, SPAWN_RADIUS)
		)
		
		-- Update visuals (escape block does its own updates; this handles wander/roll)
		if state ~= "escape" and state ~= "underground" then
			if isRolled then
				ball.CFrame = CFrame.new(pos)
			else
				local lookDir = Vector3.new(randomDir.X, 0, randomDir.Z)
				if lookDir.Magnitude < 0.1 then lookDir = Vector3.new(1, 0, 0) end
				local lookCF = CFrame.lookAt(pos, pos + lookDir.Unit)
				for i, seg in ipairs(segments) do
					seg.CFrame = lookCF * CFrame.new(0, 0, (i - 3) * segL * 0.85)
				end
				ball.CFrame = CFrame.new(pos)
			end
		end
	end)
	
	return model
end

local function isPositionNearTerrarium(pos, radius)
	local terrariums = terrariumsFolder or Workspace:FindFirstChild("Terrariums")
	if not terrariums then return false end
	local overlapParams = OverlapParams.new()
	overlapParams.FilterDescendantsInstances = {rocksFolder, rolliePolliesFolder}
	overlapParams.FilterType = Enum.RaycastFilterType.Exclude
	local parts = Workspace:GetPartBoundsInRadius(pos, radius, overlapParams)
	for _, part in ipairs(parts) do
		if part:IsDescendantOf(terrariums) then
			return true
		end
	end
	return false
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
	local rockCenter = pos + Vector3.new(0, rock.Size.Y / 2, 0)
	-- Don't spawn if rock would overlap terrarium walls
	if isPositionNearTerrarium(rockCenter, math.max(rock.Size.X, rock.Size.Z) / 2 + 1) then
		rock:Destroy()
		return nil
	end
	rock.Position = rockCenter
	rock.Parent = rocksFolder
	
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
		-- Spawn at rock base (ground level) so rollie-pollie is visible
		local rockBottom = nearestRock.Position - Vector3.new(0, nearestRock.Size.Y / 2, 0)
		nearestRock:Destroy()
		createRolliePollie(rockBottom)
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
