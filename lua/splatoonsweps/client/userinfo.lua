
-- Config menu

local ss = SplatoonSWEPs
if not ss then return end

local function PopupConfig(icon, window)
	window:SetMinWidth(math.max(ScrW() / 3, 500))
	window:SetMinHeight(math.max(ScrH() / 3, 300))
	window:SetWidth(math.max(ScrW() / 3, 500))
	window:SetHeight(math.max(ScrH() / 3, 300))
	window:SetTitle(ss.Text.ConfigTitle)
	window:Center()
	window:SetDraggable(true)
	window:ShowCloseButton(true)
	window:SetVisible(true)
	window:NoClipping(false)
	
	local LabelError = window:Add "DLabel"
	LabelError:SetPos(window:GetWide() * .4, window:GetTall() / 3 * 2 + 30)
	LabelError:SetFont "DermaDefaultBold"
	LabelError:SetText(ss.Text.Error.NotFoundPlayermodel)
	LabelError:SetTextColor(Color(255, 128, 128))
	LabelError:SetVisible(false)
	LabelError:SizeToContents()
	
	local function GetColor() -- Get current color for preview model
		local color = ss.GetColor(ss.GetOption "InkColor")
		return Vector(color.r, color.g, color.b) / 255
	end
	
	local function GetPlayermodel(i)
		return ss.Playermodel[i or ss.GetOption "Playermodel"] or
		player_manager.TranslatePlayerModel(GetConVar "cl_playermodel":GetString())
	end
	
	local function SetPlayerModel(DModelPanel) -- Apply changes to preview model
		local model = GetPlayermodel()
		if not file.Exists(model, "GAME") then
			model = LocalPlayer():GetModel()
			LabelError:SetVisible(true)
		else
			LabelError:SetVisible(false)
		end
		
		DModelPanel:SetModel(model)
		local ent = DModelPanel.Entity
		ent:SetPos(-Vector(160, 0, 0))
		ent:SetSequence "idle_fist"
		ent.GetPlayerColor = GetColor
		ent.GetInkColorProxy = GetColor
		if ss.CheckSplatoonPlayermodels[model] then
			ent.GetInfoNum = LocalPlayer().GetInfoNum
			ss.ProtectedCall(LocalPlayer().SplatColors, ent)
		end
		
		local issquid = ss.CheckSplatoonPlayermodels[model]
		local mins, maxs = ent:GetRenderBounds()
		local top = issquid and 60 or mins.z + maxs.z
		local campos = vector_up * top / 2
		ent:SetEyeTarget(campos)
		DModelPanel:SetCamPos(campos)
		DModelPanel:SetLookAt(ent:GetPos() + campos)
	end
	
	local Playermodel = window:Add "DModelPanel" -- Preview playermodel
	function Playermodel:LayoutEntity() end
	Playermodel:Dock(LEFT)
	Playermodel:SetContentAlignment(5)
	Playermodel:SetCursor "arrow"
	Playermodel:SetDirectionalLight(BOX_RIGHT, color_white)
	Playermodel:SetFOV(20)
	Playermodel:SetWide(window:GetWide() * .35)
	Playermodel:AlignLeft()
	Playermodel:AlignTop()
	SetPlayerModel(Playermodel)
	
	local LabelColor = window:Add "DLabel" -- Ink color:
	LabelColor:SetPos(window:GetWide() * .35, 32)
	LabelColor:SetText(ss.Text.InkColor)
	LabelColor:SizeToContents()
	
	local CurrentColor = window:Add "DColorButton" -- Current color box on top left
	CurrentColor:SetCursor "arrow"
	CurrentColor:SetPos(window:GetWide() * .01, window:GetTall() * .01 + 24)
	CurrentColor:SetSize(window:GetTall() / 16, window:GetTall() / 16)
	CurrentColor:SetColor(ss.GetColor(ss.GetOption "InkColor"))
	
	local ColorSelector = window:Add "DColorPalette" -- Color picker
	ColorSelector:SetPos(window:GetWide() * .35, 60)
	ColorSelector:SetWide(window:GetWide() * .31)
	ColorSelector:SetButtonSize(math.Round(ColorSelector:GetWide() / math.ceil(ss.MAX_COLORS / 3)))
	ColorSelector:SetColorButtons(ss.InkColors)
	for _, color in pairs(ColorSelector:GetChildren()) do
		local i = color:GetID()
		color:SetToolTip(ss.Text.ColorNames[i])
		function color:DoClick()
			local cvar = ss.GetConVar "InkColor"
			if cvar then cvar:SetInt(i) end
			CurrentColor:SetColor(ss.GetColor(i))
		end
	end
	
	local LabelModel = window:Add "DLabel" -- Playermodel:
	LabelModel:SetPos(window:GetWide() * .35, window:GetTall() / 2)
	LabelModel:SetText(ss.Text.Playermodel)
	LabelModel:SizeToContents()
	
	local ModelSelector = window:Add "DIconLayout" -- Playermodel selection box
	local y = window:GetTall() / 2 + LabelModel:GetTall()
	ModelSelector:SetPos(window:GetWide() * .35, y)
	ModelSelector:SetSize(window:GetWide() * .31, window:GetTall() - y)
	local size = ModelSelector:GetWide() / #ss.Text.PlayermodelNames * 2
	for i, c in ipairs(ss.Text.PlayermodelNames) do
		local item = ModelSelector:Add "SpawnIcon"
		item:SetSize(size, size)
		item:SetModel(GetPlayermodel(i))
		item:SetToolTip(c)
		function item:DoClick()
			local cvar = ss.GetConVar "Playermodel"
			if cvar then cvar:SetInt(i) end
			SetPlayerModel(Playermodel)
		end
	end
	
	local Options = window:Add "DScrollPanel" -- Group of checkboxes
	local m = window:GetTall() * .01
	Options:SetSize(window:GetWide() * .3, window:GetTall())
	Options:DockMargin(m, m, m, m)
	Options:DockPadding(m, m, m, m)
	Options:Dock(RIGHT)
	
	local AvoidWalls
	local OptionsConVar = {
		"CanHealStand",
		"CanHealInk",
		"CanReloadStand",
		"CanReloadInk",
		"BecomeSquid",
		"DrawInkOverlay",
		"DrawCrosshair",
		"NewStyleCrosshair",
		"AvoidWalls",
		"MoveViewmodel",
		"DoomStyle",
	}
	for i = 1, #OptionsConVar do
		local Check = Options:Add "DCheckBoxLabel"
		Check:Dock(TOP)
		Check:SetText(ss.Text.Options[i])
		Check:SetConVar(ss.GetConVarName(OptionsConVar[i]))
		Check:SetValue(ss.GetOption(OptionsConVar[i]))
		Check:SizeToContents()
		
		if OptionsConVar[i] == "AvoidWalls" then
			AvoidWalls = Check
		elseif OptionsConVar[i] == "MoveViewmodel" then
			Check:SetIndent(Options:GetWide() / 8)
			function AvoidWalls:OnChange(checked)
				Check:SetEnabled(checked)
			end
		end
	end
	
	Options:InvalidateParent()
	local before = ss.RenderTarget.BaseTexture:Width()
	local ComboRes = Options:Add "DComboBox"
	local ypos = math.min(Options:GetTall() * .85, Options:GetTall() - 60)
	ComboRes:SetSortItems(false)
	ComboRes:SetPos(0, ypos)
	ComboRes:SetSize(Options:GetWide() * .85, 17)
	ComboRes:SetToolTip(ss.Text.DescRTResolution)
	ComboRes:SetValue(ss.Text.RTResolutionName[ss.GetOption "RTResolution" + 1])
	for i = 1, #ss.Text.RTResolutionName do
		ComboRes:AddChoice(ss.Text.RTResolutionName[i])
	end
	
	local LabelResReq = Options:Add "DLabel"
	LabelResReq:SetFont "DermaDefaultBold"
	LabelResReq:SetPos(0, ypos - ComboRes:GetTall())
	LabelResReq:SetText(ss.Text.RTRestartRequired)
	LabelResReq:SetTextColor(Color(255, 128, 128))
	LabelResReq:SetToolTip(ss.Text.DescRTResolution)
	LabelResReq:SetVisible(before ~= ss.RTSize[ss.GetOption "RTResolution"])
	LabelResReq:SizeToContents()
	
	local LabelRes = Options:Add "DLabel" -- Ink buffer size:
	LabelRes:SetPos(0, ypos - ComboRes:GetTall() - LabelResReq:GetTall())
	LabelRes:SetText(ss.Text.RTResolution)
	LabelRes:SetToolTip(ss.Text.DescRTResolution)
	LabelRes:SizeToContents()
	
	function ComboRes:OnSelect(index, value, data)
		local cvar = ss.GetConVar "RTResolution"
		if cvar then cvar:SetInt(index - 1) end
		LabelResReq:SetVisible(before ~= ss.RTSize[index - 1])
	end
