AddCSLuaFile()

ENT.Type = "anim"
ENT.PrintName = "Traffic Light"
ENT.Category = "Decent Vehicle"
ENT.Spawnable = true
ENT.AdminOnly = false
ENT.RenderGroup = RENDERGROUP_TRANSLUCENT
ENT.Time = {36, 4, 40} -- Green, Yellow, Red

local Colors = {Color(0, 255, 0), Color(255, 191, 0), Color(255, 0, 0)}
local SpritePos = {-11.2, 0, 11.2}
local lr = "decentvehicle/trafficlight/lr"
local ly = "decentvehicle/trafficlight/ly"
local lg = "decentvehicle/trafficlight/lg"
local lightg = "decentvehicle/trafficlight/lightg"
local LightTable = {
	{lightg, lg, lightg},
	{lightg, lightg, ly},
	{lr, lightg, lightg},
}

function ENT:Think()
	local color = self:GetNWInt "DVTL_LightColor" % 3 + 1
	self:SetNWInt("DVTL_LightColor", color)
	self:NextThink(CurTime() + self.Time[color])
	for i = 1, 3 do
		self:SetSubMaterial(i, LightTable[color][i])
	end
	
	if SERVER then return true end
	self.SpriteColor = Colors[color]
	self.SpritePos = SpritePos[color]
	self:SetNextClientThink(CurTime() + self.Time[color])
end
