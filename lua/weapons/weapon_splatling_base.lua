

include("weapons/ai_translations.lua")
include("weapons/inklingbase.lua")
if SERVER then
	AddCSLuaFile ()
end

SWEP.ShootSound = {
	Sound("Breakable.Flesh")
}
SWEP.Charge = Sound("SplatoonSWEPs/charger/ChargeAimLoop00.wav")
SWEP.Beep = Sound("SplatoonSWEPs/charger/chargebeep00.mp3")

--SWEP.aim, SWEP.c1, SWEP.c2, SWEP.c3

SWEP.charge = 0

function SWEP:ClientInit()
	self.Eyes = self.Owner:GetSkin()
end

function SWEP:Init()
	if self.Owner:IsNPC() then
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
	self.aim = CreateSound(self, self.Charge)
	self.c1 = CreateSound(self, self.Charge1)
	self.c2 = CreateSound(self, self.Charge2)
	self.c3 = CreateSound(self, self.Charged)
end

function SWEP:AdditionalHolster()
	timer.Destroy("charging" .. self:EntIndex())
	
	self.charge = 0
	self:SetNWInt("charge", 0)
	
	if SERVER then
		self.aim:Stop()
		self.c1:Stop()
		self.c2:Stop()
		self.c3:Stop()
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

if CLIENT then
	function SWEP:PreViewModelDrawn(model, bone_ent, ang, pos, v, matrix)
		----------------------------------------
		
		self.charge = self:GetNWInt("charge", 0)
		model:ManipulateBoneAngles(model:LookupBone("rotate_1"), Angle(0, CurTime() * self.charge * 10, 0))
		
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
		model:ManipulateBoneAngles(model:LookupBone("rotate_1"), Angle(0, CurTime() * self.charge * 10, 0))
		
		if IsValid(self.Owner) and self.charge > 0 then
			
			if self.charge < 200 then
				self.charge = self.charge + self.ChargeSpeed
			else
				self.charge = 200
			end
		end
		--------------------------------------
	end
	
	------------------------------------------------------------
	function draw.Circle( x, y, r, deg )
		local x1, y1, x2, y2 = 0, 0, 0, 0
		surface.SetDrawColor(255, 255, 255, 127)
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
	
	function SWEP:DoDrawCrosshair(x, y)
		self.charge = self:GetNWInt("charge", 0)
		surface.DrawCircle(x, y, 22, Color(0, 0, 0, 40))
		surface.DrawCircle(x, y, 30, Color(0, 0, 0, 40))
		if self.charge > 0 then
			
			if self.charge > 100 then
				for r = 22, 30 do
					surface.SetDrawColor(255, 255, 255, 255)
					for i = 1, self.charge - 100 do
						y1 = -r * math.cos(math.rad(i * 3.6))
						x1 = r * math.sin(math.rad(i * 3.6))
						
						y2 = -r * math.cos(math.rad((i + 1) * 3.6))
						x2 = r * math.sin(math.rad((i + 1) * 3.6))
						
						surface.DrawLine(x1 + x, y1 + y, x2 + x, y2 + y)
					end
				end
				for i = 22, 30 do
					draw.Circle(x, y, i, 100) 
				end
			else
				for i = 22, 30 do
					draw.Circle(x, y, i, self.charge)
				end
			end
			
			local c = self.charge
			if c > 100 then c = 100 end
			local p = self.strength or math.Remap(c, 0, 100, 28000, self.PrimaryVelocity)
			p = p * self.Range
			local t = util.TraceLine({
				start = self.Owner:GetShootPos(),
				endpos = self.Owner:GetShootPos() + self.Owner:GetAimVector() * p,
				filter = {self, self.Owner}
			})
			if t.Hit and not (IsValid(t.Entity) and t.Entity:GetClass() == "splashootee") then
				surface.DrawCircle(x, y, 20, self.ProjColor)
				surface.DrawCircle(x, y, 21, self.ProjColor)
				surface.DrawCircle(x, y, 31, self.ProjColor)
				surface.DrawCircle(x, y, 32, self.ProjColor)
				
				if IsValid(t.Entity) and not t.Entity:GetClass() == "splashootee" then
					local d1, d2 = 20, 31
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
	self.c1:Stop()
	self.c2:Stop()
	self.c3:Stop()
	self.charge = 0
	self:SetNWInt("charge", 0)
	timer.Destroy("f" .. self:EntIndex())
	self.Owner:RemoveAmmo(self.Owner:GetAmmoCount(self.Primary.Ammo), self.Primary.Ammo, true)
