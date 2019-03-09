AddCSLuaFile()
local serverflags = {FCVAR_ARCHIVE, FCVAR_REPLICATED, FCVAR_SERVER_CAN_EXECUTE}
local clientflags = {FCVAR_ARCHIVE, FCVAR_USERINFO}
local cvarlist = {}
local cvarname = ""
local cvarprefix = {}
local cvarseparator = "_"
module("greatzenkakuman.cvartree", package.seeall)

OverrideHelpText = "Override this setting with serverside value"

local function CreateCategory(nametable)
	local n, placeholder = "", cvarlist
	for _, s in ipairs(nametable) do
		n = string.format("%s%s%s", n, cvarseparator, s)
		placeholder[s] = placeholder[s] or {iscvarlayer = true, options = {}}
		placeholder = placeholder[s]
	end

	return n, placeholder
end

function GetCVarList() return cvarlist end
function GetCVarPrefix() return cvarprefix end
function SetCVarPrefix(p, options)
	table.Empty(cvarprefix)
	return AddCVarPrefix(p, options)
end

function AddCVarPrefix(p, options)
	if isstring(p) then
		table.insert(cvarprefix, p:lower())
		local placeholder = select(2, CreateCategory(cvarprefix))
		if istable(options) then table.Merge(placeholder.options, options) end
	elseif istable(p) then
		for _, s in ipairs(p) do AddCVarPrefix(s) end
	end

	return AddCVarPrefix
end

function RemoveCVarPrefix(n)
	for i = 1, n or 1 do table.remove(cvarprefix) end
	return RemoveCVarPrefix
end

function AddCVar(name, default, helptext, options)
	local nametable = istable(name) and name or table.Copy(cvarprefix)
	if isstring(name) then table.insert(nametable, name:lower()) end

	options = options or {}
	name = table.remove(nametable)
	local n, placeholder = CreateCategory(nametable)

	if #n == 0 then return end
	local cvartable = placeholder[name] or {}
	if not (options and options.clientside) then
		local svdefault = not (options and options.serverside) and -1 or default
		local svname = string.format("sv%s%s%s", n, cvarseparator, name)
		if isbool(svdefault) then svdefault = svdefault and 1 or 0 end
		cvartable.sv = CreateConVar(svname, tostring(svdefault), serverflags, helptext)
	end

	if not (options and options.serverside) then
		local clname = string.format("cl%s%s%s", n, cvarseparator, name)
		local cldefault = isbool(default) and (default and 1 or 0) or default
		cvartable.cl = CreateConVar(clname, tostring(cldefault), clientflags, helptext)
	end

	options.type = options.type == nil and type(default) or options.type
	cvartable.options = options
	cvartable.location = nametable
	placeholder[name] = cvartable
end

function GetCVarTable(cvar, root)
	local t = root or cvarlist
	if isstring(cvar) then cvar = {cvar} end
	for _, n in ipairs(cvar or {}) do
		t = assert(t[n:lower()], "GreatZenkakuMan's Module: preference is not found.")
	end

	return t
end

local TranslateType = {
	boolean = tobool,
	number = tonumber,
}
function GetValue(t, ply)
	local servervalue = t.sv and t.sv:GetString()
	local override = tonumber(servervalue)
	local translate = TranslateType[t.options.type]
	if override and override ~= -1 or SERVER and not (IsValid(ply) and ply:IsPlayer()) then
		return not translate and servervalue or translate(servervalue)
	elseif not t.options.serverside then
		local value = SERVER and ply:GetInfo(t.cl:GetName(), t.cl:GetDefault()) or t.cl:GetString()
		return not translate and value or translate(value)
	end
end

function GetPreference(cvar, ply, root)
	local t = GetCVarTable(cvar, root)
	if not (t.cl or t.sv) then
		return function(c, p) return GetPreference(c, p, t) end
	end

	return GetValue(t, ply)
end

function SetPreference(cvar, value)
	local t = GetCVarTable(cvar)
	if SERVER and not t.options.clientside then
		t.sv:SetString(tostring(value))
	elseif CLIENT and not t.options.serverside then
		t.cl:SetString(tostring(value))
	end
end

function SetPrintName(cvar, name)
	local t = GetCVarTable(cvar)
	t.printname = name
	if t.panel then t.panel:SetText(name) end
	if t.paneladmin then t.paneladmin:SetText(name) end
end

function IteratePreferences(root)
	local t = root and GetCVarTable(root) or cvarlist
	local function f(root)
		for p, pt in pairs(root or t) do
			if not istable(pt) then continue end
			if pt.iscvarlayer then
				f(pt)
			elseif pt.cl or pt.sv then
				coroutine.yield(p, pt)
			end
		end
	end

	return coroutine.wrap(f)
end

