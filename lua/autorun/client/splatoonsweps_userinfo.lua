
--Config menu
if not SplatoonSWEPs then return end

list.Set("DesktopWindows", "SplatoonSWEPs: Config menu", {
	title = "SplatoonSWEPs",
	icon = "splatoonsweps/configicon.png",
	width = 0,
	height = 0,
	onewindow = true,
	init = function(icon, window)
		SplatoonSWEPs:ConfigMenu()
		window:Close()
	end,
})

local CVAR_DEFAULT = {
	math.random(SplatoonSWEPs.MAX_COLORS),
	1,
	1,
	1,
	1,
	1,
	SplatoonSWEPs.RTResID.MEDIUM,
}
local CVAR_DESC = {	[[
Your ink color.  Available values are:
1: Orange
2: Pink
3: Purple
4: Green
5: Cyan
6: Blue
	]], [[
Your thirdperson model.  Available values are:
1: Inkling girl
2: Inkling boy
3: Octoling
4: Don't change playermodel
5: Don't change playermodel and don't become squid
	]],
	"1: You can heal yourself when you are not in ink.\n0: You can not.",
	"1: You can heal yourself when you are in ink.\n0: You can not.",
	"1: You can reload your ink when you are not in ink.\n0: You can not.",
	"1: You can reload your ink when you are in ink.\n0: You can not.",
	[[
RenderTarget resolution used in ink system.
To apply the change, restart your GMOD client.
Higher option needs more VRAM.
Make sure your graphics card has enough space of video memory.
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
8: 2x32768x32768, 16GB.
]],
}
for i, c in ipairs(SplatoonSWEPs.ConVar) do
	CreateClientConVar(c, tostring(CVAR_DEFAULT[i]), true, true, CVAR_DESC[i])
end

function SplatoonSWEPs:ConfigMenu()
	local previewmodel = "models/props_splatoon/weapons/primaries/splattershot/splattershot.mdl"
	local division = 3
	local Window = vgui.Create "DFrame" --Main window
	Window:SetSize(ScrW() / division, ScrH() / division)
	Window:SetMinWidth(ScrW() / 3)
	Window:SetMinHeight(ScrH() / 3)
	Window:SetTitle "SplatoonSWEPs Configuration"
	Window:Center()
	Window:SetDraggable(true)
	Window:ShowCloseButton(true)
	Window:SetVisible(true)
	Window:NoClipping(false)
	Window:MakePopup()
	
	local LabelError = Label("ERROR: Playermodel is not found!\nCheck if you have required addons!", Window)
	LabelError:SetPos(Window:GetWide() * 0.4, Window:GetTall() / 3 * 2 + 30)
	LabelError:SetFont "DermaDefaultBold"
	LabelError:SetTextColor(Color(255, 128, 128))
	LabelError:SizeToContents()
	LabelError:SetVisible(false)
	
	local function GetColor() --Get current color for preview model
		local color = SplatoonSWEPs:GetColor(SplatoonSWEPs:GetConVarInt "InkColor")
		return Vector(color.r, color.g, color.b) / 255
	end
	
	local function SetPlayerModel(DModelPanel) --Apply changes to preview model
		local model = SplatoonSWEPs.Playermodel[SplatoonSWEPs:GetConVarInt "Playermodel"] or LocalPlayer():GetModel()
		local bone = table.HasValue(SplatoonSWEPs.PlayermodelName, model) and "ValveBiped.Bip01_Pelvis" or "ValveBiped.Bip01_Spine4"
		
		if not file.Exists(model, "GAME") then
			model = LocalPlayer():GetModel()
			LabelError:SetVisible(true)
		else
			LabelError:SetVisible(false)
		end
		
		DModelPanel:SetModel(model)
		local center = DModelPanel.Entity:GetBonePosition(DModelPanel.Entity:LookupBone(bone))
		DModelPanel:SetLookAt(center)
		DModelPanel:SetCamPos(center - Vector(-60, -10, -10))
		DModelPanel.Entity:SetSequence "idle_fist"
		DModelPanel.Entity:SetEyeTarget(center - Vector(-40, 0, -10))
		DModelPanel.Entity.GetPlayerColor = GetColor
		DModelPanel.Entity.GetInkColorProxy = GetColor
	end
	
	if not file.Exists(previewmodel, "GAME") then --If weapon model is not found
		local ErrorLabel = Label("Weapon model was not found!\nMake sure you have subscribed all required addons!", Window)
		ErrorLabel:SizeToContents()
		ErrorLabel:Dock(FILL) --Bring it to center
		ErrorLabel:SetContentAlignment(5)
		return
	end
	
	local Preview = vgui.Create("DModelPanel", Window) --Preview weapon model
	Preview:SetDirectionalLight(BOX_RIGHT, color_white)
	Preview:SetContentAlignment(5)
	Preview:SetSize(Window:GetWide() * 0.4, Window:GetTall() / 2)
	Preview:SetPos(-(Window:GetWide() / 30), 24)
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
	ComboColor:SetValue(SplatoonSWEPs:GetColorName(SplatoonSWEPs:GetConVarInt "InkColor"))
	for i = 1, SplatoonSWEPs.MAX_COLORS do
		ComboColor:AddChoice(SplatoonSWEPs:GetColorName(i))
	end
	
	function ComboColor:OnSelect(index, value, data)
		local cvar = SplatoonSWEPs:GetConVar "InkColor"
		if cvar then cvar:SetInt(index) end
	end
	
	local LabelColor = Label("Ink color:", Window)
	LabelColor:SizeToContents()
	LabelColor:SetPos(Window:GetWide() * 0.4, Window:GetTall() / 4 - 24)
	
	local ComboModel = vgui.Create("DComboBox", Window) --Playermodel selection box
	ComboModel:SetSortItems(false)
	ComboModel:SetPos(Window:GetWide() * 0.4, Window:GetTall() / 3 * 2)
	ComboModel:SetSize(Window:GetWide() * 0.31, 24)
	ComboModel:SetValue(SplatoonSWEPs.PlayermodelName[SplatoonSWEPs:GetConVarInt "Playermodel"])
	for i, c in ipairs(SplatoonSWEPs.PlayermodelName) do
		ComboModel:AddChoice(c)
	end
	
	function ComboModel:OnSelect(index, value, data)
		local cvar = SplatoonSWEPs:GetConVar "Playermodel"
		if cvar then cvar:SetInt(index) end
		SetPlayerModel(Playermodel)
	end
	
	local LabelModel = Label("Playermodel:", Window)
	LabelModel:SizeToContents()
	LabelModel:SetPos(Window:GetWide() * 0.4, Window:GetTall() / 3 * 2 - 24)
	
	local Options = vgui.Create("DPanel", Window) --Group of checkboxes
	Options:SetWide(Window:GetWide() / 4)
	Options:Dock(RIGHT)
	
	local OptionsText = {
		"Healing when stand",
		"Healing when in ink",
		"Reloading when stand",
		"Reloading when in ink",
	}
	local OptionsConVar = {
		"CanHealStand",
		"CanHealInk",
		"CanReloadStand",
		"CanReloadInk",
	}
	for i = 0, 3 do
		local Check = vgui.Create("DCheckBoxLabel", Options)
		Check:SetPos(4, 4 + 20 * i)
		Check:SetText(OptionsText[i + 1])
		Check:SetConVar(SplatoonSWEPs:GetConVarName(OptionsConVar[i + 1]))
		Check:SetValue(SplatoonSWEPs:GetConVarInt(OptionsConVar[i + 1]))
		Check:SetDark(true)
		Check:SizeToContents()
	end
end
