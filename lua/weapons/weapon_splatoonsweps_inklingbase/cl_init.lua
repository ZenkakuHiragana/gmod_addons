
local ss = SplatoonSWEPs
if not ss then return end
include "shared.lua"
include "baseinfo.lua"
include "cl_draw.lua"
include "ai_translations.lua"

local inktank = {
	type = "Model",
	model = ss.InkTankModel,
	bone = "ValveBiped.Bip01_Spine4",
	rel = "",
	pos = Vector(-20, 3, 0),
	angle = Angle(0, 75, 90),
	size = Vector(1, 1, 1),
	color = Color(255, 255, 255, 255),
	surpresslightning = false,
	material = "",
	skin = 0,
	bodygroup = {},
	inktank = true,
}
local subweaponusable = {
	type = "Sprite",
	sprite = "sprites/flare1",
	bone = "ValveBiped.Bip01_Spine4",
	rel = "inktank",
	pos = Vector(0, 0, 25.5),
	size = {x = 12, y = 12},
	color = Color(255, 255, 255, 255),
	nocull = true,
	additive = true,
	ignorez = false,
}

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
	self.VElements = self.VElements or {}
	self.WElements = self.WElements or {}
	self.WElements.inktank = inktank
	self.WElements.subweaponusable = subweaponusable

	for e, r in pairs {
		[self.VElements] = self.vRenderOrder,
		[self.WElements] = self.wRenderOrder,
	} do
		for k, v in pairs(e) do
			if v.type == "Model" then
				ss.tablepush(r, k)
			elseif v.type == "Sprite" or v.type == "Quad" then
				r[#r + 1] = k
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
	self.Cursor = {x = ScrW() / 2, y = ScrH() / 2}
	self:MakeSquidModel()
	self.JustUsableTime = CurTime() - 1 -- For animation of ink tank light
	self:SharedInitBase()
	ss.ProtectedCall(self.ClientInit, self)
	self:Deploy()
end

function SWEP:Deploy()
	if not IsValid(self.Owner) then return end
	if self.Owner:IsPlayer() then
		self.SurpressDrawingVM = nil
		self.HullDuckMins, self.HullDuckMaxs = self.Owner:GetHullDuck()
		self.ViewOffsetDucked = self.Owner:GetViewOffsetDucked()
		self:UpdateBonePositions(self:GetViewModel())
	end

	self:GetOptions()
	ss.ProtectedCall(self.ClientDeploy, self)
	return self:SharedDeployBase()
end

function SWEP:Holster()
	if self:GetInFence() then return false end
	if not IsValid(self.Owner) then return true end
	if self.Owner:IsPlayer() then
		self.SurpressDrawingVM = true
		local vm = self:GetViewModel()
		if IsValid(vm) then self:ResetBonePositions(vm) end
		if self:GetNWBool "becomesquid" and self.HullDuckMins then
			self.Owner:SetHullDuck(self.HullDuckMins, self.HullDuckMaxs)
			self.Owner:SetViewOffsetDucked(self.ViewOffsetDucked)
		end
	end

	self.Owner:SetHealth(self.Owner:Health() * self:GetNWInt "BackupMaxHealth" / self:GetNWInt "MaxHealth")
	ss.ProtectedCall(self.ClientHolster, self)
	return self:SharedHolsterBase()
end

-- It's important to remove CSEnt with CSEnt:Remove() when it's no longer needed.
function SWEP:OnRemove()
	local vm = self:GetViewModel()
	if IsValid(vm) then self:ResetBonePositions(vm) end
	for k, v in pairs(self.VElements) do
		if IsValid(v.modelEnt) then v.modelEnt:Remove() end
	end
	for k, v in pairs(self.WElements) do
		if IsValid(v.modelEnt) then v.modelEnt:Remove() end
	end

	if IsValid(self.Squid) then self.Squid:Remove() end
	self:StopLoopSound()
	self:EndRecording()
	ss.ProtectedCall(self.ClientOnRemove, self)
	ss.ProtectedCall(self.SharedOnRemove, self)
end

function SWEP:Think()
	if not IsValid(self.Owner) or self:GetHolstering() then return end
	if self:IsFirstTimePredicted() then
		local enough = self:GetInk() > self.Secondary.TakeAmmo * 100
		if not self.EnoughSubWeapon and enough then
			self.JustUsableTime = CurTime() - LocalPlayer():Ping() / 1000
			if self:IsCarriedByLocalPlayer() then
				surface.PlaySound(ss.BombAvailable)
			end
		end
		self.EnoughSubWeapon = enough
	end

	if IsValid(self.Squid) then
		if ss.SquidmodelIndex[self:GetNWInt "playermodel"] == ss.SQUID.OCTO then
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

	self:ProcessSchedules()
	self:SharedThinkBase()
	ss.ProtectedCall(self.ClientThink, self)
end

function SWEP:IsTPS()
	return not self:IsCarriedByLocalPlayer() or self.Owner:ShouldDrawLocalPlayer()
end

function SWEP:TranslateViewmodelPos(pos)
	if self:IsTPS() then return pos end
	local dir = pos - EyePos() dir:Normalize()
	local aim = EyeAngles():Forward()
	dir = aim + self:GetFOV() / self.ViewModelFOV * (dir - aim)
	return EyePos() + dir * pos:Distance(EyePos())
end
