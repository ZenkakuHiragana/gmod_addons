
--Player movement emulation for the ability of passing through fences.
--Source codes are taken from source-sdk-2013/mp/src/game/shared/gamemovement.cpp
local ss = SplatoonSWEPs
if not ss then return end
local ply, mv
local COORD_FRACTIONAL_BITS = 5
local COORD_DENOMINATOR = bit.lshift(1, COORD_FRACTIONAL_BITS)
local COORD_RESOLUTION = 1.0 / COORD_DENOMINATOR
local GAMEMOVEMENT_JUMP_HEIGHT = 21.0
local LIMIT_Z_DEG = math.cos(math.rad(180 - 30))
local MAX_CLIP_PLANES = 5
local WATERJUMP_HEIGHT = 8
local WL_NotInWater = 0
local WL_Feet = 1
local WL_Waist = 2
local WL_Eyes = 3
local WALLCLIMB_KEYS = bit.bor(IN_JUMP, IN_FORWARD, IN_BACK)
local function GetAirSpeedCap() return 30.0 end
local function GetCurrentGravity() return GetConVar "sv_gravity":GetFloat() end
local function GetPlayerMins(ducked)
	local mins, maxs
	if ducked then
		mins, maxs = ply:GetHullDuck()
	else
		mins, maxs = ply:GetHull()
	end
	
	return mins
end
local function GetPlayerMaxs(ducked)
	local mins, maxs
	if ducked then
		mins, maxs = ply:GetHullDuck()
	else
		mins, maxs = ply:GetHull()
	end
	
	return maxs
end

local function PlayerSolidMask(brushOnly)
	-- return brushOnly and MASK_PLAYERSOLID_BRUSHONLY or MASK_PLAYERSOLID
	return brushOnly and MASK_SHOT_PORTAL or MASK_SHOT
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

//-----------------------------------------------------------------------------
// Traces the player's collision bounds in quadrants, looking for a plane that
// can be stood upon (normal's z >= 0.7f).  Regardless of success or failure,
// replace the fraction and endpos with the original ones, so we don't try to
// move the player down to the new floor and get stuck on a leaning wall that
// the original trace hit first.
//-----------------------------------------------------------------------------
local function TryTouchGroundInQuadrants(start, endpos, fMask, collisionGroup, pm)
	local mins, maxs
	local minsSrc = GetPlayerMins()
	local maxsSrc = GetPlayerMaxs()
	
	local fraction = pm.Fraction
	local hitpos = pm.HitPos
	
	-- Check the -x, -y quadrant
	mins = minsSrc
	maxs = Vector(math.min(0, maxsSrc.x), math.min(0, maxsSrc.y), maxsSrc.z)
	pm = TryTouchGround(start, endpos, mins, maxs, fMask, collisionGroup)
	if pm.Entity and pm.HitNormal.z >= 0.7 then
		pm.Fraction = fraction
		pm.HitPos = hitpos
		return
	end
	
	-- Check the +x, +y quadrant
	mins = Vector(math.max(0, minsSrc.x), math.max(0, minsSrc.y), minsSrc.z)
	maxs = maxsSrc
	pm = TryTouchGround(start, endpos, mins, maxs, fMask, collisionGroup)
	if pm.Entity and pm.HitNormal.z >= 0.7 then
		pm.Fraction = fraction
		pm.HitPos = hitpos
		return
	end
	
	-- Check the -x, +y quadrant
	mins = Vector(minsSrc.x, math.max(0, minsSrc.y), minsSrc.z)
	maxs = Vector(math.min(0, maxsSrc.x), maxsSrc.y, maxsSrc.z)
	pm = TryTouchGround(start, endpos, mins, maxs, fMask, collisionGroup)
	if pm.Entity and pm.HitNormal.z >= 0.7 then
		pm.Fraction = fraction
		pm.HitPos = hitpos
		return
	end
	
	-- Check the +x, -y quadrant
	mins = Vector(math.max(0, minsSrc.x), minsSrc.y, minsSrc.z)
	maxs = Vector(maxsSrc.x, math.min(0, maxsSrc.y), maxsSrc.z)
	pm = TryTouchGround(start, endpos, mins, maxs, fMask, collisionGroup)
	if pm.Entity and pm.HitNormal.z >= 0.7 then
		pm.Fraction = fraction
		pm.HitPos = hitpos
		return
	end

	pm.Fraction = fraction
	pm.HitPos = hitpos
end

local function CategorizeGroundSurface(pm)
	-- local physprops = MoveHelper():GetSurfaceProps() --IPhysicsSurfaceProps
	-- ply.m_surfaceProps = pm.SurfaceProps
	-- ply.m_pSurfaceData = physprops:GetSurfaceData(ply.m_surfaceProps)
	-- physprops:GetPhysicsProperties(ply.m_surfaceProps, nil, nil, ply.m_surfaceFriction, nil)
	
	-- HACKHACK: Scale this to fudge the relationship between vphysics friction values and player friction values.
	-- A value of 0.8f feels pretty normal for vphysics, whereas 1.0f is normal for players.
	-- This scaling trivially makes them equivalent.  REVISIT if this affects low friction surfaces too much.
	-- ply.m_surfaceFriction = ply.m_surfaceFriction * 1.25
	-- if ply.m_surfaceFriction > 1.0 then
		-- ply.m_surfaceFriction = 1.0
	-- end
	
	-- ply.m_chTextureType = ply.m_pSurfaceData.game.material
end

local function SetGroundEntity(pm)
	local newGround = pm and pm.Entity
	local oldGround = ply:GetGroundEntity()
	local vecBaseVelocity = ply:GetBaseVelocity()
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
	
	-- ply:SetBaseVelocity(vecBaseVelocity)
	ply:SetGroundEntity(newGround)
	
	-- If we are on something...

	if newGround then
		CategorizeGroundSurface(pm)
		
		-- Then we are not in water jump sequence
		-- ply:SetSaveValue("m_flWaterJumpTime", 0)
		
		-- Standing on an entity other than the world, so signal that we are touching something.
		-- if not pm.HitWorld then
			-- MoveHelper():AddToTouched(pm, mv:GetVelocity())
		-- end
		
		local v = mv:GetVelocity()
		v.z = 0.0
		mv:SetVelocity(v)
	end
end

local function CanAccelerate()
	-- Dead players don't accelerate.
	if not ply:Alive() then return false end
	
	-- If waterjumping, don't accelerate
	-- if ply:GetInternalVariable "m_flWaterJumpTime" ~= 0 then
		-- return false
	-- end
	
	return true
end

local function CheckVelocity()
	--
	-- bound velocity
	--
	
	local org = mv:GetOrigin()
	for _, i in ipairs {"x", "y", "z"} do
		-- See if it's bogus.
		if mv:GetVelocity()[i] ~= mv:GetVelocity()[i] then
			Msg(string.format(1, "PM  Got a NaN velocity %s\n", i))
			local v = mv:GetVelocity()
			v[i] = 0
			mv:SetVelocity(v)
		end

		if org[i] ~= org[i] then
			Msg(string.format(1, "PM  Got a NaN origin %s\n", i))
			org[i] = 0
			mv:SetOrigin(org)
		end

		-- Bound it.
		if mv:GetVelocity()[i] > GetConVar "sv_maxvelocity":GetFloat() then
			Msg(string.format(1, "PM  Got a velocity too high on %s\n", i))
			local v = mv:GetVelocity()
			v[i] = GetConVar "sv_maxvelocity":GetFloat()
			mv:SetVelocity(v)
		elseif mv:GetVelocity()[i] < -GetConVar "sv_maxvelocity":GetFloat() then
			Msg(string.format(1, "PM  Got a velocity too low on %s\n", i))
			local v = mv:GetVelocity()
			v[i] = -GetConVar "sv_maxvelocity":GetFloat()
			mv:SetVelocity(v)
		end
	end
