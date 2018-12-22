
-- Copyright © 2018-2030 Decent Vehicle
-- written by ∩(≡＾ω＾≡)∩ (https://steamcommunity.com/id/greatzenkakuman/)
-- and DangerKiddy(DK) (https://steamcommunity.com/profiles/76561198132964487/).

include "shared.lua"
include "playermeta.lua"

local dvd = DecentVehicleDestination
function ENT:Think()
	self:SetDriverPosition()
	self:SetSequence(self:GetNWInt "Sequence")
end

function ENT:Draw()
	local seat = self:GetNWEntity "Seat"
	if IsValid(seat) then
		self:SetPos(seat:LocalToWorld(self:GetNWVector "Pos"))
		self:SetAngles(seat:LocalToWorldAngles(self:GetNWAngle "Ang"))
		self:SetupBones()
	end
	
	self:DrawModel()
end
