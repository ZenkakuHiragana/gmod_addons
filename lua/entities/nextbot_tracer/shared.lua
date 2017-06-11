
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

ENT.Act = {}
ENT.Act.Idle = ACT_HL2MP_IDLE_DUEL
ENT.Act.Run = ACT_HL2MP_RUN_DUEL
ENT.Act.Walk = ACT_HL2MP_WALK_DUEL
ENT.Act.Attack = ACT_HL2MP_GESTURE_RANGE_ATTACK_DUEL
ENT.Act.Reload = ACT_HL2MP_GESTURE_RELOAD

ENT.Dist = {}
ENT.Dist.Search = 4000
ENT.Dist.ShootRange = 500
ENT.Dist.Melee = 100
ENT.Dist.Blink = 7 * 3.280839895 * 16 --blink distance in hammer unit, meters -> inches -> hammer units

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
