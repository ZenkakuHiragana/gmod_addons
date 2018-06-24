
-- Functions for weapon settings.

local ss = SplatoonSWEPs
if not ss then return end

function ss:SetPrimary(weapon, info)
	local p = istable(weapon.Primary) and weapon.Primary or {}
	p.ClipSize = ss.MaxInkAmount --Clip size only for displaying.
	p.DefaultClip = ss.MaxInkAmount
	p.Automatic = info.IsAutomatic or false
	p.Ammo = "Ink"
	p.Delay = info.Delay.Fire * ss.FrameToSec
	p.Recoil = info.Recoil or .2
	p.ReloadDelay = info.Delay.Reload * ss.FrameToSec
	p.TakeAmmo = info.TakeAmmo * ss.MaxInkAmount
	p.PlayAnimPercent = info.PlayAnimPercent
	p.CrouchDelay = info.Delay.Crouch * ss.FrameToSec
	ss:ProtectedCall(ss.CustomPrimary[weapon.Base], p, info)
	weapon.Primary = p
end

function ss:SetSecondary(weapon, info)
	local s = istable(weapon.Secondary) and weapon.Secondary or {}
	s.ClipSize = -1
	s.DefaultClip = -1
	s.Automatic = info.IsAutomatic or false
	s.Ammo = "Ink"
	s.Delay = info.Delay.Fire * ss.FrameToSec
	s.Recoil = info.Recoil or .2
	s.ReloadDelay = info.Delay.Reload * ss.FrameToSec
	s.TakeAmmo = info.TakeAmmo * ss.MaxInkAmount
	s.PlayAnimPercent = info.PlayAnimPercent
	s.CrouchDelay = info.Delay.Crouch * ss.FrameToSec
	ss:ProtectedCall(ss.CustomSecondary[weapon.Base], s, info)
	weapon.Secondary = s
end

ss.CustomPrimary = {}
ss.CustomSecondary = {}
function ss.CustomPrimary.weapon_shooter(p, info)
	p.Straight = info.Delay.Straight * ss.FrameToSec
	p.Damage = info.Damage * ss.ToHammerHealth
	p.MinDamage = info.MinDamage * ss.ToHammerHealth
	p.InkRadius = info.InkRadius * ss.ToHammerUnits
	p.MinRadius = info.MinRadius * ss.ToHammerUnits
	p.SplashRadius = info.SplashRadius * ss.ToHammerUnits
	p.SplashPatterns = info.SplashPatterns
	p.SplashNum = info.SplashNum
	p.SplashInterval = info.SplashInterval * ss.ToHammerUnits
	p.Spread = info.Spread
	p.SpreadJump = info.SpreadJump
	p.SpreadBias = info.SpreadBias
	p.MoveSpeed = info.MoveSpeed * ss.ToHammerUnitsPerSec
	p.MinDamageTime = info.Delay.MinDamage * ss.FrameToSec
	p.DecreaseDamage = info.Delay.DecreaseDamage * ss.FrameToSec
	p.InitVelocity = info.InitVelocity * ss.ToHammerUnitsPerSec
	p.FirePosition = info.FirePosition
	p.AimDuration = info.Delay.Aim * ss.FrameToSec
	p.ColRadius = info.ColRadius or ss.mColRadius
	p.Range = p.InitVelocity * (p.Straight + 2.5 * ss.FrameToSec)
	p.RangeSqr = p.Range^2
	
	if not info.Delay.TripleShot then return end
	p.TripleShotDelay = info.Delay.TripleShot * ss.FrameToSec
end

function ss.CustomSecondary.weapon_shooter(p, info)
end

function ss:SetViewModelMods(weapon, mods)
	weapon.ViewModelBoneMods = weapon.ViewModelBoneMods or {}
	for bone, mod in pairs(mods) do
		weapon.ViewModelBoneMods[bone] = mod
	end
end

function ss:SetViewModel(weapon, view)
	weapon.VElements = weapon.VElements or {}
	weapon.VElements.weapon = {
		type = "Model",
		model = Model(view.model),
		bone = view.bone or "ValveBiped.Bip01_Spine4",
		rel = "",
		pos = view.pos,
		angle = view.angle,
		size = view.size or ss.vector_one,
		color = color_white,
		surpresslightning = false,
		material = "",
		skin = view.skin or 0,
		bodygroup = view.bodygroup or {},
	}
end

function ss:SetWorldModel(weapon, world)
	weapon.WElements = weapon.WElements or {}
	weapon.WElements.weapon = {
		type = "Model",
		model = Model(world.model),
		bone = world.bone or "ValveBiped.Bip01_R_Hand",
		rel = "",
		pos = world.pos,
		angle = world.angle,
		size = world.size or ss.vector_one,
		color = color_white,
		surpresslightning = false,
		material = "",
		skin = world.skin or 0,
		bodygroup = world.bodygroup or {},
	}
end
