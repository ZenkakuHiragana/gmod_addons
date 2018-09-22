
ENT.classname = "nextbot_tracer"

ENT.Base = "base_nextbot"
ENT.Type = "nextbot"

ENT.PrintName = "Nextbot Tracer"
ENT.Author = "GreatZenkakuMan"
ENT.Contact = ""
ENT.Purpose = ""
ENT.Spawnable = false
ENT.AutomaticFrameAdvance = true

ENT.NextBotIsFakeNPC = true
ENT.Replacement = {} --Since we make ENT:IsNPC() returns true, we must define NPC Functions.
ENT.Capabilities = {
	["Total"] = 0,
	CAP_MOVE_GROUND,
	CAP_MOVE_JUMP,
	CAP_MOVE_SHOOT,
	CAP_USE,
	CAP_WEAPON_RANGE_ATTACK1,
	CAP_WEAPON_MELEE_ATTACK1,
	CAP_USE_WEAPONS,
	CAP_ANIMATEDFACE,
	CAP_FRIENDLY_DMG_IMMUNE,
	CAP_SQUAD,
	CAP_DUCK,
	CAP_AIM_GUN,
	CAP_NO_HIT_SQUADMATES,
}
for k, v in ipairs(ENT.Capabilities) do
	ENT.Capabilities.Total = bit.bor(ENT.Capabilities.Total, v)
end

ENT.Bravery = 7 --Parameter of Schedule.GetDanger()
ENT.MaxNavAreas = 720 --Maximum amount of searching NavAreas.
ENT.MaxYawRate = 250 --default: 250
ENT.Model = "models/player/ow_tracer.mdl"
ENT.RecallInterval = 0.1 --Store my info every this seconds.
ENT.RecallInfoSize = 3 / ENT.RecallInterval
ENT.SearchAngle = 60 --FOV in degrees.
ENT.StepHeight = 30 --default: 20

ENT.Act = {}
ENT.Act.Attack = ACT_HL2MP_GESTURE_RANGE_ATTACK_DUEL
ENT.Act.Flinch = ENT.Act.Flinch or {}
	--ENT.Act.Flinch.Back = ACT_FLINCH_BACK
	--ENT.Act.Flinch.Default = ACT_FLINCH
	ENT.Act.Flinch.Head = ACT_FLINCH_HEAD
	ENT.Act.Flinch.Physics = ACT_FLINCH_PHYSICS
	--ENT.Act.Flinch.ShoulderLeft = ACT_FLINCH_SHOULDER_LEFT
	--ENT.Act.Flinch.ShoulderRight = ACT_FLINCH_SHOULDER_RIGHT
	ENT.Act.Flinch.Stomach = ACT_FLINCH_STOMACH
ENT.Act.Idle = ACT_HL2MP_IDLE_DUEL
ENT.Act.IdleCrouch = ACT_HL2MP_IDLE_CROUCH_DUEL
ENT.Act.Jump = ACT_HL2MP_JUMP_DUEL
ENT.Act.Melee = ACT_HL2MP_GESTURE_RANGE_ATTACK_MELEE
ENT.Act.Reload = ACT_HL2MP_GESTURE_RELOAD_DUEL
ENT.Act.Run = ACT_HL2MP_RUN_DUEL
ENT.Act.Swim = ACT_HL2MP_SWIM_DUEL
ENT.Act.SwimIdle = ACT_HL2MP_SWIM_IDLE_DUEL
ENT.Act.Walk = ACT_HL2MP_WALK_DUEL
ENT.Act.WalkCrouch = ACT_HL2MP_WALK_CROUCH_DUEL

ENT.Bone = {}
ENT.Bone.Head = "ValveBiped.Bip01_Head1"
ENT.Bone.ShoulderLeft = "ValveBiped.Bip01_L_UpperArm"
ENT.Bone.ShoulderRight = "ValveBiped.Bip01_R_UpperArm"
ENT.Bone.Stomach = "ValveBiped.Bip01_Spine2"

