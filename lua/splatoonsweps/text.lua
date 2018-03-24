
local ss = SplatoonSWEPs
if not ss then return end
function ss:GetColorName(colorid)
	return ss.Text.ColorNames[colorid or math.random(self.MAX_COLORS)]
end

local function TableToString(t)
	local str = ""
	for i, v in ipairs(t) do
		str = str .. tostring(i) .. ":\t" .. tostring(v) .. "\n"
	end
	
	return str
end

local lang = GetConVar "gmod_language" :GetString()
local WeaponNames = {
	".52 Gal",
	".52 Gal Deco",
	".96 Gal",
	".96 Gal Deco",
	"Aerospray MG",
	"Aerospray PG",
	"Aerospray RG",
	"Bamboozler 14 Mk Ⅰ",
	"Bamboozler 14 Mk Ⅱ",
	"Bamboozler 14 Mk Ⅲ",
	"Blaster",
	"Custom Blaster",
	"Carbon Roller",
	"Carbon Roller Deco",
	"Dual Squelcher",
	"Custom Dual Squelcher",
	"Dynamo Roller",
	"Gold Dynamo Roller",
	"Tempered Dynamo Roller",
	"E-liter 3K",
	"Custom E-liter 3K",
	"E-liter 3K Scope",
	"Custom E-liter 3K Scope",
	"H-3 Nozzlenose",
	"H-3 Nozzlenose D",
	"Cherry H-3 Nozzlenose",
	"Heavy Splatling",
	"Heavy Splatling Deco",
	"Heavy Splatling Remix",
	"Hero Charger Replica",
	"Hero Roller Replica",
	"Hero Shot Replica",
	"Hydra Splatling",
	"Custom Hydra Splatling",
	"Inkbrush",
	"Inkbrush Nouveau",
	"Permanent Inkbrush",
	"Jet Squelcher",
	"Custom Jet Squelcher",
	"L-3 Nozzlenose",
	"L-3 Nozzlenose D",
	"Luna Blaster",
	"Luna Blaster Neo",
	"Mini Splatling",
	"Refurbished Mini Splatling",
	"Zink Mini Splatling",
	"N-ZAP '83",
	"N-ZAP '85",
	"N-ZAP '89",
	"Octobrush",
	"Octobrush Nouveau",
	"Octoshot Replica",
	"Range Blaster",
	"Custom Range Blaster",
	"Grim Range Blaster",
	"Rapid Blaster",
	"Rapid Blaster Deco",
	"Rapid Blaster Pro",
	"Rapid Blaster Pro Deco",
	"Slosher",
	"Slosher Deco",
	"Soda Slosher",
	"Sloshing Machine",
	"Sloshing Machine Neo",
	"Splash-o-matic",
	"Splash-o-matic Neo",
	"Splat Charger",
	"Kelp Splat Charger",
	"Bento Splat Charger",
	"Splat Roller",
	"Krak-On Splat Roller",
	"CoroCoro Splat Roller",
	"Splatterscope",
	"Kelp Splatterscope",
	"Bento Splatterscope",
	"Splattershot",
	"Tentatek Splattershot",
	"Wasabi Splattershot",
	"Splattershot Jr.",
	"Custom Splattershot Jr.",
	"Splattershot Pro",
	"Forge Splattershot Pro",
	"Berry Splattershot Pro",
	"Sploosh-o-matic",
	"Sploosh-o-matic Neo",
	"Sploosh-o-matic 7",
	"Classic Squiffer",
	"Fresh Squiffer",
	"New Squiffer",
	"Tri-Slosher",
	"Tri-Slosher Nouveau",
}

