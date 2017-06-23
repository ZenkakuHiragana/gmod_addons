
list.Set("NPC", "nextbot_user_base", {
	Name = "UserBase",
	Class = "nextbot_user_base",
	Category = "GreatZenkakuMan's NPCs"
})

list.Set("NPC", "npc_sniper", {
	Name = "Combine Sniper",
	Class = "npc_sniper",
	Category = "GreatZenkakuMan's NPCs",
	KeyValues = {SquadName = "overwatch"}
})

AddCSLuaFile("nextbot_user_base.lua")
AddCSLuaFile("acts.lua")
include("acts.lua")
include("ainodes.lua")

ENT.Base = "base_nextbot"
ENT.Type = "nextbot"

ENT.PrintName = "UserBase"
ENT.Author = "Himajin Jichiku"
ENT.Contact = ""
ENT.Purpose = ""
ENT.Instruction = ""
ENT.Spawnable = false

ENT.AutomaticFrameAdvance = true

ENT.StepHeight = 22
ENT.JumpHeight = 58
ENT.MaxHP = 125

ENT.Weapon = nil
ENT.HoldType = "none"

ENT.Enemy = nil
ENT.look = false

function ENT:GetNoTarget() --for Half Life Renaissance Reconstructed
	return false
end

function ENT:PercentageFrozen()
	return 0
end

--hook.Add("OnEntityCreated", "ZnkkSniperIsAlone!", function(e)
--	if SERVER and IsValid(e) and e:GetClass() ~= "nextbot_user_base" and e:IsNPC() then
--		local t = "target" .. e:EntIndex()
--		timer.Create(t, 0.1, 0, function()
--			if not IsValid(e) then timer.Destroy(t) return end
--			for k, v in pairs(ents.FindByClass("nextbot_user_base")) do
--				if IsValid(v) then
--					e:AddEntityRelationship(v, D_HT, 99)
--				end
--			end
--		end)
--	end
--end)

local SnipeSound = Sound("Weapon_Pistol.NPC_Single")
local ShootSound = Sound("Weapon_Shotgun.NPC_Single")
local InjuredSound = Sound("AlyxEMP.Discharge")

function ENT:GetHullType()
	return HULL_HUMAN
end

function SetAutomaticFrameAdvance(bUsingAnim)
	self.AutomaticFrameAdvance = bUsingAnim
end

function ENT:Initialize()
	if CLIENT then return end
	self:SetModel("models/Humans/Group02/Female_01.mdl")
	self:SetSolid(SOLID_BBOX)
	self:AddFlags(FL_NPC)
	self:AddFlags(FL_OBJECT)
	self:SetSolid(SOLID_BBOX)
	self:SetCollisionGroup(COLLISION_GROUP_NONE)
	
	self.loco:SetStepHeight(self.StepHeight)
--	self.loco:SetJumpHeight(self.JumpHeight)
	
	self:SetHealth(self.MaxHP)
	self:SetMaxHealth(self.MaxHP)
	
	local c = GetConVar("gmod_npcweapon")
	if c:GetString() ~= "none" then
		self:Give(c:GetString())
	end
	self:Anim(ACT_IDLE)
	
	self:ParseFile()
end

function ENT:OnRemove()
	if IsValid(self.Weapon) then
		self.Weapon:Remove()
	end
end

function ENT:OnInjured(info)

	--[[if IsValid(self) and IsValid(info:GetAttacker()) then
		local ang = (info:GetAttacker():GetPos() - self:GetPos()):Angle()
		self:SetAngles(Angle(0, ang.yaw, ang.roll))
		self:EmitSound(InjuredSound)
	end]]
end

function ENT:OnKilled(info)
	hook.Call("OnNPCKilled", GAMEMODE, self, info:GetAttacker(), info:GetInflictor())
	self:BecomeRagdoll(info)
end

function ENT:SetEnemy( ent )
	self.Enemy = ent
end

function ENT:GetEnemy()
	return self.Enemy
end

function ENT:Give(class)
    if not IsValid(self) or class == "" then class = "weapon_pistol" end
    if IsValid(self.Weapon) then self.Weapon:Remove() end
    
    local att = "anim_attachment_RH"
    local shootpos = self:GetAttachment(self:LookupAttachment(att))
    
    local wep = ents.Create(class)
    wep:SetOwner(self)
    wep:SetPos(shootpos.Pos)
    wep:AddEFlags(EFL_NO_PHYSCANNON_INTERACTION)
    --wep:GetPhysicsObject():AddGameFlag(FVPHYSICS_NO_PLAYER_PICKUP)
    --wep:SetAngles(ang)
    wep:Spawn()
    wep:SetKeyValue("spawnflags", 1+2+4) --Adds Spawn Flags.  2 .. Deny player pickup, 4 .. Not puntable bu Gravity Gun.
    
    wep:SetSolid(SOLID_NONE)
    wep:SetParent(self)
	
    wep:Fire("setparentattachment", "anim_attachment_RH")
    wep:AddEffects(EF_BONEMERGE)
    wep:SetAngles(self:GetForward():Angle())
    
    self.Weapon = wep
    
    if class == "weapon_ar2" then
    	self.HoldType = "ar2"
    elseif class == "weapon_smg1" then
    	self.HoldType = "smg"
    elseif class == "weapon_shotgun" then
    	self.HoldType = "shotgun"
    elseif class == "weapon_pistol" then
    	self.HoldType = "pistol"
    elseif class == "weapon_rpg" then
    	self.HoldType = "rpg"
    elseif class == "weapon_crowbar" or class == "weapon_stunstick" then
    	self.HoldType = "melee"
    else
    	self.HoldType = "none"
    end