ENT.Dist = {}
--blink distance in hammer unit, meters -> inches -> hammer units
ENT.Dist.Blink = 367.45406824 --7 * 3.280839895 * 16
ENT.Dist.BlinkSqr = ENT.Dist.Blink^2
ENT.Dist.FindSpots = 3000 --Search radius for finding where the nextbot should move to.
ENT.Dist.FollowPlayer = 100 --Following player.
ENT.Dist.FollowPlayerSqr = ENT.Dist.FollowPlayer^2
ENT.Dist.Grenade = 200 --Distance for detecting grenades.
ENT.Dist.GrenadeSqr = ENT.Dist.Grenade^2
ENT.Dist.Manhack = ENT.Dist.Grenade / 2 --For Manhacks.
ENT.Dist.ManhackSqr = ENT.Dist.Manhack^2
ENT.Dist.Melee = 50
ENT.Dist.MeleeSqr = ENT.Dist.Melee^2
ENT.Dist.Mobbed = 90 --For condition "Mobbed by Enemies"
ENT.Dist.MobbedSqr = ENT.Dist.Mobbed^2
ENT.Dist.Search = 2000 --Search radius for finding enemies.
ENT.Dist.SearchSqr = ENT.Dist.Search^2
ENT.Dist.ShootRange = 500

ENT.HP = {}
ENT.HP.HeavyDamage = 15 --If I've taken damage more than that at once, flag as HeavyDamage.
ENT.HP.Init = 150
ENT.HP.MoreBlink = 75 --If my health is lower than that, do more blink.
ENT.HP.Recall = .53 --Damage fraction to be able to use recall.

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

--Returns the attachment of my left hand.
function ENT:GetLeftHand()
	return self:GetAttachment(self:LookupAttachment("anim_attachment_LH"))
end

--Returns the attachment of my right hand.
function ENT:GetRightHand()
	return self:GetAttachment(self:LookupAttachment("anim_attachment_RH"))
end

--Returns if I can hear the given sound.
function ENT:IsHearingSound(t)
	return math.log10(t.Entity:GetPos():DistToSqr(self:GetEye().Pos)) < t.SoundLevel * 0.085
end

--Data Tables.
function ENT:SetupDataTables()
	self:NetworkVar("Vector", 0, "LookatAim")
	self:NetworkVar("Bool", 0, "LookatEnemy")
	self:NetworkVar("Bool", 1, "InvisibleFlag")
	
	if SERVER then
		self:SetLookatAim(vector_origin)
		self:SetLookatEnemy(false)
		self:SetInvisibleFlag(false)
	end
end

CreateConVar("nextbot_tracer_hates_nextbots", 1, FCVAR_ARCHIVE,
	"Relationship between Tracer and other nextbots.  0: Neutural  1: Hate")
game.AddParticles("particles/tracer_muzzleflash.pcf")
PrecacheParticleSystem("hunter_muzzle_flash")
PrecacheParticleSystem("hunter_muzzle_flash_red")

list.Set("NPC", ENT.classname, {
	Name = ENT.PrintName,
	Class = ENT.classname,
	Category = "Overwatch"
})

--++Debugging functions++---------------------{

ENT.Debug = {} --Debug information flags.
ENT.Debug.BehindEnemy = false
ENT.Debug.BlinkDestination = false
ENT.Debug.BlinkTraces = false
ENT.Debug.DrawMoveSuggestions = false
ENT.Debug.DrawPath = false
ENT.Debug.Fleeing = false
ENT.Debug.LookatHead = false
ENT.Debug.SeeTrace = false
ENT.Debug.ShowEnemyMemory = false
ENT.Debug.ShowNextSchedule = false
ENT.Debug.ShowPreviousSchedule = false
ENT.Debug.StuckReposition = false
ENT.Debug.WritePathName = false

function ENT:ShowActAll()
	print("List of all available activities:")
	for i = 0, self:GetSequenceCount() - 1 do
		print(string.format("%d\t=\t%-40s%-40s", i, self:GetSequenceName(i), self:GetSequenceActivityName(i)))
	end
end

function ENT:ShowFlexAll()
	print("List of all available flexes:")
	for i = 0, self:GetFlexNum() - 1 do
		local min, max = self:GetFlexBounds(i)
		print(i .. " = " .. self:GetFlexName(i) .. " " .. min .. " / " .. max)
	end
end

function ENT:ShowPoseParameters()
	for i = 0, self:GetNumPoseParameters() - 1 do
		local min, max = self:GetPoseParameterRange(i)
		print(self:GetPoseParameterName(i) .. " " .. min .. " / " .. max)
	end
end
----------------------------------------------}
