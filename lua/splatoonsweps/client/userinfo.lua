
-- Config menu

local ss = SplatoonSWEPs
if not ss then return end

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

-- list.Set("DesktopWindows", "SplatoonSWEPs: Config menu", {
	-- title = "SplatoonSWEPs",
	-- icon = configicon,
	-- width = 0,
	-- height = 0,
	-- onewindow = true,
	-- init = PopupConfig,
-- })

local dividerratio = 1 / 4
local previewratio = .69
local configicon = "splatoonsweps/icons/config.png"
local weaponlisticon = "splatoonsweps/icons/weaponlist.png"
local equipped = Material "icon16/accept.png"
local WeaponFilters = {}
local function GetColor() -- Get current color for preview model
	local color = ss.GetColor(ss.GetOption "InkColor")
	return Vector(color.r, color.g, color.b) / 255
end

local function GetPlayermodel(i)
	local model = ss.Playermodel[i or ss.GetOption "Playermodel"] or
	player_manager.TranslatePlayerModel(GetConVar "cl_playermodel":GetString())
	local exists = file.Exists(model, "GAME")
	if not exists then model = LocalPlayer():GetModel() end
	return model, exists
end

local function SetPlayerModel(self) -- Apply changes to preview model
	local model, exists = GetPlayermodel()
	-- LabelError:SetVisible(not exists)
	
	local issquid = ss.CheckSplatoonPlayermodels[model]
	local campos = issquid and 26 or 34
	self.AnimTime = SysTime()
	self:SetModel(model)
	self:SetLookAt(Vector(1))
	self:SetCamPos(vector_origin)
	self.Entity:SetPos(Vector(issquid and 130 or 160, 0, -campos))
	self.Entity:SetSequence "idle_fist"
	self.Entity.GetPlayerColor = GetColor
	self.Entity.GetInkColorProxy = GetColor
	self.Entity:SetEyeTarget(vector_up * campos)
	self.Entity.GetInfoNum = LocalPlayer().GetInfoNum
	
	function self:OnRemove()
		if not self.Weapon then return end
		self.Weapon:Remove()
	end
	
	function self:DrawModel()
		local ret = self:PreDrawModel(self.Entity)
		if ret == false then return end
		local curparent, previous = self, self
		local leftx, rightx = 0, self:GetWide()
		local topy, bottomy = 0, self:GetTall()
		while curparent:GetParent() do
			curparent = curparent:GetParent()
			local x, y = previous:GetPos()
			topy = math.max(y, topy + y)
			leftx = math.max(x, leftx + x)
			bottomy = math.min(y + previous:GetTall(), bottomy + y)
			rightx = math.min(x + previous:GetWide(), rightx + x)
			previous = curparent
		end
		render.SetScissorRect(leftx, topy, rightx, bottomy, true)
		
		self.Entity:DrawModel()
		if self.Weapon and self.Weapon.Visible then
			self.Weapon:SetNoDraw(false)
			self.Weapon:DrawModel()
			self.Weapon:SetNoDraw(true)
		end
		
		self:PostDrawModel(self.Entity)
		render.SetScissorRect(0, 0, 0, 0, false)
	end
	
	function self:Think()
		local newmodel, exists = GetPlayermodel()
		if self:GetModel() ~= newmodel then
			local newsquid = ss.CheckSplatoonPlayermodels[newmodel]
			local newcam = newsquid and 26 or 34
			self.Entity:SetModel(newmodel)
			self.Entity:InvalidateBoneCache()
			self.Entity:SetPos(Vector(newsquid and 130 or 160, 0, -newcam))
			self.ClassName = nil
		end
		
		local w = ss.IsValidInkling(LocalPlayer())
		if not w then
			if SysTime() > self.AnimTime + .05 then
				self.Entity:SetSequence "idle_fist"
			end
			
			if self.Weapon then
				self.ClassName = nil
				self.Weapon.GetInkColorProxy = nil
				self.Weapon:SetModel "models/error.mdl"
				self.Weapon.Visible = false
			end
			
			return
		end
		
		if not self.Weapon then
			self.Weapon = ents.CreateClientProp()
			self.Weapon:SetPos(-Vector(120))
			self.Weapon:SetParent(self.Entity)
			self.Weapon:AddEffects(EF_BONEMERGE)
			self.Weapon:Spawn()
		end
		
		if self.ClassName ~= w.ClassName then
			self.Entity:SetSequence "idle_passive"
			self.Weapon.Visible = true
			self.Weapon:SetModel(w.ModelPath .. "w_right.mdl")
			for i, v in pairs(w.Bodygroup or {}) do
				self.Weapon:SetBodygroup(i, v)
			end
			
			function self.Weapon:GetInkColorProxy()
				return w:GetInkColorProxy()
			end
		end
		
		self.Weapon:SetSkin(w.Skin or 0)
		for i = 0, self.Weapon:GetNumBodyGroups() do
			self.Weapon:SetBodygroup(i, 0)
		end
		
		self.AnimTime = SysTime()
		self.ClassName = w.ClassName
	end
	
	if not issquid then return end
	ss.ProtectedCall(LocalPlayer().SplatColors, self.Entity)
