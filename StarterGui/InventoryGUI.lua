--[[
	InventoryGUI - Shows lizard inventory when pressing I
	Place in StarterGui as a LocalScript (or inside a ScreenGui)
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local LizardInventory = require(ReplicatedStorage:WaitForChild("LizardInventory"))

-- Create GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "LizardInventoryGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Name = "InventoryFrame"
frame.Size = UDim2.new(0, 280, 0, 0)
frame.Position = UDim2.new(0.5, -140, 0.1, 0)
frame.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
frame.BorderSizePixel = 0
frame.Visible = false
frame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = frame

local padding = Instance.new("UIPadding")
padding.PaddingTop = UDim.new(0, 12)
padding.PaddingBottom = UDim.new(0, 12)
padding.PaddingLeft = UDim.new(0, 16)
padding.PaddingRight = UDim.new(0, 16)
padding.Parent = frame

local title = Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(1, 0, 0, 28)
title.BackgroundTransparency = 1
title.Text = "Lizard Inventory"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 20
title.Font = Enum.Font.GothamBold
title.Parent = frame

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 6)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = frame

local function updateInventory()
	for _, child in pairs(frame:GetChildren()) do
		if child:IsA("TextLabel") and child.Name ~= "Title" then
			child:Destroy()
		end
	end
	
	local all = LizardInventory.GetAll(player)
	local count = 0
	for lizardType, amount in pairs(all) do
		if amount > 0 then
			count = count + 1
			local label = Instance.new("TextLabel")
			label.Name = lizardType
			label.Size = UDim2.new(1, 0, 0, 24)
			label.BackgroundTransparency = 1
			label.Text = "  " .. lizardType .. ": " .. amount
			label.TextColor3 = Color3.fromRGB(200, 200, 200)
			label.TextSize = 16
			label.Font = Enum.Font.Gotham
			label.TextXAlignment = Enum.TextXAlignment.Left
			label.LayoutOrder = count
			label.Parent = frame
		end
	end
	
	if count == 0 then
		local empty = Instance.new("TextLabel")
		empty.Size = UDim2.new(1, 0, 0, 24)
		empty.BackgroundTransparency = 1
		empty.Text = "  No lizards caught yet!"
		empty.TextColor3 = Color3.fromRGB(150, 150, 150)
		empty.TextSize = 14
		empty.Font = Enum.Font.Gotham
		empty.TextXAlignment = Enum.TextXAlignment.Left
		empty.LayoutOrder = 1
		empty.Parent = frame
		count = 1
	end
	
	frame.Size = UDim2.new(0, 280, 0, 12 + 28 + count * 30)
end

local function toggleInventory()
	frame.Visible = not frame.Visible
	if frame.Visible then
		updateInventory()
	end
end

-- Press I to open/close inventory
UserInputService.InputBegan:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.I then
		toggleInventory()
	end
end)

-- Update when catching a lizard
ReplicatedStorage:WaitForChild("LizardCaught").OnClientEvent:Connect(function(lizardType, newCount)
	if frame.Visible then
		updateInventory()
	end
end)

-- Create initially hidden
frame.Visible = false