end

function ENT:GetYawPitch(vec)
	--This gets the offset from 0,2,0 on the entity to the vec specified as a vector
	local yawAng = vec - self:GetAttachment(self:LookupAttachment("eyes") or 1).Pos
	--Then converts it to a vector on the entity and makes it an angle ("local angle")
	local yawAng = self:WorldToLocal(self:GetPos() + yawAng):Angle()
	
	--Same thing as above but this gets the pitch angle. Since the turret's pitch axis and the turret's yaw axis are seperate I need to do this seperately.
	local pAng = vec - self:LocalToWorld((yawAng:Forward() * 8) + Vector(0, 0, 50))
	local pAng = self:WorldToLocal(self:GetPos() + pAng):Angle()

	--Y=Yaw. This is a number between 0-360.	
	local y = yawAng.y
	--P=Pitch. This is a number between 0-360.
	local p = pAng.p
	
	--Numbers from 0 to 360 don't work with the pose parameters, so I need to make it a number from -180 to 180
	if y >= 180 then y = y - 360 end
	if p >= 180 then p = p - 360 end
	if y <- 60 || y > 60 then return false end
	if p <- 80 || p > 50 then return false end
	--Returns yaw and pitch as numbers between -180 and 180	
	return y, p
end

--This grabs yaw and pitch from ENT:GetYawPitch. 
--This function sets the facing direction of the turret also.
function ENT:Aim(vec)
	local y, p = self:GetYawPitch(vec)
	if y == false then
		return false
	end
	self:SetPoseParameter("aim_yaw", y)
	self:SetPoseParameter("aim_pitch", p)
	return true
end

function ENT:Anim(a)
	if not self:GetAct(a) then return false end
	if self:GetActivity() ~= self:GetAct(a) then
		self:StartActivity(self:GetAct(a))
		return true
	end
	return false
end

function ENT:Think()
	if SERVER then
		local n = navmesh.Find(self:GetPos(), 800, self.JumpHeight, self.JumpHeight * 3)
		for k, v in pairs(n) do
	--		v:Draw()
	--		v:DrawSpots()
		end
	end
	
--	if IsValid(self:GetEnemy()) and self.look then
--		self.loco:FaceTowards(self:GetEnemy():GetPos())
--		self:Aim(self:GetTargetPos(false))
--	end
--	
--	self:NextThink(CurTime() + 0.5)
	return true
end

local function findpath(self, area, fromArea, ladder, elevator, length)
	if not IsValid(fromArea) then
		// first area in path, no cost
		return 0
	else
		if not self.loco:IsAreaTraversable(area) then
			// our locomotor says we can't move here
			return -1
		end
		local t = util.TraceHull({
			start = area:GetCenter(),
			endpos = area:GetCenter() + Vector(0, 0, self.loco:GetMaxJumpHeight()),
			maxs = Vector(area:GetSizeX() / 2, area:GetSizeY() / 2, self.loco:GetMaxJumpHeight()),
			mins = Vector(area:GetSizeX() / -2, area:GetSizeY() / -2, 0),
			mask = MASK_NPCSOLID
		})
		if t.Hit and t.HitNonWorld then
			return -1
		end
		
		// compute distance traveled along path so far
		local dist = 0
		
		if IsValid(ladder) then
			dist = ladder:GetLength()
		elseif length > 0 then
			// optimization to avoid recomputing length
			dist = length
		else
			dist = area:GetCenter():Distance(fromArea:GetCenter())
		end
		
		local cost = dist + fromArea:GetCostSoFar()
		// check height change
		local deltaZ = fromArea:ComputeAdjacentConnectionHeightChange(area)
		if deltaZ >= self.loco:GetStepHeight() then
		print(fromArea:ComputeAdjacentConnectionHeightChange(area))
			if deltaZ >= self.loco:GetMaxJumpHeight() then
				// too high to reach
				return -1
			end
			
			// jumping is slower than flat ground
			local jumpPenalty = 5
			cost = cost + jumpPenalty * dist
			return -1
		elseif deltaZ < -self.loco:GetDeathDropHeight() then
			// too far to drop
			return -1
		end
		
		return cost
	end