WeaponNames.ja = {
	".52ガロン",
	".52ガロンデコ",
	".96ガロン",
	".96ガロンデコ",
	"プロモデラーMG",
	"プロモデラーPG",
	"プロモデラーRG",
	"14式竹筒銃・甲",
	"14式竹筒銃・乙",
	"14式竹筒銃・丙",
	"ホットブラスター",
	"ホットブラスターカスタム",
	"カーボンローラー",
	"カーボンローラーデコ",
	"デュアルスイーパー",
	"デュアルスイーパーカスタム",
	"ダイナモローラー",
	"ダイナモローラーテスラ",
	"ダイナモローラーバーンド",
	"リッター3K",
	"リッター3Kカスタム",
	"3Kスコープ",
	"3Kスコープカスタム",
	"H3リールガン",
	"H3リールガンD",
	"H3リールガンチェリー",
	"バレルスピナー",
	"バレルスピナーデコ",
	"バレルスピナーリミックス",
	"ヒーローチャージャー レプリカ",
	"ヒーローローラー レプリカ",
	"ヒーローシューター レプリカ",
	"ハイドラント",
	"ハイドラントカスタム",
	"パブロ",
	"パブロ・ヒュー",
	"パーマネント・パブロ",
	"ジェットスイーパー",
	"ジェットスイーパーカスタム",
	"L3リールガン",
	"L3リールガンD",
	"ノヴァブラスター",
	"ノヴァブラスターネオ",
	"スプラスピナー",
	"スプラスピナーリペア",
	"スプラスピナーコラボ",
	"N-ZAP83",
	"N-ZAP85",
	"N-ZAP89",
	"ホクサイ",
	"ホクサイ・ヒュー",
	"オクタシューター レプリカ",
	"ロングブラスター",
	"ロングブラスターカスタム",
	"ロングブラスターネクロ",
	"ラピッドブラスター",
	"ラピッドブラスターデコ",
	"Rブラスターエリート",
	"Rブラスターエリートデコ",
	"バケットスロッシャー",
	"バケットスロッシャーデコ",
	"バケットスロッシャーソーダ",
	"スクリュースロッシャー",
	"スクリュースロッシャーネオ",
	"シャープシューター",
	"シャープシューターネオ",
	"スプラチャージャー",
	"スプラチャージャーワカメ",
	"スプラチャージャーベントー",
	"スプラローラー",
	"スプラローラーコラボ",
	"スプラローラーコロコロ",
	"スプラスコープ",
	"スプラスコープワカメ",
	"スプラスコープベントー",
	"スプラシューター",
	"スプラシューターコラボ",
	"スプラシューターワサビ",
	"わかばシューター",
	"もみじシューター",
	"プライムシューター",
	"プライムシューターコラボ",
	"プライムシューターベリー",
	"ボールドマーカー",
	"ボールドマーカーネオ",
	"ボールドマーカー7",
	"スクイックリンα",
	"スクイックリンγ",
	"スクイックリンβ",
	"ヒッセン",
	"ヒッセン・ヒュー",
}

local WeaponNames2 = {
	"Clash Blaster",
	"Dapple Dualies",
	"Dapple Dualies Nouveau",
	"Dark Tetra Dualies",
	"Dualie Squelchers",
	"E-liter 4K",
	"Custom E-liter 4K",
	"E-liter 4K Scope",
	"Custom E-liter 4K Scope",
	"Flingza Roller",
	"Foil Flingza Roller",
	"Glooga Dualies",
	"Goo Tuber",
	"Custom Goo Tuber",
	"Hero Blaster Replica",
	"Hero Brella Replica",
	"Herobrush Replica",
	"Hero Dualie Replicas",
	"Hero Slosher Replica",
	"Hero Splatling Replica",
	"Splat Brella",
	"Firefin Splat Charger",
	"Splat Dualies",
	"Emperry Splat Dualies",
	"Firefin Splatterscope",
	"Squeezer",
	"Tenta Brella",
	"Undercover Brella",
}

WeaponNames2.ja = {
	"クラッシュブラスター",
	"スパッタリー",
	"スパッタリー・ヒュー",
	"クアッドホッパーブラック",
	"デュアルスイーパー",
	"リッター4K",
	"リッター4Kカスタム",
	"4Kスコープ",
	"4Kスコープカスタム",
	"ヴァリアブルローラー",
	"ヴァリアブルローラーフォイル",
	"ケルビン525",
	"ソイチューバー",
	"ソイチューバーカスタム",
	"ヒーローブラスター レプリカ",
	"ヒーローシェルター レプリカ",
	"ヒーローブラシ レプリカ",
	"ヒーローマニューバー レプリカ",
	"ヒーロースロッシャー レプリカ",
	"ヒーロースピナー レプリカ",
	"パラシェルター",
	"スプラチャージャーコラボ",
	"スプラマニューバー",
	"スプラマニューバーコラボ",
	"スプラスコープコラボ",
	"ボトルガイザー",
	"キャンピングシェルター",
	"スパイガジェット",
}

