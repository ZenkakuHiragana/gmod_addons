--[[
	Inkbrush Nouveau is a weapon in Splatoon.
]]

SWEP.Author = "Himajin Jichiku"
SWEP.Contact = "none"
SWEP.Purpose = "Splatoon's Inkbrush Nouveau beta"
SWEP.Instructions = "Left Click to Fire, Crouch to dive."
SWEP.Category = "GreatZenkakuMan's Splatoon SWEPs"

--SWEP.WepSelectIcon = surface.GetTextureID("weapons/smg1")

SWEP.Spawnable = true
SWEP.AdminSpawnable = true

--SWEP.InkColor = "Blue"		--Ink Color. Only can swim in the same Ink Color.
--SWEP.ProjColor = Color(0,0,255,255)
SWEP.InkColor = "Purple"		--Ink Color. Only can swim in the same Ink Color.
SWEP.ProjColor = Color(128,0,255,255)
SWEP.inInk = false			--Whether Owner is swimming or not.
SWEP.SwimSpeed = 40
SWEP.ReloadSpeed = 0.06
SWEP.RelInk = 1
SWEP.HealSpeed = 0.01
SWEP.BlastDamage = 28

SWEP.Forward = 20	--Projectile spawns
SWEP.Right = 0
SWEP.Upward = 0
SWEP.PrimaryVelocity = 30000
SWEP.SplashNum = 3		--Projectiles splash count
SWEP.SplashLen = 100		--The length between splashes
SWEP.SplashPattern = 6
SWEP.V0 = 600
SWEP.ZDelta = -3
SWEP.InkRadius = 50
SWEP.FallTimer = 210
SWEP.FiringSpeed = 700
SWEP.StopReloading = 45		--Stop reloading several frames after firing weapon.
SWEP.FreezeTime = 30
SWEP.ShootCount = 0

SWEP.Primary.ClipSize = 50
SWEP.Primary.DefaultClip = 50
SWEP.Primary.Automatic = false
SWEP.Primary.Recoil = 1.5
SWEP.Primary.Delay = 0.1
SWEP.Primary.Spread = 0.2
SWEP.Primary.Ammo = "HelicopterGun"
SWEP.Primary.TakeAmmo = 1
SWEP.Primary.Splash1 = 0.055
SWEP.Primary.Splash2 = 0.036

local ShootSound = Sound("Breakable.Flesh")

SWEP.PrintName = "Inkbrush Nouveau"
SWEP.Slot = 0
SWEP.SlotPos = 4
SWEP.DrawAmmo = true
SWEP.DrawCrosshair = true

SWEP.AutoSwitchTo = false
SWEP.AutoSwitchFrom = false

SWEP.HoldType = "melee2"
SWEP.ViewModelFOV = 70
SWEP.ViewModelFlip = false
SWEP.UseHands = true
SWEP.ViewModel = "models/weapons/c_357.mdl"
SWEP.WorldModel = "models/weapons/w_grenade.mdl"
SWEP.ShowViewModel = true
SWEP.ShowWorldModel = false
SWEP.ViewModelBoneMods = {
	["ValveBiped.Bip01_L_Finger31"] = { scale = Vector(1, 1, 1), pos = Vector(0, 0, 0), angle = Angle(7, 0, 0) },
	["Bullet3"] = { scale = Vector(0.009, 0.009, 0.009), pos = Vector(0, 0, 0), angle = Angle(0, 0, 0) },
	["ValveBiped.Bip01_L_Finger11"] = { scale = Vector(1, 1, 1), pos = Vector(0, 0, 0), angle = Angle(0, -15, 0) },
	["Bullet6"] = { scale = Vector(0.009, 0.009, 0.009), pos = Vector(0, 0, 0), angle = Angle(0, 0, 0) },
	["ValveBiped.Bip01_L_UpperArm"] = { scale = Vector(1, 1, 1), pos = Vector(2, -1.5, -0.164), angle = Angle(0, 0, 0) },
	["ValveBiped.Bip01_L_Finger42"] = { scale = Vector(1, 1, 1), pos = Vector(0, 0, 0), angle = Angle(0, -90, 0) },
	["ValveBiped.Bip01_L_Finger2"] = { scale = Vector(1, 1, 1), pos = Vector(0, 0, 0), angle = Angle(0, -20, 0) },
	["ValveBiped.Bip01_L_Finger22"] = { scale = Vector(1, 1, 1), pos = Vector(0, 0, 0), angle = Angle(0, -90, 0) },
	["Bullet1"] = { scale = Vector(0.009, 0.009, 0.009), pos = Vector(0, 0, 0), angle = Angle(0, 0, 0) },
	["ValveBiped.Bip01_L_Hand"] = { scale = Vector(1, 1, 1), pos = Vector(0, 0, 0), angle = Angle(0, 0, 50) },
	["Bullet4"] = { scale = Vector(0.009, 0.009, 0.009), pos = Vector(0, 0, 0), angle = Angle(0, 0, 0) },
	["ValveBiped.Bip01_L_Finger1"] = { scale = Vector(1, 1, 1), pos = Vector(0, 0, 0), angle = Angle(-10, -15, 0) },
	["ValveBiped.Bip01_L_Finger21"] = { scale = Vector(1, 1, 1), pos = Vector(0, 0, 0), angle = Angle(-10, 0, 0) },
	["ValveBiped.Bip01_L_Finger41"] = { scale = Vector(1, 1, 1), pos = Vector(0, 0, 0), angle = Angle(30, 0, 0) },
	["Bullet5"] = { scale = Vector(0.009, 0.009, 0.009), pos = Vector(0, 0, 0), angle = Angle(0, 0, 0) },
	["ValveBiped.Bip01_L_Finger4"] = { scale = Vector(1, 1, 1), pos = Vector(0, 0, 0), angle = Angle(1, -5, 0) },
	["Python"] = { scale = Vector(0.009, 0.009, 0.009), pos = Vector(0, 0, 0), angle = Angle(0, 0, 0) },
	["ValveBiped.Bip01_R_Finger12"] = { scale = Vector(1, 1, 1), pos = Vector(0, 0, 0), angle = Angle(-10, -75, 0) },
	["ValveBiped.Bip01_L_Finger12"] = { scale = Vector(1, 1, 1), pos = Vector(0, 0, 0), angle = Angle(-10, -75, 0) },
	["ValveBiped.Bip01_L_Finger32"] = { scale = Vector(1, 1, 1), pos = Vector(0, 0, 0), angle = Angle(0, -90, 0) },
	["Bullet2"] = { scale = Vector(0.009, 0.009, 0.009), pos = Vector(0, 0, 0), angle = Angle(0, 0, 0) },
	["ValveBiped.Bip01_L_Finger3"] = { scale = Vector(1, 1, 1), pos = Vector(0, 0, 0), angle = Angle(0, -20, 0) },
	["ValveBiped.Bip01_R_Finger1"] = { scale = Vector(1, 1, 1), pos = Vector(0, 0, 0), angle = Angle(3, -20, 0) },
	["ValveBiped.Bip01_Spine4"] = { scale = Vector(1, 1, 1), pos = Vector(0, -3, -4), angle = Angle(10, 0, 0) }
}

