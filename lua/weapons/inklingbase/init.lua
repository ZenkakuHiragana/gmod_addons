
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
		self:SetGroundColor(SplatoonSWEPs:GetSurfaceColor(util.QuickTrace(self.Owner:GetPos(), InkTraceDown, self.Owner)) or -1)
		local onourink = self:GetGroundColor() >= 0 and self:GetGroundColor() == self.ColorCode
		self:SetInWallInk(self.IsSquid and (SplatoonSWEPs:GetSurfaceColor(util.QuickTrace(p,
			(fw - right) * InkTraceLength, self.Owner)) == self.ColorCode
		or SplatoonSWEPs:GetSurfaceColor(util.QuickTrace(p,
			(fw + right) * InkTraceLength, self.Owner)) == self.ColorCode
		or SplatoonSWEPs:GetSurfaceColor(util.QuickTrace(p,
			(right + fw) * -InkTraceLength, self.Owner)) == self.ColorCode
		or SplatoonSWEPs:GetSurfaceColor(util.QuickTrace(p,
			(right - fw) * InkTraceLength, self.Owner)) == self.ColorCode))
		self:SetInInk(self.IsSquid and onourink or self:GetInWallInk())
		self:SetOnEnemyInk(self:GetGroundColor() >= 0 and not onourink)
		self.OwnerVelocity = self.Owner:GetPhysicsObject():GetVelocity()
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
	if not (IsValid(self.Owner) and self.Owner:IsPlayer() and self.Owner:Alive()) then return true end
	self:CallOnClient "ClientDeployBase"
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
	self.CanHealStand = self.Owner:GetInfoNum("CanHealStand", 1) ~= 0
	self.CanHealInk = self.Owner:GetInfoNum("CanHealInk", 1) ~= 0
	self.CanReloadStand = self.Owner:GetInfoNum("CanReloadStand", 1) ~= 0
	self.CanReloadInk = self.Owner:GetInfoNum("CanReloadInk", 1) ~= 0
	self.BackupPlayerInfo = {
		Color = self.Owner:GetColor(),
		Flags = self.Owner:GetFlags(),
		JumpPower = self.Owner:GetJumpPower(),
		RenderMode = self:GetRenderMode(),
		Speed = {
			Crouched = self.Owner:GetCrouchedWalkSpeed(),
			Duck = self.Owner:GetDuckSpeed(),
			Max = self.Owner:GetMaxSpeed(),
			Run = self.Owner:GetRunSpeed(),
			Walk = self.Owner:GetWalkSpeed(),
			UnDuck = self.Owner:GetUnDuckSpeed(),
		},
		Playermodel = {
			Model = self.Owner:GetModel(),
			Skin = self.Owner:GetSkin(),
			BodyGroups = self.Owner:GetBodyGroups(),
			SetOffsets = table.HasValue(SplatoonTable or {}, self.Owner:GetModel()),
			PlayerColor = self.Owner:GetPlayerColor(),
		},
		ViewOffsetDucked = self.Owner:GetViewOffsetDucked()
	}
	self.BackupPlayerInfo.HullMins, self.BackupPlayerInfo.HullMaxs = self.Owner:GetHullDuck()
	for k, v in pairs(self.BackupPlayerInfo.Playermodel.BodyGroups) do
		v.num = self.Owner:GetBodygroup(v.id)
	end
	local PMPath = SplatoonSWEPs.Playermodel[self:GetPMID()]
	if PMPath then
		if file.Exists(PMPath, "GAME") then
			self.PMTable = {
				Model = PMPath,
				Skin = 0,
				BodyGroups = {},
				SetOffsets = true,
				PlayerColor = self:GetInkColorProxy(),
			}
			self:ChangePlayermodel(self.PMTable)
			self:ChangeHullDuck()
		elseif SERVER then
			SplatoonSWEPs:SendError("SplatoonSWEPs: Required playermodel is not found!", 1, 10, self.Owner)
		end
	end
	return self:SharedDeployBase()
end

function SWEP:Holster()
	if not (IsValid(self.Owner) and self.Owner:IsPlayer()) then return true end
	if game.SinglePlayer() and IsValid(self.Owner) then self:CallOnClient "Holster" end
	self.PMTable = nil
	if istable(self.BackupPlayerInfo) then --Restores owner's information.
		self:ChangePlayermodel(self.BackupPlayerInfo.Playermodel)
		self.Owner:SetColor(self.BackupPlayerInfo.Color)
	--	self.Owner:RemoveFlags(self.Owner:GetFlags()) --Restores no target flag and something.
	--	self.Owner:AddFlags(self.BackupPlayerInfo.Flags)
		self.Owner:SetJumpPower(self.BackupPlayerInfo.JumpPower)
		self.Owner:SetRenderMode(self.BackupPlayerInfo.RenderMode)
		self.Owner:SetCrouchedWalkSpeed(self.BackupPlayerInfo.Speed.Crouched)
		self.Owner:SetDuckSpeed(self.BackupPlayerInfo.Speed.Duck)
		self.Owner:SetMaxSpeed(self.BackupPlayerInfo.Speed.Max)
		self.Owner:SetRunSpeed(self.BackupPlayerInfo.Speed.Run)
		self.Owner:SetWalkSpeed(self.BackupPlayerInfo.Speed.Walk)
		self.Owner:SetUnDuckSpeed(self.BackupPlayerInfo.Speed.UnDuck)
		self.Owner:SetHullDuck(self.BackupPlayerInfo.HullMins, self.BackupPlayerInfo.HullMaxs)
		self.Owner:SetViewOffsetDucked(self.BackupPlayerInfo.ViewOffsetDucked)
	end
	
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