end

local function CreateCheckBox(parent, cvar, text)
	local check = parent:Add "DCheckBoxLabel"
	check:SetConVar(cvar)
	check:SetText(text)
	check:SizeToContents()
	check:SetTall(check:GetTall() + 2)
	check:SetTextColor(check:GetSkin().Colours.Label.Dark)
	check.PerformLayout = CheckBoxLabelPerformLayout
	return check
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

local function GeneratePreview(tab)
	tab.PreviewBase = vgui.Create("SplatoonSWEPs.DFrameChild", tab)
	tab.PreviewBase:SetSize(360, 360)
	tab.PreviewBase:SetTitle(ss.Text.PreviewTitle)
	tab.PreviewBase:SetDraggable(true)
	tab.PreviewBase:SetSizable(true)
	tab.PreviewBase:SetPos(ScrW(), ScrH())
	tab.PreviewBase:SetZPos(1)
	tab.PreviewBase.InitialScreenLock = true
	
	tab.Preview = tab.PreviewBase:Add "DModelPanel"
	tab.Preview:Dock(FILL)
	tab.Preview:SetAnimated(true)
	tab.Preview:SetContentAlignment(5)
	tab.Preview:SetCursor "arrow"
	tab.Preview:SetDirectionalLight(BOX_BACK, color_white)
	tab.Preview:SetFOV(30)
	tab.Preview:AlignRight()
	tab.Preview:AlignTop()
	tab.Preview.Angles = Angle(0, 180)
	function tab.Preview:DragMousePress()
		self.PressX, self.PressY = gui.MousePos()
		self.Pressed = true
	end
	
	function tab.Preview:DragMouseRelease()
		self.Pressed = false
	end
	
	function tab.Preview:LayoutEntity(ent)
		if self.bAnimated then self:RunAnimation() end
		if self.Pressed then
			local mx, my = gui.MousePos()
			self.Angles = self.Angles - Angle(0, (self.PressX or mx) - mx)
			self.PressX, self.PressY = gui.MousePos()
		end
		
		ent:SetAngles(self.Angles)
	end
	
	SetPlayerModel(tab.Preview)
end

local function GenerateWeaponSpecificOptions(tab, side)
	side.Weapon = side.Weapon or side:Add(ss.Text.Sidemenu.Specific)
	if side.Weapon.Contents then
		side.Weapon.Contents:Clear()
	else
		side.Weapon:SetContents(vgui.Create "DListLayout")
	end
	
	local w = ss.IsValidInkling(LocalPlayer())
	side.Weapon:SetVisible(w and ss.Options[w.Base] and ss.Text.Options[w.Base])
	if not side.Weapon:IsVisible() then return end
	local Text = ss.Text.Options[w.Base]
	local CVarName = ss.GetConVarName(w.Base) 
	for k, v in SortedPairs(ss.Options[w.Base]) do
		if k == w.ClassName then
			local cvar = CVarName(k:lower())
			for k, v in SortedPairs(v) do
				if k == "Level" then
					local slider = side.Weapon.Contents:Add "DNumSlider"
					slider.Label:SetTextColor(slider.Label:GetSkin().Colours.Label.Dark)
					slider:SetConVar(cvar(k:lower()))
					slider:SetDecimals(0)
					slider:SetMinMax(0, 3)
					slider:SetText(Text[w.ClassName][k])
				else
					CreateCheckBox(side.Weapon.Contents, cvar(k:lower()), Text[w.ClassName][k])
				end
			end
		elseif isbool(v) then
			local cvar = CVarName(k:lower())
			if not ConVarExists(cvar) then continue end
			CreateCheckBox(side.Weapon.Contents, cvar, Text[k])
		end
	end
	
	side:InvalidateLayout()
end

