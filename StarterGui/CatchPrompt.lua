--[[
	CatchPrompt - Catch lizards with button (mobile) or E key (desktop)
	Shows tappable "CATCH" button when near a lizard - works on phone, tablet, PC
	Place in StarterGui as a LocalScript
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local CATCH_RANGE = 25  -- Match server - catch from further away (lizards escape at 14 studs)

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CatchPromptGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

-- Tappable/clickable CATCH button (works on mobile touch + desktop click)
local catchButton = Instance.new("TextButton")
catchButton.Name = "CatchButton"
catchButton.Size = UDim2.new(0, 160, 0, 50)
catchButton.Position = UDim2.new(0.5, -80, 0.7, 0)  -- Bottom center, easy thumb reach on mobile
catchButton.BackgroundColor3 = Color3.fromRGB(0, 180, 100)
catchButton.BorderSizePixel = 0
catchButton.Text = "CATCH"
catchButton.TextColor3 = Color3.fromRGB(255, 255, 255)
catchButton.TextSize = 22
catchButton.Font = Enum.Font.GothamBold
catchButton.Visible = false
catchButton.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = catchButton

-- Check if player is near any lizard (defined before button uses it)
local function isNearLizard()
	local character = player.Character
	if not character then return false end
	
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then return false end
	
	local lizardsFolder = workspace:FindFirstChild("Lizards")
	if not lizardsFolder then return false end
	
	for _, lizard in pairs(lizardsFolder:GetChildren()) do
		if lizard:IsA("Model") and lizard.PrimaryPart then
			local dist = (lizard.PrimaryPart.Position - root.Position).Magnitude
			if dist < CATCH_RANGE then
				return true
			end
		end
	end
	return false
end

-- Button tap/click - works on mobile and desktop
catchButton.MouseButton1Click:Connect(function()
	if isNearLizard() then
		ReplicatedStorage:WaitForChild("CatchLizardRequest"):FireServer()
	end
end)

-- Show/hide button when near lizard
RunService.RenderStepped:Connect(function()
	catchButton.Visible = isNearLizard()
end)

-- E key for desktop/keyboard users
UserInputService.InputBegan:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.E and isNearLizard() then
		ReplicatedStorage:WaitForChild("CatchLizardRequest"):FireServer()
	end
end)