end

local function ClipVelocity(vin, normal, out, overbounce)
	-- Determine how far along plane to slide based on incoming direction.
	local backoff = vin:Dot(normal) * overbounce
	local change = 0.0
	local angle = normal.z
	local i, blocked = 0, 0x00 -- Assume unblocked.
	if angle > 0 then -- If the plane that is blocking us has a positive z component, then assume it's a floor.
		blocked = bit.bor(blocked, 0x01)
	elseif angle == 0 then -- If the plane has no Z, it is vertical (wall/step)
		blocked = bit.bor(blocked, 0x02)
	end
	
	for _, i in ipairs {"x", "y", "z"} do
		change = normal[i] * backoff
		out[i] = vin[i] - change 
	end
	
	-- iterate once to make sure we aren't still moving through the plane
	local adjust = out:Dot(normal)
	if adjust < 0.0 then
		out = out - normal * adjust
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
	local v = mv:GetVelocity()
	v.z = v.z - ent_gravity * GetCurrentGravity() * 0.5 * FrameTime()
	v.z = v.z + ply:GetBaseVelocity().x * FrameTime()
	mv:SetVelocity(v)

	-- local temp = ply:GetBaseVelocity()
	-- temp.z = 0
	-- ply:SetBaseVelocity(temp)

	CheckVelocity()
end

local function FinishGravity()
	local ent_gravity = 1.0
	-- if ply:GetInternalVariable "m_flWaterJumpTime" ~= 0 then
		-- return
	-- end
	
	if ply:GetGravity() ~= 0 then
		ent_gravity = ply:GetGravity()
	end
	
	-- Get the correct velocity for the end of the dt 
	local v = mv:GetVelocity()
	v.z = v.z - (ent_gravity * GetCurrentGravity() * FrameTime() * 0.5)
  	mv:SetVelocity(v)
	
	CheckVelocity()
end

-- local function PlayerRoughLandingEffects(fvol)
	-- if fvol > 0.0 then
		--
		-- Play landing sound right away.
		-- ply:SetSaveValue("m_flStepSoundTime", 400)

		-- Play step sound for current texture.
		-- player->PlayStepSound( (Vector &)mv->GetAbsOrigin(), player->m_pSurfaceData, fvol, true );

		--
		-- Knock the screen around a little bit, temporary effect.
		--
		-- local a = ply:GetViewPunchAngles()
		-- a.roll = ply.m_Local.m_flFallVelocity * .013
		-- ply:SetViewPunchAngles(a)

		-- if ply.m_Local.m_vecPunchAngle.pitch > 8 then
			-- local a = ply:GetViewPunchAngles()
			-- a.pitch = 8
			-- ply:SetViewPunchAngles(a)
		-- end

		-- if not CLIENT then
			-- ply:RumbleEffect(fvol > 0.85 and RUMBLE_FALL_LONG or RUMBLE_FALL_SHORT, 0, RUMBLE_FLAGS_NONE)
		-- end
	-- end
-- end

-- local function GetPointContentsCached(point, slot)
	-- if g_bMovementOptimizations then
		-- assert(ply)
		-- assert(slot >= 0 and slot < MAX_PC_CACHE_SLOTS)
		-- local idx = ply:EntIndex() - 1
		-- if m_CachedGetPointContents[idx][slot] == -9999 or point:DistToSqr(m_CachedGetPointContentsPoint[idx][slot]) > 1 then
			-- m_CachedGetPointContents[idx][slot] = util.PointContents(point)
			-- m_CachedGetPointContentsPoint[idx][slot] = point
		-- end
		
		-- return m_CachedGetPointContents[idx][slot]
	-- else
		-- return util.PointContents(point)
	-- end
-- end

-- local function CheckFalling()
	-- this function really deals with landing, not falling, so early out otherwise
	-- if ply:GetGroundEntity() == NULL then --or ply.m_Local.m_flFallVelocity <= 0
		-- return
	-- end
	
	-- if ply:Alive() then --and ply.m_Local.m_flFallVelocity >= PLAYER_FALL_PUNCH_THRESHOLD
		-- local bAlive = true
		-- local fvol = 0.5
		
		-- if ply:WaterLevel() > 0 then
			-- They landed in water.
		-- else
			-- Scale it down if we landed on something that's floating...
			-- if ply:GetGroundEntity():IsEFlagSet(EFL_TOUCHING_FLUID) then
				-- ply.m_Local.m_flFallVelocity = ply.m_Local.m_flFallVelocity - PLAYER_LAND_ON_FLOATING_OBJECT
			-- end
			
			--
			-- They hit the ground.
			--
			-- if ply:GetGroundEntity():GetAbsVelocity().z < 0.0 then
				-- Player landed on a descending object. Subtract the velocity of the ground entity.
				-- ply.m_Local.m_flFallVelocity = ply.m_Local.m_flFallVelocity + ply:GetGroundEntity():GetAbsVelocity().z
				-- ply.m_Local.m_flFallVelocity = math.max(0.1, ply.m_Local.m_flFallVelocity)
			-- end

			-- if ply.m_Local.m_flFallVelocity > PLAYER_MAX_SAFE_FALL_SPEED then
				--
				-- If they hit the ground going this fast they may take damage (and die).
				--
				-- bAlive = MoveHelper():PlayerFallingDamage()
				-- fvol = 1.0
			-- elseif ply.m_Local.m_flFallVelocity > PLAYER_MAX_SAFE_FALL_SPEED / 2 then
				-- fvol = 0.85
			-- elseif ply.m_Local.m_flFallVelocity < PLAYER_MIN_BOUNCE_SPEED then
				-- fvol = 0
			-- end
		-- end

		-- PlayerRoughLandingEffects(fvol)

		-- if bAlive then
			-- MoveHelper():PlayerSetAnimation(PLAYER_WALK)
		-- end
	-- end
	
	-- let any subclasses know that the player has landed and how hard
	-- OnLand(ply.m_Local.m_flFallVelocity)
	
	--
	-- Clear the fall velocity so the impact doesn't happen again.
	--
	-- ply.m_Local.m_flFallVelocity = 0
-- end

local function CheckJumpButton()
	if not ply:Alive() then -- don't jump again until released
		mv:SetOldButtons(bit.bor(mv:GetOldButtons(), IN_JUMP))
		return
	end
	
	-- See if we are waterjumping.  If so, decrement count and return.
	-- if ply:GetInternalVariable "m_flWaterJumpTime" ~= 0 then
		-- ply:SetSaveValue("m_flWaterJumpTime", math.max(0,
		-- ply:GetInternalVariable "m_flWaterJumpTime" - FrameTime()))
		-- return
	-- end
	
	-- If we are in the water most of the way...
	if ply:WaterLevel() >= 2 then
		-- swimming, not jumping
		SetGroundEntity(nil)
		
		if ply:GetWaterType() == CONTENTS_WATER then -- We move up a certain amount
			local v = mv:GetVelocity()
			v.z = 100
			mv:SetVelocity(v)
		elseif ply:GetWaterType() == CONTENTS_SLIME then
			local v = mv:GetVelocity()
			v.z = 80
			mv:SetVelocity(v)
		end
		
		-- play swiming sound
		-- if ply:GetInternalVariable "m_flSwimSoundTime" <= 0 then
			-- Don't play sound again for 1 second
			-- ply:SetSaveValue("m_flSwimSoundTime", 1000)
			-- PlaySwimSound()
		-- end
		
		return
	end
	
	-- No more effect
 	if ply:GetGroundEntity() == NULL then
		mv:SetOldButtons(bit.bor(mv:GetOldButtons(), IN_JUMP))
		return false -- in air, so no effect
	end
	
	-- Don't allow jumping when the player is in a stasis field.
-- #ifndef HL2_EPISODIC
	-- if ply.m_Local.m_bSlowMovement then
		-- return false
	-- end
