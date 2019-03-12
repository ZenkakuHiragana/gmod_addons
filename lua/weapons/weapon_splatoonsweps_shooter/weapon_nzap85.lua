
AddCSLuaFile()
local ss = SplatoonSWEPs
if not (ss and SWEP) then return end
SWEP.ADSAngOffset = Angle(1.5, 0, 0)
SWEP.ADSAngOffset2= Angle(2, 0, 0)
SWEP.ADSOffset = Vector(-6, 0, 4.5)
SWEP.ADSOffset2 = Vector(-8, .04, 2.93)
SWEP.ShootSound = "SplatoonSWEPs.Zap"
SWEP.Special = "echolocator"
SWEP.Sub = "splatbomb"
SWEP.Variations = {
	{
		ClassName = "nzap89",
		Customized = true,
		Skin = 1,
		Special = "inkstrike",
		Sub = "sprinkler",
	},
	{
		ClassName = "nzap83",
		SheldonsPicks = true,
		Skin = 2,
		Special = "kraken",
		Sub = "pointsensor",
	},
}

ss.SetPrimary(SWEP, {
	IsAutomatic			= true,		-- false to semi-automatic
	Recoil				= .2,		-- Viewmodel recoil intensity[-]
	TakeAmmo			= .008,		-- Ink consumption per fire[-]
	Damage				= .28,		-- Maximum damage[-]
	MinDamage			= .14,		-- Minimum damage[-]
	InkRadius			= 19.2,		-- Painting radius[Splatoon units]
	MinRadius			= 18,		-- Minimum painting radius[Splatoon units]
	SplashRadius		= 12,		-- Painting radius[Splatoon units]
	SplashPatterns		= 11,		-- Paint patterns[-]
	SplashNum			= 1.5,		-- Number of splashes[-]
	SplashInterval		= 110,		-- Make an interval on each splash[Splatoon units]
	Spread				= 12,		-- Aim cone[deg]
	SpreadJump			= 18,		-- Aim cone while jumping[deg]
	SpreadBias			= .25,		-- Aim cone random component[deg]
	SpreadBiasStep		= .02,		-- Aim cone random bias initial value and step[-]
	SpreadBiasJump		= .4,		-- Aim cone random bias while jumping[-]
	MoveSpeed			= .72,		-- Walk speed while shooting[Splatoon units/frame]
	InitVelocity		= 22,		-- Ink initial velocity[Splatoon units/frame]
	Delay = {
		Aim				= 20,		-- Change hold type[frames]
		Fire			= 5,		-- Fire rate[frames]
		Reload			= 20,		-- Start reloading after firing weapon[frames]
		Crouch			= 6,		-- Cannot crouch for some frames after firing[frames]
		Straight		= 4,		-- Ink goes without gravity[frames]
		MinDamage		= 15,		-- Deals minimum damage[frames]
		DecreaseDamage	= 8,		-- Start decreasing damage[frames]
		SpreadJump		= 60,		-- Time to get spread angle back to normal[frames]
	},
})

local function RefreshViewModel(self)
	if not (IsValid(self.Owner) and self.Owner:IsPlayer()) then return end
	local ispistol = self:GetNWBool "nzap_pistolstyle"
	local mdl = ispistol and self.ViewModel1 or self.ViewModel0
	local vm = self:GetViewModel()
    if not IsValid(vm) then return end
    if vm:GetModel() == mdl then return end
    if not self:IsFirstTimePredicted() then return end
    local cycle = vm:GetCycle()
    local rate = vm:GetPlaybackRate()
    local seq = vm:GetSequence()
    vm:SetWeaponModel(mdl, self)
    vm:SendViewModelMatchingSequence(seq)
    vm:SetPlaybackRate(rate)
    vm:SetCycle(cycle)
    self.ViewModel = mdl
end

function SWEP:SharedDeploy()
	ss.ProtectedCall(self.BaseClass.SharedDeploy, self)
	RefreshViewModel(self)
end

function SWEP:Move(ply)
    ss.ProtectedCall(self.BaseClass.Move, self, ply)
    RefreshViewModel(self)
end

function SWEP:CustomActivity()
	local armpos = ss.ProtectedCall(self.BaseClass.CustomActivity, self)
	if not armpos then return end
	if self:GetNWBool "nzap_pistolstyle" then return "revolver" end
	return armpos
end

if SERVER then return end
function SWEP:GetArmPos()
	local armpos = ss.ProtectedCall(self.BaseClass.GetArmPos, self)
	if not armpos then return end
	local pistol = self:GetNWBool "nzap_pistolstyle"
	local offset = pistol and self.ADSOffset2 or self.ADSOffset
	local ang = pistol and self.ADSAngOffset2 or self.ADSAngOffset
	self.IronSightsPos[6] = self.IronSightsPos[5] + offset
	self.IronSightsAng[6] = self.IronSightsAng[5] + ang
	return 6
end
