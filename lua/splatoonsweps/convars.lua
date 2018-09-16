
local ss = SplatoonSWEPs
if not ss then return end
local ServerPrefix = "sv_splatoonsweps_"
local ClientPrefix = "cl_splatoonsweps_"
local ServerFlags = {FCVAR_ARCHIVE, FCVAR_REPLICATED, FCVAR_SERVER_CAN_EXECUTE}
local CVarDesc = {ss.Text.CVarDescription}
local function RegisterConVars(prefix, group)
	local desc = CVarDesc[1]
	group = group or ss.Options
	for name, default in pairs(group) do
		if istable(default) and not default[1] then
			table.insert(CVarDesc, 1, desc[name])
			RegisterConVars(prefix .. name:lower() .. "_", default)
		elseif prefix:find(ServerPrefix) and not isstring(default) then
			CreateConVar(prefix .. name:lower(), istable(default) and default[1] or -1, ServerFlags, desc[name])
			if istable(default) then group[name] = default[1] end
		elseif CLIENT and not istable(default) then
			default = isbool(default) and (default and 1 or 0) or default
			CreateClientConVar(prefix .. name:lower(), default, true, true, desc[name])
		end
	end
	
	table.remove(CVarDesc, 1)
end

RegisterConVars(ServerPrefix)
if CLIENT then
	CVarDesc = {ss.Text.CVarDescription}
	RegisterConVars(ClientPrefix)
end

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