SWEP.VElements = {
	["element_name"] = {
	type = "Model",
	model = "models/props_splatoon/weapons/primaries/inkbrush/inkbrush.mdl",
	bone = "ValveBiped.Bip01_R_Hand",
	rel = "",
	pos = Vector(2.5, -2.5, -15),
	angle = Angle(0, -90, 180),
	size = Vector(0.5, 0.5, 0.5),
	color = SWEP.ProjColor,
	surpresslightning = false,
	material = "",
	skin = 1,
	bodygroup = {}
	}
}

SWEP.WElements = {
	["element_name"] = {
	type = "Model",
	model = "models/props_splatoon/weapons/primaries/inkbrush/inkbrush.mdl",
	bone = "ValveBiped.Bip01_R_Hand",
	rel = "", 
	pos = Vector(33, -3, -8),
	angle = Angle(-80, 100, 180),
	size = Vector(1, 1, 1),
	color = SWEP.ProjColor,
	surpresslightning = false,
	material = "",
	skin = 1,
	bodygroup = {}
	}
}
------------------------------------------------------------------

include("weapons/splatsubweapons/inkmine.lua")
AddCSLuaFile("weapons/splatsubweapons/inkmine.lua")

include("weapons/ai_translations.lua")

local ShootSound = Sound("Breakable.Flesh")
SWEP.stoptime = 0
SWEP.rollingpos = 0
SWEP.rollconsume = 0

SWEP.healname = ""
SWEP.reloadname = ""
SWEP.inklingname = ""

/********************************************************
	SWEP Construction Kit base code
		Created by Clavus
	Available for public use, thread at:
	   facepunch.com/threads/1032378
	   
	   
	DESCRIPTION:
		This script is meant for experienced scripters 
		that KNOW WHAT THEY ARE DOING. Don't come to me 
		with basic Lua questions.
		
		Just copy into your SWEP or SWEP base of choice
		and merge with your own code.
		
		The SWEP.VElements, SWEP.WElements and
		SWEP.ViewModelBoneMods tables are all optional
		and only have to be visible to the client.
********************************************************/

local function SetBullseye(wep)
	if GetConVar("ai_disabled"):GetInt() == 1 then return end
	
	if not IsValid(wep) or not IsValid(wep.Owner) then
		return
	end
	
	if SERVER and IsValid(wep) and IsValid(wep.Owner) then
		if not IsValid(wep.Owner:GetEnemy()) then
			local e
			
			for _, v in pairs(ents.FindByClass("splashootee")) do
				if v.InkColor ~= wep.InkColor then
					if IsValid(e) then
						if e:GetPos():Distance(wep.Owner:GetPos()) > v:GetPos():Distance(wep.Owner:GetPos()) then
							e = v
						end
					else
						e = v
					end
				end
			end
			
			wep.Owner:SetNPCState(NPC_STATE_COMBAT)
			if IsValid(e) then
				
				local flag = false
				for _,v in pairs(ents.FindInSphere(e:GetPos(), 0.1)) do
					flag = flag or (v:GetClass() == "npc_bullseye")
				end
				
				if not flag then
					local tr = ents.Create("npc_bullseye")
					tr:SetPos(e:GetPos() + e:GetUp() * 80)
					tr:Spawn()
					
					wep.Owner:SetLastPosition(e:GetPos())
					wep.Owner:SetEnemy()
					wep.Owner:UpdateEnemyMemory(tr, tr:GetPos())
					wep.Owner:SetSchedule(SCHED_CHASE_ENEMY)
				end
			else
			
				if math.random() > 0.45 then
					local point, isFarFromInk
					local x, y = (math.random() * 2) - 1, (math.random() * 2) - 1
					point = wep:GetPos() + Vector(x, y, 0.03) * wep.V0 * wep.FallTimer / 500
					isFarFromInk = true
					for i = 1, 200 do
						if math.abs(x) < 0.05 and math.abs(y) < 0.05 then
							x, y = (math.random() * 2) - 1, (math.random() * 2) - 1
							point = wep:GetPos() + Vector(x, y, 0.03) * wep.V0 * wep.FallTimer / 500
						else
							for _,v in pairs(ents.FindInSphere(point, 15)) do
								if v:GetClass() == "splashootee" and v.InkColor == wep.InkColor then
									isFarFromInk = false
								end
							end
							
							if not isFarFromInk then
								x, y = (math.random() * 2) - 1, (math.random() * 2) - 1
								point = wep:GetPos() + Vector(x, y, 0.03) * wep.V0 * wep.FallTimer / 500
							else
								break
							end
						end
					end
					
					if isFarFromInk then
						local tr = ents.Create("npc_bullseye")
						tr:SetPos(point)
						tr:Spawn()
						
						wep.Owner:SetLastPosition(point)
						wep.Owner:SetEnemy()
						wep.Owner:UpdateEnemyMemory(tr, tr:GetPos())
						wep.Owner:SetSchedule(SCHED_CHASE_ENEMY)
						SafeRemoveEntityDelayed(tr, 4)
					else
						wep.Owner:SetSchedule(SCHED_PATROL_RUN)
					end
				end
			end
		else
			
			if wep.Owner:IsMoving() and not (wep:GetNWInt("swing", 0) == 1 and wep:GetNWInt("down", 0) >= 1) or
				wep.Owner:HasCondition(COND_LOST_ENEMY) then
				wep:PrimaryAttack()
				timer.Simple(0.3, function()
					if IsValid(wep) then
						wep:SetNWInt("swing", 1)
						wep:SetNWInt("down", 1)
						
					end
				end)
				
				if wep.Owner:HasCondition(COND_LOST_ENEMY) then
					wep.Owner:SetSchedule(SCHED_PATROL_RUN)
				end
			end
			
			if wep.Owner:GetEnemy():GetClass() == "npc_bullseye" then
				local flag = false
				
				for _, v in pairs(ents.FindInSphere(wep.Owner:GetEnemy():GetPos(), 0.5)) do
					flag = flag or not (v:GetClass() == "splashootee" and v.InkColor ~= wep.InkColor)
					if flag then
						break
					end
				end
				flag = flag and (wep.Owner:GetEnemy():GetPos() - wep.Owner:GetPos()):Length() < wep.V0 * wep.FallTimer / 1000
				
				if flag then
					SafeRemoveEntityDelayed(wep.Owner:GetEnemy(), 2)
				end
				
				if wep.Owner:IsCurrentSchedule(SCHED_CHASE_ENEMY) then
					wep:PrimaryAttack()
				end
			end
		end
	end
end

local function ReloadInk(wep)
	if CurTime() > wep.stoptime and wep:Clip1() < wep.Primary.ClipSize then
		local a = wep:Clip1() + (wep.RelInk or 1)
		if a > wep.Primary.ClipSize then a = wep.Primary.ClipSize end
		
		wep:SetClip1(a)
	end
end

local function Heal(wep)
	if IsValid(wep) and IsValid(wep.Owner) then
		if wep.Owner:Health() < 100 then
			wep.Owner:SetHealth(wep.Owner:Health() + 1)
		end
	else
		timer.Destroy("healing")
	end