end

function ENT:Move(moveto, opt)
    local opt = opt or {}
	local path = Path("Follow")
	local to = moveto or (self:GetPos() + Vector(math.Rand(-1, 1), math.Rand(-1, 1), 0) * (opt.dist or self.NearDistance))
	
	local traversable = util.QuickTrace(to, to + vector_up * 30)
	if traversable.AllSolid then
		debugoverlay.Line(self:GetPos(), to, 5, Color(255, 0, 0, 255), true)
		return "invalid"
	end
	
	path:SetMinLookAheadDistance(opt.lookahead or 50)
	path:SetGoalTolerance(opt.tolerance or 50)
	local valid = path:Compute(self, to, function(area, fromArea, ladder, elevator, length)
		return findpath(self, area, fromArea, ladder, elevator, length)
	end)
	
	if not (valid and path:IsValid()) then
		if self:GetRangeTo(to) < 512 then
			while self:GetRangeTo(to) > (opt.tolerance or 50) do
				self.loco:Approach(to, 1)
				if not self:GetVelocity():IsZero() then
					self:SetPoseParameter("move_yaw",
					math.Remap(self:WorldToLocal(self:GetPos() - self:GetVelocity()):Angle().y, 0, 360, -180, 180))
				end
				coroutine.yield()
			end
		end
		
		return "invalid"
	end
	
	while path:IsValid() do
		if not self:GetVelocity():IsZero() then
			self:SetPoseParameter("move_yaw",
			math.Remap(self:WorldToLocal(self:GetPos() - self:GetVelocity()):Angle().y, 0, 360, -180, 180))
		end
		
		if path:GetAge() > (opt.maxage or 60) then
			return "timeout"
		end
		
		if path:GetAge() > (opt.repath or 10) then
			path:Compute(self, to, function(area, fromArea, ladder, elevator, length)
				return findpath(self, area, fromArea, ladder, elevator, length)
			end)
		end
		
		seg = path:GetCurrentGoal()
		if seg.type == 2 then
			self.loco:JumpAcrossGap(seg.pos + Vector(0, 0, self.StepHeight), seg.forward + Vector(0, 0, self.StepHeight))
			self:StartActivity(act or self.RunPistol)
		end
		
		if opt.draw then path:Draw() end
		path:Update(self)
	--	
	--	local d = 20
	--	local base = self:GetPos() + vector_up * d
	--	local tr = {start = base,
	--				endpos = base + self:GetForward() * d,
	--				filter = self}
	--	local f = util.TraceEntity(tr, self)
	--	if f.Hit then
	--		local cross = self:GetForward():Cross(f.HitNormal).z
	--		self.loco:Approach(self:GetPos() + self:GetRight() * (cross > 0 and -d or d), 100)
	--		self.loco:FaceTowards(self:GetPos() - f.HitNormal)
	--	end
		
		-- If we're stuck then call the HandleStuck function and abandon
		if self.loco:IsStuck() then
			self:HandleStuck()
			return "stuck"
		end
		coroutine.yield()
	end
	
	return "ok"
end

function ENT:OnLandOnGround(ent)
	self.repath = true
	self:Anim(ACT_RUN)
end

function ENT:RunBehaviour()
	while true do
		if not tobool(GetConVarNumber("ai_disabled")) then
			if Entity(1):KeyDown(IN_ATTACK2) then
				self.loco:SetAcceleration(5000)
				self.loco:SetDeceleration(5000)
				self.loco:SetDesiredSpeed(150)
				self.loco:SetMaxYawRate(400)
				self:Anim(ACT_WALK)
			--	self.loco:JumpAcrossGap(Entity(1):GetEyeTrace().HitPos,
			--		(Entity(1):GetEyeTrace().HitPos + self:GetPos()):GetNormalized())
				local open, goal = self:FindPath(Entity(1):GetEyeTrace().HitPos)
				print(self:MoveToPos(Entity(1):GetEyeTrace().HitPos, {
					lookahead = 10, 
					tolerance = 5, 
					draw = true, 
					maxage = 15, 
					repath = 3,
				}))
				self:Anim(ACT_IDLE)
			elseif Entity(1):KeyDown(IN_ATTACK) then
				local e = EffectData()
				e:SetOrigin(self:GetPos())
			--	e:SetStart(self:GetPos())
			--	e:SetScale(0.1)
			--	e:SetRadius(0.1)
			--	e:SetFlags(255)
			--	e:SetMagnitude(0.1)
			--	e:SetNormal(self:GetAngles():Forward())
			--	e:SetEntity(self)
				e:SetAngles(self:GetAngles())
				util.Effect("AirboatMuzzleFlash", e)
--				ParticleEffect("hunter_muzzle_flash", self:GetPos(), self:GetAngles())
			else
				self:Anim(ACT_IDLE)
			--	self:MuzzleFlash()
			end
		end
		coroutine.wait(0.1)
	end
end