ss.Text = {Error = {}, PrintNames = {}}
ss.Text.Category = "Splatoon SWEPs"
ss.Text.ColorNames = {
	"Red",
	"Orange",
	"Yellow",
	"Yellowish green",
	"Lime",
	"Spring green",
	"Cyan",
	"Azure blue",
	"Blue",
	"Light indigo",
	"Magenta",
	"Deep pink",
	
	"Maroon",
	"Olive",
	"Green",
	"Dark cyan",
	"Navy",
	"Purple",
	
	"Light green",
	"Light blue",
	"Pink",
	
	"Black",
	"Gray",
	"Light gray",
	"White",
}
ss.Text.PlayermodelNames = {
	"Inkling Girl",
	"Inkling Boy",
	"Octoling",
	"Marie",
	"Callie",
	"Don't change playermodel",
	"Don't change playermodel and don't become squid",
}
ss.Text.ConfigTitle = "SplatoonSWEPs Configuration"
ss.Text.InkColor = "Ink color:"
ss.Text.Playermodel = "Playermodel:"
ss.Text.Error.NotFoundPlayermodel =
[[ERROR: Playermodel is not found!
Make sure you have required addons!]]
ss.Text.Error.NotFoundWeaponModel = 
[[Weapon model is not found!
Make sure you have subscribed all required addons!]]
ss.Text.Options = {
	"Heal when stand",
	"Heal when in ink",
	"Reload when stand",
	"Reload when in ink",
	"Draw ink overlay",
}
ss.Text.CVarDescription = {
	[[Your ink color.  Available values are:
]] .. TableToString(ss.Text.ColorNames),
	[[Your thirdperson model.  Available values are:
]] .. TableToString(ss.Text.PlayermodelNames),
	"Whether or not you can heal yourself when you are out of ink. (1: yes, 0: no)",
	"Whether or not you can heal yourself when you are in ink. (1: yes, 0: no)",
	"Whether or not you can reload your ink when you are out of ink. (1: yes, 0: no)",
	"Whether or not you can reload your ink when you are in ink. (1: yes, 0: no)",
	"Whether or not ink overlay should be drawn in firstperson. (1: yes, 0: no)",
	[[RenderTarget resolution used in ink system.
To apply the change, restart your GMOD client.
Higher option needs more VRAM.
Make sure your graphics card has enough space of video memory.
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
8: 2x32768x32768, 16GB.]]}
ss.Text.AuthorName = "GreatZenkakuMan"
ss.Text.Purpose = "Splat ink!"
ss.Text.Instructions = 
[[Primary: Shoot ink.
Secondary: Use sub weapon.
Reload: Use special weapon.
Sprint: Super Jump menu.
Crouch: Become squid.]]

if lang == "ja" then
	ss.Text.ConfigTitle = "SplatoonSWEPs 設定"
	ss.Text.ColorNames = {
		"赤色",
		"橙色",
		"黄色",
		"黄緑色",
		"ライム色",
		"スプリンググリーン",
		"シアン",
		"コバルトブルー",
		"青色",
		"青紫色",
		"マゼンタ",
		"赤紫色",
		
		"えんじ色",
		"オリーブ色",
		"緑色",
		"藍色",
		"紺色",
		"紫色",
		
		"薄緑色",
		"水色",
		"ピンク色",
		
		"黒",
		"灰色",
		"薄灰色",
		"白",
	}
	ss.Text.PlayermodelNames = {
		"ガール",
		"ボーイ",
		"タコゾネス",
		"ホタル",
		"アオリ",
		"無変更",
		"無変更&イカにならない",
	}

	ss.Text.InkColor = "インクの色:"
	ss.Text.Playermodel = "プレイヤーモデル:"
	ss.Text.Error.NotFoundPlayermodel =
	[[エラー: プレイヤーモデルが見つかりません！
必要なアドオンを確認してください！]]
	ss.Text.Error.NotFoundWeaponModel = 
	[[ブキのモデルが見つかりません！
必要なアドオンをすべてサブスクライブしていることを確認してください！]]
	ss.Text.Options = {
		"インク外でHP回復",
		"インク内でHP回復",
		"インク外でインク回復",
		"インク内でインク回復",
		"インクオーバーレイの描画",
	}
	ss.Text.CVarDescription = {
	[[インクの色を設定する。使用可能な値は以下の通り。:
]] .. TableToString(ss.Text.ColorNames),
	[[三人称モデル。使用可能な値は以下の通り。:
]] .. TableToString(ss.Text.PlayermodelNames),
	"インクの外で体力が回復するかどうか。 (1: する 0: しない)",
	"インクの中で体力が回復するかどうか。 (1: する 0: しない)",
	"インクの外でインクが回復するかどうか。 (1: する 0: しない)",
	"インクの中でインクが回復するかどうか。 (1: する 0: しない)",
	"一人称視点でインクのオーバーレイを描画するかどうか。 (1: する 0: しない)",
	[[インクの描画システムで用いるRenderTargetの設定。
変更を反映するにはGMODの再起動が必要です。
高解像度になるほど多くのVRAM容量が必要になります。
変更の際にはビデオメモリの容量が十分にあることを確認してください。
1: RTの解像度は4096x4096です。
    このオプションは128MBのVRAMを必要とします。
2: RTの解像度は2x4096x4096です。
    オプション1の2倍の面積に等しい解像度を持ちます。
    このオプションは256MBのVRAMを必要とします。
3: 8192x8192。512MB。
4: 2x8192x8192。1GB。
5: 16384x16384。2GB。
6: 2x16384x16384。4GB。
7: 32768x32768。8GB。
8: 2x32768x32768。16GB。]]}
	ss.Text.AuthorName = "全角ひらがな"
	ss.Text.Purpose = "ブキを手に取り、イカになれ！"
	ss.Text.Instructions = [[
メイン攻撃: インクを撃つ
サブ攻撃: サブウェポンを使う
リロード: スペシャル発動
スプリント: スーパージャンプ
しゃがみ: イカになる]]
end

for i, c in ipairs(ss.WeaponClassNames) do
	ss.Text.PrintNames[c] = (WeaponNames[lang] or WeaponNames)[i]
end

if SERVER then return end
steamworks.RequestPlayerInfo("76561198013738310", function(name) ss.Text.AuthorName = name end)
