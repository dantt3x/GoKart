local Camera = {}
Camera.__index = Camera


local TweenService = game:GetService("TweenService")
local currentCamera = game.Workspace.CurrentCamera
currentCamera.CameraType = Enum.CameraType.Scriptable

local InputController = nil

local DEBUG = false
local offset = Vector3.new(5,5,0)

local cameraPart = Instance.new("Part")
cameraPart.Name = "cam"
cameraPart.Anchored = true
cameraPart.Transparency = 1
cameraPart.CanCollide = false
cameraPart.Parent = game.Workspace.CurrentCamera

local function tween()
	if self.kart.drifting == true then

		TweenService:Create(
			currentCamera,
			TweenInfo.new(.25, Enum.EasingStyle.Cubic),
			{["FieldOfView"] = 75}
		):Play()

	else
		if currentCamera.FieldOfView ~= 70 then
			TweenService:Create(
				currentCamera,
				TweenInfo.new(.25, Enum.EasingStyle.Cubic),
				{["FieldOfView"] = 70 + (self.kart.currentSpeed * 10 / self.kart.speed)}
			):Play()
		end
	end
end


function Camera:Update(dt)	
	currentCamera.CameraType = Enum.CameraType.Scriptable
	currentCamera.CameraSubject = self.kart.cameraPart
	
	local rotMod, posMod = 1, 1
		
	if InputController.lookBehind then
		currentCamera.CameraType = Enum.CameraType.Custom
		currentCamera.CameraSubject = nil
	else
		local kartCFrame: CFrame = self.kart.cameraPart.CFrame
		
		--local predictedPosition = kartCFrame.Position + ((kartCFrame.Position - oldPos) * (dt + (dt - (self.lastDT or 0))))
		
		
		--local predictedPosition = (self.kart.rigidBody.AssemblyLinearVelocity + self.kart.rigidBody.Position) * .5
		
		--[[
		spring.target(currentCamera, 3, 15 , {CFrame = CFrame.new(predictedPosition) * CFrame.new(
			Vector3.new(
				script:GetAttribute("x"), 
				script:GetAttribute("y"),
				script:GetAttribute("z") * posMod
			))
			})
		]]
		
		currentCamera.CFrame = kartCFrame * CFrame.new(
			Vector3.new(
				script:GetAttribute("x"), 
				script:GetAttribute("y"),
				script:GetAttribute("z") * posMod
			)
		) * CFrame.fromEulerAnglesXYZ(
			math.rad(script:GetAttribute("rx") * rotMod),
			math.rad(script:GetAttribute("ry")),
			math.rad(rotMod)
		)
		
	end
end

function Camera.new(kart, input)
	InputController = input
	return setmetatable({
		
		kart = kart
		
	}, Camera)
end

return Camera