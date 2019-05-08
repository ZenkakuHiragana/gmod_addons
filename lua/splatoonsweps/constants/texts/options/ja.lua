AddCSLuaFile()
return {Options = {
    AvoidWalls = "壁を避けて狙う",
    AvoidWalls_help = "インクが壁に吸われないようにする。",
    BecomeSquid = "イカになる",
    BecomeSquid_help = "しゃがみ時にイカになるか、屈んだヒトになるか。",
    CanHealInk = "インク内でHP回復",
    CanHealInk_help = false,
    CanHealStand = "インク外でHP回復",
    CanHealStand_help = false,
    CanReloadInk = "インク内でインク回復",
    CanReloadInk_help = false,
    CanReloadStand = "インク外でインク回復",
    CanReloadStand_help = false,
    DoomStyle = "DOOMスタイル",
    DoomStyle_help = "一人称視点でブキが中央に配置される。",
    DrawCrosshair = "照準の描画",
    DrawInkOverlay = "インクオーバーレイの描画",
    DrawInkOverlay_help = "一人称視点でインクに潜った時、画面に水のエフェクトがかかる。",
    Enabled = "Splatoon SWEPsの有効化",
    FF = "同士討ちの有効化",
    Gain = {
        __printname = "各種パラメータ",
        HealSpeedInk = "体力回復速度[%] (インク内)",
        HealSpeedStand = "体力回復速度[%] (インク外)",
        MaxHealth = "最大ヘルス",
        InkAmount = "インクタンク容量",
        ReloadSpeedInk = "インク回復速度[%] (インク内)",
        ReloadSpeedStand = "インク回復速度[%] (インク外)",
    },
    LeftHand = "左利き",
    LeftHand_help = "一人称視点でブキが左側に表示される。",
    MoveViewmodel = "壁を避けて狙うとき、ビューモデルを動かす",
    MoveViewmodel_help = "「壁を避けて狙う」が有効のとき、一人称視点で腕が動く。",
    NewStyleCrosshair = "Splatoon 2風の照準",
    NoRefract = "インクの屈折を描画しない",
    NoRefract_help = "インクの下の地面が歪まなくなる。描画が重い場合のオプション。",
    ToggleADS = "アイアンサイト切り替え",
	weapon_splatoonsweps_blaster_base = {
		HurtOwner = "自爆を有効化",
	},
    weapon_splatoonsweps_charger = {
        UseRTScope = "リアルなスコープを使う",
        weapon_splatoonsweps_herocharger = {
            Level = "ヒーローチャージャーのレベル",
        },
    },
    weapon_splatoonsweps_shooter = {
        NZAP_PistolStyle = "N-ZAP: ピストル風",
        NZAP_PistolStyle_help = "N-ZAP83、N-ZAP85、N-ZAP89において、一人称視点で拳銃の持ち方をする。",
        weapon_splatoonsweps_heroshot = {
            Level = "ヒーローシューターのレベル",
        },
        weapon_splatoonsweps_octoshot = {
            Advanced = "オクタシューター: 上級タコゾネス仕様",
        },
    },
	weapon_splatoonsweps_roller = {
		weapon_splatoonsweps_heroroller = {
            Level = "ヒーローローラーのレベル",
        },
	},
}}
