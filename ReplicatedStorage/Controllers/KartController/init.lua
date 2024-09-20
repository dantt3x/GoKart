local KartController = {}
KartController.__index = KartController

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Network = ReplicatedStorage.Network
local Objects = ReplicatedStorage.Objects

local KartUpdate = Network.KartUpdate

local InputController = nil

local Util = require(ReplicatedStorage.Helpers.Utility)
local KartComponent = require(ReplicatedStorage.Components.KartComponent)

local raycastParams = RaycastParams.new()
local overlapParams = OverlapParams.new()

local temp_boostPads = game.Workspace:WaitForChild("BoostPads"):GetChildren()


local DEBUG = true

local function updateStatsToText(self)
	local statchanger = game.Players.LocalPlayer.PlayerGui:WaitForChild("ScreenGui").StatChanger
	
	if tonumber(statchanger.Acceleration.Text) ~= nil then
		self.acceleration = tonumber(statchanger.Acceleration.Text)
	end
	if tonumber(statchanger.Speed.Text) ~= nil then
		self.speed = tonumber(statchanger.Speed.Text)
	end
	if tonumber(statchanger.Drag.Text) ~= nil then
		self.drag = tonumber(statchanger.Drag.Text)
	end
	if tonumber(statchanger.Mass.Text) ~= nil then
		self.mass = tonumber(statchanger.Mass.Text)
	end
	if tonumber(statchanger.Handling.Text) ~= nil then
		self.handling = tonumber(statchanger.Handling.Text)
	end
end

local function changeRotation(self, direction, amount)
	self.goalSteer = (self.handling * direction) * amount	
end

local function createObjects(self)
	self.rigidBody = Objects.Collider:Clone()
	self.kartModel = Objects.Model:Clone()
	self.cameraPart = Objects.Model:Clone()
	self.cameraPart.Name = "Camera"	
	
	self.rigidBody.Parent = game.Workspace
	self.kartModel.Parent = game.Workspace
	self.cameraPart.Parent = game.Workspace
	
	raycastParams.FilterDescendantsInstances = {self.rigidBody, self.kartModel, self.cameraPart}
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
end

local function findFloorNormal(self, dt)
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = {temp_boostPads, self.rigidBody}
	
	local kartCFrame: CFrame = self.kartModel.CFrame
	
	local gravity: VectorForce = self.rigidBody.Gravity
	local push: VectorForce = self.rigidBody.Push
	
	local raycastHit: RaycastResult = workspace:Raycast(
		self.rigidBody.Position, 
		-kartCFrame.UpVector * (self.rigidBody.Size.Magnitude/2), 
		raycastParams
	)

	if push.Force ~= push.Force then 
		return 
	end
	
	if raycastHit then
		local rotation = Util.getRotationBetween(kartCFrame.UpVector, raycastHit.Normal, Vector3.new(1,0,0))
		local goalCFrame = rotation * kartCFrame
		
		gravity.Force = Vector3.new(0, -198.2, 0)
		
		self.grounded = true
		self.kartModel.CFrame = kartCFrame:Lerp(goalCFrame, dt * 25)
	else
		self.grounded = false
		
		gravity.Force = Vector3.new(
			0,  
			-( --negative
				(self.mass * 198.2) + push.Force.Y -- prevents you from flying in the air
			), 
			0
		)
	end
end

local function stunKart(stunDuration)
	--[[
	if self.stun then
		task.cancel(self.stun)
	end

	self.stunned = true 

	self.stun = task.delay(stunDuration, function()

		print("yoo")
		self.stunned = false
	end)
	]]
end

local function checkCollision(self, filterType: Enum.RaycastFilterType, instances: {[number]: BasePart}, respectCanCollide: boolean): (RaycastResult, Vector3)
	local margin = .5
	local kartCFrame = self.kartModel.CFrame
	local bodyPosition, bodySize = kartCFrame.Position, self.rigidBody.Size

	local newRaycastParams = RaycastParams.new()
	
	newRaycastParams.FilterType = filterType
	newRaycastParams.FilterDescendantsInstances = instances
	newRaycastParams.RespectCanCollide = respectCanCollide
	
	local forwardRay = workspace:Raycast(bodyPosition, kartCFrame.LookVector * (bodySize.X/2 + margin), newRaycastParams)
	local backwardRay = workspace:Raycast(bodyPosition, -kartCFrame.LookVector * (bodySize.X/2 + margin), newRaycastParams)
	
	local leftRay = workspace:Raycast(bodyPosition, -kartCFrame.RightVector * (bodySize.Z/2 + margin), newRaycastParams)
	local rightRay = workspace:Raycast(bodyPosition, kartCFrame.RightVector * (bodySize.Z/2 + margin), newRaycastParams)
	
	if forwardRay then
		return forwardRay, kartCFrame.LookVector
	elseif backwardRay then
		return backwardRay, -kartCFrame.LookVector
	elseif leftRay then
		return leftRay, -kartCFrame.RightVector
	elseif rightRay then
		return rightRay, kartCFrame.RightVector
	end
end