end

local dividerratio = 1 / 4
local previewratio = .69
local configicon = "splatoonsweps/configicon.png"
local function GetColor() -- Get current color for preview model
	local color = ss.GetColor(ss.GetOption "InkColor")
	return Vector(color.r, color.g, color.b) / 255
end

local function GetPlayermodel(i)
	return ss.Playermodel[i or ss.GetOption "Playermodel"] or
	player_manager.TranslatePlayerModel(GetConVar "cl_playermodel":GetString())
end

local function SetPlayerModel(self) -- Apply changes to preview model
	local model = GetPlayermodel()
	local exists = file.Exists(model, "GAME")
	-- LabelError:SetVisible(not exists)
	if not exists then model = LocalPlayer():GetModel() end
	
	self:SetModel(model)
	local issquid = ss.CheckSplatoonPlayermodels[model]
	local mins, maxs = self.Entity:GetRenderBounds()
	local top = issquid and 60 or mins.z + maxs.z
	local campos = vector_up * top / 2
	
	self.Entity:SetPos(-Vector(100))
	self.Entity:SetSequence "idle_fist"
	self.Entity.GetPlayerColor = GetColor
	self.Entity.GetInkColorProxy = GetColor
	self.Entity:SetEyeTarget(campos)
	self.Entity.GetInfoNum = LocalPlayer().GetInfoNum
	self:SetCamPos(campos)
	self:SetLookAt(self.Entity:GetPos() + campos)
	
	if not ss.CheckSplatoonPlayermodels[model] then return end
	ss.ProtectedCall(LocalPlayer().SplatColors, self.Entity)
