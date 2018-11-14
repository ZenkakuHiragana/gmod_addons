
-- Player movement emulation for the ability of passing through fences.
-- Source codes are taken from source-sdk-2013/mp/src/game/shared/gamemovement.cpp
local ss = SplatoonSWEPs
if not ss then return end
ss.MoveEmulation = ss.MoveEmulation or {
	m_surfaceFriction = {},
	m_surfaceProps = {},
	m_angViewPunchAngles = {},
	m_bAllowAutoMovement = {},
	m_bCollisionEnabled = {},
	m_bGameCodeMovedPlayer = {},
	m_bInDuckJump = {},
	m_bInFence = {},
	m_bSlowMovement = {},
	m_chPreviousTextureType = {},
	m_chTextureType = {},
	m_entGroundEntity = {},
	m_flClientMaxSpeed = {},
	m_flConstraintRadius = {},
	m_flConstraintSpeedFactor = {},
	m_flConstraintWidth = {},
	m_flDuckJumpTime = {},
	m_flDucktime = {},
	m_flFallVelocity = {},
	m_flForwardMove = {},
	m_flJumpTime = {},
	m_flMaxSpeed = {},
	m_flSideMove = {},
	m_flStepSoundTime = {},
	m_flSwimSoundTime = {},
	m_flUpMove = {},
	m_flWaterEntryTime = {},
	m_flWaterJumpTime = {},
	m_nButtons = {},
	m_nEmitSound = {},
	m_nFlags = {},
	m_nMoveType = {},
	m_nOldButtons = {},
	m_nOldWaterLevel = {},
	m_nOnLadder = {},
	m_nSetAnimation = {},
	m_nSplashData = {},
	m_nWaterLevel = {},
	m_nWaterType = {},
	m_outJumpVel = {},
	m_outStepHeight = {},
	m_outWishVel = {},
	m_pSurfaceData = {},
	m_vecAngles = {},
	m_vecBaseVelocity = {},
	m_vecConstraintCenter = {},
	m_vecForward = {},
	m_vecOldAngles = {},
	m_vecOrigin = {},
	m_vecPunchAngleVel = {},
	m_vecRight = {},
	m_vecUp = {},
	m_vecVelocity = {},
	m_vecWaterJumpVel = {},
}
local FT = FrameTime
local me, mv, ply = ss.MoveEmulation
function ss.InitializeMoveEmulation(ply)
	if not IsValid(ply) then return end
	for var, t in pairs(me) do
		if t[ply] ~= nil then continue end
		if var:find "m_ang" then t[ply] = Angle()
		elseif var:find "m_b" then t[ply] = false
		elseif var:find "m_ent" then t[ply] = NULL
		elseif var:find "m_vec" then t[ply] = Vector()
		elseif var:find "m_ch" or var:find "m_fl"
		or var:find "m_n" then t[ply] = 0 end
	end
	
	me.m_surfaceFriction[ply] = 1
	me.m_surfaceProps[ply] = 0
	me.m_outJumpVel[ply] = Vector()
	me.m_outStepHeight[ply] = 0
	me.m_outWishVel[ply] = Vector()
end

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
local function GetPlayerViewOffset(ducked)
	return ducked and ply:GetViewOffsetDucked() or ply:GetViewOffset()
end

local function PlayerSplash()
	me.m_nSplashData[ply] = EffectData()
	me.m_nSplashData[ply]:SetFlags(0)
	me.m_nSplashData[ply]:SetOrigin(me.m_vecOrigin[ply])
	me.m_nSplashData[ply]:SetNormal(vector_up)
	me.m_nSplashData[ply]:SetAngles(angle_zero)
	
	if bit.band(me.m_nWaterType[ply], CONTENTS_SLIME) ~= 0 then
		me.m_nSplashData[ply]:SetFlags(FX_WATER_IN_SLIME)
	end

	local flSpeed = ply:GetAbsVelocity():Length()
	if flSpeed < 300 then
		me.m_nSplashData[ply]:SetScale(math.Rand(10, 12))
	else
		me.m_nSplashData[ply]:SetScale(math.Rand(6, 8))
	end
end

local function PlaySwimSound()
	me.m_nEmitSound[ply] = "Player.Swim"
end

local function PlayerSolidMask(brushOnly)
	-- return brushOnly and MASK_PLAYERSOLID_BRUSHONLY or MASK_PLAYERSOLID
	return brushOnly and ss.SquidSolidMaskBrushOnly or ss.SquidSolidMask
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
	local vecPunchAngles = me.m_angViewPunchAngles[ply]
	vecPunchAngles = Vector(vecPunchAngles.p, vecPunchAngles.y, vecPunchAngles.r)
	if vecPunchAngles:LengthSqr() > 0.001 or me.m_vecPunchAngleVel[ply]:LengthSqr() > 0.001 then
		vecPunchAngles = vecPunchAngles + me.m_vecPunchAngleVel[ply] * FT()
		local damping = math.max(0, 1 - PUNCH_DAMPING * FT())
		me.m_vecPunchAngleVel[ply] = me.m_vecPunchAngleVel[ply] * damping
		
		-- torsional spring
		-- UNDONE: Per-axis spring constant?
		local springForceMagnitude = PUNCH_SPRING_CONSTANT * FT()
		springForceMagnitude = math.Clamp(springForceMagnitude, 0, 2)
		me.m_vecPunchAngleVel[ply] = me.m_vecPunchAngleVel[ply] - vecPunchAngles * springForceMagnitude

		-- don't wrap around
		vecPunchAngles:Set(Vector( 
			math.Clamp(vecPunchAngles.x, -89, 89), 
			math.Clamp(vecPunchAngles.y, -179, 179),
			math.Clamp(vecPunchAngles.z, -89, 89)))
		me.m_angViewPunchAngles[ply] = Angle(vecPunchAngles.x, vecPunchAngles.y, vecPunchAngles.z)
	else
		me.m_angViewPunchAngles[ply] = Angle()
		me.m_vecPunchAngleVel[ply]:Zero()
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
	if me.m_flConstraintRadius[ply] == 0 then return 1 end
	
	local flDistSq = me.m_vecOrigin[ply]:DistToSqr(me.m_vecConstraintCenter[ply])

	local flOuterRadiusSq = me.m_flConstraintRadius[ply] * me.m_flConstraintRadius[ply]
	local flInnerRadiusSq = me.m_flConstraintRadius[ply] - me.m_flConstraintRadius[ply]
	flInnerRadiusSq = flInnerRadiusSq * flInnerRadiusSq

	-- Only slow us down if we're inside the constraint ring
	if flDistSq <= flInnerRadiusSq or flDistSq >= flOuterRadiusSq then return 1 end

	-- Only slow us down if we're running away from the center
	local vecDesired = me.m_vecForward[ply] * me.m_flForwardMove[ply]
	+ me.m_vecRight[ply] * me.m_flSideMove[ply] + me.m_vecUp[ply] * me.m_flUpMove[ply]

	local vecDelta = me.m_vecOrigin[ply] - me.m_vecConstraintCenter[ply]
	vecDelta:Normalize()
	vecDesired:Normalize()
	if vecDelta:Dot(vecDesired) < 0 then return 1 end

	local flFrac = (math.sqrt(flDistSq) - (me.m_flConstraintRadius[ply] - me.m_flConstraintRadius[ply])) / me.m_flConstraintRadius[ply]

	return Lerp(flFrac, 1, me.m_flConstraintSpeedFactor[ply]) --flSpeedFactor
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
	
	for mins, maxs in pairs {
		-- Check the -x, -y quadrant
		[minsSrc] = Vector(math.min(0, maxsSrc.x), math.min(0, maxsSrc.y), maxsSrc.z),
		-- Check the +x, +y quadrant
		[Vector(math.max(0, minsSrc.x), math.max(0, minsSrc.y), minsSrc.z)] = maxsSrc,
		-- Check the -x, +y quadrant
		[Vector(minsSrc.x, math.max(0, minsSrc.y), minsSrc.z)]
		= Vector(math.min(0, maxsSrc.x), maxsSrc.y, maxsSrc.z),
		-- Check the +x, -y quadrant
		[Vector(math.max(0, minsSrc.x), minsSrc.y, minsSrc.z)]
		= Vector(maxsSrc.x, math.min(0, maxsSrc.y), maxsSrc.z),
	} do
		pm = TryTouchGround(start, endpos, mins, maxs, fMask, collisionGroup)
		if pm.Entity ~= NULL and pm.HitNormal.z >= 0.7 then break end
	end

	pm.Fraction = fraction
	pm.HitPos = hitpos
	return pm
end

local function CategorizeGroundSurface(pm)
	-- local physprops = MoveHelper():GetSurfaceProps() --IPhysicsSurfaceProps
	me.m_surfaceProps[ply] = pm.SurfaceProps
	-- me.m_pSurfaceData[ply] = physprops:GetSurfaceData(me.m_surfaceProps[ply])
	-- physprops:GetPhysicsProperties(me.m_surfaceProps[ply], nil, nil, me.m_surfaceFriction[ply], nil)
	
	-- HACKHACK: Scale this to fudge the relationship between vphysics friction values and player friction values.
	-- A value of 0.8f feels pretty normal for vphysics, whereas 1.0f is normal for players.
	-- This scaling trivially makes them equivalent.  REVISIT if this affects low friction surfaces too much.
	me.m_surfaceFriction[ply] = math.min(1, me.m_surfaceFriction[ply] * 1.25)
	
	-- me.m_chTextureType[ply] = me.m_pSurfaceData[ply].game.material
end

