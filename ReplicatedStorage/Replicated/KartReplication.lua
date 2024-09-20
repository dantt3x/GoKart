local KartReplication = {}

local PlayerService = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Network = ReplicatedStorage.Network
local KartUpdate = Network.KartUpdate
local reload = Network.Reload

local KartComponent = require(ReplicatedStorage.Components.KartComponent)

local localPlayerID = PlayerService.LocalPlayer.UserId

KartReplication.kartComponents = {}

local function unloadComponent(playerID: number)
	
end

local function loadNewComponent(playerID: number)
	--[[
		TODO:
		- figure out the driver of player
		- figure out the kart of player
	]]

	KartReplication.kartComponents[playerID] = KartComponent.new(false)
	KartReplication.kartComponents[playerID].isLocal = false
	
end

KartUpdate.OnClientEvent:Connect(function(playerID: number, kartInfo: {number: any})	
	if playerID == localPlayerID then return end
	
	if KartReplication.kartComponents[playerID] == nil then
		loadNewComponent(playerID)
		return
	end
	
	local mt = KartReplication.kartComponents[playerID]
	mt:KartUpdate(kartInfo)
end)

PlayerService.PlayerRemoving:Connect(function(leavingPlayer: Player)
	local kartComponent = KartReplication.kartComponents[leavingPlayer.UserId]
	
	if kartComponent then
		kartComponent:Clean()
		KartReplication.kartComponents[leavingPlayer.UserId] = nil
	end
end)

RunService.Heartbeat:Connect(function(dt)
	for playerID, kartComponent in KartReplication.kartComponents do
		kartComponent:Update(dt)
	end
end)



return KartReplication