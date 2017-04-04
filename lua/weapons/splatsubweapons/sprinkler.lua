--SubWeapon: Sprinkler
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"
SWEP.Secondary.TakeAmmo = SWEP.Primary.ClipSize * 0.7
SWEP.Secondary.Delay = 0.4

SWEP.proj = nil

function SWEP:Throw()
	self.throw = false
	if self.Secondary.TakeAmmo > self:Clip1() then return end
	
	self:TakePrimaryAmmo(self.Secondary.TakeAmmo)
	
	self:SetNextReloadTime(50)
	
	local f, up = 0, 0
	local pos = self.Owner:GetForward() * self.Forward * -3 + self.Owner:GetRight() * self.Right + self.Owner:GetUp() * self.Upward
	if self.Owner:IsNPC() then
		f = 50000
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
		
		pos = pos + self.Owner:GetShootPos()
	else
		self:SendWeaponAnim(ACT_VM_IDLE)
		self:SetNextPrimaryFire( CurTime() + self.Secondary.Delay )
		self:SetNextSecondaryFire( CurTime() + self.Secondary.Delay )
		
		self.Owner:SetAnimation(PLAYER_ATTACK1)
		timer.Simple(0.6, function()
			self:SetNWBool("throw", false)
		end)
		
		f = 18000
		pos = pos + self.Owner:GetPos() + Vector(0, 0, 42)
	end
	
	self.proj = ents.Create("splat_sprinkler")
	self.proj:SetOwner(self.Owner)
	self.proj:SetC(Vector(self.ProjColor.r / 255, self.ProjColor.g / 255, self.ProjColor.b / 255))
	self.proj:SetPos(pos)
	self.proj:SetAngles(self.Owner:EyeAngles())
	self.proj:SetPhysicsAttacker(self.Owner)
	self.proj.InkColor = self.InkColor
	self.proj.ProjColor = self.ProjColor
	self.proj:Spawn()

	local ph = self.proj:GetPhysicsObject()
	if not (ph and IsValid(ph)) then
		self.proj:Remove()
		return
	end
	ph:ApplyForceOffset((self.Owner:GetAimVector() + Vector(0, 0, up)):GetNormalized() * f, ph:GetPos() + VectorRand())
	
	timer.Simple(0.8, function()
		if IsValid(ph) and not self.proj.touchflag then
			local z = ph:GetVelocity().z
			if z > 0 then z = -z / 5 end
			ph:SetAngles(Angle(0, 0, 0))
			ph:SetVelocity(Vector(0, 0, z))
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
