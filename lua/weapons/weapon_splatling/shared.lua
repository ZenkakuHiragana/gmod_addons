
local ss = SplatoonSWEPs
if not ss then return end
SWEP.Base = "weapon_shooter"

function SWEP:CustomActivity()
	local at = self:GetAimTimer()
	if CLIENT and self:IsCarriedByLocalPlayer() then at = at - self:Ping() end
	if CurTime() > at then return "crossbow" end
	local aimpos = select(3, self:GetFirePosition())
	aimpos = (aimpos == 3 or aimpos == 4) and "rpg" or "crossbow"
	return (self:GetADS() or self.Scoped
	and self:GetChargeProgress(CLIENT) > self.Primary.Scope.StartMove)
	and not ss.ChargingEyeSkin[self.Owner:GetModel()]
	and "ar2" or aimpos
end
