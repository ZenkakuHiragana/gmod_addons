AddCSLuaFile "cl_init.lua"
AddCSLuaFile "shared.lua"
include "shared.lua"

local Time = {36, 4, 40} -- Green, Yellow, Red
local lr = "decentvehicle/trafficlight/lr"
local ly = "decentvehicle/trafficlight/ly"
local lg = "decentvehicle/trafficlight/lg"
local lightg = "decentvehicle/trafficlight/lightg"
local LightTable = {
	{lightg, lg, lightg},
	{lightg, lightg, ly},
	{lr, lightg, lightg},
}

function ENT:Initialize()
	self:SetModel "models/decentvehicle/trafficlight.mdl"
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	
	local phys = self:GetPhysicsObject()
	if not IsValid(phys) then return end
	phys:SetMass(50)
	phys:Wake()
	
	self:DrawShadow(false)
	self:Fire "DisableCollision"
	self:SetNWInt("DVTL_LightColor", 1)
end

function ENT:SpawnFunction(ply, tr, ClassName)
	if not tr.Hit then return end
	local SpawnPos = tr.HitPos + tr.HitNormal
	local ent = ents.Create(ClassName)
	if not IsValid(ent) then return end
	ent:SetPos(SpawnPos + vector_up * 18)
	ent:SetAngles(Angle(0, ply:GetAngles().yaw, 0))
	ent:Spawn()
	return ent
end

function ENT:Think()
	self:SetNWInt("DVTL_LightColor", self:GetNWInt "DVTL_LightColor" % 3 + 1)
	
	local color = self:GetNWInt "DVTL_LightColor"
	self:NextThink(CurTime() + Time[color])
	
	for i = 1, 3 do
		self:SetSubMaterial(i, LightTable[color][i])
	end
	
	return true
end
