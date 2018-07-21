
local ss = SplatoonSWEPs
if not ss then return end
include "shared.lua"
include "baseinfo.lua"
include "cl_draw.lua"
include "ai_translations.lua"

function SWEP:PopupError(msg)
	msg = ss.Text.Error[msg]
	if not msg then return end
	notification.AddLegacy(msg, NOTIFY_ERROR, 10)
end

-- Fully copies the table, meaning all tables inside this table are copied too and so on
-- (normal table.Copy copies only their reference).
-- Does not copy entities of course, only copies their reference.
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
	-- we build a render order because sprites need to be drawn after models
	self.vRenderOrder = {}
	self.wRenderOrder = {}
	
	for e, r in pairs {
		[self.VElements] = self.vRenderOrder,
		[self.WElements] = self.wRenderOrder,
	} do
		for k, v in pairs(e) do
			if v.type == "Model" then
				table.insert(r, 1, k)
			elseif v.type == "Sprite" or v.type == "Quad" then
				table.insert(r, k)
			end
		end
	end
	
	-- Create a new table for every weapon instance
	self.VElements = FullCopy(self.VElements)
	self.WElements = FullCopy(self.WElements)
	self.ViewModelBoneMods = FullCopy(self.ViewModelBoneMods)
	self:CreateModels(self.VElements) -- create viewmodels
	self:CreateModels(self.WElements) -- create worldmodels
	
	-- Our initialize code
	self.EnoughSubWeapon = true
	self.PreviousInk = true
	self:GetBombMeterPosition(self.Secondary.TakeAmmo)
	self:MakeSquidModel()
	self.JustUsableTime = CurTime() - 1 -- For animation of ink tank light
	self:SharedInitBase()
	ss:ProtectedCall(self.ClientInit, self)
	self:ClientDeployBase()
end

function SWEP:Deploy(forced)
	if self:IsFirstTimePredicted() or forced then return self:ClientDeployBase() end
end

function SWEP:ClientDeployBase()
	if not IsValid(self.Owner) then return end
	if self.Owner:IsPlayer() then
		self.SurpressDrawingVM = nil
		self.HullDuckMins, self.HullDuckMaxs = self.Owner:GetHullDuck()
		self.ViewOffsetDucked = self.Owner:GetViewOffsetDucked()
		self:UpdateBonePositions(self.Owner:GetViewModel())
	end
	
	timer.Simple(0, function()
		if not IsValid(self) then return end
		self.InkColor = ss:GetColor(self:GetColorCode())
	end)
	
	return self:SharedDeployBase()
end

function SWEP:Holster()
	if self:GetInFence() then return false end
	if not IsValid(self.Owner) then return true end
	if self.Owner:IsPlayer() then
		self.SurpressDrawingVM = true
		local vm = self.Owner:GetViewModel()
		if IsValid(vm) then self:ResetBonePositions(vm) end
		if self:GetBecomeSquid() and self.HullDuckMins then
			self.Owner:SetHullDuck(self.HullDuckMins, self.HullDuckMaxs)
			self.Owner:SetViewOffsetDucked(self.ViewOffsetDucked)
		end
	end
	
	return self:SharedHolsterBase()
end

-- It's important to remove CSEnt with CSEnt:Remove() when it's no longer needed.
function SWEP:OnRemove()
	for k, v in pairs(self.VElements) do
		if IsValid(v.modelEnt) then v.modelEnt:Remove() end
	end
	for k, v in pairs(self.WElements) do
		if IsValid(v.modelEnt) then v.modelEnt:Remove() end
	end
	
	if IsValid(self.Squid) then self.Squid:Remove() end
	return self:Holster()
end

function SWEP:Think()
	if not IsValid(self.Owner) or self:GetHolstering() then return end
	if self:IsFirstTimePredicted() then
		local enough = self:GetInk() > self.Secondary.TakeAmmo
		if not self.EnoughSubWeapon and enough then
			self.JustUsableTime = CurTime() - LocalPlayer():Ping() / 1000
			if self:IsCarriedByLocalPlayer() then
				surface.PlaySound(ss.BombAvailable)
			end
		end
		self.EnoughSubWeapon = enough
	end
	
	if IsValid(self.Squid) then
		if self:GetPMID() == ss.PLAYER.OCTO then
			if self.SquidModelNumber ~= ss.SQUID.OCTO then
				self.Squid:SetModel(ss.Squidmodel[ss.SQUID.OCTO])
				self.SquidModelNumber = ss.SQUID.OCTO
			end
		elseif self.SquidModelNumber ~= ss.SQUID.INKLING then
			self.Squid:SetModel(ss.Squidmodel[ss.SQUID.INKLING])
			self.SquidModelNumber = ss.SQUID.INKLING
		end 
	else
		self:MakeSquidModel()
	end
	
	if self:GetBecomeSquid() then
		self:DrawShadow(not self:Crouching())
	end
	
	self.WElements.weapon.bone = self:GetThrowing()
	and "ValveBiped.Bip01_L_Hand" or "ValveBiped.Bip01_R_Hand"
	self:ProcessSchedules()
	self:SharedThinkBase()
	ss:ProtectedCall(self.ClientThink, self)
end
