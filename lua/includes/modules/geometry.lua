assert(SZL, "SZL is required.")
if getfenv() ~= SZL then setfenv(1, SZL) end

--Some geometric classes
--Vector(GLua compatibility)
--Vector2D
--Segment(pair of Vector2D)

SZL.Geometry = true
if not GAMEMODE then
local VMeta = {
	__add = function(op1, op2) return Vector(op1.x + op2.x, op1.y + op2.y, op1.z + op2.z) end,
	__sub = function(op1, op2) return Vector(op1.x - op2.x, op1.y - op2.y, op1.z - op2.z) end,
	__mul = function(op1, op2)
		if isnumber(op2) then
			return Vector(op1.x * op2, op1.y * op2, op1.z * op2)
		else
			return Vector(op1 * op2.x, op1 * op2.y, op1 * op2.z)
		end
	end,
	__div = function(op1, op2) return Vector(op1.x / op2, op1.y / op2, op1.z / op2) end,
	__unm = function(op) return Vector(-op.x, -op.y, -op.z) end,
	__tostring = function(op) return tostring(op.x) .. " " .. tostring(op.y) .. " " .. tostring(op.z) end,
}
function Vector(_x, _y, _z) makeclass()
	x, y, z = 0, 0, 0
	if istable(_x) then
		x, y, z = _x.x, _x.y, _x.z
	else
		x, y, z = _x or 0, _y or 0, _z or 0
	end
	
	function Distance(_, op) return (self - op).Length() end
	function DistToSqr(_, op) return (self - op).LengthSqr() end
	function LengthSqr() return x * x + y * y + z * z end
	function Length() return math.sqrt(LengthSqr()) end
	function Dot(_, op) return x * op.x + y * op.y + z * op.z end
	function Cross(_, op) return Vector(y * op.z - z * op.y, z * op.x - x * op.z, x * op.y - y * op.x) end
	function Normalize() local l = Length() x, y, z = x / l, y / l, z / l end
	function GetNormalized() local l = Length() return Vector(x / l, y / l, z / l) end
return (endclass(VMeta)) end
end

--local MAX_FRAC, MIN_FRAC, FIX_FRAC = 1007/1024, 441/1024, 5/128
--local function Length()
--	local ax, ay = math.abs(x), math.abs(y)
--	local max, min = math.max(ax, ay), math.min(ax, ay)
--	local approx = MAX_FRAC * max + MIN_FRAC * min
--	if max < 16 * min then
--		return approx - FIX_FRAC * max
--	else
--		return approx
--	end
--end

--local function Length()
--	local a, b = math.abs(x), math.abs(y)
--	if a < b then a, b = b, a end
--	if b > 0 then
--		local b_a, s = b/a
--		s = b_a * b_a
--		s = s / (4 + s)
--		a = a + 2 * a * s
--		b = b * s
--		b_a = b/a
--		s = b_a * b_a
--		s = s / (4 + s)
--		a = a + 2 * a * s
--		b = b * s
--		b_a = b/a
--		s = b_a * b_a
--		s = s / (4 + s)
--		a = a + 2 * a * s
--	end
--	return a
--end

SZL.epsilon = 1e-10
local V2DMeta = {
	__add = function(op1, op2) return Vector2D(op1.x + op2.x, op1.y + op2.y) end,
	__sub = function(op1, op2) return Vector2D(op1.x - op2.x, op1.y - op2.y) end,
	__mul = function(op1, op2)
		if isnumber(op2) then
			return Vector2D(op1.x * op2, op1.y * op2)
		else
			return Vector2D(op1 * op2.x, op1 * op2.y)
		end
	end,
	__div = function(op1, op2) return Vector2D(op1.x / op2, op1.y / op2) end,
	__unm = function(op) return Vector2D(-op.x, -op.y) end,
	__len = function(op) return op.Length() end,
	__eq = function(op1, op2) return op1.eqx(op2) and op1.eqy(op2) end,
	__tostring = function(op)
		return string.format("(%5.2f, %5.2f)", op.x, op.y)
	end,
}

function Vector2D(_x, _y) makeclass()
	x, y = _x, _y
	if not _x then
		x, y = 0, 0
	elseif not _y then
		x, y = x.x, x.y
	end
	
	function Hash() return string.format("%a %a", x, y) end
	function Distance(op) return (self - op).Length() end
	function DistToSqr(op) return (self - op).LengthSqr() end
	function LengthSqr() return x * x + y * y end
	function Length() return math.sqrt(LengthSqr()) end
	function Dot(op) return x * op.x + y * op.y end
	function Cross(op) return x * op.y - y * op.x end
	function Rotate(source, deg)
		local rad = math.rad(deg)
		local cos, sin = math.cos(rad), math.sin(rad)
		source.x, source.y
		= source.x * cos + source.y * sin,
		  source.x * -sin + source.y * cos
	end
	function Normalize() local l = Length() x, y = x / l, y / l end
	function GetNormalized() local l = Length() return Vector2D(x / l, y / l) end
	function eqx(op) return math.abs(x - op.x) < epsilon end
	function eqy(op) return math.abs(y - op.y) < epsilon end