-- #endif
	
	if bit.band(mv:GetOldButtons(), IN_JUMP) ~= 0 then
		return false -- don't pogo stick
	end
	
	-- Cannot jump will in the unduck transition.
	if ply:Crouching() and bit.band(ply:GetFlags(), FL_DUCKING) ~= 0 then
		return false
	end
	
	-- Still updating the eye position.
	-- if ply.m_Local.m_flDuckJumpTime > 0.0 then
		-- return false
	-- end
	
	-- In the air now.
    SetGroundEntity(nil)
	
	-- ply:PlayStepSound(mv:GetOrigin(), ply.m_pSurfaceData, 1.0, true)
	
	-- MoveHelper():PlayerSetAnimation(PLAYER_JUMP);

	local flGroundFactor = 1.0
	-- if ply.m_pSurfaceData then
		-- flGroundFactor = ply.m_pSurfaceData.game.jumpFactor
	-- end

	local flMul
	if g_bMovementOptimizations then
-- #if defined(HL2_DLL) || defined(HL2_CLIENT_DLL)
		-- assert(GetCurrentGravity() == 600.0)
		-- flMul = 160.0 -- approx. 21 units.
-- #else
		-- assert(GetCurrentGravity() == 800.0)
		-- flMul = 268.3281572999747
-- #endif
	else
		flMul = math.sqrt(2 * GetCurrentGravity() * GAMEMOVEMENT_JUMP_HEIGHT)
	end

	// Acclerate upward
	// If we are ducking...
	local startz = mv:GetVelocity().z
	if ply:Crouching() or bit.band(ply:GetFlags(), FL_DUCKING) ~= 0 then
		// d = 0.5 * g * t^2		- distance traveled with linear accel
		// t = sqrt(2.0 * 45 / g)	- how long to fall 45 units
		// v = g * t				- velocity at the end (just invert it to jump up that high)
		// v = g * sqrt(2.0 * 45 / g )
		// v^2 = g * g * 2.0 * 45 / g
		// v = sqrt( g * 2.0 * 45 )
		local v = mv:GetVelocity()
		v.z = flGroundFactor * flMul -- 2 * gravity * height
		mv:SetVelocity(v)
	else
		local v = mv:GetVelocity()
		v.z = flGroundFactor * flMul -- 2 * gravity * height
		mv:SetVelocity(v)
	end

	// Add a little forward velocity based on your current forward velocity - if you are not sprinting.
-- #if defined( HL2_DLL ) || defined( HL2_CLIENT_DLL )
	if game.SinglePlayer() then
		local pMoveData = mv
		local vecForward = mv:GetAngles():Forward()
		vecForward.z = 0
		vecForward:Normalize()
		
		-- We give a certain percentage of the current forward movement as a bonus to the jump speed.  That bonus is clipped
		-- to not accumulate over time.
		local flSpeedBoostPerc = not (pMoveData:KeyDown(IN_SPEED) or ply:Crouching()) and 0.5 or 0.1
		local flSpeedAddition = math.abs(mv:GetForwardSpeed() * flSpeedBoostPerc)
		local flMaxSpeed = mv:GetMaxSpeed() * (1 + flSpeedBoostPerc) 
		local flNewSpeed = flSpeedAddition + mv:GetVelocity():Length2D()
		
		-- If we're over the maximum, we want to only boost as much as will get us to the goal speed
		if flNewSpeed > flMaxSpeed then
			flSpeedAddition = flSpeedAddition - (flNewSpeed - flMaxSpeed)
		end

		if mv:GetForwardSpeed() < 0.0 then
			flSpeedAddition = flSpeedAddition * -1.0
		end
		
		-- Add it on
		mv:SetVelocity(mv:GetVelocity() + vecForward * flSpeedAddition)
	end
-- #endif
	
	FinishGravity()
	
	-- CheckV(ply:CurrentCommandNumber(), "CheckJump", mv:GetVelocity())
	
	-- mv.m_outJumpVel.z = = mv.m_outJumpVel.z + mv:GetVelocity().z - startz
	-- mv.m_outStepHeight = mv.m_outStepHeight + 0.15
	
	-- OnJump(mv.m_outJumpVel.z)
	
	-- Set jump time.
	-- if game.SinglePlayer() then
		-- player.m_Local.m_flJumpTime = GAMEMOVEMENT_JUMP_TIME;
		-- player.m_Local.m_bInDuckJump = true;
	-- end
	
-- #if defined( HL2_DLL )
	
	-- if GetConVar "xc_uncrouch_on_jump":GetBool() then
		-- Uncrouch when jumping
		-- if ply:GetToggledDuckState() then
			-- ply:ToggleDuck()
		-- end
	-- end
	
-- #endif
	
	-- Flag that we jumped.
	mv:SetOldButtons(bit.bor(mv:GetOldButtons(), IN_JUMP)) -- don't jump again until released
	return true
end

local function CheckWater()
	-- local point = vector_origin
	-- local cont = 0
	
	-- local vPlayerMins = GetPlayerMins()
	-- local vPlayerMaxs = GetPlayerMaxs()
	
	-- Pick a spot just above the players feet.
	-- point.x = mv:GetOrigin().x + (vPlayerMins.x + vPlayerMaxs.x) * 0.5
	-- point.y = mv:GetOrigin().y + (vPlayerMins.y + vPlayerMaxs.y) * 0.5
	-- point.z = mv:GetOrigin().z + vPlayerMins.z + 1
	
	-- Assume that we are not in water at all.
	-- player->SetWaterLevel( WL_NotInWater );
	-- player->SetWaterType( CONTENTS_EMPTY );
	
	-- Grab point contents.
	-- cont = GetPointContentsCached(point, 0)
	
	-- Are we under water? (not solid and not empty?)
	-- if bit.band(cont, MASK_WATER) ~= 0 then
		-- Set water type
		-- player->SetWaterType( cont );
		
		-- We are at least at level one
		-- player->SetWaterLevel( WL_Feet );
		
		-- Now check a point that is at the player hull midpoint.
		-- point.z = mv:GetOrigin().z + (vPlayerMins.z + vPlayerMaxs.z) * 0.5
		-- cont = GetPointContentsCached(point, 1)
		-- If that point is also under water...
		-- if bit.band(cont, MASK_WATER) ~= 0 then
			-- Set a higher water level.
			-- player->SetWaterLevel( WL_Waist );

			-- Now check the eye position.  (view_ofs is relative to the origin)
			-- point.z = mv:GetAbsOrigin().z + ply:GetViewOffset().z
			-- cont = GetPointContentsCached(point, 2)
			-- if bit.band(cont, MASK_WATER) ~= 0 then
				-- player->SetWaterLevel( WL_Eyes );  -- In over our eyes
				-- end
		-- end
		
		-- Adjust velocity based on water current, if any.
		-- if bit.band(cont, MASK_CURRENT) ~= 0 then
			-- local v = vector_origin
			-- if bit.band(cont, CONTENTS_CURRENT_0) ~= 0 then
				-- v.x = v.x + 1
			-- end if bit.band(cont, CONTENTS_CURRENT_90) ~= 0 then
				-- v.y = v.y + 1
			-- end if bit.band(cont, CONTENTS_CURRENT_180) ~= 0 then
				-- v.x = v.x - 1
			-- end if bit.band(cont, CONTENTS_CURRENT_270) ~= 0 then
				-- v.y = v.y - 1
			-- end if bit.band(cont, CONTENTS_CURRENT_UP) ~= 0 then
				-- v.z = v.z + 1
			-- end if bit.band(cont, CONTENTS_CURRENT_DOWN) ~= 0 then
				-- v.z = v.z - 1
			-- end

			-- BUGBUG -- this depends on the value of an unspecified enumerated type
			-- The deeper we are, the stronger the current.
			-- ply:SetBaseVelocity(ply:GetBaseVelocity() + 50.0 * ply:WaterLevel() * v)
		-- end
	-- end
	
	-- if we just transitioned from not in water to in water, record the time it happened
	-- if WL_NotInWater == m_nOldWaterLevel and ply:WaterLevel() > WL_NotInWater then
		-- m_flWaterEntryTime = CurTime()
	-- end
	
	return ply:WaterLevel() > WL_Feet
