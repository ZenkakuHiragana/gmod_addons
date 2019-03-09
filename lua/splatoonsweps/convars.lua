
local ss = SplatoonSWEPs
if not ss then return end

require "greatzenkakuman/cvartree"
local gc = greatzenkakuman.cvartree
local prefix = "Splatoon SWEPs: "

gc.OverrideHelpText = ss.Text.OverrideHelpText
gc.SetCVarPrefix("splatoonsweps", {printname = ss.Text.Category})
local function RegisterConVars(opt, helptext, guitext)
	for cvarname, cvartable in pairs(opt) do
		if cvarname:StartWith "__" then continue end
		if not istable(cvartable) then cvartable = {cvartable} end
		if cvartable[1] ~= nil then
			local options = table.Copy(cvartable)
			options.printname, options[1] = guitext[cvarname]
			gc.AddCVar(cvarname, cvartable[1], prefix .. helptext[cvarname], options)
		else
			gc.AddCVarPrefix(cvarname, {
				subcategory = cvartable.__subcategory,
				printname = ss.Text.CategoryNames[cvarname]
				or ss.Text.PrintNames[cvarname] or guitext[cvarname].__printname,
			})

			RegisterConVars(cvartable, helptext[cvarname], guitext[cvarname])
			gc.RemoveCVarPrefix()
		end
	end
end

RegisterConVars(ss.Options, ss.Text.CVars, ss.Text.Options)
if CLIENT then gc.AddGUI "splatoonsweps" end

local RealmPrefix = {[true] = "sv", [false] = "cl"}
function ss.GetConVarName(name, serverside)
	local cvar = (RealmPrefix[serverside] or "") .. "_splatoonsweps"
	if isstring(name) then
		return cvar .. "_" .. name
	elseif istable(name) then
		for _, n in ipairs(name) do cvar = cvar .. "_" .. n end
		return cvar
	end
end

function ss.GetConVar(name, serverside)
	local prefix = serverside == nil and "cl" or ""
	return GetConVar(prefix .. ss.GetConVarName(name, serverside))
end

-- Fetch a given option.
-- Arguments:
--   string name    | The option name.
--   Player ply     | Whose option the function will return.
-- Returning:
--   function (if the option is a subcategory)
--   number/bool (depends on default value)
function ss.GetOption(name, ply)
	local nametable = {"splatoonsweps"}
	if isstring(name) then name = {name} end
	for _, n in ipairs(name) do table.insert(nametable, n:lower()) end
	return gc.GetPreference(nametable, ply)
end
