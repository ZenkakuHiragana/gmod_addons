
include("weapons/ai_translations.lua")
include("weapons/inklingbase.lua")

SWEP.SwingSound = {
	Sound("SplatoonSWEPs/roller/swing00.wav"),
	Sound("SplatoonSWEPs/roller/swing01.wav"),
}
SWEP.PreSwingSound = {
	Sound("SplatoonSWEPs/roller/splatpreswing00.mp3"),
}
SWEP.ShootSound = {
	Sound("SplatoonSWEPs/roller/PlayerWeaponRollerSpray00.wav"),
	Sound("SplatoonSWEPs/roller/PlayerWeaponRollerSpray01.wav"),
	Sound("SplatoonSWEPs/roller/PlayerWeaponRollerSpray02.wav"),
	Sound("SplatoonSWEPs/roller/PlayerWeaponRollerSpray03.wav"),
}
SWEP.RollSound = Sound("SplatoonSWEPs/roller/splatroll00.mp3")
SWEP.EmptyRollSound = Sound("SplatoonSWEPs/roller/splatemptyroll00.mp3")
SWEP.HolsterSound = Sound("SplatoonSWEPs/roller/holster00.mp3")
SWEP.SwingVolume = 40

SWEP.rollingpos = 0

function SWEP:Init()
	if self.Owner:IsNPC() then
		if self.Owner:GetClass() == "npc_metropolice" or self.Owner:GetClass() == "npc_citizen" then
			self.HoldType = "melee"
			self.Primary.Ammo = "smg1"
		else
			self.HoldType = "ar2"
			self.Primary.Ammo = "ar2"
		end
	end
	
	self.roll = CreateSound(self, self.RollSound)
	self.empty = CreateSound(self, self.EmptyRollSound)
	self.holster = CreateSound(self, self.HolsterSound)
	self.shoot = {}
	for i = 1, table.maxn(self.ShootSound) do
		table.insert(self.shoot, CreateSound(self, self.ShootSound[i]))
	end
end

SWEP.preposition = nil
local function roll(ply)
	if CLIENT then return end
	local w = ply:GetActiveWeapon()
	local volume = 1
	if w:GetNWInt("swing", 0) == 1 and w:GetNWInt("down", 0) == 1 then
		if ((w.preposition or w:GetPos()) - w:GetPos()):LengthSqr() > 0 then
			local width = w.RollWidth
			if ((w.preposition or w:GetPos()) - w:GetPos()):LengthSqr() < 13 then
				width = w.RollWidthSlow
				volume = 0.4
			end
			
			if w:Clip1() > 0 then
				
				for i = 1, 3 do
					local d = Vector(0, 0, 0)
					if i == 1 then
						d = ply:GetRight() * -width
					elseif i == 2 then
						d = ply:GetRight() * width
					end
					
					local starts, dir = ply:GetShootPos() + w:GetForward() * 60 + d, Vector(0, 0, -80)
					local tr, trwall = util.QuickTrace(starts, dir, {w, ply}),
						util.TraceLine({
							start = ply:GetPos() + Vector(0, 0, 25),
							endpos = starts,
							filter = {w, ply}
						})
					if trwall.Hit then
						tr.Hit = true
						tr.HitPos = trwall.HitPos
						tr.HitNormal = trwall.HitNormal
					end
					--debugoverlay.Line(starts, starts + dir, 1, Color(0, 255, 0, 255), true)
					if tr.Hit then
						dir = (tr.HitPos - ply:GetShootPos()) * 120
						local t = util.QuickTrace(ply:GetShootPos(), dir, {w, ply})
						
						--debugoverlay.Line(ply:GetShootPos(), ply:GetShootPos() + dir, 0.1, Color(0, 255, 0, 255), false)
						if t.Hit and t.Entity:GetClass() ~= "splashootee" then
							local r = ents.Create("splashootee")
							r:SetOwner(ply)
							r:SetColor(w.ProjColor)
							r:SetPos(t.HitPos + t.HitNormal)
							r.InkColor = w.InkColor
							r.Dmg = w.RollDamage
							r:Spawn()
							t.HitNormal = -t.HitNormal
							t.HitEntity = t.Entity
							r:BecomeTrigger(t, 15)
							util.BlastDamage(ply, ply, t.HitPos, 30, r.Dmg)
							
							if i == 1 and IsValid(r) then
								w.roll:PlayEx(volume, 100)
								w.empty:Stop()
								w:TakePrimaryAmmo(1, w.Primary.Ammo)
							end
						end
					end
				end
			else
				w.roll:Stop()
				w.empty:PlayEx(volume, 100)
			end
		else
			w.roll:Stop()
			w.empty:Stop()
		end
		
		w:SetNextReloadTime(w.StopReloading)
	else
		w.roll:Stop()
		w.empty:Stop()
	end
	w.preposition = w:GetPos()
