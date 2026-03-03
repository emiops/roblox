--[[
	MakeBicycleRideable - Makes an existing Bicycle model in Workspace rideable
	Place your Bicycle model in Workspace and ensure it's named "Bicycle"
	The script finds it, adds a VehicleSeat, welds parts, and keeps it upright
	Place this script in ServerScriptService

	Tip: If you use BicycleManager too, disable it (or remove it) to avoid two bikes
]]

local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local BICYCLE_MODEL_NAME = "Bicycle"

local function weld(a, b)
	local w = Instance.new("WeldConstraint")
	w.Part0 = a
	w.Part1 = b
	w.Parent = a
	return w
end

local function findBicycleModel()
	-- Check Workspace and common locations
	local function searchIn(parent)
		local bike = parent:FindFirstChild(BICYCLE_MODEL_NAME)
		if bike and bike:IsA("Model") then return bike end
		for _, child in ipairs(parent:GetChildren()) do
			if child:IsA("Model") and child.Name == BICYCLE_MODEL_NAME then
				return child
			end
			local found = searchIn(child)
			if found then return found end
		end
		return nil
	end
	return searchIn(Workspace)
end

local function getPrimaryPart(model)
	-- Prefer Body part (from your model structure), else first BasePart
	local body = model:FindFirstChild("Body")
	if body and body:IsA("BasePart") then return body end
	for _, child in ipairs(model:GetDescendants()) do
		if child:IsA("BasePart") then return child end
	end
	return nil
end

local function makeRideable(bike)
	if bike:GetAttribute("IsRideable") then return end
	bike:SetAttribute("IsRideable", true)

	local primaryPart = getPrimaryPart(bike)
	if not primaryPart then
		warn("[MakeBicycleRideable] No BasePart found in", bike.Name)
		return
	end

	-- Create VehicleSeat at top of model (where rider sits)
	local cf, size = bike:GetBoundingBox()
	local seatPos = cf.Position + Vector3.new(0, size.Y / 2 - 0.1, 0)
	local seat = Instance.new("VehicleSeat")
	seat.Name = "Seat"
	seat.Size = Vector3.new(0.6, 0.15, 0.8)
	seat.Color = Color3.fromRGB(80, 50, 40)
	seat.Material = Enum.Material.SmoothPlastic
	seat.MaxSpeed = 25
	seat.Torque = 80
	seat.TurnSpeed = 2
	seat.CFrame = CFrame.new(seatPos) * CFrame.Angles(0, math.atan2(-cf.LookVector.X, -cf.LookVector.Z), 0)
	seat.Parent = bike

	-- Unanchor all parts and weld everything to the seat
	for _, part in ipairs(bike:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = false
			if part ~= seat then
				weld(seat, part)
			end
		end
	end

	bike.PrimaryPart = seat

	-- AlignOrientation: keep bike upright when riding
	local uprightAtt = Instance.new("Attachment")
	uprightAtt.Name = "UprightAtt"
	uprightAtt.Parent = seat

	local alignOrientation = Instance.new("AlignOrientation")
	alignOrientation.Name = "UprightAlign"
	alignOrientation.Mode = 0  -- OneAttachment
	alignOrientation.Attachment0 = uprightAtt
	alignOrientation.CFrame = CFrame.new()
	alignOrientation.MaxTorque = 50000
	alignOrientation.Responsiveness = 25
	alignOrientation.Parent = seat

	-- Anchor when empty, unanchor when occupied
	seat.Anchored = true
	seat:GetPropertyChangedSignal("Occupant"):Connect(function()
		seat.Anchored = (seat.Occupant == nil)
	end)

	-- Update upright target each frame (keep Y-up, allow steering rotation)
	RunService.Heartbeat:Connect(function()
		if not bike.Parent then return end
		local look = seat.CFrame.LookVector
		local lookXZ = Vector3.new(look.X, 0, look.Z)
		if lookXZ.Magnitude > 0.05 then
			lookXZ = lookXZ.Unit
			local right = lookXZ:Cross(Vector3.new(0, 1, 0)).Unit
			alignOrientation.CFrame = CFrame.fromMatrix(Vector3.zero, right, Vector3.new(0, 1, 0))
		end
	end)

	print("[MakeBicycleRideable] " .. bike.Name .. " is now rideable! Sit on it and use WASD.")
end

-- Run when model exists
local function setup()
	local bike = findBicycleModel()
	if bike then
		makeRideable(bike)
		return true
	end
	return false
end

-- Try immediately, then retry when descendants are added (model might load later)
if not setup() then
	task.spawn(function()
		Workspace.DescendantAdded:Connect(function()
			local bike = findBicycleModel()
			if bike and not bike:GetAttribute("IsRideable") then
				makeRideable(bike)
			end
		end)
		-- Also poll for a few seconds in case model is added dynamically
		for _ = 1, 30 do
			task.wait(1)
			if setup() then break end
		end
	end)
end
