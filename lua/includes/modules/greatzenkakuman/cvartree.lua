AddCSLuaFile()
local serverflags = {FCVAR_REPLICATED, FCVAR_SERVER_CAN_EXECUTE}
local clientflags = {FCVAR_USERINFO}
local cvarlist = {}
local cvarname = ""
local cvarprefix = {}
local cvarseparator = "_"
local assert, CreateConVar, Either, GetConVar, hook,
ipairs, isstring, istable, IsValid, math, net,
pairs, spawnmenu, string, table, tonumber, util, vgui =
assert, CreateConVar, Either, GetConVar, hook,
ipairs, isstring, istable, IsValid, math, net,
pairs, spawnmenu, string, table, tonumber, util, vgui
module("greatzenkakuman.cvartree", package.seeall)

BOOL, INT = 1, 2
OverrideHelpText = "Override this setting with serverside value"
function GetCVarList() return cvarlist end
function GetCVarPrefix() return cvarprefix end
function SetCVarPrefix(p)
	table.Empty(cvarprefix)
	return AddCVarPrefix(p)
end

function AddCVarPrefix(p)
	if p then
		assert(isstring(p), "GreatZenkakuMan's Module: string expected.")
		table.insert(cvarprefix, p)
	end

	return AddCVarPrefix
end

function AddCVar(name, default, helptext, options)
	local nametable, n, placeholder = istable(name) and name or table.Copy(cvarprefix), "", cvarlist
	if isstring(name) then table.insert(nametable, name) end
	name = table.remove(nametable)
	for _, s in ipairs(nametable) do
		n = string.format("%s%s%s", n, cvarseparator, s)
		placeholder[s] = placeholder[s] or {iscvarlayer = true}
		placeholder = placeholder[s]
	end
	
	if #n == 0 then return end
	local cvartable = placeholder[name] or {}
	if not (options and options.clientside) then
		local svdefault = options and options.serverside and default or -1
		local svname = string.format("sv%s%s%s", n, cvarseparator, name)
		cvartable.sv = CreateConVar(svname, svdefault, serverflags, helptext)
	end

	if not (options and options.serverside) then
		local clname = string.format("cl%s%s%s", n, cvarseparator, name)
		cvartable.cl = CreateConVar(clname, default, clientflags, helptext)
	end

	cvartable.options = options
	placeholder[name] = cvartable
end

function GetCVarTable(cvar)
	local t = cvarlist
	if isstring(cvar) then cvar = {cvar} end
	for _, n in ipairs(cvar or {}) do
		t = assert(t[n], "GreatZenkakuMan's Module: preference is not found.")
	end

	return t
end

function GetPreference(cvar, ply)
	local t = GetCVarTable(cvar)
	if not (t.cl or t.sv) then return t end
	local servervalue = t.sv and t.sv:GetString()
	local override = tonumber(servervalue) and tonumber(servervalue) ~= -1
	if override or SERVER and not (IsValid(ply) and ply:IsPlayer()) then
		return servervalue
	elseif not t.options.serverside then
		if SERVER then
			return ply:GetInfo(t.cl:GetName(), t.cl:GetDefault())
		else
			return t.cl:GetString()
		end
	end
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
	if not t.panel then return end
	t.panel:SetText(name)
end

if SERVER then
	util.AddNetworkString "greatzenkakuman.cvartree.adminchange"
	net.Receive("greatzenkakuman.cvartree.adminchange", function(_, ply)
		if not ply:IsAdmin() then return end
		local cvar = GetConVar(net.ReadString())
		if not cvar then return end
		cvar:SetInt(net.ReadInt(32))
	end)

	return
end

local idprefix = "GreatZenkakuMan's Module: CVarTree"
local function EnablePanel(t, p, e)
	p:SetEnabled(e)
	for _, c in ipairs(p:GetChildren()) do c:SetEnabled(e) end
	if t == BOOL then
		p:SetConVar(e and p.ConVarName or "")
	elseif t == INT then
		p.Label:SetTextColor(p.Label:GetSkin().Colours.Label[e and "Dark" or "Default"])
		p:GetTextArea():SetTextColor(p:GetTextArea():GetSkin().Colours.Label[e and "Dark" or "Default"])
		for _, c in ipairs(p:GetChildren()) do
			c:SetMouseInputEnabled(e)
			c:SetKeyboardInputEnabled(e)
		end
	end