end

local function RollerRoll(ply, data)
	roll(ply)
end

local function modaim(p)
	print("a")
	p:SetPoseParameter("aim_yaw", 90)
	p:SetPoseParameter("aim_pitch", 90)
	return true
end

function SWEP:AdditionalDeploy()
	if IsValid(self.Owner) and self.Owner:IsPlayer() then
		hook.Add("Move", "RollerRoll", RollerRoll)
	end
end

function SWEP:AdditionalHolster()
	
	for i = 1, table.maxn(self.shoot) do
		self.shoot[i]:Stop()
	end
	self.roll:Stop()
	self.empty:Stop()
	self.holster:Stop()
	
	self:SetNWInt("swing", 0)
	self:SetNWInt("down", 0)
	hook.Remove("Move", "RollerRoll")
	
	return true
end

if CLIENT then

	function SWEP:PreViewModelDrawn(model, bone_ent, ang, pos, v, matrix)
		
		local f = self:GetNWInt("down", 0)
		if self:GetNWInt("swing", 0) == 1 and f == 1 then--and math.Clamp((CurTime() - self:GetNWFloat("downbegins", CurTime())) / self.SwingSpeed, 0, 1) == 1 then
			local filters = ents.FindByClass("splashootee")
			table.Merge(filters, {self, self.Owner, model})
			local starts
			local w = 20
			if self.Owner:IsPlayer() then
				starts = self.Owner:GetShootPos() + self:GetForward() * 70 + Vector(0, 0, 50) + self.Owner:GetRight() * w
			else
				starts = self:GetPos() + self:GetForward() * 70 + Vector(0, 0, 60) + self.Owner:GetRight() * 30
			end
			local dir = Vector(0, 0, -1000000) + self.Owner:GetRight() * w
			local trR, trwallR = util.QuickTrace(starts, dir, filters),
				util.TraceLine({
					start = self.Owner:GetPos() + Vector(0, 0, 20),
					endpos = starts,
					filter = filters
				})
			dir = Vector(0, 0, -1000000) - self.Owner:GetRight() * w
			starts = starts - self.Owner:GetRight() * w * 2
			local trL, trwallL = util.QuickTrace(starts, dir, filters),
				util.TraceLine({
					start = self.Owner:GetPos() + Vector(0, 0, 20),
					endpos = starts,
					filter = filters
				})
				
			if trwallR.Hit or trwallL.Hit then
				trR.HitPos = trwallR.HitPos
				trR.HitNormal = trwallR.HitNormal
				trL.HitPos = trwallL.HitPos
				trL.HitNormal = trwallL.HitNormal
			end
			
			local hit = trR.HitPos
			if hit.z < trL.HitPos.z then hit = trL.HitPos end
			
			local level = (hit - self.Owner:GetPos()):Angle().pitch
			if level > 180 then level = level - 360 end
			
			ang = Angle(0,0,0)
			level = math.Clamp(level * -2, -30, 80) - 100 + self.Owner:GetAngles().pitch / 9
			ang:RotateAroundAxis(ang:Up(), self.Owner:GetAngles().yaw)
			
			ang:RotateAroundAxis(ang:Right(), level)
			
			self.rollingpos = self.rollingpos + self.Owner:GetVelocity():LengthSqr() / 4000 * self.Owner:GetVelocity():GetNormalized():Dot(self:GetForward())
			if model:LookupBone("roll_1") then
				model:ManipulateBoneAngles(model:LookupBone("roll_1"), Angle(self.rollingpos, 0, 0))
			end
			
			if self.FixAng then
				ang = ang + self.FixAng
			end
		end
		
		if f ~= 0 then
			local mul = math.Clamp((CurTime() - self:GetNWFloat("downbegins", CurTime())) * 5, 0, 1)
			if f == -1 then
				model:SetAngles(ang + Angle(60 - 60 * mul, 0, 0))
				pos.z = pos.z - self.ZDelta + self.ZDelta * mul
				if mul >= 1 then
					self:SetNWInt("down", 0)
					mul = 0
				end
			else
				model:SetAngles(ang + Angle(-60 + 60 * mul, 0, 0))
				pos.z = pos.z - self.ZDelta * mul
			end
		else
			model:SetAngles(ang)
		end
		model:SetPos(pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z )
		
		f = self:GetNWInt("swing", 0)
		if f ~= 0 then
			local mul = math.Clamp((CurTime() - self:GetNWFloat("swingbegins", CurTime())) * 5, 0, 1)
			if f == -1 then
				if model:LookupBone("neck_1") then
					model:ManipulateBoneAngles(model:LookupBone("neck_1"), Angle(0, 0, -90.0 * mul))
				end
				if mul >= 1 then
					self:SetNWInt("swing", 0)
					mul = 0
				end
			else
				if model:LookupBone("neck_1") then
					model:ManipulateBoneAngles(model:LookupBone("neck_1"), Angle(0, 0, -90.0 + 90.0 * mul))
				end
			end
		else
			if model:LookupBone("neck_1") then
				model:ManipulateBoneAngles(model:LookupBone("neck_1"), Angle(0, 0, -90.0))
			end
		end
		
		if self.InkedBodygroup then
			local a = self:Clip1() > 0
			if self.FixAng then a = not a end
			if a then
				model:SetBodygroup(self.InkedBodygroup, 0)
			else
				model:SetBodygroup(self.InkedBodygroup, 1)
			end
		end
	end

	function SWEP:PreDrawWorldModel(model, bone_ent, ang, pos, v, matrix)
		
		local isinkling = GetConVar("cl_splatoon_isinkling")
		local l = math.Clamp((CurTime() - self:GetNWFloat("downbegins", CurTime())) / self.SwingSpeed, 0, 1)
		if self:GetNWInt("swing", 0) == 1 and self:GetNWInt("down", 0) == 1 then
			local filters = ents.FindByClass("splashootee")
			table.Merge(filters, {self, self.Owner, model})
			local starts = self:GetPos()
			local w = 30
			if self.Owner:IsPlayer() then
				starts = self.Owner:GetShootPos() + self:GetForward() * 70 + Vector(0, 0, 50) + self.Owner:GetRight() * w
			elseif self.Owner:IsNPC() then
				starts = self:GetPos() + self:GetForward() * 70 + Vector(0, 0, 60) + self.Owner:GetRight() * 30
			end
			
			local dir = Vector(0, 0, -1000000) + (self.Owner or self):GetRight() * w
			local trR, trwallR = util.QuickTrace(starts, dir, filters),
				util.TraceLine({
					start = self.Owner:GetPos() + Vector(0, 0, 20),
					endpos = starts,
					filter = filters
				})
			dir = Vector(0, 0, -1000000) - self.Owner:GetRight() * w
			starts = starts - self.Owner:GetRight() * w * 2
			local trL, trwallL = util.QuickTrace(starts, dir, filters),
				util.TraceLine({
					start = self.Owner:GetPos() + Vector(0, 0, 20),
					endpos = starts,
					filter = filters
				})
				
			if trwallR.Hit or trwallL.Hit then
				trR.HitPos = trwallR.HitPos
				trR.HitNormal = trwallR.HitNormal
				trL.HitPos = trwallL.HitPos
				trL.HitNormal = trwallL.HitNormal
			end
			
			local hit = trR.HitPos
			if hit.z < trL.HitPos.z then hit = trL.HitPos end
			
			local level = (hit - self.Owner:GetPos()):Angle().pitch
			if level > 180 then level = level - 360 end
			
		--	debugoverlay.Line(starts, starts + dir, 0.1, Color(0, 255, 0, 255), true)
		--	debugoverlay.Line(self.Owner:GetPos(), trR.HitPos, 0.1, Color(0, 255, 0, 255), true)
			
			local height = (self.Owner:GetPos() - self:GetPos()):Length() * 2
			ang = Angle(0, 0, 0)
			level = math.Clamp(level * -2, -30, 46 + height) - 56 - height + self.Owner:GetAngles().pitch / 9
			ang:RotateAroundAxis(ang:Up(), self.Owner:GetAngles().yaw)
			
			ang:RotateAroundAxis(ang:Right(), level)
			
			self.rollingpos = self.rollingpos + self.Owner:GetVelocity():LengthSqr() / 4000 * 
				self.Owner:GetVelocity():GetNormalized():Dot(self:GetForward())
			if model:LookupBone("roll_1") then
				model:ManipulateBoneAngles(model:LookupBone("roll_1"), Angle(self.rollingpos, 0, 0))
			end
			
			if isinkling:GetInt() == 1 and self.Owner:IsPlayer() then
				self.Owner:ManipulateBoneAngles(self.Owner:LookupBone("ValveBiped.Bip01_Spine"),
				Angle(10, -20, -30))
			end
			
			if self.FixAng then
				ang = ang + self.FixAng
			end
		else
			if isinkling:GetInt() == 1 and self.Owner:IsPlayer() then
				self.Owner:ManipulateBoneAngles(self.Owner:LookupBone("ValveBiped.Bip01_Spine"),
				Angle(0, 0, 0))
			end
			
			local f = self:GetNWInt("down", 0)
			if self.Owner:IsNPC() and f == -1 and self:GetNWInt("swing", 0) == -1 then
				ang.roll = ang.roll - 90 + 90 * l
			end
		end
		
		if self.InkedBodygroup then
			local a = self:Clip1() > 0
			if self.FixAng then a = not a end
			if a then
				model:SetBodygroup(self.InkedBodygroup, 0)
			else
				model:SetBodygroup(self.InkedBodygroup, 1)
			end
		end
		
		local f = self:GetNWInt("swing", 0)
		if f ~= 0 then
			local mul = math.Clamp((CurTime() - self:GetNWFloat("swingbegins", CurTime())) * 5, 0, 1)
			if f == -1 then
				if model:LookupBone("neck_1") then
					model:ManipulateBoneAngles(model:LookupBone("neck_1"), Angle(0, 0, -90.0 * mul))
				end
				if mul >= 1 then
					self:SetNWInt("swing", 0)
					mul = 0
				end
			else
				if model:LookupBone("neck_1") then
					model:ManipulateBoneAngles(model:LookupBone("neck_1"), Angle(0, 0, -90.0 + 90.0 * mul))
				end
			end
		else
			if model:LookupBone("neck_1") then
				model:ManipulateBoneAngles(model:LookupBone("neck_1"), Angle(0, 0, -90.0))
			end
		end
		
		model:SetPos(pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z )
		model:SetAngles(ang)
	end
	
	function SWEP:GetViewModelPosition(p, a)
		local dp, da = Vector(5, 5, 7), Angle(0, -3, 0)
		local mul = math.Clamp((CurTime() - self:GetNWFloat("swingbegins", CurTime())) * 8, 0, 1)
		dp:Rotate(a)
		
		local f = self:GetNWInt("swing", 0)
		if f ~= 0 then
			if f == -1 then
				if mul >= 1 then
					self:SetNWInt("swing", 0)
					return p, a
				end
				return p + dp - dp * mul, a + da - da * mul
			else
				return p + dp * mul, a + da * mul
			end
		else
			return p, a
		end
	end
