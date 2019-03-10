
-- Config menu

local ss = SplatoonSWEPs
if not (ss and ss.GetOption "enabled") then return end
local dividerratio = 1 / 4
local previewratio = .69
local configicon = "splatoonsweps/icons/config.png"
local weaponlisticon = "splatoonsweps/icons/weaponlist.png"
local equipped = Material "icon16/accept.png"
local WeaponFilters = {}
local function GetColor() -- Get current color for preview model
	return ss.GetColor(ss.GetOption "inkcolor"):ToVector()
end

local function GetPlayermodel(i)
	local model = ss.Playermodel[i or ss.GetOption "playermodel"]
	or player_manager.TranslatePlayerModel(GetConVar "cl_playermodel":GetString())
	local exists = model and file.Exists(model, "GAME")
	if not exists and IsValid(LocalPlayer()) then
		model = LocalPlayer():GetModel()
	end

	return model, exists
end

local function SetPlayerModel(self) -- Apply changes to preview model
	local model, exists = GetPlayermodel()
	local issquid = ss.DrLilRobotPlayermodels[model]
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
	self.Entity:SetSubMaterial()

	function self:OnRemove()
		if not IsValid(self.Weapon) then return end
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
		if IsValid(self.Weapon) and self.Weapon.Visible then
			self.Weapon:SetNoDraw(false)
			self.Weapon:DrawModel()
			self.Weapon:SetNoDraw(true)
		end

		self:PostDrawModel(self.Entity)
		render.SetScissorRect(0, 0, 0, 0, false)
	end

	function self:Think()
		local model = GetPlayermodel()
		if self:GetModel() ~= model then
			local issquid = ss.DrLilRobotPlayermodels[model]
			local campos = issquid and 26 or 34
			self.Entity:SetModel(model)
			self.Entity:InvalidateBoneCache()
			self.Entity:SetPos(Vector(issquid and 130 or 160, 0, -campos))
			self.ClassName = nil
		end

		if not ss.Playermodel[ss.GetOption "playermodel"] and IsValid(LocalPlayer()) then
			self.Entity:SetSkin(LocalPlayer():GetSkin())
			for i = 0, LocalPlayer():GetNumBodyGroups() - 1 do
				self.Entity:SetBodygroup(i, LocalPlayer():GetBodygroup(i))
			end
		else
			self.Entity:SetSkin(0)
			for i = 0, self.Entity:GetNumBodyGroups() - 1 do
				self.Entity:SetBodygroup(i, 0)
			end
		end

		local w = ss.IsValidInkling(LocalPlayer())
		if not w then
			if SysTime() > self.AnimTime + .05 then
				self.Entity:SetSequence "idle_fist"
			end

			if IsValid(self.Weapon) then
				self.ClassName = nil
				self.Weapon.GetInkColorProxy = nil
				self.Weapon:SetModel "models/error.mdl"
				self.Weapon.Visible = false
			end

			return
		end

		if not IsValid(self.Weapon) then
			self.Weapon = ClientsideModel "models/error.mdl"
			self.Weapon:SetNoDraw(true)
			self.Weapon:SetPos(-Vector(120))
			self.Weapon:SetParent(self.Entity)
			self.Weapon:AddEffects(EF_BONEMERGE)
			self.Weapon:Spawn()
		end

		if self.ClassName ~= w.ClassName then
			self.Entity:SetSequence(w.Base == "weapon_splatoonsweps_splatling" and "idle_crossbow" or "idle_passive")
			self.Weapon.Visible = true
			self.Weapon:SetModel(w.ModelPath .. "w_right.mdl")
			self.Weapon:SetSkin(w.Skin or 0)
			for i = 0, self.Weapon:GetNumBodyGroups() - 1 do
				self.Weapon:SetBodygroup(i, 0)
			end

			for i, v in pairs(w.Bodygroup or {}) do
				self.Weapon:SetBodygroup(i, v)
			end

			function self.Weapon:GetInkColorProxy()
				return w:GetInkColorProxy()
			end
		end

		self.AnimTime = SysTime()
		self.ClassName = w.ClassName
	end

	if not issquid then return end
	ss.ProtectedCall(LocalPlayer().SplatColors, self.Entity)
