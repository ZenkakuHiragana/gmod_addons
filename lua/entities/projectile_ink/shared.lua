--[[
	The main projectile entity of Splatoon SWEPS!!!
]]

ENT.Type = "anim"
ENT.Base = "base_entity"
ENT.RenderGroup = RENDERGROUP_OPAQUE
 
ENT.PrintName		= "Projectile_Ink"
ENT.Author			= "GreatZenkakuMan"
ENT.Contact			= "GitHub repository here"
ENT.Purpose			= "Projectile Ink"
ENT.Instructions	= ""
ENT.AutomaticFrameAdvance = true

ENT.Spawnable = false
ENT.AdminOnly = false
ENT.DisableDuplicator = true

local HitSound = {} --When ink meets wall
for i = 0, 20 do
	local number = tostring(i)
	if i < 10 then number = "0" .. tostring(i) end
--	table.insert(HitSound, i, Sound("SplatoonSWEPs/misc/inkHit/inkHit" .. number .. ".wav"))
end

local Slime = {} --Footsteps sound.
for i = 0, 4 do
--	table.insert(Slime, i, Sound("SplatoonSWEPs/misc/slime/slime0" .. tostring(i) .. ".wav"))
end

local DmgSound = Sound("SplatoonSWEPs/misc/DamageInkLook00.wav") --When ink meets enemy player.
ENT.FlyingModel = "models/blooryevan/ink/inkprojectile.mdl"

function ENT:SharedInit()
	self:SetModel(self.FlyingModel)
	self:PhysicsInit(SOLID_BBOX)
	self:SetSolid(SOLID_BBOX)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetCollisionGroup(COLLISION_GROUP_INTERACTIVE_DEBRIS)
end

function ENT:SetupDataTables()
	self:NetworkVar("Bool", 0, "IsInk")
	self:NetworkVar("Vector", 0, "InkColorProxy") --For material proxy.
	self:NetworkVar("Vector", 1, "CurrentInkColor") --Hex Color code
	self:NetworkVar("Vector", 2, "HitPos")
	self:NetworkVar("Vector", 3, "HitNormal")
	self:SetCurrentInkColor(vector_origin)
end