end

local function CheckWaterJump()
	local flatforward
	local forward = mv:GetAngles():Forward() -- Determine movement angles
	local flatvelocity = Vector(mv:GetVelocity())
	local curspeed 
	
	-- Already water jumping.
	-- if ply:GetInternalVariable "m_flWaterJumpTime" ~= 0 then
		-- return
	-- end
	
	-- Don't hop out if we just jumped in
	if mv:GetVelocity().z < -180 then
		return -- only hop out if we are moving up
	end
	
	-- See if we are backing up
	flatvelocity.z = 0
	
	-- Must be moving
	curspeed = flatvelocity:Length()
	flatvelocity:Normalize()
	
	-- see if near an edge
	flatforward.x = forward.x
	flatforward.y = forward.y
	flatforward.z = 0
	flatforward:Normalize()
	
	-- Are we backing into water from steps or something?  If so, don't pop forward
	if curspeed ~= 0.0 and flatvelocity:Dot(flatforward) < 0.0 then
		return
	end
	
	-- Start line trace at waist height (using the center of the player for this here)
	local vecStart = mv:GetOrigin() + (GetPlayerMins() + GetPlayerMaxs()) * 0.5
	local vecEnd = vecStart + 24.0 * flatforward
	local tr = TracePlayerBBox(vecStart, vecEnd, PlayerSolidMask(), COLLISION_GROUP_PLAYER_MOVEMENT)
	if tr.Fraction < 1.0 then -- solid at waist
		local pPhysObj = tr.Entity:GetPhysicsObject()
		if IsValid(pPhysObj) then
			if pPhysObj:HasGameFlag(FVPHYSICS_PLAYER_HELD) then
				return
			end
		end
		
		vecStart.z = mv:GetOrigin().z + ply:GetViewOffset().z + WATERJUMP_HEIGHT
		vecEnd = vecStart + 24.0 * flatforward
		-- ply:SetSaveValue("m_vecWaterJumpVel", -50.0 * tr.HitNormal)
		
		tr = TracePlayerBBox(vecStart, vecEnd, PlayerSolidMask(), COLLISION_GROUP_PLAYER_MOVEMENT)
		if tr.Fraction == 1.0 then -- open at eye level
			-- Now trace down to see if we would actually land on a standable surface.
			vecStart = Vector(vecEnd)
			vecEnd.z = vecEnd.z - 1024.0
			tr = TracePlayerBBox(vecStart, vecEnd, PlayerSolidMask(), COLLISION_GROUP_PLAYER_MOVEMENT)
			if tr.Fraction < 1.0 and tr.HitNormal.z >= 0.7 then
				mv:GetVelocity().z = 256.0 -- Push up
				mv:SetOldButtons(bit.bor(mv:GetOldButtons(), IN_JUMP)) -- Don't jump again until released
				ply:AddFlags(FL_WATERJUMP)
				-- ply:SetSaveValue("m_flWaterJumpTime", 2000.0) -- Do this for 2 seconds
			end
		end
	end
end

local function CategorizePosition()
	local point = Vector()
	local pm
	
	-- Reset this each time we-recategorize, otherwise we have bogus friction when we jump into water and plunge downward really quickly
	ply.m_surfaceFriction = 1.0
	
	-- if the player hull point one unit down is solid, the player
	-- is on ground
	
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
	
	point.x = mv:GetOrigin().x
	point.y = mv:GetOrigin().y
	point.z = mv:GetOrigin().z - flOffset
	
	local bumpOrigin = mv:GetOrigin()
	
	-- Shooting up really fast.  Definitely not on ground.
	-- On ladder moving up, so not on ground either
	-- NOTE: 145 is a jump.
	local NON_JUMP_VELOCITY = 140.0
	
	local zvel = mv:GetVelocity().z
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
		local ground = ply:GetGroundEntity()
		if ground and ground ~= NULL then
			flGroundEntityVelZ = ground:GetAbsVelocity().z
			bMovingUpRapidly = zvel - flGroundEntityVelZ > NON_JUMP_VELOCITY
		end
	end
	
	-- Was on ground, but now suddenly am not
	if bMovingUpRapidly or bMovingUp and ply:GetMoveType() == MOVETYPE_LADDER then
		SetGroundEntity(nil)
	else -- Try and move down.
		pm = TryTouchGround(bumpOrigin, point, GetPlayerMins(), GetPlayerMaxs(), MASK_PLAYERSOLID, COLLISION_GROUP_PLAYER_MOVEMENT)
		
		-- Was on ground, but now suddenly am not.  If we hit a steep plane, we are not on ground
		if not pm.Entity or pm.Entity == NULL or pm.HitNormal.z < 0.7 then
			-- Test four sub-boxes, to see if any of them would have found shallower slope we could actually stand on
			TryTouchGroundInQuadrants(bumpOrigin, point, MASK_PLAYERSOLID, COLLISION_GROUP_PLAYER_MOVEMENT, pm)

			if not pm.Entity or pm.Entity == NULL or pm.HitNormal.z < 0.7 then
				SetGroundEntity(nil)
				-- probably want to add a check for a +z velocity too!
				if mv:GetVelocity().z > 0.0 and ply:GetMoveType() ~= MOVETYPE_NOCLIP then
					ply.m_surfaceFriction = 0.25
				end
			else
				SetGroundEntity(pm)
			end
		else
			SetGroundEntity(pm) -- Otherwise, point to index of ent under us.
		end

		-- if not CLIENT then
			
			--Adrian: vehicle code handles for us.
			-- if not ply:InVehicle() then
				-- If our gamematerial has changed, tell any player surface triggers that are watching
				-- local physprops = MoveHelper():GetSurfaceProps() --IPhysicsSurfaceProps
				-- local pSurfaceProp = physprops:GetSurfaceData(pm.SurfaceProps) --surfacedata_t
				-- local cCurrGameMaterial = pSurfaceProp.game.material --char
				-- if not ply:GetGroundEntity() or ply:GetGroundEntity() == NULL then
					-- cCurrGameMaterial = 0
				-- end
				
				-- Changed?
				-- if ply.m_chPreviousTextureType ~= cCurrGameMaterial then
					-- CEnvPlayerSurfaceTrigger:SetPlayerSurface(ply, cCurrGameMaterial)
				-- end

				-- ply.m_chPreviousTextureType = cCurrGameMaterial
			-- end
		-- end
	end
end

local function WaterJump()
	-- if ply:GetInternalVariable "m_flWaterJumpTime" > 10000 then
		-- ply:SetSaveValue("m_flWaterJumpTime", 10000)
	-- end
	
	-- if not ply:GetInternalVariable "m_flWaterJumpTime" then
		-- return
	-- end
	
	-- ply:SetSaveValue("m_flWaterJumpTime", ply:GetInternalVariable "m_flWaterJumpTime" - 1000.0 * FrameTime())
	
	-- if ply:GetInternalVariable "m_flWaterJumpTime" <= 0 or ply:WaterLevel() == 0 then
		-- ply:SetSaveValue("m_flWaterJumpTime", 0)
		-- ply:RemoveFlags(FL_WATERJUMP)
	-- end
	
	-- local v = mv:GetVelocity()
	-- v.x = ply:GetInternalVariable "m_vecWaterJumpVel".x
	-- v.y = ply:GetInternalVariable "m_vecWaterJumpVel".y
	-- mv:SetVelocity(v)
end