end

function SWEP:IsInkling(isinkling)
	if self.Owner:IsPlayer() then
		
		if self.Owner:KeyDown(IN_ATTACK) then
			local scale = (self.maxspeed - self.FiringSpeed) * ((10 - self.charge^0.5) / 10)
			self.Owner:SetWalkSpeed(self.FiringSpeed + scale)
			self.Owner:SetRunSpeed(self.FiringSpeed + scale)
		else
			self.Owner:SetWalkSpeed(230)
			self.Owner:SetRunSpeed(230)
		end
		
		if self.charge > 0 and not self.Owner:KeyDown(IN_ATTACK) and not timer.Exists("f" .. self:EntIndex()) then
			local c, scale = 0, self.charge / 200
			local times = math.ceil(self.FireLast / 60 / self.Primary.Delay * scale)
			local charge = self.charge
			if charge > 100 then charge = 100 end
			self.strength = math.Remap(charge, 0, 100, 28000, self.PrimaryVelocity)
			charge = self.charge
			
			timer.Create("f" .. self:EntIndex(), self.Primary.Delay, times, function()
				if IsValid(self) then
					self:FireInk()
					self.Owner:RemoveAmmo(charge / times, self.Primary.Ammo, true)
					self.charge = self.charge - (charge / times)
					c = c + 1
					if c >= times then
						self.charge = 0
						self.Owner:RemoveAmmo(self.Owner:GetAmmoCount(self.Primary.Ammo), self.Primary.Ammo, true)
					end
					self:SetNWInt("charge", self.charge)
				end
			end)
		end
	else
		if self.charge > 0 then
			if self.charge > 200 then
				self.charge = 200
				self:SetNWInt("charge", 200)
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
		else
			self.Owner:SetSkin(self.Eyes or 0)
		--	self:SetWeaponHoldType("passive")
		end
	end
end