end

local function GeneratePreview(tab)
	tab.PreviewBase = vgui.Create("SplatoonSWEPs.DFrameChild", tab)
	tab.PreviewBase:SetSize(360, 360)
	tab.PreviewBase:SetTitle(ss.Text.PreviewTitle)
	tab.PreviewBase:SetDraggable(true)
	tab.PreviewBase:SetSizable(true)
	tab.PreviewBase:SetPaintShadow(false)
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

local function GenerateWeaponIcons(tab)
	tab.Weapon.List.IconList:Clear()

	local WeaponList = list.GetForEdit "Weapon"
	local SpawnList = {}
	for _, c in ipairs(ss.WeaponClassNames) do
		local t = WeaponList[c]
		if not t then continue end
		t.Spawnable = true -- Write it here to be spawnable and not listed as normal weapon
		if WeaponFilters.Equipped and not LocalPlayer():HasWeapon(t.ClassName) then continue end
		if WeaponFilters.Type and WeaponFilters.Type ~= t.Base then continue end
		if WeaponFilters.Variations == "Original" and (t.Customized or t.SheldonsPicks) then continue end
		if WeaponFilters.Variations and WeaponFilters.Variations ~= "Original" and not t[WeaponFilters.Variations] then continue end

		local record = ss.WeaponRecord[LocalPlayer()]
		if record then
			t.Recent = record.Recent[t.ClassName] or 0
			t.Duration = record.Duration[t.ClassName] or 0
			t.Inked = record.Inked[t.ClassName] or 0
		end

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

local function GenerateWeaponTab(tab)
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

	GenerateWeaponIcons(tab)
end

