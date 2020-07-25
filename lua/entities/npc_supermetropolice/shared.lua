AddCSLuaFile()
include "npcmeta.lua"

ENT.Base = "base_nextbot"
ENT.Category = "GreatZenkakuMan's NPCs"
ENT.ClassName = "npc_supermetropolice"
ENT.Enum = {}
ENT.PrintName = "Super Metropolice"
ENT.ModelName = "models/player/police_fem.mdl"
ENT.Skin = 0
ENT.Spawnable = false
ENT.Type = "nextbot"
list.Set("NPC", ENT.ClassName, {
    Category = ENT.Category,
    Class = ENT.ClassName,
    Name = ENT.PrintName,
})

ENT.Enum.ACT = {
    ACT_HL2MP_IDLE_COWER = 2062,
    ACT_HL2MP_SWIM_IDLE = 2063,
    ACT_HL2MP_SIT_CAMERA = 2064,
    ACT_HL2MP_SIT_DUEL = 2065,
    ACT_HL2MP_SIT_PASSIVE = 2066,
    ACT_GMOD_DEATH = 2067,
    ACT_GMOD_SHOWOFF_STAND_01 = 2068,
    ACT_GMOD_SHOWOFF_STAND_02 = 2069,
    ACT_GMOD_SHOWOFF_STAND_03 = 2070,
    ACT_GMOD_SHOWOFF_STAND_04 = 2071,
    ACT_GMOD_SHOWOFF_DUCK_01 = 2072,
    ACT_GMOD_SHOWOFF_DUCK_02 = 2073,
    ACT_FLINCH = 2074,
    ACT_FLINCH_BACK = 2075,
    ACT_FLINCH_SHOULDER_LEFT = 2076,
    ACT_FLINCH_SHOULDER_RIGHT = 2077,
    ACT_DRIVE_POD = 2078,
    ACT_HL2MP_ZOMBIE_SLUMP_ALT_IDLE = 2079,
    ACT_HL2MP_ZOMBIE_SLUMP_ALT_RISE_FAST = 2080,
    ACT_HL2MP_ZOMBIE_SLUMP_ALT_RISE_SLOW = 2081,
    ACT_HL2MP_GESTURE_RELOAD_AR2_PRONE = 2082,
    ACT_HL2MP_GESTURE_RELOAD_PISTOL_PRONE = 2083,
    ACT_HL2MP_GESTURE_RELOAD_REVOLVER_PRONE = 2084,
    ACT_HL2MP_GESTURE_RELOAD_SMG1_PRONE = 2085,
    ACT_HL2MP_GESTURE_RELOAD_DUEL_PRONE = 2086,
    ACT_HL2MP_GESTURE_RELOAD_SHOTGUN_PRONE = 2087,
}

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
