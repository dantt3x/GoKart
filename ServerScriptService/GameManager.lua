local PlayerService = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Network = ReplicatedStorage:WaitForChild("Network")
local PlayerLoaded = Network:WaitForChild("PlayerLoaded")
local Reload = Network:WaitForChild("Reload")

local GameServices = ServerStorage:WaitForChild("Services")
local loadedServices = {}

local playerList = {}
local loadedPlayers = {}

local maximum_timeout = 7
local maximum_attempts = 50
local gameStarted = false
local debuging = true

function gameLoop()
	local foo = nil
	local attempts = 0
	
	while task.wait(1/60) do
		if debuging then
			for serviceName, _ in loadedServices do
				if loadedServices[serviceName].Update then
					task.spawn(loadedServices[serviceName].Update)
				end
			end
		end
		
		if #playerList > 1 then	
			if #playerList == #loadedPlayers then
				gameStarted = true
				
				if foo then
					task.cancel(foo)
				end
			else
	 			if foo == nil and attempts > maximum_attempts then
					foo = task.delay(maximum_timeout, function()
						gameStarted = true
					end)
				else
					attempts += maximum_attempts
					--Reload:FireAllClients()
				end
			end
		end
	end	
end

function loadServices()
	for _, service: ModuleScript in GameServices:GetChildren() do
		loadedServices[service.Name] = require(service)		
	end
	
	for serviceName, _ in pairs(loadedServices) do
		if loadedServices[serviceName].Load then
			task.defer(loadedServices[serviceName].Load, playerList, loadedServices, game.Workspace.Map)
		end
	end
end

function initializePlayerList()
	for index, player: Player in PlayerService:GetChildren() do
		playerList[index] = player.UserId
		
		if debuging then
			loadedPlayers[player.UserId] = true
		end
	end
end

task.wait(5)

task.spawn(initializePlayerList)
task.defer(loadServices)
task.defer(gameLoop)

PlayerLoaded.OnServerEvent:Connect(function(player)
	loadedPlayers[player.UserId] = true
end)

PlayerService.PlayerAdded:Connect(function(newPlayer)
	table.insert(playerList, newPlayer.UserId)
end)

PlayerService.PlayerRemoving:Connect(function(leavingPlayer)
	local userID = leavingPlayer.UserId
	
	for index, id in pairs(playerList) do
		if id == userID then
			table.remove(playerList, index)
		end
	end
end)



