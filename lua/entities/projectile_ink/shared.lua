--[[
	The main projectile entity of Splatoon SWEPS!!!
]]

ENT.Type = "anim"
ENT.Base = "base_entity"
ENT.RenderGroup = RENDERGROUP_OPAQUE
 
local classname = "projectile_ink"
ENT.PrintName		= "Projectile Ink"
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
	self:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
	self:SetCustomCollisionCheck(true)
end

function ENT:SetupDataTables()
	self:NetworkVar("Bool", 0, "IsInk")
	self:NetworkVar("Int", 0, "ColorCode") --Color number
	self:NetworkVar("Vector", 0, "InkColorProxy") --For material proxy.
	self:NetworkVar("Vector", 2, "HitPos")
	self:NetworkVar("Vector", 3, "HitNormal")
end

local bound = Vector(1, 1, 1) * 10
hook.Add("ShouldCollide", "SplatoonSWEPs: Ink go through grates", function(ent1, ent2)
	local class1, class2 = ent1:GetClass(), ent2:GetClass()	
	local ink, targetent = ent1, ent2
	if class2 == classname then
		if class1 == clasname then return false end
		ink, targetent, class1, class2 = targetent, ink, class2, class1
	end
	if class1 ~= classname then return true end
	if SERVER and targetent:GetMaterialType() == MAT_GRATE then return false end
	local dir = ink:GetVelocity()
	local filter = player.GetAll()
	table.insert(filter, ink)
	local tr = util.TraceLine({
		start = ink:GetPos(),
		endpos = ink:GetPos() + dir,
		filter = filter,
	})
	return tr.MatType ~= MAT_GRATE
end)
