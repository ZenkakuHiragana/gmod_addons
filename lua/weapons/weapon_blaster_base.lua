
SWEP.Base = "weapon_splat_base"

function SWEP:Think()
	self.BaseClass.Think(self)
	if IsValid(self) and IsValid(self.Owner) then
		if self.Owner:IsPlayer() then
			if self.Owner:GetDuckSpeed() > 100 then
				self.Owner:RemoveFlags(FL_DUCKING)
				self.Owner:SetWalkSpeed(self.FiringSpeed)
				self.Owner:SetRunSpeed(self.FiringSpeed)
				
				if CLIENT then
					self:SetWeaponHoldType(self.HoldType)
				end
			end
			
		end
	end
end

function SWEP:paint()
	
	if CLIENT or (not IsValid(self)) or (not IsValid(self.Owner)) then return end
	
	local proj = ents.Create("splatblaster_projectile")
	local proforce = self.Owner:GetAimVector() * self.PrimaryVelocity
	
	proj:Setscale(Vector(5, 5, 5))
	proj:SetModel("models/spitball_large.mdl")
	proj.Owner = self.Owner
	proj:SetColor(self.ProjColor)
	proj:SetPos(self.Owner:GetShootPos() + self.Owner:GetForward() * self.Forward + self.Owner:GetRight() * self.Right + self.Owner:GetUp() * self.Upward)
	proj:SetAngles(self.Owner:EyeAngles())
	proj:SetPhysicsAttacker(self.Owner)
	proj.Radius = self.Radius
	proj.ProjColor = self.ProjColor
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
	ph:EnableGravity(false)
	ph:ApplyForceCenter(proforce)
	
	timer.Simple(self.FallTimer / 1000, function()
		if IsValid(proj) and IsValid(self) then
			local o = proj.Owner or proj
			util.BlastDamage(o, o, proj:GetPos(), proj.Radius, proj.Dmg)
			
			local e = EffectData()
			e:SetAngles(proj:GetAngles())
			e:SetEntity(proj)
			e:SetFlags(0)
			e:SetOrigin(proj:GetPos())
			e:SetRadius(proj.Radius)
			e:SetScale(10)
			e:SetStart(proj:GetPos())
			util.Effect("HelicopterMegaBomb", e)
			proj:Explode()
		end
	end)
	
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

function SWEP:PrimaryAttack()
	self.BaseClass.PrimaryAttack(self)
	if not IsValid(self) or not IsValid(self.Owner) then return end
 	if not self:CanPrimaryAttack() then return end
	
	if self.Owner:IsPlayer() then
		self.Owner:SetDuckSpeed(math.huge)
		timer.Simple(self.FreezeTime / 60, function()
			if IsValid(self) and IsValid(self.Owner) then
				self.Owner:SetDuckSpeed(0.1)
			end
		end)
	end
end
