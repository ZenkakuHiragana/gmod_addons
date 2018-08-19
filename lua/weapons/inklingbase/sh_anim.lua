
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

	-- "normal" jump animation doesn't exist
	if t == "normal" then
		self.ActivityTranslate[ACT_MP_JUMP] = ACT_HL2MP_JUMP_SLAM
	end

	self:SetupWeaponHoldTypeForAI(t)
end

function SWEP:TranslateActivity(act)
	if self.Owner:IsNPC() then
		return self.ActivityTranslateAI[act] or -1
	end
	
	local holdtype = ss.ProtectedCall(self.CustomActivity, self) or "passive"
	if self:Crouching() then holdtype = "melee2" end
	if self:GetThrowing() then holdtype = "grenade" end
	self.HoldType = holdtype
	
	local translate = self.Translate[holdtype]
	if not translate then return -1 end
	if translate[act] then
		return translate[act]
	end

	return -1
end

-- event = 5xyy, x = option index, yy = effect type
-- yy = 0 : SplatoonSWEPsMuzzleSplash
--     x = 0 : Attach to muzzle
--     x = 1 : Go backward (for charger's reverse splash)
-- yy = 1 : SplatoonSWEPsMuzzleRing
-- yy = 2 : SplatoonSWEPsMuzzleMist
function SWEP:FireAnimationEvent(pos, ang, event, options)
	if 5000 <= event and event < 6000 then
		event = event - 5000
		local vararg = string.Explode(" ", options)
		table.insert(vararg, 1, math.floor(event / 100))
		ss.ProtectedCall(ss.DispatchEffect[event % 100], self, vararg, pos, ang)
	end
	
	return true
end

function ss.UpdateAnimation(w, ply, velocity, maxseqspeed)
	ss.ProtectedCall(w.UpdateAnimation, w, ply, velocity, maxseqspeed)
	
	if not w:GetThrowing() then return end
	
	ply:AnimSetGestureWeight(GESTURE_SLOT_ATTACK_AND_RELOAD, 1)
	
	local f = (CurTime() - w:GetThrowAnimTime()) / ss.SubWeaponThrowTime
	if CLIENT and w:IsCarriedByLocalPlayer() then
		f = f + LocalPlayer():Ping() / 1000 / ss.SubWeaponThrowTime
	end
	
	if 0 <= f and f <= 1 then
		ply:AddVCDSequenceToGestureSlot(GESTURE_SLOT_ATTACK_AND_RELOAD,
		ply:SelectWeightedSequence(ACT_HL2MP_GESTURE_RANGE_ATTACK_GRENADE),
		Lerp(f, 0, .55), true)
	end
end

hook.Add("UpdateAnimation", "SplatoonSWEPs: Adjust TPS animation speed", ss.hook "UpdateAnimation")
