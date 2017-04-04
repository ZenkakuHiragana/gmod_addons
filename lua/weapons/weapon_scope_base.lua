
include("weapons/ai_translations.lua")
include("weapons/inklingbase.lua")
if SERVER then
	AddCSLuaFile ()
end

SWEP.ShootSound = {
	Sound("Breakable.Flesh"),
	Sound("Breakable.Flesh")
}
SWEP.PreFireSound = Sound("SplatoonSWEPs/charger/prefire00.wav")
SWEP.AimSound = Sound("SplatoonSWEPs/charger/ChargeAimLoop00.wav")
SWEP.Beep = Sound("SplatoonSWEPs/charger/chargebeep00.mp3")

--SWEP.aim, SWEP.prefire
SWEP.charge = 0

function SWEP:ClientInit()
	self.Eyes = self.Owner:GetSkin()
end

function SWEP:Init()
	if self.Owner:IsNPC() then
		self:SetSaveValue("m_fMaxRange1", self.Range)
		self:SetSaveValue("m_fMaxRange2", self.Range)
		self:SetSaveValue("m_fMinRange1", 50)
		self:SetSaveValue("m_fMinRange2", 50)
		
		if self.Owner:GetClass() == "npc_metropolice" then
			self.HoldType = "smg"
			self.Primary.Ammo = "smg1"
		else
			self.HoldType = "shotgun"
			self.Primary.Ammo = "buckshot"
		end
	end
	self.aim = CreateSound(self, self.AimSound)
	self.prefire = CreateSound(self, self.PreFireSound)
end

function SWEP:AdditionalHolster()
	timer.Destroy("charging" .. self:EntIndex())
	
	self.charge = 0
	self:SetNWInt("charge", 0)
	
	if SERVER then
		self.aim:Stop()
	end
	
	if IsValid(self) and IsValid(self.Owner) then
		if self.Owner:IsPlayer() then
			self.Owner:RemoveAmmo(self.Owner:GetAmmoCount(self.Primary.Ammo), self.Primary.Ammo, true)
			self.Owner:RemoveAmmo(self:Ammo1(), self.Primary.Ammo, true)
			
			local isinkling = GetConVar("cl_splatoon_isinkling")
			if isinkling and isinkling:GetInt() == 1 then
				self.Owner:SetSkin(self.Eyes or 0)
			end
		end
	end
	
	return true
end

function SWEP:SetupDataTables()
	self:NetworkVar("Int", 0, "charge")
end

function SWEP:AdditionalDeploy()
	self.fov = self.Owner:GetFOV()
	return true
end

