
AddCSLuaFile "baseinfo.lua"
AddCSLuaFile "shared.lua"
include "baseinfo.lua"
include "shared.lua"

util.PrecacheModel(SWEP.SquidModelName)

function SWEP:Initialize()
	self:SetHoldType(self.HoldType)
	self.MaxSpeed = 250
end

function SWEP:OnRemove()
	self:Holster()
end

function SWEP:ShouldDropOnDie()
	return true
end

local function ImmuneFallDamage(ply, speed)
	local weapon = ply:GetActiveWeapon()
	if IsValid(weapon) then
		if weapon.IsSplatoonWeapon then
			return 0
		end
	end
end
hook.Add("GetFallDamage", "Inklings don't take fall damage.", ImmuneFallDamage)
