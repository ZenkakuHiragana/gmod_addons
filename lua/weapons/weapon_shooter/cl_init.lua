
include "baseinfo.lua"
include "shared.lua"

--When the weapon is fired, it slightly expands.  This is maximum time to get back to normal size.
local FireWeaponCooldown = 0.1
local FireWeaponMultiplier = 1

--The way to draw weapon models is from SWEP Construction Kit.
SWEP.ShowViewModel = true
SWEP.ShowWorldModel = false

SWEP.ViewModelBoneMods = {
	["ValveBiped.Bip01_L_Finger0"] = { scale = Vector(1, 1, 1), pos = Vector(0, 0, 0), angle = Angle(7, -27, 0) },
	["Base"] = { scale = Vector(1, 1, 1), pos = Vector(-30, 30, -30), angle = Angle(0, 0, 0) },
	["ValveBiped.Bip01_L_Clavicle"] = { scale = Vector(1, 1, 1), pos = Vector(2, -2, 2), angle = Angle(0, 0, 0) },
	["ValveBiped.Bip01_Spine4"] = { scale = Vector(1, 1, 1), pos = Vector(-30, 27.5, 30), angle = Angle(0, -8, 0) },
	["ValveBiped.Bip01_L_Hand"] = { scale = Vector(1, 1, 1), pos = Vector(0, 0, 0), angle = Angle(0, 23, -12) }
}

SWEP.VElements = {
	["element_name"] = {
		type = "Model",
		model = "models/props_splatoon/weapons/primaries/splattershot/splattershot.mdl",
		bone = "ValveBiped.Bip01_Spine4",
		rel = "",
		pos = Vector(3.5, -24.3, -7.2),
		angle = Angle(12.736, 80, 90),
		size = Vector(0.56, 0.56, 0.56),
		color = Color(255, 255, 255, 255),
		surpresslightning = false,
		material = "",
		skin = 0,
		bodygroup = {}
	}
}

SWEP.WElements = {
	["element_name"] = {
		type = "Model",
		model = "models/props_splatoon/weapons/primaries/splattershot/splattershot.mdl",
		bone = "ValveBiped.Bip01_R_Hand",
		rel = "",
		pos = Vector(4, 0.6, 0.5),
		angle = Angle(0, 1, 180),
		size = Vector(1, 1, 1),
		color = Color(255, 255, 255, 255),
		surpresslightning = false,
		material = "",
		skin = 0,
		bodygroup = {}
	}
}

--Fully copies the table, meaning all tables inside this table are copied too and so on
--(normal table.Copy copies only their reference).
--Does not copy entities of course, only copies their reference.
local function FullCopy(t)
	if not t then return nil end
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

function SWEP:ResetBonePositions(vm)
	if not vm:GetBoneCount() then return end
	
	for i = 0, vm:GetBoneCount() do
		vm:ManipulateBoneScale(i, Vector(1, 1, 1))
		vm:ManipulateBonePosition(i, vector_origin)
		vm:ManipulateBoneAngles(i, angle_zero)
	end
end

local hasGarryFixedBoneScalingYet = false
function SWEP:UpdateBonePositions(vm)
	if self.ViewModelBoneMods then
		if not vm:GetBoneCount() then return end
		
		// !! WORKAROUND !! //
		// We need to check all model names :/
		local allbones = {}
		local loopthrough = self.ViewModelBoneMods
		if not hasGarryFixedBoneScalingYet then
			for i = 0, vm:GetBoneCount() do
				local bonename = vm:GetBoneName(i)
				if self.ViewModelBoneMods[bonename] then 
					allbones[bonename] = self.ViewModelBoneMods[bonename]
				else
					allbones[bonename] = { 
						scale = Vector(1,1,1),
						pos = vector_origin,
						angle = angle_zero
					}
				end
			end
			loopthrough = allbones
		end
		// !! ----------- !! //
		
		for k, v in pairs(loopthrough) do
			local bone = vm:LookupBone(k)
			if not bone then continue end
			
			// !! WORKAROUND !! //
			local s = Vector(v.scale)
			local p = Vector(v.pos)
			local ms = Vector(1,1,1)
			if not hasGarryFixedBoneScalingYet then
				local cur = vm:GetBoneParent(bone)
				while cur >= 0 do
					local pscale = loopthrough[vm:GetBoneName(cur)].scale
					ms = ms * pscale
					cur = vm:GetBoneParent(cur)
				end
			end
			
			s = s * ms
			// !! ----------- !! //
			
			if vm:GetManipulateBoneScale(bone) ~= s then
				vm:ManipulateBoneScale(bone, s)
			end
			if vm:GetManipulateBonePosition(bone) ~= p then
				vm:ManipulateBonePosition(bone, p)
			end
			if vm:GetManipulateBoneAngles(bone) ~= v.angle then
				vm:ManipulateBoneAngles(bone, v.angle)
			end
		end
	else
		self:ResetBonePositions(vm)
	end
