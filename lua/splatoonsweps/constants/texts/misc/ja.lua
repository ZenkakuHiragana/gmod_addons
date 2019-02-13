AddCSLuaFile()
return {
    Author = "全角ひらがな",
    CleanupInk = "Splatoon SWEPsのインク",
    CleanupInkMessage = "Splatoon SWEPsのインクを消去しました。",
    DescRTResolution = [[インクの描画システムで用いるバッファサイズの設定です。
この変更を反映するにはGMODの再起動が必要です。
また、高解像度になるほど多くのVRAM容量が要求されます。
変更の際にはビデオメモリの容量が十分にあることを確認してください。]],
    LateReadyToSplat = "Splatoon SWEPs: マップを塗り替えす準備ができましたが、サーバーに参加し直すことを推奨します。",
    OverrideHelpText = "サーバー側の設定を優先する",
    Sidemenu = {
        Equipped = "装備中",
        FilterTitle = "Splatoon SWEPs: ブキフィルタ",
        SortPrefix = "並べ替え: ",
        Sort = {
            Name = "名前",
            Main = "メイン",
            Sub = "サブ",
            Special = "スペシャル",
            Recent = "最近使用",
            Often = "よく使う",
            Inked = "累計塗り面積",
        },
        VariationsPrefix = "バリエーション: ",
        Variations = {
            All = "すべて",
            Original = "無印",
            Customized = "カスタム",
            SheldonsPicks = "ブキチセレクション",
        },
        WeaponTypePrefix = "ブキタイプ: ",
        WeaponType = {
            All = "すべて",
            Chargers = "チャージャー",
            Rollers = "ローラー",
            Shooters = "シューター",
            Sloshers = "スロッシャー",
            Splatlings = "スピナー",
        },
    },
    InkColor = "インクの色:",
    Instructions = [[メイン攻撃: インクを撃つ
サブ攻撃: サブウェポンを使う
リロード: スペシャル発動
スプリント: スーパージャンプ
しゃがみ: イカになる]],
    Playermodel = "プレイヤーモデル:",
    PreviewTitle = "プレビュー",
    Purpose = "ブキを手に取り、イカになれ！",
    RTResolution = "インク バッファサイズ:",
    RTRestartRequired = "(再起動が必要)",
}