function SWEP:paint()
	
	if CLIENT or (not IsValid(self)) or (not IsValid(self.Owner)) then return end
	
	local proj = ents.Create("splashootee")
	local proforce = (self.Owner:GetAimVector() +
		(VectorRand() * self.Primary.Spread)):GetNormalized() * (self.strength or self.PrimaryVelocity)
	proj:SetModel("models/spitball_large.mdl")
	proj:SetOwner(self.Owner)
	proj:SetColor(self.ProjColor)
	proj:SetPos(self.Owner:GetShootPos() + self.Owner:GetForward() * self.Forward + self.Owner:GetRight() * self.Right + self.Owner:GetUp() * self.Upward)
	proj:SetAngles(self.Owner:EyeAngles())
	proj:SetPhysicsAttacker(self.Owner)
	proj:Setscale(Vector(1, 0.6, 0.6))
	proj.InkColor = self.InkColor
	proj.Dmg = self.BlastDamage
	proj.InkRadius = self.InkRadius
	proj.SplashNum = self.SplashNum
	proj.SplashLen = self.SplashLen
	proj.SplashInit = (self.ShootCount % self.SplashPattern) *
		(self.SplashLen + math.random(-self.SplashSpread, self.SplashSpread)) / self.SplashPattern
	proj.V0 = self.V0
	proj:Spawn()
	
	local ph = proj:GetPhysicsObject()
	if not (ph and IsValid(ph)) then
		proj:Remove()
		return
	end
	ph:ApplyForceCenter(proforce)
	
	timer.Simple(self.FallTimer / 1000, function()
		if IsValid(ph) then
			local z = ph:GetVelocity().z
			if z > 0 then z = -z / 5 end
			ph:SetVelocity(Vector(0, 0, z))
		end
	end)
	
	if self.ShootCount % self.SplashPattern == 0 then
		local p = ents.Create("splashootee")
		p:SetModel("models/spitball_small.mdl")
		p:SetOwner(self.Owner)
		p:SetColor(self.ProjColor)
		p:SetPos(self.Owner:GetShootPos())
		p:SetAngles(self.Owner:EyeAngles())
		p:SetPhysicsAttacker(self.Owner)
		p.InkColor = self.InkColor
		p.Dmg = 0
		p.InkRadius = self.InkRadius
		p.SplashNum = self.SplashNum
		p.SplashLen = self.SplashLen
		p:SetNoDraw(true)
		p:Spawn()
		
		local ph = p:GetPhysicsObject()
		if not (ph and IsValid(ph)) then
			p:Remove()
			return
		end
		ph:ApplyForceCenter(Vector(0, 0, 0))
	end
	
	for i = 1, 2 do
		local splat = ents.Create("splashootee")
		splat:SetModel("models/spitball_small.mdl")
		splat:SetOwner(self.Owner)
		splat:SetColor(self.ProjColor)
		splat:SetPos(self.Owner:GetShootPos() + self.Owner:GetForward() * self.Forward + self.Owner:GetRight() * self.Right + self.Owner:GetUp() * self.Upward)
		splat:SetAngles(self.Owner:EyeAngles())
		splat:SetPhysicsAttacker(self.Owner)
		splat.InkColor = self.InkColor
		splat.Dmg = 0
		splat.InkRadius = self.InkRadius
		splat.SplashNum = self.SplashNum
		splat.SplashLen = self.SplashLen
		splat:SetNoDraw(true)
		splat:Spawn()
		
		local ph = splat:GetPhysicsObject()
		if not (ph and IsValid(ph)) then
			splat:Remove()
			return
		end
		
		local f
		if i == 1 then
			f = proforce * self.Primary.Splash1
		elseif i == 2 then
			f = proforce * self.Primary.Splash2
		end
		ph:ApplyForceCenter(f)

		timer.Simple(self.FallTimer / 1000, function()
			if IsValid(ph) then
				local z = ph:GetVelocity().z
				if z > 0 then z = -z / 5 end
				ph:SetVelocity(Vector(0, 0, z))
			end
		end)
	end
end

