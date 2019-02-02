
local ss = SplatoonSWEPs
if not ss then return end

require "greatzenkakuman/cvartree"
local gc = greatzenkakuman.cvartree
local ServerPrefix = "sv_splatoonsweps_"
local ClientPrefix = "cl_splatoonsweps_"
local ServerFlags = {FCVAR_ARCHIVE, FCVAR_REPLICATED, FCVAR_SERVER_CAN_EXECUTE}
local CVarDesc = {ss.Text.CVars}
local function RegisterConVars(prefix, group)
	local desc = CVarDesc[1]
	group = group or ss.Options
	for name, default in pairs(group) do
		if istable(default) and default[1] == nil then
			table.insert(CVarDesc, 1, desc[name])
			RegisterConVars(prefix .. name:lower() .. "_", default)
			continue
		end
		
		local IsServerside = istable(default)
		local IsClientside = isstring(default)
		if CLIENT and prefix:find(ClientPrefix) and not IsServerside then
			default = isbool(default) and (default and 1 or 0) or default
			CreateClientConVar(prefix .. name:lower(), default, true, true, desc[name])
		end
		
		if prefix:find(ServerPrefix) and not IsClientside then
			if IsServerside then
				default = default[1]
				group[name] = default
				if isbool(default) then
					default = default and "1" or "0"
				end
			else
				default = -1
			end
			
			CreateConVar(prefix .. name:lower(), default, ServerFlags, desc[name])
		end
	end
	
	table.remove(CVarDesc, 1)
end

if CLIENT then
	RegisterConVars(ClientPrefix)
	CVarDesc = {ss.Text.CVars}
end

RegisterConVars(ServerPrefix)

-- Arguments:
--   string name    | The option name.
--   bool forced    | True to return serverside forced option name.
-- Returning:
--   function (if the option is a subcategory)
--   string         | CVar name.
function ss.GetConVarName(name, forced)
	local Options = ss.Options
	local CVarName = Either(forced ~= nil, forced, SERVER)
	and ServerPrefix or ClientPrefix
	local function GetConVarName(name, forced)
		if istable(Options[name]) then
			Options = Options[name]
			CVarName = CVarName .. name .. "_"
			return GetConVarName
		end
		
		return CVarName .. name
    end
	
	return GetConVarName(name, forced)
end

function ss.GetConVar(name, forced)
	return GetConVar(ss.GetConVarName(name, forced))
end

-- Fetch a given option.
-- Arguments:
--   Player ply     | Whose option the function will return.
--   string name    | The option name.
-- Returning:
--   function (if the option is a subcategory)
--   number/bool (depends on default value)
function ss.GetOption(name, ply)
	local function f(Prefix, Options)
		return function(name, ply)
			local Prefix = Prefix or ""
			local Options = Options or ss.Options
			local default = Options[name]
			local fullname = Prefix .. name:lower()
			if istable(default) then
				return f(fullname .. "_", default)
			end
			
			local cvar = GetConVar(ServerPrefix .. fullname)
			cvar = ss.ProtectedCall(cvar and cvar.GetInt, cvar)
			if not cvar or cvar < 0 then
				cvar = default
				fullname = ClientPrefix .. fullname
				local defint = isbool(default) and (default and 1 or 0) or default
				if SERVER and IsValid(ply) then
					cvar = ss.ProtectedCall(ply.GetInfoNum, ply, fullname, defint) or defint
				else
					cvar = GetConVar(fullname)
					cvar = ss.ProtectedCall(cvar and cvar.GetInt, cvar) or defint
				end
			end
			
			if isbool(default) then return cvar > 0 end
			return cvar
		end
	end
	
	return f()(name, ply)
end
