
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

SplatoonSWEPs = SplatoonSWEPs or {}
AddCSLuaFile "../splatoonsweps_const.lua"
include "../splatoonsweps_const.lua"
include "splatoonsweps_geometry.lua"
include "splatoonsweps_inkmanager.lua"
include "splatoonsweps_bsp.lua"

local rtpow = 13
local rtsize = 2^rtpow --8192
SplatoonSWEPs.RenderTarget = {
	Side = rtsize,
	Area = rtsize^2,
	Efficiency = 0.5,
}

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

function SplatoonSWEPs:Initialize()
	local self = SplatoonSWEPs
	self.Surfaces = {Area = 0}
	self.BSP:Init()
	print("NumFacesBSP: ", self.BSP:GetLump(self.LUMP.FACES).num)
	print("NumPlanesBSP: ", self.BSP:GetLump(self.LUMP.PLANES).num)
	print("NumSurfaces: ", table.Count(self.Surfaces))
	print("SurfaceArea: ", self.SurfaceArea)
	
	--1unit -> pixels
	self.RenderTarget.Ratio = math.sqrt((self.RenderTarget.Area * self.RenderTarget.Efficiency) / self.Surfaces.Area)
	
	local convertunit = self.RenderTarget.Ratio / self.RenderTarget.Side
	local UVcursor = vector_origin
	local nextV = 0
	for _, face_array in pairs(self.Surfaces) do
		for _, f in ipairs(face_array) do
			f.MeshVertex = {}
			f.MeshTriangle = {}
			local longestsegment, longestdistance = nil, 0
			for i, v in ipairs(f.Vertices2D) do
				local d = v:DistToSqr(f.Vertices2D[i % #f.Vertices2D + 1])
				if d > longestdistance then
					d = longestdistance
					longestsegment = i
				end
			end
			longestsegment = f.Vertices2D[longestsegment % #f.Vertices2D + 1] - f.Vertices2D[longestsegment]
			
			local rotated = {}
			local angle = Angle(0, -math.deg(math.atan2(longestsegment.y, longestsegment.x)), 0)
			local mins = Vector(math.huge, math.huge, 0)
			local maxs = -mins
			for i, v in ipairs(f.Vertices2D) do
				local vr = Vector(v)
				vr:Rotate(angle)
				table.insert(rotated, vr)
				mins.x = math.min(mins.x, vr.x)
				mins.y = math.min(mins.y, vr.y)
				maxs.x = math.max(maxs.x, vr.x)
				maxs.y = math.max(maxs.y, vr.y)
			end
			
			for i, v in ipairs(rotated) do --UV coordinates
				local UV = (v - mins) * convertunit + UVcursor
				f.MeshVertex[i] = {
					pos = f.Vertices[i],
					u = UV.x,
					v = UV.y,
				}
			end
			maxs, mins = maxs - mins, vector_origin
			
		end
	end
	
	self.BSP = nil
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