end

function SWEP:Initialize()

	// other initialize code goes here

	if CLIENT then
		
		// Create a new table for every weapon instance
		self.VElements = table.FullCopy( self.VElements )
		self.WElements = table.FullCopy( self.WElements )
		self.ViewModelBoneMods = table.FullCopy( self.ViewModelBoneMods )

		self:CreateModels(self.VElements) // create viewmodels
		self:CreateModels(self.WElements) // create worldmodels
		
		// init view model bone build function
		if IsValid(self.Owner) and self.Owner:IsPlayer() then
			local vm = self.Owner:GetViewModel()
			if IsValid(vm) then
				self:ResetBonePositions(vm)
				
				// Init viewmodel visibility
				if (self.ShowViewModel == nil or self.ShowViewModel) then
					vm:SetColor(Color(255,255,255,255))
				else
					// we set the alpha to 1 instead of 0 because else ViewModelDrawn stops being called
					vm:SetColor(Color(255,255,255,1))
					// ^ stopped working in GMod 13 because you have to do Entity:SetRenderMode(1) for translucency to kick in
					// however for some reason the view model resets to render mode 0 every frame so we just apply a debug material to prevent it from drawing
					vm:SetMaterial("Debug/hsv")			
				end
			end
		end
	elseif self.Owner:IsNPC() then
		if not timer.Exists(self.inklingname) then
			self.inklingname = "inkling" .. self:EntIndex()
			timer.Create(self.inklingname, 0.5, 0, function() SetBullseye(self) end)
		end
		
		self.Owner:AddRelationship("npc_bullseye D_HT 01")
		self:SetSaveValue("m_fMaxRange1", self.V0 * self.FallTimer / 500)
		self:SetSaveValue("m_fMaxRange2", self.V0 * self.FallTimer / 500)
		self:SetSaveValue("m_fMinRange1", 20)
		self:SetSaveValue("m_fMinRange2", 20)
		
		self.Primary.Recoil = 0
		if self.Owner:GetClass() == "npc_metropolice" or self.Owner:GetClass() == "npc_citizen" then
			self.HoldType = "melee"
			self.Primary.Ammo = "smg1"
		else
			self.HoldType = "ar2"
			self.Primary.Ammo = "ar2"
		end
		
		timer.Create("think" .. self:EntIndex(), 0.1, 0, function()
			if IsValid(self) and IsValid(self.Owner) then
				self.reload = self.ReloadSpeed
				self.heal = self.HealSpeed
				self:Think()
			end
		end)
	end
	
	self:SetWeaponHoldType(self.HoldType)
end

local function roll(ply)
	local w = ply:GetActiveWeapon()
	if w:GetNWInt("swing", 0) == 1 and w:GetNWInt("down", 0) >= 1 and
		math.Clamp((CurTime() - w:GetNWFloat("downbegins", CurTime())) * 7, 0, 4) >= 4 and
		w:Clip1() > 0 then
		
		if ply:GetVelocity():LengthSqr() > 1000 then
			
			local starts, dir = ply:GetShootPos() + w:GetForward() * 40, Vector(0, 0, -80)
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
					r.Dmg = w.BlastDamage
					r:Spawn()
					t.HitNormal = -t.HitNormal
					t.HitEntity = t.Entity
					r:BecomeTrigger(t, 10)
					util.BlastDamage(ply, ply, t.HitPos, 30, r.Dmg)
					
					if IsValid(r) then
						w.rollconsume = w.rollconsume + 1
						if w.rollconsume > 20 then
							w.rollconsume = 0
							w:TakePrimaryAmmo(0.1, w.Primary.Ammo)
						end
					end
				end
			end
		end
		
		w:SetNextReloadTime(w.Primary.Delay * 60)
	end
end

local function LimitSpeed(ply, data)
	local s, sxy, d, m = ply:GetVelocity(), 0,
			ply:GetVelocity():GetNormalized():Dot(Vector(0, 0, -1)),
			ply:GetActiveWeapon().maxspeed
	sxy = math.sqrt(s.x * s.x + s.y * s.y)
	
	if math.abs(s.z) > m then
		if d < -0.8660254 then
			s.z = (s.z / math.abs(s.z)) * m / 3
		elseif d < 0.7071458 then
			s.z = (s.z / math.abs(s.z)) * m
		end
	end
	if math.abs(Vector(s.x, s.y, 0):GetNormalized():Dot(ply:GetForward())) > 0.9 then
		s.z = s.z + (s.z * 0.01 * sxy / m)
	end
	
	if sxy > m then
		s.x = s.x * m / sxy
		s.y = s.y * m / sxy
	end
	data:SetVelocity(s)
	
	roll(ply)
end

local function modaim(p)
	print("a")
	p:SetPoseParameter("aim_yaw", 90)
	p:SetPoseParameter("aim_pitch", 90)
	return true
end

function SWEP:Deploy()
	--hook.Add("PrePlayerDraw", "ModifyAim", modaim)
	hook.Add("Move", "Limit Squid's Speed", LimitSpeed)
	self.Owner:SetPlayerColor(Vector(self.ProjColor.r / 255, self.ProjColor.g / 255, self.ProjColor.b / 255))
	self.Owner:SetJumpPower(250)
	self.maxspeed = 250
	self.reload = self.ReloadSpeed * 3.3333333
	self.heal = self.HealSpeed * 10
	self.ShootCount = 0
end

function SWEP:Holster()
	timer.Destroy(self.healname)
	timer.Destroy(self.reloadname)
	timer.Destroy(self.inklingname)
	
	if not IsValid(self.Owner) or self.Owner:IsNPC() then
		timer.Destroy("think" .. self:EntIndex())
		return true
	end
	
	self.inInk = false
	self.throw = false
	self:SetNWBool("throw", false)
	self:SetNWInt("swing", 0)
	self:SetNWInt("down", 0)
	self.maxspeed = 250
	hook.Remove("Move", "Limit Squid's Speed")
	
	if IsValid(self) and IsValid(self.Owner) then
		if self.Owner:IsPlayer() then
			self.Owner:SetCrouchedWalkSpeed(0.6)
			self.Owner:SetWalkSpeed(250)
			self.Owner:SetRunSpeed(500)
			self.Owner:SetJumpPower(200)
			self.Owner:SetModel("models/drlilrobot/splatoon/ply/inkling_boy.mdl")
			self.Owner:DoAnimationEvent(PLAYERANIMEVENT_ATTACK_PRIMARY)
			self.Owner:SetNoDraw(false)
			self.Owner:SetRenderMode(RENDERMODE_NORMAL)
			self.Owner:SetColor(Color(255,255,255,255))
			self.Owner:RemoveFlags(FL_NOTARGET)
		end
	end
	
	if CLIENT and IsValid(self.Owner) and self.Owner:IsPlayer() then
		local vm = self.Owner:GetViewModel()
		if IsValid(vm) then
			self:ResetBonePositions(vm)
		end
		
		self.Owner:ManipulateBoneAngles(self.Owner:LookupBone("ValveBiped.Bip01_Spine"),
		Angle(0, 0, 0))
	end
	
	return true
end

function SWEP:OnRemove()
	self:Holster()
