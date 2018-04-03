
--Config menu
local ss = SplatoonSWEPs
if not ss then return end

list.Set("DesktopWindows", "SplatoonSWEPs: Config menu", {
	title = "SplatoonSWEPs",
	icon = "splatoonsweps/configicon.png",
	width = 0,
	height = 0,
	onewindow = true,
	init = function(icon, window)
		ss:ConfigMenu()
		window:Close()
	end,
})

for i, c in ipairs(ss.ConVar) do
	CreateClientConVar(c, tostring(ss.ConVarDefaults[i]), true, true, ss.Text.CVarDescription[i])
end

function ss:ConfigMenu()
	local previewmodel = "models/props_splatoon/weapons/primaries/splattershot/splattershot.mdl"
	local division = 3
	local Window = vgui.Create "DFrame" --Main window
	Window:SetSize(ScrW() / division, ScrH() / division)
	Window:SetMinWidth(ScrW() / 3)
	Window:SetMinHeight(ScrH() / 3)
	Window:SetTitle(ss.Text.ConfigTitle)
	Window:Center()
	Window:SetDraggable(true)
	Window:ShowCloseButton(true)
	Window:SetVisible(true)
	Window:NoClipping(false)
	Window:MakePopup()
	
	local LabelError = Label(ss.Text.Error.NotFoundPlayermodel, Window)
	LabelError:SetPos(Window:GetWide() * 0.4, Window:GetTall() / 3 * 2 + 30)
	LabelError:SetFont "DermaDefaultBold"
	LabelError:SetTextColor(Color(255, 128, 128))
	LabelError:SizeToContents()
	LabelError:SetVisible(false)
	
	local function GetColor() --Get current color for preview model
		local color = self:GetColor(self:GetConVarInt "InkColor")
		return Vector(color.r, color.g, color.b) / 255
	end
	
	local function SetPlayerModel(DModelPanel) --Apply changes to preview model
		local model = self.Playermodel[self:GetConVarInt "Playermodel"]
		if not model then model = player_manager.TranslatePlayerModel(GetConVar "cl_playermodel":GetString()) end
		local bone = table.HasValue(self.Text.PlayermodelNames, model) and "ValveBiped.Bip01_Pelvis" or "ValveBiped.Bip01_Spine4"
		
		if not file.Exists(model, "GAME") then
			model = LocalPlayer():GetModel()
			LabelError:SetVisible(true)
		else
			LabelError:SetVisible(false)
		end
		
		DModelPanel:SetModel(model)
		local center = DModelPanel.Entity:GetBonePosition(DModelPanel.Entity:LookupBone(bone) or 0)
		DModelPanel:SetLookAt(center)
		DModelPanel:SetCamPos(center - Vector(-60, -10, -10))
		DModelPanel.Entity:SetSequence "idle_fist"
		DModelPanel.Entity:SetEyeTarget(center - Vector(-40, 0, -10))
		DModelPanel.Entity.GetPlayerColor = GetColor
		DModelPanel.Entity.GetInkColorProxy = GetColor
	end
	
	if not file.Exists(previewmodel, "GAME") then --If weapon model is not found
		local ErrorLabel = Label(ss.Text.Error.NotFoundWeaponModel, Window)
		ErrorLabel:SizeToContents()
		ErrorLabel:Dock(FILL) --Bring it to center
		ErrorLabel:SetContentAlignment(5)
		return
	end
	
	local Preview = vgui.Create("DModelPanel", Window) --Preview weapon model
	Preview:SetDirectionalLight(BOX_RIGHT, color_white)
	Preview:SetContentAlignment(5)
	Preview:SetSize(Window:GetWide() * 0.4, Window:GetTall() / 2)
	Preview:SetPos(Window:GetWide() / -30, 24)
	Preview:SetModel(previewmodel)
	local center = Preview.Entity:WorldSpaceCenter()
	Preview:SetLookAt(center)
	Preview:SetCamPos(center + Vector(-30, 30, 10))
	Preview.Entity.GetInkColorProxy = GetColor
	
	local Playermodel = vgui.Create("DModelPanel", Window) --Preview playermodel
	function Playermodel:LayoutEntity() end
	Playermodel:SetDirectionalLight(BOX_RIGHT, color_white)
	Playermodel:SetContentAlignment(5)
	Playermodel:SetSize(Window:GetWide() * 0.4, Window:GetTall() * 0.75)
	Playermodel:AlignLeft(Window:GetWide() / 20)
	Playermodel:AlignBottom()
	SetPlayerModel(Playermodel)
	
	local ComboColor = vgui.Create("DComboBox", Window) --Ink color selection box
	ComboColor:SetSortItems(false)
	ComboColor:SetPos(Window:GetWide() * 0.4, Window:GetTall() / 4)
	ComboColor:SetSize(Window:GetWide() * 0.31, 24)
	ComboColor:SetValue(self:GetColorName(self:GetConVarInt "InkColor"))
	for i = 1, self.MAX_COLORS do
		ComboColor:AddChoice(self:GetColorName(i))
	end
	
	function ComboColor:OnSelect(index, value, data)
		local cvar = ss:GetConVar "InkColor"
		if cvar then cvar:SetInt(index) end
	end
	
	local LabelColor = Label(ss.Text.InkColor, Window)
	LabelColor:SizeToContents()
	LabelColor:SetPos(Window:GetWide() * 0.4, Window:GetTall() / 4 - 24)
	
	local ComboModel = vgui.Create("DComboBox", Window) --Playermodel selection box
	ComboModel:SetSortItems(false)
	ComboModel:SetPos(Window:GetWide() * 0.4, Window:GetTall() / 3 * 2)
	ComboModel:SetSize(Window:GetWide() * 0.31, 24)
	ComboModel:SetValue(self.Text.PlayermodelNames[self:GetConVarInt "Playermodel"])
	for i, c in ipairs(self.Text.PlayermodelNames) do
		ComboModel:AddChoice(c)
	end
	
	function ComboModel:OnSelect(index, value, data)
		local cvar = ss:GetConVar "Playermodel"
		if cvar then cvar:SetInt(index) end
		SetPlayerModel(Playermodel)
	end
	
	local LabelModel = Label(ss.Text.Playermodel, Window)
	LabelModel:SizeToContents()
	LabelModel:SetPos(Window:GetWide() * 0.4, Window:GetTall() / 3 * 2 - 24)
	
	local Options = vgui.Create("DPanel", Window) --Group of checkboxes
	Options:SetWide(Window:GetWide() / 4)
	Options:Dock(RIGHT)
	
	local OptionsConVar = {
		"CanHealStand",
		"CanHealInk",
		"CanReloadStand",
		"CanReloadInk",
		"DrawInkOverlay",
	}
	for i = 0, 4 do
		local Check = vgui.Create("DCheckBoxLabel", Options)
		Check:SetPos(4, 4 + 20 * i)
		Check:SetText(ss.Text.Options[i + 1])
		Check:SetConVar(self:GetConVarName(OptionsConVar[i + 1]))
		Check:SetValue(self:GetConVarInt(OptionsConVar[i + 1]))
		Check:SetDark(true)
		Check:SizeToContents()
	end
end
