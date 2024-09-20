local Projectile = {}

--[[

	// THIS IS A ITEM TYPE:
	
	Any items updated under this module will be treated as a projectile
	Projectiles have 3 Modes -> Bounce, Follow, Default
	
	Default: A projectile that moves in the direction that it was shot in, breaks on first impact.
	Bounce: A projectile identical to Default, but bounces off walls instead of breaking. (Unless it hits a player)
	Follow: A projectile identical to Default, but the trajectory is based off the maps checkpoints until it can see its target.


	TODO:
	
	
]]

type ProjectileClass = {
	projectileType: string,
	currentPosition: Vector3,
	direction: Vector3,
	ignore: number
}

type ProjectileStats = {
	speed: number,
	bounces: number,
	radius: number,
}

function Projectile:CheckCollision()
	
end

function Projectile:Update()
	local projectileStats: ProjectileStats = self.projectileStats

end

function Projectile.new(projectileName: string, startingPosition: Vector3, direction: Vector3, playerID: number)
	local projectileInfo = {}
	
	return setmetatable({
		projectileStats = projectileInfo.Stats,
		projectileType = projectileInfo.Type,
		
		currentPosition = startingPosition,
		direction = direction,
		ignore = playerID,
	}, Projectile)
end

return Projectile