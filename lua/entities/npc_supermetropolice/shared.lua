AddCSLuaFile()
include "npcmeta.lua"

ENT.Base = "base_nextbot"
ENT.Category = "GreatZenkakuMan's NPCs"
ENT.ClassName = "npc_supermetropolice"
ENT.Enum = {}
ENT.PrintName = "Super Metropolice"
ENT.Spawnable = false
ENT.Type = "nextbot"
list.Set("NPC", ENT.ClassName, {
    Category = ENT.Category,
    Class = ENT.ClassName,
    Name = ENT.PrintName,
})

function ENT:GetEyePos()
    return self:GetAttachment(self:LookupAttachment "eyes").Pos
end

function ENT:GetActiveWeapon()
    return self:GetNWEntity "ActiveWeapon"
end

function ENT:ShowPoseParameters()
	for i = 0, self:GetNumPoseParameters() - 1 do
		local min, max = self:GetPoseParameterRange(i)
		print(self:GetPoseParameterName(i) .. " " .. min .. " / " .. max)
	end
end
