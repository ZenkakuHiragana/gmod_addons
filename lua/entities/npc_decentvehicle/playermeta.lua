
-- Copyright © 2018-2030 Decent Vehicle
-- written by ∩(≡＾ω＾≡)∩ (https://steamcommunity.com/id/greatzenkakuman/)
-- and DangerKiddy(DK) (https://steamcommunity.com/profiles/76561198132964487/).

function ENT:AccountID() end -- For bots and in singleplayer, return no value
function ENT:AddCleanup() end
function ENT:AddCount() end
function ENT:AddVCDSequenceToGestureSlot() end
function ENT:Alive() return self:Health() > 0 end
function ENT:AllowFlashlight() end
function ENT:AnimResetGestureSlot() end
function ENT:AnimRestartGesture() end
function ENT:AnimRestartMainSequence() end
function ENT:AnimSetGestureSequence() end
function ENT:AnimSetGestureWeight() end
function ENT:Armor() return 0 end
function ENT:CanUseFlashlight() return false end
function ENT:ChatPrint() end
function ENT:CheckLimit() return true end
function ENT:ConCommand() end
function ENT:Crouching() return false end
function ENT:Deaths() return 0 end
function ENT:DoAnimationEvent() end
function ENT:DoAttackEvent() end
function ENT:DoCustomAnimEvent() end
function ENT:DoReloadEvent() end
function ENT:DoSecondaryAttack() end
function ENT:DrawViewModel() end
function ENT:FlashlightIsOn() return false end
function ENT:Frags() return 0 end
function ENT:PlayerEnteredSCar() end -- For SCAR base
function ENT:OnTakeDamage() end -- For SCAR base
function ENT:RemoveCarConnection() end -- For SCAR base
function ENT:InVehicle() return true end
function ENT:GetVehicle() return self.v end
function ENT:GetViewEntity() return NULL end
function ENT:Give() end
function ENT:SelectWeapon() end
function ENT:SetEyeAngles() end
function ENT:GetViewPunchAngles() return Angle() end
function ENT:SetViewPunchAngles() end
function ENT:UniqueID() return self:EntIndex() end
function ENT:Team() return TEAM_UNASSIGNED end

if CLIENT then
	function ENT:AddPlayerOption() end
	function ENT:KeyDown() return false end
	return
end

local InfoNum = {
	cl_simfphys_ctenable = 1,
	cl_simfphys_ctmul = .7,
	cl_simfphys_ctang = 15,
	cl_simfphys_auto = 1,
}
function ENT:GetInfoNum(key, default) --For Simfphys Vehicles
	return InfoNum[key] or isnumber(default) and default or 0
end

function ENT:AddDeaths() end
function ENT:AddFrags() end
function ENT:AddFrozenPhysicsObject() end
function ENT:AllowImmediateDecalPainting() end
function ENT:Ban() end
function ENT:CreateRagdoll() end
function ENT:CrosshairDisable() end
function ENT:CrosshairEnable() end
function ENT:DebugInfo() end
function ENT:DetonateTripmines() end
function ENT:DrawWorldModel() end
function ENT:DropNamedWeapon() end
function ENT:DropObject() end
function ENT:DropWeapon() end
function ENT:EnterVehicle() end
function ENT:EquipSuit() end
function ENT:ExitVehicle() end
function ENT:Flashlight() end
function ENT:Freeze() end
function ENT:SendHint() end
function ENT:KeyDown(key)
	return key == IN_FORWARD and self.Throttle > 0
	or key == IN_BACK and self.Throttle < 0
	or key == IN_MOVELEFT and self.Steering < 0
	or key == IN_MOVERIGHT and self.Steering > 0
	or key == IN_JUMP and self.HandBrake
	or false
end

if Photon then
	function ENT:IsBraking()
		local dv = self.DecentVehicle
		if not IsValid(dv) then return false end
		return dv.HandBrake
	end

	function ENT:IsReversing()
		local dv = self.DecentVehicle
		if not IsValid(dv) then return false end
		return dv.Throttle < 0 and self:GetVelocity():Dot(dv:GetVehicleForward()) < 0
	end
end

local dvd = DecentVehicleDestination
local vehiclemeta = FindMetaTable "Vehicle"
local GetDriver = vehiclemeta.GetDriver
if not dvd or dvd.HasChangedVehicleMeta then return end
function vehiclemeta:GetDriver(...)
	if self.DecentVehicle then
		if Photon and istable(self.VehicleTable) and self.VehicleTable.Photon
		and IsValid(self.PhotonVehicleSpawner) and self.PhotonVehicleSpawner:IsPlayer() then
			return self.PhotonVehicleSpawner
		elseif self.__IsSW_Motorbike then
			return self.DecentVehicle
		end
	end

	return GetDriver(self, ...)
end

dvd.HasChangedVehicleMeta = true
