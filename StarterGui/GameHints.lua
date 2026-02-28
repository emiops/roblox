--[[
	GameHints - Always-visible on-screen instructions
	Place in StarterGui as a LocalScript
]]

local Players = game:GetService("Players")

local player = Players.LocalPlayer
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "GameHints"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

local hint = Instance.new("TextLabel")
hint.Name = "Hint"
hint.Size = UDim2.new(0, 400, 0, 50)
hint.Position = UDim2.new(0.5, -200, 1, -70)
hint.BackgroundTransparency = 1
hint.Text = "E/CATCH: lizards & rollie-pollies  •  F/HIT: rocks (reveal rollie-pollies)  •  I: inventory  •  All appear in terrarium"
hint.TextColor3 = Color3.fromRGB(255, 255, 255)
hint.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
hint.TextStrokeTransparency = 0.5
hint.TextSize = 16
hint.Font = Enum.Font.Gotham
hint.Parent = screenGui
