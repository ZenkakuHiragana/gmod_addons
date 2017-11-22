
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

SplatoonSWEPs = {
	RenderTarget = {},
	SortedSurfaces = {},
	Surfaces = {Area = 0, AreaBound = 0, LongestEdge = 0},
}
AddCSLuaFile "../splatoonsweps_const.lua"
include "../splatoonsweps_const.lua"
include "splatoonsweps_geometry.lua"
include "splatoonsweps_inkmanager.lua"
include "splatoonsweps_bsp.lua"

local rtpow = 13
local rtsize = 2^rtpow --8192
local rtarea = rtsize^2
local rtmergin = 2 / rtsize
local rtmerginSqr = rtmergin^2
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

function SplatoonSWEPs:CollisionAABB(mins1, maxs1, mins2, maxs2)
	return mins1.x < maxs2.x and maxs1.x > mins2.x and
			mins1.y < maxs2.y and maxs1.y > mins2.y and
			mins1.z < maxs2.z and maxs1.z > mins2.z
end

local function GetUV(convertunit)
	local u, v, nextV = 0, 0, 0
	local convSqr = convertunit^2
	for _, face in ipairs(SplatoonSWEPs.SortedSurfaces) do --Using next-fit approach
		if face.Vertices2D.Area / convSqr < rtmerginSqr then continue end
		local bound = face.Vertices2D.bound / convertunit
		nextV = math.max(nextV, bound.y)
		if 1 - u < bound.x then 
			u, v, nextV = 0, v + nextV + rtmergin, bound.y
		end
		
		face.MeshVertex = {}
		for i, vert in ipairs(face.Vertices2D) do
			local UV = vert / convertunit --Get UV coordinates
			table.insert(face.MeshVertex, {
				pos = face.Vertices[i],
				u = UV.x + u,
				v = UV.y + v,
			})
		end
		
		u = u + bound.x + rtmergin --Advance U-coordinate
	end
	
	return v + nextV
end

function SplatoonSWEPs:Initialize()
	local self = SplatoonSWEPs
	self.BSP:Init()
	self.BSP = nil
	
	--Ratio[(units^2 / pixel^2)^1/2 -> units/pixel]
	self.RenderTarget.Ratio = math.max(math.sqrt(self.Surfaces.AreaBound / rtarea), self.Surfaces.LongestEdge / rtsize)
	table.sort(self.SortedSurfaces, function(a, b) return a.Vertices2D.Area > b.Vertices2D.Area end)
	
	--convertunit[pixel * units/pixel -> units]
	local convertunit = rtsize * self.RenderTarget.Ratio
	local maxY = GetUV(convertunit)
	while maxY > 1 do
		convertunit = convertunit * ((maxY - 1) * 0.475 + 1.0005)
		maxY = GetUV(convertunit)
	end
end

hook.Add("InitPostEntity", "SetupSplatoonGeometry", SplatoonSWEPs.Initialize)
util.AddNetworkString("SplatoonSWEPs: Send an error message")
function SplatoonSWEPs:SendError(msg, icon, duration, user)
	net.Start("SplatoonSWEPs: Send an error message")
	net.WriteString(msg)
	net.WriteUInt(icon, SplatoonSWEPs.SEND_ERROR_NOTIFY_BITS)
	net.WriteUInt(duration, SplatoonSWEPs.SEND_ERROR_DURATION_BITS)
	if user then
		net.Send(user)
	else
		net.Broadcast()
	end
end
