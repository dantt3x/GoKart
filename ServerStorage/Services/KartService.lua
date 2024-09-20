local Kart = {}

--[[

	TODO:
	- store all players positions and relative info
	- prevent players from going to fast or continuing while lagging

]]

type playerKart = {
	playerID: number,
	position: Vector3,
}

local PlayerService = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Network = ReplicatedStorage.Network
local KartUpdate = Network.KartUpdate

Kart.loaded = false
Kart.playerKarts = {}

function updatePlayerKart(index: number, position: Vector3)
	local playerKart: playerKart = Kart.playerKarts[index]
	playerKart.position = position
end

function Kart.findStoredPlayer(id: number): number
	local foundIndex = 0
	
	for index, playerKart: playerKart in pairs(Kart.playerKarts) do
		if playerKart.playerID == id then
			foundIndex = index
			break
		end
	end
	
	return foundIndex
end

function Kart.Load(playerList)
	for index, id in pairs(playerList) do
		table.insert(Kart.playerKarts, {
			playerID = id,
			position = Vector3.new(0, 0, 0),
		})
	end
	
	Kart.loaded = true
end

PlayerService.PlayerRemoving:Connect(function(leavingPlayer:Player)
	
	for index, playerKart: playerKart in pairs(Kart.playerKarts) do
		if playerKart.playerID == leavingPlayer.UserId then
			table.remove(Kart.playerKarts, index)
			break
		end
	end	
	
end)

KartUpdate.OnServerEvent:Connect(function(player: Player, info: {[number]: any})
	if Kart.loaded == false then 
		return
	end
	
	local playerID = player.UserId
	local playerIndex = Kart.findStoredPlayer(playerID)
	local position: Vector3 = info[1].Position
	
	if playerIndex ~= 0 then
		updatePlayerKart(playerIndex, position)
	end
	
	KartUpdate:FireAllClients(playerID, info)
end)

return Kart