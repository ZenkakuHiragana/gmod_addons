
list.Set("NPC", "nextbot_user_base", {
	Name = "UserBase",
	Class = "nextbot_user_base",
	Category = "GreatZenkakuMan's NPCs"
	}
)

AddCSLuaFile("acts.lua")
include("acts.lua")

ENT.Base = "base_nextbot"
ENT.Type = "nextbot"

ENT.PrintName = "UserBase"
ENT.Author = "Himajin Jichiku"
ENT.Contact = ""
ENT.Purpose = ""
ENT.Instruction = ""
ENT.Spawnable = true

ENT.AutomaticFrameAdvance = true

ENT.StepHeight = 18
ENT.JumpHeight = 25
ENT.MaxHP = 125

ENT.Weapon = nil
ENT.HoldType = "none"

ENT.Enemy = nil
ENT.look = false

function SetAutomaticFrameAdvance(bUsingAnim)
	self.AutomaticFrameAdvance = bUsingAnim
end

function ENT:Initialize()
	self:SetModel("models/Humans/Group02/Female_01.mdl")
	self:SetSolid(SOLID_BBOX)
	
	self.loco:SetStepHeight(self.StepHeight)
	self.loco:SetJumpHeight(self.JumpHeight)
	
	self:SetHealth(self.MaxHP)
	if GetConVarString("gmod_npcweapon") ~= "none" then
		self:Give(GetConVarString("gmod_npcweapon") or "weapon_pistol")
	end
	self:StartActivity(self:GetAct(ACT_IDLE))
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
	--hook.Call("OnNPCKilled", GAMEMODE, self, dmginfo:GetAttacker(), dmginfo:GetInflictor())
	self:OnRemove()
	self:BecomeRagdoll(info)
end

function ENT:SetEnemy( ent )
	self.Enemy = ent
end

function ENT:GetEnemy()
	return self.Enemy
end

function ENT:Give(class)
    if !IsValid(self) then return end
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

function ENT:Think()
	
	if IsValid(self:GetEnemy()) and self.look then
		self.loco:FaceTowards(self:GetEnemy():GetPos())
		self:Aim(self:GetTargetPos(false))
	end
	
	self:NextThink(CurTime() + 0.02)
	return true
end

function ENT:RunBehaviour()
	while true do
		if not tobool(GetConVarNumber("ai_disabled")) then
			
		end
		coroutine.wait(0.05)
	end
end
