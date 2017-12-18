
AddCSLuaFile "shared.lua"
AddCSLuaFile "baseinfo.lua"
AddCSLuaFile "cl_draw.lua"
include "shared.lua"
include "baseinfo.lua"

local InkTraceLength = 20
local InkTraceDown = -vector_up * InkTraceLength
function SWEP:SetPlayerSpeed(spd)
	self.MaxSpeed = spd
	self.Owner:SetMaxSpeed(self.MaxSpeed)
	self.Owner:SetRunSpeed(self.MaxSpeed)
	self.Owner:SetWalkSpeed(self.MaxSpeed)
end

function SWEP:Initialize()
	self.ViewAnim = ACT_VM_IDLE
	self:SetHoldType "passive"
	self:SetInInk(false)
	self:SetOnEnemyInk(false)
	self:SetCrouchPriority(false)
	self:SetNextCrouchTime(CurTime())
	self:SetInk(SplatoonSWEPs.MaxInkAmount)
	self:SetInkColorProxy(SplatoonSWEPs.vector_one)
	self:ChangeHullDuck()
	self:AddSchedule(SplatoonSWEPs:FrameToSec(3),
	function(self, schedule)
		--Set whether player is in ink or not
		local groundcolor = SplatoonSWEPs:GetSurfaceColor(
			util.QuickTrace(self.Owner:GetPos(), InkTraceDown, self.Owner))
		local ang = Angle(0, self.Owner:GetAngles().yaw, 0)
		local p = self.Owner:WorldSpaceCenter()
		local fw, right = ang:Forward(), ang:Right()
		self:SetInInk(self.IsSquid and (groundcolor == self.ColorCode or not self.Owner:OnGround()
		and (SplatoonSWEPs:GetSurfaceColor(util.QuickTrace(p,
			(fw - right) * InkTraceLength, self.Owner)) == self.ColorCode
		or SplatoonSWEPs:GetSurfaceColor(util.QuickTrace(p,
			(fw + right) * InkTraceLength, self.Owner)) == self.ColorCode
		or SplatoonSWEPs:GetSurfaceColor(util.QuickTrace(p,
			(right + fw) * -InkTraceLength, self.Owner)) == self.ColorCode
		or SplatoonSWEPs:GetSurfaceColor(util.QuickTrace(p,
			(right - fw) * InkTraceLength, self.Owner)) == self.ColorCode)))
		self:SetOnEnemyInk(groundcolor and groundcolor ~= self.ColorCode)
	end)
	if isfunction(self.ServerInit) then return self:ServerInit() end
end

function SWEP:OnRemove()
	return self:Holster()
end

function SWEP:ShouldDropOnDie()
	return true
end

local function ImmuneFallDamage(ply, speed)
	local weapon = ply:GetActiveWeapon()
	if IsValid(weapon) and weapon.IsSplatoonWeapon then
		return 0
	end
end
hook.Add("GetFallDamage", "Inklings don't take fall damage.", ImmuneFallDamage)