local function GeneratePreferenceTab(tab)
	tab.Preference = tab:AddSheet("", vgui.Create "DPanel", "icon64/tool.png")
	tab.Preference.Panel:DockMargin(8, 8, 8, 8)
	tab.Preference.Panel:DockPadding(8, 8, 8, 8)

	-- "Ink color:" Label
	tab.Preference.LabelColor = tab.Preference.Panel:Add "DLabel"
	tab.Preference.LabelColor:Dock(TOP)
	tab.Preference.LabelColor:SetText(ss.Text.InkColor)
	tab.Preference.LabelColor:SetTextColor(tab.Preference.LabelColor:GetSkin().Colours.Label.Dark)
	tab.Preference.LabelColor:SizeToContents()

	-- Color picker
	tab.Preference.ColorSelector = tab.Preference.Panel:Add "DColorPalette"
	tab.Preference.ColorSelector:Dock(TOP)
	tab.Preference.ColorSelector:SetWide(ScrW() * .16)
	tab.Preference.ColorSelector:SetColorButtons(ss.InkColors)
	tab.Preference.ColorSelector:SetButtonSize(
	math.Round(tab.Preference.ColorSelector:GetWide() / math.ceil(ss.MAX_COLORS / 3)))
	for _, color in pairs(tab.Preference.ColorSelector:GetChildren()) do
		local i = color:GetID()
		color:SetToolTip(ss.Text.ColorNames[i])
		function color:DoClick()
			if ss.sp then
				net.Start "greatzenkakuman.cvartree.adminchange"
				net.WriteString(ss.GetConVarName("inkcolor", true))
				net.WriteString(tostring(i))
				net.SendToServer()
			else
				local cvar = ss.GetConVar "inkcolor"
				if not cvar then return end
				cvar:SetInt(i)
			end
		end
	end

	-- "Playermodel:" Label
	tab.Preference.LabelModel = tab.Preference.Panel:Add "DLabel"
	tab.Preference.LabelModel:Dock(TOP)
	tab.Preference.LabelModel:SetText("\n\n" .. ss.Text.Playermodel)
	tab.Preference.LabelModel:SetTextColor(tab.Preference.LabelModel:GetSkin().Colours.Label.Dark)
	tab.Preference.LabelModel:SizeToContents()

	-- Playermodel selection box
	tab.Preference.ModelSelector = tab.Preference.Panel:Add "DIconLayout"
	tab.Preference.ModelSelector:Dock(TOP)
	tab.Preference.ModelSelector:SetSize(ScrW() * .16, ScrH() * .16)
	local size = tab.Preference.ModelSelector:GetWide() / #ss.Text.PlayermodelNames * 2
	for i, c in ipairs(ss.Text.PlayermodelNames) do
		local item = tab.Preference.ModelSelector:Add "SpawnIcon"
		local model, exists = GetPlayermodel(i)
		if not exists then model = "models/error.mdl" end
		item.ID = i
		item.Model = model
		item:SetSize(size, size)
		item:SetModel(model)
		item:SetToolTip(c)
		function item:DoClick()
			if ss.sp then
				net.Start "greatzenkakuman.cvartree.adminchange"
				net.WriteString(ss.GetConVarName("playermodel", true))
				net.WriteString(tostring(i))
				net.SendToServer()
			else
				local cvar = ss.GetConVar "playermodel"
				if not cvar then return end
				cvar:SetInt(i)
			end
		end

		function item:Think()
			local new, exists = GetPlayermodel(self.ID)
			if exists and self.Model ~= new then
				self:SetModel(new)
				self.Model = new
			end
		end
	end

	-- Ink resolution combo box
	tab.Preference.ResolutionSelector = tab.Preference.Panel:Add "DComboBox"
	tab.Preference.ResolutionSelector:SetSortItems(false)
	tab.Preference.ResolutionSelector:Dock(BOTTOM)
	tab.Preference.ResolutionSelector:SetSize(300, 17)
	tab.Preference.ResolutionSelector:SetToolTip(ss.Text.DescRTResolution)
	tab.Preference.ResolutionSelector:SetValue(ss.Text.RTResolutions[ss.GetOption "rtresolution" + 1])
	for i = 1, #ss.Text.RTResolutions do
		tab.Preference.ResolutionSelector:AddChoice(ss.Text.RTResolutions[i])
	end

	-- "Ink buffer size:" Label
	tab.Preference.LabelResolution = tab.Preference.Panel:Add "DLabel"
	tab.Preference.LabelResolution:Dock(BOTTOM)
	tab.Preference.LabelResolution:SetText(ss.Text.RTResolution)
	tab.Preference.LabelResolution:SetToolTip(ss.Text.DescRTResolution)
	tab.Preference.LabelResolution:SetTextColor(tab.Preference.LabelResolution:GetSkin().Colours.Label.Dark)
	tab.Preference.LabelResolution:SizeToContents()

	-- "Restart required" Label
	tab.Preference.LabelResetRequired = tab.Preference.Panel:Add "DLabel"
	tab.Preference.LabelResetRequired:SetFont "DermaDefaultBold"
	tab.Preference.LabelResetRequired:Dock(BOTTOM)
	tab.Preference.LabelResetRequired:SetText(ss.Text.RTRestartRequired)
	tab.Preference.LabelResetRequired:SetTextColor(Color(255, 128, 128))
	tab.Preference.LabelResetRequired:SetToolTip(ss.Text.DescRTResolution)
	tab.Preference.LabelResetRequired:SetVisible(false)
	tab.Preference.LabelResetRequired:SizeToContents()

	local RTSize
	function tab.Preference.Panel:Think()
		local selected = tab.Preference.ResolutionSelector:GetSelectedID() or ss.GetOption "rtresolution" + 1
		selected = selected - 1
		tab.Preference.LabelResetRequired:SetVisible(RTSize and RTSize ~= ss.RenderTarget.Size[selected])
		if RTSize or not ss.RenderTarget.BaseTexture then return end
		RTSize = ss.RenderTarget.BaseTexture:Width()
	end

	function tab.Preference.ResolutionSelector:OnSelect(index, value, data)
		local cvar = ss.GetConVar "rtresolution"
		if not cvar then return end
		cvar:SetInt(index - 1)
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
	side:SetLabel(ss.Text.Sidemenu.FilterTitle)
	side:SetContents(vgui.Create "DListLayout")
	side.Contents:SetPaintBackground(true)
	local eq = side.Contents:Add "DCheckBoxLabel"
	eq:SetText(ss.Text.Sidemenu.Equipped)
	eq:SizeToContents()
	eq:SetTall(eq:GetTall() + 2)
	eq:SetTextColor(eq:GetSkin().Colours.Label.Dark)
	eq.PerformLayout = CheckBoxLabelPerformLayout
	function eq:OnChange(checked)
		WeaponFilters.Equipped = checked
		GenerateWeaponIcons(tab)
	end

	local wt = side.Contents:Add "DComboBox"
	local prefix = ss.Text.Sidemenu.WeaponTypePrefix
	wt:SetSortItems()
	wt:AddChoice(prefix .. ss.Text.Sidemenu.WeaponType.All, nil, true)
	for classname, categoryname in SortedPairs(ss.Text.CategoryNames) do
		wt:AddChoice(prefix .. categoryname, classname)
	end

	function wt:OnSelect(index, value, data)
		WeaponFilters.Type = data
		GenerateWeaponIcons(tab)
	end

	local var = side.Contents:Add "DComboBox"
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

	local sort = side.Contents:Add "DComboBox"
	prefix = ss.Text.Sidemenu.SortPrefix
	sort:SetSortItems()
	sort:AddChoice(prefix .. ss.Text.Sidemenu.Sort.Name, "PrintName", true)
	sort:AddChoice(prefix .. ss.Text.Sidemenu.Sort.Main, "ClassID")
	sort:AddChoice(prefix .. ss.Text.Sidemenu.Sort.Sub, "SubWeapon")
	sort:AddChoice(prefix .. ss.Text.Sidemenu.Sort.Special, "SpecialWeapon")
	sort:AddChoice(prefix .. ss.Text.Sidemenu.Sort.Recent, "Recent")
	sort:AddChoice(prefix .. ss.Text.Sidemenu.Sort.Often, "Duration")
	sort:AddChoice(prefix .. ss.Text.Sidemenu.Sort.Inked, "Inked")
	function sort:OnSelect(index, value, data)
		WeaponFilters.Sort = data
		GenerateWeaponIcons(tab)
	end