local function Friction()
	local speed, newspeed, control
	local friction
	local drop = 0
	
	-- If we are in water jump cycle, don't apply friction
	-- if ply:GetInternalVariable "m_flWaterJumpTime" ~= 0 then
		-- return
	-- end
	
	-- Calculate speed
	speed = mv:GetVelocity():Length()
	
	-- If too slow, return
	if speed < 0.1 then
		return
	end
	
	-- apply ground friction
	if ply:GetGroundEntity() ~= NULL then -- On an entity that is the ground
		friction = GetConVar "sv_friction":GetFloat() * ply.m_surfaceFriction
		
		-- Bleed off some speed, but if we have less than the bleed
		--  threshold, bleed the threshold amount.
		control = math.max(speed, GetConVar "sv_stopspeed":GetFloat())
		
		-- Add the amount to the drop amount.
		drop = drop + control * friction * FrameTime()
	end
	
	-- scale the velocity
	newspeed = math.max(0, speed - drop)
	if newspeed ~= speed then
		-- Determine proportion of old speed we are using.
		newspeed = newspeed / speed
		-- Adjust velocity according to proportion.
		mv:SetVelocity(mv:GetVelocity() * newspeed)
	end
	
 	-- mv.m_outWishVel = mv.m_outWishVel - (1 - newspeed) * mv:GetVelocity()
end

local function Accelerate(wishdir, wishspeed, accel)
	local i
	local addspeed, accelspeed, currentspeed
	
	-- This gets overridden because some games (CSPort) want to allow dead (observer) players
	-- to be able to move around.
	if not CanAccelerate() then return end
	
	-- See if we are changing direction a bit
	currentspeed = mv:GetVelocity():Dot(wishdir)
	
	-- Reduce wishspeed by the amount of veer.
	addspeed = wishspeed - currentspeed
	
	-- If not going to add any speed, done.
	if addspeed <= 0 then return end
	
	-- Determine amount of accleration.
	accelspeed = accel * FrameTime() * wishspeed --* ply.m_surfaceFriction
	
	-- Cap at addspeed
	if accelspeed > addspeed then
		accelspeed = addspeed
	end
	
	-- Adjust velocity.
	local v = mv:GetVelocity()
	for _, i in ipairs {"x", "y", "z"} do
		v[i] = v[i] + accelspeed * wishdir[i]
	end
	mv:SetVelocity(v)
end

local function AirAccelerate(wishdir, wishspeed, accel)
	local i
	local addspeed, accelspeed, currentspeed
	local wishspd = wishspeed
	
	if not ply:Alive() then return end
	-- if ply:GetInternalVariable "m_flWaterJumpTime" ~= 0 then
		-- return
	-- end
	
	-- Cap speed
	if wishspd > GetAirSpeedCap() then
		wishspd = GetAirSpeedCap()
	end
	
	-- Determine veer amount
	currentspeed = mv:GetVelocity():Dot(wishdir)
	
	-- See how much to add
	addspeed = wishspd - currentspeed
	
	-- If not adding any, done.
	if addspeed <= 0 then return end
	
	-- Determine acceleration speed after acceleration
	accelspeed = accel * wishspeed * FrameTime() --* ply.m_surfaceFriction
	
	-- Cap it
	if accelspeed > addspeed then
		accelspeed = addspeed
	end
	
	-- Adjust pmove vel.
	local v = mv:GetVelocity()
	for _, i in ipairs {"x", "y", "z"} do
		v[i] = v[i] + accelspeed * wishdir[i]
		-- mv.m_outWishVel[i] = mv.m_outWishVel[i] + accelspeed * wishdir[i]
	end
end

local function TryPlayerMove(pFirstDest, pFirstTrace)
	local		numbumps = 4 -- Bump up to four times
	local		dir = vector_origin
	local		d = 0.0
	local		numplanes = 0 -- and not sliding along any planes
	local		planes = {} --MAX_CLIP_PLANES
	local		primal_velocity, original_velocity -- Store original velocity
				= Vector(mv:GetVelocity()), Vector(mv:GetVelocity())
	local		new_velocity = vector_origin
	local		i, j = 0, 0
	local		pm --TraceResult
	local		endpos = vector_origin
	local		time_left, allFraction = FrameTime(), 0.0 -- Total time for this movement operation.
	local		blocked = 0 -- Assume not blocked
	for bumpcount = 0, numbumps - 1 do
		if mv:GetVelocity():Length() == 0.0 then break end
		
		-- Assume we can move all the way from the current origin to the
		--  end point.
		endpos = mv:GetOrigin() + time_left * mv:GetVelocity()

		-- See if we can make it from origin to end point.
		if g_bMovementOptimizations then
			-- If their velocity Z is 0, then we can avoid an extra trace here during WalkMove.
			if pFirstDest and endpos == pFirstDest then
				pm = pFirstTrace
			else
				pm = TracePlayerBBox(mv:GetOrigin(), endpos, PlayerSolidMask(), COLLISION_GROUP_PLAYER_MOVEMENT)
			end
		else
			pm = TracePlayerBBox(mv:GetOrigin(), endpos, PlayerSolidMask(), COLLISION_GROUP_PLAYER_MOVEMENT)
		end
		
		allFraction = allFraction + pm.Fraction
		
		-- If we started in a solid object, or we were in solid space
		--  the whole way, zero out our velocity and return that we
		--  are blocked by floor and wall.
		if pm.AllSolid then
			-- entity is trapped in another solid
			mv:SetVelocity(vector_origin)
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
					mv:SetVelocity(vector_origin)
					break
				end
			end
			
			-- actually covered some distance
			mv:SetOrigin(pm.HitPos)
			mv:SetVelocity(Vector(original_velocity))
			numplanes = 0
		end
		
		-- If we covered the entire distance, we are done
		--  and can return.
		if pm.fraction == 1 then break end -- moved the entire distance
		
		-- Save entity that blocked us (since fraction was < 1.0)
		--  for contact
		-- Add it if it's not already in the list!!!
		-- MoveHelper():AddToTouched(pm, mv:GetVelocity())
		
		-- If the plane we hit has a high z component in the normal, then
		--  it's probably a floor
		if pm.HitNormal.z > 0.7 then
			blocked = bit.bor(blocked, 1) -- floor
		end
		-- If the plane has a zero z component in the normal, then it's a 
		--  step or wall
		if pm.HitNormal == 0 then
			blocked = bit.bor(blocked, 2) -- step / wall
		end
		
		-- Reduce amount of m_flFrameTime left by total time left * fraction
		--  that we covered.
		time_left = time_left * (1 - pm.Fraction)
		
		-- Did we run out of planes to clip against?
		if numplanes >= MAX_CLIP_PLANES then
			-- this shouldn't really happen
			--  Stop our movement if so.
			mv:SetVelocity(vector_origin)
			--print "Too many planes 4"
			
			break
		end
		
		-- Set up next clipping plane
		planes[numplanes] = pm.HitNormal
		numplanes = numplanes + 1
		
		-- modify original_velocity so it parallels all of the clip planes
		--
		
		-- reflect player velocity 
		-- Only give this a try for first impact plane because you can get yourself stuck in an acute corner by jumping in place
		--  and pressing forward and nobody was really using this bounce/reflection feature anyway...
		if numplanes == 1 and
			-- ply:GetMoveType() == MOVETYPE_WALK and
			ply:GetGroundEntity() == NULL then
			for i = 0, numplanes - 1 do
				if planes[i].z > 0.7 then
					-- floor or slope
					ClipVelocity(original_velocity, planes[i], new_velocity, 1)
					original_velocity = Vector(new_velocity)
				else
					ClipVelocity(original_velocity, planes[i], new_velocity, 1.0
					+ GetConVar "sv_bounce":GetFloat() * (1 - (ply.m_surfaceFriction or 0)))
				end
			end
			
			mv:SetVelocity(new_velocity)
			original_velocity = new_velocity
		else
			for i = 0, numplanes - 1 do
				ClipVelocity(original_velocity, planes[i], mv:GetVelocity(), 1)
				for j = 0, numplanes - 1 do
					if j ~= i then
						-- Are we now moving against this plane?
						if mv:GetVelocity():Dot(planes[j]) < 0 then
							break -- not ok
						end
					end
				end
				
				if j == numplanes then -- Didn't have to clip, so we're ok
					break
				end
			end
			
			-- Did we go all the way through plane set
			if i ~= numplanes then
				-- go along this plane
				-- pmove.velocity is set in clipping call, no need to set again. 
			else -- go along the crease
				if numplanes ~= 2 then
					mv:SetVelocity(vector_origin)
					break
				end
				
				dir = planes[0]:Cross(planes[1])
				dir:Normalize()
				d = dir:Dot(mv:GetVelocity())
				mv:SetVelocity(dir * d)
			end
			
			--
			-- if original velocity is against the original velocity, stop dead
			-- to avoid tiny occilations in sloping corners
			--
			d = mv:GetVelocity():Dot(primal_velocity)
			if d <= 0 then
				--print "Back"
				mv:SetVelocity(vector_origin)
				break
			end
		end
	end

	if allFraction == 0 then
		mv:SetVelocity(vector_origin)
	end

	-- Check if they slammed into a wall
	-- local fSlamVol = 0.0
	
	-- local fLateralStoppingAmount = primal_velocity:Length2D() - mv:GetVelocity():Length2D()
	-- if fLateralStoppingAmount > PLAYER_MAX_SAFE_FALL_SPEED * 2.0 then
		-- fSlamVol = 1.0
	-- elseif fLateralStoppingAmount > PLAYER_MAX_SAFE_FALL_SPEED then
		-- fSlamVol = 0.85
	-- end
	
	-- PlayerRoughLandingEffects(fSlamVol)

	return blocked
