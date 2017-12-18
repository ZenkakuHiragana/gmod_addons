--[[
	The main projectile entity of Splatoon SWEPS!!!
]]

ENT.Type = "anim"
ENT.FlyingModel = "models/blooryevan/ink/inkprojectile.mdl"

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

function ENT:SharedInit(mdl)
	self:SetModel(mdl or self.FlyingModel)
	self:SetCollisionGroup(COLLISION_GROUP_INTERACTIVE_DEBRIS)
	self:SetCustomCollisionCheck(true)
end

function ENT:SetupDataTables()
	self:NetworkVar("Vector", 0, "InkColorProxy") --For material proxy.
end

local bound = SplatoonSWEPs.vector_one * 10
local classname = "projectile_ink"
hook.Add("ShouldCollide", "SplatoonSWEPs: Ink go through grates", function(ent1, ent2)
	local class1, class2 = ent1:GetClass(), ent2:GetClass()
	local collide1, collide2 = class1 == classname, class2 == classname
	if collide1 == collide2 then return false end
	-- local wep1 = isfunction(ent1.GetActiveWeapon) and IsValid(ent1:GetActiveWeapon()) and ent1:GetActiveWeapon()
	-- local wep2 = isfunction(ent2.GetActiveWeapon) and IsValid(ent2:GetActiveWeapon()) and ent2:GetActiveWeapon()
	-- if wep1 and wep2 then
		
	-- end
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