end

function SWEP:GetBoneOrientation(basetab, tab, ent, bone_override)
	local bone, pos, ang
	if tab.rel and tab.rel ~= "" then
		local v = basetab[tab.rel]		
		if not v then return end
		
		// Technically, if there exists an element with the same name as a bone
		// you can get in an infinite loop. Let's just hope nobody's that stupid.
		pos, ang = self:GetBoneOrientation(basetab, v, ent)
		if not pos then return end
		
		pos = pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z
		ang:RotateAroundAxis(ang:Up(), v.angle.y)
		ang:RotateAroundAxis(ang:Right(), v.angle.p)
		ang:RotateAroundAxis(ang:Forward(), v.angle.r)
	else
		bone = ent:LookupBone(bone_override or tab.bone)
		if not bone then return end
		
		pos, ang = vector_origin, angle_zero
		local m = ent:GetBoneMatrix(bone)
		if m then
			pos, ang = m:GetTranslation(), m:GetAngles()
		end
		
		if IsValid(self.Owner) and self.Owner:IsPlayer() and 
			ent == self.Owner:GetViewModel() and self.ViewModelFlip then
			ang.r = -ang.r // Fixes mirrored models
		end
	end
	
	return pos, ang
end

function SWEP:CreateModels(t)
	if not t then return end
	
	// Create the clientside models here because Garry says we can't do it in the render hook
	for k, v in pairs(t) do
		if v.type == "Model" and v.model and v.model ~= "" and
			(not IsValid(v.modelEnt) or v.createdModel ~= v.model) and 
			v.model:find(".mdl") and file.Exists(v.model, "GAME") then
			
			v.modelEnt = ClientsideModel(v.model, RENDERGROUP_VIEWMODEL)
			if IsValid(v.modelEnt) then
				v.modelEnt.GetInkColorProxy = function() return self:GetInkColorProxy() end
				v.modelEnt:SetPos(self:GetPos())
				v.modelEnt:SetAngles(self:GetAngles())
				v.modelEnt:SetParent(self)
				v.modelEnt:SetNoDraw(true)
				v.modelEnt:DrawShadow(true)
				v.createdModel = v.model
			else
				v.modelEnt = nil
			end
			
		elseif v.type == "Sprite" and v.sprite and v.sprite ~= "" and
			(not v.spriteMaterial or v.createdSprite ~= v.sprite) 
			and file.Exists("materials/" .. v.sprite .. ".vmt", "GAME") then
			
			local name = v.sprite .. "-"
			local params = { ["$basetexture"] = v.sprite }
			// make sure we create a unique name based on the selected options
			local tocheck = { "nocull", "additive", "vertexalpha", "vertexcolor", "ignorez" }
			for i, j in pairs(tocheck) do
				if v[j] then
					params["$" .. j] = 1
					name = name .. "1"
				else
					name = name .. "0"
				end
			end
			
			v.createdSprite = v.sprite
			v.spriteMaterial = CreateMaterial(name, "UnlitGeneric", params)
			if v.spriteMaterial:IsError() then
				v.createdSprite = nil
				v.spriteMaterial = nil
			end
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
				vm:SetColor(Color(255,255,255,1))
				--^ stopped working in GMod 13 because you have to do Entity:SetRenderMode(1) for translucency to kick in
				--however for some reason the view model resets to render mode 0 every frame
				--so we just apply a debug material to prevent it from drawing
				vm:SetMaterial("Debug/hsv")			
			end
		end
	end
	
	--Our initialize code
	local icon = "vgui/entities/" .. self:GetClass()
	if not file.Exists(icon .. ".vmt", "GAME") then icon = "weapons/swep" end
	self.WepSelectIcon = surface.GetTextureID(icon)
	
	self.Squid = ClientsideModel(self.SquidModelName, RENDERGROUP_BOTH)
	self.Squid:SetPos(self:GetPos())
	self.Squid:SetAngles(self:GetAngles())
	self.Squid:SetNoDraw(true)
	self.Squid:DrawShadow(false)
	self.Squid:SetPredictable(true)
	self.Squid.GetInkColorProxy = function()
		if IsValid(self) then
			return self:GetInkColorProxy()
		else
			return Vector(1, 1, 1)
		end
	end
	
	local color = self:GetCorrectInkColor()
	self.Color = Color(color.x, color.y, color.z)
	self.VectorColor = Vector(self.Color.r / 255, self.Color.g / 255, self.Color.b / 255)
