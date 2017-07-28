--[[
	The main projectile entity of Splatoon SWEPS!!!
]]
AddCSLuaFile "shared.lua"
include "shared.lua"
util.AddNetworkString("SplatoonSWEPs: Receive vertices info")

local GridSize = 32
local GridHalf = GridSize / 2
local function SnapToGrid(vec)
	--Snap to grid
	local x, y, z = vec.x, vec.y, vec.z
	local mod = Vector(x % GridSize, y % GridSize, z % GridSize)
	if mod.x < GridHalf then
		x = x - mod.x
	else
		x = x + GridSize - mod.x
	end
	if mod.y < GridHalf then
		y = y - mod.y
	else
		y = y + GridSize - mod.y
	end
	if mod.z < GridHalf then
		z = z - mod.z
	else
		z = z + GridSize - mod.z
	end
	return Vector(x, y, z)
end

local inkdegrees = 45
local circle_polys = 16
local reference_polys = {}
local reference_vert = Vector(1, 0, 0)
local referense_vert45 = Vector(1, 0, 0)
for i = 1, circle_polys do
	referense_vert45:Rotate(Angle(0, 360 / circle_polys, 0))
	table.insert(reference_polys, {Vector(0, 0, 0), Vector(referense_vert45), Vector(reference_vert)})
	reference_vert:Rotate(Angle(0, 360 / circle_polys, 0))
end
--reference_polys = {
--	{Vector(0, 0, 0), Vector(1/2^0.5, 1/2^0.5, 0), Vector(1, 0, 0)},
--	{Vector(0, 0, 0), Vector(0, 1, 0), Vector(1/2^0.5, 1/2^0.5, 0)}}
for k, v in ipairs(reference_polys) do
	for i = 1, 3 do
		v[i] = Vector(0, v[i].x, v[i].y)
	end
end

