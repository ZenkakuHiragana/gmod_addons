
local ss = SplatoonSWEPs
if not ss then return end
SWEP.Base = "weapon_splatoonsweps_shooter"

function SWEP:SharedPrimaryAttack(able)
	local p = self.Primary
	local timescale = ss.GetTimeScale(self.Owner)
    local prefiredelay = self:Crouching() and p.PreFireDelaySquid or p.PreFireDelay
	self:SetNextPrimaryFire(CurTime() + p.Delay / timescale)
	self:SetAimTimer(CurTime() + prefiredelay / timescale)
	self:SetCooldown(math.max(self:GetCooldown(), CurTime() + prefiredelay / timescale))
    self:SetFireDelay(CurTime() + prefiredelay / timescale)
end

function SWEP:Move(ply)
    self:GetBase().Move(self, ply)
    if CurTime() < self:GetFireDelay() then return end
    if self.CannotStandup then return end

    local p = self.Primary
    local timescale = ss.GetTimeScale(ply)
    local d = p.PostFireDelay / timescale
    local r = p.ReloadDelay / timescale
    self:SetFireDelay(math.huge)
	self.ReloadSchedule:SetDelay(r) -- Stop reloading ink
	self.ReloadSchedule:SetLastCalled(CurTime() + r)
    if self:GetInk() < p.TakeAmmo then
        d = p.PreFireDelay / timescale
        self:PlayEmptySound()
        self:SetCooldown(math.max(self:GetCooldown(), CurTime() + d))
        self:SetAimTimer(math.max(self:GetAimTimer(true), CurTime() + d))
        return
    end

    self:CreateInk()
    self:SetInk(math.max(0, self:GetInk() - p.TakeAmmo))
    self:SetCooldown(math.max(self:GetCooldown(), CurTime() + d))
    self:SetAimTimer(CurTime() + d)
end

function SWEP:UpdateAnimation(ply, min, max) end
function SWEP:CustomDataTables()
    self:GetBase().CustomDataTables(self)
    self:AddNetworkVar("Float", "FireDelay")
    self:SetFireDelay(math.huge)
    local getaimtimer = self.GetAimTimer
    function self:GetAimTimer(org) -- This is needed when it's firing continuously.
        local a = getaimtimer(self)
        if org then return a end
        if CurTime() > self:GetFireDelay() then return a end
        if CurTime() > self:GetNextPrimaryFire() then return a end
        if self:GetKey() ~= IN_ATTACK then return a end
        return math.huge
    end
end
