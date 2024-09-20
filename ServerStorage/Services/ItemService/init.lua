local Item = {}
Item.__index = Item

type storedItem = {
	playerID: number,
	itemID: number,
}

type activeItem = {
	id: number,
	object: {}, -- class
}

type itemGrid = {
	radius: number,
	position: Vector3,
	boxes: {[string]: Vector3},
}

--[[

	TODO:
	- update collision for itemboxes
	- give random item to player
	- control logic of items

]]

local PlayerService = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Network = ReplicatedStorage.Network.Item

local BoxUpdate = Network.BoxUpdate
local NewItem = Network.NewItem
local UseItem = Network.UseItem
local ItemUpdate = Network.ItemUpdate

local KartService = nil

local test_minRadius = 5
local test_maximumItems = 2
local test_itemBoxCD = 2

local itemGrids: {[string]: itemGrid} = {}
local onCooldown: {[string]: boolean} = {}

local storedItems: {[number]: storedItem} = {}
local activeItems: {[number]: activeItem} = {}

function itemBoxCooldown(boxName)
	onCooldown[boxName] = false
	BoxUpdate:FireAllClients(boxName, false)
end

function createNewActiveItem(playerID: number, itemID: number)
	
end

function createNewStoredItem(playerID: number): storedItem
	
	--[[
	
		TODO:
		- get pool of all items that player can get at his position rank (checkpoints)
		- rng
		- set itemID
	]]
	
	local newItemID = "TestItem"
	
	local newStoredItem: storedItem = {
		playerID = playerID,
		itemID = newItemID,
	}
	
	local playerItemCount = 0
	
	for _, storedItem: storedItem in pairs(storedItems) do
		if storedItem.playerID == playerID then
			playerItemCount += 1
		end
	end
	
	if playerItemCount >= test_maximumItems then
		for i = #storedItems, 1, -1 do
			if storedItems[i].playerID == playerID then
				
				playerItemCount -= 1
				table.remove(storedItems, i)
				
				if playerItemCount >= test_maximumItems then
					continue
				else
					break
				end
				
			end
		end
	end

	table.insert(storedItems, newStoredItem)
	return newStoredItem
end

function checkKartCollision(kartPosition: Vector3): string | null
	
	for gridName, grid: itemGrid in pairs(itemGrids) do
		local gridDistance = (grid.position - kartPosition).Magnitude

		if gridDistance <= grid.radius then
			
			for boxName, boxPosition: Vector3 in pairs(grid.boxes) do
				local boxDistance = (boxPosition - kartPosition).Magnitude
				
				if boxDistance <= test_minRadius and (onCooldown[boxName] == false or onCooldown[boxName] == nil) then
					return boxName
				else
					continue
				end
			end
			
		end
	end
	
end

function Item.Update()	
	for index, playerKart in KartService.playerKarts do
		local kartPosition: Vector3 = playerKart.position

		local boxHitName: string = checkKartCollision(kartPosition)

		if boxHitName then
			-- boxhitname, onCooldown
			onCooldown[boxHitName] = true
			BoxUpdate:FireAllClients(boxHitName, true)
			task.delay(test_itemBoxCD, itemBoxCooldown, boxHitName)
			
			createNewStoredItem(playerKart.playerID)
			
			print(storedItems)
			
			-- do smth			
		end
	end
	
	for _, item: activeItem in pairs(activeItems) do
		item.object:Update()
		ItemUpdate:FireAllClients(item.object.clientInfo)
	end	
	
end

PlayerService.PlayerRemoving:Connect(function(leavingPlayer: Player)
	
	local found = 0
	
	for index, storedItem: storedItem in pairs(storedItems) do
		if storedItem.playerID == leavingPlayer.UserId then
			table.remove(storedItems, index)
			
			found += 1
			
			if found > test_maximumItems then
				break
			end
		end
	end
	
end)

function Item.Load(playerList, loadedServices, mapFolder)
	KartService = loadedServices.KartService

	local itemBoxFolder = mapFolder.ItemBoxes
	
	for _, grid: Model in itemBoxFolder:GetChildren() do
		
		local newLoadedGrid: itemGrid = {}
		newLoadedGrid.radius = 0
		newLoadedGrid.position = grid.WorldPivot.Position
		newLoadedGrid.boxes = {}
		
		for _, itemBox: BasePart in grid:GetChildren() do
			newLoadedGrid.radius += itemBox.Size.Magnitude
			newLoadedGrid.boxes[itemBox.Name] = itemBox.Position
		end
		
		itemGrids[grid.Name] = newLoadedGrid
	end
end

UseItem.OnServerEvent:Connect(function(player: Player, itemID: number)	
	local playerID = player.UserId
	
	for index, storedItem in pairs(storedItems) do
		
		if storedItem.itemID == itemID and storedItem.playerID == playerID then
			createNewActiveItem(storedItem.playerID, storedItem.itemID)
			table.remove(storedItems, index)
			
			break
		end
		
	end
end)

return Item
