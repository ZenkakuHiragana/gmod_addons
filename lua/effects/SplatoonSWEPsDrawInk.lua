
local ss = SplatoonSWEPs
if not ss then return end

local surf = ss.SequentialSurfaces
function EFFECT:Init(e)
	self:Remove()
	local i = math.abs(e:GetScale())
	local info = e:GetStart() -- Vector(Radius, Inkangle, Ratio)
	local pos = e:GetOrigin()
	ss.PaintQueue[CurTime()] = table.ForceInsert(ss.PaintQueue[CurTime()], {
		c = e:GetAttachment(),
		dispflag = e:GetScale() < 0 and 0 or 1,
		done = 0,
		inkangle = info.y,
		n = i,
		owner = e:GetEntity(),
		pos = pos,
		r = info.x,
		ratio = info.z,
		t = e:GetFlags(),
	})
end
