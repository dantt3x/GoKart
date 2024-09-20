local Util = {}

function Util.smoothStep(a, b, t)
	t = t * t * t * (t * (t * 6 - 15) + 10)
	return a + (b - a) * t
end

function Util.getRotationBetween(u, v, axis)
	--EgoMoose
	local dot, uxv = u:Dot(v), u:Cross(v)
	if (dot < -0.99999) then return CFrame.fromAxisAngle(axis, math.pi) end
	return CFrame.new(0, 0, 0, uxv.x, uxv.y, uxv.z, 1 + dot)
end

return Util
