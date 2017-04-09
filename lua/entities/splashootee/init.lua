--[[
	Splashootee is a Splashooter's projectile.
	This prints orange ink if it hit a wall.
]]

AddCSLuaFile("shared.lua")
include('shared.lua')

local HitSound = {}
for i = 0, 20 do
	if i < 10 then
		table.insert(HitSound, i, Sound("SplatoonSWEPs/misc/inkHit/inkHit0" .. i .. ".wav"))
	else
		table.insert(HitSound, i, Sound("SplatoonSWEPs/misc/inkHit/inkHit" .. i .. ".wav"))
	end
end

local Slime = {}
for i = 0, 4 do
	table.insert(Slime, i, Sound("SplatoonSWEPs/misc/slime/slime0" .. i .. ".wav"))
end

local DmgSound = Sound("SplatoonSWEPs/misc/DamageInkLook00.wav")
local mat = Material("models/props_c17/metalladder001")
local big, medium, small, micro = 19, 10, 5, 3

local function draw(deleteflag)	
	if deleteflag then
		local amount = 255
		if timer.Exists("spray") then 
			RunConsoleCommand("r_cleardecals")
			SplatoonSurfaces.times = 0
			timer.Adjust("spray", 0.04, math.floor(#SplatoonSurfaces / amount) + 1, function()
				for i = amount * SplatoonSurfaces.times, amount * (SplatoonSurfaces.times + 1) do
					local k = i + 1
					if k > #SplatoonSurfaces then k = #SplatoonSurfaces end
					local v = SplatoonSurfaces[k]
					if not isnumber(v) and v then
						util.Decal("Ink" .. v.ColorName, v.Pos - v.Normal, v.Pos + v.Normal)
						if i > #SplatoonSurfaces then break end
					end
				end
				SplatoonSurfaces.times = SplatoonSurfaces.times + 1
			end)
		else
			RunConsoleCommand("r_cleardecals")
			SplatoonSurfaces.times = 0
			timer.Create("spray", 0.04, math.floor(#SplatoonSurfaces / amount) + 1, function()
				for i = amount * SplatoonSurfaces.times, amount * (SplatoonSurfaces.times + 1) do
					local k = i + 1
					if k > #SplatoonSurfaces then k = #SplatoonSurfaces end
					local v = SplatoonSurfaces[k]
					if not isnumber(v) and v then
						util.Decal("Ink" .. v.ColorName, v.Pos - v.Normal, v.Pos + v.Normal)
						if i > #SplatoonSurfaces then break end
					end
				end
				SplatoonSurfaces.times = SplatoonSurfaces.times + 1
			end)
		end
	elseif not isnumber(SplatoonSurfaces[#SplatoonSurfaces]) then
		util.Decal("Ink" .. SplatoonSurfaces[#SplatoonSurfaces].ColorName, 
			SplatoonSurfaces[#SplatoonSurfaces].Pos - SplatoonSurfaces[#SplatoonSurfaces].Normal, 
			SplatoonSurfaces[#SplatoonSurfaces].Pos + SplatoonSurfaces[#SplatoonSurfaces].Normal)
	end
end

function ENT:setCollision(a)
	--self:SetMaterial("phoenix_storms/fender_white")
	self:SetMaterial("decals/inks/ink" .. self.InkColor)
	
	self:UseTriggerBounds(true, 1)
	local h = a
	local ang = self.Normal:Angle()
	ang.pitch = math.abs(ang.pitch - 90)
	ang.yaw = math.abs(ang.yaw)
	
	local xmul, ymul, zmul =
		math.abs(math.cos(math.rad(ang.pitch))) + math.abs(math.sin(math.rad(ang.yaw))),
		math.abs(math.cos(math.rad(ang.pitch))) + math.abs(math.cos(math.rad(ang.yaw))),
		math.abs(math.sin(math.rad(ang.pitch))) + math.abs(math.sin(math.rad(ang.yaw)))
	
	xmul = math.Clamp(xmul, 0, 1)
	ymul = math.Clamp(ymul, 0, 1)
	zmul = math.Clamp(zmul, 0, 1)
	
	h.x = a.x * xmul + 4
	h.y = a.y * ymul + 4
	h.z = a.z * zmul + 4
	self:SetCollisionBounds(-h, h)
	
	self:SetNWVector("hull", a)
end

local function Drop(self)
	if not IsValid(self) then return end
	
	local loops = 4
	if self.InkRadius <= 8 then
		loops = 1
	elseif self.InkRadius <= 14 then
		loops = 2
	end
	for i = 1, loops do
		local pos = self:GetPos() + Vector(0, 0, -10)
		if i == 1 then
			pos = pos + self:GetForward() * self.InkRadius
		elseif i == 2 then
			pos = pos - self:GetForward() * self.InkRadius
		elseif i == 3 then
			pos = pos + self:GetRight() * self.InkRadius
		else
			pos = pos - self:GetRight() * self.InkRadius
		end
		
		local drop = ents.Create("splashootee")
		drop:SetPos(pos)
		drop:SetAngles(self:GetAngles())
		drop:SetModel("models/spitball_small.mdl")
		drop:SetOwner(self.Owner)
		drop:SetPhysicsAttacker(self.Owner)
		drop:SetColor(self:GetColor())
		drop.InkColor = self.InkColor
		drop.Dmg = 0
		drop:SetNoDraw(true)
		drop:Spawn()
		local p = drop:GetPhysicsObject()
		if not (p and IsValid(p)) then
			drop:Remove()
			return
		end
		p:ApplyForceCenter(Vector(0, 0, 0))
	end
end

function ENT:OnRemove()
	timer.Remove(self.DropInitname)
	timer.Remove(self.Dropname)
	timer.Remove(self.InkDmgname)
	
	if not self.Pos then return end
	
	for k, v in pairs(ents.FindInSphere(self:GetPos(), self:GetNWVector("hull", Vector(big, big, big)):Length())) do
		if v.inInk ~= nil then
			v.inInk = false
		end
	end
	
	local deletelist = {}
	for k,v in pairs(SplatoonSurfaces) do
		if not isnumber(v) and self.Pos and self.Pos:IsEqualTol(v.Pos, 10) and 
			self.Normal:IsEqualTol(v.Normal, 10) then
			table.insert(deletelist, k)
		end
	end
	
	for k,v in pairs(deletelist) do
		table.remove(SplatoonSurfaces, v)
	end
	
	draw(true)
end

function ENT:Initialize()
	
	local c = GetConVar("sv_splatoon_automatic_disappear")
	if c:GetFloat() > 0 then
		SafeRemoveEntityDelayed(self, c:GetFloat())
	end
	self:PhysicsInit(SOLID_BBOX)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_BBOX)
	self:SetCollisionGroup(COLLISION_GROUP_INTERACTIVE_DEBRIS)
	
	local a = big
--	self:SetCollisionBounds(Vector(-a, -a, -a), Vector(a, a, a))
	
	self:SetNWVector("hull", Vector(big, big, big) / 2)
	
	if self:GetModel() ~= "models/spitball_large.mdl" then
		return
	else
		self.DropInitname = "dropinit" .. CurTime()
		timer.Create(self.DropInitname, self.SplashInit / self.V0, 1, function()
			Drop(self)
			if self.SplashNum > 1 then
				self.Dropname = "drop" .. CurTime()
				timer.Create(self.Dropname, self.SplashLen / self.V0, self.SplashNum - 1, function() Drop(self) end)
			end
		end)
	end
end

function ENT:transform(n)
	self:SetAngles(self:GetAngles() - self.AngleDif)
	self.size = math.floor(n)
	if self.size == 0 then
		self:SetModel("models/props_trainstation/trainstation_clock001.mdl")
		self.AngleDif = Angle(0, 0, -90)
		self:SetAngles(self:GetAngles() + self.AngleDif)
		self:setCollision(Vector(big, big, big) / 1.8)
	end
end

function ENT:StartTouch(t)
	if not IsValid(t) then return end
	
	if t:IsPlayer() then
		self:EmitSound(HitSound[math.random(0, 20)])
	end
	
	if t:GetClass() == "splashootee" then
		if t.InkColor ~= self.InkColor then
			local tr = util.TraceLine({
				start = self:GetPos() - self:GetForward() * 3,
				endpos = self:GetPos(),
				ent = self
			})
			
			if self.size < 1 then
				self:transform(self.size + 1)
				util.Decal("Ink" .. self.InkColor, tr.HitPos + tr.HitNormal, tr.HitPos - tr.HitNormal)
				
				--debugoverlay.Line(self:GetPos(), self:GetPos() + self:GetRight() * 30, 10, Color(0, 255, 0, 255), false)
				--debugoverlay.Line(tr.HitPos, tr.HitPos + tr.HitNormal * 10, 10, Color(0, 255, 0, 255), false)
			else
				self:Remove()
				return true
			end
		else
			local d = t:GetPos() - self:GetPos()
		end
	end
end

function ENT:Touch(t)
	if not IsValid(t) then return end
	
	if t:IsPlayer() then
		if t:GetActiveWeapon().InkColor == self.InkColor then
			if t:GetVelocity():GetNormalized():Dot(-self:GetForward()) < 0.9 then
				t:GetActiveWeapon().inInk = true
			end
			return false
		else
			if t:GetActiveWeapon().inInk == false then
				if t:Health() > t:GetMaxHealth() / 2 and not timer.Exists(self.InkDmgname) then
					self.InkDmgname = "inkdmg" .. t:EntIndex()
					timer.Create(self.InkDmgname, 0.02, 1, function()
						if IsValid(t) then
							t:SetHealth(t:Health() - 0.5)
						end
					end)
				end
				local s = t:GetVelocity() / -2
				s.z = s.z / 10
				t:SetVelocity(s)
				
				return true
			end
		end
	end
	
	if t:IsNPC() and t.GetActiveWeapon ~= nil then
		if t:GetActiveWeapon().InkColor ~= self.InkColor then
			if t:Health() > t:GetMaxHealth() / 2 and not timer.Exists(self.InkDmgname) then
				self.InkDmgname = "inkdmg" .. t:EntIndex()
				timer.Create(self.InkDmgname, 0.02, 1, function()
					if IsValid(t) then
						t:SetHealth(t:Health() - 0.5)
					end
				end)
			end
			
			return true
		end
	end
	
	return false
end

function ENT:EndTouch(t)
	timer.Destroy(self.InkDmgname)
	if not IsValid(t) then return end
	
	if t:IsPlayer() and isfunction(t.GetActiveWeapon) then
		t:GetActiveWeapon().inInk = false
	end
end

function ENT:BecomeTrigger(data, range, p)
	if self:WaterLevel() > 1 then
		SafeRemoveEntityDelayed(self, 0)
		return
	end
	
	local tr = util.TraceLine({
		start = self:GetPos() - self:GetForward() * 3,
		endpos = self:GetPos(),
		ent = self
	})
	--debugoverlay.Line(tr.HitPos + tr.HitNormal, tr.HitPos - tr.HitNormal, 10, Color(0, 255, 0, 255), true)
	--util.Decal("Ink" .. self.InkColor, tr.HitPos + tr.HitNormal, tr.HitPos - tr.HitNormal)
	
	timer.Simple(0, function()
		self:SetTrigger(true)
		self:SetMoveType(MOVETYPE_NONE)
		self:SetPos(data.HitPos)
		self:SetNotSolid(true)
		self:SetNoDraw(false)
		
		if SERVER then
			local deletelist = {}
			local delflag = false
			local r = self:GetNWVector("hull", Vector(big, big, big)).x * 0.6
			for _,v in pairs(ents.FindInSphere(data.HitPos, r)) do
				if IsValid(v) and v ~= self and v:GetClass() == "splashootee" then
					if v.InkColor == self.InkColor then
						if v:GetMoveType() == MOVETYPE_NONE then
							SafeRemoveEntityDelayed(self, 0)
							return
						end
					else
						SafeRemoveEntityDelayed(v, 0)
						table.insert(deletelist, v)
					end
				end
			end
			
			for k,v in pairs(deletelist) do
				if v.Pos and v.Normal then
					for _,w in pairs(SplatoonSurfaces) do
						if not isnumber(w) and w.Pos:IsEqualTol(v.Pos, 10) and w.Normal:IsEqualTol(v.Normal, 10) then
							table.remove(SplatoonSurfaces, _)
							delflag = true
						end
					end
				end
			end
			
			self.Pos = data.HitPos
			self.Normal = data.HitNormal
			table.insert(SplatoonSurfaces, {
				Pos = data.HitPos,
				Normal = data.HitNormal,
				ColorName = self.InkColor
			})
			
			draw(delflag)
		end
	end)
	
	self:PhysicsInit( SOLID_BBOX )
	self:SetSolid( SOLID_BBOX )
	
	self:SetAngles(data.HitNormal:Angle())
	self:transform(self.size or 0)
	self:SetNoDraw(true)
	self:DrawShadow(false)
	self:SetRenderMode(RENDERMODE_NORMAL)
	self:SetGravity(0)
	self:SetNWBool("triggered", true)
	self:SetNWVector("normal", data.HitNormal)
	self.Normal = data.HitNormal
	self:Setscale(Vector(1, 1, 1))
	self:Setdelta(Vector(0, 0, 0))
end

local function PlaceDecal( self, Player, Entity, Data )

	if Entity == nil then return end
	if not Entity:IsWorld() and not IsValid(Entity) then return end
	
	local Bone = Data.bone
	if not IsValid(Bone) then
		Bone = Entity
	end
	util.Decal(Data.decal, Bone:LocalToWorld(Data.Pos1), Bone:LocalToWorld(Data.Pos2))
	
	if SERVER then
		local i = Entity.DecalCount or 0
		i = i + 1
		duplicator.StoreEntityModifier(Entity, "decal" .. i, Data)
		Entity.DecalCount = i
	end
end

function ENT:paint(data)
	local Pos1 = data.HitPos - data.HitNormal
	local Pos2 = data.HitPos + data.HitNormal
	local decal = "Ink" .. self.InkColor
	
	local Bone = data.PhysObject
	if not Bone then
		Bone = data.HitEntity
	end
	
	Pos1 = Bone:WorldToLocal(Pos1)
	Pos2 = Bone:WorldToLocal(Pos2)
	
	PlaceDecal(self, self:GetOwner(), data.HitEntity, {
		Pos1 = Pos1,
		Pos2 = Pos2,
		bone = Bone,
		decal = decal
	})
end

function ENT:PhysicsUpdate()
	if self:WaterLevel() > 1 then
		SafeRemoveEntityDelayed(self, 0)
		return
	end
end

function ENT:PhysicsCollide(data)
	local Owner = self.Owner
	if not IsValid(Owner) then self:Remove() return end
	
	local p = self:GetPhysicsObject()
	if not (p or IsValid(p)) then
		SafeRemoveEntityDelayed(self, 0)
		return
	else
		p:SetMass(0.00001)
		p:SetVelocityInstantaneous(Vector(0, 0, 0))
	end
	if self:Getdelta() ~= Vector(0, 0, 0) then
		local t = util.TraceLine({
			start = data.HitPos - self:Getdelta() - data.HitNormal * big,
			endpos = data.HitPos - self:Getdelta() + data.HitNormal * big,
			filter = {self, self.Owner}
		})
		if not t.Hit then
			SafeRemoveEntityDelayed(self, 0)
			return
		end
		data.HitPos = t.HitPos
	end
	
	util.BlastDamage(Owner, Owner, data.HitPos, 30, self.Dmg)
	self:EmitSound(Slime[math.random(0, 4)], SNDLVL_20dB, 100, 0.2, CHAN_BODY)
	
	if data.HitEntity:IsWorld() then
		self:BecomeTrigger(data, self.r or 4, p)
		timer.Destroy(self.DropInitname)
		timer.Destroy(self.Dropname)
	else
		self:paint(data)
		SafeRemoveEntityDelayed(self, 0)
	end
end

