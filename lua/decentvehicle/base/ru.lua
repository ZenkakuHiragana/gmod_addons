
-- Copyright © 2018-2030 Decent Vehicle
-- written by ∩(≡＾ω＾≡)∩ (https://steamcommunity.com/id/greatzenkakuman/)
-- and DangerKiddy(DK) (https://steamcommunity.com/profiles/76561198132964487/).

return {
    CVars = {
        AutoLoad = "Decent Vehicle: Загружать точки автоматически при загрузке.",
        DetectionRange = "Decent Vehicle: Транспорт найденый в этом радиусе будет автоматически управляться.",
        DetectionRangeELS = "Decent Vehicle: Радиус определенния транспорта с ELS, чтобы уступить им дорогу",
        DriveSide = [[Decent Vehicle: Решает какое движение.
0: Правостороннее (Европа, Америка итд.)
1: Левостороннее (Британия, Австралия итд.)]],
        ForceHeadlights = "Decent Vehicle: Заставляет Decent Vehicle включить фары",
		LockVehicle = "Decent Vehicle: Закрывать транспорт при спавне?",
        ShouldGoToRefuel = "Decent Vehicle: 1: Ехать на АЗС чтобы заправитьсч.  0: заправляться автоматичкски.",
        TimeToStopEmergency = "Decent Vehicle: Время в секундах чтобы выключить аварийные сигналы.",
        TurnOnLights = [[Decent Vehicle: Уровень использования фаи.
0: Выключены
1: Только ходовые
2: Ходовые и фары
3: Использовать все.]],
    },
	DeletedWaypoints = "Decent Vehicle: Точки удалены!",
    Errors = {
        AttachmentNotFound = "Decent Vehicle: attachment vehicle_feet_passenger0 не найден!",
        WaypointNotFound = "Decent Vehicle: Точка не найден!",
    },
	GeneratedWaypoints = "Decent Vehicle: Точки сгенерировались!",
	LoadedWaypoints = "Decent Vehicle: Точки загружены!",
    OldVersionNotify = "Decent Vehicle: Эта версия устарела!",
	OnDelete = "Вы собираетесь УДАЛИТЬ точки.",
	OnGenerate = "Вы собираетесь СГЕНЕРИРОВАТЬ точки.",
    OnLoad = "Вы собираетесь ЗАГРУЗИТЬ точки.",
    OnSave = "Вы собираетесь СОХРАНИТЬ точки.",
    SavedWaypoints = "Decent Vehicle: Точки сохранены!",
    SaveLoad_Cancel = "Отмена",
    SaveLoad_OK = "ОК",
    Tools = {
        AlwaysDrawWaypoints = "Постоянно отрисовывать точки",
        AutoLoad = "Загружать точки при загрузке игры",
        AutoLoadHelp = "Decent Vehicle будет автоматически загружать точки при загрузке карты.",
        Bidirectional = "Bi-directional соединение",
        BidirectionalHelp = "Connect bi-directional link automatically.",
        Category = "GreatZenkakuMan's tools",
		Delete = "Удалить точки",
        Description = "Создайте свой маршрут для транспорта!",
        DescriptionInMenu = "Создать маршруты для Decent Vehicle",
        DetectionRange = "Радиус для спавна",
        DetectionRangeELS = "Радиус для определения машин с ELS",
		DrawDistance = "Дистанция отрисовки",
		DrawDistanceHelp = "Дистанция, на которой будут отрисовываться точки",
        DrawWaypoints = "Отображать точки",
        DriveSide = "Левостороннее движение",
		ForceHeadlights = "Включить фары",
		ForceHeadlightsHelp = "Заставляет Decent Vehicle включить фары",
        FuelStation = "Заправка",
        FuelStationHelp = "Decent Vehicle будет ехать сюда чтобы заправиться.",
		Generate = "Сгенерировать точки",
        Instructions = "Выберете точку и/или светофор чтобы соединить их.  Выберете транспорт управляемый Decent Vehicle, чтобы назначить ему группу.",
        Left = {
            "Создать новую точку.",
            "Выберите другую точку которую вы хотите соединить.  Выберите эту же точку чтобы удалить ее.",
        },
        LightLevel = {
            All = "Все фары",
            Headlights = "Ходовые и фары",
            None = "Без фар",
            Running = "Только ходовые",
            Title = "Уровень освещения",
        },
		LockVehicle = "Закрывать транспорт",
		LockVehicleHelp = "Закрывать транспорт при спавне?",
        MaxSpeed = "Максисальная скорость [км/ч]",
        Name = "Decent Vehicle Waypoint Tool",
        PrintName = "Decent Vehicle Waypoint Tool",
        Restore = "Загрузить точки",
        Right = {"Обновить точки."},
        Save = "Сохранить точки",
        ServerSettings = "Настройки сервера",
        ShouldGoToRefuel = "Ездить на заправку",
        ShowInfo = {
            FuelStation = "Заправка: ",
            Group = "Группа: ",
            ID = "ID: ",
            SpeedLimit = "Ограничение [км/ч]: ",
            UseTurnLights = "Использовать поворотники: ",
            WaitUntilNext = "Ждать [сек.]: ",
        },
        ShowUpdates = "Уведомлять об обновлениях",
        ShowUpdatesHelp = "Если отмечено, вы будете уведомлены о всех обновлениях.",
        UpdateRadius = "Обновить радиус",
        UpdateRadiusHelp = "Точки в этом радиусе будут обновлены в то время, когда вы нажмете E + Правая Кнопка Мыши.",
        UseTurnLights = "Использовать поворотники",
        UseTurnLightsHelp = "Decent Vehicles будет использовать поворотники.",
        WaitTime = "Ожидание [секунды]",
        WaitTimeHelp = "Когда Decent Vehicle возьмет эту точку, он будет ждать данное время.",
        WaypointGroup = "Группа точки",
        WaypointGroupHelp = [[Вы можете разделить маршруты по группам.
0 значит, что все могут тут ездить.]],
    },
    UndoText = "Отмена точки",
}
