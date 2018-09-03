
-- Weapon names, descriptions, and other texts.

local ss = SplatoonSWEPs
if not ss then return end
function ss.GetColorName(colorid)
	return ss.Text.ColorNames[colorid or math.random(self.MAX_COLORS)]
end

local function TableToString(t)
	local str = ""
	for i, v in ipairs(t) do
		if i > 1 then str = str .. "\n" end
		str = str .. tostring(i) .. ":\t" .. tostring(v)
	end
	
	return str
end

local lang = GetConVar "gmod_language" :GetString()
local WeaponNames = { -- English
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
	"Neo Splash-o-matic",
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
	"Neo Sploosh-o-matic",
	"Sploosh-o-matic 7",
	"Classic Squiffer",
	"Fresh Squiffer",
	"New Squiffer",
	"Tri-Slosher",
	"Tri-Slosher Nouveau",
}

WeaponNames.ja = { -- Japanese
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
	"シャープマーカー",
	"シャープマーカーネオ",
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

WeaponNames.de = { -- German
	".52 Gallon",
	".52 Gallon Deko",
	".96 Gallon",
	".96 Gallon Deko",
	"Airbrush MG",
	"Airbrush PG",
	"Airbrush RG",
	nil, -- Bamboozler 14 Mk Ⅰ
	nil, -- Bamboozler 14 Mk Ⅱ
	nil, -- Bamboozler 14 Mk Ⅲ
	nil, -- Blaster
	nil, -- Custom Blaster
	nil, -- Carbon Roller
	nil, -- Carbon Roller Deco
	"Dual-Platscher",
	"Dual-Platscher SE",
	nil, -- Dynamo Roller
	nil, -- Gold Dynamo Roller
	nil, -- Tempered Dynamo Roller
	nil, -- E-liter 3K
	nil, -- Custom E-liter 3K
	nil, -- E-liter 3K Scope
	nil, -- Custom E-liter 3K Scope
	"S3 Tintenwerfer",
	"S3 Tintenwerfer D",
	"S3 Tintenwerfer Kirsch",
	nil, -- Heavy Splatling
	nil, -- Heavy Splatling Deco
	nil, -- Heavy Splatling Remix
	nil, -- Hero Charger Replica
	nil, -- Hero Roller Replica
	"Heldenwaffe Replik",
	nil, -- Hydra Splatling
	nil, -- Custom Hydra Splatling
	nil, -- Inkbrush
	nil, -- Inkbrush Nouveau
	nil, -- Permanent Inkbrush
	"Platscher",
	"Platscher SE",
	"L3 Tintenwerfer",
	"L3 Tintenwerfer D",
	nil, -- Luna Blaster
	nil, -- Luna Blaster Neo
	nil, -- Mini Splatling
	nil, -- Refurbished Mini Splatling
	nil, -- Zink Mini Splatling
	"N-ZAP83",
	"N-ZAP85",
	"N-ZAP89",
	nil, -- Octobrush
	nil, -- Octobrush Nouveau
	"Oktowaffe Replik",
	nil, -- Range Blaster
	nil, -- Custom Range Blaster
	nil, -- Grim Range Blaster
	nil, -- Rapid Blaster
	nil, -- Rapid Blaster Deco
	nil, -- Rapid Blaster Pro
	nil, -- Rapid Blaster Pro Deco
	nil, -- Slosher
	nil, -- Slosher Deco
	nil, -- Soda Slosher
	nil, -- Sloshing Machine
	nil, -- Sloshing Machine Neo
	"Fein-Disperser",
	"Fein-Disperser Neo",
	nil, -- Splat Charger
	nil, -- Kelp Splat Charger
	nil, -- Bento Splat Charger
	nil, -- Splat Roller
	nil, -- Krak-On Splat Roller
	nil, -- CoroCoro Splat Roller
	nil, -- Splatterscope
	nil, -- Kelp Splatterscope
	nil, -- Bento Splatterscope
	"Kleckser",
	"Tentatek-Kleckser",
	"Wasabi-Kleckser",
	"Junior-Kleckser",
	"Junior-Kleckser Plus",
	"Profi-Kleckser",
	"Focus-Profi-Kleckser",
	"Beeren-Profi-Kleckser",
	"Disperser",
	"Disperser Neo",
	"Disperser 7",
	nil,
	nil,
	nil,
	nil,
	nil,
}

WeaponNames["es-ES"] = { -- Spanish (NOE)
	"Salpicadora 2000",
	"Salpicadora 2000 DX",
	"Salpicadora 3000",
	"Salpicadora 3000 DX",
	"Aerógrafo pro",
	"Aerógrafo Extra",
	"Aerógrafo plus",
	nil, -- Bamboozler 14 Mk Ⅰ
	nil, -- Bamboozler 14 Mk Ⅱ
	nil, -- Bamboozler 14 Mk Ⅲ
	nil, -- Blaster
	nil, -- Custom Blaster
	nil, -- Carbon Roller
	nil, -- Carbon Roller Deco
	"Barredora Doble",
	"Barredora Doble SP",
	nil, -- Dynamo Roller
	nil, -- Gold Dynamo Roller
	nil, -- Tempered Dynamo Roller
	nil, -- E-liter 3K
	nil, -- Custom E-liter 3K
	nil, -- E-liter 3K Scope
	nil, -- Custom E-liter 3K Scope
	"Tintambor pesado",
	"Tintambor pesado D",
	"Tintambor pesado cereza",
	nil, -- Heavy Splatling
	nil, -- Heavy Splatling Deco
	nil, -- Heavy Splatling Remix
	nil, -- Hero Charger Replica
	nil, -- Hero Roller Replica
	"Pistola de Élite (réplica)",
	nil, -- Hydra Splatling
	nil, -- Custom Hydra Splatling
	nil, -- Inkbrush
	nil, -- Inkbrush Nouveau
	nil, -- Permanent Inkbrush
	"Megabarredora",
	"Megabarredora SP",
	"Tintambor ligero",
	"Tintambor ligero D",
	nil, -- Luna Blaster
	nil, -- Luna Blaster Neo
	nil, -- Mini Splatling
	nil, -- Refurbished Mini Splatling
	nil, -- Zink Mini Splatling
	"N-ZAP 83",
	"N-ZAP 85",
	"N-ZAP 89",
	nil, -- Octobrush
	nil, -- Octobrush Nouveau
	"Pistola octariana (réplica)",
	nil, -- Range Blaster
	nil, -- Custom Range Blaster
	nil, -- Grim Range Blaster
	nil, -- Rapid Blaster
	nil, -- Rapid Blaster Deco
	nil, -- Rapid Blaster Pro
	nil, -- Rapid Blaster Pro Deco
	nil, -- Slosher
	nil, -- Slosher Deco
	nil, -- Soda Slosher
	nil, -- Sloshing Machine
	nil, -- Sloshing Machine Neo
	"Marcador fino",
	"Marcador fino neo",
	nil, -- Splat Charger
	nil, -- Kelp Splat Charger
	nil, -- Bento Splat Charger
	nil, -- Splat Roller
	nil, -- Krak-On Splat Roller
	nil, -- CoroCoro Splat Roller
	nil, -- Splatterscope
	nil, -- Kelp Splatterscope
	nil, -- Bento Splatterscope
	"Lanzatintas",
	"Lanzatintas B",
	"Lanzatintas wasabi",
	"Lanzatintas novato",
	"Lanzatintas novato B",
	"Lanzatintas plus",
	"Lanzatintas plus B",
	"Lanzatintas plus frambuesa",
	"Marcador",
	"Marcador neo",
	"Marcador versátil",
	nil,
	nil,
	nil,
	nil,
	nil,
}

WeaponNames.fr = { -- French (NOE)
	"Calibre 2000",
	"Calibre 2000 chic",
	"Calibre 3000",
	"Calibre 3000 chic",
	"Aérogun",
	"Aérogun select",
	"Aérogun premium",
	nil, -- Bamboozler 14 Mk Ⅰ
	nil, -- Bamboozler 14 Mk Ⅱ
	nil, -- Bamboozler 14 Mk Ⅲ
	nil, -- Blaster
	nil, -- Custom Blaster
	nil, -- Carbon Roller
	nil, -- Carbon Roller Deco
	"Nettoyeur duo",
	"Nettoyeur duo modifié",
	nil, -- Dynamo Roller
	nil, -- Gold Dynamo Roller
	nil, -- Tempered Dynamo Roller
	nil, -- E-liter 3K
	nil, -- Custom E-liter 3K
	nil, -- E-liter 3K Scope
	nil, -- Custom E-liter 3K Scope
	"Arroseur lourd",
	"Arroseur lourd Cétacé",
	"Arroseur lourd Cerise",
	nil, -- Heavy Splatling
	nil, -- Heavy Splatling Deco
	nil, -- Heavy Splatling Remix
	nil, -- Hero Charger Replica
	nil, -- Hero Roller Replica
	"Lanceur héroïque (réplique)",
	nil, -- Hydra Splatling
	nil, -- Custom Hydra Splatling
	nil, -- Inkbrush
	nil, -- Inkbrush Nouveau
	nil, -- Permanent Inkbrush
	"Nettoyeur XL",
	"Nettoyeur XL modifié",
	"Arroseur léger",
	"Arroseur léger Cétacé",
	nil, -- Luna Blaster
	nil, -- Luna Blaster Neo
	nil, -- Mini Splatling
	nil, -- Refurbished Mini Splatling
	nil, -- Zink Mini Splatling
	"N-ZAP 83",
	"N-ZAP 85",
	"N-ZAP 89",
	nil, -- Octobrush
	nil, -- Octobrush Nouveau
	"Lanceur Octaling (réplique)",
	nil, -- Range Blaster
	nil, -- Custom Range Blaster
	nil, -- Grim Range Blaster
	nil, -- Rapid Blaster
	nil, -- Rapid Blaster Deco
	nil, -- Rapid Blaster Pro
	nil, -- Rapid Blaster Pro Deco
	nil, -- Slosher
	nil, -- Slosher Deco
	nil, -- Soda Slosher
	nil, -- Sloshing Machine
	nil, -- Sloshing Machine Neo
	"Marqueur léger",
	"Marqueur léger Néo",
	nil, -- Splat Charger
	nil, -- Kelp Splat Charger
	nil, -- Bento Splat Charger
	nil, -- Splat Roller
	nil, -- Krak-On Splat Roller
	nil, -- CoroCoro Splat Roller
	nil, -- Splatterscope
	nil, -- Kelp Splatterscope
	nil, -- Bento Splatterscope
	"Liquidateur",
	"Liquidateur griffé",
	"Liquidateur Wasabi",
	"Liquidateur Jr.",
	"Liquidateur Sr.",
	"Liquidateur pro",
	"Liquidateur pro griffé",
	"Liquidateur pro Framboise",
	"Marqueur lourd",
	"Marqueur lourd Néo",
	"Marqueur lourd 7",
	nil,
	nil,
	nil,
	nil,
	nil,
}

WeaponNames.it = { -- Italian
	"Calibro 2000",
	"Calibro 2000 DX",
	"Calibro 3000",
	"Calibro 3000 DX",
	"Aerografo",
	"Aerografo deluxe",
	"Aerografo élite",
	nil, -- Bamboozler 14 Mk Ⅰ
	nil, -- Bamboozler 14 Mk Ⅱ
	nil, -- Bamboozler 14 Mk Ⅲ
	nil, -- Blaster
	nil, -- Custom Blaster
	nil, -- Carbon Roller
	nil, -- Carbon Roller Deco
	"Sweeper duo",
	"Sweeper duo CM",
	nil, -- Dynamo Roller
	nil, -- Gold Dynamo Roller
	nil, -- Tempered Dynamo Roller
	nil, -- E-liter 3K
	nil, -- Custom E-liter 3K
	nil, -- E-liter 3K Scope
	nil, -- Custom E-liter 3K Scope
	"Triplete",
	"Triplete D",
	"Triplete ciliegia",
	nil, -- Heavy Splatling
	nil, -- Heavy Splatling Deco
	nil, -- Heavy Splatling Remix
	nil, -- Hero Charger Replica
	nil, -- Hero Roller Replica
	"Pistola élite replica",
	nil, -- Hydra Splatling
	nil, -- Custom Hydra Splatling
	nil, -- Inkbrush
	nil, -- Inkbrush Nouveau
	nil, -- Permanent Inkbrush
	"Sweeper",
	"Sweeper CM",
	"Triplete compatto",
	"Triplete compatto D",
	nil, -- Luna Blaster
	nil, -- Luna Blaster Neo
	nil, -- Mini Splatling
	nil, -- Refurbished Mini Splatling
	nil, -- Zink Mini Splatling
	"N-ZAP83",
	"N-ZAP85",
	"N-ZAP89",
	nil, -- Octobrush
	nil, -- Octobrush Nouveau
	"Octosplasher replica",
	nil, -- Range Blaster
	nil, -- Custom Range Blaster
	nil, -- Grim Range Blaster
	nil, -- Rapid Blaster
	nil, -- Rapid Blaster Deco
	nil, -- Rapid Blaster Pro
	nil, -- Rapid Blaster Pro Deco
	nil, -- Slosher
	nil, -- Slosher Deco
	nil, -- Soda Slosher
	nil, -- Sloshing Machine
	nil, -- Sloshing Machine Neo
	"Marker d'assalto",
	"Marker d'assalto Neo",
	nil, -- Splat Charger
	nil, -- Kelp Splat Charger
	nil, -- Bento Splat Charger
	nil, -- Splat Roller
	nil, -- Krak-On Splat Roller
	nil, -- CoroCoro Splat Roller
	nil, -- Splatterscope
	nil, -- Kelp Splatterscope
	nil, -- Bento Splatterscope
	"Splasher",
	"Splasher logo",
	"Splasher wasabi",
	"Sparacolore recluta",
	"Sparacolore logo",
	"Splasher élite",
	"Splasher élite logo",
	"Splasher élite viola",
	"Marker",
	"Marker neo",
	"Marker multi",
	nil,
	nil,
	nil,
	nil,
	nil,
}

WeaponNames.nl = { -- Dutch
	".52 Kaliter",
	".52 Kaliter Deco",
	".96 Kaliter",
	".96 Kaliter Deco",
	"Kladderwerper",
	nil, -- Aerospray PG
	"Kladderwerper Pro",
	nil, -- Bamboozler 14 Mk Ⅰ
	nil, -- Bamboozler 14 Mk Ⅱ
	nil, -- Bamboozler 14 Mk Ⅲ
	nil, -- Blaster
	nil, -- Custom Blaster
	nil, -- Carbon Roller
	nil, -- Carbon Roller Deco
	"Dubbelplonzers",
	"Gemodde Dubbelplonzers",
	nil, -- Dynamo Roller
	nil, -- Gold Dynamo Roller
	nil, -- Tempered Dynamo Roller
	nil, -- E-liter 3K
	nil, -- Custom E-liter 3K
	nil, -- E-liter 3K Scope
	nil, -- Custom E-liter 3K Scope
	"H-3 Langsnuit",
	"H-3 Langsnuit D",
	nil, -- Cherry H-3 Nozzlenose
	nil, -- Heavy Splatling
	nil, -- Heavy Splatling Deco
	nil, -- Heavy Splatling Remix
	nil, -- Hero Charger Replica
	nil, -- Hero Roller Replica
	"Heldenspetter (replica)",
	nil, -- Hydra Splatling
	nil, -- Custom Hydra Splatling
	nil, -- Inkbrush
	nil, -- Inkbrush Nouveau
	nil, -- Permanent Inkbrush
	"Straalplonzer",
	"Gemodde Straalplonzer",
	"L-3 Stompsnuit",
	"L-3 Stompsnuit D",
	nil, -- Luna Blaster
	nil, -- Luna Blaster Neo
	nil, -- Mini Splatling
	nil, -- Refurbished Mini Splatling
	nil, -- Zink Mini Splatling
	"N-ZAP '83",
	"N-ZAP '85",
	"N-ZAP '89",
	nil, -- Octobrush
	nil, -- Octobrush Nouveau
	nil, -- Octoshot Replica
	nil, -- Range Blaster
	nil, -- Custom Range Blaster
	nil, -- Grim Range Blaster
	nil, -- Rapid Blaster
	nil, -- Rapid Blaster Deco
	nil, -- Rapid Blaster Pro
	nil, -- Rapid Blaster Pro Deco
	nil, -- Slosher
	nil, -- Slosher Deco
	nil, -- Soda Slosher
	nil, -- Sloshing Machine
	nil, -- Sloshing Machine Neo
	"Spetterspuit",
	"Spetterspuit Neo",
	nil, -- Splat Charger
	nil, -- Kelp Splat Charger
	nil, -- Bento Splat Charger
	nil, -- Splat Roller
	nil, -- Krak-On Splat Roller
	nil, -- CoroCoro Splat Roller
	nil, -- Splatterscope
	nil, -- Kelp Splatterscope
	nil, -- Bento Splatterscope
	"Superspetter",
	"Tentatek Superspetter",
	"Wasabi Superspetter",
	"Superspetter jr.",
	"Gemodde Superspetter jr.",
	"Superspetter Pro",
	"Forge Superspetter Pro",
	nil, -- Berry Splattershot Pro
	"Spettertuit",
	"Spettertuit Neo",
	"Spettertuit 7",
	nil,
	nil,
	nil,
	nil,
	nil,
}

WeaponNames.ru = { -- Russian
	"Струевик .52",
	"Струевик .52 «Деко»",
	"Струевик .96",
	"Струевик .96 «Деко»",
	"Аэроспрей",
	nil,
	"Аэроспрей ДЕЛЮКС",
	nil, -- Bamboozler 14 Mk Ⅰ
	nil, -- Bamboozler 14 Mk Ⅱ
	nil, -- Bamboozler 14 Mk Ⅲ
	nil, -- Blaster
	nil, -- Custom Blaster
	nil, -- Carbon Roller
	nil, -- Carbon Roller Deco
	nil, -- Dual Squelcher
	nil, -- Custom Dual Squelcher
	nil, -- Dynamo Roller
	nil, -- Gold Dynamo Roller
	nil, -- Tempered Dynamo Roller
	nil, -- E-liter 3K
	nil, -- Custom E-liter 3K
	nil, -- E-liter 3K Scope
	nil, -- Custom E-liter 3K Scope
	"Тяжелый каплетрон",
	nil, -- H-3 Nozzlenose D
	"Cherry H-3 Nozzlenose",
	nil, -- Heavy Splatling
	nil, -- Heavy Splatling Deco
	nil, -- Heavy Splatling Remix
	nil, -- Hero Charger Replica
	nil, -- Hero Roller Replica
	"Каплестрел-004 (клон)",
	nil, -- Hydra Splatling
	nil, -- Custom Hydra Splatling
	nil, -- Inkbrush
	nil, -- Inkbrush Nouveau
	nil, -- Permanent Inkbrush
	"Плескарь",
	"Плескарь «Понт»",
	"Каплетрон-компакт",
	"L-3 Nozzlenose D",
	nil, -- Luna Blaster
	nil, -- Luna Blaster Neo
	nil, -- Mini Splatling
	nil, -- Refurbished Mini Splatling
	nil, -- Zink Mini Splatling
	"N-ZAP 83",
	"N-ZAP 85",
	"N-ZAP 89",
	nil, -- Octobrush
	nil, -- Octobrush Nouveau
	nil, -- Octoshot Replica
	nil, -- Range Blaster
	nil, -- Custom Range Blaster
	nil, -- Grim Range Blaster
	nil, -- Rapid Blaster
	nil, -- Rapid Blaster Deco
	nil, -- Rapid Blaster Pro
	nil, -- Rapid Blaster Pro Deco
	nil, -- Slosher
	nil, -- Slosher Deco
	nil, -- Soda Slosher
	nil, -- Sloshing Machine
	nil, -- Sloshing Machine Neo
	"Плюхомет",
	nil, -- Neo Splash-o-matic
	nil, -- Splat Charger
	nil, -- Kelp Splat Charger
	nil, -- Bento Splat Charger
	nil, -- Splat Roller
	nil, -- Krak-On Splat Roller
	nil, -- CoroCoro Splat Roller
	nil, -- Splatterscope
	nil, -- Kelp Splatterscope
	nil, -- Bento Splatterscope
	"Каплестрел",
	"Каплестрел «Щуччи»",
	"Каплестрел «Wasabi»",
	"Каплестрел-У",
	"Каплестрел-У 2.0",
	"Каплестрел ПРО",
	"Каплестрел ПРО «Блиц»",
	nil, -- Berry Splattershot Pro
	"Плюхотрон",
	nil, -- Neo Sploosh-o-matic
	nil, -- Sploosh-o-matic 7
	nil,
	nil,
	nil,
	nil,
	nil,
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
ss.Text.Category = "SplatoonSWEPs"
ss.Text.CleanupInk = "SplatoonSWEPs Ink"
ss.Text.CleanupInkMessage = "Cleaned up SplatoonSWEPs Ink."
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
}
ss.Text.RTResolutionName = {
	"2048x2048, 32MB",
	"4096x4096, 128MB",
	"2x4096x4096, 256MB",
	"8192x8192, 512MB",
	"2x8192x8192, 1GB",
	"16384x16384, 2GB",
	"2x16384x16384, 4GB",
	"32768x32768, 8GB",
	"2x32768x32768, 16GB",
}
ss.Text.RTResolution = "Ink buffer size:"
ss.Text.RTRestartRequired = "(Requires restart)"
ss.Text.DescRTResolution = 
[[Buffer size used in ink system.
To apply the change, restart your GMOD client.
Higher option needs more VRAM.
Make sure your graphics card has enough space of video memory.]]
ss.Text.ConfigTitle = "SplatoonSWEPs Configuration"
ss.Text.InkColor = "Ink color:"
ss.Text.Playermodel = "Playermodel:"
ss.Text.Error.NotFoundPlayermodel =
[[ERROR: Playermodel is not found!
Make sure you have required addons!]]
ss.Text.Error.NotFoundWeaponModel = 
[[ERROR: Weapon model is not found!
Make sure you have subscribed all required addons!]]
ss.Text.Error.CantSpawnInk = "SplatoonSWEPs: Can't spawn ink!  Required model is not found!"
ss.Text.Error.WeaponModelNotFound = "SplatoonSWEPs: Required model is not found!"
ss.Text.Error.WeaponPlayermodelNotFound = "SplatoonSWEPs: Required playermodel is not found!"
ss.Text.Error.WeaponSquidModelNotFound = "SplatoonSWEPs: Squid model is not found!  Check your subscriptions!"
ss.Text.Error.WeaponSpriteMatNotFound = "SplatoonSWEPs: Required sprite material is not found!"
ss.Text.Error.CrashDetected = "SplatoonSWEPs: Ink resolution has been reduced so as not to crash your client."
ss.Text.Options = {
	"Heal when stand",
	"Heal when in ink",
	"Reload when stand",
	"Reload when in ink",
	"Become squid",
	"Draw ink overlay",
	"Draw crosshair",
	"Use new style crosshair",
	"Make sight avoid walls",
	"Move Viewmodel",
	"Doom-styled",
}
ss.Text.CVarDescription = {
	Clear = "Clears all ink in the map.",
	Enabled = "Enables or disables SplatoonSWEPs. (1: enabled, 0: disabled)",
	FF = "Enables friendly fire. (1: enabled, 0: disabled)",
	[[Your ink color.  Available values are:
]] .. TableToString(ss.Text.ColorNames),
	[[Your thirdperson model.  Available values are:
]] .. TableToString(ss.Text.PlayermodelNames),
	"Heal yourself when you are out of ink. (1: yes, 0: no)",
	"Heal yourself when you are in ink. (1: yes, 0: no)",
	"Reload your ink when you are out of ink. (1: yes, 0: no)",
	"Reload your ink when you are in ink. (1: yes, 0: no)",
	"Become squid on crouching. (1: yes, 0: no)",
	"Draw ink overlay in firstperson. (1: yes, 0: no)",
	[[The resolution of RenderTarget used in ink system.
To apply the change, restart your GMOD client.
Higher option needs more VRAM.
Make sure your graphics card has enough space of video memory.
0: If your client has crashed while SplatoonSWEPs is loading, this value is set.  The resolution is 2048x2048.
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
	"Draw Splatoon-styled crosshair. (1: yes, 0: no)",
	"Make crosshair act like Splatoon 2. (1: yes, 0: no)",
	"Prevent SWEPs from shooting at wall wastfully. (1: yes, 0: no)",
	"Move viewmodel when avoid setting is enabled. (1: yes, 0: no)","Enables Aim down sights.  Weapon accuracy will not be better. (1: enabled, 0: disabled)",
}
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
	}

	ss.Text.RTResolution = "インク バッファサイズ:"
	ss.Text.RTRestartRequired = "(再起動が必要)"
	ss.Text.DescRTResolution =
	[[インクの描画システムで用いるバッファサイズの設定です。
この変更を反映するにはGMODの再起動が必要です。
また、高解像度になるほど多くのVRAM容量が要求されます。
変更の際にはビデオメモリの容量が十分にあることを確認してください。]]
	ss.Text.InkColor = "インクの色:"
	ss.Text.Playermodel = "プレイヤーモデル:"
	ss.Text.Error.NotFoundPlayermodel =
	[[エラー: プレイヤーモデルが見つかりません！
必要なアドオンを確認してください！]]
	ss.Text.Error.NotFoundWeaponModel = 
	[[エラー: ブキのモデルが見つかりません！
必要なアドオンをすべてサブスクライブしていることを確認してください！]]
	ss.Text.Error.CantSpawnInk = "SplatoonSWEPs: 必要なモデルが見つからないため、インクを出現させられません！"
	ss.Text.Error.WeaponModelNotFound = "SplatoonSWEPs: 必要なモデルが見つかりません！"
	ss.Text.Error.WeaponPlayermodelNotFound = "SplatoonSWEPs: プレイヤーモデルが見つかりません！"
	ss.Text.Error.WeaponSquidModelNotFound = "SplatoonSWEPs: イカのモデルが見つかりません！"
	ss.Text.Error.WeaponSpriteMatNotFound = "SplatoonSWEPs: 必要なスプライトマテリアルが見つかりません！"
	ss.Text.Error.CrashDetected = "SplatoonSWEPs: GMODクライアントの異常終了を検知したため、インクの解像度が縮小されています。"
	ss.Text.Options = {
		"インク外でHP回復",
		"インク内でHP回復",
		"インク外でインク回復",
		"インク内でインク回復",
		"イカになる",
		"インクオーバーレイの描画",
		"照準の描画",
		"Splatoon 2風の照準",
		"壁を避けて狙う",
		"ビューモデルを動かす",
		"DOOMスタイル",
	}
	ss.Text.CVarDescription = {
		Clear = "マップにあるすべてのインクを消去する。",
		Enabled = "SplatoonSWEPsを有効化するかどうか。 (1: する 0: しない)",
		FF = "同士討ちを有効にする。 (1: する 0: しない)",
		[[インクの色を設定する。使用可能な値は以下の通り。:
]] .. TableToString(ss.Text.ColorNames),
		[[三人称モデル。使用可能な値は以下の通り。:
]] .. TableToString(ss.Text.PlayermodelNames),
		"インクの外で体力が回復するかどうか。 (1: する 0: しない)",
		"インクの中で体力が回復するかどうか。 (1: する 0: しない)",
		"インクの外でインクが回復するかどうか。 (1: する 0: しない)",
		"インクの中でインクが回復するかどうか。 (1: する 0: しない)",
		"しゃがんだ時にイカになるかどうか。 (1: する 0: しない)",
		"一人称視点でインクのオーバーレイを描画するかどうか。 (1: する 0: しない)",
		[[インクの描画システムで用いるRenderTargetの設定。
この変更を反映するにはGMODの再起動を必要とする。
また、高解像度になるほど多くのVRAM容量が要求される。
ビデオメモリの容量が十分にあることを確認してから変更することを推奨する。
0: SplatoonSWEPsのロード中にクラッシュした場合の値で、解像度は2048x2048である。
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
		"スプラトゥーン風の照準を描画するかどうか。 (1: する 0: しない)",
		"照準の動き方をスプラトゥーン2に合わせるかどうか。 (1: する 0: しない)",
		"インクが壁に吸い付かないようにするかどうか。 (1: する 0: しない)",
		"壁を避けて狙う時、ビューモデルを動かすかどうか。 (1: する 0: しない)",
		"ADSを有効にする。ただし、命中率は上昇しない。 (1: する 0: しない)",
	}
	ss.Text.AuthorName = "全角ひらがな"
	ss.Text.Purpose = "ブキを手に取り、イカになれ！"
	ss.Text.Instructions = [[
メイン攻撃: インクを撃つ
サブ攻撃: サブウェポンを使う
リロード: スペシャル発動
スプリント: スーパージャンプ
しゃがみ: イカになる]]
end

local WeaponNameTable = WeaponNames[lang] or WeaponNames
for i, c in ipairs(ss.WeaponClassNames) do
	ss.Text.PrintNames[c] = WeaponNameTable[i] or WeaponNames[i]
end

if SERVER then return end
language.Add("Cleanup_" .. ss.CleanupTypeInk, ss.Text.CleanupInk)
language.Add("Cleaned_" .. ss.CleanupTypeInk, ss.Text.CleanupInkMessage)
steamworks.RequestPlayerInfo("76561198013738310", function(name) ss.Text.AuthorName = name end)
