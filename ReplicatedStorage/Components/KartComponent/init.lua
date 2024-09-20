local KartComponent = {}
KartComponent.__index = KartComponent

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Network = ReplicatedStorage.Network

local Effect = require(script.Effect)
local Sound = require(script.Sound)
local Animation = require(script.Animation)

local KartModels = ReplicatedStorage.Objects.Karts

local util = require(ReplicatedStorage.Helpers.Utility)
local spring = require(script.Spring)

local maximum_frames = 30

--[[

	KartComponent:KartUpdate(kartInfo) -> updates the kart position, orientation, and driver animation.
	KartComponent:KartEvent(kartInfo) -> fires when event happens (player did trick, player used item, etc.)
]]

local function updateWelds(self, currentSteer: number): ()
	local steer: Weld = self.kartModel.Root.Steer	
	
	steer.C1 = CFrame.fromEulerAnglesXYZ(0,0,math.rad(-currentSteer*2))
	
	local lean: Weld = self.kartModel.Root.Lean
	lean.C1 = CFrame.fromEulerAnglesXYZ(0,0,math.rad(currentSteer))
	
	local LWheel: Weld = self.kartModel.Root.LWheel
	local RWheel: Weld = self.kartModel.Root.RWheel
	
	LWheel.C1 = CFrame.new(Vector3.new(3, 2.5, -0.75)) * CFrame.fromEulerAnglesXYZ(math.rad(currentSteer/8),0,0)
	RWheel.C1 = CFrame.new(Vector3.new(-3, 2.5, -0.75)) * CFrame.fromEulerAnglesXYZ(math.rad(currentSteer/8),0,0)
end

local function updateDriftOrientation(self, kartCFrame: CFrame, currentSteer: number, dt): CFrame
	local kartModel: Model = self.kartModel

	self.kartModel:PivotTo(
		CFrame.new(kartCFrame.Position) * 
		self.kartModel.PrimaryPart.CFrame.Rotation:Lerp(
			kartCFrame.Rotation * CFrame.fromEulerAnglesXYZ(0, math.rad(currentSteer), 0), 
			math.min(dt*20, 1)
		)
	)
end

function KartComponent:KartUpdate(kartInfo, dt)
	-- do smth
	local previousTime = self.lastTime
	
	if self.isLocal then	
		local kartCFrame: CFrame = kartInfo[1]
		local driftDirection: number = kartInfo[2]
		local currentSteer: number = kartInfo[3]

		updateDriftOrientation(self, kartCFrame, currentSteer, dt)
		updateWelds(self, currentSteer)
	else
		
		local newCFrame: CFrame = kartInfo[1]
		local driftDirection: number = kartInfo[2]
		local currentSteer = kartInfo[3]
		local originalT = kartInfo[4]
		local velocity = kartInfo[5]
		
		--[[
		local position: Vector3 = kartInfo[1]
		local orientation: Vector3 = kartInfo[2]
		local animationState: {[number]: string | number} = kartInfo[3]
		local originalT = kartInfo[4]
		local velocity = kartInfo[5]
		]]
	
		table.sort(self.remotePosToUpdate, function(a, b)
			return a[4] > b[4]
		end)

		
		for i = #self.remotePosToUpdate, 1, -1 do
			if #self.remotePosToUpdate <= maximum_frames then
				break
			end
			
			table.remove(self.remotePosToUpdate, i)
		end
	
		local previousKartInfo = self.remotePosToUpdate[#self.remotePosToUpdate - 1]
		
		if #self.remotePosToUpdate > 1 and (previousKartInfo[1].Position - newCFrame.Position).Magnitude < 1 then else
			table.insert(self.remotePosToUpdate, 
				{
					newCFrame, 
					driftDirection,
					currentSteer,
					originalT, 
					
					workspace:GetServerTimeNow(), 
					self.kartModel.PrimaryPart.CFrame, 
					velocity
				}
			)
		end
	end
end

function KartComponent:KartEvent()
	-- do smth
end

function KartComponent:Update(dt)
	-- remote only
	if not self.remotePosToUpdate[1] then return end
	
	local kartModelCFrame = self.kartModel.PrimaryPart.CFrame
	local kartInformation = self.remotePosToUpdate[1]
	
	local targetCFrame: CFrame = kartInformation[1] or kartModelCFrame	
	local driftDirection: number = kartInformation[2]
	local currentSteer: number = kartInformation[3]
	local originalTime: number = kartInformation[4]
	local currentTime: number = kartInformation[5]
	local originalCFrame: CFrame = kartInformation[6]
	local velocity = kartInformation[7]

	
	local totalTime = (currentTime - originalTime)
	local distance = (targetCFrame.Position - originalCFrame.Position).Magnitude
	
	--self.kartModel.PrimaryPart.CFrame = kartModelCFrame:Lerp(targetCFrame + ((targetCFrame.Position - originalCFrame.Position) * totalTime), (dt * totalTime) * distance)

	updateDriftOrientation(self, targetCFrame, currentSteer, dt)
	updateWelds(self, currentSteer)
	
	self.kartModel.PrimaryPart.CFrame = kartModelCFrame:Lerp(targetCFrame + (velocity * totalTime), math.clamp(((dt * totalTime) * distance * 3), 0, 1))
	
	if (kartModelCFrame.Position - targetCFrame.Position).Magnitude < 1 then
		--print("REMOVING: "..#self.posToUpdate)
		table.remove(self.remotePosToUpdate, 1)
	end
end

function KartComponent:Clean()
	self.kartModel:Destroy()
	self = nil
end

function KartComponent.new(isLocalKart: boolean)	
	local newKartModel = KartModels.Default:Clone()
	newKartModel.Parent = game.Workspace	
	
	local test = setmetatable({	
		holdingItem = false,
		
		isLocal = isLocalKart,
		localPosToUpdate = nil,
		remotePosToUpdate = {},
		drift = 0,
		steer = 0,
		move = 0,
		
		driverName = "Default",
		kartName = "Default",
		
		kartModel = newKartModel,
		
		currentAnimation = {
			name = "Idle",
			frame = 0,
		},
	}, KartComponent)
	
	return test
end

return KartComponent
