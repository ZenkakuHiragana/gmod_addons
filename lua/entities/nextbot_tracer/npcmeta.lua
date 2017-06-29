
local metatable = FindMetaTable("NextBot")
local function emptybool() return false end
local function emptyentity() return NULL end
local function emptynumber() return 0 end
local function ReplaceFunction(funcname, func)
	if not isstring(funcname) or not isfunction(func) then return end
	local oldfunc = metatable.MetaBaseClass[funcname]
	
	if isfunction(oldfunc) then
		metatable[funcname] = function(self, ...)
			if self.NextBotIsFakeNPC then
				return func(self, ...)
			elseif isfunction(oldfunc) then
				return oldfunc(self, ...)
			end
			error(string.format("attempt to call method '%s' (a %s value)", funcname, type(oldfunc)))
		end
		return metatable[funcname]
	end
end

ENT.Replacement.IsNPC = function() return true end
ENT.Replacement.CapabilitiesGet = function(self) return self.Capabilities.Total end
ENT.Replacement.ConditionName = function(self, id) return "Fake function lol" end
ENT.Replacement.GetActiveWeapon = function(self) return self.Equipment.Entity end
ENT.Replacement.GetArrivalActivity = emptynumber
ENT.Replacement.GetArrivalSequence = emptynumber
ENT.Replacement.GetBlockingEntity = emptyentity
ENT.Replacement.GetCurrentWeaponProficiency = function() return WEAPON_PROFICIENCY_PERFECT end
ENT.Replacement.GetExpression = function() return "" end
ENT.Replacement.GetHullType = function() return HULL_HUMAN end
ENT.Replacement.GetMovementActivity = emptynumber
ENT.Replacement.GetMovementSequence = emptynumber
ENT.Replacement.GetNPCState = function(self) return self:GetState() end
ENT.Replacement.GetPathDistanceToGoal = emptynumber
ENT.Replacement.GetPathTimeToGoal = emptynumber
ENT.Replacement.GetShootPos = function(self) return self:GetRightHand().Pos end
ENT.Replacement.GetTarget = function(self) return self:GetEnemy() end
ENT.Replacement.Give = emptyentity
ENT.Replacement.IsCurrentSchedule = function(self, sched) return self:GetSchedule() == sched end
ENT.Replacement.IsMoving = function(self) return self:GetActivity() ~= self.Act.Idle end
ENT.Replacement.IsRunningBehavior = emptybool
ENT.Replacement.IsUnreachable = emptybool
ENT.Replacement.PlaySentence = function(self, sentence, delay, volume) return -1 end
ENT.Replacement.SetLastPosition = function(self, position) self.m_vecLastPosition = position end
ENT.Replacement[1] = function(self)
	local function empty() end
	local replaced = {}
	for k, v in pairs(self.Replacement) do
		if isstring(k) then replaced[k] = false end
	end
	
	--Iterate all NPC functions
	for k, v in pairs(FindMetaTable("NPC")) do
		if not isstring(k) or k:find("__") then continue end --Skip if current function is meta event.
		if k:find("VJ") then continue end --Avoid copying VJ functions.
		if isstring(k) and isfunction(v) and --Make sure it has a string key and is a function.
			(not self.Replacement[k] or isfunction(self.Replacement[k])) then
			--Replace the function if Nextbot MetaTable has the same key.
			local result = ReplaceFunction(k, self.Replacement[k] or empty)
			if result then --Successfully replaced.
				if isbool(replaced[k]) then
					replaced[k] = true
				end
			else --NPC has the function but NextBot doesn't.
				self[k] = v
			end
		end
	end
	
	--NPC has the function but NextBot doesn't.
	for k, v in pairs(replaced) do --And there're more replacements.
		if not v and isfunction(self.Replacement[k]) then
			self[k] = self.Replacement[k]
		end
	end
end