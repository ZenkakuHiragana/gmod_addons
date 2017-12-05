
SWEP.Base = "inklingbase"
SWEP.Spawnable = true
SWEP.FirePosition = Vector(6, -8, -8)

SWEP.Primary.Delay = 0.03
SWEP.Primary.TakeAmmo = .5

function SWEP:SharedSecondaryAttack(canattack)
	SplatoonSWEPs:ClearAllInk()
end

function SWEP:CustomDataTables()
	self:AddNetworkVar("Float", "ModifyWeaponSize") --Shooter expands its model when firing.
end
