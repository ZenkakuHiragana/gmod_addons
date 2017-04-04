--SubWeapon: Ink Mine
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"
SWEP.Secondary.TakeAmmo = SWEP.Primary.ClipSize / 2
SWEP.Secondary.Delay = 0.4

SWEP.proj = nil

function SWEP:Throw()
	self.throw = false
	timer.Simple(0.6, function()
		self:SetNWBool("throw", false)
	end)
	if self.Secondary.TakeAmmo > self:Clip1() then return end
	
	local t = util.TraceLine({
		start = self.Owner:GetPos() + Vector(0, 0, 1),
		endpos = self.Owner:GetPos() - Vector(0, 0, 1),
		filter = {self, self.Owner, self.proj}
	})
	if t.Hit and t.HitWorld then
		self:TakePrimaryAmmo(self.Secondary.TakeAmmo)
		
		self:SetNextReloadTime(50)
		
		self:SendWeaponAnim(ACT_VM_IDLE)
		self:SetNextPrimaryFire( CurTime() + self.Primary.Delay )
		self:SetNextSecondaryFire( CurTime() + self.Primary.Delay )
		
		self.Owner:SetAnimation(PLAYER_ATTACK1)
		
		if SERVER and IsValid(self.proj) then self.proj:Remove() end
		for _,v in pairs(ents.FindInSphere(t.HitPos, 6)) do
			if IsValid(v) and v ~= self and v:GetClass() == "splashootee" then
				v:Remove()
			end
		end
		
		self.proj = ents.Create("splat_inkmine")
		self.proj:SetModel("models/spitball_medium.mdl")
		self.proj:SetOwner(self.Owner)
		self.proj:SetColor(self.ProjColor)
		self.proj:SetPhysicsAttacker(self.Owner)
		self.proj.InkColor = self.InkColor
		self.proj.ProjColor = self.ProjColor
		self.proj.Dmg = 0
		self.proj.InkRadius = self.InkRadius
		self.proj.SplashNum = self.SplashNum
		self.proj.SplashLen = self.SplashLen
		self.proj.SplashInit = 1
		self.proj.V0 = Vector(0, 0, 1)
		self.proj.Normal = t.HitNormal
		
		self.proj:Spawn()
		
		if SERVER and self.proj:WaterLevel() > 1 then
			self.proj:Remove()
			return
		end
		
		self.proj:SetPos(t.HitPos + t.HitNormal)
		self.proj:SetAngles(-t.HitNormal:Angle())
		self.proj:SetTrigger(true)
		self.proj:DrawShadow(false)
		self.proj:SetSolid(SOLID_BBOX)
		self.proj:SetMoveType(MOVETYPE_NONE)
		self.proj:SetCollisionGroup(COLLISION_GROUP_INTERACTIVE_DEBRIS)
		self.proj:SetGravity(0)
		self.proj:SetNWBool("triggered", true)
		self.proj:SetNWVector("normal", t.HitNormal)
		self.proj:Setscale(Vector(1, 1, 1))
		self.proj:Setdelta(Vector(0, 0, 0))
		self.proj:transform(0)
	end
end

function SWEP:SecondaryAttack()
	if self.Secondary.TakeAmmo > self:Clip1() then return end
	if not self:CanPrimaryAttack() then return end
	
	self.wepAnim = ACT_VM_IDLE_LOWERED
	self:SendWeaponAnim(ACT_VM_IDLE_LOWERED)
	if self.Owner:IsNPC() then
		self:SetNextPrimaryFire( CurTime() + self.Secondary.Delay )
		self:SetNextSecondaryFire( CurTime() + self.Secondary.Delay )
		
		timer.Simple(0.5, function()
			if IsValid(self) and IsValid(self.Owner) then
				self:Throw()
				self.Owner:ClearSchedule()
			end
		end)
	else
		self.Owner:SetCurrentViewOffset(self.Owner:GetViewOffset())
		self.Owner:RemoveFlags(FL_DUCKING)
		self.throw = true
		self:SetNWBool("throw", true)
	end
end
