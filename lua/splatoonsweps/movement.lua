
--Player movement emulation for the ability of passing through fences.
--Source codes are taken from source-sdk-2013/mp/src/game/shared/gamemovement.cpp
local ss = SplatoonSWEPs
if not ss then return end
util.PrecacheSound "Player.Swim"
local m_nOldWaterLevel, m_flWaterEntryTime, m_nOnLadder
local m_vecForward, m_vecRight, m_vecUp
local m_flForwardMove, m_flSideMove, m_flUpMove
local m_nOldButtons, m_nButtons, m_flMaxSpeed, m_flClientMaxSpeed
local mvangles, mvoldangles, plyflags, plyviewangles
local plyemitsound, splashdata, setanimation
local ply, mv, mt, morg, mvel, bvel, plyground
local COORD_FRACTIONAL_BITS = 5
local COORD_DENOMINATOR = bit.lshift(1, COORD_FRACTIONAL_BITS)
local COORD_RESOLUTION = 1.0 / COORD_DENOMINATOR
local DIST_EPSILON = .03125
local FX_WATER_IN_SLIME = 0x01
local GAMEMOVEMENT_JUMP_HEIGHT = 21.0 -- units
local GAMEMOVEMENT_JUMP_TIME = 510.0 -- ms approx. - based on the 21 unit height jump
local LIMIT_Z_DEG = math.cos(math.rad(180 - 30))
local MAX_CLIP_PLANES = 5
local PLAYER_FALL_PUNCH_THRESHOLD = 303.0 or 350 -- HL2 or Other
local PLAYER_LAND_ON_FLOATING_OBJECT = 173 or 200 -- HL2 or Other
local PLAYER_MAX_SAFE_FALL_SPEED = 526.5 or 580 -- HL2 or Other
local PLAYER_MIN_BOUNCE_SPEED = 173 or 200 -- HL2 or Other
local PUNCH_DAMPING = 9.0
local PUNCH_SPRING_CONSTANT = 65.0
local RUMBLE_FALL_LONG = 18
local RUMBLE_FALL_SHORT = 19
local RUMBLE_FLAGS_NONE = 0
local WATERJUMP_HEIGHT = 8
local WL_NotInWater = 0
local WL_Feet = 1
local WL_Waist = 2
local WL_Eyes = 3
local WALLCLIMB_KEYS = bit.bor(IN_JUMP, IN_FORWARD, IN_BACK)
local function IsDead() return ply:Health() <= 0 and not ply:Alive() end
local function GetAirSpeedCap() return 30.0 end
local function GetCurrentGravity() return GetConVar "sv_gravity":GetFloat() end
local function GetPlayerMins(ducked)
	local mins, maxs
	if ducked or ply:Crouching() then
		mins, maxs = ply:GetHullDuck()
	else
		mins, maxs = ply:GetHull()
	end
	
	return mins
end
local function GetPlayerMaxs(ducked)
	local mins, maxs
	if ducked or ply:Crouching() then
		mins, maxs = ply:GetHullDuck()
	else
		mins, maxs = ply:GetHull()
	end
	
	return maxs
end

local function PlayerSplash()
	splashdata = EffectData()
	splashdata:SetFlags(0)
	splashdata:SetOrigin(morg)
	splashdata:SetNormal(vector_up)
	splashdata:SetAngles(angle_zero)
	
	if bit.band(ss.m_nWaterType[ply], CONTENTS_SLIME) ~= 0 then
		splashdata:SetFlags(FX_WATER_IN_SLIME)
	end

	local flSpeed = ply:GetAbsVelocity():Length()
	if flSpeed < 300 then
		splashdata:SetScale(math.Rand(10, 12))
	else
		splashdata:SetScale(math.Rand(6, 8))
	end
end

local function PlaySwimSound()
	-- MoveHelper():StartSound(morg, "Player.Swim")
	plyemitsound = "Player.Swim"
end

local function PlayerSolidMask(brushOnly)
	-- return brushOnly and MASK_PLAYERSOLID_BRUSHONLY or MASK_PLAYERSOLID
	return brushOnly and MASK_SHOT_PORTAL or MASK_SHOT
end

local function RumbleEffect(index, rumbleData, rumbleFlags)
	if IsDead() then return end
	-- net.Start "Rumble"
	-- net.WriteUInt(index, 8)
	-- net.WriteUInt(rumbleData, 8)
	-- net.WriteUInt(rumbleFlags, 8)
	-- net.Send(ply)
end

local function DecayPunchAngle()
	local vecPunchAngles = plyviewangles
	vecPunchAngles = Vector(vecPunchAngles.p, vecPunchAngles.y, vecPunchAngles.r)
	if vecPunchAngles:LengthSqr() > 0.001 or ss.m_vecPunchAngleVel[ply]:LengthSqr() > 0.001 then
		vecPunchAngles = vecPunchAngles + ss.m_vecPunchAngleVel[ply] * FrameTime()
		local damping = math.max(0, 1 - PUNCH_DAMPING * FrameTime())
		ss.m_vecPunchAngleVel[ply] = ss.m_vecPunchAngleVel[ply] * damping
		
		-- torsional spring
		-- UNDONE: Per-axis spring constant?
		local springForceMagnitude = PUNCH_SPRING_CONSTANT * FrameTime()
		springForceMagnitude = math.Clamp(springForceMagnitude, 0, 2)
		ss.m_vecPunchAngleVel[ply] = ss.m_vecPunchAngleVel[ply] - vecPunchAngles * springForceMagnitude

		-- don't wrap around
		vecPunchAngles:Set(Vector( 
			math.Clamp(vecPunchAngles.x, -89, 89), 
			math.Clamp(vecPunchAngles.y, -179, 179),
			math.Clamp(vecPunchAngles.z, -89, 89)))
		plyviewangles = Angle(vecPunchAngles.x, vecPunchAngles.y, vecPunchAngles.z)
	else
		plyviewangles = Angle()
		ss.m_vecPunchAngleVel[ply]:Zero()
	end
end

local function CalcRoll(angles, velocity, rollangle, rollspeed)
	local side = velocity:Dot(angles:Right())
	local sign = side < 0 and -1 or 1
	local value = rollangle
	
	side = math.abs(side)
	if side < rollspeed then
		side = side * value / rollspeed
	else
		side = value
	end
	
	return side * sign
end

local function ComputeConstraintSpeedFactor()
	-- If we have a constraint, slow down because of that too.
	if not (mv and mv.m_flConstraintRadius) or mv.m_flConstraintRadius == 0 then return 1 end
	
	local flDistSq = morg:DistToSqr(mv.m_vecConstraintCenter)

	local flOuterRadiusSq = mv.m_flConstraintRadius * mv.m_flConstraintRadius
	local flInnerRadiusSq = mv.m_flConstraintRadius - mv.m_flConstraintWidth
	flInnerRadiusSq = flInnerRadiusSq * flInnerRadiusSq

	-- Only slow us down if we're inside the constraint ring
	if flDistSq <= flInnerRadiusSq or flDistSq >= flOuterRadiusSq then return 1 end

	-- Only slow us down if we're running away from the center
	local vecDesired = m_vecForward * m_flForwardMove
	+ m_vecRight * m_flSideMove + m_vecUp * m_flUpMove

	local vecDelta = morg - mv.m_vecConstraintCenter
	vecDelta:Normalize()
	vecDesired:Normalize()
	if vecDelta:Dot(vecDesired) < 0 then return 1 end

	local flFrac = (math.sqrt(flDistSq) - (mv.m_flConstraintRadius - mv.m_flConstraintWidth)) / mv.m_flConstraintWidth

	return Lerp(flFrac, 1, mv.m_flConstraintSpeedFactor) --flSpeedFactor
end

local function TracePlayerBBox(start, endpos, fMask, collisionGroup)
	return util.TraceHull {
		start = start, endpos = endpos,
		mins = GetPlayerMins(), maxs = GetPlayerMaxs(),
		mask = fMask, collisiongroup = collisionGroup,
		filter = ply,
	}
end

local function TryTouchGround(start, endpos, mins, maxs, fMask, collisionGroup)
	return util.TraceHull {
		start = start, endpos = endpos,
		mins = mins, maxs = maxs,
		mask = fMask, collisiongroup = collisionGroup,
		filter = ply,
	}
end

