
local function ItemTintInit(self, mat, values)
	-- Store the name of the variable we want to set
	self.ResultTo = values.resultvar
end

local function ItemTintBind(self, mat, ent)
	if not IsValid(ent) then return end
	if isfunction(ent.GetInkColorProxy) and isvector(ent:GetInkColorProxy()) then
		--If the target ent has a function called GetInkColorProxy then use that
		--The function SHOULD return a Vector with the chosen ink color.
		mat:SetVector(self.ResultTo, ent:GetInkColorProxy())
	end
end

local matInit, matBind = ItemTintInit, ItemTintBind
if matproxy.ProxyList["ItemTintColor"] then
	local OldItemTintInit = matproxy.ProxyList["ItemTintColor"].init
	local OldItemTintBind = matproxy.ProxyList["ItemTintColor"].bind
	matInit = function(self, mat, values)
		OldItemTintInit(self, mat, values)
		ItemTintInit(self, mat, values)
	end
	matBind = function(self, mat, ent)
		OldItemTintBind(self, mat, ent)
		ItemTintBind(self, mat, ent)
	end
end

matproxy.Add(
{
	name = "ItemTintColor", 
	init = matInit,
	bind = matBind
})