return (endclass(V2DMeta)) end

function Vector3DTo2D(_3d, component)
	if not component then component = {"y", "z"} end
	return Vector2D(_3d[component[1]], _3d[component[2]])
end

function Vector2DTo3D(_2d, component)
	if not component then component = {"", "x", "y"} end
	return Vector(_2d[component[1]], _2d[component[2]], _2d[component[3]])
end

local SegAttrMeta = {}
function SegAttrMeta.__tostring(op)
	local s = tostring(op[1]) .. ", "
	for k in pairs(op) do
		if k ~= 1 then
			s = s .. tostring(k) .. ", "
		end
	end
	return "{" .. string.sub(s, 1, -3) .. "}"
end

local SegMeta = {
	__unm = function(op) return Segment(op.endpos(), op.start(), op.left, op.right, op.getattr(true), op.other) end,
	__eq = function(op1, op2)
		return op1.start() == op2.start()
		and op1.endpos == op2.endpos()
		and op1.left == op2.left
		and op1.right == op2.right
		and op1.other.left == op2.other.left
		and op1.other.right == op2.other.right
		and op1.getattr(true) == op2.getattr(true)
	end,
	__tostring = function(op)
		return tostring(op.start())
		.. "->" .. tostring(op.endpos())
		.. "\t" .. tostring(op.left)
		.. "/" .. tostring(op.right)
		.. "\t" .. tostring(op.other.left)
		.. "/" .. tostring(op.other.right)
		.. "\t(" .. tostring(op.getattr(true)) .. ")"
	end,
}

function Segment(begins, ends, _left, _right, _attr, _other) makeclass()
	other, left, right = _other and {left = _other.left, right = _other.right} or {}, _left, _right
	if _left ~= nil and _right == nil and _attr == nil then _attr, left = _left end
	if not ends then
		left, right, _attr = begins.left, begins.right, begins.getattr(true)
		begins, ends = Vector2D(begins.start()), Vector2D(begins.endpos())
	end
	begins, ends, _attr = begins or Vector2D(), ends or Vector2D(), _attr or true
	function getattr(filled) return filled and _attr or false end
	function start() return begins end
	function endpos() return ends end
	function setstart(v) begins = v end
	function setend(v) ends = v end
	function cross(v) return (v - begins).Cross(ends - begins) end
	function isleft(v) return cross(v) < -epsilon end
	function isright(v) return cross(v) > epsilon end
	function online(v) return math.abs(cross(v)) < epsilon end
	function equalpos(op) return begins == op.start() and ends == op.endpos() end
	function negatepos()
		begins, ends, left, right, other.left, other.right
		= ends, begins, right, left, other.right, other.left
	end
	function getdirection(isnorm)
		if isnorm then
			local dir = ends - begins
			local len = dir.Length()
			return dir / len, len
		else
			return ends - begins
		end
	end
	
	function intersect(other)
		local v1, v2 = getdirection(), other.getdirection()
		local dstart = other.start() - begins
		local cdivisor = v2.Cross(v1)
		if math.abs(cdivisor) > epsilon then
			local c1 = v2.Cross(dstart) / cdivisor
			local c2 = v1.Cross(dstart) / cdivisor
			if c1 >= 0 and c1 <= 1 and c2 >= 0 and c2 <= 1 then
				return begins + c1 * v1
			end
		elseif online(other.start()) then --segments are collinear
			local l = v1.LengthSqr()
			local fr1 = v1.Dot(other.start() - begins)
			local fr2 = v1.Dot(other.endpos() - begins)
			fr1, fr2 = fr1 / l, fr2 / l
			if fr1 > fr2 then
				fr1, fr2 = fr2, fr1
				other = -other
			end
			
			if 0 < fr1 and fr1 < 1 then
				return other.start(), fr2 < 1 and other.endpos() or ends
			elseif 0 < fr2 and fr2 < 1 then
				return other.endpos(), begins
			elseif fr1 <= 0 and fr2 >= 1 then
				return begins, fr1 < 0 and begins or ends
			end
		end
	end
return (endclass(SegMeta)) end