end

local function DividerThink(self)
	local w = self:GetSize()
	if w == self.w then return end
	self:SetLeftWidth(self:GetWide() * self.ratio)
	self.w = w
end

local function DividerSaveRatio(self, mode)
	self:MouseRelease(mode)
	self.ratio = self:GetLeftWidth() / self:GetWide()
end

local function GeneratePreview(window, tab)
	tab.PreviewBase = vgui.Create "DPanel"
	tab.PreviewBase:SetPaintBackground(false)
	tab.Preview = tab.PreviewBase:Add "DModelPanel"
	tab.Preview.LayoutEntity = function() end
	tab.Preview:Dock(FILL)
	tab.Preview:SetContentAlignment(5)
	tab.Preview:SetCursor "arrow"
	tab.Preview:SetDirectionalLight(BOX_RIGHT, color_white)
	tab.Preview:SetFOV(30)
	tab.Preview:AlignRight()
	tab.Preview:AlignTop()
	SetPlayerModel(tab.Preview)
	
	tab.Divider = vgui.Create "DHorizontalDivider"
	tab.Divider.MouseRelease = tab.Divider.OnMouseReleased
	tab.Divider.OnMouseReleased = DividerSaveRatio
	tab.Divider.Think = DividerThink
	tab.Divider.ratio = previewratio
	tab.Divider:Dock(FILL)
	tab.Divider:SetRight(tab.PreviewBase)
	tab.Divider:SetLeftWidth(tab.Divider:GetWide() * tab.Divider.ratio)
	tab.Divider:SetLeftMin(window:GetMinWidth() / 4)
	tab.Divider:SetRightMin(window:GetMinWidth() / 4)