end

local function StayOnGround()
	local trace
	local start = mv:GetOrigin()
	local endpos = mv:GetOrigin()
	start.z = start.z + 2
	endpos.z = endpos.z - ply:GetStepSize()
	
	-- See how far up we can go without getting stuck
	
	trace = TracePlayerBBox(mv:GetOrigin(), start, PlayerSolidMask(), COLLISION_GROUP_PLAYER_MOVEMENT)
	start = trace.HitPos
	
	-- using trace.startsolid is unreliable here, it doesn't get set when
	-- tracing bounding box vs. terrain
	
	-- Now trace down from a known safe position
	trace = TracePlayerBBox(start, endpos, PlayerSolidMask(), COLLISION_GROUP_PLAYER_MOVEMENT)
	if trace.Fraction > 0.0 and	 -- must go somewhere
		trace.Fraction < 1.0 and -- must hit something
		not trace.StartSolid and -- can't be embedded in a solid
		trace.HitNormal.z >= 0.7 then -- can't hit a steep slope that we can't stand on anyway
		local flDelta = math.abs(mv:GetOrigin().z - trace.HitPos.z)
		
		-- This is incredibly hacky. The real problem is that trace returning that strange value we can't network over.
		if flDelta > 0.5 * COORD_RESOLUTION then
			mv:SetOrigin(trace.HitPos)
		end
	end
end

local function StepMove(vecDestination, trace)
	local vecEndPos = Vector(vecDestination)
	
	-- Try sliding forward both on ground and up 16 pixels
	--  take the move that goes farthest
	local vecPos, vecVel = Vector(mv:GetOrigin()), Vector(mv:GetVelocity())
	
	-- Slide move down.
	TryPlayerMove(vecEndPos, trace)
	
	-- Down results.
	local vecDownPos, vecDownVel = Vector(mv:GetOrigin()), Vector(mv:GetVelocity())
	
	-- Reset original values.
	mv:SetOrigin(vecPos)
	mv:SetVelocity(Vector(vecVel))
	
	-- Move up a stair height.
	vecEndPos = Vector(mv:GetOrigin())
	-- if ply.m_Local.m_bAllowAutoMovement then
		-- vecEndPos.z = vecEndPos.z + ply.m_Local.m_flStepSize + DIST_EPSILON
	-- end
	
	trace = TracePlayerBBox(mv:GetOrigin(), vecEndPos, PlayerSolidMask(), COLLISION_GROUP_PLAYER_MOVEMENT)
	if not (trace.StartSolid or trace.AllSolid) then
		mv:SetOrigin(trace.HitPos)
	end
	
	-- Slide move up.
	TryPlayerMove()
	
	-- Move down a stair (attempt to).
	vecEndPos = Vector(mv:GetOrigin())
	-- if ply.m_Local.m_bAllowAutoMovement then
		-- vecEndPos.z = vecEndPos.z - ply.m_Local.m_flStepSize + DIST_EPSILON
	-- end
		
	trace = TracePlayerBBox(mv:GetOrigin(), vecEndPos, PlayerSolidMask(), COLLISION_GROUP_PLAYER_MOVEMENT)
	
	-- If we are not on the ground any more then use the original movement attempt.
	if trace.HitNormal.z < 0.7 then
		mv:SetOrigin(vecDownPos)
		mv:SetVelocity(Vector(vecDownVel))
		-- local flStepDist = mv:GetOrigin().z - vecPos.z
		-- if flStepDist > 0.0 then
			-- mv.m_outStepHeight = mv.m_outStepHeight + flStepDist
		-- end
		return
	end
	
	-- If the trace ended up in empty space, copy the end over to the origin.
	if not (trace.StartSolid or trace.AllSolid) then
		mv:SetOrigin(trace.HitPos)
	end
	
	-- Copy this origin to up.
	local vecUpPos = Vector(mv:GetOrigin())
	
	-- decide which one went farther
	local flDownDist
		= (vecDownPos.x - vecPos.x) * (vecDownPos.x - vecPos.x)
		+ (vecDownPos.y - vecPos.y) * (vecDownPos.y - vecPos.y)
	local flUpDist
		= (vecUpPos.x - vecPos.x) * (vecUpPos.x - vecPos.x)
		+ (vecUpPos.y - vecPos.y) * (vecUpPos.y - vecPos.y)
	if flDownDist > flUpDist then
		mv:SetOrigin(vecDownPos)
		mv:SetVelocity(Vector(vecDownVel))
	else 
		-- copy z value from slide move
		local v = mv:GetVelocity()
		v.z = vecDownVel.z
		mv:SetVelocity(v)
	end
	
	-- local flStepDist = mv:GetOrigin().z - vecPos.z
	-- if flStepDist > 0 then
		-- mv.m_outStepHeight = = mv.m_outStepHeight + flStepDist
	-- end
end

local function AirMove()
	local i
	local wishvel = Vector()
	local fmove, smove
	local wishdir
	local wishspeed
	local forward = mv:GetAngles():Forward()
	local right = mv:GetAngles():Right()
	local up = mv:GetAngles():Up() -- Determine movement angles
	
	-- Copy movement amounts
	fmove = mv:GetForwardSpeed()
	smove = mv:GetSideSpeed()
	
	-- Zero out z components of movement vectors
	forward.z, right.z = 0, 0
	forward:Normalize() -- Normalize remainder of vectors
	right:Normalize() --

	for _, i in ipairs {"x", "y", "z"} do -- Determine x and y parts of velocity
		wishvel[i] = forward[i] * fmove + right[i] * smove
	end
	
	wishvel.z = 0 -- Zero out z part of velocity

	wishdir = Vector(wishvel) -- Determine maginitude of speed of move
	wishspeed = wishdir:Length()
	wishdir:Normalize()
	
	--
	-- clamp to server defined max speed
	--
	if wishspeed ~= 0.0 and wishspeed > mv:GetMaxSpeed() then
		wishvel = wishvel * mv:GetMaxSpeed() / wishspeed
		wishspeed = mv:GetMaxSpeed()
	end
	
	AirAccelerate(wishdir, wishspeed, GetConVar "sv_airaccelerate":GetFloat())
	
	-- Add in any base velocity to the current velocity.
	mv:SetVelocity(mv:GetVelocity() + ply:GetBaseVelocity())
	
	TryPlayerMove()
	
	-- Now pull the base velocity back out.   Base velocity is set if you are on a moving object, like a conveyor (or maybe another monster?)
	mv:SetVelocity(mv:GetVelocity() - ply:GetBaseVelocity())
