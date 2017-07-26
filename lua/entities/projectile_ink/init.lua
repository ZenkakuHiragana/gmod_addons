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

--[[SplatoonSWEPs = {
	Point = {Vector(), Vector(), ...},
	Grid = {?},
	Surface = {
		{vertices = {v1, v2, v3}, normal = Vector(), center = Vector()},
		...
	}
}
]]
local inkdegrees = 45
local function SetupVertices(self, coldata)
	local tb = {} --Result vertices table
	local surf = {} --Surfaces that are affected by painting
	local pos, normal = coldata.HitPos, coldata.HitNormal --Just for convenience
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
					local dot1 = normal:Dot(rel1)
					if dot1 > 0 and dot1 < self.InkRadius * math.cos(math.rad(inkdegrees)) then
						--Vertices is within InkRadius
						local v2 = s.vertices[math.floor(k + 1 + 0.4 * k) % 4] --1 -> 1.4, 2 -> 3.8, 3 -> 5.4
						local rel2 = v2 - pos
						local line = v2 - v1 --now v1 and v2 are relative vector
						v1, v2 = rel1 - normal * dot1, rel2 - normal * normal:Dot(rel2)
						if line:Cross(v1):LengthSqr() / line:LengthSqr() < self.InkRadiusSqr then
							if (v1:Dot(line) < 0 and v2:Dot(line) > 0) or
								math.min(v2:LengthSqr(), v1:LengthSqr()) < self.InkRadiusSqr then
								table.insert(surf, {
									s.vertices[1] - s.normal,
									s.vertices[2] - s.normal,
									s.vertices[3] - s.normal})
								break
							end
						end
					end --if dot1 > 0
				end --for k = 1, 3
			end --if s.normal:Dot
		end --for #SplatoonSWEPs.Surface
	end --if SplatoonSWEPs
	
	local isempty = true
	for k, v in ipairs(surf) do
	--	debugoverlay.Line(v[1] + vector_up, v[2] + vector_up, 10, Color(0, 255, 0), true)
	--	debugoverlay.Line(v[2] + vector_up, v[3] + vector_up, 10, Color(0, 255, 0), true)
	--	debugoverlay.Line(v[3] + vector_up, v[1] + vector_up, 10, Color(0, 255, 0), true)
		table.insert(tb, {pos = v[1] - normal * .1, u = math.random(), v = math.random()})
		table.insert(tb, {pos = v[2] - normal * .1, u = math.random(), v = math.random()})
		table.insert(tb, {pos = v[3] - normal * .1, u = math.random(), v = math.random()})
		isempty = false
	end
	
	if isempty then
		local v1, v2, v3, v4 = Vector(-50, -50, 0), Vector(50, -50, 0), Vector(-50, 50, 0), Vector(50, 50, 0)
		local ang = normal:Angle() ang.p = ang.p - 90 ang:Normalize()
		v1:Rotate(ang)
		v2:Rotate(ang)
		v3:Rotate(ang)
		v4:Rotate(ang)
		tb = {
			{pos = pos + v1, u = 0, v = 0},
			{pos = pos + v4, u = 1, v = 1},
			{pos = pos + v2, u = 1, v = 0},
			{pos = pos + v1, u = 0, v = 0},
			{pos = pos + v3, u = 0, v = 1},
			{pos = pos + v4, u = 1, v = 1},
		}
	end
	
	table.insert(tb, {pos = SplatoonSWEPs.DispVertices[1][1].pos + vector_up, u = 0, v = 0})
	table.insert(tb, {pos = SplatoonSWEPs.DispVertices[1][10].pos + vector_up, u = 1, v = 0})
	table.insert(tb, {pos = SplatoonSWEPs.DispVertices[1][2].pos + vector_up, u = 1, v = 1})
	
	return tb
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
	
	self.InkRadius = 500
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
	if coldata.HitSky then self:Remove() return end
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

function ENT:OnRemove()
	if IsValid(self.proj) then self.proj:Remove() end
end

function ENT:Think()
	if Entity(1):KeyDown(IN_ATTACK2) then
		self:Remove()
	end
end

-- Spawning env_sprite_oriented
-- local ang = coldata.HitNormal:Angle()
-- ang:Normalize()
-- local p = ents.Create("env_sprite_oriented")
-- p:SetPos(coldata.HitPos)
-- p:SetAngles(ang)
-- p:SetParent(self)
-- local color = self:GetCurrentInkColor()
-- color = Color(color.x, color.y, color.z)
-- p:SetColor(color)
-- p:SetLocalPos(vector_origin)
-- p:SetLocalAngles(angle_zero)

-- local c, b = self:GetCurrentInkColor(), 8
-- p:Input("rendercolor", Format("%i %i %i 255", c.r * b, c.g * b, c.b * b ))
-- ang.p = -ang.p
-- p:SetKeyValue("angles", tostring(ang))
-- p:SetKeyValue("rendermode", "1")
-- p:SetKeyValue("model", "sprites/splatoonink.vmt")
-- p:SetKeyValue("spawnflags", "1")
-- p:SetKeyValue("scale", "0.125")

-- p:Spawn()
