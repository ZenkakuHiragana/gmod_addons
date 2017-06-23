
ENT.classname = "nextbot_tracer"

ENT.Base = "base_nextbot"
ENT.Type = "nextbot"

ENT.PrintName = "Nextbot Tracer"
ENT.Author = "GreatZenkakuMan"
ENT.Contact = ""
ENT.Purpose = ""
ENT.Spawnable = false
ENT.AutomaticFrameAdvance = true
ENT.Model = "models/player/ow_tracer.mdl"
ENT.MaxYawRate = 250 --default: 250
ENT.StepHeight = 30 --default: 20
ENT.SearchAngle = 60 --FOV in degrees.
ENT.MaxNavAreas = 720 --Maximum amount of searching NavAreas.
ENT.Bravery = 6 --Parameter of Schedule.GetDanger()
ENT.RecallInterval = 0.1 --Store my info every this seconds.
ENT.RecallInfoSize = 3 / ENT.RecallInterval

ENT.Act = {}
ENT.Act.Idle = ACT_HL2MP_IDLE_DUEL
ENT.Act.IdleCrouch = ACT_HL2MP_IDLE_CROUCH_DUEL
ENT.Act.Run = ACT_HL2MP_RUN_DUEL
ENT.Act.Walk = ACT_HL2MP_WALK_DUEL
ENT.Act.WalkCrouch = ACT_HL2MP_WALK_CROUCH_DUEL
ENT.Act.Jump = ACT_HL2MP_JUMP_DUEL
ENT.Act.SwimIdle = ACT_HL2MP_SWIM_IDLE_DUEL
ENT.Act.Swim = ACT_HL2MP_SWIM_DUEL
ENT.Act.Attack = ACT_HL2MP_GESTURE_RANGE_ATTACK_DUEL
ENT.Act.Melee = ACT_HL2MP_GESTURE_RANGE_ATTACK_MELEE
ENT.Act.Reload = ACT_HL2MP_GESTURE_RELOAD_DUEL

ENT.Dist = {}
--blink distance in hammer unit, meters -> inches -> hammer units
ENT.Dist.Blink = 7 * 3.280839895 * 16 --367.45406824
ENT.Dist.BlinkSqr = ENT.Dist.Blink^2
ENT.Dist.FindSpots = 1000 --Search radius for finding where the nextbot should move to.
ENT.Dist.Grenade = 200 --Distance for detecting grenades.
ENT.Dist.GrenadeSqr = ENT.Dist.Grenade^2
ENT.Dist.Search = 1000 --Search radius for finding enemies.
ENT.Dist.ShootRange = 500
ENT.Dist.Manhack = ENT.Dist.Grenade / 2 --For Manhacks.
ENT.Dist.ManhackSqr = ENT.Dist.Manhack^2
ENT.Dist.Melee = 100
ENT.Dist.MeleeSqr = ENT.Dist.Melee^2
ENT.Dist.Mobbed = 90 --For Condition "Mobbed by Enemies"
ENT.Dist.MobbedSqr = ENT.Dist.Mobbed^2

ENT.HP = {}
ENT.HP.Init = 150
ENT.HP.MoreBlink = 75 --If my health is lower than that, do more blink.
ENT.HP.HeavyDamage = 15 --If I've taken damage more than that at once, flag as HeavyDamage.
ENT.HP.Recall = 80 / ENT.HP.Init --Damage fraction to be able to use recall.

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

--Returns a table about the hand.
--Argument:
----bool isleft | True if it is left hand.
function ENT:GetHand(isleft)
	local att = isleft and "anim_attachment_LH" or "anim_attachment_RH"
	return self:GetAttachment(self:LookupAttachment(att))
end

--For Half Life Renaissance Reconstructed
function ENT:GetNoTarget()
	return false
end

--For Half Life Renaissance Reconstructed
function ENT:PercentageFrozen()
	return 0
end

--Determines whether given entity is targetable or not.
function ENT:Validate(e)
	if not IsValid(e) or e == self then return -1 end
	
	local c = e:GetClass()
	if not isstring(c) then return -1
	elseif c == "npc_rollermine" or c == "npc_turret_floor" then
		return 0
	elseif c ~= self.classname or IsAlone then
		if e:Health() > 0 then
			if not c:find("bullseye") and c ~= "env_flare" and
			c ~= "npc_combinegunship" and c ~= "npc_helicopter" and c ~= "npc_strider" then
				if e:IsNPC() or e.Type == "nextbot" or
				(e:IsPlayer() and not (self:GetConVarBool("ai_ignoreplayers") or e:IsFlagSet(FL_NOTARGET))) then
					return 0
				end
			end
		end
	else
		return 1
	end
	
	return -1
end

--Returns if I can hear the given sound.
function ENT:IsHearingSound(t)
	return math.log10(t.Entity:GetPos():DistToSqr(self:GetEye().Pos)) < t.SoundLevel * 0.085
end

--Data Tables for eye blink.
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

if IsMounted("ep2") then
    game.AddParticles( "particles/hunter_projectile.pcf" )
	PrecacheParticleSystem( "hunter_muzzle_flash" )	
end

list.Set("NPC", ENT.classname, {
	Name = "Nextbot Tracer",
	Class = ENT.classname,
	Category = "GreatZenkakuMan's NPCs"
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