end

local function MakeGUI(p, nametable, admin)
	p:ClearControls()
	for preference, pt in pairs(GetCVarTable(nametable)) do
		if not istable(pt) then continue end
		if pt.iscvarlayer then
			pt.panel = vgui.Create("ControlPanel", p)
			pt.panel:SetLabel(pt.printname or preference)
			p:AddPanel(pt.panel)
			local nt = table.Copy(nametable)
			table.insert(nt, preference)
			MakeGUI(pt.panel, nt, admin)
		elseif pt.options then
			local cvar = Either(admin, pt.sv, pt.cl)
			if not cvar or Either(admin, pt.options.clientside, pt.options.serverside) then continue end
			local override, variable
			if pt.options.type == BOOL then
				variable = vgui.Create("DCheckBoxLabel", p)
				variable:SetTextColor(variable:GetSkin().Colours.Label.Dark)
				variable.ConVarName = cvar:GetName()
			elseif pt.options.type == INT then
				variable = vgui.Create("DNumSlider", p)
				variable:SetMinMax(pt.options.min, pt.options.max)
				variable:SetDecimals(pt.options.decimals or 0)
				variable.Label:SetTextColor(variable.Label:GetSkin().Colours.Label.Dark)
			end

			variable:SetConVar(cvar:GetName())
			variable:SetText(pt.printname or preference)
			pt.panel = variable
			if admin and not pt.options.serverside then
				EnablePanel(pt.options.type, variable, pt.sv:GetInt() ~= -1)
				override = vgui.Create("DCheckBox", p)
				override:SetTooltip(OverrideHelpText)

				function override:OnChange(checked)
					EnablePanel(pt.options.type, variable, checked)
					net.Start "greatzenkakuman.cvartree.adminchange"
					net.WriteString(pt.sv:GetName())
					net.WriteInt(checked and cvar:GetDefault() or -1, 32)
					net.SendToServer()
				end
			end

			p:AddItem(override or variable, override and variable)
			if override then
				local t = (variable:GetTall() - 15) / 2
				local b = t + (t > math.floor(t) and 1 or 0)
				override:DockMargin(0, math.floor(t), 0, b)
				override:SetWidth(15)
				variable:Dock(TOP)
				variable:DockMargin(10, 0, 0, 0)
			end
		end
	end
end

function AddGUI(name)
	if isstring(name) then name = {name} end
	local t = GetCVarTable(name)
	hook.Add("PopulateToolMenu", idprefix .. t.printname, function()
		spawnmenu.AddToolMenuOption("Utilities", "User",
		idprefix .. t.printname, t.printname, "", "", function(p)
			MakeGUI(p, name)
		end)

		spawnmenu.AddToolMenuOption("Utilities", "Admin",
		"CVarTreeAdmin" .. t.printname, t.printname, "", "", function(p)
			MakeGUI(p, name, true)
		end)
	end)
end

-- require "greatzenkakuman/cvartree"
-- print("Test>", greatzenkakuman)
-- if not greatzenkakuman then return end
-- print("Test>", greatzenkakuman.cvartree)

-- local ct = greatzenkakuman.cvartree
-- ct.AddCVar({"greatzenkakuman", "tree", "preference1"}, 0, "Text Help", {type = ct.BOOL})
-- ct.AddCVarPrefix "greatzenkakuman" "tree"
-- ct.AddCVar("preference2", 25, "Overridable/GZM/Tree/preference2", {type = ct.INT, min = 0, max = 50})
-- ct.SetCVarPrefix "greatzenkakuman" "tree2"
-- ct.AddCVar("serveronly1", 1, "Serveronly/GZM/Tree2/Serveronly1", {serverside = true, type = ct.BOOL})
-- ct.AddCVar("clientonly1", 1, "Clientonly/GZM/Tree2/Clientonly1", {clientside = true, type = ct.BOOL})
-- ct.SetCVarPrefix()
-- ct.AddCVar({"greatzenkakuman", "tree3", "subtree1", "four_layers"}, 2, "Four layers test", {type = ct.INT, min = 1, max = 3, decimals = 1})

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
