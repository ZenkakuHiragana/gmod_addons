
local ss = SplatoonSWEPs
if not ss then return end

function EFFECT:Init(e)
	local info = e:GetStart() -- Vector(Radius, Inkangle, Ratio)
	ss.PaintQueue[CurTime()] = table.ForceInsert(ss.PaintQueue[CurTime()], {
		c = e:GetAttachment(),
		dispflag = e:GetScale() < 0 and 0 or 1,
		done = 0,
		inkangle = info.y,
		n = math.abs(e:GetScale()),
		pos = e:GetOrigin(),
		r = info.x,
		ratio = info.z,
		t = e:GetFlags(),
	})
end

function EFFECT:Render() end
function EFFECT:Think() end