end

local function WalkMove()
	local i
	
	local wishvel = Vector()
	local spd
	local fmove, smove
	local wishdir
	local wishspeed
	
	local dest = Vector()
	local pm
	local forward = mv:GetAngles():Forward()
	local right = mv:GetAngles():Right()
	local up = mv:GetAngles():Up() -- Determine movement angles
	
	local oldground = ply:GetGroundEntity()
	
	-- Copy movement amounts
	fmove = mv:GetForwardSpeed()
	smove = mv:GetSideSpeed()
	
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
	
	for _, i in ipairs {"x", "y", "z"} do -- Determine x and y parts of velocity
		wishvel[i] = forward[i] * fmove + right[i] * smove
	end
	
	wishvel.z = 0 -- Zero out z part of velocity
	
	wishdir = Vector(wishvel) -- Determine maginitude of speed of move
	wishspeed = wishdir:Length()
	wishdir:Normalize()
	
	--
	-- Clamp to server defined max speed
	--
	if wishspeed ~= 0.0 and wishspeed > mv:GetMaxSpeed() then
		wishvel = wishvel * mv:GetMaxSpeed() / wishspeed
		wishspeed = mv:GetMaxSpeed()
	end
	
	-- Set pmove velocity
	local v = mv:GetVelocity()
	v.z = 0
	mv:SetVelocity(v)
	Accelerate(wishdir, wishspeed, GetConVar "sv_accelerate":GetFloat())
	v = mv:GetVelocity()
	v.z = 0
	mv:SetVelocity(v)
	
	-- Add in any base velocity to the current velocity.
	mv:SetVelocity(mv:GetVelocity() + ply:GetBaseVelocity())
	
	spd = mv:GetVelocity():Length()
	
	if spd < 1.0 then
		-- Now pull the base velocity back out.   Base velocity is set if you are on a moving object, like a conveyor (or maybe another monster?)
		mv:SetVelocity(-ply:GetBaseVelocity())
		return
	end
	
	-- first try just moving to the destination	
	dest.x = mv:GetOrigin().x + mv:GetVelocity().x * FrameTime()
	dest.y = mv:GetOrigin().y + mv:GetVelocity().y * FrameTime()	
	dest.z = mv:GetOrigin().z
	
	-- first try moving directly to the next spot
	pm = TracePlayerBBox(mv:GetOrigin(), dest, PlayerSolidMask(), COLLISION_GROUP_PLAYER_MOVEMENT)
	
	-- If we made it all the way, then copy trace end as new player position.
	-- mv.m_outWishVel = mv.m_outWishVel + wishdir * wishspeed

	if pm.Fraction == 1 then
		mv:SetOrigin(pm.HitPos)
		-- Now pull the base velocity back out.   Base velocity is set if you are on a moving object, like a conveyor (or maybe another monster?)
		mv:SetVelocity(mv:GetVelocity() - ply:GetBaseVelocity())
		
		StayOnGround()
		return
	end
	
	-- Don't walk up stairs if not on ground.
	if oldground == NULL and ply:WaterLevel() == 0 then
		-- Now pull the base velocity back out.   Base velocity is set if you are on a moving object, like a conveyor (or maybe another monster?)
		mv:SetVelocity(mv:GetVelocity() - ply:GetBaseVelocity())
		return
	end
	
	-- If we are jumping out of water, don't do anything more.
	-- if ply:GetInternalVariable "m_flWaterJumpTime" ~= 0 then
		-- Now pull the base velocity back out.   Base velocity is set if you are on a moving object, like a conveyor (or maybe another monster?)
		-- mv:SetVelocity(mv:GetVelocity() - ply:GetBaseVelocity())
		-- return
	-- end
	
	StepMove(dest, pm)
	
	-- Now pull the base velocity back out.   Base velocity is set if you are on a moving object, like a conveyor (or maybe another monster?)
	mv:SetVelocity(mv:GetVelocity() - ply:GetBaseVelocity())
	
	StayOnGround()
end

local function WaterMove()
	local i
	local wishvel
	local wishspeed
	local wishdir
	local start, dest
	local temp
	local pm
	local speed, newspeed, addspeed, accelspeed
	local forward = mv:GetAngles():Forward()
	local right = mv:GetAngles():Right()
	local up = mv:GetAngles():Up() -- Determine movement angles
	
	--
	-- user intentions
	--
	for _, i in ipairs {"x", "y", "z"} do
		wishvel[i] = forward[i] * mv:GetForwardSpeed() + right[i] * mv:GetSideSpeed()
	end
	
	-- if we have the jump key down, move us up as well
	if mv:KeyDown(IN_JUMP) then
		wishvel.z = wishvel.z + mv:GetMaxClientSpeed()
	-- Sinking after no other movement occurs
	elseif mv:GetForwardSpeed() == 0 and mv:GetSideSpeed() == 0 and mv:GetUpSpeed() == 0 then
		wishvel.z = wishvel.z - 60 -- drift towards bottom
	else -- Go straight up by upmove amount.
		-- exaggerate upward movement along forward as well
		local upwardMovememnt = mv:GetForwardSpeed() * forward.z * 2
		upwardMovememnt = math.Clamp(upwardMovememnt, 0.0, mv:GetMaxClientSpeed())
		wishvel.z = wishvel.z + mv:GetUpSpeed() + upwardMovememnt
	end
	
	-- Copy it over and determine speed
	wishdir = Vector(wishvel)
	wishspeed = wishdir:Length()
	wishdir:Normalize()
	
	-- Cap speed.
	if wishspeed > mv:GetMaxSpeed() then
		wishvel = wishvel * mv:GetMaxSpeed() / wishspeed
		wishspeed = mv:GetMaxSpeed()
	end
	
	-- Slow us down a bit.
	wishspeed = wishspeed * 0.8
	
	-- Water friction
	temp = Vector(mv:GetVelocity())
	speed = temp:Length()
	temp:Normalize()
	if speed ~= 0 then
		newspeed = speed - FrameTime() * speed * GetConVar "sv_friction":GetFloat() --* ply.m_surfaceFriction
		if newspeed < 0.1 then
			newspeed = 0
		end
		
		mv:SetVelocity(mv:GetVelocity() * newspeed / speed)
	else
		newspeed = 0
	end
	
	-- water acceleration
	if wishspeed >= 0.1 then -- old !
		addspeed = wishspeed - newspeed
		if addspeed > 0 then
			wishvel:Normalize()
			accelspeed = GetConVar "sv_accelerate":GetFloat() * wishspeed * FrameTime() --* ply.m_surfaceFriction
			if accelspeed > addspeed then
				accelspeed = addspeed
			end
			
			local v = mv:GetVelocity()
			for _, i in ipairs {"x", "y", "z"} do
				local deltaSpeed = accelspeed * wishvel[i]
				v[i] = v[i] + deltaSpeed
				-- mv->m_outWishVel[i] += deltaSpeed
			end
			mv:SetVelocity(v)
		end
	end
	
	mv:SetVelocity(mv:GetVelocity() + ply:GetBaseVelocity())
	
	-- Now move
	-- assume it is a stair or a slope, so press down from stepheight above
	dest = mv:GetOrigin() + FrameTime() * mv:GetVelocity()
	
	pm = TracePlayerBBox(mv:GetOrigin(), dest, PlayerSolidMask(), COLLISION_GROUP_PLAYER_MOVEMENT)
	if pm.Fraction == 1.0 then
		start = Vector(dest)
		-- if ply.m_Local.m_bAllowAutoMovement then
			-- start.z = = start.z + ply.m_Local.m_flStepSize + 1
		-- end
		
		pm = TracePlayerBBox(start, dest, PlayerSolidMask(), COLLISION_GROUP_PLAYER_MOVEMENT)
		
		if not (pm.StartSolid or pm.AllSolid) then
			local stepDist = pm.HitPos - mv:GetOrigin().z
			-- mv.m_outStepHeight = mv.m_outStepHeight + stepDist
			-- walked up the step, so just keep result and exit
			mv:SetOrigin(pm.HitPos)
			mv:SetVelocity(mv:GetVelocity() - ply:GetBaseVelocity())
			return
		end
		
		-- Try moving straight along out normal path.
		TryPlayerMove()
	else
		if not ply:GetGroundEntity() then
			TryPlayerMove()
			mv:SetVelocity(mv:GetVelocity() - ply:GetBaseVelocity())
			return
		end
		
		StepMove(dest, pm)
	end
	
	mv:SetVelocity(mv:GetVelocity() - ply:GetBaseVelocity())
