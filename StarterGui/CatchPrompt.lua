--[[
	CatchPrompt - Catch lizards/rollie-pollies (E) or hit rocks (F)
	Shows CATCH or HIT button when near - works on phone, tablet, PC
	Place in StarterGui as a LocalScript
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local CATCH_RANGE = 25
local HIT_RANGE = 8

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CatchPromptGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

-- CATCH button (lizards + rollie-pollies)
local catchButton = Instance.new("TextButton")
catchButton.Name = "CatchButton"
catchButton.Size = UDim2.new(0, 160, 0, 50)
catchButton.Position = UDim2.new(0.5, -80, 0.7, 0)
catchButton.BackgroundColor3 = Color3.fromRGB(0, 180, 100)
catchButton.BorderSizePixel = 0
catchButton.Text = "CATCH"
catchButton.TextColor3 = Color3.fromRGB(255, 255, 255)
catchButton.TextSize = 22
catchButton.Font = Enum.Font.GothamBold
catchButton.Visible = false
catchButton.Parent = screenGui

-- HIT button (rocks)
local hitButton = Instance.new("TextButton")
hitButton.Name = "HitButton"
hitButton.Size = UDim2.new(0, 160, 0, 50)
hitButton.Position = UDim2.new(0.5, -80, 0.6, 0)
hitButton.BackgroundColor3 = Color3.fromRGB(140, 80, 40)
hitButton.BorderSizePixel = 0
hitButton.Text = "HIT ROCK"
hitButton.TextColor3 = Color3.fromRGB(255, 255, 255)
hitButton.TextSize = 20
hitButton.Font = Enum.Font.GothamBold
hitButton.Visible = false
hitButton.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = catchButton
corner:Clone().Parent = hitButton

local function isNearCatchable()
	local character = player.Character
	if not character or not character:FindFirstChild("HumanoidRootPart") then return false end
	local root = character.HumanoidRootPart
	
	local lizardsFolder = workspace:FindFirstChild("Lizards")
	if lizardsFolder then
		for _, m in pairs(lizardsFolder:GetChildren()) do
			if m:IsA("Model") and m.PrimaryPart then
				if (m.PrimaryPart.Position - root.Position).Magnitude < CATCH_RANGE then
					return true
				end
			end
		end
	end
	
	local rollieFolder = workspace:FindFirstChild("RolliePollies")
	if rollieFolder then
		for _, m in pairs(rollieFolder:GetChildren()) do
			if m:IsA("Model") and m.PrimaryPart then
				if (m.PrimaryPart.Position - root.Position).Magnitude < CATCH_RANGE then
					return true
				end
			end
		end
	end
	return false
end

local function isNearRock()
	local character = player.Character
	if not character or not character:FindFirstChild("HumanoidRootPart") then return false end
	local root = character.HumanoidRootPart
	
	local rocksFolder = workspace:FindFirstChild("Rocks")
	if not rocksFolder then return false end
	
	for _, rock in pairs(rocksFolder:GetChildren()) do
		if rock:IsA("BasePart") then
			if (rock.Position - root.Position).Magnitude < HIT_RANGE then
				return true
			end
		end
	end
	return false
end

catchButton.MouseButton1Click:Connect(function()
	if isNearCatchable() then
		ReplicatedStorage:WaitForChild("CatchLizardRequest"):FireServer()
	end
end)

hitButton.MouseButton1Click:Connect(function()
	if isNearRock() then
		ReplicatedStorage:WaitForChild("HitRockRequest"):FireServer()
	end
end)

RunService.RenderStepped:Connect(function()
	catchButton.Visible = isNearCatchable()
	hitButton.Visible = isNearRock()
end)

UserInputService.InputBegan:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.E and isNearCatchable() then
		ReplicatedStorage:WaitForChild("CatchLizardRequest"):FireServer()
	elseif input.KeyCode == Enum.KeyCode.F and isNearRock() then
		ReplicatedStorage:WaitForChild("HitRockRequest"):FireServer()
	end
end)