if SERVER then
	util.AddNetworkString "greatzenkakuman.cvartree.adminchange"
	net.Receive("greatzenkakuman.cvartree.adminchange", function(_, ply)
		if not ply:IsAdmin() then return end
		local cvar = GetConVar(net.ReadString())
		if not cvar then return end
		cvar:SetString(net.ReadString())
	end)

	return
end

-- PreferenceTable -> pt, IsEnabledPanel -> e
local idprefix = "GreatZenkakuMan's Module: CVarTree"
local function EnablePanel(pt, e)
	if not pt.paneladmin then return end
	pt.paneladmin:SetEnabled(e)
	for _, c in ipairs(pt.paneladmin:GetChildren()) do c:SetEnabled(e) end

	if pt.options.type == "number" then
		local s = e and "Dark" or "Default"
		local l, t = pt.paneladmin.Label, pt.paneladmin:GetTextArea()
		l:SetTextColor(l:GetSkin().Colours.Label[s])
		t:SetTextColor(t:GetSkin().Colours.Label[s])
		for _, c in ipairs(pt.paneladmin:GetChildren()) do
			c:SetMouseInputEnabled(e)
			c:SetKeyboardInputEnabled(e)
		end
	end
end

local waitafterchange = .1
local function GetOnChange(pt)
	if pt.options.type == "boolean" then
		return function(convar, old, new)
			if not (IsValid(LocalPlayer()) and LocalPlayer():IsAdmin()) then return end
			if pt.panel then pt.panel:SetChecked(tobool(new)) end
			if pt.paneladmin then pt.paneladmin:SetChecked(tobool(new)) end
		end
	elseif pt.options.type == "number" then
		return function(convar, old, new)
			if not (IsValid(LocalPlayer()) and LocalPlayer():IsAdmin()) then return end
			if pt.panel and not pt.panel:IsEditing() then pt.panel:SetValue(tonumber(new)) end
			if pt.paneladmin and not pt.paneladmin:IsEditing() then pt.paneladmin:SetValue(tonumber(new)) end
		end
	end
end

local function GetDermaPanelOnChange(pt)
	if not pt.paneladmin then return end
	local name, getvalue
	if pt.options.type == "boolean" then
		function pt.paneladmin:OnChange(value)
			net.Start "greatzenkakuman.cvartree.adminchange"
			net.WriteString(self.CVarName)
			net.WriteString(value and "1" or "0")
			net.SendToServer()
		end

		return pt.paneladmin.OnChange
	elseif pt.options.type == "number" then
		function pt.paneladmin:OnValueChanged(value)
			value = math.Round(value, self:GetDecimals())
			net.Start "greatzenkakuman.cvartree.adminchange"
			net.WriteString(self.CVarName)
			net.WriteString(tostring(value))
			net.SendToServer()
		end

		return pt.paneladmin.OnValueChanged
	end
end

local function MakeElement(p, admin, pt)
	local cvar = Either(admin, pt.sv, pt.cl)
	local panel = admin and "paneladmin" or "panel"
	if not cvar or Either(admin, pt.options.clientside, pt.options.serverside) then return end
	if pt.options.type == "boolean" then
		pt[panel] = vgui.Create("DCheckBoxLabel", p)
		pt[panel]:SetTextColor(pt[panel]:GetSkin().Colours.Label.Dark)
		pt[panel]:SetValue(cvar:GetBool())
	elseif pt.options.type == "number" then
		pt[panel] = vgui.Create("DNumSlider", p)
		pt[panel]:SetMinMax(pt.options.min, pt.options.max)
		pt[panel]:SetDecimals(pt.options.decimals or 0)
		pt[panel]:SetValue(cvar:GetInt())
		pt[panel].Label:SetTextColor(pt[panel].Label:GetSkin().Colours.Label.Dark)
	end

	pt[panel].CVarName = cvar:GetName()
	pt[panel]:SetText(pt.printname)

	local override
	if admin then
		local onchange = GetDermaPanelOnChange(pt)
		cvars.AddChangeCallback(pt[panel].CVarName, GetOnChange(pt))

		if not pt.options.serverside then
			local checked = cvar:GetInt() ~= -1
			EnablePanel(pt, checked)
			override = vgui.Create("DCheckBox", p)
			override:SetTooltip(OverrideHelpText)
			override:SetValue(checked)
			cvars.AddChangeCallback(pt[panel].CVarName, function(convar, old, new)
				if not (IsValid(LocalPlayer()) and LocalPlayer():IsAdmin()) then return end
				local checked = tonumber(new) ~= -1
				override:SetChecked(checked)
				EnablePanel(pt, checked)
			end)

			function override:OnChange(checked)
				EnablePanel(pt, checked)
				onchange(pt.cl:GetDefault())
				net.Start "greatzenkakuman.cvartree.adminchange"
				net.WriteString(pt[panel].CVarName)
				net.WriteString(checked and pt.cl:GetDefault() or "-1")
				net.SendToServer()
			end
		end
	else
		pt[panel]:SetConVar(cvar:GetName())
	end

	p:AddItem(override or pt[panel], override and pt[panel])
	if override then
		local t = (pt[panel]:GetTall() - 15) / 2
		local b = t + (t > math.floor(t) and 1 or 0)
		override:DockMargin(0, math.floor(t), 0, b)
		override:SetWidth(15)
		pt[panel]:Dock(TOP)
		pt[panel]:DockMargin(10, 0, 0, 0)
	end