local function GenerateWeaponIcons(tab, side)
	tab.Weapon.List.IconList:Clear()
	
	local WeaponList = list.Get "Weapon"
	local SpawnList = {}
	for _, c in ipairs(ss.WeaponClassNames) do
		local t = WeaponList[c]
		if not t then continue end
		if WeaponFilters.Equipped and not LocalPlayer():HasWeapon(t.ClassName) then continue end
		if WeaponFilters.Type and WeaponFilters.Type ~= t.Base then continue end
		if WeaponFilters.Variations == "Original" and (t.Customized or t.SheldonsPicks) then continue end
		if WeaponFilters.Variations and WeaponFilters.Variations ~= "Original" and not t[WeaponFilters.Variations] then continue end
		table.insert(SpawnList, t)
	end
	
	for _, t in SortedPairsByMemberValue(SpawnList, WeaponFilters.Sort or "PrintName") do
		local icontest = spawnmenu.CreateContentIcon("weapon", nil, {
			material = "entities/" .. t.ClassName .. ".png",
			nicename = t.PrintName,
			spawnname = t.ClassName,
		})
		
		if not icontest then continue end
		local icon = vgui.Create("ContentIcon", tab.Weapon.List)
		icon:SetContentType "weapon"
		icon:SetSpawnName(t.ClassName)
		icon:SetName(t.PrintName)
		icon:SetMaterial("entities/" .. t.ClassName .. ".png")
		icon:SetAdminOnly(t.AdminOnly)
		icon:SetColor(Color(135, 206, 250))
		icon.DoMiddleClick = icontest.DoMiddleClick
		icon.OpenMenu = icontest.OpenMenu
		icon.Click = icontest.DoClick
		icon.ClassID = t.ClassID or 0
		if ss.ProtectedCall(LocalPlayer().HasWeapon, LocalPlayer(), t.ClassName) then
			icon.Label:SetFont "DermaDefaultBold"
		end
		
		function icon:DoClick()
			if LocalPlayer():HasWeapon(self:GetSpawnName()) then
				net.Start "SplatoonSWEPs: Strip weapon"
				net.WriteUInt(self.ClassID, 8)
				net.SendToServer()
				self.Label:SetFont "DermaDefault"
			else
				self:Click()
				self.Label:SetFont "DermaDefaultBold"
			end
		end
		
		icon.BasePaint = icon.Paint
		function icon:Paint(w, h)
			icon:BasePaint(w, h)
			if LocalPlayer():HasWeapon(self:GetSpawnName()) then
				surface.SetDrawColor(color_white)
				surface.SetMaterial(equipped)
				surface.DrawTexturedRect(self.Border + 8, self.Border + 8, 16, 16)
			end
		end
		
		icontest:SetVisible(false)
		icontest:Remove()
		tab.Weapon.List:Add(icon)
	end
end

local function GenerateWeaponTab(tab, side)
	tab.Weapon = ss.IsValidInkling(LocalPlayer()) 
	tab.Weapon = tab.Weapon and "entities/" .. tab.Weapon.ClassName .. ".png"
	tab.Weapon = tab:AddSheet("", vgui.Create("DPanel", tab), tab.Weapon or configicon)
	tab.Weapon.Panel:SetPaintBackground(false)
	tab.Weapon.List = vgui.Create("ContentContainer", tab.Weapon.Panel)
	tab.Weapon.List.IconList:MakeDroppable "SplatoonSWEPs"
	tab.Weapon.List.IconList:SetDropPos ""
	tab.Weapon.List:SetTriggerSpawnlistChange(false)
	tab.Weapon.List:Dock(FILL)
	function tab.Weapon.Tab:Think()
		local img = ss.IsValidInkling(LocalPlayer()) 
		img = img and "entities/" .. img.ClassName .. ".png" or configicon
		if img and img ~= self.Image:GetImage() then
			self.Image:SetImage(img)
		end
	end
	
	GenerateWeaponIcons(tab, side)
end