end

local function disarm(self)
	self:SetNWInt("swing", -1)
	self:SetNWInt("down", -1)
	self:SetNWFloat("swingbegins", CurTime())
	self:SetNWFloat("downbegins", CurTime())
	self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
	self.holster:Play()
	timer.Simple(0.5, function()
		if not IsValid(self) then return end
		self.holster:Stop()
	end)
	
	timer.Simple(self.Primary.Delay, function()
		if IsValid(self) and IsValid(self.Owner) then
			self:SetNWInt("swing", 0)
			self:SetNWInt("down", 0)
		end
	end)
end

local function rollerthink(self)
	if self:GetNWInt("swing", 0) == 1 and self:GetNWInt("down", 0) == 1 then
		if math.Clamp((CurTime() - self:GetNWFloat("downbegins", CurTime())) * 5, 0, 1) > 0.9 and
			self.Owner:IsPlayer() and not self.Owner:KeyDown(IN_ATTACK) then
			self:SendWeaponAnim(ACT_VM_IDLE)
			disarm(self)
		elseif self.Owner:IsNPC() then
			if not timer.Exists("disarm" .. self.Owner:EntIndex()) then
				timer.Create("disarm" .. self.Owner:EntIndex(), math.random() * 5, 1, function()
					if not IsValid(self) then return end
					disarm(self)
				end)
			else
				roll(self.Owner)
				if self:Clip1() < self.Primary.ClipSize / 10 then
					self.Owner:ClearSchedule()
					self.Owner:SetSchedule(SCHED_RELOAD)
				end
			end
		end
	end
