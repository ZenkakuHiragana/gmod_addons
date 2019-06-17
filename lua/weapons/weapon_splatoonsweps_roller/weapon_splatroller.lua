
AddCSLuaFile()
local ss = SplatoonSWEPs
if not (ss and SWEP) then return end
SWEP.PreSwingSound = "SplatoonSWEPs.RollerPreSwing"
SWEP.SwingSound = "SplatoonSWEPs.RollerSwing"
SWEP.SplashSound = "SplatoonSWEPs.RollerSplashLight"
SWEP.RollSound = ss.SplatRollerRoll
SWEP.Special = "killerwail"
SWEP.Sub = "suctionbomb"
SWEP.Variations = {
	{
		Customized = true,
		Bodygroup = {nil, 1},
		Special = "kraken",
		Sub = "squidbeakon",
		Suffix = "krakon",
	},
	{
		ClassName = "splatroller_corocoro",
		SheldonsPicks = true,
		Special = "inkzooka",
		Sub = "splashwall",
	},
	{
		ClassName = "heroroller",
		IsHeroWeapon = true,
	},
}

ss.SetPrimary(SWEP, {
	mSwingLiftFrame = 20,
	mSplashNum = 12,
	mSplashInitSpeedBase = 8.2,
	mSplashInitSpeedRandomZ = 3,
	mSplashInitSpeedRandomX = 0.4,
	mSplashInitVecYRate = 0,
	mSplashDeg = 2.2,
	mSplashSubNum = 0,
	mSplashSubInitSpeedBase = 17.5,
	mSplashSubInitSpeedRandomZ = 3.5,
	mSplashSubInitSpeedRandomX = 0,
	mSplashSubInitVecYRate = 0,
	mSplashSubDeg = 7,
	mSplashPositionWidth = 8,
	mSplashInsideDamageRate = 0.4,
	mCorePaintWidthHalf = 26,
	mCorePaintSlowMoveWidthHalf = 13,
	mSlowMoveSpeed = 0,
	mCoreColWidthHalf = 10,
	mInkConsumeCore = 0.001,
	mInkConsumeSplash = 0.09,
	mInkRecoverCoreStop = 20,
	mInkRecoverSplashStop = 45,
	mMoveSpeed = 1.2,
	mCoreColRadius = 4,
	mCoreDamage = 1.4,
	mTargetEffectScale = 1.5,
	mTargetEffectVelRate = 1.2,
	mSplashStraightFrame = 4,
	mSplashDamageMaxDist = 45,
	mSplashDamageMinDist = 100,
	mSplashDamageMaxValue = 1.25,
	mSplashDamageMinValue = 0.25,
	mSplashOutsideDamageMaxDist = 95,
	mSplashOutsideDamageMinDist = 105,
	mSplashOutsideDamageMaxValue = 0.5,
	mSplashOutsideDamageMinValue = 0.25,
	mSplashDamageRateBias = 1,
	mSplashDrawRadius = 3,
	mSplashPaintNearD = 10,
	mSplashPaintNearR = 20,
	mSplashPaintFarD = 200,
	mSplashPaintFarR = 17,
	mSplashCollisionRadiusForField = 6,
	mSplashCollisionRadiusForPlayer = 8.5,
	mSplashCoverApertureFreeFrame = -1,
	mSplashSubStraightFrame = 4,
	mSplashSubDamageMaxDist = 45,
	mSplashSubDamageMinDist = 100,
	mSplashSubDamageMaxValue = 1.25,
	mSplashSubDamageMinValue = 0.25,
	mSplashSubDamageRateBias = 1,
	mSplashSubDrawRadius = 3,
	mSplashSubPaintNearD = 10,
	mSplashSubPaintNearR = 18,
	mSplashSubPaintFarD = 200,
	mSplashSubPaintFarR = 15,
	mSplashSubCollisionRadiusForField = 9,
	mSplashSubCollisionRadiusForPlayer = 9,
	mSplashSubCoverApertureFreeFrame = -1,
	mSplashPaintType = 1,
	mArmorTypeObjectDamageRate = 0.4,
	mArmorTypeGachihokoDamageRate = 0.3,
	mPaintBrushType = false,
	mPaintBrushRotYDegree = 0,
	mPaintBrushSwingRepeatFrame = 6,
	mPaintBrushNearestBulletLoopNum = 6,
	mPaintBrushNearestBulletOrderNum = 2,
	mPaintBrushNearestBulletRadius = 20,
	mDropSplashDrawRadius = 0.5,
	mDropSplashPaintRadius = 0,
})