local function GeneratePreferenceTab(tab)
	tab.Preference = tab:AddSheet("", vgui.Create "DPanel", "icon64/tool.png")
	tab.Preference.Panel:DockMargin(8, 8, 8, 8)
	tab.Preference.Panel:DockPadding(8, 8, 8, 8)
	tab.Preference.LabelColor = tab.Preference.Panel:Add "DLabel" -- Ink color:
	tab.Preference.LabelColor:Dock(TOP)
	tab.Preference.LabelColor:SetText(ss.Text.InkColor)
	tab.Preference.LabelColor:SetTextColor(tab.Preference.LabelColor:GetSkin().Colours.Label.Dark)
	tab.Preference.LabelColor:SizeToContents()
	
	tab.Preference.ColorSelector = tab.Preference.Panel:Add "DColorPalette" -- Color picker
	tab.Preference.ColorSelector:Dock(TOP)
	tab.Preference.ColorSelector:SetWide(ScrW() * .16)
	tab.Preference.ColorSelector:SetColorButtons(ss.InkColors)
	tab.Preference.ColorSelector:SetButtonSize(
	math.Round(tab.Preference.ColorSelector:GetWide() / math.ceil(ss.MAX_COLORS / 3)))
	for _, color in pairs(tab.Preference.ColorSelector:GetChildren()) do
		local i = color:GetID()
		color:SetToolTip(ss.Text.ColorNames[i])
		function color:DoClick()
			local cvar = ss.GetConVar "InkColor"
			if not cvar then return end
			cvar:SetInt(i)
		end
	end
	
	tab.Preference.LabelModel = tab.Preference.Panel:Add "DLabel" -- Playermodel:
	tab.Preference.LabelModel:Dock(TOP)
	tab.Preference.LabelModel:SetText("\n\n" .. ss.Text.Playermodel)
	tab.Preference.LabelModel:SetTextColor(tab.Preference.LabelModel:GetSkin().Colours.Label.Dark)
	tab.Preference.LabelModel:SizeToContents()
	
	tab.Preference.ModelSelector = tab.Preference.Panel:Add "DIconLayout" -- Playermodel selection box
	tab.Preference.ModelSelector:Dock(TOP)
	tab.Preference.ModelSelector:SetSize(ScrW() * .16, ScrH() * .16)
	local size = tab.Preference.ModelSelector:GetWide() / #ss.Text.PlayermodelNames * 2
	for i, c in ipairs(ss.Text.PlayermodelNames) do
		local item = tab.Preference.ModelSelector:Add "SpawnIcon"
		local model, exists = GetPlayermodel(i)
		item:SetSize(size, size)
		item:SetModel(model)
		item:SetToolTip(c)
		function item:DoClick()
			local cvar = ss.GetConVar "Playermodel"
			if cvar then cvar:SetInt(i) end
		end
	end
end

local function CheckBoxLabelPerformLayout(self)
	local x = self.m_iIndent or 0
	local y = math.floor((self:GetTall() - self.Button:GetTall()) / 2)
	self.Button:SetSize(15, 15)
	self.Button:SetPos(x, y)
	self.Label:SizeToContents()
	self.Label:SetPos(x + self.Button:GetWide() + 9, y)
end

local function GenerateFilter(tab, side)
	side.Filter = side:Add(ss.Text.Sidemenu.WeaponList)
	side.Filter:SetContents(vgui.Create "DListLayout")
	local eq = side.Filter.Contents:Add "DCheckBoxLabel"
	eq:SetText(ss.Text.Sidemenu.Equipped)
	eq:SizeToContents()
	eq:SetTall(eq:GetTall() + 2)
	eq:SetTextColor(eq:GetSkin().Colours.Label.Dark)
	eq.PerformLayout = CheckBoxLabelPerformLayout
	function eq:OnChange(checked)
		WeaponFilters.Equipped = checked
		GenerateWeaponIcons(tab)
	end
	
	local wt = side.Filter.Contents:Add "DComboBox"
	local prefix = ss.Text.Sidemenu.WeaponTypePrefix
	wt:SetSortItems()
	wt:AddChoice(prefix .. ss.Text.Sidemenu.WeaponType.All, nil, true)
	wt:AddChoice(prefix .. ss.Text.Sidemenu.WeaponType.Shooters, "weapon_shooter")
	wt:AddChoice(prefix .. ss.Text.Sidemenu.WeaponType.Chargers, "weapon_charger")
	wt:AddChoice(prefix .. ss.Text.Sidemenu.WeaponType.Rollers, "weapon_roller")
	wt:AddChoice(prefix .. ss.Text.Sidemenu.WeaponType.Splatlings, "weapon_splatling")
	wt:AddChoice(prefix .. ss.Text.Sidemenu.WeaponType.Sloshers, "weapon_slosher")
	function wt:OnSelect(index, value, data)
		WeaponFilters.Type = data
		GenerateWeaponIcons(tab)
	end
	
	local var = side.Filter.Contents:Add "DComboBox"
	prefix = ss.Text.Sidemenu.VariationsPrefix
	var:SetSortItems()
	var:AddChoice(prefix .. ss.Text.Sidemenu.Variations.All, nil, true)
	var:AddChoice(prefix .. ss.Text.Sidemenu.Variations.Original, "Original")
	var:AddChoice(prefix .. ss.Text.Sidemenu.Variations.Customized, "Customized")
	var:AddChoice(prefix .. ss.Text.Sidemenu.Variations.SheldonsPicks, "SheldonsPicks")
	function var:OnSelect(index, value, data)
		WeaponFilters.Variations = data
		GenerateWeaponIcons(tab)
	end
	
	local sort = side.Filter.Contents:Add "DComboBox"
	prefix = ss.Text.Sidemenu.SortPrefix
	sort:SetSortItems()
	sort:AddChoice(prefix .. ss.Text.Sidemenu.Sort.Name, "PrintName", true)
	sort:AddChoice(prefix .. ss.Text.Sidemenu.Sort.Main, "ClassID")
	sort:AddChoice(prefix .. ss.Text.Sidemenu.Sort.Sub, "SubWeapon")
	sort:AddChoice(prefix .. ss.Text.Sidemenu.Sort.Special, "SpecialWeapon")
	sort:AddChoice(prefix .. ss.Text.Sidemenu.Sort.Recent, nil)
	sort:AddChoice(prefix .. ss.Text.Sidemenu.Sort.Often, nil)
	sort:AddChoice(prefix .. ss.Text.Sidemenu.Sort.Inked, nil)
	function sort:OnSelect(index, value, data)
		WeaponFilters.Sort = data
		GenerateWeaponIcons(tab)
	end