local function SetGroundEntity(pm)
	local newGround = pm and pm.Entity or NULL
	local oldGround = me.m_entGroundEntity[ply]
	local vecBaseVelocity = me.m_vecBaseVelocity[ply]
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
	
	me.m_vecBaseVelocity[ply] = vecBaseVelocity
	me.m_entGroundEntity[ply] = newGround or NULL
	
	-- If we are on something...

	if newGround then
		CategorizeGroundSurface(pm)
		
		-- Then we are not in water jump sequence
		me.m_flWaterJumpTime[ply] = 0
		
		-- Standing on an entity other than the world, so signal that we are touching something.
		if not pm.HitWorld then
			-- MoveHelper():AddToTouched(pm, me.m_vecVelocity[ply])
		end
		
		me.m_vecVelocity[ply].z = 0.0
	end
end

local function CanAccelerate()
	-- Dead players don't accelerate.
	if IsDead() then return false end
	
	-- If waterjumping, don't accelerate
	if me.m_flWaterJumpTime[ply] ~= 0 then
		return false
	end
	
	return true
end

local function CheckParameters()
	if me.m_nMoveType[ply] ~= MOVETYPE_ISOMETRIC and
		me.m_nMoveType[ply] ~= MOVETYPE_NOCLIP and
		me.m_nMoveType[ply] ~= MOVETYPE_OBSERVER then
		local spd = me.m_flForwardMove[ply] * me.m_flForwardMove[ply]
		+ me.m_flSideMove[ply] * me.m_flSideMove[ply] + me.m_flUpMove[ply] * me.m_flUpMove[ply]
		if me.m_flClientMaxSpeed[ply] ~= 0.0 then
			me.m_flClientMaxSpeed[ply] = math.min(me.m_flClientMaxSpeed[ply], me.m_flMaxSpeed[ply])
		end

		-- Slow down by the speed factor
		local flSpeedFactor = 1.0
		if me.m_pSurfaceData[ply] then
			-- flSpeedFactor = me.m_pSurfaceData[ply].game.maxSpeedFactor
		end

		-- If we have a constraint, slow down because of that too.
		local flConstraintSpeedFactor = ComputeConstraintSpeedFactor()
		if flConstraintSpeedFactor < flSpeedFactor then
			flSpeedFactor = flConstraintSpeedFactor
		end

		me.m_flMaxSpeed[ply] = me.m_flMaxSpeed[ply] * flSpeedFactor

		if g_bMovementOptimizations then
			-- Same thing but only do the sqrt if we have to.
			if spd ~= 0.0 and spd > me.m_flMaxSpeed[ply] * me.m_flMaxSpeed[ply] then
				local fRatio = me.m_flMaxSpeed[ply] / math.sqrt(spd)
				me.m_flForwardMove[ply] = me.m_flForwardMove[ply] * fRatio
				me.m_flSideMove[ply] = me.m_flSideMove[ply] * fRatio
				me.m_flUpMove[ply] = me.m_flUpMove[ply] * fRatio
			end
		else
			spd = math.sqrt(spd)
			if spd ~= 0.0 and spd > me.m_flMaxSpeed[ply] then
				local fRatio = me.m_flMaxSpeed[ply] / spd
				me.m_flForwardMove[ply] = me.m_flForwardMove[ply] * fRatio
				me.m_flSideMove[ply] = me.m_flSideMove[ply] * fRatio
				me.m_flUpMove[ply] = me.m_flUpMove[ply] * fRatio
			end
		end
	end

	if bit.band(me.m_nFlags[ply], bit.bor(FL_FROZEN, FL_ONTRAIN)) ~= 0 or IsDead() then
		me.m_flForwardMove[ply], me.m_flSideMove[ply], me.m_flUpMove[ply] = 0, 0, 0
	end

	DecayPunchAngle()

	-- Take angles from command.
	if not IsDead() then
		local v_angle = me.m_vecAngles[ply] + me.m_angViewPunchAngles[ply]

		-- Now adjust roll angle
		if me.m_nMoveType[ply] ~= MOVETYPE_ISOMETRIC and me.m_nMoveType[ply] ~= MOVETYPE_NOCLIP then
			me.m_vecAngles[ply].roll = CalcRoll(v_angle, me.m_vecVelocity[ply], GetConVar "sv_rollangle":GetFloat(), GetConVar "sv_rollspeed":GetFloat())
		else
			me.m_vecAngles[ply].roll = 0.0 -- v_angle.roll
		end
		me.m_vecAngles[ply].pitch = v_angle.pitch
		me.m_vecAngles[ply].yaw = v_angle.yaw
	else
		me.m_vecAngles[ply] = me.m_vecOldAngles[ply]
	end

	-- Set dead player view_offset
	if IsDead() then
		-- ply:SetViewOffset(g_pGameRules->GetViewVectors()->m_vDeadViewHeight * ply:GetModelScale())
	end

	-- Adjust client view angles to match values used on server.
	me.m_vecAngles[ply].yaw = math.NormalizeAngle(me.m_vecAngles[ply].yaw)
end

local function ReduceTimers()
	local frame_msec = 1000.0 * FT()
	if me.m_flDucktime[ply] > 0 then
		me.m_flDucktime[ply] = math.max(0, me.m_flDucktime[ply] - frame_msec)
	end if me.m_flDuckJumpTime[ply] > 0 then
		me.m_flDuckJumpTime[ply] = math.max(0, me.m_flDuckJumpTime[ply] - frame_msec)
	end if me.m_flJumpTime[ply] > 0 then
		me.m_flJumpTime[ply] = math.max(0, me.m_flJumpTime[ply] - frame_msec)
	end if me.m_flSwimSoundTime[ply] > 0 then
		me.m_flSwimSoundTime[ply] = math.max(0, me.m_flSwimSoundTime[ply] - frame_msec)
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
		if me.m_vecVelocity[ply][i] ~= me.m_vecVelocity[ply][i] then me.m_vecVelocity[ply][i] = 0 end
		if me.m_vecOrigin[ply][i] ~= me.m_vecOrigin[ply][i] then me.m_vecOrigin[ply][i] = 0 end

		-- Bound it.
		-- Msg(string.format(1, "PM  Got a velocity too high on %s\n", i))
		-- Msg(string.format(1, "PM  Got a velocity too low on %s\n", i))
		me.m_vecVelocity[ply][i] = math.Clamp(me.m_vecVelocity[ply][i], -maxvelocity, maxvelocity)
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
	
	out:Set(vin - normal * backoff)
	
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
	me.m_vecVelocity[ply].z = me.m_vecVelocity[ply].z - ent_gravity * GetCurrentGravity() * 0.5 * FT()
	me.m_vecVelocity[ply].z = me.m_vecVelocity[ply].z + me.m_vecBaseVelocity[ply].x * FT()
	me.m_vecBaseVelocity[ply].z = 0

	CheckVelocity()
end

local function FinishGravity()
	if me.m_flWaterJumpTime[ply] ~= 0 then
		return
	end
	
	local ent_gravity = 1.0
	if ply:GetGravity() ~= 0 then
		ent_gravity = ply:GetGravity()
	end
	
	-- Get the correct velocity for the end of the dt
	me.m_vecVelocity[ply].z = me.m_vecVelocity[ply].z - ent_gravity * GetCurrentGravity() * FT() / 2
	
	CheckVelocity()
end

local function PlayerRoughLandingEffects(fvol)
	if fvol > 0.0 then
		-- Play landing sound right away.
		me.m_flStepSoundTime[ply] = 400

		-- Play step sound for current texture.
		-- ply:PlayStepSound(me.m_vecOrigin[ply], me.m_pSurfaceData[ply], fvol, true)

		--
		-- Knock the screen around a little bit, temporary effect.
		--
		local a = Angle(me.m_angViewPunchAngles[ply])
		me.m_angViewPunchAngles[ply].pitch = math.min(me.m_angViewPunchAngles[ply].pitch, 8)
		me.m_angViewPunchAngles[ply].roll = me.m_flFallVelocity[ply] * .013
		me.m_vecPunchAngleVel[ply] = Vector(a.p - me.m_angViewPunchAngles[ply].p, 0, a.r - me.m_angViewPunchAngles[ply].r)

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
	if me.m_entGroundEntity[ply] == NULL or me.m_flFallVelocity[ply] <= 0 then
		return
	end
	
	if not IsDead() and me.m_flFallVelocity[ply] >= PLAYER_FALL_PUNCH_THRESHOLD then
		local bAlive = true
		local fvol = 0.5
		
		if me.m_nWaterLevel[ply] > 0 then
			-- They landed in water.
		else
			-- Scale it down if we landed on something that's floating...
			if me.m_entGroundEntity[ply]:IsEFlagSet(EFL_TOUCHING_FLUID) then
				me.m_flFallVelocity[ply] = me.m_flFallVelocity[ply] - PLAYER_LAND_ON_FLOATING_OBJECT
			end
			
			--
			-- They hit the ground.
			--
			if me.m_entGroundEntity[ply]:GetAbsVelocity().z < 0.0 then
				-- Player landed on a descending object. Subtract the velocity of the ground entity.
				me.m_flFallVelocity[ply] = me.m_flFallVelocity[ply] + me.m_entGroundEntity[ply]:GetAbsVelocity().z
				me.m_flFallVelocity[ply] = math.max(0.1, me.m_flFallVelocity[ply])
			end

			if me.m_flFallVelocity[ply] > PLAYER_MAX_SAFE_FALL_SPEED then
				--
				-- If they hit the ground going this fast they may take damage (and die).
				--
				-- bAlive = MoveHelper():PlayerFallingDamage()
				fvol = 1.0
			elseif me.m_flFallVelocity[ply] > PLAYER_MAX_SAFE_FALL_SPEED / 2 then
				fvol = 0.85
			elseif me.m_flFallVelocity[ply] < PLAYER_MIN_BOUNCE_SPEED then
				fvol = 0
			end
		end

		PlayerRoughLandingEffects(fvol)

		if bAlive then
			me.m_nSetAnimation[ply] = PLAYER_WALK
		end
	end
	
	-- let any subclasses know that the player has landed and how hard
	hook.Run("SplatoonSWEPs: OnPlayerLand", me.m_flFallVelocity[ply])
	
	--
	-- Clear the fall velocity so the impact doesn't happen again.
	--
	me.m_flFallVelocity[ply] = 0