function SWEP:FireInk()
	if not IsValid(self) or not IsValid(self.Owner) then return end
	if not self:CanPrimaryAttack() or
		(self.Owner:IsPlayer() and self.Owner:Crouching()) then return end
	
	self.ShootCount = self.ShootCount + 1
	self:paint()
	self.Owner:SetAnimation(PLAYER_ATTACK1)
	self:TakePrimaryAmmo(self.Primary.TakeAmmo)
	
	self.throw = false
	self:SetNWBool("throw", false)
	
	if self.Owner:IsPlayer() then
		local rnda = self.Primary.Recoil * -1
		local rndb = self.Primary.Recoil * math.random(-1, 1)
		self.Owner:ViewPunch( Angle( rnda,rndb,rnda ) )
		self:SetNextPrimaryFire( CurTime() + self.Primary.Delay )
		self:SetNextSecondaryFire( CurTime() + self.Primary.Delay )
		self:SetNextReloadTime(self.StopReloading)
		self.Weapon:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
	else
		--self.Owner:SetSchedule(SCHED_RANGE_ATTACK1)
		self:ShootEffects()
		self.Owner:MuzzleFlash()
		self:SetNextPrimaryFire( CurTime() + self.Primary.Delay )
		self:SetNextSecondaryFire( CurTime() + self.Primary.Delay )
	end
	self:EmitSound(self.ShootSound[math.random(1, table.maxn(self.ShootSound))], 75, math.random(90, 110))
	self.aim:Stop()
	self.c1:Stop()
	self.c2:Stop()
	self.c3:Stop()
	
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
	
	if SERVER then
		if self.Owner:IsPlayer() then
			if self.charge > self:Clip1() then
				self.charge = self:Clip1()
			else
				self:SetNextReloadTime(self.StopReloading)
			end
		end
		
		if self.charge < 200 and not timer.Exists("charging" .. self:EntIndex()) then
			self.c3:Stop()
			local t = 0.005
			if not self.Owner:IsFlagSet(FL_ONGROUND) then t = 0.005 * 6 end
			timer.Create("charging" .. self:EntIndex(), t, 1, function()
				if IsValid(self) and IsValid(self.Owner) then
					if self.charge < 100 then
						self.charge = self.charge + self.ChargeSpeed
						if self.charge >= 100 then
							--play the first beep
						--	self.c1:Stop()
							self:EmitSound(self.Beep, 75, 100)
						else
							self.c1:PlayEx(1, (self.charge / 2) + 100)
							self.aim:PlayEx(0.5, (self.charge * 0.9) + 1)
						end
					elseif self.charge < 200 then
						self.charge = self.charge + self.ChargeSpeed2
						if self.charge >= 200 then
							self.charge = 200
							self.aim:Stop()
						--	self.c2:Stop()
							self:EmitSound(self.Beep, 75, 115)
							self.c3:PlayEx(1, 100)
						else
							self.c2:PlayEx(1, self.charge / 2)
							self.aim:PlayEx(0.5, (self.charge * 0.9) + 1)
						end
					end
					if self.Owner:IsPlayer() then
						self.Owner:GiveAmmo(self.charge - self.Owner:GetAmmoCount(self.Primary.Ammo),
							self.Primary.Ammo, true)
					end
				end
			end)
		elseif not timer.Exists("charging" .. self:EntIndex()) then
			timer.Create("charging" .. self:EntIndex(), 1.2, 1, function()
				if IsValid(self) and IsValid(self.Owner) and not (self.charge < 200) then
				--	self.c2:Stop()
					self.c3:Stop()
				--	self.c2:Play()
					self.c3:Play()
				end
			end)
		end
		self:SetNWInt("charge", self.charge)
		
		if self.Owner:IsNPC() then
			if self:Clip1() < self.Primary.ClipSize / 3 then
				self.Owner:SetSchedule(SCHED_RELOAD)
				timer.Destroy("fire" .. self:EntIndex())
				timer.Destroy("f" .. self:EntIndex())
				self.charge = 0
				self:SetNWInt("charge", 0)
				return
			end
			
			if not timer.Exists("fire" .. self:EntIndex()) then
				self.Owner:SetCurrentWeaponProficiency(WEAPON_PROFICIENCY_PERFECT)
				self.Owner:SetSchedule(SCHED_RANGE_ATTACK1)
				self:SetNextPrimaryFire( CurTime() + self.Primary.Delay )
				self:SetNextSecondaryFire( CurTime() + self.Primary.Delay )
				
				self.charge = 8
				self:SetNWInt("charge", 8)
				
				timer.Create("fire" .. self:EntIndex(), 2.5 / self.ChargeSpeed + math.random(), 1, function()
					if IsValid(self) and IsValid(self.Owner) then
						self.charge = 200
						
						local c, scale = 0, self.charge / 200
						local times = math.ceil(self.FireLast / 60 / self.Primary.Delay * scale)
						local charge = self.charge
						if charge > 100 then charge = 100 end
						self.strength = math.Remap(charge, 0, 100, 28000, self.PrimaryVelocity)
						charge = self.charge
						
						timer.Create("f" .. self:EntIndex(), self.Primary.Delay, times, function()
							if IsValid(self) then
								self:FireInk()
								self.charge = self.charge - (charge / times)
								c = c + 1
								if c >= times then
									self.charge = 0
								end
								self:SetNWInt("charge", self.charge)
							end
						end)
					end
				end)
			end
		end
	end
	
end

function SWEP:SecondaryAttack()
	if self.Owner:IsPlayer() then
		PrintMessage(HUD_PRINTCENTER, "No sub weapon equipped!")
	end
end
