
local holdtypes = {
	"ar2",
	"crossbow",
	"grenade",
	"melee",
	"melee2",
	"passive",
	"pistol",
	"revolver",
	"rpg",
	"shotgun",
	"smg",
}
local a = ENT.Enum.ACT
local ActivityTranslation = {
	[ ACT_IDLE ] = {
		smg = ACT_IDLE_SMG1,
		ar2 = {ACT_IDLE_RIFLE, ACT_IDLE_SMG1},
		pistol = ACT_IDLE_PISTOL,
		shotgun = {ACT_IDLE_SHOTGUN, ACT_IDLE_SMG1},
		melee = ACT_IDLE_MELEE,
		passive = ACT_IDLE,
		grenade = ACT_IDLE,
	},
	[ ACT_IDLE_ANGRY ] = {
		fallback = ACT_IDLE,
		smg = ACT_IDLE_ANGRY_SMG1,
		ar2 = ACT_IDLE_ANGRY_SMG1,
		pistol = ACT_IDLE_ANGRY_PISTOL,
		shotgun = {ACT_IDLE_ANGRY_SHOTGUN, ACT_IDLE_ANGRY_SMG1},
		melee = ACT_IDLE_ANGRY_MELEE,
		passive = ACT_IDLE_ANGRY,
		grenade = ACT_IDLE_ANGRY,
	},
	[ ACT_IDLE_RELAXED ] = {
		fallback = ACT_IDLE,
		smg = ACT_IDLE_SMG1_RELAXED,
		ar2 = ACT_IDLE_SMG1_RELAXED,
		shotgun = {ACT_IDLE_SHOTGUN_RELAXED, ACT_IDLE_SMG1_RELAXED},
	},
	[ ACT_IDLE_STIMULATED ] = {
		fallback = ACT_IDLE,
		smg = ACT_IDLE_SMG1_STIMULATED,
		ar2 = ACT_IDLE_SMG1_STIMULATED,
		shotgun = {ACT_IDLE_SHOTGUN_STIMULATED, ACT_IDLE_SMG1_STIMULATED},
	},
	[ ACT_IDLE_AGITATED ] = {
		fallback = ACT_IDLE_STIMULATED,
		shotgun = ACT_IDLE_SHOTGUN_AGITATED,
	},
	[ ACT_WALK ] = {
		smg = ACT_WALK_RIFLE,
		ar2 = ACT_WALK_RIFLE,
		pistol = ACT_WALK_PISTOL,
		shotgun = ACT_WALK_RIFLE,
		melee = ACT_WALK,
		passive = ACT_WALK,
		grenade = ACT_WALK,
		rpg = ACT_WALK_RPG,
	},
	[ ACT_WALK_RELAXED ] = {
		fallback = ACT_WALK,
		smg = ACT_WALK_RIFLE_RELAXED,
		ar2 = ACT_WALK_RIFLE_RELAXED,
		shotgun = ACT_WALK_RIFLE_RELAXED,
		rpg = ACT_WALK_RPG_RELAXED,
	},
	[ ACT_WALK_STIMULATED ] = {
		fallback = ACT_WALK,
		smg = ACT_WALK_RIFLE_STIULATED,
		ar2 = ACT_WALK_RIFLE_STIULATED,
		shotgun = ACT_WALK_RIFLE_STIMULATED,
	},
	[ ACT_WALK_STEALTH ] = {
		fallback = ACT_WALK,
		pistol = ACT_WALK_STEALTH_PISTOL,
	},
	[ ACT_WALK_AIM ] = {
		fallback = ACT_WALK,
		smg = ACT_WALK_AIM_RIFLE,
		ar2 = ACT_WALK_AIM_RIFLE,
		pistol = ACT_WALK_AIM_PISTOL,
		shotgun = ACT_WALK_AIM_SHOTGUN,
	},
	[ ACT_WALK_AIM_STIMULATED ] = {
		fallback = ACT_WALK_AIM,
		smg = ACT_WALK_AIM_RIFLE_STIMULATED,
		ar2 = ACT_WALK_AIM_RIFLE_STIMULATED,
		shotgun = ACT_WALK_AIM_SHOTGUN_STIMULATED,
	},
	[ ACT_WALK_AIM_STEALTH ] = {
		fallback = ACT_WALK_AIM,
		pistol = ACT_WALK_AIM_STEALTH_PISTOL,
	},
	[ ACT_WALK_CROUCH ] = {
		smg = ACT_WALK_CROUCH_RIFLE,
		ar2 = ACT_WALK_CROUCH_RIFLE,
		shotgun = ACT_WALK_CROUCH_RIFLE,
		rpg = ACT_WALK_CROUCH_RPG,
	},
	[ ACT_WALK_CROUCH_AIM ] = {
		fallback = ACT_WALK_CROUCH,
		smg = ACT_WALK_CROUCH_AIM_RIFLE,
		ar2 = ACT_WALK_CROUCH_AIM_RIFLE,
		shotgun = ACT_WALK_CROUCH_AIM_RIFLE,
	},
	[ ACT_RUN ] = {
		smg = ACT_RUN_RIFLE,
		ar2 = ACT_RUN_RIFLE,
		pistol = ACT_RUN_PISTOL,
		shotgun = ACT_RUN_RIFLE,
	},
	[ ACT_RUN_RELAXED ] = {
		fallback = ACT_RUN,
		smg = ACT_RUN_RIFLE_RELAXED,
		ar2 = ACT_RUN_RIFLE_RELAXED,
		rpg = ACT_RUN_RPG_RELAXED,
		shotgun = ACT_RUN_RIFLE_RELAXED,
	},
	[ ACT_RUN_STIMULATED ] = {
		fallback = ACT_RUN,
		smg = ACT_RUN_RIFLE_STIMULATED,
		ar2 = ACT_RUN_RIFLE_STIMULATED,
		rpg = ACT_RUN_RPG_RELAXED,
		shotgun = ACT_RUN_RIFLE_STIMULATED,
	},
	[ ACT_RUN_STEALTH ] = {
		fallback = ACT_RUN,
		pistol = ACT_RUN_STEALTH_PISTOL,
	},
	[ ACT_RUN_AIM ] = {
		smg = ACT_RUN_AIM_RIFLE,
		ar2 = ACT_RUN_AIM_RIFLE,
		pistol = ACT_RUN_AIM_PISTOL,
		shotgun = ACT_RUN_AIM_SHOTGUN,
	},
	[ ACT_RUN_AIM_STIMULATED ] = {
		fallback = ACT_RUN_AIM,
		smg = ACT_RUN_AIM_RIFLE_STIMULATED,
		ar2 = ACT_RUN_AIM_RIFLE_STIMULATED,
		shotgun = ACT_RUN_AIM_RIFLE_STIMULATED,
	},
	[ ACT_RUN_AIM_STEALTH ] = {
		fallback = ACT_RUN_AIM,
		pistol = ACT_RUN_AIM_STEALTH_PISTOL,
	},
	[ ACT_RUN_CROUCH ] = {
		smg = ACT_RUN_CROUCH_RIFLE,
		ar2 = ACT_RUN_CROUCH_RIFLE,
		shotgun = ACT_RUN_CROUCH_RIFLE,
		rpg = ACT_RUN_CROUCH_RPG,
	},
	[ ACT_RUN_CROUCH_AIM ] = {
		fallback = ACT_RUN_CROUCH,
		smg = ACT_RUN_CROUCH_AIM_RIFLE,
		ar2 = ACT_RUN_CROUCH_AIM_RIFLE,
		shotgun = ACT_RUN_CROUCH_AIM_RIFLE,
	},
	[ ACT_GESTURE_RANGE_ATTACK1 ] = {
		smg = ACT_GESTURE_RANGE_ATTACK_SMG1,
		ar2 = {ACT_GESTURE_RANGE_ATTACK_AR2, ACT_GESTURE_RANGE_ATTACK_SMG1},
		pistol = ACT_GESTURE_RANGE_ATTACK_PISTOL,
		shotgun = {ACT_GESTURE_RANGE_ATTACK_SHOTGUN, ACT_GESTURE_RANGE_ATTACK_SMG1},
		grenade = ACT_GESTURE_RANGE_ATTACK_THROW,
	},
	[ ACT_GESTURE_MELEE_ATTACK1 ] = {
		melee = ACT_GESTURE_MELEE_ATTACK_SWING,
	},
	[ ACT_GESTURE_RELOAD ] = {
		smg = ACT_GESTURE_RELOAD_SMG1,
		ar2 = ACT_GESTURE_RELOAD_SMG1,
		pistol = ACT_GESTURE_RELOAD_PISTOL,
		shotgun = ACT_GESTURE_RELOAD_SHOTGUN,
	},

	[ ACT_HL2MP_IDLE ] = {
		smg = ACT_HL2MP_IDLE_SMG1,
		ar2 = ACT_HL2MP_IDLE_AR2,
		pistol = ACT_HL2MP_IDLE_PISTOL,
		shotgun = ACT_HL2MP_IDLE_SHOTGUN,
		passive = ACT_HL2MP_IDLE_PASSIVE,
		melee = ACT_HL2MP_IDLE_MELEE,
		grenade = ACT_HL2MP_IDLE_GRENADE,
		rpg = ACT_HL2MP_IDLE_RPG,
		revolver = ACT_HL2MP_IDLE_REVOLVER,
		normal = ACT_HL2MP_IDLE,
	},
	[ ACT_HL2MP_IDLE_CROUCH ] = {
		smg = ACT_HL2MP_IDLE_CROUCH_SMG1,
		ar2 = ACT_HL2MP_IDLE_CROUCH_AR2,
		pistol = ACT_HL2MP_IDLE_CROUCH_PISTOL,
		shotgun = ACT_HL2MP_IDLE_CROUCH_SHOTGUN,
		passive = ACT_HL2MP_IDLE_CROUCH_PASSIVE,
		melee = ACT_HL2MP_IDLE_CROUCH_MELEE,
		grenade = ACT_HL2MP_IDLE_CROUCH_GRENADE,
		rpg = ACT_HL2MP_IDLE_CROUCH_RPG,
		revolver = ACT_HL2MP_IDLE_CROUCH_REVOLVER,
		normal = ACT_HL2MP_IDLE_CROUCH,
	},
	[ ACT_HL2MP_WALK ] = {
		smg = ACT_HL2MP_WALK_SMG1,
		ar2 = ACT_HL2MP_WALK_AR2,
		pistol = ACT_HL2MP_WALK_PISTOL,
		shotgun = ACT_HL2MP_WALK_SHOTGUN,
		passive = ACT_HL2MP_WALK_PASSIVE,
		melee = ACT_HL2MP_WALK_MELEE,
		grenade = ACT_HL2MP_WALK_GRENADE,
		rpg = ACT_HL2MP_WALK_RPG,
		revolver = ACT_HL2MP_WALK_REVOLVER,
		normal = ACT_HL2MP_WALK,
	},
	[ ACT_HL2MP_WALK_CROUCH ] = {
		smg = ACT_HL2MP_WALK_CROUCH_SMG1,
		ar2 = ACT_HL2MP_WALK_CROUCH_AR2,
		pistol = ACT_HL2MP_WALK_CROUCH_PISTOL,
		shotgun = ACT_HL2MP_WALK_CROUCH_SHOTGUN,
		passive = ACT_HL2MP_WALK_CROUCH_PASSIVE,
		melee = ACT_HL2MP_WALK_CROUCH_MELEE,
		grenade = ACT_HL2MP_WALK_CROUCH_GRENADE,
		rpg = ACT_HL2MP_WALK_CROUCH_RPG,
		revolver = ACT_HL2MP_WALK_CROUCH_REVOLVER,
		normal = ACT_HL2MP_WALK_CROUCH,
	},
	[ ACT_HL2MP_RUN ] = {
		smg = ACT_HL2MP_RUN_SMG1,
		ar2 = ACT_HL2MP_RUN_AR2,
		pistol = ACT_HL2MP_RUN_PISTOL,
		shotgun = ACT_HL2MP_RUN_SHOTGUN,
		passive = ACT_HL2MP_RUN_PASSIVE,
		melee = ACT_HL2MP_RUN_MELEE,
		grenade = ACT_HL2MP_RUN_GRENADE,
		rpg = ACT_HL2MP_RUN_RPG,
		revolver = ACT_HL2MP_RUN_REVOLVER,
		normal = ACT_HL2MP_RUN,
	},
	[ ACT_HL2MP_GESTURE_RANGE_ATTACK ] = {
		smg = ACT_HL2MP_GESTURE_RANGE_ATTACK_SMG1,
		ar2 = ACT_HL2MP_GESTURE_RANGE_ATTACK_AR2,
		pistol = ACT_HL2MP_GESTURE_RANGE_ATTACK_PISTOL,
		shotgun = ACT_HL2MP_GESTURE_RANGE_ATTACK_SHOTGUN,
		passive = ACT_HL2MP_GESTURE_RANGE_ATTACK_PASSIVE,
		melee = ACT_HL2MP_GESTURE_RANGE_ATTACK_MELEE,
		grenade = ACT_HL2MP_GESTURE_RANGE_ATTACK_GRENADE,
		rpg = ACT_HL2MP_GESTURE_RANGE_ATTACK_RPG,
		revolver = ACT_HL2MP_GESTURE_RANGE_ATTACK_REVOLVER,
		normal = ACT_HL2MP_GESTURE_RANGE_ATTACK_GRENADE,
	},
	[ ACT_HL2MP_GESTURE_RELOAD ] = {
		smg = ACT_HL2MP_GESTURE_RELOAD_SMG1,
		ar2 = ACT_HL2MP_GESTURE_RELOAD_AR2,
		pistol = ACT_HL2MP_GESTURE_RELOAD_PISTOL,
		shotgun = ACT_HL2MP_GESTURE_RELOAD_SHOTGUN,
		passive = ACT_HL2MP_GESTURE_RELOAD_PASSIVE,
		melee = ACT_HL2MP_GESTURE_RELOAD_MELEE,
		grenade = ACT_HL2MP_GESTURE_RELOAD_GRENADE,
		rpg = ACT_HL2MP_GESTURE_RELOAD_RPG,
		revolver = ACT_HL2MP_GESTURE_RELOAD_REVOLVER,
		normal = ACT_HL2MP_GESTURE_RELOAD_MELEE,
	},
	[ ACT_HL2MP_SIT ] = {
		smg = ACT_HL2MP_SIT_SMG1,
		ar2 = ACT_HL2MP_SIT_AR2,
		pistol = ACT_HL2MP_SIT_PISTOL,
		shotgun = ACT_HL2MP_SIT_SHOTGUN,
		passive = a.ACT_HL2MP_SIT_PASSIVE,
		melee = ACT_HL2MP_SIT_MELEE,
		grenade = ACT_HL2MP_SIT_GRENADE,
		rpg = ACT_HL2MP_SIT_RPG,
		revolver = ACT_HL2MP_SIT_PISTOL,
		normal = ACT_HL2MP_SIT,
	},
	[ ACT_HL2MP_SWIM ] = {
		smg = ACT_HL2MP_SWIM_SMG1,
		ar2 = ACT_HL2MP_SWIM_AR2,
		pistol = ACT_HL2MP_SWIM_PISTOL,
		shotgun = ACT_HL2MP_SWIM_SHOTGUN,
		passive = ACT_HL2MP_SWIM_PASSIVE,
		melee = ACT_HL2MP_SWIM_MELEE,
		grenade = ACT_HL2MP_SWIM_GRENADE,
		rpg = ACT_HL2MP_SWIM_RPG,
		revolver = ACT_HL2MP_SWIM_PISTOL,
		normal = ACT_HL2MP_SWIM,
	},
	[ ACT_HL2MP_SWIM_IDLE ] = {
		smg = ACT_HL2MP_SWIM_IDLE_SMG1,
		ar2 = ACT_HL2MP_SWIM_IDLE_AR2,
		pistol = ACT_HL2MP_SWIM_IDLE_PISTOL,
		shotgun = ACT_HL2MP_SWIM_IDLE_SHOTGUN,
		passive = ACT_HL2MP_SWIM_IDLE_PASSIVE,
		melee = ACT_HL2MP_SWIM_IDLE_MELEE,
		grenade = ACT_HL2MP_SWIM_IDLE_GRENADE,
		rpg = ACT_HL2MP_SWIM_IDLE_RPG,
		revolver = ACT_HL2MP_SWIM_IDLE_PISTOL,
		normal = ACT_HL2MP_SWIM_IDLE,
	},
	[ ACT_HL2MP_JUMP ] = {
		smg = ACT_HL2MP_JUMP_SMG1,
		ar2 = ACT_HL2MP_JUMP_AR2,
		pistol = ACT_HL2MP_JUMP_PISTOL,
		shotgun = ACT_HL2MP_JUMP_SHOTGUN,
		passive = ACT_HL2MP_JUMP_PASSIVE,
		melee = ACT_HL2MP_JUMP_MELEE,
		grenade = ACT_HL2MP_JUMP_GRENADE,
		rpg = ACT_HL2MP_JUMP_RPG,
		revolver = ACT_HL2MP_JUMP_PISTOL,
		normal = ACT_HL2MP_JUMP,
	},
}

function ENT:TranslateActivity(act_src)
    local h = self:GetWeaponParameters().HoldType
	local t = ActivityTranslation
	local act = act_src
	if not t[act] then return act end
	local translated = t[act][h]
	while self:SelectWeightedSequence(translated) < 0 do
		if not translated then return act end
		if istable(translated) then
			for _, a in ipairs(translated) do
				if self:SelectWeightedSequence(a) >= 0 then
					translated = a
					break
				end
			end

			if istable(translated) then translated = ACT_INVALID end
		end

		act = t[act].fallback
		if not act then return act_src end
	end

	return translated
end