end

function SWEP:IsSquid(isinkling)
	self:SetNWInt("swing", 0)
	self:SetNWInt("down", 0)
	
	rollerthink(self)
end

function SWEP:IsInkling(isinkling)
	
	if self.Owner:IsPlayer() then
		if self.wepAnim ~= ACT_VM_IDLE and not self.throw then
			self.holster:Play()
			timer.Simple(0.5, function()
				if not IsValid(self) then return end
				self.holster:Stop()
			end)
		end
		
		if self:GetNWInt("swing", 0) == 1 and self:GetNWInt("down", 0) ~= 1 then
			self.Owner:SetWalkSpeed(self.FiringSpeed / 4)
			self.Owner:SetRunSpeed(self.FiringSpeed / 4)
		elseif self:GetNWInt("down", 0) == 1 then
			self.Owner:SetWalkSpeed(self.FiringSpeed)
			self.Owner:SetRunSpeed(self.FiringSpeed)
		else
			self.Owner:SetWalkSpeed(230)
			self.Owner:SetRunSpeed(230)
		end
	end
	
	rollerthink(self)
end

function SWEP:ClientThink(throw)
	if self:GetNWInt("swing", 0) == 1 and self:GetNWInt("down", 0) == 1 then
		self.Owner:AddVCDSequenceToGestureSlot(GESTURE_SLOT_ATTACK_AND_RELOAD, 326, 0.56, true)
	end