function KartController:Collision(dT)
	--[[

		TODO:
		- create collision checking function
		- if bumping into wall, bump kart in the direction where both faces are negative against the normal
		- do same for player, base bump off mass

	]]
	
	local function boostPads()
		overlapParams.FilterType = Enum.RaycastFilterType.Include
		overlapParams.FilterDescendantsInstances = {temp_boostPads}
		overlapParams.MaxParts = 1
		
		local boundsHit = workspace:GetPartBoundsInBox(
			self.rigidBody.CFrame, 
			self.rigidBody.Size, 
			overlapParams
		)
		
		if boundsHit[1] then
			self:Boost(dT, 500)
		end
	end
	
	boostPads()
end

function KartController:Trick(dT)
	--[[
	
		TODO:
		- while midair, have option to do trick
		- if trick then boost speed slightly
	
		- change trick window later
	]]
	
	if self.grounded == false and self.trickDone == false then
		self.trickWindow += 1 * dT
		
		if self.trickWindow > 0.25 then
			return
		else
			InputController.canTrick = true
			
			if InputController.trickDone == true then
				InputController.canTrick = false
				InputController.trickDone = false
				self.trickDone = true
			end
		end
	else
		
		if self.trickDone then
			self:Boost(dT, 300)
		end
		
		self.trickWindow = 0
		self.trickDone = false
		InputController.canTrick = false
		InputController.trickDone = false
	end
end

function KartController:Stop(stunDuration)
	--[[
	
		TODO:
		- upon colliding with a offensive item, completely stop all velocity
		- play animation of jump in air + hurt animation
	]]	
end

function KartController:SpinOut()
	--[[
	
		TODO:
		- upon colliding with a debris item, stop all velocity quickly with a spin out animation
	
	]]
end

function KartController:Boost(dT, boostPower)	
	self.boosting = true
	
	if boostPower then
		local newMultiplier = math.min(boostPower/100, 3)

		if newMultiplier > self.speedMultiplier then 
			self.speedMultiplier = newMultiplier
		end
		
		self.boostDuration = math.min(boostPower + self.boostDuration, 300)
	else
		self.boostDuration = Util.smoothStep(self.boostDuration, 0, dT * 15)
	end 	
	
	if self.boostDuration <= 1 then
		self.boosting = false
		self.boostDuration = 0
		self.speedMultiplier = 1
	end
end

function KartController:Drift(dT)
	-- checks if the kart is able to drift, if so update drift variabels
	
	--[[
		TODO:
		- fix this spaghetti code holy elseif hell
	]]
	
	if (InputController.drifting 
		and InputController.steerDirection ~= 0 
		and self.drifting == false  
		and self.boosting == false 
		and self.grounded == true
		and self.currentSpeed > 10)
	then
		
		self.drifting = true
		self.driftDirection = InputController.steerDirection
		self.boostPower = 0
		
	elseif (InputController.drifting 
		and self.drifting == true 
		and self.boostPower < 300)
	then
		
		self.boostPower += self.speed * math.max(math.abs(InputController.steerDirection + self.driftDirection), .25) * dT
		
	elseif InputController.drifting == false then
		
		self.drifting = false
		self.driftDirection = 0
		
		if self.boostPower > 0 then
			self:Boost(dT, self.boostPower)
			self.boostPower = 0
		end
		
	end
end

function KartController:Steer(dT)
	-- controls the steer of the kart
	local torque: Torque = self.rigidBody.Torque
	local kartCFrame = self.kartModel.CFrame
		
	if self.drifting then
		if self.driftDirection > 0 then
			self.driftControl = math.max((self.driftDirection + InputController.steerDirection), .25)
		else
			self.driftControl =  math.max((math.abs(self.driftDirection) + -InputController.steerDirection), .25)
		end

		changeRotation(self, self.driftDirection, self.driftControl)
		torque.Torque = self.kartModel.CFrame.RightVector.Unit
	else
		local direction = InputController.steerDirection >= 0 and 1 or -1
		local amount = InputController.steerDirection

		changeRotation(self, direction, math.abs(amount))
		torque.Torque = Vector3.new(0, 0, 0)
	end
	
	
	self.currentSteer = Util.smoothStep(
		self.currentSteer, 
		self.goalSteer, 
		dT * self.handling
	)
	
	self.kartModel.CFrame = kartCFrame:Lerp(
		kartCFrame * CFrame.fromEulerAnglesXYZ(
			0, 
			math.rad(kartCFrame.Rotation.Y + self.currentSteer), 
			0
		), 
		
		math.clamp(dT * 5, 0, 1)
	)
end

