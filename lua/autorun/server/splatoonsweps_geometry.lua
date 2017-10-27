
if not SplatoonSWEPs then return end

function SplatoonSWEPs.IsCCW(p1, p2, p3)
	return (p2 - p1):Cross(p3 - p2).x > 0
end
local IsCCW = SplatoonSWEPs.IsCCW

function SplatoonSWEPs.IsInTriangle(p1, p2, p3, p)
	return IsCCW(p1, p2, p) and IsCCW(p2, p3, p) and IsCCW(p3, p1, p)
end
local IsInTriangle = SplatoonSWEPs.IsInTriangle

function SplatoonSWEPs.GetPlaneProjection(pos, planeorigin, planenormal, direction)
	return pos + direction * planenormal:Dot(planeorigin - pos) / planenormal:Dot(direction)
end

--Returns the shared point, shared line and the angle between two planes.
function SplatoonSWEPs.GetSharedLine(n1, n2, p1, p2)
	local normal_dot = n1:Dot(n2)
	if normal_dot > math.cos(math.rad(10)) then return end
	local d1, d2 = p1:Dot(n1), p2:Dot(n2)
	return n1:Cross(n2):GetNormalized(), ((d1 - d2 * normal_dot) * n1 + (d2 - d1 * normal_dot) * n2) / (1 - normal_dot^2), math.acos(normal_dot)
end

--Rotates the given vector around specified normalized axis.
function SplatoonSWEPs.RotateAroundAxis(source, axis, rotation)
	local rotation = rotation / 2
	local sin, cos = math.sin(rotation), math.cos(rotation)
	local sinaxis = sin * axis
	local cossource_sourcesinaxis = cos * source + source:Cross(sinaxis)
	return source:Dot(sinaxis) * sinaxis + cos * cossource_sourcesinaxis + cossource_sourcesinaxis:Cross(sinaxis)
end
