
--SplatoonSWEPs structure
--The core of new ink system.

--Fix Angle:Normalize() in SLVBase
--The problem is functions between default Angle:Normalize() and SLVBase's have different behaviour:
--default one changes the given angle, SLV's returns normalized angle.
--So I need to branch the normalize function.  That's why I hate SLVBase.
local NormalizeAngle = FindMetaTable("Angle").Normalize
if SLVBase and not SLVBase.IsFixedNormalizeAngle then
	NormalizeAngle = function(ang) ang:Set(ang:Normalize()) return ang end
	SLVBase.IsFixedNormalizeAngle = true
end

require "SZL"
SplatoonSWEPs = SplatoonSWEPs or {}
AddCSLuaFile "../splatoonsweps_const.lua"
include "../splatoonsweps_const.lua"
include "splatoonsweps_geometry.lua"
include "splatoonsweps_inkmanager.lua"
include "splatoonsweps_bsp.lua"

function SplatoonSWEPs:Check(point)
	return self.Surfaces
	-- local x = point.x - point.x % chunkrate
	-- local y = point.y - point.y % chunkrate
	-- local z = point.z - point.z % chunkrate
	-- debugoverlay.Box(Vector(x, y, z), vector_origin,
	-- Vector(chunksize, chunksize, chunksize), 5, Color(0,255,0))
	-- return SplatoonSWEPs.GridSurf[x][y][z]
end

local function IsExternalSurface(verts, center, normal)
  	normal = normal * 0.5
  	return
  		bit.band(util.PointContents(center + normal), ALL_VISIBLE_CONTENTS) == 0 or
		bit.band(util.PointContents(verts[1] + (center - verts[1]) * 0.05 + normal), ALL_VISIBLE_CONTENTS) == 0 or
		bit.band(util.PointContents(verts[2] + (center - verts[2]) * 0.05 + normal), ALL_VISIBLE_CONTENTS) == 0 or
		bit.band(util.PointContents(verts[3] + (center - verts[3]) * 0.05 + normal), ALL_VISIBLE_CONTENTS) == 0
end

function SplatoonSWEPs:GetBoundingBox(minbound, vectors)
	local mins = Vector(math.huge, math.huge, math.huge)
	local maxs = -mins
	for _, v in ipairs(vectors) do
		mins.x = math.min(mins.x, v.x - minbound)
		mins.y = math.min(mins.y, v.y - minbound)
		mins.z = math.min(mins.z, v.z - minbound)
		maxs.x = math.max(maxs.x, v.x + minbound)
		maxs.y = math.max(maxs.y, v.y + minbound)
		maxs.z = math.max(maxs.z, v.z + minbound)
	end
	return mins, maxs
end

function SplatoonSWEPs:Initialize()
	SplatoonSWEPs.Surfaces = {}
	SplatoonSWEPs.BSP:Init()
	self.BSP = nil
end
hook.Add("InitPostEntity", "SetupSplatoonGeometry", SplatoonSWEPs.Initialize)

util.AddNetworkString("SplatoonSWEPs: Send error message from server")
function SplatoonSWEPs:SendError(msg, icon, duration, user)
	net.Start("SplatoonSWEPs: Send error message from server")
	net.WriteString(msg)
	net.WriteUInt(icon, SplatoonSWEPs.SEND_ERROR_NOTIFY_BITS)
	net.WriteUInt(duration, SplatoonSWEPs.SEND_ERROR_DURATION_BITS)
	if user then
		net.Send(user)
	else
		net.Broadcast()
	end
end