-------------------------------------------------------------------------------
-- Traces the player's collision bounds in quadrants, looking for a plane that
-- can be stood upon (normal's z >= 0.7f).  Regardless of success or failure,
-- replace the fraction and endpos with the original ones, so we don't try to
-- move the player down to the new floor and get stuck on a leaning wall that
-- the original trace hit first.
-------------------------------------------------------------------------------
local function TryTouchGroundInQuadrants(start, endpos, fMask, collisionGroup, pm)
	local minsSrc, maxsSrc = GetPlayerMins(), GetPlayerMaxs()
	local fraction, hitpos = pm.Fraction, pm.HitPos
	
	-- Check the -x, -y quadrant
	local mins = minsSrc
	local maxs = Vector(math.min(0, maxsSrc.x), math.min(0, maxsSrc.y), maxsSrc.z)
	pm = TryTouchGround(start, endpos, mins, maxs, fMask, collisionGroup)
	if pm.Entity and pm.HitNormal.z >= 0.7 then
		pm.Fraction = fraction
		pm.HitPos = hitpos
		return pm
	end
	
	-- Check the +x, +y quadrant
	mins = Vector(math.max(0, minsSrc.x), math.max(0, minsSrc.y), minsSrc.z)
	maxs = maxsSrc
	pm = TryTouchGround(start, endpos, mins, maxs, fMask, collisionGroup)
	if pm.Entity and pm.HitNormal.z >= 0.7 then
		pm.Fraction = fraction
		pm.HitPos = hitpos
		return pm
	end
	
	-- Check the -x, +y quadrant
	mins = Vector(minsSrc.x, math.max(0, minsSrc.y), minsSrc.z)
	maxs = Vector(math.min(0, maxsSrc.x), maxsSrc.y, maxsSrc.z)
	pm = TryTouchGround(start, endpos, mins, maxs, fMask, collisionGroup)
	if pm.Entity and pm.HitNormal.z >= 0.7 then
		pm.Fraction = fraction
		pm.HitPos = hitpos
		return pm
	end
	
	-- Check the +x, -y quadrant
	mins = Vector(math.max(0, minsSrc.x), minsSrc.y, minsSrc.z)
	maxs = Vector(maxsSrc.x, math.min(0, maxsSrc.y), maxsSrc.z)
	pm = TryTouchGround(start, endpos, mins, maxs, fMask, collisionGroup)
	if pm.Entity and pm.HitNormal.z >= 0.7 then
		pm.Fraction = fraction
		pm.HitPos = hitpos
		return pm
	end

	pm.Fraction = fraction
	pm.HitPos = hitpos
	return pm
end

local function CategorizeGroundSurface(pm)
	-- local physprops = MoveHelper():GetSurfaceProps() --IPhysicsSurfaceProps
	-- ply.m_surfaceProps = pm.SurfaceProps
	-- ply.m_pSurfaceData = physprops:GetSurfaceData(ply.m_surfaceProps)
	-- physprops:GetPhysicsProperties(ply.m_surfaceProps, nil, nil, ss.m_surfaceFriction[ply], nil)
	
	-- HACKHACK: Scale this to fudge the relationship between vphysics friction values and player friction values.
	-- A value of 0.8f feels pretty normal for vphysics, whereas 1.0f is normal for players.
	-- This scaling trivially makes them equivalent.  REVISIT if this affects low friction surfaces too much.
	ss.m_surfaceFriction[ply] = math.min(1, ss.m_surfaceFriction[ply] * 1.25)
	
	-- ply.m_chTextureType = ply.m_pSurfaceData.game.material
end

local function SetGroundEntity(pm)
	local newGround = pm and pm.Entity or NULL
	local oldGround = plyground
	local vecBaseVelocity = bvel
	if newGround == NULL then newGround = nil end
	if oldGround == NULL then oldGround = nil end
	if not oldGround and newGround then
		-- Subtract ground velocity at instant we hit ground jumping
		vecBaseVelocity = vecBaseVelocity - newGround:GetAbsVelocity()
		vecBaseVelocity.z = newGround:GetAbsVelocity().z
	elseif oldGround and not newGround then
		-- Add in ground velocity at instant we started jumping
 		vecBaseVelocity = vecBaseVelocity + oldGround:GetAbsVelocity()
		vecBaseVelocity.z = oldGround:GetAbsVelocity().z
	end
	
	bvel = vecBaseVelocity
	plyground = newGround or NULL
	
	-- If we are on something...

	if newGround then
		CategorizeGroundSurface(pm)
		
		-- Then we are not in water jump sequence
		ss.m_flWaterJumpTime[ply] = 0
		
		-- Standing on an entity other than the world, so signal that we are touching something.
		if not pm.HitWorld then
			-- MoveHelper():AddToTouched(pm, mvel)
		end
		
		mvel.z = 0.0
	end
end

local function CanAccelerate()
	-- Dead players don't accelerate.
	if IsDead() then return false end
	
	-- If waterjumping, don't accelerate
	if ss.m_flWaterJumpTime[ply] ~= 0 then
		return false
	end
	
	return true
end

local function CheckParameters()
	if mt ~= MOVETYPE_ISOMETRIC and
		mt ~= MOVETYPE_NOCLIP and
		mt ~= MOVETYPE_OBSERVER then
		local spd = m_flForwardMove * m_flForwardMove
		+ m_flSideMove * m_flSideMove + m_flUpMove * m_flUpMove
		if m_flClientMaxSpeed ~= 0.0 then
			m_flClientMaxSpeed = math.min(m_flClientMaxSpeed, m_flMaxSpeed)
		end

		-- Slow down by the speed factor
		local flSpeedFactor = 1.0
		-- if ply.m_pSurfaceData then
			-- flSpeedFactor = ply.m_pSurfaceData.game.maxSpeedFactor
		-- end

		-- If we have a constraint, slow down because of that too.
		local flConstraintSpeedFactor = ComputeConstraintSpeedFactor()
		if flConstraintSpeedFactor < flSpeedFactor then
			flSpeedFactor = flConstraintSpeedFactor
		end

		m_flMaxSpeed = m_flMaxSpeed * flSpeedFactor

		if g_bMovementOptimizations then
			-- Same thing but only do the sqrt if we have to.
			if spd ~= 0.0 and spd > m_flMaxSpeed * m_flMaxSpeed then
				local fRatio = m_flMaxSpeed / math.sqrt(spd)
				m_flForwardMove = m_flForwardMove * fRatio
				m_flSideMove = m_flSideMove * fRatio
				m_flUpMove = m_flUpMove * fRatio
			end
		else
			spd = math.sqrt(spd)
			if spd ~= 0.0 and spd > m_flMaxSpeed then
				local fRatio = m_flMaxSpeed / spd
				m_flForwardMove = m_flForwardMove * fRatio
				m_flSideMove = m_flSideMove * fRatio
				m_flUpMove = m_flUpMove * fRatio
			end
		end
	end

	if bit.band(plyflags, bit.bor(FL_FROZEN, FL_ONTRAIN)) ~= 0 or IsDead() then
		m_flForwardMove, m_flSideMove, m_flUpMove = 0, 0, 0
	end

	DecayPunchAngle()

	-- Take angles from command.
	if not IsDead() then
		local v_angle = mvangles + plyviewangles

		-- Now adjust roll angle
		if mt ~= MOVETYPE_ISOMETRIC and mt ~= MOVETYPE_NOCLIP then
			mvangles.roll = CalcRoll(v_angle, mvel, GetConVar "sv_rollangle":GetFloat(), GetConVar "sv_rollspeed":GetFloat())
		else
			mvangles.roll = 0.0 -- v_angle.roll
		end
		mvangles.pitch = v_angle.pitch
		mvangles.yaw = v_angle.yaw
	else
		mvangles = mvoldangles
	end

	-- Set dead player view_offset
	if IsDead() then
		-- ply:SetViewOffset(g_pGameRules->GetViewVectors()->m_vDeadViewHeight * ply:GetModelScale())
	end

	-- Adjust client view angles to match values used on server.
	if mvangles.yaw > 180 then
		mvangles.yaw = mvangles.yaw - 360
	end
end

local function ReduceTimers()
	local frame_msec = 1000.0 * FrameTime()
	if ss.m_flDucktime[ply] > 0 then
		ss.m_flDucktime[ply] = math.max(0, ss.m_flDucktime[ply] - frame_msec)
	end if ss.m_flDuckJumpTime[ply] > 0 then
		ss.m_flDuckJumpTime[ply] = math.max(0, ss.m_flDuckJumpTime[ply] - frame_msec)
	end if ss.m_flJumpTime[ply] > 0 then
		ss.m_flJumpTime[ply] = math.max(0, ss.m_flJumpTime[ply] - frame_msec)
	end if ss.m_flSwimSoundTime[ply] > 0 then
		ss.m_flSwimSoundTime[ply] = math.max(0, ss.m_flSwimSoundTime[ply] - frame_msec)
	end
end

local function CheckVelocity()
	--
	-- bound velocity
	--
	local maxvelocity = GetConVar "sv_maxvelocity":GetFloat()
	for _, i in ipairs {"x", "y", "z"} do
		-- See if it's bogus.
		-- Msg(string.format(1, "PM  Got a NaN velocity %s\n", i))
		-- Msg(string.format(1, "PM  Got a NaN origin %s\n", i))
		if mvel[i] ~= mvel[i] then mvel[i] = 0 end
		if morg[i] ~= morg[i] then morg[i] = 0 end

		-- Bound it.
		-- Msg(string.format(1, "PM  Got a velocity too high on %s\n", i))
		-- Msg(string.format(1, "PM  Got a velocity too low on %s\n", i))
		mvel[i] = math.Clamp(mvel[i], -maxvelocity, maxvelocity)
	end
end

local function ClipVelocity(vin, normal, out, overbounce)
	-- Determine how far along plane to slide based on incoming direction.
	local backoff = vin:Dot(normal) * overbounce
	local angle = normal.z
	local i, blocked = 0, 0x00 -- Assume unblocked.
	if angle > 0 then -- If the plane that is blocking us has a positive z component, then assume it's a floor.
		blocked = bit.bor(blocked, 0x01)
	elseif angle == 0 then -- If the plane has no Z, it is vertical (wall/step)
		blocked = bit.bor(blocked, 0x02)
	end
	
	out:Set(vin)
	out:Sub(normal * backoff)
	
	-- iterate once to make sure we aren't still moving through the plane
	local adjust = out:Dot(normal)
	if adjust < 0.0 then
		out:Sub(normal * adjust)
		--Msg(string.format("Adjustment = %lf\n", adjust))
	end
	
	-- Return blocking flags.
	return blocked
end


local function StartGravity()
	local ent_gravity = 1.0
	if ply:GetGravity() > 0 then
		ent_gravity = ply:GetGravity()
	end

	-- Add gravity so they'll be in the correct position during movement
	-- yes, this 0.5 looks wrong, but it's not.
	mvel.z = mvel.z - ent_gravity * GetCurrentGravity() * 0.5 * FrameTime()
	mvel.z = mvel.z + bvel.x * FrameTime()
	bvel.z = 0

	CheckVelocity()
end

local function FinishGravity()
	local ent_gravity = 1.0
	if ss.m_flWaterJumpTime[ply] ~= 0 then
		return
	end
	
	if ply:GetGravity() ~= 0 then
		ent_gravity = ply:GetGravity()
	end
	
	-- Get the correct velocity for the end of the dt
	mvel.z = mvel.z - (ent_gravity * GetCurrentGravity() * FrameTime() * 0.5)
	
	CheckVelocity()
end

local function PlayerRoughLandingEffects(fvol)
	if fvol > 0.0 then
		-- Play landing sound right away.
		-- ply:SetSaveValue("m_flStepSoundTime", 400)

		-- Play step sound for current texture.
		-- ply:PlayStepSound(morg, ply.m_pSurfaceData, fvol, true)

		--
		-- Knock the screen around a little bit, temporary effect.
		--
		local a = Angle(plyviewangles)
		plyviewangles.pitch = math.min(plyviewangles.pitch, 8)
		plyviewangles.roll = ss.m_flFallVelocity[ply] * .013
		ss.m_vecPunchAngleVel[ply] = Vector(a.p - plyviewangles.p, 0, a.r - plyviewangles.r)

		if SERVER then
			RumbleEffect(fvol > 0.85 and RUMBLE_FALL_LONG or RUMBLE_FALL_SHORT, 0, RUMBLE_FLAGS_NONE)
		end
	end
end

local function GetPointContentsCached(point, slot)
	if g_bMovementOptimizations then
		-- assert(ply)
		-- assert(slot >= 0 and slot < MAX_PC_CACHE_SLOTS)
		-- local idx = ply:EntIndex()
		-- if m_CachedGetPointContents[idx][slot] == -9999 or point:DistToSqr(m_CachedGetPointContentsPoint[idx][slot]) > 1 then
			-- m_CachedGetPointContents[idx][slot] = util.PointContents(point)
			-- m_CachedGetPointContentsPoint[idx][slot] = point
		-- end
		
		-- return m_CachedGetPointContents[idx][slot]
	else
		return util.PointContents(point)
	end
end

local function CheckFalling()
	-- this function really deals with landing, not falling, so early out otherwise
	if plyground == NULL or ss.m_flFallVelocity[ply] <= 0 then
		return
	end
	
	if not IsDead() and ss.m_flFallVelocity[ply] >= PLAYER_FALL_PUNCH_THRESHOLD then
		local bAlive = true
		local fvol = 0.5
		
		if ss.m_nWaterLevel[ply] > 0 then
			-- They landed in water.
		else
			-- Scale it down if we landed on something that's floating...
			if plyground:IsEFlagSet(EFL_TOUCHING_FLUID) then
				ss.m_flFallVelocity[ply] = ss.m_flFallVelocity[ply] - PLAYER_LAND_ON_FLOATING_OBJECT
			end
			
			--
			-- They hit the ground.
			--
			if plyground:GetAbsVelocity().z < 0.0 then
				-- Player landed on a descending object. Subtract the velocity of the ground entity.
				ss.m_flFallVelocity[ply] = ss.m_flFallVelocity[ply] + plyground:GetAbsVelocity().z
				ss.m_flFallVelocity[ply] = math.max(0.1, ss.m_flFallVelocity[ply])
			end

			if ss.m_flFallVelocity[ply] > PLAYER_MAX_SAFE_FALL_SPEED then
				--
				-- If they hit the ground going this fast they may take damage (and die).
				--
				-- bAlive = MoveHelper():PlayerFallingDamage()
				fvol = 1.0
			elseif ss.m_flFallVelocity[ply] > PLAYER_MAX_SAFE_FALL_SPEED / 2 then
				fvol = 0.85
			elseif ss.m_flFallVelocity[ply] < PLAYER_MIN_BOUNCE_SPEED then
				fvol = 0
			end
		end

		PlayerRoughLandingEffects(fvol)

		if bAlive then
			setanimation = PLAYER_WALK
		end
	end
	
	-- let any subclasses know that the player has landed and how hard
	-- OnLand(ss.m_flFallVelocity[ply])
	
	--
	-- Clear the fall velocity so the impact doesn't happen again.
	--
	ss.m_flFallVelocity[ply] = 0
end

local function CheckJumpButton()
	if IsDead() then -- don't jump again until released
		m_nOldButtons = bit.bor(m_nOldButtons, IN_JUMP)
		return
	end
	
	-- See if we are waterjumping.  If so, decrement count and return.
	if ss.m_flWaterJumpTime[ply] ~= 0 then
		ss.m_flWaterJumpTime[ply] = math.max(0, ss.m_flWaterJumpTime[ply] - FrameTime())
		return
	end
	
	-- If we are in the water most of the way...
	if ss.m_nWaterLevel[ply] >= 2 then
		-- swimming, not jumping
		SetGroundEntity(nil)
		
		if bit.band(ss.m_nWaterType[ply], CONTENTS_WATER) ~= 0 then -- We move up a certain amount
			mvel.z = 100
		elseif bit.band(ss.m_nWaterType[ply], CONTENTS_SLIME) ~= 0 then
			mvel.z = 80
		end
		
		-- play swiming sound
		if ss.m_flSwimSoundTime[ply] <= 0 then
			-- Don't play sound again for 1 second
			ss.m_flSwimSoundTime[ply] = 1000
			PlaySwimSound()
		end
		
		return
	end
	
	-- No more effect
 	if plyground == NULL then
		m_nOldButtons = bit.bor(m_nOldButtons, IN_JUMP)
		return false -- in air, so no effect
	end
	
	-- Don't allow jumping when the player is in a stasis field.
-- #ifndef HL2_EPISODIC
	-- if ply.m_Local.m_bSlowMovement then
		-- return false
	-- end
-- #endif
	
	if bit.band(m_nOldButtons, IN_JUMP) ~= 0 then
		return false -- don't pogo stick
	end
	
	-- Cannot jump will in the unduck transition.
	if ply:Crouching() and bit.band(plyflags, FL_DUCKING) ~= 0 then
		return false
	end
	
	-- Still updating the eye position.
	if ss.m_flDuckJumpTime[ply] > 0.0 then
		return false
	end
	
	-- In the air now.
    SetGroundEntity(nil)
	
	if SERVER then
	-- ply:PlayStepSound(morg, ply.m_pSurfaceData, 1.0, true)
		ply:PlayStepSound(1)
	end
	
	setanimation = PLAYER_JUMP
	mvel.z = mvel.z + ply:GetJumpPower()

	-- local flGroundFactor = 1.0
	-- if ply.m_pSurfaceData then
		-- flGroundFactor = ply.m_pSurfaceData.game.jumpFactor
	-- end

	-- local flMul
	-- if g_bMovementOptimizations then
-- #if defined(HL2_DLL) || defined(HL2_CLIENT_DLL)
		-- assert(GetCurrentGravity() == 600.0)
		-- flMul = 160.0 -- approx. 21 units.
-- #else
		-- assert(GetCurrentGravity() == 800.0)
		-- flMul = 268.3281572999747
-- #endif
	-- else
		-- flMul = math.sqrt(2 * GetCurrentGravity() * GAMEMOVEMENT_JUMP_HEIGHT)
	-- end

	-- Acclerate upward
	-- If we are ducking...
	-- local startz = mvel.z
	-- if ply:Crouching() or bit.band(ply:GetFlags(), FL_DUCKING) ~= 0 then
		-- d = 0.5 * g * t^2		- distance traveled with linear accel
		-- t = sqrt(2.0 * 45 / g)	- how long to fall 45 units
		-- v = g * t				- velocity at the end (just invert it to jump up that high)
		-- v = g * sqrt(2.0 * 45 / g )
		-- v^2 = g * g * 2.0 * 45 / g
		-- v = sqrt( g * 2.0 * 45 )
		-- mvel.z = flGroundFactor * flMul -- 2 * gravity * height
	-- else
		-- mvel.z = flGroundFactor * flMul -- 2 * gravity * height
	-- end

	-- Add a little forward velocity based on your current forward velocity - if you are not sprinting.
-- #if defined( HL2_DLL ) || defined( HL2_CLIENT_DLL )
	-- if game.SinglePlayer() then
		-- local pMoveData = mv
		-- local vecForward = Vector(m_vecForward)
		-- vecForward.z = 0
		-- vecForward:Normalize()
		
		-- We give a certain percentage of the current forward movement as a bonus to the jump speed.  That bonus is clipped
		-- to not accumulate over time.
		-- local flSpeedBoostPerc = not (pMoveData:KeyDown(IN_SPEED) or ply:Crouching()) and 0.5 or 0.1
		-- local flSpeedAddition = math.abs(m_flForwardMove * flSpeedBoostPerc)
		-- local flMaxSpeed = m_flMaxSpeed * (1 + flSpeedBoostPerc) 
		-- local flNewSpeed = flSpeedAddition + mvel:Length2D()
		
		-- If we're over the maximum, we want to only boost as much as will get us to the goal speed
		-- if flNewSpeed > flMaxSpeed then
			-- flSpeedAddition = flSpeedAddition - (flNewSpeed - flMaxSpeed)
		-- end

		-- if m_flForwardMove < 0.0 then
			-- flSpeedAddition = flSpeedAddition * -1.0
		-- end
		
		-- Add it on
		-- mvel = mvel + vecForward * flSpeedAddition
	-- end
-- #endif
	
	FinishGravity()
	
	-- CheckV(ply:CurrentCommandNumber(), "CheckJump", mvel)
	
	-- mv.m_outJumpVel.z = = mv.m_outJumpVel.z + mvel.z - startz
	-- mv.m_outStepHeight = mv.m_outStepHeight + 0.15
	
	-- OnJump(mv.m_outJumpVel.z)
	
	-- Set jump time.
	if game.SinglePlayer() then
		ss.m_flJumpTime[ply] = GAMEMOVEMENT_JUMP_TIME;
		ss.m_bInDuckJump[ply] = true;
	end
	
-- #if defined( HL2_DLL )
	
	-- if GetConVar "xc_uncrouch_on_jump":GetBool() then
		-- Uncrouch when jumping
		-- if ply:GetToggledDuckState() then
			-- ply:ToggleDuck()
		-- end
	-- end
	
-- #endif
	
	-- Flag that we jumped.
	m_nOldButtons = bit.bor(m_nOldButtons, IN_JUMP) -- don't jump again until released
	return true
end

local function CheckWater()
	local vPlayerMins = GetPlayerMins()
	local vPlayerMaxs = GetPlayerMaxs()
	
	-- Pick a spot just above the players feet.
	local point = morg + (vPlayerMins + vPlayerMaxs) / 2
	point.z = morg.z + vPlayerMins.z + 1
	
	-- Assume that we are not in water at all.
	ss.m_nWaterLevel[ply] = WL_NotInWater
	ss.m_nWaterType[ply] = CONTENTS_EMPTY
	
	-- Grab point contents.
	local cont = GetPointContentsCached(point, 0)
	
	-- Are we under water? (not solid and not empty?)
	if bit.band(cont, MASK_WATER) ~= 0 then
		-- Set water type
		ss.m_nWaterType[ply] = cont
		
		-- We are at least at level one
		ss.m_nWaterLevel[ply] = WL_Feet
		
		-- Now check a point that is at the player hull midpoint.
		point.z = morg.z + (vPlayerMins.z + vPlayerMaxs.z) * 0.5
		cont = GetPointContentsCached(point, 1)
		-- If that point is also under water...
		if bit.band(cont, MASK_WATER) ~= 0 then
			-- Set a higher water level.
			ss.m_nWaterLevel[ply] = WL_Waist

			-- Now check the eye position.  (view_ofs is relative to the origin)
			point.z = morg.z + ply:GetViewOffset().z
			cont = GetPointContentsCached(point, 2)
			if bit.band(cont, MASK_WATER) ~= 0 then
				ss.m_nWaterLevel[ply] = WL_Eyes -- In over our eyes
			end
		end
		
		-- Adjust velocity based on water current, if any.
		if bit.band(cont, MASK_CURRENT) ~= 0 then
			local v = Vector()
			if bit.band(cont, CONTENTS_CURRENT_0) ~= 0 then
				v.x = v.x + 1
			end if bit.band(cont, CONTENTS_CURRENT_90) ~= 0 then
				v.y = v.y + 1
			end if bit.band(cont, CONTENTS_CURRENT_180) ~= 0 then
				v.x = v.x - 1
			end if bit.band(cont, CONTENTS_CURRENT_270) ~= 0 then
				v.y = v.y - 1
			end if bit.band(cont, CONTENTS_CURRENT_UP) ~= 0 then
				v.z = v.z + 1
			end if bit.band(cont, CONTENTS_CURRENT_DOWN) ~= 0 then
				v.z = v.z - 1
			end

			-- BUGBUG -- this depends on the value of an unspecified enumerated type
			-- The deeper we are, the stronger the current.
			bvel = bvel + 50.0 * ss.m_nWaterLevel[ply] * v
		end
	end
	
	-- if we just transitioned from not in water to in water, record the time it happened
	if WL_NotInWater == m_nOldWaterLevel and ss.m_nWaterLevel[ply] > WL_NotInWater then
		m_flWaterEntryTime = CurTime()
	end
	
	return ss.m_nWaterLevel[ply] > WL_Feet
end

local function CheckWaterJump()
	if ss.m_flWaterJumpTime[ply] ~= 0 then
		return -- Already water jumping.
	end
	
	-- Don't hop out if we just jumped in
	if mvel.z < -180 then return end -- only hop out if we are moving up
	
	-- See if we are backing up
	local flatvelocity = Vector(mvel)
	flatvelocity.z = 0
	
	-- Must be moving
	local curspeed = flatvelocity:Length()
	flatvelocity:Normalize()
	
	-- see if near an edge
	local flatforward = Vector(m_vecForward)
	flatforward.z = 0
	flatforward:Normalize()
	
	-- Are we backing into water from steps or something?  If so, don't pop forward
	if curspeed ~= 0.0 and flatvelocity:Dot(flatforward) < 0.0 then
		return
	end
	
	-- Start line trace at waist height (using the center of the player for this here)
	local vecStart = morg + (GetPlayerMins() + GetPlayerMaxs()) * 0.5
	local vecEnd = vecStart + 24.0 * flatforward
	local tr = TracePlayerBBox(vecStart, vecEnd, PlayerSolidMask(), COLLISION_GROUP_PLAYER_MOVEMENT)
	if tr.Fraction < 1.0 then -- solid at waist
		local pPhysObj = tr.Entity:GetPhysicsObject()
		if IsValid(pPhysObj) then
			if pPhysObj:HasGameFlag(FVPHYSICS_PLAYER_HELD) then
				return
			end
		end
		
		vecStart.z = morg.z + WATERJUMP_HEIGHT + (ply:Crouching()
		and ply:GetViewOffsetDucked().z or ply:GetViewOffset().z)
		vecEnd = vecStart + 24.0 * flatforward
		ss.m_vecWaterJumpVel[ply] = -50.0 * tr.HitNormal
		
		tr = TracePlayerBBox(vecStart, vecEnd, PlayerSolidMask(), COLLISION_GROUP_PLAYER_MOVEMENT)
		if tr.Fraction == 1.0 then -- open at eye level
			-- Now trace down to see if we would actually land on a standable surface.
			vecStart = Vector(vecEnd)
			vecEnd.z = vecEnd.z - 1024.0
			tr = TracePlayerBBox(vecStart, vecEnd, PlayerSolidMask(), COLLISION_GROUP_PLAYER_MOVEMENT)
			if tr.Fraction < 1.0 and tr.HitNormal.z >= 0.7 then
				mvel.z = 256.0 -- Push up
				m_nOldButtons = bit.bor(m_nOldButtons, IN_JUMP) -- Don't jump again until released
				plyflags = bit.bor(plyflags, FL_WATERJUMP)
				ss.m_flWaterJumpTime[ply] = 2000.0 -- Do this for 2 seconds
			end
		end
	end
end

local function CategorizePosition()
	local point = Vector(morg)
	
	-- Reset this each time we-recategorize, otherwise we have bogus friction when we jump into water and plunge downward really quickly
	ss.m_surfaceFriction[ply] = 1.0
	
	-- if the player hull point one unit down is solid, the player is on ground
	
	-- see if standing on something solid	
	
	-- Doing this before we move may introduce a potential latency in water detection, but
	-- doing it after can get us stuck on the bottom in water if the amount we move up
	-- is less than the 1 pixel 'threshold' we're about to snap to.	Also, we'll call
	-- this several times per frame, so we really need to avoid sticking to the bottom of
	-- water on each call, and the converse case will correct itself if called twice.
	CheckWater()
	
	-- observers don't have a ground entity
	if ply:GetObserverMode() ~= OBS_MODE_NONE then return end
	
	local flOffset = 2.0
	point.z = point.z - flOffset
	
	local bumpOrigin = Vector(morg)
	
	-- Shooting up really fast.  Definitely not on ground.
	-- On ladder moving up, so not on ground either
	-- NOTE: 145 is a jump.
	local NON_JUMP_VELOCITY = 140.0
	
	local zvel = mvel.z
	local bMovingUp = zvel > 0.0
	local bMovingUpRapidly = zvel > NON_JUMP_VELOCITY
	local flGroundEntityVelZ = 0.0
	if bMovingUpRapidly then
		-- Tracker 73219, 75878:  ywb 8/2/07
		-- After save/restore (and maybe at other times), we can get a case where we were saved on a lift and 
		--  after restore we'll have a high local velocity due to the lift making our abs velocity appear high.  
		-- We need to account for standing on a moving ground object in that case in order to determine if we really 
		--  are moving away from the object we are standing on at too rapid a speed.  Note that CheckJump already sets
		--  ground entity to NULL, so this wouldn't have any effect unless we are moving up rapidly not from the jump button.
		if plyground ~= NULL then
			flGroundEntityVelZ = plyground:GetAbsVelocity().z
			bMovingUpRapidly = zvel - flGroundEntityVelZ > NON_JUMP_VELOCITY
		end
	end
	
	-- Was on ground, but now suddenly am not
	if bMovingUpRapidly or bMovingUp and mt == MOVETYPE_LADDER then
		SetGroundEntity(nil)
	else -- Try and move down.
		local pm = TryTouchGround(bumpOrigin, point, GetPlayerMins(), GetPlayerMaxs(), MASK_SHOT, COLLISION_GROUP_PLAYER_MOVEMENT)
		
		-- Was on ground, but now suddenly am not.  If we hit a steep plane, we are not on ground
		if not pm.Entity or pm.Entity == NULL or pm.HitNormal.z < 0.7 then
			-- Test four sub-boxes, to see if any of them would have found shallower slope we could actually stand on
			pm = TryTouchGroundInQuadrants(bumpOrigin, point, MASK_SHOT, COLLISION_GROUP_PLAYER_MOVEMENT, pm)

			if not pm.Entity or pm.Entity == NULL or pm.HitNormal.z < 0.7 then
				SetGroundEntity(nil)
				-- probably want to add a check for a +z velocity too!
				if mvel.z > 0.0 and mt ~= MOVETYPE_NOCLIP then
					ss.m_surfaceFriction[ply] = 0.25
				end
			else
				SetGroundEntity(pm)
			end
		else
			SetGroundEntity(pm) -- Otherwise, point to index of ent under us.
		end

		if not CLIENT then
			
			--Adrian: vehicle code handles for us.
			if not ply:InVehicle() then
				-- If our gamematerial has changed, tell any player surface triggers that are watching
				-- local physprops = MoveHelper():GetSurfaceProps() --IPhysicsSurfaceProps
				-- local pSurfaceProp = physprops:GetSurfaceData(pm.SurfaceProps) --surfacedata_t
				-- local cCurrGameMaterial = pSurfaceProp.game.material --char
				if plyground == NULL then
					-- cCurrGameMaterial = 0
				end
				
				-- Changed?
				-- if ply.m_chPreviousTextureType ~= cCurrGameMaterial then
					-- CEnvPlayerSurfaceTrigger:SetPlayerSurface(ply, cCurrGameMaterial)
				-- end

				-- ply.m_chPreviousTextureType = cCurrGameMaterial
			end
		end
	end
end

local function WaterJump()
	if ss.m_flWaterJumpTime[ply] > 10000 then
		ss.m_flWaterJumpTime[ply] = 10000
	end
	
	if ss.m_flWaterJumpTime[ply] == 0 then
		return
	end
	
	ss.m_flWaterJumpTime[ply] = ss.m_flWaterJumpTime[ply] - 1000.0 * FrameTime()
	
	if ss.m_flWaterJumpTime[ply] <= 0 or ss.m_nWaterLevel[ply] == 0 then
		ss.m_flWaterJumpTime[ply] = 0
		plyflags = bit.band(plyflags, bit.bnot(FL_WATERJUMP))
	end
	
	mvel.x = ss.m_vecWaterJumpVel[ply].x
	mvel.y = ss.m_vecWaterJumpVel[ply].y
end

local function Friction()
	-- If we are in water jump cycle, don't apply friction
	if ss.m_flWaterJumpTime[ply] ~= 0 then return end
	
	local speed = mvel:Length() -- Calculate speed
	if speed < 0.1 then return end -- If too slow, return
	
	local drop = 0 -- apply ground friction
	if plyground ~= NULL then -- On an entity that is the ground
		local friction = GetConVar "sv_friction":GetFloat() * ss.m_surfaceFriction[ply]
		
		-- Bleed off some speed, but if we have less than the bleed
		--  threshold, bleed the threshold amount.
		local control = math.max(speed, GetConVar "sv_stopspeed":GetFloat())
		
		-- Add the amount to the drop amount.
		drop = drop + control * friction * FrameTime()
	end
	
	-- scale the velocity
	local newspeed = math.max(0, speed - drop)
	if newspeed ~= speed then
		-- Determine proportion of old speed we are using.
		newspeed = newspeed / speed
		-- Adjust velocity according to proportion.
		mvel:Mul(newspeed)
	end
	
 	-- mv.m_outWishVel:Sub((1 - newspeed) * mvel)
end

local function Accelerate(wishdir, wishspeed, accel)
	-- This gets overridden because some games (CSPort) want to allow dead (observer) players
	-- to be able to move around.
	if not CanAccelerate() then return end
	
	-- See if we are changing direction a bit
	local currentspeed = mvel:Dot(wishdir)
	
	-- Reduce wishspeed by the amount of veer.
	local addspeed = wishspeed - currentspeed
	
	-- If not going to add any speed, done.
	if addspeed <= 0 then return end
	
	-- Determine amount of accleration.
	-- Cap at addspeed
	local accelspeed = math.min(addspeed, accel * FrameTime() * wishspeed * ss.m_surfaceFriction[ply])
	
	-- Adjust velocity.
	mvel:Add(accelspeed * wishdir)
end

local function AirAccelerate(wishdir, wishspeed, accel)
	if IsDead() then return end
	if ss.m_flWaterJumpTime[ply] ~= 0 then return end
	local wishspd = math.min(wishspeed, GetAirSpeedCap()) -- Cap speed
	
	-- Determine veer amount
	local currentspeed = mvel:Dot(wishdir)
	
	-- See how much to add
	local addspeed = wishspd - currentspeed
	
	-- If not adding any, done.
	if addspeed <= 0 then return end
	
	-- Determine acceleration speed after acceleration
	-- Cap it
	local accelspeed = math.min(addspeed,
	accel * wishspeed * FrameTime() * ss.m_surfaceFriction[ply])
	
	-- Adjust pmove vel.
	mvel:Add(accelspeed * wishdir)
	-- mv.m_outWishVel:Add(accelspeed * wishdir)
end

local function TryPlayerMove(pFirstDest, pFirstTrace)
	local numbumps = 4 -- Bump up to four times
	local dir = Vector()
	local d = 0.0
	local numplanes = 0 -- and not sliding along any planes
	local planes = {} -- MAX_CLIP_PLANES
	local primal_velocity, original_velocity = Vector(mvel), Vector(mvel) -- Store original velocity
	local new_velocity = Vector()
	local a, b = 0, 0
	local pm --TraceResult
	local endpos = Vector()
	local time_left, allFraction = FrameTime(), 0 -- Total time for this movement operation.
	local blocked = 0 -- Assume not blocked
	for bumpcount = 1, numbumps do
		if mvel:Length() == 0.0 then break end
		
		-- Assume we can move all the way from the current origin to the
		--  end point.
		endpos = morg + time_left * mvel

		-- See if we can make it from origin to end point.
		if g_bMovementOptimizations then
			-- If their velocity Z is 0, then we can avoid an extra trace here during WalkMove.
			if pFirstDest and endpos == pFirstDest then
				pm = pFirstTrace
			else
				pm = TracePlayerBBox(morg, endpos, PlayerSolidMask(), COLLISION_GROUP_PLAYER_MOVEMENT)
			end
		else
			pm = TracePlayerBBox(morg, endpos, PlayerSolidMask(), COLLISION_GROUP_PLAYER_MOVEMENT)
		end
		
		allFraction = allFraction + pm.Fraction
		
		-- If we started in a solid object, or we were in solid space
		--  the whole way, zero out our velocity and return that we
		--  are blocked by floor and wall.
		if pm.AllSolid then
			-- entity is trapped in another solid
			mvel:Zero()
			return 4
		end

		-- If we moved some portion of the total distance, then
		--  copy the end position into the pmove.origin and 
		--  zero the plane counter.
		if pm.Fraction > 0 then
			if numbumps > 0 and pm.Fraction == 1 then
				-- There's a precision issue with terrain tracing that can cause a swept box to successfully trace
				--  when the end position is stuck in the triangle.  Re-run the test with an uswept box to catch that
				--  case until the bug is fixed.
				-- If we detect getting stuck, don't allow the movement
				local stuck = TracePlayerBBox(pm.HitPos, pm.HitPos, PlayerSolidMask(), COLLISION_GROUP_PLAYER_MOVEMENT)
				if stuck.StartSolid or stuck.Fraction ~= 1.0 then
					--Msg "Player will become stuck!!!\n"
					mvel:Zero()
					break
				end
			end
			
			-- actually covered some distance
			morg:Set(pm.HitPos)
			original_velocity:Set(mvel)
			numplanes = 0
		end
		
		-- If we covered the entire distance, we are done
		--  and can return.
		if pm.Fraction == 1 then break end -- moved the entire distance
		
		-- Save entity that blocked us (since fraction was < 1.0)
		--  for contact
		-- Add it if it's not already in the list!!!
		-- MoveHelper():AddToTouched(pm, mvel)
		
		-- If the plane we hit has a high z component in the normal, then
		--  it's probably a floor
		if pm.HitNormal.z > 0.7 then
			blocked = bit.bor(blocked, 1) -- floor
		end
		-- If the plane has a zero z component in the normal, then it's a 
		--  step or wall
		if pm.HitNormal.z == 0 then
			blocked = bit.bor(blocked, 2) -- step / wall
		end
		
		-- Reduce amount of m_flFrameTime left by total time left * fraction
		--  that we covered.
		time_left = time_left * (1 - pm.Fraction)
		
		-- Did we run out of planes to clip against?
		if numplanes > MAX_CLIP_PLANES then
			-- this shouldn't really happen
			--  Stop our movement if so.
			mvel:Zero()
			--print "Too many planes 4"
			
			break
		end
		
		-- Set up next clipping plane
		numplanes = numplanes + 1
		planes[numplanes] = Vector(pm.HitNormal)
		
		-- modify original_velocity so it parallels all of the clip planes
		--
		
		-- reflect player velocity 
		-- Only give this a try for first impact plane because you can get yourself stuck in an acute corner by jumping in place
		--  and pressing forward and nobody was really using this bounce/reflection feature anyway...
		if numplanes == 2 and mt == MOVETYPE_WALK and plyground == NULL then
			for i = 1, numplanes do
				if planes[i].z > 0.7 then
					-- floor or slope
					ClipVelocity(original_velocity, planes[i], new_velocity, 1)
					original_velocity:Set(new_velocity)
				else
					ClipVelocity(original_velocity, planes[i], new_velocity, 1.0
					+ GetConVar "sv_bounce":GetFloat() * (1 - ss.m_surfaceFriction[ply]))
				end
			end
			
			mvel:Set(new_velocity)
			original_velocity:Set(new_velocity)
		else
			for i = 1, numplanes do
				a = i
				ClipVelocity(original_velocity, planes[a], mvel, 1)
				for j = 1, numplanes do
					b = j
					if b ~= a then
						-- Are we now moving against this plane?
						if mvel:Dot(planes[b]) < 0 then
							break -- not ok
						end
					elseif b == numplanes then
						b = b + 1
					end
				end
				
				if b == numplanes + 1 then -- Didn't have to clip, so we're ok
					break
				elseif a == numplanes then
					a = a + 1
				end
			end
			
			-- Did we go all the way through plane set
			if a <= numplanes then
				-- go along this plane
				-- pmove.velocity is set in clipping call, no need to set again. 
			else -- go along the crease
				if numplanes ~= 2 then
					mvel:Zero()
					break
				end
				
				dir = planes[1]:Cross(planes[2])
				dir:Normalize()
				d = dir:Dot(mvel)
				mvel = dir * d
			end
			
			--
			-- if original velocity is against the original velocity, stop dead
			-- to avoid tiny occilations in sloping corners
			--
			d = mvel:Dot(primal_velocity)
			if d <= 0 then
				--print "Back"
				mvel:Zero()
				break
			end
		end
	end

	if allFraction == 0 then
		mvel:Zero()
	end

	-- Check if they slammed into a wall
	local fSlamVol = 0.0
	
	local fLateralStoppingAmount = primal_velocity:Length2D() - mvel:Length2D()
	if fLateralStoppingAmount > PLAYER_MAX_SAFE_FALL_SPEED * 2.0 then
		fSlamVol = 1.0
	elseif fLateralStoppingAmount > PLAYER_MAX_SAFE_FALL_SPEED then
		fSlamVol = 0.85
	end
	
	PlayerRoughLandingEffects(fSlamVol)
	
	return blocked
end

local function StayOnGround()
	local start, endpos = Vector(morg), Vector(morg)
	start.z, endpos.z = start.z + 2, endpos.z - ply:GetStepSize()
	
	-- See how far up we can go without getting stuck
	
	local trace = TracePlayerBBox(morg, start, PlayerSolidMask(), COLLISION_GROUP_PLAYER_MOVEMENT)
	start = trace.HitPos
	
	-- using trace.StartSolid is unreliable here, it doesn't get set when
	-- tracing bounding box vs. terrain
	
	-- Now trace down from a known safe position
	trace = TracePlayerBBox(start, endpos, PlayerSolidMask(), COLLISION_GROUP_PLAYER_MOVEMENT)
	if trace.Fraction > 0.0 and	 -- must go somewhere
		trace.Fraction < 1.0 and -- must hit something
		not trace.StartSolid and -- can't be embedded in a solid
		trace.HitNormal.z >= 0.7 then -- can't hit a steep slope that we can't stand on anyway
		local flDelta = math.abs(morg.z - trace.HitPos.z)
		
		-- This is incredibly hacky. The real problem is that trace returning that strange value we can't network over.
		if flDelta > 0.5 * COORD_RESOLUTION then
			morg:Set(trace.HitPos)
		end
	end
end

local function StepMove(vecDestination, trace)
	local vecEndPos = Vector(vecDestination)
	
	-- Try sliding forward both on ground and up 16 pixels
	--  take the move that goes farthest
	local vecPos, vecVel = Vector(morg), Vector(mvel)
	
	-- Slide move down.
	TryPlayerMove(vecEndPos, trace)
	
	-- Down results.
	local vecDownPos, vecDownVel = Vector(morg), Vector(mvel)
	
	-- Reset original values.
	morg:Set(vecPos)
	mvel:Set(vecVel)
	
	-- Move up a stair height.
	vecEndPos:Set(morg)
	if true or ply.m_Local.m_bAllowAutoMovement then
		vecEndPos.z = vecEndPos.z + ply:GetStepSize() + DIST_EPSILON
	end
	
	trace = TracePlayerBBox(morg, vecEndPos, PlayerSolidMask(), COLLISION_GROUP_PLAYER_MOVEMENT)
	if not (trace.StartSolid or trace.AllSolid) then
		morg:Set(trace.HitPos)
	end
	
	-- Slide move up.
	TryPlayerMove()
	
	-- Move down a stair (attempt to).
	vecEndPos:Set(morg)
	if true or ply.m_Local.m_bAllowAutoMovement then
		vecEndPos.z = vecEndPos.z - ply:GetStepSize() + DIST_EPSILON
	end
		
	trace = TracePlayerBBox(morg, vecEndPos, PlayerSolidMask(), COLLISION_GROUP_PLAYER_MOVEMENT)
	
	-- If we are not on the ground any more then use the original movement attempt.
	if trace.HitNormal.z < 0.7 then
		morg:Set(vecDownPos)
		mvel:Set(vecDownVel)
		local flStepDist = morg.z - vecPos.z
		if flStepDist > 0.0 then
			-- mv.m_outStepHeight = mv.m_outStepHeight + flStepDist
		end
		return
	end
	
	-- If the trace ended up in empty space, copy the end over to the origin.
	if not (trace.StartSolid or trace.AllSolid) then
		morg:Set(trace.HitPos)
	end
	
	-- Copy this origin to up.
	local vecUpPos = Vector(morg)
	
	-- decide which one went farther
	local flDownDist
		= (vecDownPos.x - vecPos.x) * (vecDownPos.x - vecPos.x)
		+ (vecDownPos.y - vecPos.y) * (vecDownPos.y - vecPos.y)
	local flUpDist
		= (vecUpPos.x - vecPos.x) * (vecUpPos.x - vecPos.x)
		+ (vecUpPos.y - vecPos.y) * (vecUpPos.y - vecPos.y)
	if flDownDist > flUpDist then
		morg:Set(vecDownPos)
		mvel:Set(vecDownVel)
	else 
		-- copy z value from slide move
		mvel.z = vecDownVel.z
	end
	
	local flStepDist = morg.z - vecPos.z
	if flStepDist > 0 then
		-- mv.m_outStepHeight = mv.m_outStepHeight + flStepDist
	end
end

local function AirMove()
	local fmove, smove = m_flForwardMove, m_flSideMove -- Copy movement amounts
	local forward, right, up = m_vecForward, m_vecRight, m_vecUp -- Determine movement angles
	
	-- Zero out z components of movement vectors
	forward.z, right.z = 0, 0
	forward:Normalize() -- Normalize remainder of vectors
	right:Normalize() --

	local wishvel = forward * fmove + right * smove -- Determine x and y parts of velocity
	wishvel.z = 0 -- Zero out z part of velocity

	local wishdir = Vector(wishvel) -- Determine maginitude of speed of move
	local wishspeed = wishdir:Length()
	wishdir:Normalize()
	
	--
	-- clamp to server defined max speed
	--
	if wishspeed ~= 0.0 and wishspeed > m_flMaxSpeed then
		wishvel = wishvel * m_flMaxSpeed / wishspeed
		wishspeed = m_flMaxSpeed
	end
	
	AirAccelerate(wishdir, wishspeed, GetConVar "sv_airaccelerate":GetFloat())
	
	-- Add in any base velocity to the current velocity.
	mvel:Add(bvel)
	
	TryPlayerMove()
	
	-- Now pull the base velocity back out.   Base velocity is set if you are on a moving object, like a conveyor (or maybe another monster?)
	mvel:Sub(bvel)
end

local function WalkMove()
	local fmove, smove = m_flForwardMove, m_flSideMove -- Copy movement amounts
	local forward, right, up = m_vecForward, m_vecRight, m_vecUp -- Determine movement angles
	local oldground = plyground
	
	-- Zero out z components of movement vectors
	if g_bMovementOptimizations then
		if forward.z ~= 0 then
			forward.z = 0
			forward:Normalize()
		end
		
		if right.z ~= 0 then
			right.z = 0
			right:Normalize()
		end
	else
		forward.z, right.z = 0, 0
		
		forward:Normalize() -- Normalize remainder of vectors.
		right:Normalize()   -- 
	end
	
	local wishvel = forward * fmove + right * smove -- Determine x and y parts of velocity
	wishvel.z = 0 -- Zero out z part of velocity
	
	local wishdir = Vector(wishvel) -- Determine maginitude of speed of move
	local wishspeed = wishdir:Length()
	wishdir:Normalize()
	
	--
	-- Clamp to server defined max speed
	--
	if wishspeed ~= 0.0 and wishspeed > m_flMaxSpeed then
		wishvel:Mul(m_flMaxSpeed / wishspeed)
		wishspeed = m_flMaxSpeed
	end
	
	-- Set pmove velocity
	mvel.z = 0
	Accelerate(wishdir, wishspeed, GetConVar "sv_accelerate":GetFloat())
	mvel.z = 0
	
	-- Add in any base velocity to the current velocity.
	mvel:Add(bvel)
	
	local spd = mvel:Length()
	if spd < 1.0 then
		mvel:Zero()
		-- Now pull the base velocity back out.   Base velocity is set if you are on a moving object, like a conveyor (or maybe another monster?)
		mvel:Sub(bvel)
		return
	end
	
	-- first try just moving to the destination	
	local dest = morg + mvel * FrameTime()
	dest.z = morg.z
	
	-- first try moving directly to the next spot
	local pm = TracePlayerBBox(morg, dest, PlayerSolidMask(), COLLISION_GROUP_PLAYER_MOVEMENT)
	
	-- If we made it all the way, then copy trace end as new player position.
	-- mv.m_outWishVel = mv.m_outWishVel + wishdir * wishspeed

	if pm.Fraction == 1 then
		morg = pm.HitPos
		-- Now pull the base velocity back out.   Base velocity is set if you are on a moving object, like a conveyor (or maybe another monster?)
		mvel:Sub(bvel)
		
		StayOnGround()
		return
	end
	
	-- Don't walk up stairs if not on ground.
	if oldground == NULL and ss.m_nWaterLevel[ply] == 0 then
		-- Now pull the base velocity back out.   Base velocity is set if you are on a moving object, like a conveyor (or maybe another monster?)
		mvel:Sub(bvel)
		return
	end
	
	-- If we are jumping out of water, don't do anything more.
	if ss.m_flWaterJumpTime[ply] ~= 0 then
		-- Now pull the base velocity back out.   Base velocity is set if you are on a moving object, like a conveyor (or maybe another monster?)
		mvel:Sub(bvel)
		return
	end
	
	StepMove(dest, pm)
	
	-- Now pull the base velocity back out.   Base velocity is set if you are on a moving object, like a conveyor (or maybe another monster?)
	mvel:Sub(bvel)
	
	StayOnGround()
end

local function WaterMove()
	--
	-- user intentions
	-- Determine movement angles
	local forward, right, up = m_vecForward, m_vecRight, m_vecUp
	local wishvel = forward * m_flForwardMove + right * m_flSideMove
	
	-- if we have the jump key down, move us up as well
	if bit.band(m_nButtons, IN_JUMP) ~= 0 then
		wishvel.z = wishvel.z + m_flClientMaxSpeed
	-- Sinking after no other movement occurs
	elseif m_flForwardMove == 0 and m_flSideMove == 0 and m_flUpMove == 0 then
		wishvel.z = wishvel.z - 60 -- drift towards bottom
	else -- Go straight up by upmove amount.
		-- exaggerate upward movement along forward as well
		local upwardMovememnt = m_flForwardMove * forward.z * 2
		upwardMovememnt = math.Clamp(upwardMovememnt, 0.0, m_flClientMaxSpeed)
		wishvel.z = wishvel.z + m_flUpMove + upwardMovememnt
	end
	
	-- Copy it over and determine speed
	local wishdir = Vector(wishvel)
	local wishspeed = wishdir:Length()
	wishdir:Normalize()
	
	-- Cap speed.
	if wishspeed > m_flMaxSpeed then
		wishvel = wishvel * m_flMaxSpeed / wishspeed
		wishspeed = m_flMaxSpeed
	end
	
	-- Slow us down a bit.
	wishspeed = wishspeed * 0.8
	
	-- Water friction
	local temp = Vector(mvel)
	local speed, newspeed = temp:Length()
	temp:Normalize()
	if speed ~= 0 then
		newspeed = speed - FrameTime() * speed * GetConVar "sv_friction":GetFloat() * ss.m_surfaceFriction[ply]
		if newspeed < 0.1 then
			newspeed = 0
		end
		
		mvel:Mul(newspeed / speed)
	else
		newspeed = 0
	end
	
	-- water acceleration
	if wishspeed >= 0.1 then -- old !
		local addspeed = wishspeed - newspeed
		if addspeed > 0 then
			wishvel:Normalize()
			local accelspeed = math.min(addspeed,
			GetConVar "sv_accelerate":GetFloat() * wishspeed * FrameTime() * ss.m_surfaceFriction[ply])
			
			mvel:Add(accelspeed * wishvel)
			-- mv.m_outWishVel:Add(accelspeed * wishvel)
		end
	end
	
	mvel:Add(bvel)
	
	-- Now move
	-- assume it is a stair or a slope, so press down from stepheight above
	local dest = morg + FrameTime() * mvel
	local pm = TracePlayerBBox(morg, dest, PlayerSolidMask(), COLLISION_GROUP_PLAYER_MOVEMENT)
	if pm.Fraction == 1.0 then
		local start = Vector(dest)
		if true or ply.m_Local.m_bAllowAutoMovement then
			start.z = start.z + ply:GetStepSize() + 1
		end
		
		pm = TracePlayerBBox(start, dest, PlayerSolidMask(), COLLISION_GROUP_PLAYER_MOVEMENT)
		
		if not (pm.StartSolid or pm.AllSolid) then
			local stepDist = pm.HitPos.z - morg.z
			-- mv.m_outStepHeight = mv.m_outStepHeight + stepDist
			-- walked up the step, so just keep result and exit
			morg:Set(pm.HitPos)
			mvel:Sub(bvel)
			return
		end
		
		-- Try moving straight along out normal path.
		TryPlayerMove()
	else
		if plyground == NULL then
			TryPlayerMove()
			mvel:Sub(bvel)
			return
		end
		
		StepMove(dest, pm)
	end
	
	mvel:Sub(bvel)
end

local function FullWalkMove()
	if not CheckWater() then
		StartGravity()
	end

	-- If we are leaping out of the water, just update the counters.
	if ss.m_flWaterJumpTime[ply] ~= 0 then
		WaterJump()
		TryPlayerMove()
		CheckWater() -- See if we are still in water?
		return
	end

	-- If we are swimming in the water, see if we are nudging against a place we can jump up out
	--  of, and, if so, start out jump.  Otherwise, if we are not moving up, then reset jump timer to 0
	if ss.m_nWaterLevel[ply] >= WL_Waist then
		if ss.m_nWaterLevel[ply] == WL_Waist then
			CheckWaterJump()
		end

		-- If we are falling again, then we must not trying to jump out of water any more.
		if mvel.z < 0 and ss.m_flWaterJumpTime[ply] ~= 0 then
			ss.m_flWaterJumpTime[ply] = 0
		end

		-- Was jump button pressed?
		if bit.band(m_nButtons, IN_JUMP) ~= 0 then
			CheckJumpButton()
		else
			m_nOldButtons = bit.band(m_nOldButtons, bit.bnot(IN_JUMP))
		end

		-- Perform regular water movement
		WaterMove()
		
		-- Redetermine position vars
		CategorizePosition()
		
		-- If we are on ground, no downward velocity.
		if plyground ~= NULL then
			mvel.z = 0
		end
	else -- Not fully underwater
		-- Was jump button pressed?
		if bit.band(m_nButtons, IN_JUMP) ~= 0 then
 			CheckJumpButton()
		else
			m_nOldButtons = bit.band(m_nOldButtons, bit.bnot(IN_JUMP))
		end
		
		-- Fricion is handled before we add in any base velocity. That way, if we are on a conveyor, 
		--  we don't slow when standing still, relative to the conveyor.
		if plyground ~= NULL then
			mvel.z = 0
			Friction()
		end
		
		-- Make sure velocity is valid.
		CheckVelocity()
		
		if plyground ~= NULL then
			WalkMove()
		else
			AirMove()  -- Take into account movement when in air.
		end
		
		-- Set final flags.
		CategorizePosition()
		
		-- Make sure velocity is valid.
		CheckVelocity()
		
		-- Add any remaining gravitational component.
		if not CheckWater() then
			FinishGravity()
		end

		-- If we are on ground, no downward velocity.
		if plyground ~= NULL then
			mvel.z = 0
		end
		CheckFalling()
	end

	if m_nOldWaterLevel == WL_NotInWater and ss.m_nWaterLevel[ply] ~= WL_NotInWater or
		m_nOldWaterLevel ~= WL_NotInWater and ss.m_nWaterLevel[ply] == WL_NotInWater then
		PlaySwimSound()
		PlayerSplash() -- if SERVER then in original source
	end
end

local function SquidMove()
	CheckParameters()
	
	-- clear output applied velocity
	-- mv.m_outWishVel:Zero()
	-- mv.m_outJumpVel:Zero()

	-- MoveHelper()->ResetTouchList() -- Assume we don't touch anything

	ReduceTimers()

	-- Determine movement angles
	-- AngleVectors(mvangles, m_vecForward, m_vecRight, m_vecUp)

	-- Always try and unstick us unless we are using a couple of the movement modes
	if mt ~= MOVETYPE_NOCLIP and mt ~= MOVETYPE_NONE and mt ~= MOVETYPE_ISOMETRIC
		and mt ~= MOVETYPE_OBSERVER and not IsDead() then
		-- if CheckInterval(STUCK) then -- Always return true if g_bMovementOptimizations is false
			-- if CheckStuck() then
				-- return -- Can't move, we're stuck
			-- end
		-- end
	end

	-- Now that we are "unstuck", see where we are (ply:WaterLevel() and type, ply:GetGroundEntity()).
	if mt ~= MOVETYPE_WALK or mv.m_bGameCodeMovedPlayer or
		not GetConVar "sv_optimizedmovement":GetBool() then
		CategorizePosition()
	elseif mvel.z > 250.0 then
		SetGroundEntity(nil)
	end

	-- Store off the starting water level
	m_nOldWaterLevel = ss.m_nWaterLevel[ply]

	-- If we are not on ground, store off how fast we are moving down
	if plyground == NULL then
		ss.m_flFallVelocity[ply] = -mvel.z
	end

	m_nOnLadder = 0

	-- ply:UpdateStepSound(ply.m_pSurfaceData, morg, mvel)

	-- UpdateDuckJumpEyeOffset()
	-- Duck()

	-- Don't run ladder code if dead on on a train
	if not IsDead() or bit.band(plyflags, FL_ONTRAIN) == 0 then
		-- If was not on a ladder now, but was on one before, 
		--  get off of the ladder
		
		-- TODO: this causes lots of weirdness.
		-- local bCheckLadder = CheckInterval(LADDER)
		-- if bCheckLadder or mt == MOVETYPE_LADDER then
			-- if not LadderMove() and mt == MOVETYPE_LADDER then
				-- Clear ladder stuff unless player is dead or riding a train
				-- It will be reset immediately again next frame if necessary
				-- mt = MOVETYPE_WALK
				-- ply:SetMoveCollide(MOVECOLLIDE_DEFAULT)
			-- end
		-- end
	end
	
	FullWalkMove()
end

hook.Add("Move", "SplatoonSWEPs: Squid's movement", function(ply, mv)
	local w = ss:IsValidInkling(ply)
	if not w then return end
	local maxspeed = mv:GetMaxSpeed() * (w.IsDisruptored and ss.DisruptoredSpeed or 1)
	local v = mv:GetVelocity() --Current velocity
	local speed = v:Length2D() --Horizontal speed
	local vz = v.z v.z = 0
	if w:GetInWallInk() and mv:KeyDown(WALLCLIMB_KEYS) then
		vz = math.max(math.abs(vz) * -.75, vz + math.min(
		12 + (mv:KeyPressed(IN_JUMP) and maxspeed / 4 or 0), maxspeed))
		if ply:OnGround() and (ply:GetEyeTraceNoCursor().Fraction
			< util.TraceLine(util.GetPlayerTrace(ply, -ply:GetAimVector())).Fraction)
			== mv:KeyDown(IN_FORWARD) then
			mv:AddKey(IN_JUMP)
		end
	end --Wall climbing
	
	if speed > maxspeed then --Limits horizontal speed
		v = v * maxspeed / speed
		speed = math.min(speed, maxspeed)
	end
	
	if w.OnOutOfInk then --Prevent wall-climb jump
		vz = math.min(vz, maxspeed * .8)
		w.OnOutOfInk = false
	end
	
	mv:SetVelocity(Vector(v.x, v.y, vz)) --Squids can go through fences
end)

--Prevent crouching after firing.
hook.Add("SetupMove", "SplatoonSWEPs: Prevent owner from crouch", function(ply, mv, cm)
	local w = ss:IsValidInkling(ply)
	if not w then return end
	local c = mv:KeyDown(IN_DUCK)
	w.EnemyInkPreventCrouching = w.EnemyInkPreventCrouching and c and w:GetOnEnemyInk()
	if (not w.CrouchPriority and c and mv:KeyDown(IN_ATTACK))
	or CurTime() < w:GetNextCrouchTime() or w.EnemyInkPreventCrouching then
		mv:SetButtons(bit.band(mv:GetButtons(), bit.bnot(IN_DUCK)))
		cm:RemoveKey(IN_DUCK)
	end
end)

hook.Add("FinishMove", "SplatoonSWEPs: Handle noclip", function(p, m)
	ply, mv = p, m
	if not ply:Crouching() then return end
	local w = ss:IsValidInkling(ply)
	if not w then return end
	local infence = w:GetInFence()
	if not ply:Crouching() or (not infence and ply:GetMoveType() == MOVETYPE_NOCLIP) then return end
	local oldpos = Vector(morg)
	local oldvel = Vector(mvel)
	local oldvangles = Angle(plyviewangles)
	local t = {
		start = oldpos, endpos = oldpos - vector_up,
		mins = GetPlayerMins(), maxs = GetPlayerMaxs(),
		mask = MASK_SHOT, collisiongroup = COLLISION_GROUP_PLAYER_MOVEMENT,
		filter = ply,
	}
	
	m_nButtons = mv:GetButtons()
	m_nOldButtons = mv:GetOldButtons()
	m_flClientMaxSpeed = mv:GetMaxClientSpeed()
	m_flMaxSpeed = mv:GetMaxSpeed()
	m_flForwardMove = mv:GetForwardSpeed()
	m_flSideMove = mv:GetSideSpeed()
	m_flUpMove = mv:GetUpSpeed()
	mvangles = mv:GetAngles()
	mvoldangles = mv:GetOldAngles()
	m_vecForward = mvangles:Forward()
	m_vecRight = mvangles:Right()
	m_vecUp = mvangles:Up()
	morg = mv:GetOrigin()
	mvel = mv:GetVelocity()
	mt = MOVETYPE_WALK
	bvel = ply:GetBaseVelocity()
	plyground = ply:GetGroundEntity()
	plyviewangles = ply:GetViewPunchAngles()
	ss.m_nWaterLevel[ply] = ply:WaterLevel()
	setanimation, plyemitsound, splashdata = nil
	plyflags = ply:GetFlags()
	SetGroundEntity(util.TraceHull(t))
	SquidMove()
	debugoverlay.Box(oldpos, GetPlayerMins(), GetPlayerMaxs(), .05, Color(0,0,255,64))
	debugoverlay.Box(morg, GetPlayerMins(), GetPlayerMaxs(), .05, Color(0,255,0,64))
	print(mvel:Length())
	t.endpos = morg
	t.mask = MASK_PLAYERSOLID
	w:SetInFence(util.TraceHull(t).Hit or (plyground ~= NULL) ~= (ply:GetGroundEntity() ~= NULL))
	if w:GetInFence() then
		mv:SetButtons(m_nButtons)
		mv:SetOldButtons(m_nOldButtons)
		mv:SetOrigin(morg)
		mv:SetVelocity(mvel)
		mv:SetAngles(mvangles)
		mv:SetOldAngles(mvoldangles)
		mv:SetMaxSpeed(m_flMaxSpeed)
		mv:SetMaxClientSpeed(m_flClientMaxSpeed)
		mv:SetForwardSpeed(m_flForwardMove)
		mv:SetSideSpeed(m_flSideMove)
		mv:SetUpSpeed(m_flUpMove)
		ply:SetGroundEntity(plyground)
		ply:SetMoveType(MOVETYPE_NOCLIP)
		ply:SetViewPunchAngles(plyviewangles)
		ply:RemoveFlags(ply:GetFlags())
		ply:AddFlags(plyflags)
		ply:AddEFlags(EFL_NOCLIP_ACTIVE)
		if ss.m_nWaterLevel[ply] > WL_NotInWater then
			ply:AddFlags(FL_INWATER)
		else
			ply:RemoveFlags(FL_INWATER)
		end
		if plyemitsound then ply:EmitSound(plyemitsound) end
		if setanimation then ply:SetAnimation(setanimation) end
		if splashdata then util.Effect("watersplash", splashdata) end
		if not infence then hook.Run("SplatoonSWEPs: OnEnteredFence", morg, mvel) end
		hook.Run("UpdateAnimation", ply, mvel, ply:GetSequenceGroundSpeed(ply:GetSequence()))
		return true
	else
		ply:SetMoveType(MOVETYPE_WALK)
		if infence then
			if not mv:KeyDown(IN_DUCK) then
				t.mins, t.maxs = ply:GetHull()
				if util.TraceHull(t).Hit then return end
				ply:RemoveFlags(FL_DUCKING)
				oldvel.z = math.min(oldvel.z, 100)
				mv:SetVelocity(oldvel)
			end
			hook.Run("SplatoonSWEPs: OnLeftFence", morg, mvel)
		end
	end
end)

hook.Add("PlayerNoClip", "SplatoonSWEPs: Through fence", function(ply, desired)
	local w = ss:IsValidInkling(ply)
	local isnoclip = ply:GetMoveType() == MOVETYPE_NOCLIP
	if not (w and w.IsSquid and isnoclip) then return end
	if not w:GetInFence() then ply:SetMoveType(MOVETYPE_WALK) end
	w:SetInFence(false)
	return false
end)