end

local function CheckJumpButton()
	if IsDead() then -- don't jump again until released
		me.m_nOldButtons[ply] = bit.bor(me.m_nOldButtons[ply], IN_JUMP)
		return
	end
	
	-- See if we are waterjumping.  If so, decrement count and return.
	if me.m_flWaterJumpTime[ply] ~= 0 then
		me.m_flWaterJumpTime[ply] = math.max(0, me.m_flWaterJumpTime[ply] - FT())
		return
	end
	
	-- If we are in the water most of the way...
	if me.m_nWaterLevel[ply] >= 2 then
		-- swimming, not jumping
		SetGroundEntity(nil)
		
		if bit.band(me.m_nWaterType[ply], CONTENTS_WATER) ~= 0 then -- We move up a certain amount
			me.m_vecVelocity[ply].z = 100
		elseif bit.band(me.m_nWaterType[ply], CONTENTS_SLIME) ~= 0 then
			me.m_vecVelocity[ply].z = 80
		end
		
		-- play swiming sound
		if me.m_flSwimSoundTime[ply] <= 0 then
			-- Don't play sound again for 1 second
			me.m_flSwimSoundTime[ply] = 1000
			PlaySwimSound()
		end
		
		return
	end
	
	-- No more effect
 	if me.m_entGroundEntity[ply] == NULL then
		me.m_nOldButtons[ply] = bit.bor(me.m_nOldButtons[ply], IN_JUMP)
		return false -- in air, so no effect
	end
	
	-- Don't allow jumping when the player is in a stasis field.
-- #ifndef HL2_EPISODIC
	if me.m_bSlowMovement[ply] then
		return false
	end
-- #endif
	
	if bit.band(me.m_nOldButtons[ply], IN_JUMP) ~= 0 then
		return false -- don't pogo stick
	end
	
	-- Cannot jump will in the unduck transition.
	-- if ply:Crouching() and bit.band(me.m_nFlags[ply], FL_DUCKING) ~= 0 then
		-- return false
	-- end
	
	-- Still updating the eye position.
	if me.m_flDuckJumpTime[ply] > 0.0 then
		return false
	end
	
	-- In the air now.
    SetGroundEntity(nil)
	
	if SERVER then
	-- ply:PlayStepSound(me.m_vecOrigin[ply], me.m_pSurfaceData[ply], 1.0, true)
		ply:PlayStepSound(1)
	end
	
	me.m_nSetAnimation[ply] = PLAYER_JUMP

	local flGroundFactor = 1.0
	if me.m_pSurfaceData[ply] then
		-- flGroundFactor = me.m_pSurfaceData[ply].game.jumpFactor
	end

	local flMul
	if g_bMovementOptimizations then
-- #if defined(HL2_DLL) || defined(HL2_CLIENT_DLL)
		assert(GetCurrentGravity() == 600.0)
		flMul = 160.0 -- approx. 21 units.
-- #else
		assert(GetCurrentGravity() == 800.0)
		flMul = 268.3281572999747
-- #endif
	else
		flMul = math.sqrt(2 * GetCurrentGravity() * GAMEMOVEMENT_JUMP_HEIGHT)
	end

	-- Acclerate upward
	-- If we are ducking...
	local startz = me.m_vecVelocity[ply].z
	if ply:Crouching() or bit.band(me.m_nFlags[ply], FL_DUCKING) ~= 0 then
		-- d = 0.5 * g * t^2		- distance traveled with linear accel
		-- t = sqrt(2.0 * 45 / g)	- how long to fall 45 units
		-- v = g * t				- velocity at the end (just invert it to jump up that high)
		-- v = g * sqrt(2.0 * 45 / g )
		-- v^2 = g * g * 2.0 * 45 / g
		-- v = sqrt( g * 2.0 * 45 )
		me.m_vecVelocity[ply].z = flGroundFactor * flMul -- 2 * gravity * height
	else
		me.m_vecVelocity[ply].z = flGroundFactor * flMul -- 2 * gravity * height
	end
	me.m_vecVelocity[ply].z = ply:GetJumpPower()

	-- Add a little forward velocity based on your current forward velocity - if you are not sprinting.
-- #if defined( HL2_DLL ) || defined( HL2_CLIENT_DLL )
	if ss.sp then
		local pMoveData = mv
		local vecForward = Vector(me.m_vecForward[ply])
		vecForward.z = 0
		vecForward:Normalize()
		
		-- We give a certain percentage of the current forward movement as a bonus to the jump speed.  That bonus is clipped
		-- to not accumulate over time.
		local flSpeedBoostPerc = bit.band(me.m_nButtons[ply], IN_SPEED) == 0 and not ply:Crouching() and 0.5 or 0.1
		local flSpeedAddition = math.abs(me.m_flForwardMove[ply] * flSpeedBoostPerc)
		local flMaxSpeed = me.m_flMaxSpeed[ply] * (1 + flSpeedBoostPerc) 
		local flNewSpeed = flSpeedAddition + me.m_vecVelocity[ply]:Length2D()
		
		-- If we're over the maximum, we want to only boost as much as will get us to the goal speed
		if flNewSpeed > flMaxSpeed then
			flSpeedAddition = flSpeedAddition - (flNewSpeed - flMaxSpeed)
		end

		if me.m_flForwardMove[ply] < 0.0 then
			flSpeedAddition = flSpeedAddition * -1.0
		end
		
		-- Add it on
		-- me.m_vecVelocity[ply] = me.m_vecVelocity[ply] + vecForward * flSpeedAddition
	end
-- #endif
	
	FinishGravity()
	
	-- CheckV(ply:CurrentCommandNumber(), "CheckJump", me.m_vecVelocity[ply])
	
	me.m_outJumpVel[ply].z = me.m_outJumpVel[ply].z + me.m_vecVelocity[ply].z - startz
	me.m_outStepHeight[ply] = me.m_outStepHeight[ply] + 0.15
	
	hook.Run("SplatoonSWEPs: OnPlayerJump", me.m_outJumpVel[ply].z)
	
	-- Set jump time.
	if ss.sp then
		me.m_flJumpTime[ply] = GAMEMOVEMENT_JUMP_TIME
		me.m_bInDuckJump[ply] = true
	end
	
-- #if defined( HL2_DLL )
	if GetConVar "xc_uncrouch_on_jump":GetBool() then
		-- Uncrouch when jumping
		-- if ply:GetToggledDuckState() then
			-- ply:ToggleDuck()
		-- end
	end
-- #endif
	
	-- Flag that we jumped.
	me.m_nOldButtons[ply] = bit.bor(me.m_nOldButtons[ply], IN_JUMP) -- don't jump again until released
	return true
end

local function CheckWater()
	local vPlayerMins = GetPlayerMins()
	local vPlayerMaxs = GetPlayerMaxs()
	
	-- Pick a spot just above the players feet.
	local point = me.m_vecOrigin[ply] + (vPlayerMins + vPlayerMaxs) / 2
	point.z = me.m_vecOrigin[ply].z + vPlayerMins.z + 1
	
	-- Assume that we are not in water at all.
	me.m_nWaterLevel[ply] = WL_NotInWater
	me.m_nWaterType[ply] = CONTENTS_EMPTY
	
	-- Grab point contents.
	local cont = GetPointContentsCached(point, 0)
	
	-- Are we under water? (not solid and not empty?)
	if bit.band(cont, MASK_WATER) ~= 0 then
		-- Set water type
		me.m_nWaterType[ply] = cont
		
		-- We are at least at level one
		me.m_nWaterLevel[ply] = WL_Feet
		
		-- Now check a point that is at the player hull midpoint.
		point.z = me.m_vecOrigin[ply].z + (vPlayerMins.z + vPlayerMaxs.z) * 0.5
		cont = GetPointContentsCached(point, 1)
		-- If that point is also under water...
		if bit.band(cont, MASK_WATER) ~= 0 then
			-- Set a higher water level.
			me.m_nWaterLevel[ply] = WL_Waist

			-- Now check the eye position.  (view_ofs is relative to the origin)
			point.z = me.m_vecOrigin[ply].z + ply:GetViewOffset().z
			cont = GetPointContentsCached(point, 2)
			if bit.band(cont, MASK_WATER) ~= 0 then
				me.m_nWaterLevel[ply] = WL_Eyes -- In over our eyes
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
			me.m_vecBaseVelocity[ply] = me.m_vecBaseVelocity[ply] + 50.0 * me.m_nWaterLevel[ply] * v
		end
	end
	
	-- if we just transitioned from not in water to in water, record the time it happened
	if WL_NotInWater == me.m_nOldWaterLevel[ply] and me.m_nWaterLevel[ply] > WL_NotInWater then
		me.m_flWaterEntryTime[ply] = CurTime()
	end
	
	return me.m_nWaterLevel[ply] > WL_Feet
end

