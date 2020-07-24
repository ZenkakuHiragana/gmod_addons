
local function GetYawRatio(yaw)
    local yaw = math.abs(yaw) % 90
    if yaw > 45 then yaw = 90 - yaw end
    return math.Remap(yaw, 0, 45, 0.5, 1 / math.sqrt(2))
end

function ENT:GetMins()
	return self.CollisionBoundMins * GetYawRatio(self:GetAngles().yaw)
end

function ENT:GetMaxs(stand)
    local maxs = stand and self.CollisionBoundMaxs or self.CollisionBoundMaxsCrouched
	return maxs * GetYawRatio(self:GetAngles().yaw)
end

function ENT:GetHull(stand)
	return self:GetMins(), self:GetMaxs(not self.Crouching)
end

function ENT:TraceHull(from, to, mask, filter, collisiongroup, stand)
    local from = from or self:GetPos()
    local mins, maxs = self:GetHull(stand)
    local TRACE_DELTA_Z = vector_up * self.loco:GetStepHeight()
	return util.TraceHull {
		start = from + TRACE_DELTA_Z,
		endpos = (to or from) + TRACE_DELTA_Z,
		collisiongroup = collisiongroup,
		filter = table.Add({self}, filter),
		mask = mask or MASK_NPCSOLID,
		maxs = maxs,
		mins = mins,
	}
end

function ENT:TraceHullStand(from, to, mask, filter, collisiongroup)
	return self:TraceHull(from, to, mask, filter, collisiongroup, true)
end

function ENT:GetAxes()
    local p = self.Path
    local f = self:GetForward()
    if p:IsValid() then f = p:GetCursorData().forward end
    local d = math.Rand(-45, 45)
    local a = Angle()
    local u = self:GetUp()
    a:RotateAroundAxis(u, -90 + d)
    local r = Vector(f)
    r:Rotate(a)
    local fl = Vector(f)
    local fr = Vector(f)
    a = Angle()
    a:RotateAroundAxis(u, 45 + d)
    fl:Rotate(a)
    a = Angle()
    a:RotateAroundAxis(u, -45 + d)
    fr:Rotate(a)
    return f, r, fl, fr
end

function ENT:TraceHullAround(distance, collisiongroup, mask)
    local d = distance or 5
    local TRACE_DELTA_Z = vector_up * self.loco:GetStepHeight()
    local org = self:GetPos() + TRACE_DELTA_Z
    local f, r, fl, fr = self:GetAxes()
    local t = {
        start = org,
        collisiongroup = collisiongroup,
        filter = self,
        mask = mask or MASK_NPCSOLID,
        maxs = self:GetMaxs(),
        mins = self:GetMins(),
    }
    t.endpos = org + fl * d
    self:swept("FixPath", t.start, t.endpos, t.mins, t.maxs)
    local tfl = util.TraceHull(t)
    t.endpos = org + fr * d
    self:swept("FixPath", t.start, t.endpos, t.mins, t.maxs)
    local tfr = util.TraceHull(t)
    t.endpos = org - fr * d
    self:swept("FixPath", t.start, t.endpos, t.mins, t.maxs)
    local tbl = util.TraceHull(t)
    t.endpos = org - fl * d
    self:swept("FixPath", t.start, t.endpos, t.mins, t.maxs)
    local tbr = util.TraceHull(t)

    return {
        ForwardLeft = tfl,
        ForwardRight = tfr,
        BackwardLeft = tbl,
        BackwardRight = tbr,
    }
end

function ENT:GetHitDirectionAround(t, ...)
    local t = t or self:TraceHullAround(...)
    local dirID =
    (t.ForwardLeft.Hit and 1 or 0) +
    (t.ForwardRight.Hit and 2 or 0) +
    (t.BackwardLeft.Hit and 4 or 0) +
    (t.BackwardRight.Hit and 8 or 0)
    if dirID == 0 then return Vector() end
    local f, r, fl, fr = self:GetAxes()
    return ({fl, fr, f, -fr, -r, Vector(), fl, -fl, Vector(), r, fr, -f, -fr, -fl, Vector()})[dirID]
end

function ENT:GetTraceToLastPos()
    return util.TraceLine {
        start = self:EyePos(),
        endpos = self:GetLastPosition(),
        mask = MASK_BLOCKLOS,
        filter = self,
    }
end