if CLIENT then
	function SWEP:PreViewModelDrawn(model, bone_ent, ang, pos, v, matrix)
		----------------------------------------
		if self.Owner:IsPlayer() then
			if self:Ammo1() > 0 and self:Ammo1() < 50 then
				render.DrawLine(model:GetPos() + Vector(0, 0, 1),
					model:GetPos() + Vector(0, 0, 1) + self.Owner:GetForward() * 10000, self.ProjColor, true)
			elseif self:Ammo1() > 90 then
				matrix:Scale(Vector(0.1, 0.1, 0.1))
			end
		end
		
		if not self.fireVM then return end
		local s = self.fireVM - CurTime()
		if s > 0 then
			matrix:Scale(Vector(1 + s * 2, 1 + s * 2, 1 + s * 2))
		end
		----------------------------------------
	end
	
	function SWEP:PreDrawWorldModel(model, bone_ent, ang, pos, v, matrix)
		--------------------------------------
			self.charge = self:GetNWInt("charge", 0)
		if IsValid(self.Owner) and self.charge > 0 then
			local vec
			if self.Owner:IsPlayer() then
				vec = self.Owner:GetAimVector()
			else
				--vec = self:GetNWVector("aim", self.Owner:GetForward())
				vec = model:GetForward()
			end
			
			local s = self:GetAttachment(self:LookupAttachment("muzzle")).Pos
					+ Vector(0, 0, 1.5) + model:GetForward() * 3 + model:GetRight() * 0
			local aim = vec * self:GetNWInt("charge", 0) / 100 * self.Range
			
			if math.abs(vec:Dot(Vector(0, 0, 1))) > 0.78 then
				aim = model:GetForward() * self:GetNWInt("charge", 0) / 100 * self.Range
			end
			
			local tb = {
				start = s,
				endpos = s + aim,
				filter = self
			}
				if self.charge < 100 then
					self.charge = self.charge + self.ChargeSpeed
				else
					self.charge = 100
				end
				
			local t = util.TraceLine(tb)
				render.DrawLine(tb.start, t.HitPos or tb.endpos, self.ProjColor, true)
		end
		--------------------------------------
	end
	
	------------------------------------------------------------
	function draw.Circle( x, y, r, deg )
		local x1, y1, x2, y2 = 0, 0, 0, 0
		surface.SetDrawColor(255, 255, 255, 255)
		for i = 1, deg do
			y1 = -r * math.cos(math.rad(i * 3.6))
			x1 = r * math.sin(math.rad(i * 3.6))
			
			y2 = -r * math.cos(math.rad((i + 1) * 3.6))
			x2 = r * math.sin(math.rad((i + 1) * 3.6))
			
			surface.DrawLine(x1 + x, y1 + y, x2 + x, y2 + y)
		end
		surface.SetDrawColor(0, 0, 0, 100)
		for i = deg, 100 do
			y1 = -r * math.cos(math.rad(i * 3.6))
			x1 = r * math.sin(math.rad(i * 3.6))
			
			y2 = -r * math.cos(math.rad((i + 1) * 3.6))
			x2 = r * math.sin(math.rad((i + 1) * 3.6))
			
			surface.DrawLine(x1 + x, y1 + y, x2 + x, y2 + y)
		end
	end
	
	local scope = Material("gmod/scope")
	local scoperef = Material("gmod/scope-refract")
	function SWEP:DoDrawCrosshair(x, y)
		if self.charge > 50 then
			local black = Color(0, 0, 0, 255 * ((self.charge - 50) / 50))
			surface.SetDrawColor(black)
			if self.charge >= 100 then
				surface.SetMaterial(scoperef)
				surface.DrawTexturedRect(0, 0, ScrW(), ScrH())
			end
			surface.SetMaterial(scope)
			surface.DrawTexturedRect(0, 0, ScrW(), ScrH())
		end
		
		self.charge = self:GetNWInt("charge", 0)
		surface.DrawCircle(x, y, 10, Color(0, 0, 0, 40))
		surface.DrawCircle(x, y, 15, Color(0, 0, 0, 40))
		if self.charge > 0 then
			for i = 11, 14 do
				draw.Circle(x, y, i, self.charge)
			end
		--	if self.charge < self:Clip1() then
		--		self:SetNWInt("charge", self.charge + self.ChargeSpeed / 2)
		--	end
			
			
			local p = self.Range * self.charge / 100
			if p < self.SplashLen * 16 then p = self.SplashLen * 16 end
			local t = util.TraceLine({
				start = self.Owner:GetShootPos(),
				endpos = self.Owner:GetShootPos() + self.Owner:GetAimVector() * p,
				filter = {self, self.Owner}
			})
			if t.Hit then
				surface.DrawCircle(x, y, 9, self.ProjColor)
				surface.DrawCircle(x, y, 10, self.ProjColor)
				surface.DrawCircle(x, y, 15, self.ProjColor)
				surface.DrawCircle(x, y, 16, self.ProjColor)
				
				if IsValid(t.Entity) then
					local d1, d2 = 15, 26
					local darker = Color(self.ProjColor.r / 3, self.ProjColor.g / 3, self.ProjColor.b / 3)
					local brighter = Color(self.ProjColor.r + (255 - self.ProjColor.r) / 2,
											self.ProjColor.g + (255 - self.ProjColor.g) / 2,
											self.ProjColor.b + (255 - self.ProjColor.b) / 2)
					surface.SetDrawColor(brighter)
					local w, h = 0, 0
					for i = 1, 7 do
						if i == 2 then
							w, h = 1, 0
						elseif i == 3 then
							w, h = 0, 1
						elseif i == 4 then
							surface.SetDrawColor(self.ProjColor)
							w, h = 2, 0
						elseif i == 5 then
							w, h = 0, 2
						elseif i == 6 then
							surface.SetDrawColor(darker)
							w, h = 3, 0
						elseif i == 7 then
							w, h = 0, 3
						end
						surface.DrawLine(x + d1 + w, y + d1 + h, x + d2 + w, y + d2 + h)
						surface.DrawLine(x + d1 + w, y - d1 - h, x + d2 + w, y - d2 - h)
						surface.DrawLine(x - d1 - w, y + d1 + h, x - d2 - w, y + d2 + h)
						surface.DrawLine(x - d1 - w, y - d1 - h, x - d2 - w, y - d2 - h)
					end
				end
			end
			return true
		else
			return false
		end
	end
	------------------------------------------------------------
