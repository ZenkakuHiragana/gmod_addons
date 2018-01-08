
SplatoonSWEPs:AddTimerFramework(SWEP)
function SWEP:ChangePlayermodel(data)
	-- if SERVER then return end
	self.Owner:SetModel(data.Model)
	self.Owner:SetSkin(data.Skin)
	local bodygroups = ""
	local numgroups = self.Owner:GetNumBodyGroups()
	if isnumber(numgroups) then
		for k = 0, self.Owner:GetNumBodyGroups() - 1 do
			local v = data.BodyGroups[k + 1]
			if istable(v) and isnumber(v.num) then v = v.num else v = 0 end
			self.Owner:SetBodygroup(k, v)
			bodygroups = bodygroups .. tostring(v) .. " "
		end
	end
	if bodygroups == "" then bodygroups = "0" end
	if data.SetOffsets then
		self.Owner:SetNWInt("splt_isSet", 1)
		self.Owner:SetNWInt("splt_SplatoonOffsets", 2)
		if isfunction(self.Owner.SplatoonOffsets) then
			self.Owner:SplatoonOffsets()
		end
	else
		self.Owner:SetNWInt("splt_isSet", 0)
		self.Owner:SetNWInt("splt_SplatoonOffsets", 1)
		if isfunction(self.Owner.DefaultOffsets) then
			self.Owner:DefaultOffsets()
		end
	end
	self.Owner:SetSubMaterial()
	self.Owner:SetPlayerColor(data.PlayerColor)
	self.Owner:ConCommand("cl_playermodel " .. player_manager.TranslateToPlayerModelName(data.Model))
	self.Owner:ConCommand("cl_playerskin " .. tostring(data.Skin))
	self.Owner:ConCommand("cl_playerbodygroups " .. bodygroups)
	self.Owner:ConCommand("cl_playercolor " .. tostring(data.PlayerColor))
	
	local hands = self.Owner:GetHands()
	if IsValid(hands) then
		local info = player_manager.TranslatePlayerHands(player_manager.TranslateToPlayerModelName(data.Model))
		if info then
			hands:SetModel(info.model)
			hands:SetSkin(info.skin)
			hands:SetBodyGroups(info.body)
		end
	end
end

function SWEP:ChangeHullDuck()
	if not (IsValid(self.Owner) and self.Owner:IsPlayer()) then return end
	if self:GetPMID() ~= SplatoonSWEPs.PLAYER.NOSQUID then
		self.Owner:SetHullDuck(SplatoonSWEPs.SquidBoundMins, SplatoonSWEPs.SquidBoundMaxs)
		self.Owner:SetViewOffsetDucked(SplatoonSWEPs.SquidViewOffset)
	end
end

function SWEP:SetPlayerSpeed(spd)
	self.MaxSpeed = spd
	self.Owner:SetMaxSpeed(self.MaxSpeed)
	self.Owner:SetRunSpeed(self.MaxSpeed)
	self.Owner:SetWalkSpeed(self.MaxSpeed)
end

--When NPC weapon is picked up by player.
function SWEP:OwnerChanged()
	if not (IsValid(self.Owner) and self.Owner:IsPlayer()) then return true end
end

function SWEP:SharedInitBase()
	self.SwimSound = CreateSound(self, SplatoonSWEPs.SwimSound)
	self.EnemyInkSound = CreateSound(self, SplatoonSWEPs.EnemyInkSound)
	if isfunction(self.SharedInit) then return self:SharedInit() end
end

