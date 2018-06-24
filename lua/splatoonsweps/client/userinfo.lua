
-- Config menu

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
			local color = ss:GetColor(ss:GetConVarInt "InkColor")
			return Vector(color.r, color.g, color.b) / 255
		end
		
		local function GetPlayermodel(i)
			return ss.Playermodel[i or ss:GetConVarInt "Playermodel"] or
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
		CurrentColor:SetColor(ss:GetColor(ss:GetConVarInt "InkColor"))
		
		local ColorSelector = window:Add "DColorPalette" -- Color picker
		ColorSelector:SetPos(window:GetWide() * .35, 60)
		ColorSelector:SetWide(window:GetWide() * .31)
		ColorSelector:SetButtonSize(math.Round(ColorSelector:GetWide() / math.ceil(ss.MAX_COLORS / 3)))
		ColorSelector:SetColorButtons(ss.InkColors)
		for _, color in pairs(ColorSelector:GetChildren()) do
			local i = color:GetID()
			color:SetToolTip(ss.Text.ColorNames[i])
			function color:DoClick()
				local cvar = ss:GetConVar "InkColor"
				if cvar then cvar:SetInt(i) end
				CurrentColor:SetColor(ss:GetColor(i))
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
				local cvar = ss:GetConVar "Playermodel"
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
		}
		for i = 1, #OptionsConVar do
			local Check = Options:Add "DCheckBoxLabel"
			Check:Dock(TOP)
			Check:SetText(ss.Text.Options[i])
			Check:SetConVar(ss:GetConVarName(OptionsConVar[i]))
			Check:SetValue(ss:GetConVarInt(OptionsConVar[i]))
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
		ComboRes:SetValue(ss.Text.RTResolutionName[ss:GetConVarInt "RTResolution" + 1])
		for i = 1, #ss.Text.RTResolutionName do
			ComboRes:AddChoice(ss.Text.RTResolutionName[i])
		end
		
		local LabelResReq = Options:Add "DLabel"
		LabelResReq:SetFont "DermaDefaultBold"
		LabelResReq:SetPos(0, ypos - ComboRes:GetTall())
		LabelResReq:SetText(ss.Text.RTRestartRequired)
		LabelResReq:SetTextColor(Color(255, 128, 128))
		LabelResReq:SetToolTip(ss.Text.DescRTResolution)
		LabelResReq:SetVisible(before ~= ss.RTSize[ss:GetConVarInt "RTResolution"])
		LabelResReq:SizeToContents()
		
		local LabelRes = Options:Add "DLabel" -- Ink buffer size:
		LabelRes:SetPos(0, ypos - ComboRes:GetTall() - LabelResReq:GetTall())
		LabelRes:SetText(ss.Text.RTResolution)
		LabelRes:SetToolTip(ss.Text.DescRTResolution)
		LabelRes:SizeToContents()
		
		function ComboRes:OnSelect(index, value, data)
			local cvar = ss:GetConVar "RTResolution"
			if cvar then cvar:SetInt(index - 1) end
			LabelResReq:SetVisible(before ~= ss.RTSize[index - 1])
		end
	end,
})