end

function SWEP:SetNextReloadTime(time)
	self.stoptime = CurTime() + time / 60
end

if CLIENT then

	SWEP.DrawAmmo = true
	SWEP.DrawCrosshair = true

	SWEP.vRenderOrder = nil
	function SWEP:ViewModelDrawn()
		
		local vm = self.Owner:GetViewModel()
		if !IsValid(vm) then return end
		
		if (!self.VElements) then return end
		
		self:UpdateBonePositions(vm)

		if (!self.vRenderOrder) then
			
			// we build a render order because sprites need to be drawn after models
			self.vRenderOrder = {}

			for k, v in pairs( self.VElements ) do
				if (v.type == "Model") then
					table.insert(self.vRenderOrder, 1, k)
				elseif (v.type == "Sprite" or v.type == "Quad") then
					table.insert(self.vRenderOrder, k)
				end
			end
			
		end

		for k, name in ipairs( self.vRenderOrder ) do
		
			local v = self.VElements[name]
			if (!v) then self.vRenderOrder = nil break end
			if (v.hide) then continue end
			
			local model = v.modelEnt
			local sprite = v.spriteMaterial
			
			if (!v.bone) then continue end
			
			local pos, ang = self:GetBoneOrientation( self.VElements, v, vm )
			
			if (!pos) then continue end
			
			if (v.type == "Model" and IsValid(model)) then
				
			--	root_2
			--	neck_2
			--	brush1_2
			--	brush2_2
			--	brush3_2
				
				local f = self:GetNWInt("down", 0)
				local l = math.Clamp((CurTime() - self:GetNWFloat("downbegins", CurTime())) * 7, 0, 4)
				if self:GetNWInt("swing", 0) == 1 and f >= 1 and l >= 4 then
					local starts, dir = self.Owner:GetShootPos() + self:GetForward() * 70 + Vector(0, 0, 50), Vector(0, 0, -1000000)
					local tr, trwall = util.QuickTrace(starts, dir, {self, self.Owner, model}),
						util.TraceLine({
							start = self.Owner:GetPos(),
							endpos = starts,
							filter = {self, self.Owner, model}
						})
						
					if trwall.Hit then
						tr.HitPos = trwall.HitPos
						tr.HitNormal = trwall.HitNormal
					end
					
					local level = (tr.HitPos - self.Owner:GetPos()):Angle().pitch
					if level > 180 then
						level = level - 360
					end
					level = math.Clamp(level * -2, -20, 100)
					
					--debugoverlay.Line(starts, starts + dir, 0.1, Color(0, 255, 0, 255), true)
					--debugoverlay.Line(self.Owner:GetPos(), tr.HitPos, 0.1, Color(0, 255, 0, 255), true)
					
					ang.roll = -level + 90
					ang.pitch = 180
					ang.yaw = ang.yaw - 90
				elseif  f ~= 0 then
					if l > 1 then
						l = 1
					end
					
					if f == -1 then
						ang.roll = ang.roll - 90 + 90 * l
						ang.yaw = self.Owner:EyeAngles().yaw + 90 - 90 * l
					elseif f == 1 then
						ang:RotateAroundAxis(self.Owner:EyeAngles():Forward(), 70)
						ang:RotateAroundAxis(self.Owner:EyeAngles():Up(), 140 * l)
						ang:RotateAroundAxis(ang:Up(), -90)
						pos.y = pos.y + 4
					elseif f == 2 then
						ang:RotateAroundAxis(self.Owner:EyeAngles():Forward(), 70)
						ang:RotateAroundAxis(self.Owner:EyeAngles():Up(), 140 - 140 * l)
						ang:RotateAroundAxis(ang:Up(), 90)
						pos.y = pos.y + 4
					end
				end
				
				
			--	if f ~= 0 then
			--		local mul = math.Clamp((CurTime() - self:GetNWFloat("downbegins", CurTime())) * 10, 0, 1)
			--		if f == -1 then
			--			model:SetAngles(ang + Angle(0, 0, -60 + 60 * mul))
			--			pos.z = pos.z - self.ZDelta + self.ZDelta * mul
			--			if mul >= 1 then
			--				self:SetNWInt("down", 0)
			--				mul = 0
			--			end
			--		else
			--			model:SetAngles(ang + Angle(0, 0, -60 * mul))
			--			pos.z = pos.z - self.ZDelta * mul
			--		end
			--	else
			--		
			--	end
				
				f = self:GetNWInt("swing", 0)
				if f ~= 0 then
					local mul = math.Clamp((CurTime() - self:GetNWFloat("swingbegins", CurTime())) * 5, 0, 1)
					if f == -1 then
						--model:ManipulateBoneAngles(model:LookupBone("neck"), Angle(0, 0, -90.0 * mul))
						if mul >= 1 then
							self:SetNWInt("swing", 0)
							self:SetNWInt("down", 0)
							self:SetNWFloat("swingbegins", CurTime())
							self:SetNWFloat("downbegins", CurTime())
							mul = 0
						end
					end
				else
					--model:ManipulateBoneAngles(model:LookupBone("neck"), Angle(0, 0, -90.0))
				end
				model:SetPos(pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z )
				
				ang:RotateAroundAxis(ang:Up(), v.angle.y)
				ang:RotateAroundAxis(ang:Right(), v.angle.p)
				ang:RotateAroundAxis(ang:Forward(), v.angle.r)
				model:SetAngles(ang)
				--model:SetModelScale(v.size)
				local matrix = Matrix()
				matrix:Scale(v.size)
				model:EnableMatrix( "RenderMultiply", matrix )
				
				if (v.material == "") then
					model:SetMaterial("")
				elseif (model:GetMaterial() != v.material) then
					model:SetMaterial( v.material )
				end
				
				if (v.skin and v.skin != model:GetSkin()) then
					model:SetSkin(v.skin)
				end
				
				if (v.bodygroup) then
					for k, v in pairs( v.bodygroup ) do
						if (model:GetBodygroup(k) != v) then
							model:SetBodygroup(k, v)
						end
					end
				end
				
				if (v.surpresslightning) then
					render.SuppressEngineLighting(true)
				end
				
				render.SetColorModulation(v.color.r/255, v.color.g/255, v.color.b/255)
				render.SetBlend(v.color.a/255)
				
				model:DrawModel()
				render.SetBlend(1)
				render.SetColorModulation(1, 1, 1)
				
				if (v.surpresslightning) then
					render.SuppressEngineLighting(false)
				end
				
			elseif (v.type == "Sprite" and sprite) then
				
				local drawpos = pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z
				render.SetMaterial(sprite)
				render.DrawSprite(drawpos, v.size.x, v.size.y, v.color)
				
			elseif (v.type == "Quad" and v.draw_func) then
				
				local drawpos = pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z
				ang:RotateAroundAxis(ang:Up(), v.angle.y)
				ang:RotateAroundAxis(ang:Right(), v.angle.p)
				ang:RotateAroundAxis(ang:Forward(), v.angle.r)
				
				cam.Start3D2D(drawpos, ang, v.size)
					v.draw_func( self )
				cam.End3D2D()

			end
			
		end
		
	end

	SWEP.wRenderOrder = nil
	function SWEP:DrawWorldModel()
		
		if not IsValid(self.Owner) then return end
		if (self.ShowWorldModel == nil or self.ShowWorldModel) then
			self:DrawModel()
		end
		
		if (!self.WElements) then return end
		
		if (!self.wRenderOrder) then

			self.wRenderOrder = {}

			for k, v in pairs( self.WElements ) do
				if (v.type == "Model") then
					table.insert(self.wRenderOrder, 1, k)
				elseif (v.type == "Sprite" or v.type == "Quad") then
					table.insert(self.wRenderOrder, k)
				end
			end

		end
		
		if (IsValid(self.Owner)) then
			bone_ent = self.Owner
		else
			// when the weapon is dropped
			bone_ent = self
		end
		
		for k, name in pairs( self.wRenderOrder ) do
		
			local v = self.WElements[name]
			if (!v) then self.wRenderOrder = nil break end
			if (v.hide) then continue end
			
			local pos, ang
			
			if (v.bone) then
				pos, ang = self:GetBoneOrientation( self.WElements, v, bone_ent )
			else
				pos, ang = self:GetBoneOrientation( self.WElements, v, bone_ent, "ValveBiped.Bip01_R_Hand" )
			end
			
			if (!pos) then continue end
			
			local model = v.modelEnt
			local sprite = v.spriteMaterial
			
			if (v.type == "Model" and IsValid(model)) then
				
				local f = self:GetNWInt("down", 0)
				local l = math.Clamp((CurTime() - self:GetNWFloat("downbegins", CurTime())) * 7, 0, 4)
				if self:GetNWInt("swing", 0) == 1 and f >= 1 and l >= 4 then
					local starts
					if self.Owner:IsPlayer() then
						starts = self.Owner:GetShootPos() + self:GetForward() * 70 + Vector(0, 0, 50)
					else
						starts = self:GetPos() + self:GetForward() * 70 + Vector(0, 0, 60)
					end
					local dir = Vector(0, 0, -1000000)
					local tr, trwall = util.QuickTrace(starts, dir, {self, self.Owner, model}),
						util.TraceLine({
							start = self.Owner:GetPos() + Vector(0, 0, 20),
							endpos = starts,
							filter = {self, self.Owner, model}
						})
						
					if trwall.Hit then
						tr.HitPos = trwall.HitPos
						tr.HitNormal = trwall.HitNormal
					end
					
					local level = (tr.HitPos - self.Owner:GetPos()):Angle().pitch
					if level > 180 then
						level = level - 360
					end
					
					--debugoverlay.Line(starts, starts + dir, 0.1, Color(0, 255, 0, 255), true)
					--debugoverlay.Line(self.Owner:GetPos(), tr.HitPos, 0.1, Color(0, 255, 0, 255), true)
					
					local default = 80
					if self.Owner:IsNPC() then
						level = math.Clamp(level * -2, -30, 110)
						default = 50
					else
						level = math.Clamp(level * -2, -60, 80)
					end
					ang.roll = -level - default
					ang.pitch = 0
					ang.yaw = self.Owner:GetAngles().yaw + 90
					
					if self.Owner:IsPlayer() then
						self.Owner:ManipulateBoneAngles(self.Owner:LookupBone("ValveBiped.Bip01_Spine"),
						Angle(0, 0, 5))
					end
				else
					if self.Owner:IsPlayer() then
						self.Owner:ManipulateBoneAngles(self.Owner:LookupBone("ValveBiped.Bip01_Spine"),
						Angle(0, 0, 0))
					end
					
					if  f ~= 0 then
						if l > 1 then l = 1 end
						
						if f == -1 then
							ang.roll = ang.roll - 90 + 90 * l
							ang.yaw = self.Owner:EyeAngles().yaw + 90 - 90 * l
						elseif f == 1 then
							ang:RotateAroundAxis(self.Owner:EyeAngles():Forward(), 80)
							ang:RotateAroundAxis(self.Owner:EyeAngles():Up(), 70 * l)
							ang:RotateAroundAxis(ang:Up(), -90)
							pos.y = pos.y + 10
						elseif f == 2 then
							ang:RotateAroundAxis(self.Owner:EyeAngles():Forward(), 80)
							ang:RotateAroundAxis(self.Owner:EyeAngles():Up(), 180 - 150 * l)
							ang:RotateAroundAxis(ang:Up(), 90)
							pos.y = pos.y + 10
						end
					end
				end
				
				local f = self:GetNWInt("swing", 0)
				if f ~= 0 then
					local mul = math.Clamp((CurTime() - self:GetNWFloat("swingbegins", CurTime())) * 5, 0, 1)
					if f == -1 then
						--model:ManipulateBoneAngles(model:LookupBone("neck"), Angle(0, 0, -90.0 * mul))
						if mul >= 1 then
							self:SetNWInt("swing", 0)
							self:SetNWInt("down", 0)
							self:SetNWFloat("swingbegins", CurTime())
							self:SetNWFloat("downbegins", CurTime())
							mul = 0
						end
					else
						--model:ManipulateBoneAngles(model:LookupBone("neck"), Angle(0, 0, -90.0 + 90.0 * mul))
					end
				else
					--model:ManipulateBoneAngles(model:LookupBone("neck"), Angle(0, 0, -90.0))
				end
				
				model:SetPos(pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z )
			
				ang:RotateAroundAxis(ang:Up(), v.angle.y)
				ang:RotateAroundAxis(ang:Right(), v.angle.p)
				ang:RotateAroundAxis(ang:Forward(), v.angle.r)
				model:SetAngles(ang)
				//model:SetModelScale(v.size)
				local matrix = Matrix()
				matrix:Scale(v.size)
				model:EnableMatrix( "RenderMultiply", matrix )
				
				if (v.material == "") then
					model:SetMaterial("")
				elseif (model:GetMaterial() != v.material) then
					model:SetMaterial( v.material )
				end
				
				if (v.skin and v.skin != model:GetSkin()) then
					model:SetSkin(v.skin)
				end
				
				if (v.bodygroup) then
					for k, v in pairs( v.bodygroup ) do
						if (model:GetBodygroup(k) != v) then
							model:SetBodygroup(k, v)
						end
					end
				end
				
				if (v.surpresslightning) then
					render.SuppressEngineLighting(true)
				end
				
				render.SetColorModulation(v.color.r/255, v.color.g/255, v.color.b/255)
				render.SetBlend(v.color.a/255)
				
				model:DrawModel()
				render.SetBlend(1)
				render.SetColorModulation(1, 1, 1)
				
				if (v.surpresslightning) then
					render.SuppressEngineLighting(false)
				end
				
			elseif (v.type == "Sprite" and sprite) then
				
				local drawpos = pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z
				render.SetMaterial(sprite)
				render.DrawSprite(drawpos, v.size.x, v.size.y, v.color)
				
			elseif (v.type == "Quad" and v.draw_func) then
				
				local drawpos = pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z
				ang:RotateAroundAxis(ang:Up(), v.angle.y)
				ang:RotateAroundAxis(ang:Right(), v.angle.p)
				ang:RotateAroundAxis(ang:Forward(), v.angle.r)
				
				cam.Start3D2D(drawpos, ang, v.size)
					v.draw_func( self )
				cam.End3D2D()

			end
			
		end
		
	end

	function SWEP:GetBoneOrientation( basetab, tab, ent, bone_override )
		
		local bone, pos, ang
		if (tab.rel and tab.rel != "") then
			
			local v = basetab[tab.rel]
			
			if (!v) then return end
			
			// Technically, if there exists an element with the same name as a bone
			// you can get in an infinite loop. Let's just hope nobody's that stupid.
			pos, ang = self:GetBoneOrientation( basetab, v, ent )
			
			if (!pos) then return end
			
			pos = pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z
			ang:RotateAroundAxis(ang:Up(), v.angle.y)
			ang:RotateAroundAxis(ang:Right(), v.angle.p)
			ang:RotateAroundAxis(ang:Forward(), v.angle.r)
				
		else
		
			bone = ent:LookupBone(bone_override or tab.bone)

			if (!bone) then return end
			
			pos, ang = Vector(0,0,0), Angle(0,0,0)
			local m = ent:GetBoneMatrix(bone)
			if (m) then
				pos, ang = m:GetTranslation(), m:GetAngles()
			end
			
			if (IsValid(self.Owner) and self.Owner:IsPlayer() and 
				ent == self.Owner:GetViewModel() and self.ViewModelFlip) then
				ang.r = -ang.r // Fixes mirrored models
			end
		
		end
		
		return pos, ang
	end

	function SWEP:CreateModels( tab )

		if (!tab) then return end

		// Create the clientside models here because Garry says we can't do it in the render hook
		for k, v in pairs( tab ) do
			if (v.type == "Model" and v.model and v.model != "" and (!IsValid(v.modelEnt) or v.createdModel != v.model) and 
					string.find(v.model, ".mdl") and file.Exists (v.model, "GAME") ) then
				
				v.modelEnt = ClientsideModel(v.model, RENDER_GROUP_VIEW_MODEL_OPAQUE)
				if (IsValid(v.modelEnt)) then
					v.modelEnt:SetPos(self:GetPos())
					v.modelEnt:SetAngles(self:GetAngles())
					v.modelEnt:SetParent(self)
					v.modelEnt:SetNoDraw(true)
					v.createdModel = v.model
				else
					v.modelEnt = nil
				end
				
			elseif (v.type == "Sprite" and v.sprite and v.sprite != "" and (!v.spriteMaterial or v.createdSprite != v.sprite) 
				and file.Exists ("materials/"..v.sprite..".vmt", "GAME")) then
				
				local name = v.sprite.."-"
				local params = { ["$basetexture"] = v.sprite }
				// make sure we create a unique name based on the selected options
				local tocheck = { "nocull", "additive", "vertexalpha", "vertexcolor", "ignorez" }
				for i, j in pairs( tocheck ) do
					if (v[j]) then
						params["$"..j] = 1
						name = name.."1"
					else
						name = name.."0"
					end
				end

				v.createdSprite = v.sprite
				v.spriteMaterial = CreateMaterial(name,"UnlitGeneric",params)
				
			end
		end
		
	end
	
	local allbones
	local hasGarryFixedBoneScalingYet = false

	function SWEP:UpdateBonePositions(vm)
		
		if self.ViewModelBoneMods then
			
			if (!vm:GetBoneCount()) then return end
			
			// !! WORKAROUND !! //
			// We need to check all model names :/
			local loopthrough = self.ViewModelBoneMods
			if (!hasGarryFixedBoneScalingYet) then
				allbones = {}
				for i=0, vm:GetBoneCount() do
					local bonename = vm:GetBoneName(i)
					if (self.ViewModelBoneMods[bonename]) then 
						allbones[bonename] = self.ViewModelBoneMods[bonename]
					else
						allbones[bonename] = { 
							scale = Vector(1,1,1),
							pos = Vector(0,0,0),
							angle = Angle(0,0,0)
						}
					end
				end
				
				loopthrough = allbones
			end
			// !! ----------- !! //
			
			for k, v in pairs( loopthrough ) do
				local bone = vm:LookupBone(k)
				if (!bone) then continue end
				
				// !! WORKAROUND !! //
				local s = Vector(v.scale.x,v.scale.y,v.scale.z)
				local p = Vector(v.pos.x,v.pos.y,v.pos.z)
				local ms = Vector(1,1,1)
				if (!hasGarryFixedBoneScalingYet) then
					local cur = vm:GetBoneParent(bone)
					while(cur >= 0) do
						local pscale = loopthrough[vm:GetBoneName(cur)].scale
						ms = ms * pscale
						cur = vm:GetBoneParent(cur)
					end
				end
				
				s = s * ms
				// !! ----------- !! //
				
				if vm:GetManipulateBoneScale(bone) != s then
					vm:ManipulateBoneScale( bone, s )
				end
				if vm:GetManipulateBoneAngles(bone) != v.angle then
					vm:ManipulateBoneAngles( bone, v.angle )
				end
				if vm:GetManipulateBonePosition(bone) != p then
					vm:ManipulateBonePosition( bone, p )
				end
			end
		else
			self:ResetBonePositions(vm)
		end
		   
	end
	 
	function SWEP:ResetBonePositions(vm)
		
		if (!vm:GetBoneCount()) then return end
		for i=0, vm:GetBoneCount() do
			vm:ManipulateBoneScale( i, Vector(1, 1, 1) )
			vm:ManipulateBoneAngles( i, Angle(0, 0, 0) )
			vm:ManipulateBonePosition( i, Vector(0, 0, 0) )
		end
		
	end

	/**************************
		Global utility code
	**************************/

	// Fully copies the table, meaning all tables inside this table are copied too and so on (normal table.Copy copies only their reference).
	// Does not copy entities of course, only copies their reference.
	// WARNING: do not use on tables that contain themselves somewhere down the line or you'll get an infinite loop
	function table.FullCopy( tab )

		if (!tab) then return nil end
		
		local res = {}
		for k, v in pairs( tab ) do
			if (type(v) == "table") then
				res[k] = table.FullCopy(v) // recursion ho!
			elseif (type(v) == "Vector") then
				res[k] = Vector(v.x, v.y, v.z)
			elseif (type(v) == "Angle") then
				res[k] = Angle(v.p, v.y, v.r)
			else
				res[k] = v
			end
		end
		
		return res
		
	end
	
