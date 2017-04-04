--SubWeapon: Squid Beakon
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"
SWEP.Secondary.TakeAmmo = SWEP.Primary.ClipSize * 0.90
SWEP.Secondary.Delay = 0.4

SWEP.proj = nil
local BEAKON_MAX = 4

local function createink(self, t)
	if t.Hit then
		if t.HitWorld then
			local p = ents.Create("splashootee")
			p:SetModel("models/spitball_small.mdl")
			p:SetOwner(self.Owner)
			p:SetColor(self.ProjColor)
			p:SetPhysicsAttacker(self.Owner)
			p.InkColor = self.InkColor
			p.Dmg = 0
			p.InkRadius = self.InkRadius
			p.SplashNum = self.SplashNum
			p.SplashLen = self.SplashLen
			p:SetNoDraw(true)
			p:Spawn()
			p:BecomeTrigger({
				HitPos = t.HitPos,
				HitNormal = -t.HitNormal
			})
		else
			--if IsValid(t.HitEntity) then
				util.Decal("Ink" .. self.InkColor, t.HitPos + t.HitNormal, t.HitPos - t.HitNormal)
			--end
		end
	end
end

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
		
		self.beakoncount = self.beakoncount or 0
		self.proj = self.proj or {}
		if IsValid(self.proj[((self.beakoncount + 1) % BEAKON_MAX) + 1]) then
			self.proj[((self.beakoncount + 1) % BEAKON_MAX) + 1]:Remove()
		end
		
		local proj = ents.Create("splat_beakon")
		proj.Owner = self.Owner
		proj.InkColor = self.InkColor
		proj.ProjColor = self.ProjColor
		proj:SetC(Vector(self.ProjColor.r / 255, self.ProjColor.g / 255, self.ProjColor.b / 255))
		local a = t.HitNormal:Angle()
		a.pitch = a.pitch + 90
		proj:SetPos(t.HitPos)
		proj:SetAngles(a)
		proj:Spawn()
		
		if SERVER and proj:WaterLevel() > 1 then
			proj:Remove()
			return
		end
		createink(self, t)
		
		self.proj[(self.beakoncount % BEAKON_MAX) + 1] = proj
		self.beakoncount = self.beakoncount + 1
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
