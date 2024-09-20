local Checkpoint = {}

type playerPlacement = {
	playerID: number,
	currentLap: number,
	currentCheckpoint: number,
	placement: number,
}

type checkpoint = {
	position: Vector3,
	radius: number,
}

--[[

	TODO:
	- load map checkpoints
	- track where each player is on map
	- sort players by who finished the quickest
	- end race

]]

local PlayerService = game:GetService("Players")
local KartService = nil

local initialPlacement = 1
Checkpoint.playerPlacements = {}
Checkpoint.checkpoints = {}

Checkpoint.Finished = script.Finished

local finishedPlayers = 0

function sortPlayersByPlacement(): ()	
	for i = 1, #Checkpoint.playerPlacements, 1 do
		
		local hasSwapped = false
		
		for j = 1, #Checkpoint.playerPlacements - i, 1 do
			local placementA: playerPlacement = Checkpoint.playerPlacements[j]
			local placementB: playerPlacement = Checkpoint.playerPlacements[j + 1]
			
			if placementA ~= nil and placementB ~= nil then
				local valueA = placementA.currentCheckpoint * placementA.currentLap
				local valueB = placementB.currentCheckpoint * placementB.currentCheckpoint
				
				local rankA = placementA.placement
				local rankB = placementB.placement
				
				if valueA > valueB and rankA < rankB then
					
					placementA.placement = rankB
					hasSwapped = true
					
				elseif valueB > valueA and rankB < rankA then
					
					placementB.placement = rankA
					hasSwapped = true
					
				end
			end
			
		end
	
		if hasSwapped == false then
			break
		end
	end
end

function Checkpoint.Update()

	
	for _, playerKart in KartService.playerKarts do
		
		local kartPosition: Vector3 = playerKart.position
		local playerID = playerKart.playerID
		
		local foundPlacement: playerPlacement = nil
		
		for _, placement: playerPlacement in Checkpoint.playerPlacements do
			if placement.playerID == playerID then
				foundPlacement = placement
				break	
			end
		end
		
		if foundPlacement then
			local nextInt = foundPlacement.currentCheckpoint + 1
			local checkpointToCheck: checkpoint = Checkpoint.checkpoints[nextInt]
	
			local position: Vector3 = checkpointToCheck.position
			local radius: number = checkpointToCheck.radius
		
			if (kartPosition - position).Magnitude <= radius then
				
				if nextInt >= #Checkpoint.checkpoints then
					foundPlacement.currentLap += 1
					foundPlacement.currentCheckpoint = 1
					
					if foundPlacement.currentLap > 3 then
						print("RACE FINISHED!")
						finishedPlayers += 1
					end
				else
					foundPlacement.currentCheckpoint = nextInt
				end
			end 
		else
			warn("player placement not found?")
		end
		
	end
	
	sortPlayersByPlacement()
	
end

PlayerService.PlayerRemoving:Connect(function(leavingPlayer: Player)
	
	for index, playerPlacement: playerPlacement in pairs(Checkpoint.playerPlacements) do
		if playerPlacement.playerID == leavingPlayer.UserId then
			table.remove(Checkpoint.playerPlacements, index)
			break
		end
	end
	
end)

function Checkpoint.Load(playerList, loadedServices, mapFolder)
	KartService = loadedServices.KartService
	
	for index, playerID in pairs(playerList) do
		local newPlacement: playerPlacement = {}
		newPlacement.playerID = playerID
		newPlacement.currentLap = 1
		newPlacement.currentCheckpoint = 1
		newPlacement.placement = initialPlacement
		
		table.insert(Checkpoint.playerPlacements, newPlacement)
		
		initialPlacement += 1
	end
	
	local mapCheckpoints = mapFolder.Checkpoints:GetChildren()
	
	for _, checkpointPart: BasePart in mapCheckpoints do
		local newCheckpoint: checkpoint = {}
		newCheckpoint.position = checkpointPart.Position
		
		newCheckpoint.radius = Vector3.new(checkpointPart.Size.X/2, 0, 0).Magnitude
		
		Checkpoint.checkpoints[tonumber(checkpointPart.Name)] = newCheckpoint
	end
end


return Checkpoint