elseif SERVER then

	AddCSLuaFile ("shared.lua")
	SWEP.weight = 5
	
	SWEP.AutoSwitchTo = false
	SWEP.AutoSwitchFrom = false
end

function SWEP:GetCatabilities()
	return CAP_INNATE_MELEE_ATTACK1 + CAP_INNATE_MELEE_ATTACK2
		 + CAP_WEAPON_MELEE_ATTACK1 + CAP_WEAPON_MELEE_ATTACK2
		 + CAP_USE + CAP_OPEN_DOORS + CAP_AUTO_DOORS + CAP_SKIP_NAV_GROUND_CHECK
		 -- + CAP_USE_SHOT_REGULATOR
end

function SWEP:Reload()
	if SERVER and self.Owner:IsNPC() then
		if self.ReloadingTime and CurTime() <= self.ReloadingTime then
			self.Owner:RemoveFlags(FL_DUCK)
		return end
	 
		if self:Clip1() < self.Primary.ClipSize then
	 		
	 		self.Owner:AddFlags(FL_DUCK)
			self:DefaultReload( ACT_VM_RELOAD )
	        local AnimationTime = self.Owner:GetViewModel():SequenceDuration()
	        self.ReloadingTime = CurTime() + AnimationTime
	        self:SetNextPrimaryFire(CurTime() + AnimationTime)
	        self:SetNextSecondaryFire(CurTime() + AnimationTime)
	 
		end
	end
