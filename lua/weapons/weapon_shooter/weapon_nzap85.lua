
AddCSLuaFile()
local ss = SplatoonSWEPs
if not (ss and SWEP) then return end
SWEP.ADSAngOffset = Angle(1.5, 0, 0)
SWEP.ADSAngOffset2= Angle(2, 0, 0)
SWEP.ADSOffset = Vector(-6, 0, 4.5)
SWEP.ADSOffset2 = Vector(-8, .04, 2.93)
SWEP.ShootSound = "SplatoonSWEPs.Zap"
SWEP.Sub = "splatbomb"
SWEP.Special = "echolocator"
SWEP.Variations = {
	{
		Customized = true,
		ClassName = "weapon_nzap89",
		Sub = "sprinkler",
		Special = "inkstrike",
		Skin = 1,
	},
	{
		SheldonsPicks = true,
		ClassName = "weapon_nzap83",
		Sub = "pointsensor",
		Special = "kraken",
		Skin = 2,
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

local function SetViewModel(self)
	if not IsValid(self.Owner) then return end
	local vm = self.Owner:GetViewModel()
	if not IsValid(vm) then return end
	local pistol = self:GetNWBool "pistolstyle"
	self.ViewModel = string.format("%sc_viewmodel%s.mdl", self.ModelPath, pistol and "2" or "")
	vm:SetWeaponModel(self.ViewModel, self)
end

function SWEP:SharedInit()
	ss.ProtectedCall(self.BaseClass.SharedInit, self)
	SetViewModel(self)
	self:AddSchedule(0, function(self, schedule)
		if tobool(self.ViewModel:find "2") ~= self:GetNWBool "pistolstyle" then
			SetViewModel(self)
		end
	end)
end

function SWEP:SharedDeploy()
	ss.ProtectedCall(self.BaseClass.SharedDeploy, self)
	SetViewModel(self)
end

function SWEP:CustomActivity()
	local armpos = ss.ProtectedCall(self.BaseClass.CustomActivity, self)
	if not armpos then return end
	if self:GetNWBool "pistolstyle" then
		return "revolver"
	end
	
	return armpos
end

if SERVER then return end
function SWEP:GetArmPos()
	local armpos = self.BaseClass.GetArmPos(self)
	if not armpos then return end
	local pistol = self:GetNWBool "pistolstyle"
	local offset = pistol and self.ADSOffset2 or self.ADSOffset
	local ang = pistol and self.ADSAngOffset2 or self.ADSAngOffset
	self.IronSightsPos[6] = self.IronSightsPos[5] + offset
	self.IronSightsAng[6] = self.IronSightsAng[5] + ang
	return 6
end