end

function SWEP:ViewModelDrawn()
	if not IsValid(self) or not IsValid(self.Owner) then return end	
	if not self.VElements then return end
	
	local vm = self.Owner:GetViewModel()
	self:UpdateBonePositions(vm)
	self.ViewModelFlag = true
	
	local bone_ent = self // when the weapon is dropped
	if IsValid(self.Owner) then
		bone_ent = self.Owner
	end
	
	for k, name in ipairs(self.vRenderOrder) do
		local v = self.VElements[name]
		if not v then self.vRenderOrder = nil break end
		if v.hide then continue end
		if not v.bone then continue end
		
		local model, sprite = v.modelEnt, v.spriteMaterial		
		local pos, ang = self:GetBoneOrientation(self.VElements, v, vm)
		if not pos then continue end
		
		if v.type == "Model" and IsValid(model) then
			model:SetPos(pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z)
			ang:RotateAroundAxis(ang:Up(), v.angle.y)
			ang:RotateAroundAxis(ang:Right(), v.angle.p)
			ang:RotateAroundAxis(ang:Forward(), v.angle.r)
			model:SetAngles(ang)
			
			local matrix = Matrix()
			matrix:Scale(v.size)
			
			if model:GetMaterial() ~= v.material then
				if v.material == "" then
					model:SetMaterial("")
				else
					model:SetMaterial(v.material)
				end
			end
			
			if v.skin and v.skin ~= model:GetSkin() then
				model:SetSkin(v.skin)
			end
			
			if v.bodygroup then
				for k, v in pairs(v.bodygroup) do
					if model:GetBodygroup(k) ~= v then
						model:SetBodygroup(k, v)
					end
				end
			end
			
			if v.surpresslightning then
				render.SuppressEngineLighting(true)
			end
			
			if isfunction(self.PreViewModelDrawn) then
				self:PreViewModelDrawn(model, bone_ent, ang, pos, v, matrix)
			end
			
			model:EnableMatrix("RenderMultiply", matrix)
			render.SetColorModulation(v.color.r / 255, v.color.g / 255, v.color.b / 255)
			render.SetBlend(v.color.a / 255)
			model:DrawModel()
			render.SetBlend(1)
			render.SetColorModulation(1, 1, 1)
			
			if v.surpresslightning then
				render.SuppressEngineLighting(false)
			end
			
		elseif v.type == "Sprite" and sprite then
			local drawpos = pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z
			render.SetMaterial(sprite)
			render.DrawSprite(drawpos, v.size.x, v.size.y, v.color)
			
		elseif v.type == "Quad" and v.draw_func then
			local drawpos = pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z
			ang:RotateAroundAxis(ang:Up(), v.angle.y)
			ang:RotateAroundAxis(ang:Right(), v.angle.p)
			ang:RotateAroundAxis(ang:Forward(), v.angle.r)
			
			cam.Start3D2D(drawpos, ang, v.size)
			v.draw_func(self)
			cam.End3D2D()
		end
	end
end