end

local function GenerateWeaponTab(window, tab)
	tab.Weapon = ss.IsValidInkling(LocalPlayer()) 
	tab.Weapon = tab.Weapon and "entities/" .. tab.Weapon.ClassName .. ".png"
	tab.Weapon = tab:AddSheet("", vgui.Create "DPanel", tab.Weapon or configicon)
	tab.Weapon.Panel:SetPaintBackground(false)
	tab.Weapon.Panel.ListBase = vgui.Create "DPanel"
	tab.Weapon.List = vgui.Create("ContentContainer", tab.Weapon.Panel.ListBase)
	tab.Weapon.List:SetTriggerSpawnlistChange(false)
	tab.Weapon.List:Dock(FILL)
	
	tab.Divider:SetLeft(tab.Weapon.Panel.ListBase)
	tab.Divider:SetParent(tab.Weapon.Panel)
	
	local WeaponList = list.Get "Weapon"
	local SpawnList = {}
	for _, c in ipairs(ss.WeaponClassNames) do
		table.insert(SpawnList, WeaponList[c])
	end
	
	for _, t in SortedPairsByMemberValue(SpawnList, "PrintName") do
		local icon = vgui.Create("ContentIcon", tab.Weapon.List)
		icon:SetContentType "weapon"
		icon:SetSpawnName(t.ClassName)
		icon:SetName(t.PrintName)
		icon:SetMaterial("entities/" .. t.ClassName .. ".png")
		icon:SetAdminOnly(t.AdminOnly)
		icon:SetColor(Color(135, 206, 250))
		function icon:DoClick()
			RunConsoleCommand("gm_giveswep", t.ClassName)
			surface.PlaySound "ui/buttonclickrelease.wav"
		end

		function icon:DoMiddleClick()
			RunConsoleCommand("gm_spawnswep", t.ClassName)
			surface.PlaySound "ui/buttonclickrelease.wav"
		end

		function icon:OpenMenu()
			local m = DermaMenu()
			m:AddOption("Copy to Clipboard", function()
				SetClipboardText(t.ClassName)
			end)
			
			m:AddOption("Spawn Using Toolgun", function()
				RunConsoleCommand("gmod_tool", "creator")
				RunConsoleCommand("creator_type", "3")
				RunConsoleCommand("creator_name", t.ClassName)
			end)
			
			m:AddSpacer()
			m:AddOption("Delete", function()
				icon:Remove()
				hook.Run("SpawnlistContentChanged", icon)
			end)
			
			m:Open()
		end
		
		tab.Weapon.List:Add(icon)
	end
end

local function GeneratePreferenceTab(window, tab)
	tab.Preference = tab:AddSheet("", vgui.Create "DPanel", "icon64/tool.png")
	tab.Preference.Panel:SetPaintBackground(false)
	tab.Preference.Panel.ListBase = vgui.Create "DPanel"
	tab.Preference.List = tab.Preference.Panel.ListBase:Add "DLabel"
	tab.Preference.List:Dock(FILL)
	tab.Preference.List:SetText "Dummy"
	tab.Preference.List:SetTextColor(Color(108, 111, 114))
	tab.Preference.List:SetContentAlignment(5)
end

local function CheckBoxLabelPerformLayout(self)
	local x = self.m_iIndent or 0
	local y = math.floor((self:GetTall() - self.Button:GetTall()) / 2)
	self.Button:SetSize(15, 15)
	self.Button:SetPos(x, y)
	self.Label:SizeToContents()
	self.Label:SetPos(x + self.Button:GetWide() + 9, y)