function KartController:Move(dT)
	local push: VectorForce = self.rigidBody.Push
	local drag: VectorForce = self.rigidBody.Drag

	if self.stunned then
		self.goalSpeed = 0
		self.currentSpeed = Util.smoothStep(self.currentSpeed, self.goalSpeed, 1)
	else
		local accelerationDirection = InputController.accelerateDirection
		
		if self.drifting then
			accelerationDirection = math.max(accelerationDirection, .25)
		else
			accelerationDirection = math.max(accelerationDirection, -.25)
		end
		
		print(accelerationDirection)
		
		self.goalSpeed = self.speed * accelerationDirection * self.speedMultiplier
		

		
		self.currentSpeed = Util.smoothStep(
			self.currentSpeed, 
			self.goalSpeed, 
			math.min(dT * self.acceleration * self.speedMultiplier, 1)
		)
	end
	
	if push.Force ~= push.Force then
		return
	end

	push.Force = (
		self.kartModel.CFrame.LookVector 
		* (
			self.currentSpeed 
			* self.mass 
			* self.acceleration 
		) -- TODO: change this magic number to something more stable
	)
	--[[]]
	local bodyVelocity: Vector3 = self.rigidBody.AssemblyLinearVelocity	
	-- https://devforum.roblox.com/t/how-do-i-limit-the-velocity-of-vectorforce/1755788/20
	local dragForce: Vector3 = -bodyVelocity.Unit * (bodyVelocity.Magnitude ^ 2) * Vector3.new(1,1,1) * dT
	
	if dragForce ~= dragForce then -- NaN check
		return 
	end
	
	if bodyVelocity.Magnitude > (self.acceleration + self.drag) then
		if self.grounded then
			drag.Force = (
				(self.drag ^ 2) 
				* dragForce 
			)
		else
			dragForce = Vector3.new(
				dragForce.X, 
				dragForce.Y / self.mass, 
				dragForce.Z
			)
			
			drag.Force = (
				(self.drag ^ 2) 
				* dragForce 
			)
		end
	else
		drag.Force = Vector3.new(0, 0, 0)
		
		if self.grounded == false then else
			self.rigidBody.AssemblyLinearVelocity = bodyVelocity:Lerp(Vector3.new(), dT * self.acceleration) 
		end
	end
end

function KartController:Update(dT, fDT)
	if DEBUG then
		updateStatsToText(self)
	end
	
	if not self.rigidBody then
		return -- cleaner check, debugging
	end
	
	self.cameraPart.CFrame = CFrame.new(self.kartModel.Position) * self.cameraPart.CFrame.Rotation:Lerp(self.kartModel.CFrame.Rotation, (dT + fDT) * 4)
	
	--print(dT + fDT)
	
	findFloorNormal(self, dT)
	self:Move(dT)
	--self:Collision(dT)
	self:Drift(dT)
	self:Steer(dT)
	self:Boost(dT)
	self:Trick(dT)
	

	task.defer(function()
			--[[]
				TODO:
				
				- create multiplayer {
					actionState
					position and orientation
					steerDirection
				}
			]]
			
			--[[
				mini TODO:
				truncate vectors
			]]
		
		if self.updateTick > .25 then
			--[[
			local newCFrame: CFrame = kartInfo[1]
		local driftDirection: number = kartInfo[2]
		local currentSteer = kartInfo[3]
		local originalT = kartInfo[4]
		local velocity = kartInfo[5]]
		
			local kartInfo = {
				[1] = self.kartModel.CFrame,
				[2] = self.driftDirection,
				[3] = self.currentSteer,
				[4] = workspace:GetServerTimeNow(),
				[5] = self.rigidBody.AssemblyLinearVelocity,
			}
			
			KartUpdate:FireServer(kartInfo)
			self.updateTick = 0
		else
			self.updateTick += dT
		end
	end)
end

function KartController:Render(dT)
	self.kartModel.Position = self.rigidBody.Position
	
	task.defer(function()
		self.kartComponent:KartUpdate({
			self.cameraPart.CFrame,
			self.driftDirection,
			self.currentSteer,
		}, dT)
	end)
end


function KartController:Clean()
	self.kartComponent:Clean()
	self.rigidBody:Destroy()
	self.kartModel:Destroy()
	self = nil
end

function KartController.new(input)
	local newKartComponent = KartComponent.new(true) 
	
	local newKart = setmetatable({
		-- velocity
		currentSpeed = 0,
		currentSteer = 0,
		goalSpeed = 0,
		goalSteer = 0,
		multiplier = 0,
		trickWindow = 0,

		-- drifting
		steerDirection = 0,
		driftDirection = 0,
		driftControl = 0,

		-- boost
		boostPower = 0,
		speedMultiplier = 0,
		boostDuration = 0,

		-- booleans
		grounded = false,
		drifting = false,
		boosting = false,

		-- objects
		rigidBody = nil,
		kartModel = nil,
		cameraPart = nil,
		kartComponent = newKartComponent,
		updateTick = 0,
		stun = nil,
		
		-- kartAttributes
		
		acceleration = script:GetAttribute("Acceleration"),
		drag = script:GetAttribute("Drag"),
		handling = script:GetAttribute("Handling"),
		mass = script:GetAttribute("Mass"),
		speed = script:GetAttribute("Speed"),
		traction = script:GetAttribute("Traction"),
	}, KartController)
	
	InputController = input
	createObjects(newKart)
	
	return newKart
end

--[[


local currentSpeed, currentSteer, goalSpeed, goalSteer = 0, 0, 0, 0
local steerDirection, driftDirection = 0, 0
local boostPower, boostDuration = 0, 0
]]


return KartController