function SWEP:DrawWorldModel()
	self:DrawShadow(not self.Owner:GetNoDraw())
	if self.Owner:GetNoDraw() then return end
	if self.ShowWorldModel == nil or self.ShowWorldModel then
		self:DrawModel()
	end
	
	if not self.WElements then return end	
	self.ViewModelFlag = false
	
	local bone_ent = self // when the weapon is dropped
	if IsValid(self.Owner) then
		bone_ent = self.Owner
	end
	
	for k, name in pairs(self.wRenderOrder) do
		local v = self.WElements[name]
		if not v then self.wRenderOrder = nil break end
		if v.hide then continue end
		
		local pos, ang = self:GetBoneOrientation(self.WElements, v, bone_ent, not v.bone and "ValveBiped.Bip01_R_Hand")
		if not pos then continue end
		
		local model, sprite = v.modelEnt, v.spriteMaterial
		if v.type == "Model" and IsValid(model) then
			model:SetPos(pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z)
			ang:RotateAroundAxis(ang:Up(), v.angle.y)
			ang:RotateAroundAxis(ang:Right(), v.angle.p)
			ang:RotateAroundAxis(ang:Forward(), v.angle.r)
			model:SetAngles(ang)
			
			local matrix = Matrix()
			matrix:Scale(v.size)
			
			if model:GetMaterial() ~= v.material then
				if v.material == "" then
					model:SetMaterial("")
				else
					model:SetMaterial(v.material)
				end
			end
			
			if v.skin and v.skin ~= model:GetSkin() then
				model:SetSkin(v.skin)
			end
			
			if v.bodygroup then
				for k, v in pairs(v.bodygroup) do
					if model:GetBodygroup(k) ~= v then
						model:SetBodygroup(k, v)
					end
				end
			end
			
			if v.surpresslightning then
				render.SuppressEngineLighting(true)
			end
			
			if isfunction(self.PreDrawWorldModel) then
				self:PreDrawWorldModel(model, bone_ent, pos, ang, v, matrix)
			end
			
			model:EnableMatrix("RenderMultiply", matrix)
			render.SetColorModulation(v.color.r / 255, v.color.g / 255, v.color.b / 255)
			render.SetBlend(v.color.a / 255)
			model:DrawModel()
			model:CreateShadow()
			render.SetBlend(1)
			render.SetColorModulation(1, 1, 1)
			
			if v.surpresslightning then
				render.SuppressEngineLighting(false)
			end
			
		elseif v.type == "Sprite" and sprite then
			local drawpos = pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z
			render.SetMaterial(sprite)
			render.DrawSprite(drawpos, v.size.x, v.size.y, v.color)
			
		elseif v.type == "Quad" and v.draw_func then
			local drawpos = pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z
			ang:RotateAroundAxis(ang:Up(), v.angle.y)
			ang:RotateAroundAxis(ang:Right(), v.angle.p)
			ang:RotateAroundAxis(ang:Forward(), v.angle.r)
			
			cam.Start3D2D(drawpos, ang, v.size)
			v.draw_func( self )
			cam.End3D2D()
		end
	end
end

function SWEP:DrawHUD()
	if self.Squid.ShouldDraw then
		self.Squid:DrawModel()
	end
end

--Show remaining amount of ink tank
function SWEP:CustomAmmoDisplay()
	self.AmmoDisplay = self.AmmoDisplay or {}
	self.AmmoDisplay.Draw = true
	
	if self.Primary.ClipSize > 0 then
		self.AmmoDisplay.PrimaryClip = 300
		self.AmmoDisplay.PrimaryAmmo = self:Clip1()
	end
	
	if self.Secondary.ClipSize > 0 then
		self.AmmoDisplay.SecondaryClip = nil
		self.AmmoDisplay.SecondaryAmmo = nil
	end
	
	return self.AmmoDisplay
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
	self:Holster()
end

--Custom functions executed before weapon model is drawn.
--model | Weapon model(Clientside Entity)
--bone_ent | Owner entity
--pos, ang | Position and angle of weapon model
--v | Viewmodel/Worldmodel element table
--matrix | VMatrix for scaling
local function ExpandModel(self, model, bone_ent, pos, ang, v, matrix)
	local fraction = (self:GetModifyWeaponSize() - CurTime() + FireWeaponCooldown) * FireWeaponMultiplier
	if fraction > 0 then model:SetModelScale(1 + fraction) end
end

function SWEP:PreDrawWorldModel(model, bone_ent, pos, ang, v, matrix)
	ExpandModel(self, model, bone_ent, pos, ang, v, matrix)
end

function SWEP:PreViewModelDrawn(model, bone_ent, pos, ang, v, matrix)
	ExpandModel(self, model, bone_ent, pos, ang, v, matrix)
end