end

local function GenerateWeaponContents(self)
	if self.PropPanel then
		self.PropPanel.SideOption:Remove()
		if dragndrop.IsDragging() then return end
		self.PropPanel:Remove()
	end

	self.PropPanel = vgui.Create("DPanel", self.PanelContent)
	self.PropPanel:SetPaintBackground(false)
	self.PropPanel:SetVisible(false)

	local navbar = self.PanelContent.ContentNavBar
	self.PropPanel.SideOption = vgui.Create("DCollapsibleCategory", navbar)
	self.PropPanel.SideOption:Dock(TOP)
	function self.PropPanel.SideOption.Think()
		local panel = self.PropPanel
		local opt = panel.SideOption
		if opt:IsVisible() ~= panel:IsVisible() then
			opt:SetVisible(panel:IsVisible())
			navbar.Tree:InvalidateLayout()
		end
	end

	local tab = vgui.Create("SplatoonSWEPs.DPropertySheetPlus")
	self.PropPanel:Add(tab)
	tab:Dock(FILL)
	tab:SetMaxTabSize(math.max(48, ScrH() * .08))
	tab:SetMinTabSize(math.max(48, ScrH() * .08))

	WeaponFilters = {}
	GeneratePreview(tab)
	GenerateWeaponTab(tab)
	GeneratePreferenceTab(tab)
	GenerateFilter(tab, self.PropPanel.SideOption)
end

hook.Add("PopulateWeapons", "SplatoonSWEPs: Generate weapon list",
function(PanelContent, tree, node)
	local node = tree:AddNode("SplatoonSWEPs", weaponlisticon)
	node.PanelContent = PanelContent
	node.DoPopulate = GenerateWeaponContents
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
