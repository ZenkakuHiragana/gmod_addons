
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
	SplatoonSWEPs.BSP:Init()
	
	local mapsurfaces = {}
	local self = SplatoonSWEPs
	local faces = self.BSP:GetLump(self.LUMP.FACES)
	for _, f in ipairs(faces.data) do
		local texturename = f.TexInfoTable.texdata.name:lower()
		if texturename:find("tool") or texturename:find("water") then continue end
		if f.DispInfoTable then
			for i, t in ipairs(f.DispInfoTable.Triangles) do
				local existing
				for k, m in pairs(mapsurfaces) do
					if not isnumber(k) and m.normal:IsEqualTol(t.normal, 0.1) and
						math.abs(m.normal:Dot(t.Vertices[0] - m.origin)) < 1e-10 then	
						existing = m
						break
					end
				end
				
				if existing then
					local newverts = {}
					for k, v in ipairs(t.Vertices) do
						newverts[k] = SZL.Vector3DTo2D(WorldToLocal(v, angle_zero, existing.origin, existing.angle), nil)
					end
					existing.Polygon = existing.Polygon + SZL.Polygon(t.Polygon.tag, newverts)
					existing.mins, existing.maxs = self:GetBoundingBox(0, {existing.mins, existing.maxs, t.mins, t.maxs})
				else
					mapsurfaces[tostring(t.normal)] = {
						mins = t.mins,
						maxs = t.maxs,
						normal = t.normal,
						angle = t.angle,
						origin = t.Vertices[0],
						Vertices = t.Vertices,
						Polygon = t.Polygon,
					}
				end
			end
		elseif mapsurfaces[f.plane] then
			local m = mapsurfaces[f.plane]
			m.Polygon = m.Polygon + f.Polygon
			m.mins, m.maxs = self:GetBoundingBox(0, {m.mins, m.maxs, f.mins, f.maxs})
		else
			mapsurfaces[f.plane] = {
				mins = f.mins,
				maxs = f.maxs,
				normal = f.normal,
				angle = f.angle,
				origin = f.Vertices[0],
				Vertices = f.Vertices,
				Polygon = f.Polygon,
			}
		end
	end
	
	self.BSP = nil
	self.Surfaces = mapsurfaces
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