local function CheckWaterJump()
	if me.m_flWaterJumpTime[ply] ~= 0 then
		return -- Already water jumping.
	end
	
	-- Don't hop out if we just jumped in
	if me.m_vecVelocity[ply].z < -180 then return end -- only hop out if we are moving up
	
	-- See if we are backing up
	local flatvelocity = Vector(me.m_vecVelocity[ply])
	flatvelocity.z = 0
	
	-- Must be moving
	local curspeed = flatvelocity:Length()
	flatvelocity:Normalize()
	
	-- see if near an edge
	local flatforward = Vector(me.m_vecForward[ply])
	flatforward.z = 0
	flatforward:Normalize()
	
	-- Are we backing into water from steps or something?  If so, don't pop forward
	if curspeed ~= 0.0 and flatvelocity:Dot(flatforward) < 0.0 then
		return
	end
	
	-- Start line trace at waist height (using the center of the player for this here)
	local vecStart = me.m_vecOrigin[ply] + (GetPlayerMins() + GetPlayerMaxs()) * 0.5
	local vecEnd = vecStart + 24.0 * flatforward
	local tr = TracePlayerBBox(vecStart, vecEnd, PlayerSolidMask(), COLLISION_GROUP_PLAYER_MOVEMENT)
	if tr.Fraction < 1.0 then -- solid at waist
		local pPhysObj = tr.Entity:GetPhysicsObject()
		if IsValid(pPhysObj) then
			if pPhysObj:HasGameFlag(FVPHYSICS_PLAYER_HELD) then
				return
			end
		end
		
		vecStart.z = me.m_vecOrigin[ply].z + GetPlayerViewOffset(ply:Crouching()).z + WATERJUMP_HEIGHT
		vecEnd = vecStart + 24.0 * flatforward
		me.m_vecWaterJumpVel[ply] = -50.0 * tr.HitNormal
		
		tr = TracePlayerBBox(vecStart, vecEnd, PlayerSolidMask(), COLLISION_GROUP_PLAYER_MOVEMENT)
		if tr.Fraction == 1.0 then -- open at eye level
			-- Now trace down to see if we would actually land on a standable surface.
			vecStart = Vector(vecEnd)
			vecEnd.z = vecEnd.z - 1024.0
			tr = TracePlayerBBox(vecStart, vecEnd, PlayerSolidMask(), COLLISION_GROUP_PLAYER_MOVEMENT)
			if tr.Fraction < 1.0 and tr.HitNormal.z >= 0.7 then
				me.m_vecVelocity[ply].z = 256.0 -- Push up
				me.m_nOldButtons[ply] = bit.bor(me.m_nOldButtons[ply], IN_JUMP) -- Don't jump again until released
				me.m_nFlags[ply] = bit.bor(me.m_nFlags[ply], FL_WATERJUMP)
				me.m_flWaterJumpTime[ply] = 2000.0 -- Do this for 2 seconds
			end
		end
	end
end

local function CategorizePosition()
	-- Reset this each time we-recategorize, otherwise we have bogus friction when we jump into water and plunge downward really quickly
	me.m_surfaceFriction[ply] = 1.0
	
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
	
	local bumpOrigin = Vector(me.m_vecOrigin[ply])
	local point = Vector(me.m_vecOrigin[ply])
	local flOffset = 2.0
	point.z = point.z - flOffset
	
	-- Shooting up really fast.  Definitely not on ground.
	-- On ladder moving up, so not on ground either
	-- NOTE: 145 is a jump.
	local NON_JUMP_VELOCITY = 65 -- float NON_JUMP_VELOCITY = 140.0f; in gamemovement.cpp
	
	local zvel = me.m_vecVelocity[ply].z
	local bMovingUp = zvel > 0.0
	local bMovingUpRapidly = zvel > NON_JUMP_VELOCITY
	if bMovingUpRapidly and me.m_entGroundEntity[ply] ~= NULL then
		-- Tracker 73219, 75878:  ywb 8/2/07
		-- After save/restore (and maybe at other times), we can get a case where we were saved on a lift and 
		--  after restore we'll have a high local velocity due to the lift making our abs velocity appear high.  
		-- We need to account for standing on a moving ground object in that case in order to determine if we really 
		--  are moving away from the object we are standing on at too rapid a speed.  Note that CheckJump already sets
		--  ground entity to NULL, so this wouldn't have any effect unless we are moving up rapidly not from the jump button.
		local flGroundEntityVelZ = me.m_entGroundEntity[ply]:GetAbsVelocity().z
		bMovingUpRapidly = zvel - flGroundEntityVelZ > NON_JUMP_VELOCITY
	end
	
	-- Was on ground, but now suddenly am not
	if bMovingUpRapidly or bMovingUp and me.m_nMoveType[ply] == MOVETYPE_LADDER then
		SetGroundEntity(nil)
	else -- Try and move down.
		local pm = TryTouchGround(bumpOrigin, point, GetPlayerMins(), GetPlayerMaxs(), ss.SquidSolidMask, COLLISION_GROUP_PLAYER_MOVEMENT)
		
		-- Was on ground, but now suddenly am not.  If we hit a steep plane, we are not on ground
		if pm.Entity == NULL or pm.HitNormal.z < 0.7 then
			-- Test four sub-boxes, to see if any of them would have found shallower slope we could actually stand on
			pm = TryTouchGroundInQuadrants(bumpOrigin, point, ss.SquidSolidMask, COLLISION_GROUP_PLAYER_MOVEMENT, pm)

			if pm.Entity == NULL or pm.HitNormal.z < 0.7 then
				SetGroundEntity(nil)
				-- probably want to add a check for a +z velocity too!
				if me.m_vecVelocity[ply].z > 0.0 and me.m_nMoveType[ply] ~= MOVETYPE_NOCLIP then
					me.m_surfaceFriction[ply] = 0.25
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
				if me.m_entGroundEntity[ply] == NULL then
					-- cCurrGameMaterial = 0
				end
				
				-- Changed?
				if me.m_chPreviousTextureType[ply] ~= cCurrGameMaterial then
					-- CEnvPlayerSurfaceTrigger:SetPlayerSurface(ply, cCurrGameMaterial)
				end

				me.m_chPreviousTextureType[ply] = cCurrGameMaterial
			end
		end
	end
end

local function WaterJump()
	if me.m_flWaterJumpTime[ply] > 10000 then
		me.m_flWaterJumpTime[ply] = 10000
	end
	
	if me.m_flWaterJumpTime[ply] == 0 then
		return
	end
	
	me.m_flWaterJumpTime[ply] = me.m_flWaterJumpTime[ply] - 1000.0 * FT()
	
	if me.m_flWaterJumpTime[ply] <= 0 or me.m_nWaterLevel[ply] == 0 then
		me.m_flWaterJumpTime[ply] = 0
		me.m_nFlags[ply] = bit.band(me.m_nFlags[ply], bit.bnot(FL_WATERJUMP))
	end
	
	me.m_vecVelocity[ply].x = me.m_vecWaterJumpVel[ply].x
	me.m_vecVelocity[ply].y = me.m_vecWaterJumpVel[ply].y
end

local function Friction()
	-- If we are in water jump cycle, don't apply friction
	if me.m_flWaterJumpTime[ply] ~= 0 then return end
	
	local speed = me.m_vecVelocity[ply]:Length() -- Calculate speed
	if speed < 0.1 then return end -- If too slow, return
	
	local drop = 0 -- apply ground friction
	if me.m_entGroundEntity[ply] ~= NULL then -- On an entity that is the ground
		local friction = GetConVar "sv_friction":GetFloat() * me.m_surfaceFriction[ply]
		
		-- Bleed off some speed, but if we have less than the bleed
		--  threshold, bleed the threshold amount.
		local control = math.max(speed, GetConVar "sv_stopspeed":GetFloat())
		
		-- Add the amount to the drop amount.
		drop = drop + control * friction * FT()
	end
	
	-- scale the velocity
	local newspeed = math.max(0, speed - drop)
	if newspeed ~= speed then
		-- Determine proportion of old speed we are using.
		newspeed = newspeed / speed
		-- Adjust velocity according to proportion.
		me.m_vecVelocity[ply]:Mul(newspeed)
	end
	
 	me.m_outWishVel[ply]:Sub((1 - newspeed) * me.m_vecVelocity[ply])
end

local function Accelerate(wishdir, wishspeed, accel)
	-- This gets overridden because some games (CSPort) want to allow dead (observer) players
	-- to be able to move around.
	if not CanAccelerate() then return end
	
	-- See if we are changing direction a bit
	local currentspeed = me.m_vecVelocity[ply]:Dot(wishdir)
	
	-- Reduce wishspeed by the amount of veer.
	local addspeed = wishspeed - currentspeed
	
	-- If not going to add any speed, done.
	if addspeed <= 0 then return end
	
	-- Determine amount of accleration.
	-- Cap at addspeed
	local accelspeed = math.min(addspeed, accel * FT() * wishspeed * me.m_surfaceFriction[ply])
	
	-- Adjust velocity.
	me.m_vecVelocity[ply]:Add(accelspeed * wishdir)
end

local function AirAccelerate(wishdir, wishspeed, accel)
	if IsDead() then return end
	if me.m_flWaterJumpTime[ply] ~= 0 then return end
	local ws = math.min(wishspeed, GetAirSpeedCap()) -- Cap speed
	
	-- Determine veer amount
	local currentspeed = me.m_vecVelocity[ply]:Dot(wishdir)
	
	-- See how much to add
	local addspeed = ws - currentspeed
	
	-- If not adding any, done.
	if addspeed <= 0 then return end
	
	-- Determine acceleration speed after acceleration
	-- Cap it
	local accelspeed = math.min(addspeed,
	accel * wishspeed * FT() * me.m_surfaceFriction[ply])
	
	-- Adjust pmove vel.
	me.m_vecVelocity[ply]:Add(accelspeed * wishdir)
	me.m_outWishVel[ply]:Add(accelspeed * wishdir)
end

