AddCSLuaFile()
return {CVars = {
    AvoidWalls = "Prevent SWEPs from shooting at wall wastfully. (1: enabled, 0: disabled)",
    BecomeSquid = "Become squid on crouching. (1: enabled, 0: disabled)",
    CanHealInk = "Heal yourself when you are in ink. (1: enabled, 0: disabled)",
    CanHealStand = "Heal yourself when you are out of ink. (1: enabled, 0: disabled)",
    CanReloadInk = "Reload your ink when you are in ink. (1: enabled, 0: disabled)",
    CanReloadStand = "Reload your ink when you are out of ink. (1: enabled, 0: disabled)",
    Clear = "Clear all ink in the map.",
    DoomStyle = "Bring the weapon viewmodel to the center of the screen. (1: enabled, 0: disabled)",
    DrawCrosshair = "Draw Splatoon-like crosshair. (1: enabled, 0: disabled)",
    DrawInkOverlay = "Draw ink overlay in firstperson. (1: enabled, 0: disabled)",
    Enabled = "Enable or disable Splatoon SWEPs. (1: enabled, 0: disabled)",
    FF = "Enable friendly fire. (1: enabled, 0: disabled)",
    InkColor = "Your ink color.  Available values are:\n",
    LeftHand = "Use left hand to hold weapons. (1: enabled, 0: disabled)",
    MoveViewmodel = "Move viewmodel when avoid setting is enabled. (1: enabled, 0: disabled)",
    NewStyleCrosshair = "Make crosshair act like Splatoon 2. (1: enabled, 0: disabled)",
    NoRefract = "Don't draw the refraction effect of ink. (1: don't draw, 0: draw)",
    Playermodel = "Your thirdperson model.  Available values are:\n",
    RTResolution = [[The resolution of RenderTarget used in ink system.
To apply the change, restart your GMOD client.
Higher option needs more VRAM.
Make sure your graphics card has enough space of video memory.
0: If your client has crashed while SplatoonSWEPs is loading, this value is set.
    The resolution is 2048x2048, and the VRAM usage is 32MB.
1: RT has 4096x4096 resolution.
    This option uses 128MB of your VRAM.
2: RT has 2x4096x4096 resolution.
    The resolution is twice as large as option 1.
    This option uses 256MB of your VRAM.
3: 8192x8192, using 512MB.
4: 2x8192x8192, 1GB.
5: 16384x16384, 2GB.
6: 2x16384x16384, 4GB.
7: 32768x32768, 8GB.
8: 2x32768x32768, 16GB.]],
    ToggleADS = "Aim down sight mode. (1: toggle, 0: hold)",
	weapon_splatoonsweps_blaster_base = {
		HurtOwner = "If enabled, inkling will be injured by his/her blaster's explosion. (1: enabled, 0: disabled)",
	},
    weapon_splatoonsweps_charger = {
        UseRTScope = "For scoped chargers, use realistic scope instead of standard scope effect. (1: enabled, 0: disabled)",
        weapon_splatoonsweps_herocharger = {
            Level = "The level of Hero Charger Replica. (0, 1, 2, 3 -> Level 1, 2, 3, 4)",
        },
    },
    weapon_splatoonsweps_shooter = {
        weapon_splatoonsweps_heroshot = {
            Level = "The level of Hero Shot Replica. (0, 1, 2, 3 -> Level 1, 2, 3, 4)",
        },
        weapon_splatoonsweps_octoshot = {
            Advanced = "Skin color for Octoshot Replica. (set to 0 for standard octalian's weapon color, 1 for elite octalian's)",
        },
        weapon_splatoonsweps_nzap85 = {
            PistolStyle = "Hold N-ZAP '85 like a pistol instead of a rifle. (1: enabled, 0: disabled)",
        },
        weapon_splatoonsweps_nzap89 = {
            PistolStyle = "Hold N-ZAP '89 like a pistol instead of a rifle. (1: enabled, 0: disabled)",
        },
        weapon_splatoonsweps_nzap83 = {
            PistolStyle = "Hold N-ZAP '83 like a pistol instead of a rifle. (1: enabled, 0: disabled)",
        },
    },
}}