end

local function GenerateSideOptions(window, side)
	side.List = side:Add "DListLayout"
	side.List:Dock(FILL)
	side.List.Category = vgui.Create "DListLayout"
	side.List.Weapon = vgui.Create "DListLayout"
	local Category = side.List:Add "DCollapsibleCategory"
	local Weapon = side.List:Add "DCollapsibleCategory"
	Category:SetLabel "Weapon category"
	Category:SetContents(side.List.Category)
	Weapon:SetLabel "Specific"
	Weapon:SetContents(side.List.Weapon)
	
	for i = 1, 10 do
		local check = side.List.Category:Add "DCheckBoxLabel"
		check:SetText "Use new style crosshair"
		check:SetValue(false)
		check:SizeToContents()
		check:SetTall(check:GetTall() + 2)
		check.PerformLayout = CheckBoxLabelPerformLayout
		
		check = side.List.Weapon:Add "DCheckBoxLabel"
		check:SetText "インクオーバーレイの描画"
		check:SetValue(false)
		check:SizeToContents()
		check:SetTall(check:GetTall() + 2)
		check.PerformLayout = CheckBoxLabelPerformLayout
	end
end

local function PopupConfig(icon, window)
	window:SetIcon(configicon)
	window:SetMinWidth(math.max(ScrW() / 3, 500))
	window:SetMinHeight(math.max(ScrH() / 3, 300))
	window:SetWidth(math.max(ScrW() / 2, 500))
	window:SetHeight(math.max(ScrH() / 2, 300))
	window:SetTitle(ss.Text.ConfigTitle)
	window:SetDraggable(true)
	window:SetSizable(true)
	window:Center()
	window.btnMinim:SetVisible(false)
	window.btnMaxim:SetDisabled(false)
	window.btnMaxim:SetToolTip "Reset the window size"
	
	local divider = window:Add "DHorizontalDivider"
	local side = vgui.Create("DPanel", divider)
	local main = vgui.Create("DPanel", divider)
	side:SetPaintBackground(false)
	main:SetPaintBackground(false)
	divider:SetLeft(side)
	divider:SetRight(main)
	divider:Dock(FILL)
	divider:SetLeftMin(window:GetMinWidth() / 4)
	divider:SetLeftWidth(divider:GetLeftMin())
	divider:SetRightMin(window:GetMinWidth() * 2 / 3)
	
	local tab = divider:GetRight():Add "SplatoonSWEPs.DPropertySheetPlus"
	tab:Dock(FILL)
	tab:SetMaxTabSize(96)
	tab:SetMinTabSize(96)
	
	GenerateSideOptions(window, side)
	GeneratePreview(window, tab)
	GenerateWeaponTab(window, tab)
	GeneratePreferenceTab(window, tab)
	
	function window.btnMaxim:DoClick()
		window:SetWidth(math.max(ScrW() / 2, 500))
		window:SetHeight(math.max(ScrH() / 2, 300))
		window:InvalidateLayout(true)
		divider:SetLeftWidth(divider:GetLeftMin())
		tab.Divider.ratio = previewratio
		tab.Divider:SetLeftWidth(tab.Divider:GetWide() * previewratio)
		tab.Divider:InvalidateLayout()
	end
	
	local function DoClick(self)
		tab:SetActiveTab(self)
		tab.Divider:SetParent(self:GetPanel())
		tab.Divider:GetLeft():SetVisible(false)
		tab.Divider:SetLeft(self:GetPanel().ListBase)
		self:GetPanel().ListBase:SetVisible(true)
	end
	
	for _, t in ipairs(tab:GetItems()) do
		t.Tab.DoClick = DoClick
	end
end

list.Set("DesktopWindows", "SplatoonSWEPs: Config menu", {
	title = "SplatoonSWEPs",
	icon = configicon,
	width = 0,
	height = 0,
	onewindow = true,
	init = PopupConfig,
})