local function TryPlayerMove(pFirstDest, pFirstTrace)
	local numbumps = 4 -- Bump up to four times
	local dir = Vector()
	local d = 0.0
	local numplanes = 0 -- and not sliding along any planes
	local planes = {} -- MAX_CLIP_PLANES
	local primal_velocity, original_velocity = Vector(me.m_vecVelocity[ply]), Vector(me.m_vecVelocity[ply]) -- Store original velocity
	local new_velocity = Vector()
	local a, b = 0, 0
	local pm -- TraceResult
	local endpos = Vector()
	local time_left, allFraction = FT(), 0 -- Total time for this movement operation.
	local blocked = 0 -- Assume not blocked
	for bumpcount = 1, numbumps do
		if me.m_vecVelocity[ply]:LengthSqr() == 0.0 then break end
		
		-- Assume we can move all the way from the current origin to the end point.
		endpos = me.m_vecOrigin[ply] + time_left * me.m_vecVelocity[ply]
		
		-- See if we can make it from origin to end point.
		if g_bMovementOptimizations then
			-- If their velocity Z is 0, then we can avoid an extra trace here during WalkMove.
			if pFirstDest and endpos == pFirstDest then
				pm = pFirstTrace
			else
				pm = TracePlayerBBox(me.m_vecOrigin[ply], endpos, PlayerSolidMask(), COLLISION_GROUP_PLAYER_MOVEMENT)
			end
		else
			pm = TracePlayerBBox(me.m_vecOrigin[ply], endpos, PlayerSolidMask(), COLLISION_GROUP_PLAYER_MOVEMENT)
		end
		
		allFraction = allFraction + pm.Fraction
		
		-- If we started in a solid object, or we were in solid space
		--  the whole way, zero out our velocity and return that we
		--  are blocked by floor and wall.
		if pm.AllSolid then
			-- entity is trapped in another solid
			me.m_vecVelocity[ply]:Zero()
			return 4
		end
		
		-- If we moved some portion of the total distance, then
		--  copy the end position into the pmove.origin and 
		--  zero the plane counter.
		if pm.Fraction > 0 then
			if pm.Fraction == 1 then -- and numplanes > 1
				-- There's a precision issue with terrain tracing that can cause a swept box to successfully trace
				--  when the end position is stuck in the triangle.  Re-run the test with an uswept box to catch that
				--  case until the bug is fixed.
				-- If we detect getting stuck, don't allow the movement
				local stuck = TracePlayerBBox(pm.HitPos, pm.HitPos, PlayerSolidMask(), COLLISION_GROUP_PLAYER_MOVEMENT)
				if stuck.StartSolid or stuck.Fraction ~= 1.0 then
					-- Msg "Player will become stuck!!!\n"
					me.m_vecVelocity[ply]:Zero()
					break
				end
			end
			
			-- actually covered some distance
			me.m_vecOrigin[ply]:Set(pm.HitPos)
			original_velocity:Set(me.m_vecVelocity[ply])
			numplanes = 0
		end
		
		-- If we covered the entire distance, we are done
		--  and can return.
		if pm.Fraction == 1 then break end -- moved the entire distance
		
		-- Save entity that blocked us (since fraction was < 1.0)
		--  for contact
		-- Add it if it's not already in the list!!!
		-- MoveHelper():AddToTouched(pm, me.m_vecVelocity[ply])
		
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
			me.m_vecVelocity[ply]:Zero()
			-- print "Too many planes 4"
			
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
		if numplanes == 1 and me.m_nMoveType[ply] == MOVETYPE_WALK and me.m_entGroundEntity[ply] == NULL then
			for i = 1, numplanes do
				if planes[i].z > 0.7 then
					-- floor or slope
					ClipVelocity(original_velocity, planes[i], new_velocity, 1)
					original_velocity:Set(new_velocity)
				else
					ClipVelocity(original_velocity, planes[i], new_velocity, 1.0
					+ GetConVar "sv_bounce":GetFloat() * (1 - me.m_surfaceFriction[ply]))
				end
			end
			
			me.m_vecVelocity[ply]:Set(new_velocity)
			original_velocity:Set(new_velocity)
		else
			for i = 1, numplanes do
				a = i
				ClipVelocity(original_velocity, planes[a], me.m_vecVelocity[ply], 1)
				for j = 1, numplanes do
					b = j
					if j ~= i then
						-- Are we now moving against this plane?
						if me.m_vecVelocity[ply]:Dot(planes[j]) < 0 then
							break -- not ok
						end
					elseif j == numplanes then
						b = numplanes + 1
						break
					end
				end
				
				if b == numplanes + 1 then -- Didn't have to clip, so we're ok
					break
				elseif i == numplanes then
					a = numplanes + 1
				end
			end
			
			-- Did we go all the way through plane set
			if a <= numplanes then
				-- go along this plane
				-- pmove.velocity is set in clipping call, no need to set again. 
			else -- go along the crease
				if numplanes ~= 2 then
					me.m_vecVelocity[ply]:Zero()
					break
				end
				
				dir = planes[1]:Cross(planes[2])
				dir:Normalize()
				d = dir:Dot(me.m_vecVelocity[ply])
				me.m_vecVelocity[ply] = dir * d
			end
			
			--
			-- if original velocity is against the original velocity, stop dead
			-- to avoid tiny occilations in sloping corners
			--
			d = me.m_vecVelocity[ply]:Dot(primal_velocity)
			if d <= 0 then
				-- print "Back"
				me.m_vecVelocity[ply]:Zero()
				break
			end
		end
	end
	
	if allFraction == 0 then
		me.m_vecVelocity[ply]:Zero()
	end

	-- Check if they slammed into a wall
	local fSlamVol = 0.0
	
	local fLateralStoppingAmount = primal_velocity:Length2D() - me.m_vecVelocity[ply]:Length2D()
	if fLateralStoppingAmount > PLAYER_MAX_SAFE_FALL_SPEED * 2.0 then
		fSlamVol = 1.0
	elseif fLateralStoppingAmount > PLAYER_MAX_SAFE_FALL_SPEED then
		fSlamVol = 0.85
	end
	
	PlayerRoughLandingEffects(fSlamVol)
	
	return blocked
end

local function StayOnGround()
	local start, endpos = Vector(me.m_vecOrigin[ply]), Vector(me.m_vecOrigin[ply])
	start.z, endpos.z = start.z + 2, endpos.z - ply:GetStepSize()
	
	-- See how far up we can go without getting stuck
	local trace = TracePlayerBBox(me.m_vecOrigin[ply], start, PlayerSolidMask(), COLLISION_GROUP_PLAYER_MOVEMENT)
	start = trace.HitPos
	
	-- using trace.StartSolid is unreliable here, it doesn't get set when
	-- tracing bounding box vs. terrain
	
	-- Now trace down from a known safe position
	trace = TracePlayerBBox(start, endpos, PlayerSolidMask(), COLLISION_GROUP_PLAYER_MOVEMENT)
	if trace.Fraction > 0.0 and	 -- must go somewhere
		trace.Fraction < 1.0 and -- must hit something
		not trace.StartSolid and -- can't be embedded in a solid
		trace.HitNormal.z >= 0.7 then -- can't hit a steep slope that we can't stand on anyway
		local flDelta = math.abs(me.m_vecOrigin[ply].z - trace.HitPos.z)
		
		-- This is incredibly hacky. The real problem is that trace returning that strange value we can't network over.
		if flDelta > 0.5 * COORD_RESOLUTION then
			me.m_vecOrigin[ply]:Set(trace.HitPos)
		end
	end
end

local function StepMove(vecDestination, trace)
	local vecEndPos = Vector(vecDestination)
	
	-- Try sliding forward both on ground and up 16 pixels
	--  take the move that goes farthest
	local vecPos, vecVel = Vector(me.m_vecOrigin[ply]), Vector(me.m_vecVelocity[ply])
	
	-- Slide move down.
	TryPlayerMove(vecEndPos, trace)
	
	-- Down results.
	local vecDownPos, vecDownVel = Vector(me.m_vecOrigin[ply]), Vector(me.m_vecVelocity[ply])
	
	-- Reset original values.
	me.m_vecOrigin[ply]:Set(vecPos)
	me.m_vecVelocity[ply]:Set(vecVel)
	
	-- Move up a stair height.
	vecEndPos:Set(me.m_vecOrigin[ply])
	if me.m_bAllowAutoMovement[ply] then
		vecEndPos.z = vecEndPos.z + ply:GetStepSize() + DIST_EPSILON
	end
	
	trace = TracePlayerBBox(me.m_vecOrigin[ply], vecEndPos, PlayerSolidMask(), COLLISION_GROUP_PLAYER_MOVEMENT)
	if not (trace.StartSolid or trace.AllSolid) then
		me.m_vecOrigin[ply]:Set(trace.HitPos)
	end
	
	-- Slide move up.
	TryPlayerMove()
	
	-- Move down a stair (attempt to).
	vecEndPos:Set(me.m_vecOrigin[ply])
	if me.m_bAllowAutoMovement[ply] then
		vecEndPos.z = vecEndPos.z - ply:GetStepSize() - DIST_EPSILON
	end
		
	trace = TracePlayerBBox(me.m_vecOrigin[ply], vecEndPos, PlayerSolidMask(), COLLISION_GROUP_PLAYER_MOVEMENT)
	
	-- If we are not on the ground any more then use the original movement attempt.
	if trace.HitNormal.z < 0.7 then
		me.m_vecOrigin[ply]:Set(vecDownPos)
		me.m_vecVelocity[ply]:Set(vecDownVel)
		local flStepDist = me.m_vecOrigin[ply].z - vecPos.z
		if flStepDist > 0.0 then
			me.m_outStepHeight[ply] = me.m_outStepHeight[ply] + flStepDist
		end
		return
	end
	
	-- If the trace ended up in empty space, copy the end over to the origin.
	if not (trace.StartSolid or trace.AllSolid) then
		me.m_vecOrigin[ply]:Set(trace.HitPos)
	end
	
	-- Copy this origin to up.
	local vecUpPos = Vector(me.m_vecOrigin[ply])
	
	-- decide which one went farther
	local flDownDist
		= (vecDownPos.x - vecPos.x) * (vecDownPos.x - vecPos.x)
		+ (vecDownPos.y - vecPos.y) * (vecDownPos.y - vecPos.y)
	local flUpDist
		= (vecUpPos.x - vecPos.x) * (vecUpPos.x - vecPos.x)
		+ (vecUpPos.y - vecPos.y) * (vecUpPos.y - vecPos.y)
	if flDownDist > flUpDist then
		me.m_vecOrigin[ply]:Set(vecDownPos)
		me.m_vecVelocity[ply]:Set(vecDownVel)
	else 
		-- copy z value from slide move
		me.m_vecVelocity[ply].z = vecDownVel.z
	end
	
	local flStepDist = me.m_vecOrigin[ply].z - vecPos.z
	if flStepDist > 0 then
		me.m_outStepHeight[ply] = me.m_outStepHeight[ply] + flStepDist
	end