end

local function GenerateSideOptions(tab, side)
	GenerateFilter(tab, side)
	
	side.Common = side:Add(ss.Text.Sidemenu.CommonOptions)
	side.Common:SetContents(vgui.Create "DListLayout")
	for k, v in SortedPairs(ss.Options) do
		local cvar = ss.GetConVarName(k)
		if not (isbool(v) and ConVarExists(cvar)) then continue end
		CreateCheckBox(side.Common.Contents, cvar, ss.Text.Options[k])
	end
end

local function GenerateWeaponContent(self)
	if self.PropPanel then
		self.PropPanel.SideOption:Remove()
		if dragndrop.IsDragging() then return end
		self.PropPanel:Remove()
	end
	
	self.PropPanel = vgui.Create("DPanel", self.PanelContent)
	self.PropPanel:SetPaintBackground(false)
	self.PropPanel:SetVisible(false)
	
	local navbar = self.PanelContent.ContentNavBar
	self.PropPanel.SideOption = vgui.Create("DCategoryList", navbar)
	self.PropPanel.SideOption:Dock(BOTTOM)
	self.PropPanel.SideOption:SetSize(navbar:GetWide(), ScrH() * 2 / 3)
	function self.PropPanel.SideOption.Think()
		local panel = self.PropPanel
		local opt = panel.SideOption
		if opt:IsVisible() ~= panel:IsVisible() then
			opt:SetVisible(panel:IsVisible())
			navbar.Tree:InvalidateLayout()
		end
		
		local w = ss.IsValidInkling(LocalPlayer())
		if self.WeaponClass == (w and w.ClassName) then return end
		self.WeaponClass = w and w.ClassName
		GenerateWeaponSpecificOptions(tab, self.PropPanel.SideOption)
	end
	
	local tab = vgui.Create("SplatoonSWEPs.DPropertySheetPlus")
	self.PropPanel:Add(tab)
	tab:Dock(FILL)
	tab:SetMaxTabSize(math.max(48, ScrH() * .08))
	tab:SetMinTabSize(math.max(48, ScrH() * .08))
	
	WeaponFilters = {}
	GeneratePreview(tab)
	GenerateWeaponTab(tab, self.PropPanel.SideOption)
	GeneratePreferenceTab(tab)
	GenerateSideOptions(tab, self.PropPanel.SideOption)
end

hook.Add("PopulateWeapons", "SplatoonSWEPs: Generate weapon list",
function(PanelContent, tree, node)
	local node = tree:AddNode("SplatoonSWEPs", weaponlisticon)
	node.PanelContent = PanelContent
	node.DoPopulate = GenerateWeaponContent
	node.OriginalThink = node.Think
	node.ScrW, node.ScrH = ScrW(), ScrH()
	function node:DoClick()
		self:DoPopulate()
		self.PanelContent:SwitchPanel(self.PropPanel)
	end
	
	function node:Think()
		ss.ProtectedCall(node.OriginalThink, node)
		if ScrW() == self.ScrW and ScrH() == self.ScrH then return end
		self.ScrW, self.ScrH = ScrW(), ScrH()
		self:DoPopulate()
	end
end)
