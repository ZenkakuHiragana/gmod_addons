
local ShootSound = Sound("NPC_Hunter.FlechetteShoot")
local ColorCodes = {
	Color(255, 128, 0),
	Color(255, 0, 255),
	Color(128, 0, 255),
	Color(0, 0, 255),
	Color(0, 255, 255),
	Color(0, 0, 255)
}
SWEP.InklingModel = {
	Girl = "models/drlilrobot/splatoon/ply/inkling_girl.mdl",
	Boy = "models/drlilrobot/splatoon/ply/inkling_boy.mdl",
}
SWEP.IsSplatoonWeapon = true
SWEP.Color = ColorCodes[math.random(1, #ColorCodes)]
SWEP.VectorColor = Vector(SWEP.Color.r / 255, SWEP.Color.g / 255, SWEP.Color.b / 255)

--Model from Enhanced Inklings 
SWEP.SquidModelName = "models/props_splatoon/squids/squid_beta.mdl"

function SWEP:ChangePlayermodel(data)
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
	
	if SERVER then
		timer.Simple(0.1, function()
			if IsValid(self) and IsValid(self.Owner) and isfunction(self.Owner.SetupHands) then
				self.Owner:SetupHands()
			end
		end)
	end
end

--Squids have a limited movement speed.
local function LimitSpeed(ply, data)
	if not IsValid(ply) or not ply:IsPlayer() then return end
	local weapon = ply:GetActiveWeapon()
	if not IsValid(weapon) then return end
	
	local maxspeed = weapon.MaxSpeed
	if not isnumber(maxspeed) then return end
	
	local velocity = ply:GetVelocity() --Inkling's current velocity
	local speed2D = velocity:Length2D() --Horizontal speed
	local dot = velocity:GetNormalized():Dot(-vector_up) --Checking if it's falling
	
	--Disruptors make Inkling slower
	if weapon.poison then
		maxspeed = maxspeed / 2
	end
	
	--This only limits horizontal speed.
	if speed2D > maxspeed then
		local newVelocity2D = Vector(velocity.x, velocity.y, 0)
		newVelocity2D = newVelocity2D:GetNormalized() * maxspeed
		velocity.x = newVelocity2D.x
		velocity.y = newVelocity2D.y
	end
	
	data:SetVelocity(velocity)
end
hook.Add("Move", "Limit Squid's Speed", LimitSpeed)

function SWEP:OwnerChanged()
	if not IsValid(self) or not IsValid(self.Owner) or not self.Owner:IsPlayer() then return true end
end

--Predicted Hooks
function SWEP:Deploy()
	if not IsValid(self) or not IsValid(self.Owner) or not self.Owner:IsPlayer() then return true end
	if game.SinglePlayer() then self:CallOnClient("Deploy") end
	
	self.BackupPlayerInfo = {
		Color = self.Owner:GetColor(),
		Flags = self.Owner:GetFlags(),
		JumpPower = self.Owner:GetJumpPower(),
		NoDraw = self.Owner:GetNoDraw(),
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
	}
	for k, v in pairs(self.BackupPlayerInfo.Playermodel.BodyGroups) do
		v.num = self.Owner:GetBodygroup(v.id)
	end
	
	self.Owner:SetColor(color_white)
	
	self.MaxSpeed = 250
	self.Owner:SetCrouchedWalkSpeed(0.5)
	self.Owner:SetMaxSpeed(self.MaxSpeed)
	self.Owner:SetRunSpeed(self.MaxSpeed)
	self.Owner:SetWalkSpeed(self.MaxSpeed)
	
	self:ChangePlayermodel({
		Model = self.InklingModel.Girl,
		Skin = 0,
		BodyGroups = {},
		SetOffsets = true,
		PlayerColor = self.VectorColor,
	})
	
	self:SetInkColorProxy(self.VectorColor)
	return true
end

function SWEP:Holster()
	if not IsValid(self) or not IsValid(self.Owner) or not self.Owner:IsPlayer() then return true end
	if game.SinglePlayer() then self:CallOnClient("Holster") end
	
	--Restores owner's information.
	if istable(self.BackupPlayerInfo) then
		self.Owner:SetColor(self.BackupPlayerInfo.Color)
	--	self.Owner:RemoveFlags(self.Owner:GetFlags())
	--	self.Owner:AddFlags(self.BackupPlayerInfo.Flags)
		self.Owner:SetJumpPower(self.BackupPlayerInfo.JumpPower)
		self.Owner:SetNoDraw(self.BackupPlayerInfo.NoDraw)
		self.Owner:SetRenderMode(self.BackupPlayerInfo.RenderMode)
		self.Owner:SetCrouchedWalkSpeed(self.BackupPlayerInfo.Speed.Crouched)
		self.Owner:SetDuckSpeed(self.BackupPlayerInfo.Speed.Duck)
		self.Owner:SetMaxSpeed(self.BackupPlayerInfo.Speed.Max)
		self.Owner:SetRunSpeed(self.BackupPlayerInfo.Speed.Run)
		self.Owner:SetWalkSpeed(self.BackupPlayerInfo.Speed.Walk)
		self.Owner:SetUnDuckSpeed(self.BackupPlayerInfo.Speed.UnDuck)
		
		self:ChangePlayermodel(self.BackupPlayerInfo.Playermodel)
	end
	
	if CLIENT then
		local vm = self.Owner:GetViewModel()
		if IsValid(vm) then self:ResetBonePositions(vm) end
		
		self.Owner:ManipulateBoneAngles(0, angle_zero)
	end
	return true
end

local HealingDelay = 0.01
function SWEP:Think()
	self:CallOnClient("Think")
	local issquid = self.Owner:Crouching()
	if IsFirstTimePredicted() then
		--Gradually heal the owner
		if CurTime() > self:GetNextHealTime() then
			local delay = HealingDelay
			if not self.Owner:Crouching() then
				delay = delay * 10
			end
			
			self.Owner:SetHealth(math.Clamp(self.Owner:Health() + 1, 0, self.Owner:GetMaxHealth()))
			self:SetNextHealTime(CurTime() + delay)
		end
		--Recharging ink
		if CurTime() > self:GetNextReloadTime() then
			local delay = 3 --3 seconds to recharge fully
			if not self:GetInInk() then
				delay = delay * 10
			end
			
			self:SetClip1(self:Clip1() + 1) --workaround!
			self:SetNextReloadTime(CurTime() + delay)
		end
		
		self.Owner:SetNoDraw(issquid)
	end
	
	if CLIENT then
		local a = (self.Owner:GetVelocity() + self.Owner:GetForward() * 40):Angle()
		if self.Owner:GetVelocity():LengthSqr() < 16 then
			a.p = 0
		elseif a.p > 45 and a.p <= 90 then
			a.p = 45
		elseif a.p >= 270 and a.p < 300 then
			a.p = 300
		else
			a.r = a.p
		end
		a.p = a.p - 90
		a.y = self.Owner:GetAngles().y
		a.r = 180
		
		self.Squid:SetAngles(a)
		self.Squid:SetPos(self.Owner:GetPos())
		self.Squid:SetEyeTarget(self.Squid:GetPos() + self.Squid:GetUp() * 100)
		
		self.Squid.ShouldDraw = issquid and not self.ViewModelFlag
		if issquid then
			self.Squid:DrawModel()
			self.Squid:CreateShadow()
		end
	end
end

function SWEP:Reload()
	
end

function SWEP:PrimaryAttack()
	if not self:CanPrimaryAttack() then return end
	self:SetNextPrimaryFire(CurTime() + 0.1)
	self:EmitSound(ShootSound)
	self:MuzzleFlash()
	self:SetModifyWeaponSize(CurTime())
	
	local rnda = self.Primary.Recoil * -1
	local rndb = self.Primary.Recoil * math.Rand(-1, 1)
	self.Owner:ViewPunch( Angle( rnda,rndb,rnda ) )
	
	if IsFirstTimePredicted() then
		
	end
end

--Throw sub weapon
function SWEP:SecondaryAttack()
	if not self:CanSecondaryAttack() then return end
	self:SetNextSecondaryFire(CurTime() + 0.5)
	self:EmitSound(ShootSound)
	self:MuzzleFlash()
	
	if IsFirstTimePredicted() then
		
	end
end
--Predicted Hooks

function SWEP:SetupDataTables()
	self:NetworkVar("Bool", 0, "InInk") --Whether or not owner is in ink.
	self:NetworkVar("Float", 0, "NextHealTime") --Owner heals gradually.
	self:NetworkVar("Float", 1, "NextReloadTime") --Owner recharging ink gradually.
	self:NetworkVar("Vector", 0, "InkColorProxy") --For material proxy.
	self:NetworkVar("Vector", 1, "CorrectInkColor")
	
	self:SetInInk(false)
	self:SetNextHealTime(CurTime())
	self:SetNextReloadTime(CurTime())
	self:SetInkColorProxy(self.VectorColor)
	self:SetCorrectInkColor(Vector(self.Color.r, self.Color.g, self.Color.b))
	
	if isfunction(self.CustomDataTables) then self:CustomDataTables() end
end

function SWEP:CustomDataTables()
	self:NetworkVar("Float", 2, "AimingDuration") --Passive when owner is not firing wrapon.
	self:NetworkVar("Float", 2, "ModifyWeaponSize") --Shooter expands its model when firing.
	self:SetAimingDuration(CurTime())
	self:SetModifyWeaponSize(CurTime() - 1)
end
