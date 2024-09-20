local InputController = {}
InputController.__index = InputController

local UserInputService = game:GetService("UserInputService")


local function mobileUpdate()

end

local function controllerUpdate()

end

function InputController:KeyboardUpdate(dt)

	if UserInputService:IsKeyDown(Enum.KeyCode.W) and UserInputService:IsKeyDown(Enum.KeyCode.S) == false then
		self.accelerateDirection = 1
	elseif UserInputService:IsKeyDown(Enum.KeyCode.S) and UserInputService:IsKeyDown(Enum.KeyCode.W) == false then
		self.accelerateDirection = -1
	else
		self.accelerateDirection = 0
	end


	if UserInputService:IsKeyDown(Enum.KeyCode.A) and UserInputService:IsKeyDown(Enum.KeyCode.D) == false then
		self.steerDirection = 1
	elseif UserInputService:IsKeyDown(Enum.KeyCode.D) and UserInputService:IsKeyDown(Enum.KeyCode.A) == false then
		self.steerDirection = -1
	else
		self.steerDirection = 0
	end

	if UserInputService:IsKeyDown(Enum.KeyCode.Space) == true then
		self.drifting = true
	else
		self.drifting = false
	end

	if UserInputService:IsKeyDown(Enum.KeyCode.F) == true then
		self.lookBehind = true
	else
		self.lookBehind = false
	end
	
	if UserInputService:IsKeyDown(Enum.KeyCode.G) == true then
		self.trickHoldTime += 1 * dt
	else
		self.trickHoldTime = 0
	end
	
	if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
		if self.canTrick == true then
			self.trickDone = true
		end
	end
end

function InputController:Update(dt)
	if UserInputService.KeyboardEnabled == true then
		self:KeyboardUpdate(dt)	
	elseif UserInputService.GamepadEnabled == true then
		--controllerUpdate(self)
	elseif UserInputService.GyroscopeEnabled == true then
		--mobileUpdate(self)
	else
		warn("Player has no input_object to read from (try reconnecting keyboard / controller or rejoining.)")
	end
end

function InputController.new()
	return setmetatable({}, InputController)
end

return InputController
