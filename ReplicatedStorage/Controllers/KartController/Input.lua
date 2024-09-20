local Input = {}

local UserInputService = game:GetService("UserInputService")

local steerDirection = 0
local accelerateDirection = 0
local drifting = false

local function mobileUpdate()
	
end

local function controllerUpdate()
	
end

local function keyboardUpdate()
	
	if UserInputService:IsKeyDown(Enum.KeyCode.W) and UserInputService:IsKeyDown(Enum.KeyCode.S) == false then
		accelerateDirection = 1
	elseif UserInputService:IsKeyDown(Enum.KeyCode.S) and UserInputService:IsKeyDown(Enum.KeyCode.W) == false then
		accelerateDirection = -1
	else
		accelerateDirection = 0
	end
	
	
	if UserInputService:IsKeyDown(Enum.KeyCode.A) and UserInputService:IsKeyDown(Enum.KeyCode.D) == false then
		steerDirection = 1
	elseif UserInputService:IsKeyDown(Enum.KeyCode.D) and UserInputService:IsKeyDown(Enum.KeyCode.A) == false then
		steerDirection = -1
	else
		steerDirection = 0
	end
	
	
	if UserInputService:IsKeyDown(Enum.KeyCode.Space) == true then
		drifting = true
	else
		drifting = false
	end
end

function Input.isDrifting()
	return drifting
end

function Input.getAccelerate()
	return accelerateDirection
end

function Input.getSteer()
	return steerDirection
end

function Input.Update()
	if UserInputService.KeyboardEnabled == true then
		keyboardUpdate()		
	elseif UserInputService.GamepadEnabled == true then
		controllerUpdate()
	elseif UserInputService.GyroscopeEnabled == true then
		mobileUpdate()
	else
		warn("Player has no input_object to read from (try reconnecting keyboard / controller or rejoining.)")
	end
end

return Input