--Predicted hooks
function SWEP:SharedDeployBase()
	self.SwimSound:Play()
	self.EnemyInkSound:Play()
	self.SwimSound:ChangeVolume(0)
	self.EnemyInkSound:ChangeVolume(0)
	self.CanHealStand = SplatoonSWEPs:GetConVarBool "CanHealStand"
	self.CanHealInk = SplatoonSWEPs:GetConVarBool "CanHealInk"
	self.CanReloadStand = SplatoonSWEPs:GetConVarBool "CanReloadStand"
	self.CanReloadInk = SplatoonSWEPs:GetConVarBool "CanReloadInk"
	self.BackupPlayerInfo = {
		Color = self.Owner:GetColor(),
		Flags = self.Owner:GetFlags(),
		JumpPower = self.Owner:GetJumpPower(),
		MoveType = self.Owner:GetMoveType(),
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
	
	if isfunction(self.SharedDeploy) then self:SharedDeploy() end
	return true
end

function SWEP:SharedHolsterBase()
	self.SwimSound:ChangeVolume(0)
	self.EnemyInkSound:ChangeVolume(0)
	self.SwimSound:Stop()
	self.EnemyInkSound:Stop()
	self.PMTable = nil
	if istable(self.BackupPlayerInfo) then --Restores owner's information.
		self:ChangePlayermodel(self.BackupPlayerInfo.Playermodel)
		self.Owner:SetColor(self.BackupPlayerInfo.Color)
	--	self.Owner:RemoveFlags(self.Owner:GetFlags()) --Restores no target flag and something.
	--	self.Owner:AddFlags(self.BackupPlayerInfo.Flags)
		self.Owner:SetJumpPower(self.BackupPlayerInfo.JumpPower)
		self.Owner:DrawShadow(true)
		self.Owner:SetMaterial ""
		self.Owner:SetMoveType(self.BackupPlayerInfo.MoveType)
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
	
	if isfunction(self.SharedHolster) then self:SharedHolster() end
	return true
end

local inklingVM = ACT_VM_IDLE --Viewmodel animation(inkling)
local squidVM = ACT_VM_HOLSTER --Viewmodel animation(squid)
local throwingVM = ACT_VM_IDLE_LOWERED --Viewmodel animation(throwing sub weapon)
function SWEP:SharedThinkBase()
	if SERVER or self:IsFirstTimePredicted() then
		local sq = self.Owner:IsPlayer()
		if sq then
			sq = self.Owner:Crouching()
		else
			sq = self.Owner:GetFlags(FL_DUCKING)
		end
	
		--Send viewmodel animation.
		if self.IsSquid and self.ViewAnim ~= squidVM then
			self:SendWeaponAnim(squidVM)
			self.ViewAnim = squidVM
		elseif not self.IsSquid and self.ViewAnim ~= inklingVM then
			self:SendWeaponAnim(inklingVM)
			self.ViewAnim = inklingVM
		end
		
		if not self.Holstering and self.PMTable and self.PMTable.Model ~= self.Owner:GetModel() then
			self:ChangePlayermodel(self.PMTable)
		end
		
		if sq then
			self.SwimSound:ChangeVolume(self:GetInInk() and self.Owner:GetVelocity():LengthSqr()
				/ SplatoonSWEPs.SquidBaseSpeed / SplatoonSWEPs.SquidBaseSpeed or 0)
			if not self.IsSquid then
				self.Owner:RemoveAllDecals()
				if CLIENT then self.Owner:EmitSound "SplatoonSWEPs_Player.ToSquid" end
			end
			
			if self:GetOnEnemyInk() then
				self:AddSchedule(SplatoonSWEPs:FrameToSec(20), 1, function(self, schedule)
					self.EnemyInkPreventCrouching = self:GetOnEnemyInk()
				end)
			end
		elseif not sq and self.IsSquid then
			self.SwimSound:ChangeVolume(0)
			if CLIENT then self.Owner:EmitSound "SplatoonSWEPs_Player.ToHuman" end
		end
		
		self.IsSquid = sq
	end
	if isfunction(self.SharedThink) then return self:SharedThink() end
end

--Begin to use special weapon.
function SWEP:Reload()
	if game.SinglePlayer() then self:CallOnClient "Reload" end
	
end

function SWEP:CommonFire(isprimary)
	if self.CrouchPriority then return false end
	local Weapon = isprimary and self.Primary or self.Secondary
	local laggedvalue = self.Owner:IsPlayer() and self.Owner:GetLaggedMovementValue() or 1
	self.ReloadSchedule:SetDelay(Weapon.ReloadDelay * laggedvalue)
	self:SetNextCrouchTime(CurTime() + Weapon.CrouchDelay * laggedvalue)
	
	if self:GetInk() <= 0 then return false end --Check remaining amount of ink
	self:SetNextPrimaryFire(CurTime() + Weapon.Delay * laggedvalue)
	self:MuzzleFlash()
	
	if math.random() < Weapon.PlayAnimPercent then
		self.Owner:SetAnimation(PLAYER_ATTACK1)
	end
	
	if self.Owner:IsPlayer() then
		local rnda = Weapon.Recoil * -1
		local rndb = Weapon.Recoil * util.SharedRandom(
		"SplatoonSWEPs: Weapon base recoil" .. self:EntIndex(), -1, 1)
		self.Owner:ViewPunch(Angle(rnda, rndb, rnda)) --Apply viewmodel punch
	end
	
	return true
end

--Shoot ink.
function SWEP:PrimaryAttack()
	local canattack = self:CommonFire(true)
	if game.SinglePlayer() then self:CallOnClient "PrimaryAttack" end
	if isfunction(self.SharedPrimaryAttack) then self:SharedPrimaryAttack(canattack) end
	if SERVER and isfunction(self.ServerPrimaryAttack) then
		return self:ServerPrimaryAttack(canattack)
	elseif CLIENT and isfunction(self.ClientPrimaryAttack) then
		return self:ClientPrimaryAttack(canattack)
	end
end

--Use sub weapon
function SWEP:SecondaryAttack()
	local canattack = self:CommonFire(false)
	if game.SinglePlayer() then self:CallOnClient "SecondaryAttack" end
	if isfunction(self.SharedSecondaryAttack) then self:SharedSecondaryAttack(canattack) end
	if SERVER and isfunction(self.ServerSecondaryAttack) then
		return self:ServerSecondaryAttack(canattack)
	elseif CLIENT and isfunction(self.ClientSecondaryAttack) then
		return self:ClientSecondaryAttack(canattack)
	end
end
--End of predicted hooks

local NetworkVarNotifyCallsOnClient = false
function SWEP:ChangeInInk(name, old, new)
	if not NetworkVarNotifyCallsOnClient then
		if SERVER then
			self:CallOnClient("ChangeInInk", table.concat({name, tostring(old), tostring(new)}, " "))
		elseif not self:IsFirstTimePredicted() then return else
			old, new = tobool(old), tobool(new)
		end
	end
	
	old, new = tobool(old), tobool(new)
	local outofink = old and not new
	local intoink = not old and new
	if outofink == intoink then return end
	self.Owner:SetCrouchedWalkSpeed(intoink and 1 or 0.5)
	self:SetPlayerSpeed(intoink and SplatoonSWEPs.SquidBaseSpeed or SplatoonSWEPs.InklingBaseSpeed)
	if intoink and SERVER then
		local velocity = self.OwnerVelocity:Length()
		if self.Owner:OnGround() and velocity > 400 then
			local dp = math.Clamp(600 - velocity, 0, 200) / 2
			self.Owner:EmitSound("SplatoonSWEPs_Player.InkDiveDeep", 75, 100 + dp, .5, CHAN_BODY)
		else
			local dp = 50 - velocity / 4
			self.Owner:EmitSound("SplatoonSWEPs_Player.InkDiveShallow", 75, 100 + dp, .5, CHAN_BODY)
		end
	elseif outofink then
		self.OnOutOfInk = true
	end
end

function SWEP:ChangeOnEnemyInk(name, old, new)
	if not NetworkVarNotifyCallsOnClient then
		if SERVER then
			self:CallOnClient("ChangeOnEnemyInk", table.concat({name, tostring(old), tostring(new)}, " "))
		elseif not self:IsFirstTimePredicted() then return else
			old, new = tobool(old), tobool(new)
		end
	end
	
	local outofink = old and not new
	local intoink = not old and new
	if outofink == intoink then return
	elseif intoink then
		self:SetPlayerSpeed(SplatoonSWEPs.OnEnemyInkSpeed) --Hard to move
		self.Owner:SetJumpPower(SplatoonSWEPs.OnEnemyInkJumpPower) --Reduce jump power
		self.EnemyInkSound:ChangeVolume(1, 0.5)
		
		if CLIENT then return end
		self:AddSchedule(SplatoonSWEPs:FrameToSec(2), function(self, schedule)
			if not self:GetOnEnemyInk() then return true end --Enemy ink damage
			if self.Owner:Health() > self.Owner:GetMaxHealth() / 2 then
				self.Owner:SetHealth(self.Owner:Health() - 1)
			end
		end)
		
		self:AddSchedule(SplatoonSWEPs:FrameToSec(20), 1, function(self, schedule)
			self.EnemyInkPreventCrouching = self:GetOnEnemyInk()
		end)
	else
		self:SetPlayerSpeed(self:GetInInk() and SplatoonSWEPs.SquidBaseSpeed or SplatoonSWEPs.InklingBaseSpeed)
		self.Owner:SetJumpPower(SplatoonSWEPs.InklingJumpPower) --Restore
		self.EnemyInkSound:ChangeVolume(0, 0.5)
	end
end

local ReloadMultiply = 1 / 0.12 --Reloading rate(inkling)
local HealingDelay = 0.1 --Healing rate(inkling)
function SWEP:GetLastSlot(typeof) return self.NetworkSlot[typeof] end
function SWEP:AddNetworkVar(typeof, name)
	if self.NetworkSlot[typeof] >= 31 then error "SplatoonSWEPs: Tried to use too many network vars!" end
	self.NetworkSlot[typeof] = self.NetworkSlot[typeof] + 1
	self:NetworkVar(typeof, self.NetworkSlot[typeof], name)
	return self.NetworkSlot[typeof]
end

function SWEP:SetupDataTables()
	self.FunctionQueue = {}
	self.NetworkSlot = {
		String = -1, Bool = -1, Float = -1, Int = -1,
		Vector = -1, Angle = -1, Entity = -1,
	}
	self:AddNetworkVar("Bool", "InInk") --If owner is in ink.
	self:AddNetworkVar("Bool", "InWallInk") --If owner is on wall.
	self:AddNetworkVar("Bool", "OnEnemyInk") --If owner is on enemy ink.
	-- self:AddNetworkVar("Bool", "CrouchPriority") --If crouch input takes a priority.
	self:AddNetworkVar("Float", "Ink") --Ink remainig. 0 ~ SplatoonSWEPs.MaxInkAmount
	self:AddNetworkVar("Vector", "InkColorProxy") --For material proxy.
	self:AddNetworkVar("Float", "NextCrouchTime") --Shooting cooldown.
	self:AddNetworkVar("Int", "PMID") --Playermodel ID
	self:AddNetworkSchedule(HealingDelay, function(self, schedule) --Gradually heals the owner
		local canheal = self.CanHealInk and self:GetInInk()
		schedule:SetDelay(HealingDelay / (canheal and 8 or 1))
		if not self:GetOnEnemyInk() and (self.CanHealStand or canheal) then
			self.Owner:SetHealth(math.Clamp(self.Owner:Health() + 1, 0, self.Owner:GetMaxHealth()))
		end
	end)
	
	self.ReloadSchedule = self:AddNetworkSchedule(0,
	function(self, schedule) --Recharging ink
		local reloadamount = math.max(0, schedule:SinceLastCalled())
		local canreload = self.CanReloadInk and self:GetInInk()
		local mul = ReloadMultiply * (canreload and 4 or 1)
		if self.CanReloadStand or canreload then
			self:SetInk(math.Clamp(self:GetInk() + reloadamount * mul, 0, SplatoonSWEPs.MaxInkAmount))
		end
		
		schedule:SetDelay(0)
	end)
	
	self:NetworkVarNotify("InInk", self.ChangeInInk)
	self:NetworkVarNotify("OnEnemyInk", self.ChangeOnEnemyInk)
	if isfunction(self.CustomDataTables) then self:CustomDataTables() end
end