end

function SWEP:IsSquid(isinkling)
	self.aim:Stop()
	self.prefire:Stop()
	if self.charge > 0 then
		self.charge = 0
		self:SetNWInt("charge", 0)
		self.Owner:SetFOV(0, 0.2)
		self.Owner:RemoveAmmo(self.Owner:GetAmmoCount(self.Primary.Ammo), self.Primary.Ammo, true)
	end
end

function SWEP:IsInkling(isinkling)
	if self.Owner:IsPlayer() then
		if self.Owner:KeyDown(IN_ATTACK) then
			self.Owner:SetWalkSpeed(self.FiringSpeed + ((250 - self.FiringSpeed) * ((10 - self.charge^0.5) / 10)))
			self.Owner:SetRunSpeed(self.FiringSpeed + ((250 - self.FiringSpeed) * ((10 - self.charge^0.5) / 10)))
		else
			self.Owner:SetWalkSpeed(230)
			self.Owner:SetRunSpeed(230)
		end
		
		if self.charge > 0 then
			if not self.Owner:KeyDown(IN_ATTACK) then
				self:FireInk()
				self.Owner:SetFOV(0, 0.2)
			elseif self.charge > 50 then
				self.Owner:SetFOV(self.fov - ((self.fov - self.Zoom) * ((self.charge - 50) / 50)), 0)
			end
		end
	else
		if self.charge > 0 then
			if self.charge > 100 then
				self.charge = 100
				self:SetNWInt("charge", 100)
			else
				self.charge = self.charge + self.ChargeSpeed * 2
				self:SetNWInt("charge", self.charge)
			end
		end
	end
end

function SWEP:ClientThink(throw)
	if not throw then
		if self.Owner:KeyDown(IN_ATTACK) then
			self.Owner:SetSkin(4)
			self:SetWeaponHoldType(self.HoldType)
		else
			self:SetWeaponHoldType("passive")
			self.Owner:SetSkin(self.Eyes or 0)
		end
	end
end