local move_normal_distance = .1
local function SetupVertices(self, coldata)
	local tb = {} --Result vertices table
	local surf = {} --Surfaces that are affected by painting
	local pos, normal = coldata.HitPos, coldata.HitNormal --Just for convenience
	local ang = normal:Angle()
	ang:RotateAroundAxis(normal, -self.Owner:EyeAngles().yaw + 180)
	if SplatoonSWEPs then --This section doesn't search displacements; I must analyze BSP format.
		local targetsurf = SplatoonSWEPs.Check(pos)
		for i, s in pairs(targetsurf) do --This section searches all surfaces.  I have to cut some of them.
			if not istable(s) then continue end
			if not (s.normal and s.vertices) then continue end
			--Surfaces that have almost same normal as the given data.
			if s.normal:Dot(normal) > math.cos(math.rad(inkdegrees)) then
				for k = 1, 3 do
					--Surface.Z is near HitPos
					local v1 = s.vertices[k]
					local rel1 = v1 - pos
					local dot1 = s.normal:Dot(rel1)
					if dot1 > 0 and dot1 < self.InkRadius * math.sin(math.rad(inkdegrees)) then
						--Vertices is within InkRadius
						local v2 = s.vertices[i % 3 + 1]
						local rel2 = v2 - pos
						local line = v2 - v1 --now v1 and v2 are relative vector
						v1, v2 = rel1 - normal * dot1, rel2 - normal * normal:Dot(rel2)
						if line:GetNormalized():Cross(v1):Dot(normal) < self.InkRadius then
							if (v1:Dot(line) < 0 and v2:Dot(line) > 0) or
								math.min(v2:LengthSqr(), v1:LengthSqr()) < self.InkRadiusSqr then
								table.insert(surf, {
									s.vertices[1] - s.normal * move_normal_distance,
									s.vertices[2] - s.normal * move_normal_distance,
									s.vertices[3] - s.normal * move_normal_distance
								})
								break
							end
						end
					end --if dot1 > 0
				end --for k = 1, 3
			end --if s.normal:Dot
		end --for #SplatoonSWEPs.Surface
	end --if SplatoonSWEPs
	
	local verts = {} --Vertices for polygon that we attempt to draw
	local i1, i2, k1, k2 = vector_origin, vector_origin, vector_origin, vector_origin
	local v1, v2, intersection = vector_origin, vector_origin, vector_origin
	local cross1, cross2 = vector_origin, vector_origin
	local drawable_vertices = {vector_origin, vector_origin, vector_origin}
	local d_in_ref, ref_in_d = {true, true, true}, false
	for _, reference in ipairs(reference_polys) do
		for _, drawable in ipairs(surf) do
			tb = {}
			d_in_ref = {true, true, true}
			for i = 1, 3 do --Look into each line segments
				ref_in_d = true
				i1 = reference[i] * self.InkRadius
				i2 = reference[i % 3 + 1] * self.InkRadius
				drawable_vertices = {vector_origin, vector_origin, vector_origin}
				for k = 1, 3 do
					k1 = WorldToLocal(drawable[k], angle_zero, pos, ang)
					k2 = WorldToLocal(drawable[k % 3 + 1], angle_zero, pos, ang)
					k1, k2 = Vector(0, k1.y, k1.z), Vector(0, k2.y, k2.z)
					v1, v2 = i2 - i1, k2 - k1
					drawable_vertices[k] = k1
					--Check crossing each other
					cross1 = v2:Cross(v1).x
					cross1, cross2 = v2:Cross(k1 - i1).x / cross1, v1:Cross(k1 - i1).x / cross1
					if cross1 >= 0 and cross2 >= 0 and cross1 <= 1 and cross2 <= 1 then
						intersection = i1 + cross1 * v1
						table.insert(tb, {pos = intersection, z = intersection.z})
					end
					--is reference vertex in drawable triangle?
					if v2:Cross(i1 - k2).x < 0 then
						ref_in_d = false
					end
					--is drawable vertex in reference triangle?
					if v1:Cross(k1 - i2).x >= 0 then
						d_in_ref[k] = false
					end
				end
				if ref_in_d then
					table.insert(tb, {pos = i1, z = i1.z})
				end
			end
			for k, within in ipairs(d_in_ref) do
				if within then
					table.insert(tb, {pos = drawable_vertices[k], z = drawable_vertices[k].z})
				end
			end
			
			v1 = nil
			local base = Vector(0, 1, 0)
			for k, v in SortedPairsByMemberValue(tb, "z", true) do
				if not v1 then
					v1, tb[k].rad = v.pos, -math.huge
				else
					v2 = (v.pos - v1):GetNormalized()
					tb[k].rad = math.atan2(base:Cross(v2).x, base:Dot(v2))
				end
			end
			table.SortByMember(tb, "rad", true)
			tb.plane = {pos = drawable[1], normal = 
			(drawable[2] - drawable[1]):Cross(drawable[3] - drawable[2]):GetNormalized()}
			table.insert(verts, tb)
		end
	end
	
	--split polygons into triangles
	--get back to world coordinate
	local tris, tri_prev, tri_prev2, trivector, i = {}, {}, {}, vector_origin, 1
	local planepos, planenormal = vector_origin, vector_origin
	for __, poly in ipairs(verts) do
		if #poly == 0 then continue end
		planepos = poly.plane.pos
		planenormal = poly.plane.normal
		i = 1
		while i <= #poly do
			trivector = LocalToWorld(poly[i].pos, angle_zero, pos, ang)
			trivector = trivector - (planenormal:Dot(trivector - planepos) / planenormal:Dot(normal)) * normal
			tb = {pos = trivector,
				u = math.abs(poly[i].pos.y) / self.InkRadius,
				v = math.abs(poly[i].pos.z) / self.InkRadius}
			
			if i > 3 then
				i1 = i % 2 == 1 and 1 or 2
				tri_prev = tris[#tris]
				tri_prev2 = tris[#tris - i1]
				table.insert(tris, tri_prev)
				v1 = tri_prev2.pos - tri_prev.pos
				v2 = trivector - tri_prev.pos
				cross1 = v1:Cross(v2)
				if cross1:Dot(planenormal) >= 0 then
					table.insert(tris, tri_prev2)
					table.insert(tris, tb)
				else
					table.insert(tris, tb)
					table.insert(tris, tri_prev2)
				end
				i = i + 1
			else
				v1 = LocalToWorld(poly[i + 1].pos, angle_zero, pos, ang)
				v2 = LocalToWorld(poly[i + 2].pos, angle_zero, pos, ang)
				v1 = v1 - (planenormal:Dot(v1 - planepos) / planenormal:Dot(normal)) * normal
				v2 = v2 - (planenormal:Dot(v2 - planepos) / planenormal:Dot(normal)) * normal
				table.insert(tris, tb)
				
				cross1 = (v1 - trivector):Cross(v2 - trivector)
				if cross1:Dot(planenormal) >= 0 then
					table.insert(tris, {pos = v1,
						u = math.abs(poly[i + 1].pos.y) / self.InkRadius,
						v = math.abs(poly[i + 1].pos.z) / self.InkRadius})
					table.insert(tris, {pos = v2,
						u = math.abs(poly[i + 2].pos.y) / self.InkRadius,
						v = math.abs(poly[i + 2].pos.z) / self.InkRadius})
				else
					table.insert(tris, {pos = v2,
						u = math.abs(poly[i + 2].pos.y) / self.InkRadius,
						v = math.abs(poly[i + 2].pos.z) / self.InkRadius})
					table.insert(tris, {pos = v1,
						u = math.abs(poly[i + 1].pos.y) / self.InkRadius,
						v = math.abs(poly[i + 1].pos.z) / self.InkRadius})
				end
				i = i + 3
			end
		end
	end
	
--	print("triangles: " .. #tris / 3)
--	for i = 1, 2, 3 do
--		if i + 2 <= #tris then
--			debugoverlay.Line(tris[i].pos, tris[i + 1].pos, 4, Color(0,0,255),true)
--			debugoverlay.Line(tris[i + 1].pos, tris[i + 2].pos, 4, Color(0,0,255),true)
--			debugoverlay.Line(tris[i + 2].pos, tris[i].pos, 4, Color(0,0,255),true)
--		end
--	end
	return tris
end

local displacementOverlay = false
function ENT:Initialize()
--	SplatoonSWEPs.Initialize()
	if not util.IsValidModel(self.FlyingModel) then
		self:Remove()
		return
	end
	
	self:SharedInit()
	self:SetIsInk(false)
	self:SetInkColorProxy(self.InkColor or vector_origin)
	
	local ph = self:GetPhysicsObject()
	if not IsValid(ph) then return end
	ph:SetMaterial("watermelon") --or "flesh"
	
	self.InkRadius = math.random(60, 100)
	self.InkRadiusSqr = self.InkRadius^2
	
	if displacementOverlay then
		local index = 1
	--	for index = 1, 110 do
			local info = SplatoonSWEPs.DispInfo[index]
			local vert = SplatoonSWEPs.DispVertices[index]
			local prev, prev10 = vector_origin, vector_origin
			for k, v in pairs(vert) do
				if not prev:IsZero() then
					debugoverlay.Line(prev, v.pos, 10, Color(0,255,0), false)
				end
				if not prev10:IsZero() then
					debugoverlay.Line(prev10, v.pos, 10, Color(0,255,0), false)
				end
				prev = v.pos
				if k > 2^v.power and vert[k - (2^v.power)] then
					prev10 = vert[k - (2^v.power)].pos
				end
			end
			
			local st = SplatoonSWEPs.DispInfo[index].startPosition
			debugoverlay.Line(st, st + vector_up * 50, 10, Color(255,255,255), true)
			debugoverlay.Line(info.vertices[1], info.vertices[1] + vector_up * 50, 10, Color(255,0,0), true)
			debugoverlay.Line(info.vertices[2], info.vertices[2] + vector_up * 50, 10, Color(0,255,0), true)
			debugoverlay.Line(info.vertices[3], info.vertices[3] + vector_up * 50, 10, Color(0,0,255), true)
			debugoverlay.Line(info.vertices[4], info.vertices[4] + vector_up * 50, 10, Color(255,255,0), true)
	--	end
	end
end

function ENT:PhysicsCollide(coldata, collider)
	if util.QuickTrace(coldata.HitPos, coldata.HitNormal, self).HitSky then
		SafeRemoveEntityDelayed(self, 0)
		return
	end
	local snapped = SnapToGrid(coldata.HitPos) - coldata.HitNormal
	
	self:SetIsInk(true)
	self:SetHitPos(coldata.HitPos)
	self:SetHitNormal(coldata.HitNormal)
	self:SetAngles(coldata.HitNormal:Angle())
	self:DrawShadow(false)
	
	timer.Simple(0, function()
		if not IsValid(self) then return end
		self:SetMoveType(MOVETYPE_NONE)
		self:PhysicsInit(SOLID_NONE)
		self:SetPos(coldata.HitPos)
	end)
	
	net.Start("SplatoonSWEPs: Receive vertices info")
	net.WriteEntity(self)
	net.WriteTable(SetupVertices(self, coldata))
	net.Broadcast()
end

function ENT:Think()
	if Entity(1):KeyDown(IN_ATTACK2) then
		self:Remove()
	end
end
