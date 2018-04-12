
--Config menu
local ss = SplatoonSWEPs
if not ss then return end
for i, c in ipairs(ss.ConVar) do
	CreateClientConVar(c, tostring(ss.ConVarDefaults[i]), true, true, ss.Text.CVarDescription[i])
end

list.Set("DesktopWindows", "SplatoonSWEPs: Config menu", {
	title = "SplatoonSWEPs",
	icon = "splatoonsweps/configicon.png",
	width = 0,
	height = 0,
	onewindow = true,
	init = function(icon, window)
		local division = 3
		window:SetSize(ScrW() / division, ScrH() / division)
		window:SetMinWidth(ScrW() / 3)
		window:SetMinHeight(ScrH() / 3)
		window:SetWidth(ScrW() / 3)
		window:SetHeight(ScrH() / 3)
		window:SetTitle(ss.Text.ConfigTitle)
		window:Center()
		window:SetDraggable(true)
		window:ShowCloseButton(true)
		window:SetVisible(true)
		window:NoClipping(false)
		
		local previewmodel = "models/props_splatoon/weapons/primaries/splattershot/splattershot.mdl"
		local LabelError = window:Add "DLabel"
		LabelError:SetPos(window:GetWide() * 0.4, window:GetTall() / 3 * 2 + 30)
		LabelError:SetFont "DermaDefaultBold"
		LabelError:SetText(ss.Text.Error.NotFoundPlayermodel)
		LabelError:SetTextColor(Color(255, 128, 128))
		LabelError:SizeToContents()
		LabelError:SetVisible(false)
		
		local function GetColor() --Get current color for preview model
			local color = ss:GetColor(ss:GetConVarInt "InkColor")
			return Vector(color.r, color.g, color.b) / 255
		end
		
		local function SetPlayerModel(DModelPanel) --Apply changes to preview model
			local model = ss.Playermodel[ss:GetConVarInt "Playermodel"]
			if not model then model = player_manager.TranslatePlayerModel(GetConVar "cl_playermodel":GetString()) end
			local bone = table.HasValue(ss.Text.PlayermodelNames, model) and "ValveBiped.Bip01_Pelvis" or "ValveBiped.Bip01_Spine4"
			
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
			local ErrorLabel = Label(ss.Text.Error.NotFoundWeaponModel, window)
			ErrorLabel:SizeToContents()
			ErrorLabel:Dock(FILL) --Bring it to center
			ErrorLabel:SetContentAlignment(5)
			return
		end
		
		local Preview = window:Add "DModelPanel" --Preview weapon model
		Preview:SetDirectionalLight(BOX_RIGHT, color_white)
		Preview:SetContentAlignment(5)
		Preview:SetSize(window:GetWide() * 0.4, window:GetTall() / 2)
		Preview:SetPos(window:GetWide() / -30, 24)
		Preview:SetModel(previewmodel)
		local center = Preview.Entity:WorldSpaceCenter()
		Preview:SetLookAt(center)
		Preview:SetCamPos(center + Vector(-30, 30, 10))
		Preview.Entity.GetInkColorProxy = GetColor
		
		local Playermodel = window:Add "DModelPanel" --Preview playermodel
		function Playermodel:LayoutEntity() end
		Playermodel:SetDirectionalLight(BOX_RIGHT, color_white)
		Playermodel:SetContentAlignment(5)
		Playermodel:SetSize(window:GetWide() * 0.4, window:GetTall() * 0.75)
		Playermodel:AlignLeft(window:GetWide() / 20)
		Playermodel:AlignBottom()
		SetPlayerModel(Playermodel)
		
		local ComboColor = window:Add "DComboBox" --Ink color selection box
		ComboColor:SetSortItems(false)
		ComboColor:SetPos(window:GetWide() * 0.4, window:GetTall() / 4)
		ComboColor:SetSize(window:GetWide() * 0.31, 24)
		ComboColor:SetValue(ss:GetColorName(ss:GetConVarInt "InkColor"))
		for i = 1, ss.MAX_COLORS do
			ComboColor:AddChoice(ss:GetColorName(i))
		end
		
		function ComboColor:OnSelect(index, value, data)
			local cvar = ss:GetConVar "InkColor"
			if cvar then cvar:SetInt(index) end
		end
		
		local LabelColor = window:Add "DLabel"
		LabelColor:SetPos(window:GetWide() * 0.4, window:GetTall() / 4 - 24)
		LabelColor:SetText(ss.Text.InkColor)
		LabelColor:SizeToContents()
		
		local ComboModel = window:Add "DComboBox" --Playermodel selection box
		ComboModel:SetSortItems(false)
		ComboModel:SetPos(window:GetWide() * 0.4, window:GetTall() / 3 * 2)
		ComboModel:SetSize(window:GetWide() * 0.31, 24)
		ComboModel:SetValue(ss.Text.PlayermodelNames[ss:GetConVarInt "Playermodel"])
		for i, c in ipairs(ss.Text.PlayermodelNames) do
			ComboModel:AddChoice(c)
		end
		
		function ComboModel:OnSelect(index, value, data)
			local cvar = ss:GetConVar "Playermodel"
			if cvar then cvar:SetInt(index) end
			SetPlayerModel(Playermodel)
		end
		
		local LabelModel = window:Add "DLabel"
		LabelModel:SetPos(window:GetWide() * 0.4, window:GetTall() / 3 * 2 - 24)
		LabelModel:SetText(ss.Text.Playermodel)
		LabelModel:SizeToContents()
		
		local Options = window:Add "DPanel" --Group of checkboxes
		Options:SetWide(window:GetWide() / 4)
		Options:Dock(RIGHT)
		
		local OptionsConVar = {
			"CanHealStand",
			"CanHealInk",
			"CanReloadStand",
			"CanReloadInk",
			"DrawInkOverlay",
		}
		for i = 0, 4 do
			local Check = Options:Add "DCheckBoxLabel"
			Check:SetPos(4, 4 + 20 * i)
			Check:SetText(ss.Text.Options[i + 1])
			Check:SetConVar(ss:GetConVarName(OptionsConVar[i + 1]))
			Check:SetValue(ss:GetConVarInt(OptionsConVar[i + 1]))
			Check:SetDark(true)
			Check:SizeToContents()
		end
	end,
})