end

function SWEP:paint()
	
	if CLIENT then return end
	
	self:EmitSound(self.SwingSound[math.random(1, table.maxn(self.SwingSound))], self.SwingVolume)
	local num = math.random(1, table.maxn(self.shoot))
	self.shoot[num]:Stop()
	self.shoot[num]:Play()
	
	for _ = 1, self.SwingNum do
		self.ShootCount = self.ShootCount + 1
		if self.ShootCount % self.SplashPattern < 4 then
			self.ShootCount = 4
		end
		
		local proj = ents.Create("splashootee")
		local proforce = (self.Owner:GetAimVector() +
			(VectorRand() * self.Primary.Spread)):GetNormalized() * self.PrimaryVelocity * math.Rand(0.5, 1)
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
		proj.SplashInit = self.FallTimer / 2000 * self.V0
		proj.V0 = self.V0
		proj.r = 2
		
		proj:Setscale(Vector(6, 3, 0.5))
		proj:Setink(self.InkColor)
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
		
		for i = 1, 2 do
			local splat = ents.Create("splashootee")
			splat:SetModel("models/spitball_medium.mdl")
			splat:SetOwner(self.Owner)
			splat:SetColor(self.ProjColor)
			splat:SetPos(self.Owner:GetShootPos() + self.Owner:GetForward() * self.Forward + self.Owner:GetRight() * self.Right + self.Owner:GetUp() * self.Upward)
			splat:SetAngles(self.Owner:EyeAngles())
			splat:SetPhysicsAttacker(self.Owner)
			splat.InkColor = self.InkColor
			splat.Dmg = self.BlastDamage
			splat.InkRadius = self.InkRadius
			splat.SplashNum = self.SplashNum
			splat.SplashLen = self.SplashLen
			splat.SplashInit = self.FallTimer / 2000 * self.V0
			splat.V0 = self.V0
			splat:SetNoDraw(true)
			splat:Spawn()
			splat.r = 2
			
			splat:Setscale(Vector(6, 3, 0.5))
			splat:Setink(self.InkColor)
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
	
	
	--if self.ShootCount % self.SplashPattern == 0 then
	--	local p = ents.Create("splashootee")
	--	p:SetModel("models/spitball_small.mdl")
	--	p:SetOwner(self.Owner)
	--	p:SetColor(self.ProjColor)
	--	p:SetPos(self.Owner:GetShootPos())
	--	p:SetAngles(self.Owner:EyeAngles())
	--	p:SetPhysicsAttacker(self.Owner)
	--	p.InkColor = self.InkColor
	--	p.Dmg = 0
	--	p.InkRadius = self.InkRadius
	--	p.SplashNum = self.SplashNum
	--	p.SplashLen = self.SplashLen
	--	p:SetNoDraw(true)
	--	p:Spawn()
	--	
	--	local ph = p:GetPhysicsObject()
	--	if not (ph and IsValid(ph)) then
	--		p:Remove()
	--		return
	--	end
	--	ph:ApplyForceCenter(Vector(0, 0, 0))
	--end
	
	self:TakePrimaryAmmo(self.Primary.TakeAmmo, self.Primary.Ammo)
	self:SetNextReloadTime(self.StopReloading)
