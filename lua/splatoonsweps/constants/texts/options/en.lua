AddCSLuaFile()
return {Options = {
    AvoidWalls = "Avoid walls",
    AvoidWalls_help = "If checked, the weapons try not to waste ink by hitting walls.",
    BecomeSquid = "Become squid",
    BecomeSquid_help = "If checked, you will become squid on crouching.",
    CanHealInk = "Heal in ink",
    CanHealInk_help = "If checked, you can heal yourself when you're in ink.",
    CanHealStand = "Heal when standing",
    CanHealStand_help = "If checked, you can heal yourself gradually when you're out of ink.",
    CanReloadInk = "Reload in ink",
    CanReloadInk_help = "If checked, you can refill your ink tank when you're in ink.",
    CanReloadStand = "Reload when standing",
    CanReloadStand_help = "If checked, you can refill your ink tank gradually when you're out of ink.",
    DoomStyle = "DOOM-like",
    DoomStyle_help = "If checked, the view model will be placed at the center of the screen.",
    DrawCrosshair = "Draw crosshair",
    DrawInkOverlay = "Draw ink overlay",
    DrawInkOverlay_help = "If checked, an water effect will be drawn when you're in ink and first person mode.",
    Enabled = "Enable Splatoon SWEPs",
    FF = "Enable friendly fire",
    Gain = {
        __printname = "Parameters",
        HealSpeedInk = "Heal speed [%] (In ink)",
        HealSpeedStand = "Heal speed [%] (Out of ink)",
        MaxHealth = "Maximum health",
        InkAmount = "Amount of ink",
        ReloadSpeedInk = "Reload speed [%] (In ink)",
        ReloadSpeedStand = "Reload speed [%] (Out of ink)",
    },
    LeftHand = "Left hand mode",
    LeftHand_help = "If checked, the view model will be placed on the left.",
    MoveViewmodel = "Move viewmodel to avoid walls",
    MoveViewmodel_help = 'When "Avoid Walls" is enabled, the view model will be animated.',
    NewStyleCrosshair = "Use Splatoon 2 crosshair",
    NoRefract = "Suppress ink refraction",
    NoRefract_help = "Disables the refraction effect of ink.  Check if you feel a performance issue.",
    ToggleADS = "Toggle ADS instead of holding",
	weapon_splatoonsweps_blaster_base = {
		HurtOwner = "Explosion hurts its owner",
	},
    weapon_splatoonsweps_charger = {
        UseRTScope = "Use realistic scope",
        weapon_splatoonsweps_herocharger = {
            Level = "Hero Charger Level",
        },
    },
    weapon_splatoonsweps_shooter = {
        NZAP_PistolStyle = "N-ZAP: Pistol-like",
        NZAP_PistolStyle_help = "For N-ZAP '83, N-ZAP '85, and N-ZAP '89, you can hold them like HL2 revolver.",
        weapon_splatoonsweps_heroshot = {
            Level = "Hero Shot Level",
        },
        weapon_splatoonsweps_octoshot = {
            Advanced = "Elite Octoshot",
        },
    },
	weapon_splatoonsweps_roller = {
		weapon_splatoonsweps_heroroller = {
            Level = "Hero Roller Level",
        },
	},
}}
