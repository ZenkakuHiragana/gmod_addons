
local ss = SplatoonSWEPs
if not ss then return end

local rootpi = math.sqrt(math.pi) / 2
local surf = ss.SequentialSurfaces
function EFFECT:Init(e)
	local i = math.abs(e:GetScale())
	local info = e:GetStart() -- Vector(Radius, Inkangle, Ratio)
	local pos = e:GetOrigin()
	local sizevec = Vector(info.x, info.x) * rootpi
	ss.PaintQueue[CurTime()] = table.ForceInsert(ss.PaintQueue[CurTime()], {
		c = e:GetAttachment(),
		dispflag = e:GetScale() < 0 and 0 or 1,
		done = 0,
		inkangle = info.y,
		n = i,
		pos = pos,
		r = info.x,
		ratio = info.z,
		t = e:GetFlags(),
	})
	
	if e:GetEntity() == LocalPlayer() then return end
	local pos2d = ss.To2D(pos, surf.Origins[i], surf.Angles[i])
	local bmins, bmaxs = pos2d - sizevec, pos2d + sizevec
	ss.AddInkRectangle(surf.InkCircles[i], CurTime(), {
		angle = info.y,
		bounds = {bmins.x, bmins.y, bmaxs.x, bmaxs.y},
		color = e:GetAttachment(),
		pos = pos2d,
		radius = info.x,
		ratio = info.z,
		texid = e:GetFlags(),
	})
end

function EFFECT:Render() end
function EFFECT:Think() end
