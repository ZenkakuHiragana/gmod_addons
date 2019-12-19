AddCSLuaFile()
return {CVars = {
    AvoidWalls = "インクが壁に吸い付かないようにする。 (1: 有効 0: 無効)",
    BecomeSquid = "しゃがんだ時にイカになる。 (1: 有効 0: 無効)",
    CanHealInk = "インクの中で体力が回復する。 (1: 有効 0: 無効)",
    CanHealStand = "インクの外で体力が回復する。 (1: 有効 0: 無効)",
    CanReloadInk = "インクの中でインクが回復する。 (1: 有効 0: 無効)",
    CanReloadStand = "インクの外でインクが回復する。 (1: 有効 0: 無効)",
    Clear = "マップ上のすべてのインクを消去する。",
    DoomStyle = "ビューモデルを画面中央に置く (1: 有効 0: 無効)",
    DrawCrosshair = "スプラトゥーン風の照準を描画する。 (1: 有効 0: 無効)",
    DrawInkOverlay = "一人称視点でインクのオーバーレイを描画する。 (1: 有効 0: 無効)",
    Enabled = "Splatoon SWEPsを有効化する。 (1: 有効 0: 無効)",
    FF = "同士討ちを有効にする。 (1: 有効 0: 無効)",
    Gain = {
        HealSpeedInk = "インク内における体力回復速度の倍率。 例えば200を設定すると体力回復にかかる時間が半分になる。",
        HealSpeedStand = "インク外における体力回復速度の倍率。 例えば200を設定すると体力回復にかかる時間が半分になる。",
        MaxHealth = "インクリングの最大ヘルス。",
        InkAmount = "インクタンクの容量。",
        ReloadSpeedInk = "インク内におけるインク回復速度の倍率。 例えば200を設定するとインク回復にかかる時間が半分になる。",
        ReloadSpeedStand = "インク外におけるインク回復速度の倍率。 例えば200を設定するとインク回復にかかる時間が半分になる。",
    },
    HideInk = "マップに塗られたインクを非表示にする。 (1: 有効, 0: 無効)",
    InkColor = "インクの色を設定する。使用可能な値は以下の通り。:\n",
    LeftHand = "左手でブキを構える。 (1: 有効, 0: 無効)",
    MoveViewmodel = "壁を避けて狙う時、ビューモデルを動かす。 (1: 有効 0: 無効)",
    NewStyleCrosshair = "照準の動き方をスプラトゥーン2に合わせる。 (1: 有効 0: 無効)",
    NoRefract = "インクの屈折エフェクトを描画しないようにする。 (1: 描画しない 0: 描画する)",
    NPCInkColor = {
        Citizen = "市民のインクの色。",
        Combine = "コンバインのインクの色。",
		Military = "「軍隊」に属するNPCのインクの色。",
		Zombie = "ゾンビのインクの色。",
		Antlion = "アントライオンのインクの色。",
		Alien = "エイリアンのインクの色。",
		Barnacle = "バーナクルのインクの色。",
        Others = "その他のNPCのインクの色。",
    },
    Playermodel = "三人称モデル。使用可能な値は以下の通り。:\n",
    ResetCamera = "スプラトゥーンのYボタンに相当するカメラリセットコマンド。",
    RTResolution = [[インクの描画システムで用いるRenderTargetの設定。
この変更を反映するにはGMODの再起動を必要とする。
また、高解像度になるほど多くのVRAM容量が要求される。
ビデオメモリの容量が十分にあることを確認してから変更することを推奨する。
0: SplatoonSWEPsのロード中にクラッシュした場合の値である。
    解像度は2048x2048、VRAM使用量は32MBである。
1: RTの解像度は4096x4096である。
    このオプションは128MBのVRAMを必要とする。
2: RTの解像度は2x4096x4096である。
    オプション1の2倍の面積に等しい解像度を持つ。
    このオプションは256MBのVRAMを必要とする。
3: 8192x8192、512MB。
4: 2x8192x8192、1GB。
5: 16384x16384、2GB。
6: 2x16384x16384、4GB。
7: 32768x32768、8GB。
8: 2x32768x32768、16GB。]],
    TakeFallDamage = "ブキを持っている時、落下ダメージを受けるかどうか。 (1: 受ける, 0: 受けない)",
    ToggleADS = "アイアンサイト切り替え(1)/ホールド(0)",
	weapon_splatoonsweps_blaster_base = {
		HurtOwner = "ブラスターの爆風で自爆するかどうか。 (1: 有効, 0: 無効)",
	},
    weapon_splatoonsweps_charger = {
        UseRTScope = "スコープ付きチャージャーで、リアルなスコープを使う。 (1: 有効, 0: 無効)",
        weapon_splatoonsweps_herocharger = {
            Level = "ヒーローチャージャーレプリカのレベル。 (0, 1, 2, 3 → レベル 1, 2, 3, 4)",
        },
    },
    weapon_splatoonsweps_shooter = {
        NZAP_PistolStyle = "N-ZAP系統をピストルのように構える。 (1: 有効, 0: 無効)",
        weapon_splatoonsweps_heroshot = {
            Level = "ヒーローシューターレプリカのレベル。 (0, 1, 2, 3 → レベル 1, 2, 3, 4)",
        },
        weapon_splatoonsweps_octoshot = {
            Advanced = "オクタシューターレプリカのスキン。 (0: 通常タコゾネス, 1: ワカメ付きタコゾネス)",
        },
    },
    weapon_splatoonsweps_slosher_base = {
        Automatic = "自動的にスロッシャーを振る。 (1: 有効, 0: 無効)",
    },
	weapon_splatoonsweps_roller = {
        AutomaticBrush = "自動的にフデを連打する。 (1: 有効, 0: 無効)",
        DropAtFeet = "バージョン2.8.0以降のように、連続で振り攻撃をした場合に足元にもインクが塗られるようにする。 (1: 有効, 0: 無効)",
		weapon_splatoonsweps_heroroller = {
            Level = "ヒーローローラーレプリカのレベル。 (0, 1, 2, 3 → レベル 1, 2, 3, 4)",
        },
	},
}}