end

local function MakeGUI(p, nametable, admin)
	local categories, ordered, preferences = {}, {}, {}
	for name, pt in pairs(GetCVarTable(nametable)) do
		if name:StartWith "__" then continue end
		if not istable(pt) then continue end
		pt.printname = pt.printname or pt.options and pt.options.printname or name
		if pt.iscvarlayer then
			categories[name] = pt
		elseif pt.options and not pt.options.hidden then
			if pt.options.order then
				pt.order = pt.options.order
				ordered[name] = pt
			else
				preferences[name] = pt
			end
		end
	end

	for _, pt in SortedPairsByMemberValue(ordered, "order") do MakeElement(p, admin, pt) end
	for _, pt in SortedPairsByMemberValue(preferences, "printname") do MakeElement(p, admin, pt) end
	for name, pt in SortedPairs(categories) do
		if pt.options.subcategory then
			pt.panel = p
			local l = p:Help(pt.printname)
			l:DockMargin(0, 0, 8, 8)
			l:SetTextColor(l:GetSkin().Colours.Tree.Hover)
		else
			pt.panel = vgui.Create("ControlPanel", p)
			pt.panel:SetLabel(pt.printname)
			p:AddPanel(pt.panel)
		end

		local nt = table.Copy(nametable)
		table.insert(nt, name)
		MakeGUI(pt.panel, nt, admin)
	end

	if #p.Items == 0 then p:Remove() end
end

function AddGUI(name)
	if isstring(name) then name = {name} end
	local t = GetCVarTable(name)
	local printname = t.printname or t.options and t.options.printname or name[#name]
	hook.Add("PopulateToolMenu", idprefix .. printname, function()
		spawnmenu.AddToolMenuOption("Utilities", "User",
		idprefix .. printname, printname, "", "", function(p)
			p:ClearControls()
			MakeGUI(p, name)
		end)

		spawnmenu.AddToolMenuOption("Utilities", "Admin",
		"CVarTreeAdmin" .. printname, printname, "", "", function(p)
			p:ClearControls()
			MakeGUI(p, name, true)
			local think = p.Think
			function p:Think()
				if not IsValid(LocalPlayer()) then return end
				p.Think = think
				if LocalPlayer():IsAdmin() then return end
				p:Remove()
			end
		end)
	end)
end

-- require "greatzenkakuman/cvartree"
-- print("Test>", greatzenkakuman)
-- if not greatzenkakuman then return end
-- print("Test>", greatzenkakuman.cvartree)

-- local ct = greatzenkakuman.cvartree
-- ct.AddCVar({"greatzenkakuman", "tree", "preference1"}, 0, "Text Help")
-- ct.AddCVarPrefix "greatzenkakuman" "tree"
-- ct.AddCVar("preference2", 25, "Overridable/GZM/Tree/preference2", {type = "number", min = 0, max = 50})
-- ct.SetCVarPrefix "greatzenkakuman" "tree2"
-- ct.AddCVar("serveronly1", 1, "Serveronly/GZM/Tree2/Serveronly1", {serverside = true})
-- ct.AddCVar("clientonly1", 1, "Clientonly/GZM/Tree2/Clientonly1", {clientside = true})
-- ct.SetCVarPrefix()
-- ct.AddCVar({"greatzenkakuman", "tree3", "subtree1", "four_layers"}, 2, "Four layers test", {type = "number", min = 1, max = 3, decimals = 1})

-- ct.SetPrintName("greatzenkakuman", "GreatZenkakuMan's Preference")
-- ct.SetPrintName({"greatzenkakuman", "tree"}, "Tree1")
-- ct.SetPrintName({"greatzenkakuman", "tree2"}, "Tree2")
-- ct.SetPrintName({"greatzenkakuman", "tree", "preference1"}, "Preference 1")
-- ct.SetPrintName({"greatzenkakuman", "tree", "preference2"}, "Preference 2")
-- ct.SetPrintName({"greatzenkakuman", "tree2", "serveronly1"}, "Server")
-- ct.SetPrintName({"greatzenkakuman", "tree2", "clientonly1"}, "Client")
-- ct.SetPrintName({"greatzenkakuman", "tree3"}, "Tree3")
-- ct.SetPrintName({"greatzenkakuman", "tree3", "subtree1"}, "Sub-tree1")
-- ct.SetPrintName({"greatzenkakuman", "tree3", "subtree1", "four_layers"}, "Four layer test")
-- if CLIENT then ct.AddGUI "greatzenkakuman" end
-- PrintTable(ct.GetCVarList())