function SWEP:paint()
	
	local dmg = self.MinDamage + (self.UptoDamage - self.MinDamage) / (100 - self.MinTime) * (self.charge - self.MinTime)
	if self.charge >= 100 then dmg = self.MaxDamage end
	if dmg < self.MinDamage then dmg = self.MinDamage end
	
	local distance = self.Range * self.charge / 100
	if distance < self.SplashLen * 11 then distance = self.SplashLen * 11 end
	
	--if util.QuickTrace(self.Owner:GetShootPos(),
	--	self.Owner:GetAimVector() * distance, {self, self.Owner}) then end
	local b = {
		Attacker = self.Owner,
		Damage = dmg,
		Force = 0,
		Distance = distance,
		HullSize = 4,
		Num = 1,
		Tracer = 10000000,
		AmmoType = self.Primary.Ammo,
		Dir = self.Owner:GetAimVector(),
		Spread = Vector(0, 0, 0),
		Src = self.Owner:GetShootPos()
	}
	
	self:FireBullets(b, true)
	local SplatInit = math.random(0, self.SplashPattern or 0) * self.SplashLen / ((self.SplashPattern or 2) - 1)
	local SplatRate = self.SplashLen * (self.SplashMul - ((self.SplashMul - 1) * self.charge / 100))
	local d = self.Width * self.charge / 100
	if d < 16 then
		d = 0
	else
		SplatInit = 0
	end
	
	local pos = self.Owner:GetShootPos()-- + self.Owner:GetForward() * self.Forward + self.Owner:GetRight() * self.Right + self.Owner:GetUp() * self.Upward
	local tb = {
		start = pos,
		endpos = pos + self.Owner:GetAimVector() * self.Range,
		filter = {self, self.Owner}
	}
	local t = util.TraceLine(tb)
	local r = self.Range * self.charge / 100
	local tl = (t.HitPos - pos):Length()
	
	local loops = 1
	local wallhit = ((t.Hit and tl < r) or tl < SplatRate * 16)
	if wallhit then
		loops = math.floor(tl / SplatRate)
	else
		loops = math.floor(r / SplatRate)
		if loops < 16 then loops = 16 end
	end
	for _ = 1, 2 do
		for i = 1, loops do
			local proj = ents.Create("splashootee")
			proj:Setscale(Vector(10, 1, 1))
			proj:Setink(self.InkColor)
			proj:Setdelta(self.Owner:GetRight() * d)
			
			local vec
			if self.Owner:IsPlayer() then
				vec = self.Owner:GetEyeTrace()
			else
				vec = t
			end
			local p = pos + (vec.HitPos - pos):GetNormalized() * (SplatRate * i + SplatInit)
			proj:SetModel("models/spitball_medium.mdl")
			proj:SetOwner(self.Owner)
			proj:SetColor(self.ProjColor)
			proj:SetPos(p)
			proj:SetAngles(self.Owner:GetAimVector():Angle())
			proj:SetPhysicsAttacker(self.Owner)
			proj.InkColor = self.InkColor
			proj.Dmg = 0
			proj.InkRadius = self.InkRadius
			proj.SplashLen = SplatRate
			proj.V0 = self.V0
			proj:DrawShadow(false)
			if _ == 1 and d >= 16 then proj:SetNoDraw(true) end
			proj:Spawn()
			
			local ph = proj:GetPhysicsObject()
			if not (ph and IsValid(ph)) then
				proj:Remove()
				return
			end
			ph:ApplyForceCenter(Vector(0, 0, 0))
		end
		
		if d < 16 then
			break
		else
			d = -d
		end
	end
	
	if not wallhit then return end
	
	local below = util.TraceLine({
		start = t.HitPos + t.HitNormal * self.Range * self.charge / 300,
		endpos = t.HitPos + t.HitNormal * self.Range * self.charge / 300 - Vector(0, 0, tl)
	})
	local delta = {
		Vector(0, 0, 0.8),
		Vector(0, -0.8, 0),
		Vector(0, 0.8, 0)
	}
	
	loops = 3
	if math.abs(t.HitNormal:Dot(Vector(0, 0, 1))) > 0.70714576 then
		loops = 1
	end
	
	for _ = 1, loops do
		local d, a = delta[_], t.HitNormal:Angle()
		--a.pitch = a.pitch - 90
		d:Rotate(a)
		local p = t.HitPos + d * self.SplashLen * self.charge / 100
		if loops == 1 then p = t.HitPos end
		
		--debugoverlay.Line(p, p - t.HitNormal, 5, Color(0, 255, 0, 255), true)
		
		if util.TraceLine({
			start = p,
			endpos = p - t.HitNormal,
			filter = {self, self.Owner}
		}).HitWorld then
			
			local proj = ents.Create("splashootee")
			proj:SetOwner(self.Owner)
			proj:SetColor(self.ProjColor)
			proj:SetPos(p)
			proj:SetPhysicsAttacker(self.Owner)
			proj.InkColor = self.InkColor
			proj.Dmg = 0
			proj:Spawn()
			proj:BecomeTrigger({
				HitPos = p,
				HitNormal = -t.HitNormal
			}, 1)
			proj:transform(math.floor(math.Remap(100 - self.charge, 0, 100, 0, 3)))
		else
			util.Decal("Ink" .. self.InkColor, p + t.HitNormal, p - t.HitNormal)
		end
	end
	
	local index = 0.8
	local filter_ent = ents.FindByClass("splashootee")
	table.insert(filter_ent, self)
	table.insert(filter_ent, self.Owner)
	pos = t.HitPos + Vector(0, 0, -SplatRate) * index
	while pos.z > below.HitPos.z + SplatRate * 0.8 do
		pos = t.HitPos + Vector(0, 0, -SplatRate) * index
		debugoverlay.Line(pos, pos - t.HitNormal * 5, 5, Color(0, 255, 0, 255), false)
		local tw = util.TraceLine({
			start = self.Owner:GetShootPos(),
			endpos = pos - t.HitNormal * 5,
			filter = filter_ent
		})
		if tw.Hit then
			local proj = ents.Create("splashootee")
			proj:SetOwner(self.Owner)
			proj:SetColor(self.ProjColor)
			proj:SetPos(tw.HitPos)
			proj:SetPhysicsAttacker(self.Owner)
			proj.InkColor = self.InkColor
			proj.Dmg = 0
			proj:Spawn()
			proj:BecomeTrigger({
				HitPos = tw.HitPos,
				HitNormal = -tw.HitNormal
			}, 0)
			proj:transform(math.floor(math.Remap(100 - self.charge, 0, 105, 0, 3)))
		else
			util.Decal("Ink" .. self.InkColor, tw.HitPos + t.HitNormal * 5, tw.HitPos - t.HitNormal * 5)
		end
		index = index + 1
	end
end