end

local function AirMove()
	local fmove, smove = me.m_flForwardMove[ply], me.m_flSideMove[ply] -- Copy movement amounts
	local forward, right, up = me.m_vecForward[ply], me.m_vecRight[ply], me.m_vecUp[ply] -- Determine movement angles
	
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
	if wishspeed ~= 0.0 and wishspeed > me.m_flMaxSpeed[ply] then
		wishvel = wishvel * me.m_flMaxSpeed[ply] / wishspeed
		wishspeed = me.m_flMaxSpeed[ply]
	end
	
	AirAccelerate(wishdir, wishspeed, GetConVar "sv_airaccelerate":GetFloat())
	
	-- Add in any base velocity to the current velocity.
	me.m_vecVelocity[ply]:Add(me.m_vecBaseVelocity[ply])
	
	TryPlayerMove()
	
	-- Now pull the base velocity back out.   Base velocity is set if you are on a moving object, like a conveyor (or maybe another monster?)
	me.m_vecVelocity[ply]:Sub(me.m_vecBaseVelocity[ply])
end

local function WalkMove()
	local fmove, smove = me.m_flForwardMove[ply], me.m_flSideMove[ply] -- Copy movement amounts
	local forward, right, up = me.m_vecForward[ply], me.m_vecRight[ply], me.m_vecUp[ply] -- Determine movement angles
	local oldground = me.m_entGroundEntity[ply]
	
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
	if wishspeed ~= 0.0 and wishspeed > me.m_flMaxSpeed[ply] then
		wishvel:Mul(me.m_flMaxSpeed[ply] / wishspeed)
		wishspeed = me.m_flMaxSpeed[ply]
	end
	
	-- Set pmove velocity
	me.m_vecVelocity[ply].z = 0
	Accelerate(wishdir, wishspeed, GetConVar "sv_accelerate":GetFloat())
	me.m_vecVelocity[ply].z = 0
	
	-- Add in any base velocity to the current velocity.
	me.m_vecVelocity[ply]:Add(me.m_vecBaseVelocity[ply])
	
	local spd = me.m_vecVelocity[ply]:Length()
	if spd < 1.0 then
		me.m_vecVelocity[ply]:Zero()
		-- Now pull the base velocity back out.  Base velocity is set if you are on a moving object, like a conveyor (or maybe another monster?)
		me.m_vecVelocity[ply]:Sub(me.m_vecBaseVelocity[ply])
		return
	end
	
	-- first try just moving to the destination	
	local dest = me.m_vecOrigin[ply] + me.m_vecVelocity[ply] * FT()
	dest.z = me.m_vecOrigin[ply].z
	
	-- first try moving directly to the next spot
	local pm = TracePlayerBBox(me.m_vecOrigin[ply], dest, PlayerSolidMask(), COLLISION_GROUP_PLAYER_MOVEMENT)
	
	-- If we made it all the way, then copy trace end as new player position.
	me.m_outWishVel[ply]:Add(wishdir * wishspeed)
	
	if pm.Fraction == 1 then
		me.m_vecOrigin[ply] = pm.HitPos
		-- Now pull the base velocity back out.   Base velocity is set if you are on a moving object, like a conveyor (or maybe another monster?)
		me.m_vecVelocity[ply]:Sub(me.m_vecBaseVelocity[ply])
		
		StayOnGround()
		return
	end
	
	-- Don't walk up stairs if not on ground.
	if oldground == NULL and me.m_nWaterLevel[ply] == 0 then
		-- Now pull the base velocity back out.   Base velocity is set if you are on a moving object, like a conveyor (or maybe another monster?)
		me.m_vecVelocity[ply]:Sub(me.m_vecBaseVelocity[ply])
		return
	end
	
	-- If we are jumping out of water, don't do anything more.
	if me.m_flWaterJumpTime[ply] ~= 0 then
		-- Now pull the base velocity back out.   Base velocity is set if you are on a moving object, like a conveyor (or maybe another monster?)
		me.m_vecVelocity[ply]:Sub(me.m_vecBaseVelocity[ply])
		return
	end
	
	StepMove(dest, pm)
	
	-- Now pull the base velocity back out.   Base velocity is set if you are on a moving object, like a conveyor (or maybe another monster?)
	me.m_vecVelocity[ply]:Sub(me.m_vecBaseVelocity[ply])
	
	StayOnGround()
end

local function WaterMove()
	--
	-- user intentions
	-- Determine movement angles
	local forward, right, up = me.m_vecForward[ply], me.m_vecRight[ply], me.m_vecUp[ply]
	local wishvel = forward * me.m_flForwardMove[ply] + right * me.m_flSideMove[ply]
	
	-- if we have the jump key down, move us up as well
	if bit.band(me.m_nButtons[ply], IN_JUMP) ~= 0 then
		wishvel.z = wishvel.z + me.m_flClientMaxSpeed[ply]
	-- Sinking after no other movement occurs
	elseif me.m_flForwardMove[ply] == 0 and me.m_flSideMove[ply] == 0 and me.m_flUpMove[ply] == 0 then
		wishvel.z = wishvel.z - 60 -- drift towards bottom
	else -- Go straight up by upmove amount.
		-- exaggerate upward movement along forward as well
		local upwardMovememnt = me.m_flForwardMove[ply] * forward.z * 2
		upwardMovememnt = math.Clamp(upwardMovememnt, 0.0, me.m_flClientMaxSpeed[ply])
		wishvel.z = wishvel.z + me.m_flUpMove[ply] + upwardMovememnt
	end
	
	-- Copy it over and determine speed
	local wishdir = Vector(wishvel)
	local wishspeed = wishdir:Length()
	wishdir:Normalize()
	
	-- Cap speed.
	if wishspeed > me.m_flMaxSpeed[ply] then
		wishvel = wishvel * me.m_flMaxSpeed[ply] / wishspeed
		wishspeed = me.m_flMaxSpeed[ply]
	end
	
	wishspeed = wishspeed * 0.8 -- Slow us down a bit.
	
	-- Water friction
	local temp = Vector(me.m_vecVelocity[ply])
	local speed, newspeed = temp:Length()
	temp:Normalize()
	if speed ~= 0 then
		newspeed = speed - FT() * speed * GetConVar "sv_friction":GetFloat() * me.m_surfaceFriction[ply]
		if newspeed < 0.1 then
			newspeed = 0
		end
		
		me.m_vecVelocity[ply]:Mul(newspeed / speed)
	else
		newspeed = 0
	end
	
	-- water acceleration
	if wishspeed >= 0.1 then -- old !
		local addspeed = wishspeed - newspeed
		if addspeed > 0 then
			wishvel:Normalize()
			local accelspeed = math.min(addspeed,
			GetConVar "sv_accelerate":GetFloat() * wishspeed * FT() * me.m_surfaceFriction[ply])
			
			me.m_vecVelocity[ply]:Add(accelspeed * wishvel)
			me.m_outWishVel[ply]:Add(accelspeed * wishvel)
		end
	end
	
	me.m_vecVelocity[ply]:Add(me.m_vecBaseVelocity[ply])
	
	-- Now move
	-- assume it is a stair or a slope, so press down from stepheight above
	local dest = me.m_vecOrigin[ply] + FT() * me.m_vecVelocity[ply]
	local pm = TracePlayerBBox(me.m_vecOrigin[ply], dest, PlayerSolidMask(), COLLISION_GROUP_PLAYER_MOVEMENT)
	if pm.Fraction == 1.0 then
		local start = Vector(dest)
		if me.m_bAllowAutoMovement[ply] then
			start.z = start.z + ply:GetStepSize() + 1
		end
		
		pm = TracePlayerBBox(start, dest, PlayerSolidMask(), COLLISION_GROUP_PLAYER_MOVEMENT)
		
		if not (pm.StartSolid or pm.AllSolid) then
			local stepDist = pm.HitPos.z - me.m_vecOrigin[ply].z
			me.m_outStepHeight[ply] = me.m_outStepHeight[ply] + stepDist
			-- walked up the step, so just keep result and exit
			me.m_vecOrigin[ply]:Set(pm.HitPos)
			me.m_vecVelocity[ply]:Sub(me.m_vecBaseVelocity[ply])
			return
		end
		
		-- Try moving straight along out normal path.
		TryPlayerMove()
	else
		if me.m_entGroundEntity[ply] == NULL then
			TryPlayerMove()
			me.m_vecVelocity[ply]:Sub(me.m_vecBaseVelocity[ply])
			return
		end
		
		StepMove(dest, pm)
	end
	
	me.m_vecVelocity[ply]:Sub(me.m_vecBaseVelocity[ply])
end

