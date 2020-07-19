
local dev = GetConVar "developer"
local config = {
    AvoidNPCs = false,
    Benchmark = true,
    CanRappelUp = false,
    CanRappelForward = false,
    CheckCrouching = false,
    ComputePath = false,
    FindCoverPosAll = false,
    FindCoverPosAttempt = false,
    FindCoverPosAttemptAlt = false,
    FindLateralCover = false,
    FindLateralLOS = false,
    FindLOSAll = false,
    FindLOSAttempt = false,
    FindLOSAttemptAlt = false,
    fInterval = false,
    FixPath = false,
    HasInterrupt = false,
    MeleeTrace = false,
    MoveAwayPath = false,
    ScheduleStart = true,
    SelectSchedule = false,
    TaskStart = false,
    TestThrowVec = false,
    UpdateAimParameters = false,
    UpdatePath = true,
}
function ENT:box(category, org, mins, maxs, tick)
    if dev:GetInt() == 0 then return end
    if category and not config[category] then return end
    if not (mins and maxs) then mins, maxs = self:GetHull() end
    debugoverlay.Box(org, mins, maxs, tick and 0.1 or 3, Color(0, 255, 0, 8))
end

function ENT:drawpath()
    if dev:GetInt() == 0 then return end
    if not config["UpdatePath"] then return end
    self.Path:Draw()
end

function ENT:line(category, from, to, tick, ignorez)
    if dev:GetInt() == 0 then return end
    if category and not config[category] then return end
    debugoverlay.Line(from, to, tick and 0.1 or 3, Color(0, 255, 0), ignorez)
end

function ENT:point(category, p, tick, ignorez)
    if dev:GetInt() == 0 then return end
    if category and not config[category] then return end
    debugoverlay.Cross(p, 3, tick and 0.1 or 3, Color(0, 255, 0), ignorez)
end

function ENT:print(category, ...)
    if dev:GetInt() == 0 then return end
    if category and not config[category] then return end
    local args = {}
    for _, a in ipairs {...} do
        if istable(a) then
            PrintTable(a)
        else
            args[#args + 1] = a
        end
    end

	print(self, unpack(args))
end

function ENT:swept(category, from, to, mins, maxs, tick, color)
    if dev:GetInt() == 0 then return end
    if category and not config[category] then return end
    if not (mins and maxs) then mins, maxs = self:GetHull() end
    debugoverlay.SweptBox(from, to, mins, maxs, angle_zero, tick and 0.1 or 3, color or Color(0, 255, 0, 8))
end

function ENT:text(category, org, text, tick, checkz)
    if dev:GetInt() == 0 then return end
    if category and not config[category] then return end
    debugoverlay.Text(org, tostring(text), tick and 0.1 or 3, checkz)
end

function ENT:trace(category, tr, tick)
    if not istable(tr) then return end
    if tr.HitPos then
        self:line(category, tr.StartPos, tr.HitPos, tick)
    elseif tr.maxs then
        self:swept(category, tr.start, tr.endpos, tr.mins, tr.maxs, tick)
    else
        self:line(category, tr.start, tr.endpos, tick)
    end
end

function ENT:vector(category, from, to, tick, ignorez)
    self:line(category, from, from + to, tick, ignorez)
end