function SWEP:FireInk()
	self:SetNextPrimaryFire( CurTime() + self.Primary.Delay )
	self:SetNextSecondaryFire( CurTime() + self.Primary.Delay )
	self:SetNextReloadTime(self.StopReloading)
	self.ShootCount = self.ShootCount + 1
	self:paint()
	self:TakePrimaryAmmo(self.Primary.TakeAmmo * self.charge)
	
	if self.Owner:IsPlayer() then
		self.Owner:RemoveAmmo(self.Owner:GetAmmoCount(self.Primary.Ammo), self.Primary.Ammo, true)
		local rnda = self.Primary.Recoil * -1
		local rndb = self.Primary.Recoil * math.random(-1, 1)
		self.Owner:ViewPunch( Angle( rnda,rndb,rnda ) )
		if SERVER then
			self.Owner:SendLua("if LocalPlayer():GetActiveWeapon() then LocalPlayer():GetActiveWeapon().fireVM = CurTime() + 0.08 end")
		end
	else
		self:ShootEffects()
		self.Owner:MuzzleFlash()
	end
	
	local lv = 1
	local pitch = 100
	if self.charge > 75 then lv = 2 pitch = 100 + 75 / 5 end
	self:EmitSound(self.ShootSound[lv], 75, pitch - self.charge / 5, CHAN_WEAPON)
	self.aim:Stop()
	self.prefire:Stop()
	
	self.charge = 0
	self:SetNWInt("charge", 0)
	self:SetNextReloadTime(self.StopReloading)
	
	self.throw = false
	self:SetNWBool("throw", false)
end

function SWEP:PrimaryAttack()
	if not IsValid(self) or not IsValid(self.Owner) then return end
 	if not self:CanPrimaryAttack() then return end
	if self.Owner:IsFlagSet(FL_DUCKING) then return end
	
	self.throw = false
	self:SetNWBool("throw", false)
	if self.charge == 0 then
		self.prefire:Play()
	end
	
	if SERVER and self.Owner:IsPlayer() then
		if self.charge * self.Primary.TakeAmmo > self:Clip1() then
			self.charge = self:Clip1() / self.Primary.TakeAmmo
		else
			self:SetNextReloadTime(self.StopReloading)
		end
		
		if self.charge < 100 and not timer.Exists("charging" .. self:EntIndex()) then
			local t = 0.005
			if not self.Owner:IsFlagSet(FL_ONGROUND) then t = 0.005 * 6 end
			timer.Create("charging" .. self:EntIndex(), t, 1, function()
				if IsValid(self) and IsValid(self.Owner) then
					self.charge = self.charge + self.ChargeSpeed
					self.Owner:GiveAmmo(self.charge - self.Owner:GetAmmoCount(self.Primary.Ammo), self.Primary.Ammo, true)
					if self.charge >= 100 then
						self.charge = 100
						self.Owner:RemoveAmmo(self.Owner:GetAmmoCount(self.Primary.Ammo) - 100, self.Primary.Ammo, true)
						self.aim:Stop()
						self:EmitSound(self.Beep)
					else
						self.aim:PlayEx(0.5, (self.charge * 0.9) + 1)
					end
				end
			end)
		end
		self:SetNWInt("charge", self.charge)
	elseif SERVER and self.Owner:IsNPC() then
		if self:Clip1() < self.Primary.ClipSize / 3 then
			self.Owner:SetSchedule(SCHED_RELOAD)
			timer.Destroy("fire" .. self:EntIndex())
			self.charge = 0
			self:SetNWInt("charge", 0)
			return
		end
		
		self:SetNWVector("aim", self.Owner:GetAimVector())
		
		if not timer.Exists("fire" .. self:EntIndex()) then
			self.Owner:SetCurrentWeaponProficiency(WEAPON_PROFICIENCY_PERFECT)
			self.Owner:SetSchedule(SCHED_RANGE_ATTACK1)
			self:SetNextPrimaryFire( CurTime() + self.Primary.Delay / 2 )
			self:SetNextSecondaryFire( CurTime() + self.Primary.Delay / 2 )
			
			self.charge = 8
			self:SetNWInt("charge", 8)
			
			timer.Create("fire" .. self:EntIndex(), 1.5 / self.ChargeSpeed, 1, function()
				if IsValid(self) and IsValid(self.Owner) then
					self.charge = 100
					self:FireInk()
				end
			end)
		end
	end
end

function SWEP:SecondaryAttack()
	if self.Owner:IsPlayer() then
		PrintMessage(HUD_PRINTCENTER, "No sub weapon equipped!")
	end
end
