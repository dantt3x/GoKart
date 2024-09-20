local ItemReplication = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Network = ReplicatedStorage.Network.Item

local itemBoxes = game.Workspace.Map.ItemBoxes:GetChildren()

local BoxUpdate = Network.BoxUpdate
local ItemUpdate = Network.ItemUpdate

local activeItems = {}

local function findBox(boxName: string): BasePart
	for _, grid: Model in itemBoxes do
		if grid:FindFirstChild(boxName) then
			return grid[boxName]
		end
	end
	
	return nil
end

BoxUpdate.OnClientEvent:Connect(function(boxName: string, onCooldown: boolean)
	local foundBox = findBox(boxName)	
	
	if foundBox then
		if onCooldown then
			foundBox.Transparency = 1
		else
			foundBox.Transparency = 0
		end
	end
end)

return ItemReplication