end

function SWEP:Think()
	if SERVER then
		if IsValid(self.Owner) then
			if not timer.Exists(self.healname) then
				self.healname = "healing" .. self:EntIndex()
				timer.Create(self.healname, self.heal, 0, function() Heal(self) end)
			end
			if not timer.Exists(self.reloadname) then
				self.reloadname = "reloading!" .. self:EntIndex()
				timer.Create(self.reloadname, self.reload, 0, function() ReloadInk(self) end)
			end
			
			if self.Owner:Health() <= 0 then
				self:Remove()
			end
		else
			self:Remove()
		end
		
		if self.Owner:IsPlayer() and self.Owner:Crouching() then
			if self.Owner:GetDuckSpeed() > 100 then
				self.Owner:RemoveFlags(FL_DUCKING)
				return
			end
			
			if self.wepAnim ~= ACT_VM_HOLSTER and not self.throw then
				self.wepAnim = ACT_VM_HOLSTER
				self:SendWeaponAnim(ACT_VM_HOLSTER)
			end
			
			self.throw = false
			self:SetNWBool("throw", false)
			self:SetNWInt("swing", 0)
			self:SetNWInt("down", 0)
			self:SetNWInt("swingbegins", CurTime())
			self:SetNWInt("downbegins", CurTime())
			
			if self.inInk then
				self.maxspeed = 460
				if self.Owner:IsPlayer() then
					if (self.Owner:KeyDown(IN_FORWARD) or self.Owner:KeyDown(IN_JUMP)) and
						self.Owner:EyeAngles().pitch < -45 then
						self.Owner:SetVelocity(self.Owner:GetForward() * self.SwimSpeed * self.Owner:EyeAngles().pitch / -90)
					elseif not self.Owner:KeyDown(IN_JUMP) and self.Owner:GetVelocity().z > 0 then
						self.Owner:SetVelocity(Vector(0, 0, self.Owner:GetVelocity().z / -8))
					end
					
					if self.heal ~= self.HealSpeed then
						self.heal = self.HealSpeed
						timer.Adjust(self.healname, self.heal, 0, function() Heal(self) end)
					end
					if self.reload ~= self.ReloadSpeed then
						self.reload = self.ReloadSpeed
						timer.Adjust(self.reloadname, self.reload, 0, function() ReloadInk(self) end)
					end
					
					self.Owner:SetWalkSpeed(460)
					self.Owner:SetRunSpeed(460)
					self.Owner:SetCrouchedWalkSpeed(1)
					self.Owner:SetNoDraw(true)
					self.Owner:SetRenderMode(RENDERMODE_NONE)
					self.Owner:SetColor(Color(0,0,0,0))
					self.Owner:AddFlags(FL_NOTARGET)
					
					self:SetNoDraw(true)
				end
			else
				self.maxspeed = 350
				if self.Owner:IsPlayer() then
					if not self.Owner:KeyDown(IN_JUMP) and self.Owner:GetVelocity().z > 0 then
						self.Owner:SetVelocity(Vector(0, 0, self.Owner:GetVelocity().z / -8))
					end
					
					if self.heal ~= self.HealSpeed * 10 then
						self.heal = self.HealSpeed * 10
						timer.Adjust(self.healname, self.heal, 0, function() Heal(self) end)
					end
					if self.reload < self.ReloadSpeed * 3.3333333 then
						self.reload = self.ReloadSpeed * 3.3333333
						timer.Adjust(self.reloadname, self.reload, 0, function() ReloadInk(self) end)
					end
					
					self.Owner:SetWalkSpeed(230)
					self.Owner:SetRunSpeed(230)
					self.Owner:SetCrouchedWalkSpeed(0.6)
					self.Owner:SetNoDraw(false)
					self.Owner:SetRenderMode(RENDERMODE_NORMAL)
					self.Owner:SetColor(self.ProjColor)
					self.Owner:RemoveFlags(FL_NOTARGET)
					if self.Owner:GetModel() ~= "models/drlilrobot/splatoon/squid.mdl" then
						self.Owner:SetModel("models/drlilrobot/splatoon/squid.mdl")
					end
					
					local a = (self.Owner:GetVelocity() + self.Owner:GetForward() * 40):Angle()
					if self.Owner:GetVelocity():LengthSqr() < 16 then
						a.pitch = 0
					elseif a.pitch > 45 and a.pitch <= 90 then
						a.pitch = 45
					elseif a.pitch >= 270 and a.pitch < 300 then
						a.pitch = 300
					end
					self.Owner:ManipulateBoneAngles(0, Angle(0, 180, 90 + a.pitch))
					
					self:SetNoDraw(true)
				end
			end
		else
			if self.wepAnim ~= ACT_VM_IDLE and not self.throw then
				self.wepAnim = ACT_VM_IDLE
				self:SendWeaponAnim(ACT_VM_IDLE)
			end
			
			self.inInk = false
			if self.Owner:IsPlayer() then
				if self.heal ~= self.HealSpeed * 10 then
					self.heal = self.HealSpeed * 10
					timer.Adjust(self.healname, self.heal, 0, function() Heal(self) end)
				end
				if self.reload < self.ReloadSpeed * 3.3333333 then
					self.reload = self.ReloadSpeed * 3.3333333
					timer.Adjust(self.reloadname, self.reload, 0, function() ReloadInk(self) end)
				end
				
				self.maxspeed = 250
				if self:GetNWInt("swing", 0) == 1 then
					if self:GetNWInt("down", 0) >= 1 and
						math.Clamp((CurTime() - self:GetNWFloat("downbegins", CurTime())) * 7, 0, 4) >= 4 then
						self.Owner:SetWalkSpeed(self.FiringSpeed)
						self.Owner:SetRunSpeed(self.FiringSpeed)
					else
						self.Owner:SetWalkSpeed(self.FiringSpeed / 4)
						self.Owner:SetRunSpeed(self.FiringSpeed / 4)
					end
				else
					self.Owner:SetWalkSpeed(230)
					self.Owner:SetRunSpeed(230)
				end
				self.Owner:SetCrouchedWalkSpeed(0.6)
				if self.Owner:GetModel() ~= "models/drlilrobot/splatoon/ply/inkling_boy.mdl" then
					self.Owner:SetModel("models/drlilrobot/splatoon/ply/inkling_boy.mdl")
				end
				self.Owner:SetNoDraw(false)
				self.Owner:SetRenderMode(RENDERMODE_NORMAL)
				self.Owner:SetColor(Color(255,255,255,255))
				self.Owner:RemoveFlags(FL_NOTARGET)
				
				self:SetNoDraw(false)
				
				if self.throw then
					if not self.Owner:KeyDown(IN_ATTACK2) then
						self:Throw()
					else
						if self.wepAnim ~= ACT_VM_IDLE_LOWERED then
							self.wepAnim = ACT_VM_IDLE_LOWERED
							self:SendWeaponAnim(ACT_VM_IDLE_LOWERED)
						end
					end
				end
				
			else
				if IsValid(self.Owner) and GetConVar("ai_disabled"):GetInt() ~= 1 then
					if self.Owner:IsCurrentSchedule(SCHED_RANGE_ATTACK2) then--or
						--self.Owner:GetSequence() == ACT_SIGNAL1 then
						self:SecondaryAttack()
					elseif self.Owner:IsCurrentSchedule(SCHED_MELEE_ATTACK1) or self.Owner:IsCurrentSchedule(SCHED_MELEE_ATTACK2) then
						self.Owner:ClearSchedule()
						self.Owner:SetSchedule(SCHED_RANGE_ATTACK1)
					end
				end
			end
		end
		
		if self:GetNWInt("swing", 0) == 1 and self:GetNWInt("down", 0) >= 1 then
			if math.Clamp((CurTime() - self:GetNWFloat("downbegins", CurTime())) * 5, 0, 3) > 2.5 and
				self.Owner:IsPlayer() and not self.Owner:KeyDown(IN_ATTACK) then
				self:SendWeaponAnim(ACT_VM_IDLE)
				self:SetNWInt("swing", -1)
				self:SetNWInt("down", -1)
				self:SetNWFloat("swingbegins", CurTime())
				self:SetNWFloat("downbegins", CurTime())
				self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
			elseif self.Owner:IsNPC() then
				if not self.Owner:IsMoving() and not timer.Exists("disarm" .. self.Owner:EntIndex()) then
					timer.Create("disarm" .. self.Owner:EntIndex(), 0.3, 1, function()
						if IsValid(self) then
							self:SetNWInt("swing", -1)
							self:SetNWInt("down", -1)
							self:SetNWFloat("swingbegins", CurTime())
							self:SetNWFloat("downbegins", CurTime())
							--self:SetNextPrimaryFire(CurTime() + 0.05)
						end
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
	elseif CLIENT and IsValid(self.Owner) and self.Owner:IsPlayer() then
		
		if self:GetNWBool("throw", false) then
			self:SetWeaponHoldType("grenade")
			for k, v in pairs(self.WElements or {}) do
				v.hide = true
			end
		elseif self:GetNWInt("swing", 0) == 1 and self:GetNWInt("down", 0) >= 1 then
			--self.Owner:AddVCDSequenceToGestureSlot(GESTURE_SLOT_ATTACK_AND_RELOAD, 326, 0.56, true)
			self:SetWeaponHoldType("crossbow")
		else
			self:SetWeaponHoldType(self.HoldType)
			for k, v in pairs(self.WElements or {}) do
				v.hide = false
			end
		end
	end
end

function SWEP:paint()
	
	if CLIENT then return end
	
	local d = {
		Vector(1, 0, 0),
		Vector(1, 0, 0),
		Vector(1, 0, 0)
	}
	d[1]:Rotate(Angle(0, -60, 0))
	d[2]:Rotate(Angle(0, 60, 0))
	for _ = 1, 3 do
		local proj = ents.Create("splashootee")
		local dir = d[_]
		dir:Rotate(self.Owner:GetAimVector():Angle())
		local proforce = (self.Owner:GetAimVector() + dir +
			(VectorRand() * self.Primary.Spread)):GetNormalized() * math.random(self.PrimaryVelocity * 0.7, self.PrimaryVelocity)
		proj:SetModel("models/spitball_large.mdl")
		proj:SetOwner(self.Owner)
		proj:SetColor(self.ProjColor)
		proj:SetPos(self.Owner:GetShootPos() + self.Owner:GetForward() * self.Forward + self.Owner:GetRight() * self.Right + self.Owner:GetUp() * self.Upward)
		proj:SetAngles(self.Owner:EyeAngles())
		proj:SetPhysicsAttacker(self.Owner)
		proj.InkColor = self.InkColor
		proj.Dmg = self.BlastDamage
		proj.InkRadius = self.InkRadius
		proj.SplashNum = 1
		proj.SplashLen = 1
		proj.SplashInit = self.FallTimer / 1100
		proj.V0 = 1
		
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
			--splat:SetNoDraw(true)
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
	
	self:TakePrimaryAmmo(self.Primary.TakeAmmo, self.Primary.Ammo)
	self:SetNextReloadTime(self.StopReloading)
end

function SWEP:PrimaryAttack()
	if CLIENT or !self:CanPrimaryAttack() or self.Owner:IsFlagSet(FL_DUCKING) then return end
	
	self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
	if self:GetNWInt("swing", 0) ~= 1 or self:GetNWInt("down", 0) == 2 then
		self:SetNWFloat("swingbegins", CurTime())
		if SERVER and self.Owner:IsPlayer() then
			self.Owner:SendLua("LocalPlayer():AddVCDSequenceToGestureSlot(GESTURE_SLOT_ATTACK_AND_RELOAD, 326, 0, true)")
		end
		
		timer.Simple(0.1, function()
			if IsValid(self) and IsValid(self.Owner) and self:GetNWInt("swing", 0) == 1 then
				self:SendWeaponAnim(ACT_VM_HOLSTER)
				self:SetNWInt("down", 1)
				self:SetNWFloat("downbegins", CurTime())
				self:paint()
			end
		end)
	else
		self:SetNWInt("down", 2)
		self:SetNWFloat("downbegins", CurTime())
		self:paint()
	end
	
	if self.Owner:IsPlayer() then
		self.Owner:SetDuckSpeed(math.huge)
		timer.Simple(self.FreezeTime / 60, function()
			if IsValid(self) and IsValid(self.Owner) then
				self.Owner:SetDuckSpeed(0.1)
			end
		end)
	else
		if not timer.Exists("fire" .. self.Owner:EntIndex()) then
			timer.Create("fire" .. self.Owner:EntIndex(), 0.3, 1, function()
				if IsValid(self) and IsValid(self.Owner) then
					self:PrimaryAttack()
				end
			end)
		end
	end
	self:SetNWInt("swing", 1)
end

function SWEP:GetViewModelPosition(p, a)
	local dp, da = Vector(0, 25, -15), Angle(0, -3, -90)
	local mul = math.Clamp((CurTime() - self:GetNWFloat("swingbegins", CurTime())) * 2, 0, 1)
	dp:Rotate(a)
	
	local f = self:GetNWInt("swing", 0)
	if f ~= 0 then
		if f == -1 then
			if mul >= 1 then
				self:SetNWInt("swing", 0)
				return p, a
			end
		--	return p + dp - dp * mul, a + da - da * mul
		else
		--	return p + dp * mul, a + da * mul
		end
	else
		return p, a
	end
		return p, a
end

function SWEP:Throw()
end

function SWEP:SecondaryAttack()
end