end

function SWEP:PrimaryAttack()
	if not IsValid(self) or not IsValid(self.Owner) then return end
 	if not self:CanPrimaryAttack() then return end
 	
	if self.Owner:IsNPC() and self:GetNWInt("down", 0) ~= 0 then
		disarm(self)
	end
	if self:GetNWInt("swing", 0) == 0 then
		self:SetNWInt("swing", 1)
		self:SetNWFloat("swingbegins", CurTime())
		if SERVER and self.Owner:IsPlayer() then
			self:SetNextReloadTime(self.StopReloading)
			self.Owner:SetCurrentViewOffset(self.Owner:GetViewOffset())
			self.Owner:RemoveFlags(FL_DUCKING)
			self.Owner:SetDuckSpeed(math.huge)
			if not timer.Exists("swinganim" .. self:EntIndex()) then
				self:EmitSound(self.PreSwingSound[math.random(1, table.maxn(self.PreSwingSound))])
				timer.Create("swinganim" .. self:EntIndex(), self.SwingSpeed - 0.1, 1, function()
					if IsValid(self) and IsValid(self.Owner) then
						self.Owner:SendLua("LocalPlayer():AddVCDSequenceToGestureSlot(GESTURE_SLOT_ATTACK_AND_RELOAD, 326, 0, true)")
					end
				end)
			end
		end
		
		if not timer.Exists("swing_down" .. self:EntIndex()) then
			timer.Create("swing_down" .. self:EntIndex(), self.SwingSpeed, 1, function()
				if IsValid(self) and IsValid(self.Owner) and self:GetNWInt("swing", 0) == 1 then
					self:SendWeaponAnim(ACT_VM_HOLSTER)
					self:SetNWInt("down", 1)
					self:SetNWFloat("downbegins", CurTime())
					self:paint()
					if self.Owner:IsPlayer() then
						self.Owner:SetDuckSpeed(0.1)
					end
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
