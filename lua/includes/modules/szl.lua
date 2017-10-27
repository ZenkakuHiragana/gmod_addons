
if dofile then
	dofile "SZL/gluacompatible.lua"
end

setmetatable(_G, {__tostring = function() return "Global Env" end})
local _M = setmetatable({}, {__index = _G, __tostring = function() return "table: SZL" end})
function _M.namespace(name) setfenv(2, _G[name]) end
SZL = _M

SZL.namespace "SZL"
local metamethods = {
	"add", "call", "concat", "div", "eq", "gc", "ipairs", "le", "len", "lt",
	"metatable", "mod", "mode", "mul", "newstring", "pairs", "pow", "sub", "tostring", "unm"
}

function makeclass(baseclass)
	local meta, self = {}, {}
	self.meta = meta
	self.BaseClass = baseclass
	self.self = self
	meta.__env = getfenv(2)
	meta.__isinstance = true
	meta.__index = baseclass or getfenv(2)
	meta.__tostring = meta.__tostring or function() return "class" end
	setmetatable(self, meta)
	setfenv(2, self)
end

function endclass(metaoverride)
	local instance = getfenv(2)
	local meta = debug.getmetatable(instance)
	if metaoverride then
		for _, v in ipairs(metamethods) do
			local k = "__" .. v
			meta[k] = metaoverride[k] or meta[k]
		end
	end
	setfenv(2, meta.__env)
	meta.__env = nil
	instance.meta = nil
	return instance
end

function enum(table)
	local self, meta = {}, {}
	local i, len, marked = 0, 0, {}
	for k, v in pairs(table) do
		if isstring(k) and isnumber(v) then
			self[k] = v
			marked[v] = true
		elseif isnumber(k) and isstring(v) then
			repeat
				i = i + 1
			until not marked[i]
			self[v] = i
		end
		len = len + 1
	end
	self["len"] = len
	
	meta.__metatable = meta
	function meta.__newindex()
		error "attempt to write to a read-only table."
	end
	
	function meta.__len(op)
		return op.len
	end
	
	function meta.__tostring(op)
		return "enum (length = " .. tostring(#op) .. ")"
	end
	
	function meta.__index()
		error "attempt to index with an invalid key"
	end
	
	return setmetatable(self, meta)
end

--------------------------------------------------

SZL = setmetatable(SZL, {__index = _G, __tostring = showSZL})
