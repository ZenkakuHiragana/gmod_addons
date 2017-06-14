
local classname = "nextbot_tracer"

ENT.Base = "base_nextbot"
ENT.Type = "nextbot"

ENT.PrintName = "Nextbot Tracer"
ENT.Author = "GreatZenkakuMan"
ENT.Contact = ""
ENT.Purpose = ""
ENT.Spawnable = false
ENT.AutomaticFrameAdvance = true
ENT.Model = "models/player/ow_tracer.mdl"
ENT.SearchAngle = 60
ENT.MaxNavAreas = 400 --Maximum amount of searching NavAreas.
ENT.Bravery = 6

ENT.Act = {}
ENT.Act.Idle = ACT_HL2MP_IDLE_DUEL
ENT.Act.Run = ACT_HL2MP_RUN_DUEL
ENT.Act.Walk = ACT_HL2MP_WALK_DUEL
ENT.Act.Attack = ACT_HL2MP_GESTURE_RANGE_ATTACK_DUEL
ENT.Act.Melee = ACT_HL2MP_GESTURE_RANGE_ATTACK_MELEE
ENT.Act.Reload = ACT_HL2MP_GESTURE_RELOAD_DUEL

ENT.Dist = {}
ENT.Dist.Search = 4000
ENT.Dist.ShootRange = 500
ENT.Dist.Melee = 100
ENT.Dist.Blink = 7 * 3.280839895 * 16 --blink distance in hammer unit, meters -> inches -> hammer units
ENT.Dist.BlinkSqr = ENT.Dist.Blink^2
ENT.Dist.Grenade = 300 --Distance for detecting grenades.
ENT.Dist.GrenadeSqr = ENT.Dist.Grenade^2
ENT.Dist.Manhack = ENT.Dist.Grenade / 2
ENT.Dist.ManhackSqr = ENT.Dist.Manhack^2
ENT.Dist.FindSpots = 3000 --Search radius for finding where the nextbot should move to.

ENT.HP = {}
ENT.HP.Init = 150

--GetConVar() needs to check if it's valid.  so this function wraps it.
function ENT:GetConVarBool(var)
	if not isstring(var) then return false end
	local convar = GetConVar(var)
	return convar and convar:GetBool()
end

--Returns the attachment of my eyes.
function ENT:GetEye()
	return self:GetAttachment(self:LookupAttachment("eyes"))
end

--Returns a table with information og what I am looking at.
function ENT:GetEyeTrace(dist)
	return util.QuickTrace(self:GetEye().Pos,
		self:GetEye().Ang:Forward() * (dist or 80), self)
end

--For Half Life Renaissance Reconstructed
function ENT:GetNoTarget()
	return false
end

--For Half Life Renaissance Reconstructed
function ENT:PercentageFrozen()
	return 0
end

list.Set("NPC", classname, {
	Name = "Nextbot Tracer",
	Class = classname,
	Category = "GreatZenkakuMan's NPCs"
})

local metatable = FindMetaTable("Entity")
local isnpc = metatable.IsNPC
--function metatable:IsNPC() return self:GetClass() == classname or isnpc(self) end
function metatable:AddEntityRelationship() end
function metatable:AddRelationship() end
function metatable:AlertSound() end
function metatable:CapabilitiesAdd() end
function metatable:CapabilitiesClear() end
function metatable:CapabilitiesGet() return CAP_MOVE_GROUND end
function metatable:CapabilitiesRemove() end
function metatable:Classify() return CLASS_CITIZEN_REBEL end
function metatable:ClearCondition() end
function metatable:ClearEnemyMemory() end
function metatable:ClearExpression() end
function metatable:ClearGoal() end
function metatable:ClearSchedule() end
function metatable:ClearSchedule() end
function metatable:GetActiveWeapon() return NULL end
function metatable:SetCurrentWeaponProficiency(p) end
function metatable:SetLastPosition(v) end
function metatable:SetTarget(p) end

--++Debugging functions++---------------------{
function ENT:ShowActAll()
	print("List of all available activities:")
	for i = 0, self:GetSequenceCount() - 1 do
		print(i .. " = " .. self:GetSequenceActivityName(i))
	end
end

function ENT:ShowSequenceAll()
	print("List of all available sequences:")
	PrintTable(self:GetSequenceList())
end

function ENT:ShowPoseParameters()
	for i = 0, self:GetNumPoseParameters() - 1 do
		local min, max = self:GetPoseParameterRange(i)
		print(self:GetPoseParameterName(i) .. " " .. min .. " / " .. max)
	end
end
----------------------------------------------}