function SWEP:Deploy()
	if not (IsValid(self.Owner) and self.Owner:IsPlayer()) then return true end
	self:CallOnClient "Deploy"
	
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
	
	self:SetPlayerSpeed(SplatoonSWEPs.InklingBaseSpeed)
	self.Owner:SetJumpPower(SplatoonSWEPs.InklingJumpPower)
	self.Owner:SetColor(color_white)
	self.Owner:SetCrouchedWalkSpeed(0.5)
	
	self.PMID = self.Owner:GetInfoNum(SplatoonSWEPs:GetConVarName "Playermodel", 1)
	if self.PMID ~= SplatoonSWEPs.PLAYER.NOSQUID then
		self.Owner:SetMaterial(self.Owner:Crouching() and "color" or "")
	end
	
	if self.Owner:IsPlayer() then
		self.ColorCode = self.Owner:GetInfoNum(SplatoonSWEPs:GetConVarName "InkColor", 1)
		self:SetHoldType "passive"
	end
	self.SquidAvailable = file.Exists(SplatoonSWEPs.Squidmodel[self.PMID == SplatoonSWEPs.PLAYER.OCTO
		and SplatoonSWEPs.SQUID.OCTO or SplatoonSWEPs.SQUID.INKLING], "GAME")
	self.Color = SplatoonSWEPs:GetColor(self.ColorCode)
	self:SetInkColorProxy(Vector(self.Color.r, self.Color.g, self.Color.b) / 255)
	
	self.PMPath = SplatoonSWEPs.Playermodel[self.PMID]
	if file.Exists(self.PMPath, "GAME") then
		self.PMTable = {
			Model = self.PMPath,
			Skin = 0,
			BodyGroups = {},
			SetOffsets = true,
			PlayerColor = self:GetInkColorProxy(),
		}
		self:ChangePlayermodel(self.PMTable)
		self:ChangeHullDuck()
	else
		SplatoonSWEPs:SendError("SplatoonSWEPs: Required playermodel is not found!", NOTIFY_ERROR, 10, self.Owner)
	end
	
	return self:SharedDeploy()
end

function SWEP:Holster()
	if not (IsValid(self.Owner) and self.Owner:IsPlayer()) then return true end
	self:CallOnClient "Holster"
	if istable(self.BackupPlayerInfo) then --Restores owner's information.
		self:ChangePlayermodel(self.BackupPlayerInfo.Playermodel)
		self.Owner:SetColor(self.BackupPlayerInfo.Color)
	--	self.Owner:RemoveFlags(self.Owner:GetFlags()) --Restores no target flag and something.
	--	self.Owner:AddFlags(self.BackupPlayerInfo.Flags)
		self.Owner:SetJumpPower(self.BackupPlayerInfo.JumpPower)
		self.Owner:DrawShadow(true)
		self.Owner:SetMaterial ""
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
	
	if isfunction(self.ServerHolster) then self:ServerHolster() end
	return true
end

local inklingVM = ACT_VM_IDLE --Viewmodel animation(inkling)
local squidVM = ACT_VM_HOLSTER --Viewmodel animation(squid)
local throwingVM = ACT_VM_IDLE_LOWERED --Viewmodel animation(throwing sub weapon)
function SWEP:Think()
	if not IsValid(self.Owner) then return end
	self.IsSquid = self.Owner:IsPlayer()
	if self.IsSquid then
		self.IsSquid = self.Owner:Crouching()
	else
		self.IsSquid = self.Owner:GetFlags(FL_DUCKING)
	end
	
	--When in ink
	if not self.Owner:OnGround() and self:GetInInk() and self.Owner:KeyDown(IN_JUMP + IN_FORWARD + IN_BACK) then
		self.Owner:SetVelocity(self.Owner:GetForward() * 40 * self.Owner:EyeAngles().pitch / -90)
	end
	
	if self.SquidAvailable and self.PMID ~= SplatoonSWEPs.PLAYER.NOSQUID then
		self.Owner:SetMaterial(self.IsSquid and "color" or "")
		self:DrawShadow(not self.IsSquid)
	end
	
	--Send viewmodel animation.
	if self.IsSquid and self.ViewAnim ~= squidVM then
		self:SendWeaponAnim(squidVM)
		self.ViewAnim = squidVM
	elseif not self.IsSquid and self.ViewAnim ~= inklingVM then
		self:SendWeaponAnim(inklingVM)
		self.ViewAnim = inklingVM
	end
	
	if self.PMTable and self.PMTable.Model ~= self.Owner:GetModel() then
		self:ChangePlayermodel(self.PMTable)
	end
	
	self:ProcessSchedules()
	self:SetClip1(self:GetInk() / SplatoonSWEPs.MaxInkAmount * 100)
	if isfunction(self.ServerThink) then return self:ServerThink() end
end
