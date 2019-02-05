
AddCSLuaFile()
local ss = SplatoonSWEPs
if not (ss and SWEP) then return end
SWEP.ADSAngOffset = Angle(0, 0, 0)
SWEP.ADSOffset = Vector(0, 0, 1.5)
SWEP.ShootSound = "SplatoonSWEPs.Splattershot"
SWEP.Sub = "burstbomb"
SWEP.Special = "bombrush"
SWEP.Variations = {
	{
		Customized = true,
		ClassName = "weapon_splattershot_tentatek",
		Sub = "suctionbomb",
		Special = "inkzooka",
		Skin = 1,
	},
	{
		SheldonsPicks = true,
		ClassName = "weapon_splattershot_wasabi",
		Sub = "splatbomb",
		Special = "inkstrike",
		Skin = 2,
	},
	{
		ClassName = "weapon_heroshot",
		SharedThink = Either(SERVER, nil, function(self)
			ss.ProtectedCall(self.BaseClass.SharedThink, self)
			self.Skin = self:GetNWInt("level", ss.Options[self.Base][self.ClassName].Level)
		end),
	},
	{
		ClassName = "weapon_octoshot",
		ShootSound = "SplatoonSWEPs.Octoshot",
		Sub = "suctionbomb",
		Special = "inkzooka",
		Skin = 1,
		SharedThink = Either(SERVER, nil, function(self)
			ss.ProtectedCall(self.BaseClass.SharedThink, self)
			self.Skin = self:GetNWBool("advanced", ss.Options[self.Base][self.ClassName].Advanced)
			self.Skin = self.Skin and 1 or 0
		end),
	},
}

ss.SetPrimary(SWEP, {
	IsAutomatic			= true,		-- false to semi-automatic
	Recoil				= .2,		-- Viewmodel recoil intensity[-]
	TakeAmmo			= .009,		-- Ink consumption per fire[-]
	Damage				= .36,		-- Maximum damage[-]
	MinDamage			= .18,		-- Minimum damage[-]
	InkRadius			= 19.2,		-- Painting radius[Splatoon units]
	MinRadius			= 18,		-- Minimum painting radius[Splatoon units]
	SplashRadius		= 13,		-- Painting radius[Splatoon units]
	SplashPatterns		= 5,		-- Paint patterns[-]
	SplashNum			= 2,		-- Number of splashes[-]
	SplashInterval		= 75,		-- Make an interval on each splash[Splatoon units]
	Spread				= 6,		-- Aim cone[deg]
	SpreadJump			= 15,		-- Aim cone while jumping[deg]
	SpreadBias			= .25,		-- Aim cone random bias[-]
	SpreadBiasStep		= .02,		-- Aim cone random bias initial value and step[-]
	SpreadBiasJump		= .4,		-- Aim cone random bias while jumping[-]
	MoveSpeed			= .72,		-- Walk speed while shooting[Splatoon units/frame]
	InitVelocity		= 22,		-- Ink initial velocity[Splatoon units/frame]	
	Delay = {
		Aim				= 20,		-- Change hold type[frames]
		Fire			= 6,		-- Fire rate[frames]
		Reload			= 20,		-- Start reloading after firing weapon[frames]
		Crouch			= 6,		-- Cannot crouch for some frames after firing[frames]
		Straight		= 4,		-- Ink goes without gravity[frames]
		MinDamage		= 15,		-- Deals minimum damage[frames]
		DecreaseDamage	= 8,		-- Start decreasing damage[frames]
		SpreadJump		= 60,		-- Time to get spread angle back to normal[frames]
	},
})
