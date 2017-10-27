
--Emulates GLua functions
if not dofile then return end

for functionname, typename in pairs {
	["bool"] = "boolean",
	["function"] = "function",
	["number"] = "number",
	["string"] = "string",
	["table"] = "table",
	["angle"] = "angle",
	["vector"] = "vector",
} do getfenv()["is" .. functionname] =
	function(test)
		return type(test) == typename
	end
end

package.path = package.path .. ";./SZL/?.lua"
CompileString = loadstring
RunString = function(str) return assert(CompileString(str))() end
--load = nil
--loadstring = nil
if not bit and bit32 then bit, bit32 = bit32 end

function table.Copy(t, lookup_table)
	if not istable(t) then return t end
	local copy = {}
	setmetatable(copy, debug.getmetatable(t))
	for i, v in pairs(t) do
		if not istable(v) then
			copy[i] = v
		else
			lookup_table = lookup_table or {}
			lookup_table[t] = copy
			if lookup_table[v] then
				copy[i] = lookup_table[v] -- we already copied this table. reuse the copy.
			else
				copy[i] = table.Copy(v, lookup_table) -- not yet copied. copy it.
			end
		end
	end
	return copy
end

function Vector(v) return v end
function Angle(a) return angle end
function PrintTable(tbl, indent, did)
	if not indent then indent = 0 end
	did = did or {[tbl] = true}
	for k, v in pairs(tbl) do
		local formatting = string.rep("    ", indent) .. tostring(k) .. " = "
		if istable(v) and not did[v] and string.sub(tostring(v), 1, 9) == "table: 0x" then
			print(formatting)
			PrintTable(v, indent + 1, did)
			did[v] = true
		else
			print(formatting .. tostring(v))
		end
	end
end

function include(filename)
	local path = "./SZL/" .. filename
	return assert(loadfile(path))()
end
