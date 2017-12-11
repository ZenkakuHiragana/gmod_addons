
include "cooldownlib.lua"
include "baseinfo.lua"
include "shared.lua"
include "cl_draw.lua"

local errorduration = 10
function SWEP:PopupError(msg)
	notification.AddLegacy(msg, NOTIFY_ERROR, errorduration)
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

function SWEP:MakeSquidModel(id)
	self.SquidModelNumber = self.PMID == SplatoonSWEPs.PLAYER.OCTO
		and SplatoonSWEPs.SQUID.OCTO or SplatoonSWEPs.SQUID.INKLING
	local modelpath = SplatoonSWEPs.Squidmodel[self.SquidModelNumber] --Octopus or squid?
	if IsValid(self.Squid) then self.Squid:Remove() end
	if file.Exists(modelpath, "GAME") then
		self.Squid = ClientsideModel(modelpath, RENDERGROUP_BOTH)
		self.Squid.Angle = self:GetAngles()
		self.Squid:SetPos(self:GetPos())
		self.Squid:SetAngles(self:GetAngles())
		self.Squid:SetNoDraw(true)
		self.Squid:DrawShadow(false)
		self.Squid.GetInkColorProxy = function()
			if IsValid(self) then
				return self:GetInkColorProxy()
			else
				return SplatoonSWEPs.vector_one
			end
		end
	else
		print "SplatoonSWEPs: Squid model is not found!  Check your subscription!"
		if self.PMID ~= SplatoonSWEPs.PLAYER.NOSQUID then
			self:PopupError "SplatoonSWEPs: Squid model is not found!  You cannot become squid!"
		end
	end
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
		if IsValid(vm) then
			self:ResetBonePositions(vm)
			
			--Init viewmodel visibility
			if self.ShowViewModel == nil or self.ShowViewModel then
				vm:SetColor(color_white)
			else
				--we set the alpha to 1 instead of 0 because else ViewModelDrawn stops being called
				vm:SetColor(ColorAlpha(color_white, 1))
				--^ stopped working in GMod 13 because you have to do Entity:SetRenderMode(1) for translucency to kick in
				--however for some reason the view model resets to render mode 0 every frame
				--so we just apply a debug material to prevent it from drawing
				vm:SetMaterial "Debug/hsv"
			end
		end
	end
	
	--Our initialize code
	local icon = "vgui/entities/" .. self:GetClass()
	if not file.Exists(icon .. ".vmt", "GAME") then icon = "weapons/swep" end
	self.WepSelectIcon = surface.GetTextureID(icon)
	self:GetBombMeterPosition(self.Secondary.TakeAmmo)
	self:MakeSquidModel()
	self:ChangeHullDuck()
	
	self.JustUsableTime = CurTime() - 1 --For animation of ink tank light
	if IsValid(self.Owner) and self.Owner:IsPlayer() then
		self.HullDuckMins, self.HullDuckMaxs = self.Owner:GetHullDuck()
		self.ViewOffsetDucked = self.Owner:GetViewOffsetDucked()
	end
	if isfunction(self.ClientInit) then return self:ClientInit() end
end

function SWEP:Deploy()
	if not IsFirstTimePredicted() then return end
	self.PMID = SplatoonSWEPs:GetConVarInt "Playermodel"
	if IsValid(self.Squid) then
		if self.PMID == SplatoonSWEPs.PLAYER.OCTO and self.SquidModelNumber ~= SplatoonSWEPs.SQUID.OCTO then
			self.Squid:SetModel(SplatoonSWEPs.Squidmodel[SplatoonSWEPs.SQUID.OCTO])
			self.SquidModelNumber = SplatoonSWEPs.SQUID.OCTO
		elseif self.SquidModelNumber ~= SplatoonSWEPs.SQUID.INKLING then
			self.Squid:SetModel(SplatoonSWEPs.Squidmodel[SplatoonSWEPs.SQUID.INKLING])
			self.SquidModelNumber = SplatoonSWEPs.SQUID.INKLING
		end
	else
		self:MakeSquidModel()
	end
	
	self.HullDuckMins, self.HullDuckMaxs = self.Owner:GetHullDuck()
	self.ViewOffsetDucked = self.Owner:GetViewOffsetDucked()
	self:ChangeHullDuck()
	return self:SharedDeploy()
end

function SWEP:Holster()
	if not IsFirstTimePredicted() then return end
	if not IsValid(self.Owner) then return true end
	local vm = self.Owner:GetViewModel()
	if IsValid(vm) then self:ResetBonePositions(vm) end
	
	self.Owner:ManipulateBoneAngles(0, angle_zero)
	if self.PMID ~= SplatoonSWEPs.PLAYER.NOSQUID then
		self.Owner:SetHullDuck(self.HullDuckMins, self.HullDuckMaxs)
		self.Owner:SetViewOffsetDucked(self.ViewOffsetDucked)
	end
	if isfunction(self.ClientHolster) then self:ClientHolster() end
	return true
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
	if not IsValid(self.Owner) then return end
	local issquid = self.Owner:IsPlayer()
	if issquid then
		issquid = self.Owner:Crouching()
	else
		issquid = self.Owner:GetFlags(FL_DUCKING)
	end
	
	self:ProcessSchedules()
	if isfunction(self.ClientThink) then return self:ClientThink(issquid) end
end
