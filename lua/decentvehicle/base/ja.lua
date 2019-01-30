
-- Copyright © 2018-2030 Decent Vehicle
-- written by ∩(≡＾ω＾≡)∩ (https://steamcommunity.com/id/greatzenkakuman/)
-- and DangerKiddy(DK) (https://steamcommunity.com/profiles/76561198132964487/).

return {
	CVars = {
		AutoLoad = "Decent Vehicle: マップ読み込み時に自動的にウェイポイントを読み込むかどうか。",
		DetectionRange = "Decent Vehicle: スポーン時に車両を検索する範囲。",
		DetectionRangeELS = "Decent Vehicle: 運転中、非常灯付きの車を検知する範囲。",
		DriveSide = [[Decent Vehicle: 左側通行か右側通行か。
0: 右側通行 (ヨーロッパやアメリカなど)
1: 左側通行 (イギリスやオーストラリアなど)]],
		LockVehicle = "Decent Vehicle: 1にすると、Decent Vehicleの操縦する車両にプレイヤーが乗れないようになる。",
		ShouldGoToRefuel = "Decent Vehicle: 1: ガソリンスタンドに向かって給油する  0: 自動的に給油されるようにする",
		TimeToStopEmergency = "Decent Vehicle: 衝突時、ハザードランプを消すまでの時間。",
		TurnOnLights = [[Decent Vehicle: 使用するライトのレベル。
0: 無効
1: デイライトのみ
2: デイライトとヘッドライト
3: 可能なものすべて]],
	},
	DeletedWaypoints = "Decent Vehicle: ウェイポイントが削除されました!",
	Errors = {
		AttachmentNotFound = "Decent Vehicle: アタッチメント vehicle_feet_passenger0 が見つかりません!",
		WaypointNotFound = "Decent Vehicle: ウェイポイントが見つかりません!",
	},
	GeneratedWaypoints = "Decent Vehicle: ウェイポイントが生成されました!",
	LoadedWaypoints = "Decent Vehicle: ウェイポイントが読み込まれました!",
	OldVersionNotify = "Decent Vehicle: 古いバージョンを使用しているようです。 アップデートを確認してください!",
	OnDelete = "保存されたウェイポイントを削除します。",
	OnGenerate = "ウェイポイントの自動生成を行います。",
	OnLoad = "ウェイポイントの読み込みを行います。",
	OnSave = "ウェイポイントの保存を行います。",
	SavedWaypoints = "Decent Vehicle: ウェイポイントが保存されました!",
	SaveLoad_Cancel = "キャンセル",
	SaveLoad_OK = "OK",
	Tools = {
		AlwaysDrawWaypoints = "常にウェイポイントを表示する",
		Bidirectional = "双方向に接続",
		BidirectionalHelp = "自動的に双方向に接続します。",
		Category = "GreatZenkakuMan's tools",
		Delete = "ウェイポイントの削除",
		Description = "乗り物のために道を作ろう!",
		DescriptionInMenu = "Decent Vehicleのためのルートを構築する。",
		DetectionRange = "スポーン時の車両検出範囲",
		DetectionRangeELS = "緊急車両の検出範囲",
		DrawDistance = "描画距離",
		DrawDistanceHelp = "ウェイポイントを描画する最大の距離。",
		DrawWaypoints = "ウェイポイントを描画する",
		DriveSide = "左側通行",
		FuelStation = "ガソリンスタンド",
		FuelStationHelp = "給油のために向かう地点であるかどうか。",
		Generate = "ウェイポイントの生成",
		Instructions = "ウェイポイントや信号をクリックして接続する。または、Decent Vehicleが運転する乗り物をクリックするとグループ番号を割り当てられる。",
		Left = {
			"新しいウェイポイントを作成する。",
			"接続したいウェイポイントをクリックする。同じものをもう一度クリックすると消去する。",
		},
		LightLevel = {
			All = "すべて",
			Headlights = "デイライトとヘッドライト",
			None = "無効",
			Running = "デイライトのみ",
			Title = "ライトのレベル"
		},
		LockVehicle = "車両をロックする",
		LockVehicleHelp = "チェックを入れると、他のプレイヤーがDecent Vehicleの操縦する車両に乗れなくなる。",
		MaxSpeed = "最大速度 [km/h]",
		Name = "Decent Vehicle ウェイポイントツール",
		PrintName = "Decent Vehicle ウェイポイントツール",
		Restore = "ウェイポイントの読み込み",
		Right = {"ウェイポイントを更新する。"},
		Save = "ウェイポイントの保存",
		ServerSettings = "サーバー側の設定",
		ShouldGoToRefuel = "ガソリンスタンドへ向かう",
		ShowInfo = {
			FuelStation = "ガソリンスタンド: ",
			Group = "グループ番号: ",
			ID = "ID: ",
			SpeedLimit = "最大速度 [km/h]: ",
			UseTurnLights = "ウィンカーを使う: ",
			WaitUntilNext = "待ち時間 [秒]: ",
		},
		ShowUpdates = "アップデートを通知する",
		ShowUpdatesHelp = "チェックすると、アップデートされたときに通知が出るようになる。",
		UpdateRadius = "アップデートの適用半径",
		UpdateRadiusHelp = "E + 右クリックでこの範囲にあるウェイポイントが一度に更新される。",
		UseTurnLights = "ウィンカーを使う",
		UseTurnLightsHelp = "これが有効化されたウェイポイントへ向かうとき、ウィンカーを使うようになる。",
		WaitTime = "待ち時間 [秒]",
		WaitTimeHelp = "ウェイポイントの到着後に指定した時間だけ待つようになる。",
		WaypointGroup = "グループ番号",
		WaypointGroupHelp = [[一部のDecent Vehicleに対して向かうべき道を制限できる。
0にすると誰でも通れるウェイポイントになる。]],
	},
	UndoText = "Decent Vehicleのウェイポイントを元に戻した",
}