local function FullWalkMove()
	if not CheckWater() then
		StartGravity()
	end

	-- If we are leaping out of the water, just update the counters.
	if me.m_flWaterJumpTime[ply] ~= 0 then
		WaterJump()
		TryPlayerMove()
		CheckWater() -- See if we are still in water?
		return
	end
	
	-- If we are swimming in the water, see if we are nudging against a place we can jump up out
	--  of, and, if so, start out jump.  Otherwise, if we are not moving up, then reset jump timer to 0
	if me.m_nWaterLevel[ply] >= WL_Waist then
		if me.m_nWaterLevel[ply] == WL_Waist then
			CheckWaterJump()
		end

		-- If we are falling again, then we must not trying to jump out of water any more.
		if me.m_vecVelocity[ply].z < 0 and me.m_flWaterJumpTime[ply] ~= 0 then
			me.m_flWaterJumpTime[ply] = 0
		end

		-- Was jump button pressed?
		if bit.band(me.m_nButtons[ply], IN_JUMP) ~= 0 then
			CheckJumpButton()
		else
			me.m_nOldButtons[ply] = bit.band(me.m_nOldButtons[ply], bit.bnot(IN_JUMP))
		end

		-- Perform regular water movement
		WaterMove()
		
		-- Redetermine position vars
		CategorizePosition()
		
		-- If we are on ground, no downward velocity.
		if me.m_entGroundEntity[ply] ~= NULL then
			me.m_vecVelocity[ply].z = 0
		end
	else -- Not fully underwater
		-- Was jump button pressed?
		if bit.band(me.m_nButtons[ply], IN_JUMP) ~= 0 then
 			CheckJumpButton()
		else
			me.m_nOldButtons[ply] = bit.band(me.m_nOldButtons[ply], bit.bnot(IN_JUMP))
		end
		
		-- Fricion is handled before we add in any base velocity. That way, if we are on a conveyor, 
		--  we don't slow when standing still, relative to the conveyor.
		if me.m_entGroundEntity[ply] ~= NULL then
			me.m_vecVelocity[ply].z = 0
			Friction()
		end
		
		-- Make sure velocity is valid.
		CheckVelocity()
		
		if me.m_entGroundEntity[ply] ~= NULL then
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
		if me.m_entGroundEntity[ply] ~= NULL then
			me.m_vecVelocity[ply].z = 0
		end
		CheckFalling()
	end
	
	if me.m_nOldWaterLevel[ply] == WL_NotInWater and me.m_nWaterLevel[ply] ~= WL_NotInWater or
		me.m_nOldWaterLevel[ply] ~= WL_NotInWater and me.m_nWaterLevel[ply] == WL_NotInWater then
		PlaySwimSound()
		PlayerSplash() -- if not CLIENT then in original source
	end
end

local function SquidMove()
	CheckParameters()
	
	-- clear output applied velocity
	me.m_outWishVel[ply]:Zero()
	me.m_outJumpVel[ply]:Zero()

	-- MoveHelper()->ResetTouchList() -- Assume we don't touch anything

	ReduceTimers()

	-- Determine movement angles
	me.m_vecForward[ply] = me.m_vecAngles[ply]:Forward()
	me.m_vecRight[ply] = me.m_vecAngles[ply]:Right()
	me.m_vecUp[ply] = me.m_vecAngles[ply]:Up()

	-- Always try and unstick us unless we are using a couple of the movement modes
	if me.m_nMoveType[ply] ~= MOVETYPE_NOCLIP and me.m_nMoveType[ply] ~= MOVETYPE_NONE and me.m_nMoveType[ply] ~= MOVETYPE_ISOMETRIC
		and me.m_nMoveType[ply] ~= MOVETYPE_OBSERVER and not IsDead() then
		-- if CheckInterval(STUCK) then -- Always return true if g_bMovementOptimizations is false
			-- if CheckStuck() then
				-- return -- Can't move, we're stuck
			-- end
		-- end
	end

	-- Now that we are "unstuck", see where we are (ply:WaterLevel() and type, ply:GetGroundEntity()).
	if me.m_nMoveType[ply] ~= MOVETYPE_WALK or me.m_bGameCodeMovedPlayer[ply] or
		not GetConVar "sv_optimizedmovement":GetBool() then
		CategorizePosition()
	elseif me.m_vecVelocity[ply].z > 250.0 then
		SetGroundEntity(nil)
	end

	-- Store off the starting water level
	me.m_nOldWaterLevel[ply] = me.m_nWaterLevel[ply]

	-- If we are not on ground, store off how fast we are moving down
	if me.m_entGroundEntity[ply] == NULL then
		me.m_flFallVelocity[ply] = -me.m_vecVelocity[ply].z
	end

	me.m_nOnLadder[ply] = 0

	-- ply:UpdateStepSound(me.m_pSurfaceData[ply], me.m_vecOrigin[ply], me.m_vecVelocity[ply])

	-- UpdateDuckJumpEyeOffset()
	-- Duck()

	-- Don't run ladder code if dead on on a train
	if not IsDead() or bit.band(me.m_nFlags[ply], FL_ONTRAIN) == 0 then
		-- If was not on a ladder now, but was on one before, 
		--  get off of the ladder
		
		-- TODO: this causes lots of weirdness.
		-- local bCheckLadder = CheckInterval(LADDER)
		-- if bCheckLadder or me.m_nMoveType[ply] == MOVETYPE_LADDER then
			-- if not LadderMove() and me.m_nMoveType[ply] == MOVETYPE_LADDER then
				-- Clear ladder stuff unless player is dead or riding a train
				-- It will be reset immediately again next frame if necessary
				-- me.m_nMoveType[ply] = MOVETYPE_WALK
				-- ply:SetMoveCollide(MOVECOLLIDE_DEFAULT)
			-- end
		-- end
	end
	
	FullWalkMove()
end

local function CheckFenceStand(pos, endpos, ignorenormals)
	local t = { -- Check strictly if player stands on fence.
		start = pos, endpos = endpos,
		mins = GetPlayerMins(), maxs = GetPlayerMaxs(),
		mask = ss.MASK_GRATE, collisiongroup = COLLISION_GROUP_PLAYER_MOVEMENT,
		filter = ply,
	}
	
	local tr = util.TraceHull(t)
	t.mask = ss.SquidSolidMask
	local trsolid = util.TraceHull(t)
	if ignorenormals then tr.HitNormal.z, trsolid.HitNormal.z = 1, 1 end
	
	local b = tr.Entity == NULL or tr.HitNormal.z < .7
	if b ~= (trsolid.Entity == NULL or trsolid.HitNormal.z < .7) then return not b, tr.StartSolid end
	if b then
		tr = TryTouchGroundInQuadrants(pos, t.endpos, ss.MASK_GRATE, COLLISION_GROUP_PLAYER_MOVEMENT, tr)
		trsolid = TryTouchGroundInQuadrants(pos, t.endpos, ss.SquidSolidMask, COLLISION_GROUP_PLAYER_MOVEMENT, trsolid)
		if ignorenormals then tr.HitNormal.z, trsolid.HitNormal.z = 1, 1 end
		if not (tr.Entity == NULL or tr.HitNormal.z < .7) and
			(trsolid.Entity == NULL or trsolid.HitNormal.z < .7) then
			return true, tr.StartSolid
		end
	end
end

local function GetInFence(w, oldpos, newpos)
	if not ply:Crouching() then return false end
	local t = {
		start = oldpos, endpos = newpos or oldpos,
		mins = GetPlayerMins(), maxs = GetPlayerMaxs(),
		mask = ss.MASK_GRATE, collisiongroup = COLLISION_GROUP_PLAYER_MOVEMENT,
		filter = ply,
	}
	
	local tr = util.TraceHull(t)
	t.mask = ss.SquidSolidMask -- Check if player is stuck in fence
	return tr.Entity ~= NULL and util.TraceHull(t).Entity == NULL
end

