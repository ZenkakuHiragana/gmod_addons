
include("weapons/ai_translations.lua")
include("weapons/inklingbase.lua")
if SERVER then
	AddCSLuaFile ()
end

SWEP.ShootSound = {
	Sound("Breakable.Flesh")
}

function SWEP:Bullseye()
	local wep = self
	if wep.Owner:IsMoving() and not wep.FreezeTime then
		timer.Create("fireauto" .. wep.Owner:EntIndex(), wep.Primary.Delay * 2, 3, function()
			if IsValid(wep) and IsValid(wep.Owner) then
				wep.Owner:SetMovementActivity(ACT_RUN_AIM_RIFLE)
				wep:PrimaryAttack()
			end
		end)
	end
end

function SWEP:Init()
	if self.Owner:IsNPC() then
		self.Primary.Recoil = 0
		if self.Owner:GetClass() == "npc_metropolice" or self.Owner:GetClass() == "npc_citizen" then
			self.HoldType = "smg"
			self.Primary.Ammo = "smg1"
		else
			self.HoldType = "ar2"
			self.Primary.Ammo = "ar2"
		end
	end
end

function SWEP:IsInkling(isinkling)
	if self.Owner:IsPlayer() then
		if self.Owner:KeyDown(IN_ATTACK) then
			self.Owner:SetWalkSpeed(self.FiringSpeed)
			self.Owner:SetRunSpeed(self.FiringSpeed)
		else
			self.Owner:SetWalkSpeed(230)
			self.Owner:SetRunSpeed(230)
		end
	end
end

if CLIENT then
	function SWEP:ClientThink(throw)
		if not (throw or self.Owner:KeyDown(IN_ATTACK)) then
			self:SetWeaponHoldType("passive")
		end
	end
	
	function SWEP:PreViewModelDrawn(model, bone_ent, ang, pos, v, matrix)
		if not self.fireVM then return end
		local s = self.fireVM - CurTime()
		if s > 0 then
			matrix:Scale(Vector(1 + s * 2, 1 + s * 2, 1 + s * 2))
		end
	end
	
	function SWEP:PreDrawWorldModel(model, bone_ent, ang, pos, v, matrix)
		if not self.fireVM then return end
		local s = self.fireVM - CurTime()
		if s > 0 then
			matrix:Scale(Vector(1 + s * 2, 1 + s * 2, 1 + s * 2))
		end
	end
end

function SWEP:paint()
	
	if CLIENT or (not IsValid(self)) or (not IsValid(self.Owner)) then return end
	
	local proj = ents.Create("splashootee")
	local proforce = (self.Owner:GetAimVector() +
		(VectorRand() * self.Primary.Spread)):GetNormalized() * self.PrimaryVelocity
	proj:SetModel("models/spitball_large.mdl")
	proj:SetOwner(self.Owner)
	proj:SetColor(self.ProjColor)
	proj:SetPos(self.Owner:GetShootPos() + self.Owner:GetForward() * self.Forward + self.Owner:GetRight() * self.Right + self.Owner:GetUp() * self.Upward)
	proj:SetAngles(self.Owner:EyeAngles())
	proj:SetPhysicsAttacker(self.Owner)
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

function SWEP:PrimaryAttack()
	if not IsValid(self) or not IsValid(self.Owner) then return end
 	if not self:CanPrimaryAttack() then return end
	
	self.ShootCount = self.ShootCount + 1
	self:paint()
	self:EmitSound(self.ShootSound[math.random(1, table.maxn(self.ShootSound))], 75, math.random(90, 110))
	self:TakePrimaryAmmo(self.Primary.TakeAmmo)
	--self.Owner:SetAnimation(PLAYER_ATTACK1)
	
	self.throw = false
	self:SetNWBool("throw", false)
	
	if self.Owner:IsPlayer() then
		self.Owner:SetCurrentViewOffset(self.Owner:GetViewOffset())
 		self.Owner:RemoveFlags(FL_DUCKING)
		local rnda = self.Primary.Recoil * -1
		local rndb = self.Primary.Recoil * math.Rand(-1, 1)
		self.Owner:ViewPunch( Angle( rnda,rndb,rnda ) )
		self:SetNextPrimaryFire( CurTime() + self.Primary.Delay )
		self:SetNextSecondaryFire( CurTime() + self.Primary.Delay )
		self:SetNextReloadTime(self.StopReloading)
		--self.Weapon:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
		if SERVER then
			self.Owner:SendLua("if LocalPlayer():GetActiveWeapon() then LocalPlayer():GetActiveWeapon().fireVM = CurTime() + 0.08 end")
		end
	else
		--self.Owner:SetSchedule(SCHED_RANGE_ATTACK1)
		self:ShootEffects()
		self.Owner:MuzzleFlash()
		self:SetNextPrimaryFire( CurTime() + self.Primary.Delay / 2 )
		self:SetNextSecondaryFire( CurTime() + self.Primary.Delay / 2 )
		
--		if IsValid(self.Owner:GetEnemy()) and (self.Owner:GetEnemy():GetPos() - self.Owner:GetPos()):Length() > self.V0 * self.FallTimer / 1000 then
--			self.Owner:SetCondition(COND_LOST_ENEMY)
--			self.Owner:SetCondition(COND_ENEMY_TOO_FAR)
--			self.Owner:SetCondition(COND_TOO_FAR_TO_ATTACK)
--			self.Owner:ClearSchedule()
--			self.Owner:SetSchedule(SCHED_CHASE_ENEMY)
--		end
		if self:Clip1() < self.Primary.ClipSize / 3 * 2 then
			self.Owner:SetSchedule(SCHED_RELOAD)
		end
		
		if not timer.Exists("fire" .. self:EntIndex()) and self.Primary.Delay < 0.1 then
			timer.Create("fire" .. self:EntIndex(), self.Primary.Delay, 2, function()
				if IsValid(self) then
					self:PrimaryAttack()
				end
			end)
		end
	end
end

function SWEP:SecondaryAttack()
	if self.Owner:IsPlayer() then
		PrintMessage(HUD_PRINTCENTER, "No sub weapon equipped!")
		self:Remove()
	end
end
