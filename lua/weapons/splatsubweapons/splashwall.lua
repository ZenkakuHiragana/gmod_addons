--SubWeapon: Splash shield
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"
SWEP.Secondary.TakeAmmo = SWEP.Primary.ClipSize * 0.6
SWEP.Secondary.Delay = 0.4
SWEP.Shield = nil

function SWEP:Throw()
	self.throw = false
	if self.Secondary.TakeAmmo > self:Clip1() then return end
	
	self:SetNextReloadTime(50)
	
	local f, up = 0, 0
	if self.Owner:IsNPC() then
		f = 20000
		if IsValid(self.Owner:GetEnemy()) then
			f = (self.Owner:GetEnemy():GetPos() - self.Owner:GetPos()):Length() * 80
			if f > 50000 then
				f = 28000
			end
			
			up = (self.Owner:GetEnemy():GetPos().z - self.Owner:GetPos().z) / 1000
			if up > 10 then
				up = 10
			end
		end
	else
		self:SendWeaponAnim(ACT_VM_IDLE)
		self:SetNextPrimaryFire( CurTime() + self.Secondary.Delay )
		self:SetNextSecondaryFire( CurTime() + self.Secondary.Delay )
		
		self.Owner:SetAnimation(PLAYER_ATTACK1)
		timer.Simple(0.6, function()
			self:SetNWBool("throw", false)
		end)
		
		up = 0.08
		f = 20000
	end
	if IsValid(self.Shield) then return end
	self:TakePrimaryAmmo(self.Secondary.TakeAmmo)
	
	local proj = ents.Create("splat_splashwall")
	proj:SetOwner(self.Owner)
	proj:SetC(Vector(self.ProjColor.r / 255, self.ProjColor.g / 255, self.ProjColor.b / 255))
	proj:SetPhysicsAttacker(self.Owner)
	proj.InkColor = self.InkColor
	proj.ProjColor = self.ProjColor
	proj:SetPos(self.Owner:GetPos() + self.Owner:GetForward() * 20 + Vector(0, 0, 10))
	proj:SetAngles(Angle(0, self.Owner:GetAngles().yaw, 0))
	proj:Spawn()
	self.Shield = proj

	local ph = proj:GetPhysicsObject()
	if not (ph and IsValid(ph)) then
		proj:Remove()
		return
	end
	ph:ApplyForceCenter(Vector(self.Owner:GetForward().x, self.Owner:GetForward().y, up):GetNormalized() * f)
	
	timer.Simple(0.8, function()
		if IsValid(ph) and not proj.touchflag then
			local z = ph:GetVelocity().z
			if z > 0 then z = -z / 5 end
			ph:SetAngles(Angle(0, 0, 0))
			ph:SetVelocityInstantaneous(Vector(0, 0, z))
		end
	end)
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
