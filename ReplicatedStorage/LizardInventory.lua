--[[
	LizardInventory - ModuleScript for lizard inventory functions
	Place in ReplicatedStorage
	Usage: local Inventory = require(ReplicatedStorage.LizardInventory)
]]

local LizardInventory = {}

local function getInventoryFolder(player)
	local folder = player:FindFirstChild("LizardInventory")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "LizardInventory"
		folder.Parent = player
	end
	return folder
end

-- Add a lizard to player's inventory (call from server)
function LizardInventory.AddLizard(player, lizardType)
	local folder = getInventoryFolder(player)
	local value = folder:FindFirstChild(lizardType)
	if not value then
		value = Instance.new("IntValue")
		value.Name = lizardType
		value.Parent = folder
	end
	value.Value = value.Value + 1
	return value.Value
end

-- Get count of a specific lizard type
function LizardInventory.GetCount(player, lizardType)
	local folder = player:FindFirstChild("LizardInventory")
	if not folder then return 0 end
	local value = folder:FindFirstChild(lizardType)
	return value and value.Value or 0
end

-- Get total lizards caught
function LizardInventory.GetTotal(player)
	local folder = player:FindFirstChild("LizardInventory")
	if not folder then return 0 end
	local total = 0
	for _, child in pairs(folder:GetChildren()) do
		if child:IsA("IntValue") then
			total = total + child.Value
		end
	end
	return total
end

-- Get all lizard types and counts (for UI)
function LizardInventory.GetAll(player)
	local folder = player:FindFirstChild("LizardInventory")
	if not folder then return {} end
	local result = {}
	for _, child in pairs(folder:GetChildren()) do
		if child:IsA("IntValue") then
			result[child.Name] = child.Value
		end
	end
	return result
end

return LizardInventory
