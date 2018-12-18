
-- Copyright © 2018-2030 Decent Vehicle
-- written by ∩(≡＾ω＾≡)∩ (https://steamcommunity.com/id/greatzenkakuman/)
-- and DangerKiddy(DK) (https://steamcommunity.com/profiles/76561198132964487/).

include "shared.lua"
include "playermeta.lua"

local dvd = DecentVehicleDestination
function ENT:Initialize()
	self:SetModel(istable(self.Model) and
	self.Model[math.random(#self.Model)] or
	self.Model or dvd.DefaultDriverModel[math.random(#dvd.DefaultDriverModel)])
	self:SetSequence "drive_jeep"
end

function ENT:Draw()
	if not IsValid(self:GetSeat()) then return end
	self:SetPos(self:GetSeat():LocalToWorld(self:GetSeatPos()))
	self:SetAngles(self:GetSeat():LocalToWorldAngles(self:GetSeatAng()))
	self:SetupBones()
	self:DrawModel()
end
