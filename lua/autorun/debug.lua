
--Debugging code

DebugOverlayTime = 3
DebugOverlayColor = Color(0, 255, 0)
function DebugAxis(pos, ang, size, ignoreZ)
	debugoverlay.Axis(pos, ang, size, DebugOverlayTime, ignoreZ)
end
function DebugLine(start, endpos, ignoreZ)
	debugoverlay.Line(start, endpos, DebugOverlayTime, DebugOverlayColor, ignoreZ)
end
function DebugText(pos, text, ignoreZ)
	debugoverlay.Text(pos, text, DebugOverlayTime, not ignoreZ)
end
function DebugTriangle(p1, p2, p3, ignoreZ)
	debugoverlay.Triangle(p1, p2, p3, DebugOverlayTime, DebugOverlayColor, ignoreZ)
end
function DebugPlane(p, n, ignoreZ)
	DebugSphere(p, 5, true)
	DebugVector(p, n * 50, true)
end
function DebugPoint(pos, size, ignoreZ)
	debugoverlay.Cross(pos, size, DebugOverlayTime, DebugOverlayColor, ignoreZ)
end
function DebugScreenText(x, y, text)
	debugoverlay.ScreenText(x, y, text, DebugOverlayTime, DebugOverlayColor)
end
function DebugSphere(pos, rad, ignoreZ)
	debugoverlay.Sphere(pos, rad, DebugOverlayTime, DebugOverlayColor, ignoreZ)
end
function DebugVector(start, dir, ignoreZ)
	debugoverlay.Line(start, start + dir, DebugOverlayTime, DebugOverlayColor, ignoreZ)
end

local circle_polys = 8
local reference_polys = {}
local reference_vert = Vector(0, 1, 0)
local reference_vert45 = Vector(0, 1, 0)
for i = 1, circle_polys do
	table.insert(reference_polys, Vector(reference_vert))
	reference_vert:Rotate(Angle(0, 0, 360 / circle_polys))
end

function RequestInkOrder(self)
	local tr = self.Owner:GetEyeTrace()
	local pos, normal = tr.HitPos, tr.HitNormal
	SplatoonSWEPsInkManager.AddQueue(pos, normal, 100, Vector(255, 255, 255), reference_polys)
	DebugSphere(pos, 5, true)
	DebugVector(pos, normal * 50, true)
end
----------------------