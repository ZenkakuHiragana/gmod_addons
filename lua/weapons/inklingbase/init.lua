
AddCSLuaFile "shared.lua"
AddCSLuaFile "baseinfo.lua"
AddCSLuaFile "cl_draw.lua"
include "shared.lua"
include "baseinfo.lua"

local InkTraceLength = 20
local InkTraceDown = -vector_up * InkTraceLength
function SWEP:Initialize()
	self.OwnerVelocity = vector_origin
	self.ViewAnim = ACT_VM_IDLE
	self:SetHoldType "passive"
	self:SetInInk(false)
	self:SetOnEnemyInk(false)
	self:SetNextCrouchTime(CurTime())
	self:SetInk(SplatoonSWEPs.MaxInkAmount)
	self:SetInkColorProxy(SplatoonSWEPs.vector_one)
	self:ChangeHullDuck()
	self:AddSchedule(SplatoonSWEPs:FrameToSec(3),
	function(self, schedule)
		--Set whether player is in ink or not
		local ang = Angle(0, self.Owner:GetAngles().yaw, 0)
		local p = self.Owner:WorldSpaceCenter()
		local fw, right = ang:Forward(), ang:Right()
		self.Owner.GroundColor = SplatoonSWEPs:GetSurfaceColor(util.QuickTrace(self.Owner:GetPos(), InkTraceDown, self.Owner))
		self:SetInWallInk(self.IsSquid and (SplatoonSWEPs:GetSurfaceColor(util.QuickTrace(p,
			(fw - right) * InkTraceLength, self.Owner)) == self.ColorCode
		or SplatoonSWEPs:GetSurfaceColor(util.QuickTrace(p,
			(fw + right) * InkTraceLength, self.Owner)) == self.ColorCode
		or SplatoonSWEPs:GetSurfaceColor(util.QuickTrace(p,
			(right + fw) * -InkTraceLength, self.Owner)) == self.ColorCode
		or SplatoonSWEPs:GetSurfaceColor(util.QuickTrace(p,
			(right - fw) * InkTraceLength, self.Owner)) == self.ColorCode))
		self:SetInInk(self.IsSquid and self.Owner.GroundColor == self.ColorCode or self:GetInWallInk())
		self:SetOnEnemyInk(self.Owner.GroundColor and self.Owner.GroundColor ~= self.ColorCode or false)
		self.OwnerVelocity = self.Owner:GetVelocity()
	end)
	
	self:SharedInitBase()
	if isfunction(self.ServerInit) then return self:ServerInit() end
end

function SWEP:OnRemove()
	return self:Holster()
end

function SWEP:ShouldDropOnDie()
	return true
end

function SWEP:Deploy()
	if not (IsValid(self.Owner) and self.Owner:IsPlayer()) then return true end
	if game.SinglePlayer() then self:CallOnClient "Deploy" end
	self:SetInInk(false)
	self:SetOnEnemyInk(false)
	self:SetNextCrouchTime(CurTime())
	self.OwnerVelocity = self.Owner:GetVelocity()
	self.ViewAnim = ACT_VM_IDLE
	self:SetPMID(self.Owner:GetInfoNum(SplatoonSWEPs:GetConVarName "Playermodel", 1))
	if self:GetPMID() ~= SplatoonSWEPs.PLAYER.NOSQUID then
		self.Owner:SetMaterial(self.Owner:Crouching() and "color" or "")
	end
	
	if self.Owner:IsPlayer() then
		self.ColorCode = self.Owner:GetInfoNum(SplatoonSWEPs:GetConVarName "InkColor", 1)
		self:SetHoldType "passive"
	end
	
	if self.ColorCode == 0 then 
		self.ColorCode = math.random(SplatoonSWEPs.MAX_COLORS)
	end
	
	self.SquidAvailable = file.Exists(SplatoonSWEPs.Squidmodel[self:GetPMID() == SplatoonSWEPs.PLAYER.OCTO
		and SplatoonSWEPs.SQUID.OCTO or SplatoonSWEPs.SQUID.INKLING], "GAME")
	self.Color = SplatoonSWEPs:GetColor(self.ColorCode)
	self:SetInkColorProxy(Vector(self.Color.r, self.Color.g, self.Color.b) / 255)
	return self:SharedDeployBase()
end

function SWEP:Holster()
	if not (IsValid(self.Owner) and self.Owner:IsPlayer()) then return true end
	if game.SinglePlayer() then self:CallOnClient "Holster" end
	return self:SharedHolsterBase()
end

function SWEP:OnRemove() return self:Holster() end
function SWEP:Think()
	if not IsValid(self.Owner) or self.Holstering then return end
	self:ProcessSchedules()
	self:SharedThinkBase()
	self:SetClip1(math.max(0, self:GetInk() / SplatoonSWEPs.MaxInkAmount * 100))
	if isfunction(self.ServerThink) then return self:ServerThink() end
end