local AttackMask = bit.bnot(IN_ATTACK)
local DuckMask = bit.bnot(IN_DUCK)
function ss.MoveHook(w, p, m)
	ply, mv = p, m
	ss.ProtectedCall(w.Move, w, p, m)
	w.EnemyInkPreventCrouching = w.EnemyInkPreventCrouching and w:GetOnEnemyInk() and ply:KeyDown(IN_DUCK)
	w.PreventCrouching = w:GetKey() ~= 0 and w:GetKey() ~= IN_DUCK or CurTime() < w:GetCooldown()
	if w.PreventCrouching or w.EnemyInkPreventCrouching then
		mv:SetButtons(bit.band(mv:GetButtons(), DuckMask))
	end
	
	local maxspeed = math.min(mv:GetMaxSpeed(), w.InklingSpeed * 1.1)
	if ply:OnGround() then -- Max speed clip
		maxspeed = ss.ProtectedCall(w.CustomMoveSpeed, w) or w.InklingSpeed
		maxspeed = maxspeed * Either(ply:Crouching(), ss.SquidSpeedOutofInk, 1)
		maxspeed = w:GetInInk() and w.SquidSpeed or maxspeed
		maxspeed = w:GetOnEnemyInk() and w.OnEnemyInkSpeed or maxspeed
		maxspeed = maxspeed * (w.IsDisruptored and ss.DisruptoredSpeed or 1)
		mv:SetMaxSpeed(maxspeed)
		mv:SetMaxClientSpeed(maxspeed)
		ply:SetMaxSpeed(maxspeed)
		ply:SetRunSpeed(maxspeed)
		ply:SetWalkSpeed(maxspeed)
	end
	
	ply:SetJumpPower(w:GetOnEnemyInk() and w.OnEnemyInkJumpPower or w.JumpPower)
	if CLIENT then w:UpdateInkState() end -- Ink state prediction
	
	for v, i in pairs {
		[mv:GetVelocity()] = true, -- Current velocity
		[me.m_vecVelocity[ply]] = false,
	} do -- Wall climbing
		local speed, vz = v:Length2D(), v.z -- Horizontal speed, Z component
		if w:GetInWallInk() and mv:KeyDown(WALLCLIMB_KEYS) then
			vz = math.max(math.abs(vz) * -.75, vz + math.min(
			12 + (mv:KeyPressed(IN_JUMP) and maxspeed / 4 or 0), maxspeed))
			if ply:OnGround() then
				local t = {
					start = ply:GetShootPos(), endpos = ply:GetShootPos() + ply:GetAimVector() * 32768,
					mask = ss.SquidSolidMask, collisiongroup = COLLISION_GROUP_PLAYER_MOVEMENT, filter = ply,
				}
				local fw = util.TraceLine(t)
				t.endpos = ply:GetShootPos() - ply:GetAimVector() * 32768
				local bk = util.TraceLine(t)
				t.endpos = ply:GetShootPos() + ply:GetRight() * 32768
				local right = util.TraceLine(t)
				t.endpos = ply:GetShootPos() - ply:GetRight() * 32768
				local left = util.TraceLine(t)
				if math.min(fw.Fraction, bk.Fraction) < math.min(right.Fraction, left.Fraction)
				and fw.Fraction < bk.Fraction == mv:KeyDown(IN_FORWARD) then
					mv:AddKey(IN_JUMP)
				end
			end
		end
		
		if speed > maxspeed then -- Limits horizontal speed
			v:Mul(maxspeed / speed)
			speed = math.min(speed, maxspeed)
		end
		
		v.z = w.OnOutofInk and not w:GetInWallInk()
		and math.min(vz, ply:GetJumpPower() * .7) or vz
		if i then mv:SetVelocity(v) end
	end
	
	-- Send viewmodel animation.
	local infence = Either(SERVER, w:GetInFence(), me.m_bInFence[ply])
	if ply:Crouching() then
		w.SwimSound:ChangeVolume(math.Clamp(mv:GetVelocity():Length() / w.SquidSpeed * (w:GetInInk() and 1 or 0), 0, 1))
		if not w:GetOldCrouching() then
			ply:RemoveAllDecals()
			w:EmitSound "SplatoonSWEPs_Player.ToSquid"
			w:SendWeaponAnim(ss.ViewModel.Squid)
		end
		
		if w:GetOnEnemyInk() then
			w:AddSchedule(20 * ss.FrameToSec, 1, function(self, schedule)
				self.EnemyInkPreventCrouching = self:GetOnEnemyInk()
			end)
		end
	elseif infence then -- Cannot stand while in fence
		mv:AddKey(IN_DUCK) -- it's not correct behavior though
	elseif not ply:Crouching() and w:GetOldCrouching() then
		w.SwimSound:ChangeVolume(0)
		w:EmitSound "SplatoonSWEPs_Player.ToHuman"
		w:SendWeaponAnim(w:GetThrowing() and ss.ViewModel.Throwing or ss.ViewModel.Standing)
	end
	
	w.OnOutofInk = w:GetInWallInk()
	w:SetOldCrouching(ply:Crouching())
	me.m_angViewPunchAngles[ply] = ply:GetViewPunchAngles()
	me.m_bAllowAutoMovement[ply] = true
	me.m_bInDuckJump[ply] = ply:Crouching() and not ply:OnGround()
	me.m_entGroundEntity[ply] = ply:GetGroundEntity()
	me.m_flClientMaxSpeed[ply] = mv:GetMaxClientSpeed()
	me.m_flConstraintRadius[ply] = mv:GetConstraintRadius()
	me.m_flForwardMove[ply] = mv:GetForwardSpeed()
	me.m_flMaxSpeed[ply] = mv:GetMaxSpeed()
	me.m_flSideMove[ply] = mv:GetSideSpeed()
	me.m_flUpMove[ply] = mv:GetUpSpeed()
	me.m_nButtons[ply] = mv:GetButtons()
	me.m_nEmitSound[ply] = nil
	me.m_nFlags[ply] = ply:GetFlags()
	me.m_nMoveType[ply] = MOVETYPE_WALK
	me.m_nOldButtons[ply] = mv:GetOldButtons()
	me.m_nSetAnimation[ply] = nil
	me.m_nSplashData[ply] = nil
	me.m_nWaterLevel[ply] = ply:WaterLevel()
	me.m_vecAngles[ply] = mv:GetAngles()
	me.m_vecBaseVelocity[ply] = ply:GetBaseVelocity()
	me.m_vecOldAngles[ply] = mv:GetOldAngles()
	me.m_vecOrigin[ply] = mv:GetOrigin()
	me.m_vecVelocity[ply] = mv:GetVelocity()
	if CLIENT then me.m_bInFence[ply] = w:GetInFence() end
	if infence and ply:GetMoveType() == MOVETYPE_NOCLIP then
		ply:SetMoveType(MOVETYPE_WALK)
	end
end

-- Squids can go through fences
function ss.FinishMove(w, p, m)
	ply, mv = p, m
	if not (w:GetInFence() or mv:KeyDown(IN_DUCK)) then return end
	if not ply:Crouching() then
		if SERVER then
			w:SetInFence(false)
		else
			me.m_bInFence[ply] = false
		end
		
		return
	end
	
	local prevfence = Either(SERVER, w:GetInFence(), me.m_bInFence[ply])
	if not prevfence and ply:GetMoveType() == MOVETYPE_NOCLIP then return end
	local infence = GetInFence(w, me.m_vecOrigin[ply])
	local oldpos = Vector(me.m_vecOrigin[ply])
	local newpos = Vector(oldpos)
	newpos.z = newpos.z - 2
	if ply:GetGroundEntity() ~= NULL and GetInFence(w, oldpos, newpos) then
		SetGroundEntity(nil) -- Squid cannot stand on fence
		infence = true
	end
	
	SquidMove() -- Movement emulation
	infence = infence or GetInFence(w, me.m_vecOrigin[ply]) -- Check if player is penetrating into fence
	
	if SERVER then
		w:SetInFence(infence)
	else
		me.m_bInFence[ply] = infence
	end
	
	if not (infence or prevfence) then return end
	if infence then
		ply:SetViewPunchAngles(me.m_angViewPunchAngles[ply])
		ply:SetGroundEntity(me.m_entGroundEntity[ply])
		mv:SetMaxClientSpeed(me.m_flClientMaxSpeed[ply])
		mv:SetConstraintRadius(me.m_flConstraintRadius[ply])
		mv:SetForwardSpeed(me.m_flForwardMove[ply])
		mv:SetMaxSpeed(me.m_flMaxSpeed[ply])
		mv:SetSideSpeed(me.m_flSideMove[ply])
		mv:SetUpSpeed(me.m_flUpMove[ply])
		mv:SetButtons(me.m_nButtons[ply])
		-- if me.m_nEmitSound[ply] then ply:EmitSound(me.m_nEmitSound[ply]) end
		ply:RemoveFlags(ply:GetFlags())
		ply:AddFlags(bit.bor(me.m_nFlags[ply], FL_DUCKING))
		mv:SetOldButtons(me.m_nOldButtons[ply])
		-- if me.m_nSetAnimation[ply] then ply:SetAnimation(me.m_nSetAnimation[ply]) end
		-- if me.m_nSplashData[ply] then util.Effect("watersplash", me.m_nSplashData[ply]) end
		mv:SetAngles(me.m_vecAngles[ply])
		mv:SetOldAngles(me.m_vecOldAngles[ply])
		mv:SetOrigin(me.m_vecOrigin[ply])
		mv:SetVelocity(me.m_vecVelocity[ply])
		ply:SetMoveType(MOVETYPE_NOCLIP)
		ply:AddEFlags(EFL_NOCLIP_ACTIVE)
		if me.m_nWaterLevel[ply] > WL_NotInWater then
			ply:AddFlags(FL_INWATER)
		else
			ply:RemoveFlags(FL_INWATER)
		end if me.m_entGroundEntity[ply] ~= NULL then
			ply:AddFlags(FL_ONGROUND)
		else
			ply:RemoveFlags(FL_ONGROUND)
		end
	elseif not mv:KeyDown(IN_DUCK) then
		local t = {
			start = oldpos, endpos = me.m_vecOrigin[ply],
			mask = MASK_PLAYERSOLID, collisiongroup = COLLISION_GROUP_PLAYER_MOVEMENT,
			filter = ply,
		}
		t.mins, t.maxs = ply:GetHull()
		if not util.TraceHull(t).Hit then
			me.m_vecVelocity[ply].z = math.min(me.m_vecVelocity[ply].z / 2, 100)
			mv:SetVelocity(me.m_vecVelocity[ply])
		end
	end
end

function ss.PlayerNoClip(w, ply, desired)
	if desired then return end
	local old = w:GetInFence()
	w:SetInFence(not old and util.TraceHull {
		start = ply:GetPos(), endpos = ply:GetPos(),
		mins = GetPlayerMins(), maxs = GetPlayerMaxs(),
		mask = ss.MASK_GRATE, collisiongroup = COLLISION_GROUP_PLAYER_MOVEMENT,
		filter = ply,
	} .Hit)
	
	if CLIENT then
		me.m_bInFence[ply] = w:GetInFence()
	end
	
	return old == w:GetInFence()
end

hook.Add("FinishMove", "SplatoonSWEPs: Handle noclip", ss.hook "FinishMove")
hook.Add("Move", "SplatoonSWEPs: Squid's movement", ss.hook "MoveHook")
hook.Add("PlayerNoClip", "SplatoonSWEPs: Through fence", ss.hook "PlayerNoClip")
