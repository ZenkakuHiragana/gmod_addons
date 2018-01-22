
include "shared.lua"
include "baseinfo.lua"
include "cl_draw.lua"

local errorduration = 10
function SWEP:PopupError(msg)
	notification.AddLegacy(msg, NOTIFY_ERROR, errorduration)
end

function SWEP:IsFirstTimePredicted()
	return game.SinglePlayer() or IsFirstTimePredicted()
end

--Fully copies the table, meaning all tables inside this table are copied too and so on
--(normal table.Copy copies only their reference).
--Does not copy entities of course, only copies their reference.
local function FullCopy(t)
	if not istable(t) then return t end
	
	local res = {}
	for k, v in pairs(t) do
		if istable(v) then
			if v == t then
				res[k] = res
			else
				res[k] = FullCopy(v)
			end
		elseif isvector(v) then
			res[k] = Vector(v)
		elseif isangle(v) then
			res[k] = Angle(v)
		else
			res[k] = v
		end
	end
	
	return res
end

function SWEP:Initialize()
	--we build a render order because sprites need to be drawn after models
	self.vRenderOrder = {}
	self.wRenderOrder = {}
	for k, v in pairs(self.VElements) do
		if v.type == "Model" then
			table.insert(self.vRenderOrder, 1, k)
		elseif v.type == "Sprite" or v.type == "Quad" then
			table.insert(self.vRenderOrder, k)
		end
	end

	for k, v in pairs(self.WElements) do
		if v.type == "Model" then
			table.insert(self.wRenderOrder, 1, k)
		elseif v.type == "Sprite" or v.type == "Quad" then
			table.insert(self.wRenderOrder, k)
		end
	end
	
	--Create a new table for every weapon instance
	self.VElements = FullCopy(self.VElements)
	self.WElements = FullCopy(self.WElements)
	self.ViewModelBoneMods = FullCopy(self.ViewModelBoneMods)
	self:CreateModels(self.VElements) --create viewmodels
	self:CreateModels(self.WElements) --create worldmodels
	
	--init view model bone build function
	if IsValid(self.Owner) and self.Owner:IsPlayer() then
		local vm = self.Owner:GetViewModel()
		if IsValid(vm) then self:ResetBonePositions(vm) end
	end
	
	--Our initialize code
	local icon = "vgui/entities/" .. self:GetClass()
	if not file.Exists(icon .. ".vmt", "GAME") then icon = "weapons/swep" end
	self.WepSelectIcon = surface.GetTextureID(icon)
	self.EnoughSubWeapon = true
	self.PreviousInk = true
	self.Holstering = false
	self:GetBombMeterPosition(self.Secondary.TakeAmmo)
	self:MakeSquidModel()
	self:ChangeHullDuck()
	
	self.JustUsableTime = CurTime() - 1 --For animation of ink tank light
	if IsValid(self.Owner) and self.Owner:IsPlayer() then
		self.HullDuckMins, self.HullDuckMaxs = self.Owner:GetHullDuck()
		self.ViewOffsetDucked = self.Owner:GetViewOffsetDucked()
	end
	
	self:SharedInitBase()
	if isfunction(self.ClientInit) then self:ClientInit() end
	return self:ClientDeployBase()
end

function SWEP:Deploy()
	if self:IsFirstTimePredicted() then return self:ClientDeployBase() end
end

function SWEP:ClientDeployBase()
	self.CanHealStand, self.CanHealInk, self.CanReloadStand,  self.CanReloadInk = false, false, false, false
	self.HullDuckMins, self.HullDuckMaxs = self.Owner:GetHullDuck()
	self.ViewOffsetDucked = self.Owner:GetViewOffsetDucked()
	self:ChangeHullDuck()
	return self:SharedDeployBase()
end

function SWEP:Holster()
	if not (IsValid(self.Owner) and self:IsFirstTimePredicted()) then return end
	local vm = self.Owner:GetViewModel()
	if IsValid(vm) then self:ResetBonePositions(vm) end
	if self:GetPMID() ~= SplatoonSWEPs.PLAYER.NOSQUID then
		self.Owner:SetHullDuck(self.HullDuckMins, self.HullDuckMaxs)
		self.Owner:SetViewOffsetDucked(self.ViewOffsetDucked)
	end
	
	return self:SharedHolsterBase()
end

--It's important to remove CSEnt with CSEnt:Remove() when it's no longer needed.
function SWEP:OnRemove()
	for k, v in pairs(self.VElements) do
		if IsValid(v.modelEnt) then v.modelEnt:Remove() end
	end
	for k, v in pairs(self.WElements) do
		if IsValid(v.modelEnt) then v.modelEnt:Remove() end
	end
	
	if IsValid(self.Squid) then self.Squid:Remove() end
	if IsValid(self.Owner) then
		local vm = isfunction(self.Owner.GetViewModel) and self.Owner:GetViewModel()
		if IsValid(vm) then self:ResetBonePositions(vm) end
		self.Owner:ManipulateBoneAngles(0, angle_zero)
	end
	
	return self:Holster()
end

function SWEP:Think()
	if not IsValid(self.Owner) or self.Holstering then return end
	if self:IsFirstTimePredicted() then
		local enough = self:GetInk() > self.Secondary.TakeAmmo
		if not self.EnoughSubWeapon and enough then
			self.JustUsableTime = CurTime()
			surface.PlaySound(SplatoonSWEPs.BombAvailable)
		end
		self.EnoughSubWeapon = enough
	end
	
	if IsValid(self.Squid) then
		if self:GetPMID() == SplatoonSWEPs.PLAYER.OCTO then
			if self.SquidModelNumber ~= SplatoonSWEPs.SQUID.OCTO then
				self.Squid:SetModel(SplatoonSWEPs.Squidmodel[SplatoonSWEPs.SQUID.OCTO])
				self.SquidModelNumber = SplatoonSWEPs.SQUID.OCTO
			end
		elseif self.SquidModelNumber ~= SplatoonSWEPs.SQUID.INKLING then
			self.Squid:SetModel(SplatoonSWEPs.Squidmodel[SplatoonSWEPs.SQUID.INKLING])
			self.SquidModelNumber = SplatoonSWEPs.SQUID.INKLING
		end 
	else
		self:MakeSquidModel()
	end
	
	if self:GetPMID() ~= SplatoonSWEPs.PLAYER.NOSQUID then
		self.Owner:SetMaterial(self.IsSquid and "color" or "")
		self:DrawShadow(not self.IsSquid)
	end
	
	self:ProcessSchedules()
	self:SharedThinkBase()
	if isfunction(self.ClientThink) then return self:ClientThink() end
end
