
AddCSLuaFile()
local ss = SplatoonSWEPs
if not ss then return end

local ActIndex = {
	[ "pistol" ]		= ACT_HL2MP_IDLE_PISTOL,
	[ "smg" ]			= ACT_HL2MP_IDLE_SMG1,
	[ "grenade" ]		= ACT_HL2MP_IDLE_GRENADE,
	[ "ar2" ]			= ACT_HL2MP_IDLE_AR2,
	[ "shotgun" ]		= ACT_HL2MP_IDLE_SHOTGUN,
	[ "rpg" ]			= ACT_HL2MP_IDLE_RPG,
	[ "physgun" ]		= ACT_HL2MP_IDLE_PHYSGUN,
	[ "crossbow" ]		= ACT_HL2MP_IDLE_CROSSBOW,
	[ "melee" ]			= ACT_HL2MP_IDLE_MELEE,
	[ "slam" ]			= ACT_HL2MP_IDLE_SLAM,
	[ "normal" ]		= ACT_HL2MP_IDLE,
	[ "fist" ]			= ACT_HL2MP_IDLE_FIST,
	[ "melee2" ]		= ACT_HL2MP_IDLE_MELEE2,
	[ "passive" ]		= ACT_HL2MP_IDLE_PASSIVE,
	[ "knife" ]			= ACT_HL2MP_IDLE_KNIFE,
	[ "duel" ]			= ACT_HL2MP_IDLE_DUEL,
	[ "camera" ]		= ACT_HL2MP_IDLE_CAMERA,
	[ "magic" ]			= ACT_HL2MP_IDLE_MAGIC,
	[ "revolver" ]		= ACT_HL2MP_IDLE_REVOLVER,
}

function SWEP:SetWeaponHoldType(t)
	if not isstring(t) then return end
	t = t:lower()
	local index = assert(ActIndex[t], "SplatoonSWEPs: SWEP:SetWeaponHoldType - ActIndex[] is not set!")

	self.ActivityTranslate = {}
	self.ActivityTranslate[ ACT_MP_STAND_IDLE ]					= index
	self.ActivityTranslate[ ACT_MP_WALK ]						= index + 1
	self.ActivityTranslate[ ACT_MP_RUN ]						= index + 2
	self.ActivityTranslate[ ACT_MP_CROUCH_IDLE ]				= index + 3
	self.ActivityTranslate[ ACT_MP_CROUCHWALK ]					= index + 4
	self.ActivityTranslate[ ACT_MP_ATTACK_STAND_PRIMARYFIRE ]	= index + 5
	self.ActivityTranslate[ ACT_MP_ATTACK_CROUCH_PRIMARYFIRE ]	= index + 5
	self.ActivityTranslate[ ACT_MP_RELOAD_STAND ]				= index + 6
	self.ActivityTranslate[ ACT_MP_RELOAD_CROUCH ]				= index + 6
	self.ActivityTranslate[ ACT_MP_JUMP ]						= index + 7
	self.ActivityTranslate[ ACT_RANGE_ATTACK1 ]					= index + 8
	self.ActivityTranslate[ ACT_MP_SWIM ]						= index + 9

	if t == "normal" then -- "normal" jump animation doesn't exist
		self.ActivityTranslate[ACT_MP_JUMP] = ACT_HL2MP_JUMP_SLAM
	end

	self:SetupWeaponHoldTypeForAI(t)
end

local NPCHoldType = {
	weapon_splatoonsweps_blaster_base = "smg",
	weapon_splatoonsweps_charger = "smg",
	weapon_splatoonsweps_shooter = "smg",
	weapon_splatoonsweps_slosher_base = "smg",
	weapon_splatoonsweps_splatling = "smg",
	weapon_splatoonsweps_roller = "melee",
}
function SWEP:TranslateActivity(act)
	if self.Owner:IsNPC() then
		local h = NPCHoldType[self.Base]
		local a = self.ActivityTranslateAI
		local invalid = self.Owner:SelectWeightedSequence(a[h][act] or 0) < 0
		return not invalid and a[h][act] or a.smg[act] or -1
	end

	local holdtype = ss.ProtectedCall(self.CustomActivity, self) or "passive"
	if self:Crouching() then holdtype = "melee2" end
	if self:GetThrowing() then holdtype = "grenade" end
	self.HoldType = holdtype

	local translate = self.Translate[holdtype]
	return translate and translate[act] or -1
end

-- event = 5xyy, x = option index, yy = effect type
-- yy = 0 : SplatoonSWEPsMuzzleSplash
--     x = 0 : Attach to muzzle
--     x = 1 : Go backward (for charger)
-- yy = 1 : SplatoonSWEPsMuzzleRing
-- yy = 2 : SplatoonSWEPsMuzzleMist
-- yy = 3 : SplatoonSWEPsMuzzleFlash
-- yy = 4 : SplatoonSWEPsRollerSplash
-- yy = 5 : SplatoonSWEPsBrushSwing1
-- yy = 6 : SplatoonSWEPsBrushSwing2
-- yy = 7 : SplatoonSWEPsSlosherSplash
function SWEP:FireAnimationEvent(pos, ang, event, options)
	if 5000 <= event and event < 6000 then
		event = event - 5000
		local vararg = string.Explode(" ", options)
		ss.tablepush(vararg, math.floor(event / 100))
		ss.ProtectedCall(ss.DispatchEffect[event % 100], self, vararg, pos, ang)
	end

	return true
end