end

local function FullWalkMove()
	if not CheckWater() then
		StartGravity()
	end

	-- If we are leaping out of the water, just update the counters.
	-- if ply:GetInternalVariable "m_flWaterJumpTime" then
		-- WaterJump()
		-- TryPlayerMove()
		-- CheckWater() -- See if we are still in water?
		-- return
	-- end

	-- If we are swimming in the water, see if we are nudging against a place we can jump up out
	--  of, and, if so, start out jump.  Otherwise, if we are not moving up, then reset jump timer to 0
	if ply:WaterLevel() >= WL_Waist then
		if ply:WaterLevel() == WL_Waist then
			CheckWaterJump()
		end

		-- If we are falling again, then we must not trying to jump out of water any more.
		-- if mv:GetVelocity().z < 0 and ply:GetInternalVariable "m_flWaterJumpTime" ~= 0 then
			-- ply:SetSaveValue("m_flWaterJumpTime", 0)
		-- end

		-- Was jump button pressed?
		if mv:KeyPressed(IN_JUMP) then
			CheckJumpButton()
		else
			mv:SetOldButtons(bit.band(mv:GetOldButtons(), bit.bnot(IN_JUMP)))
		end

		-- Perform regular water movement
		WaterMove()

		-- Redetermine position vars
		CategorizePosition()

		-- If we are on ground, no downward velocity.
		if ply:GetGroundEntity() ~= NULL then
			local v = mv:GetVelocity() 
			v.z = 0
			mv:SetVelocity(v)
		end
	else -- Not fully underwater
		-- Was jump button pressed?
		if mv:KeyPressed(IN_JUMP) then
 			CheckJumpButton()
		else
			mv:SetOldButtons(bit.band(mv:GetOldButtons(), bit.bnot(IN_JUMP)))
		end

		-- Fricion is handled before we add in any base velocity. That way, if we are on a conveyor, 
		--  we don't slow when standing still, relative to the conveyor.
		if ply:GetGroundEntity() ~= NULL then
			local v = mv:GetVelocity() 
			v.z = 0
			mv:SetVelocity(v)
			Friction()
		end

		-- Make sure velocity is valid.
		CheckVelocity()

		if ply:GetGroundEntity() ~= NULL then
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
		if ply:GetGroundEntity() ~= NULL then
			local v = mv:GetVelocity() 
			v.z = 0
			mv:SetVelocity(v)
		end
		-- CheckFalling()
	end

	-- if m_nOldWaterLevel == WL_NotInWater and ply:WaterLevel() ~= WL_NotInWater or
		-- m_nOldWaterLevel ~= WL_NotInWater and ply:WaterLevel() == WL_NotInWater then
		-- PlaySwimSound()
		-- if not CLIENT then
			-- Splash(ply)
		-- end
	-- end
end

hook.Add("Move", "SplatoonSWEPs: Squid's movement", function(_ply, _mv)
	ply, mv = _ply, _mv
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
	if ply:Crouching() then
		local oldoldbuttons = mv:GetOldButtons()
		local oldflags = ply:GetFlags()
		local oldpos, oldvel = Vector(mv:GetOrigin()), Vector(mv:GetVelocity())
		FullWalkMove()
		local tr = util.TraceHull {
			start = mv:GetOrigin(), endpos = mv:GetOrigin(),
			mins = GetPlayerMins(), maxs = GetPlayerMaxs(),
			mask = MASK_PLAYERSOLID, collisiongroup = COLLISION_GROUP_PLAYER_MOVEMENT,
			filter = ply,
		}
		if tr.Hit then
			ply:SetMoveType(MOVETYPE_NONE)
			return true
		else
			mv:SetOldButtons(oldoldbuttons)
			mv:SetOrigin(oldpos)
			mv:SetVelocity(oldvel)
			ply:RemoveFlags(ply:GetFlags())
			ply:AddFlags(oldflags)
			ply:SetMoveType(MOVETYPE_WALK)
		end
	end
end)

local function WalkMove_Old()
	local friction = GetConVar "sv_friction":GetFloat() * math.max(GetConVar "sv_stopspeed":GetFloat(), speed)
	local accel = GetConVar(ply:OnGround() and "sv_accelerate" or "sv_airaccelerate"):GetFloat()
	local gravity = GetConVar "sv_gravity":GetFloat() * FrameTime()
	local dir = mv:GetMoveAngles()
	dir.p = 0 --Add X, Y component
	dir = dir:Forward() * mv:GetForwardSpeed() + dir:Right() * mv:GetSideSpeed()
	dir = accel * dir * 1e-4 * maxspeed * FrameTime()
	v = v * math.max(0, 1 - friction * FrameTime() / speed) + dir
	
	speed = v:Length()
	if speed > maxspeed then --X, Y speed cap
		v = v * maxspeed / speed
		speed = math.min(speed, maxspeed)
	end
	
	v.z = vz - gravity
	if ply:OnGround() and mv:KeyPressed(IN_JUMP) then
		v.z = v.z + ply:GetJumpPower()
	end
	
	local oldpos = mv:GetOrigin()
	local filter = {ply, w}
	local mins, maxs = ply:GetHullDuck()
	local t = {
		start = oldpos, endpos = oldpos + (v + ply:GetBaseVelocity()) * FrameTime(),
		mins = mins, maxs = maxs, filter = filter, mask = MASK_SHOT_PORTAL,
	}
	
	local onground, groundent, fence = -1
	for i = 1, 4 do
		local tr = util.TraceHull(t)
		if not tr.Hit then break end
		local pull = tr.HitNormal * tr.HitNormal:Dot(tr.HitPos - t.endpos)
		local solidvec = t.endpos + pull - tr.HitPos
		solidvec:Normalize()
		v = solidvec * solidvec:Dot(v)
		t.endpos = t.endpos + pull
		if tr.HitNormal.z > onground then
			onground = tr.HitNormal.z
			groundent = tr.Entity
		end
	end
	
	fence = fence or ss:CheckFence(ply, oldpos, t.endpos, filter, mins, maxs)
	if fence then
		ply:SetMoveType(MOVETYPE_NONE)
	elseif w:GetInFence() and ply:GetMoveType() == MOVETYPE_NOCLIP then
		ply:SetMoveType(MOVETYPE_WALK)
	end
	
	w:SetInFence(tobool(fence))
	if not fence then return end --Player is in fence, then apply
	if onground > .70710678 then
		ply:SetGroundEntity(groundent)
		ply:AddFlags(FL_ONGROUND) --Can land on up to 45 deg slope
	else
		ply:SetGroundEntity()
		ply:RemoveFlags(FL_ONGROUND)
	end
	
	mv:SetVelocity(v)
	mv:SetOrigin(t.endpos)
	return true
end
