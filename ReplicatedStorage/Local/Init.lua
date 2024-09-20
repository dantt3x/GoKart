local Local = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Network = ReplicatedStorage:WaitForChild("Network")
local Controllers = ReplicatedStorage:WaitForChild("Controllers")
local Replicated = ReplicatedStorage:WaitForChild("Replicated")


local reload = Network:WaitForChild("Reload")

local loaded, reloaded = false, false
local input, kart, camera = nil, nil, nil

--[[

	TODO:
	- preload all assets needed for game to run
	- send handshake to server to let them know loading finished
	- if load takes too long, backout (>10%) or skip entirely (<50%)	
	- create assets needed for each player and listen for events from server
	
]]

script.Reset.Event:Connect(function()
	kart:Clean()
	task.wait()
	kart = Local.KartController.new(input)
	camera.kart = kart
end)

function Local.Start()
	for _, controller: ModuleScript in Controllers:GetChildren() do
		
		Local[controller.Name] = require(controller)
		
		if Local[controller.Name].Init then
			Local[controller.Name].Init()
		end		
	end
	
	for _, replicator: ModuleScript in Replicated:GetChildren() do
		Local[replicator.Name] = require(replicator)
		
		if Local[replicator.Name].Init then
			Local[replicator.Name].Init()
		end		
	end
	
	--preloadAnimations()
	
	input = Local.InputController.new()
	kart = Local.KartController.new(input)
	camera = Local.CameraController.new(kart, input)
	
	local frameDT = 0
	local physicsDT = 0
	
	RunService.PreSimulation:Connect(function(dt)
		
		frameDT = dt
		input:Update(dt)
		
	end)
	
	
	RunService.PreSimulation:Connect(function(dt, t)
		physicsDT = dt
		
		task.spawn(function()
			kart:Update(dt, frameDT)
		end)
	end)
	
	
	RunService.PostSimulation:Connect(function(dt)
		task.spawn(function()
			kart:Render(frameDT + physicsDT)
		end)
		
		task.defer(function()
			camera:Update(dt)
		end)
		
	end)
end
	
return Local

