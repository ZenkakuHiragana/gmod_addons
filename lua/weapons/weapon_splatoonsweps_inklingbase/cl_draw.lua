
-- The way to draw ink tank comes from SWEP Construction Kit.
local ss = SplatoonSWEPs
if not ss then return end
function SWEP:ResetBonePositions(vm)
	if not (IsValid(vm) and vm:GetBoneCount()) then return end
	for i = 0, vm:GetBoneCount() do
		vm:ManipulateBoneScale(i, ss.vector_one)
		vm:ManipulateBonePosition(i, vector_origin)
		vm:ManipulateBoneAngles(i, angle_zero)
	end
end

local hasGarryFixedBoneScalingYet = false
function SWEP:UpdateBonePositions(vm)
	if IsValid(vm) and self.ViewModelBoneMods then
		if not vm:GetBoneCount() then return end

		-- !! WORKAROUND !! --
		-- We need to check all model names :/
		local allbones = {}
		local loopthrough = self.ViewModelBoneMods
		if not hasGarryFixedBoneScalingYet then
			for i = 0, vm:GetBoneCount() do
				local bonename = vm:GetBoneName(i)
				if self.ViewModelBoneMods[bonename] then
					allbones[bonename] = self.ViewModelBoneMods[bonename]
				else
					allbones[bonename] = {
						scale = ss.vector_one,
						pos = vector_origin,
						angle = angle_zero
					}
				end
			end
			loopthrough = allbones
		end
		-- !! ----------- !! --

		for k, v in pairs(loopthrough) do
			local bone = vm:LookupBone(k)
			if not bone then continue end

			-- !! WORKAROUND !! --
			local s = Vector(v.scale)
			local p = Vector(v.pos)
			local ms = ss.vector_one
			if not hasGarryFixedBoneScalingYet then
				local cur = vm:GetBoneParent(bone)
				while cur >= 0 do
					local pscale = loopthrough[vm:GetBoneName(cur)].scale
					ms = ms * pscale
					cur = vm:GetBoneParent(cur)
				end
			end

			s = s * ms
			-- !! ----------- !! --

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

		-- Technically, if there exists an element with the same name as a bone
		-- you can get in an infinite loop. Let's just hope nobody's that stupid.
		pos, ang = self:GetBoneOrientation(basetab, v, ent)
		if not pos then return end

		pos = pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z
		ang:RotateAroundAxis(ang:Up(), v.angle.y)
		ang:RotateAroundAxis(ang:Right(), v.angle.p)
		ang:RotateAroundAxis(ang:Forward(), v.angle.r)
	else
		bone = ent:LookupBone(bone_override or tab.bone)
		if not bone then return end
		local m = ent:GetBoneMatrix(bone)
		pos, ang = m and m:GetTranslation(), m and m:GetAngles()

		if ent == self:GetViewModel() and self.ViewModelFlip then
			ang.r = -ang.r -- Fixes mirrored models
		end
	end

	return pos, ang
end

function SWEP:RecreateModel(v, modelname)
	local modelname = modelname or v.model ~= "" and v.model
	if not (modelname and util.IsModelLoaded(modelname)) then return end
	v.modelEnt = ClientsideModel(modelname, RENDERGROUP_BOTH)
	if IsValid(v.modelEnt) then
		v.createdModel = modelname
		v.modelEnt:SetPos(self:GetPos())
		v.modelEnt:SetAngles(self:GetAngles())
		v.modelEnt:SetParent(self)
		v.modelEnt:SetNoDraw(true)
		v.modelEnt:DrawShadow(true)
		function v.modelEnt.GetInkColorProxy()
			if IsValid(self) then
				return self:GetInkColorProxy()
			else
				return ss.vector_one
			end
		end
	else
		v.modelEnt = nil
	end

	return IsValid(v.modelEnt)
end

function SWEP:CreateModels(t)
	if not t then return end

	-- Create the clientside models here because Garry says we can't do it in the render hook
	local errormodelshown, errormaterialshown = false, false
	for k, v in pairs(t) do
		local modelname = k == "weapon" and self.WeaponModelName or v.model ~= "" and v.model
		if v.type == "Model" and modelname and (not IsValid(v.modelEnt) or v.createdModel ~= modelname) then
			if file.Exists(modelname, "GAME") then
				self:RecreateModel(v, modelname)
			elseif not errormodelshown then
				self:PopupError "WeaponModelNotFound"
				errormodelshown = true
			end
		elseif v.type == "Sprite" and v.sprite and v.sprite ~= "" and
			(not v.spriteMaterial or v.createdSprite ~= v.sprite) then

			if file.Exists("materials/" .. v.sprite .. ".vmt", "GAME") then
				local name = v.sprite .. "-"
				local params = {["$basetexture"] = v.sprite}
				-- make sure we create a unique name based on the selected options
				local tocheck = {"nocull", "additive", "vertexalpha", "vertexcolor", "ignorez"}
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
			elseif not errormaterialshown then
				self:PopupError "WeaponSpriteMatNotFound"
				errormaterialshown = true
			end
		end
	end
end

function SWEP:MakeSquidModel(id)
	self.SquidModelNumber = ss.SquidmodelIndex[self:GetNWInt "playermodel"] or ss.SQUID.INKLING
	local modelpath = ss.Squidmodel[self.SquidModelNumber] -- Octopus or squid?
	if IsValid(self.Squid) then self.Squid:Remove() end
	if file.Exists(modelpath, "GAME") then
		self.Squid = ClientsideModel(modelpath, RENDERGROUP_BOTH)
		if IsValid(self.Squid) then
			self.Squid:SetPos(self:GetPos())
			self.Squid:SetAngles(self:GetAngles())
			self.Squid:SetNoDraw(true)
			self.Squid:DrawShadow(true)
			self.Squid.GetInkColorProxy = function()
				if IsValid(self) then
					return self:GetInkColorProxy()
				else
					return ss.vector_one
				end
			end
		else
			self.Squid = nil
		end
	elseif not self.ErrorSquidModel then
		self.ErrorSquidModel = true
		if self:GetNWBool "becomesquid" then
			self:PopupError "WeaponSquidModelNotFound"
		end
	end
end

function SWEP:PreDrawViewModel(vm, weapon, ply)
	for k, v in pairs(self.Bodygroup or {}) do vm:SetBodygroup(k, v) end
	vm:SetSkin(self.Skin or 0)
	ss.ProtectedCall(self.PreViewModelDrawn, self, vm, weapon, ply)
	vm:SetupBones()
end

function SWEP:ViewModelDrawn(vm)
	if self.SurpressDrawingVM or self:GetHolstering() or
	not (IsValid(self) and IsValid(self.Owner)) then return end
	for k, name in ipairs(self.vRenderOrder) do
		local v = self.VElements[name]
		if not v then self.vRenderOrder = nil break end
		if v.hide or not v.bone then continue end

		local sprite = v.spriteMaterial
		local pos, ang = self:GetBoneOrientation(self.VElements, v, vm)
		if not pos then continue end
		if v.type == "Model" then
			if not (IsValid(v.modelEnt) or self:RecreateModel(v)) then continue end
			local model = v.modelEnt
			local da = name == "weapon" and v.angle or Angle()
			local dp = name == "weapon" and v.pos or Vector()
			model:SetPos(pos + ang:Forward() * dp.x + ang:Right() * dp.y + ang:Up() * dp.z)
			ang:RotateAroundAxis(ang:Up(), da.y)
			ang:RotateAroundAxis(ang:Right(), da.p)
			ang:RotateAroundAxis(ang:Forward(), da.r)
			model:SetAngles(ang)

			local matrix = Matrix()
			matrix:Scale(v.size)

			if model:GetMaterial() ~= v.material then
				if v.material == "" then
					model:SetMaterial ""
				else
					model:SetMaterial(v.material)
				end
			end

			local skin = name == "weapon" and self.Skin or v.skin
			if skin and skin ~= model:GetSkin() then
				model:SetSkin(skin)
			end

			for k, v in pairs(name == "weapon" and self.Bodygroup or v.bodygroup or {}) do
				if model:GetBodygroup(k) == v then continue end
				model:SetBodygroup(k, v)
			end

			if v.surpresslightning then
				render.SuppressEngineLighting(true)
			end

			ss.ProtectedCall(self.PreDrawViewModelElements, self, model, self.Owner, ang, pos, v, matrix)
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

		elseif v.type == "Quad" then
			local drawpos = pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z
			ang:RotateAroundAxis(ang:Up(), v.angle.y)
			ang:RotateAroundAxis(ang:Right(), v.angle.p)
			ang:RotateAroundAxis(ang:Forward(), v.angle.r)

			if v.is2d then cam.Start3D2D(drawpos, ang, v.size) end
			ss.ProtectedCall(v.draw_func, self)
			if v.is2d then cam.End3D2D() end
		end
	end
end

function SWEP:DrawWorldModel()
	if IsValid(self.Owner) then
		if self:GetHolstering() then return end
		if self:Crouching() then
			if self:GetInInk() then
				return
			elseif self:GetNWBool "becomesquid" and IsValid(self.Squid) then
				-- It seems changing eye position doesn't work.
				self.Squid:SetEyeTarget(self.Squid:GetPos() + self.Squid:GetUp() * 100)
				-- Move clientside model to player's position.
				local v = self.Owner:GetVelocity()
				local a = v:Angle()
				if v:LengthSqr() < 16 then -- Speed limit
					a.p = 0
				elseif a.p > 45 and a.p <= 90 then -- Angle limit: up and down
					a.p = 45
				elseif a.p >= 270 and a.p < 300 then
					a.p = 300
				else
					a.r = a.p
				end
				a.p, a.y, a.r = a.p - 90, self:GetAimVector():Angle().yaw, 180
				self.Squid:SetAngles(a)
				self.Squid:SetPos(self.Owner:GetPos())
				self.Squid:DrawModel()
				self.Squid:DrawShadow(true)
				self.Squid:CreateShadow()

				return
			end
		end
	end

	if ss.ProtectedCall(self.PreDrawWorldModel, self) then return end
	if not self:IsCarriedByLocalPlayer() then self:Think() end
	self:SetupBones()
	self:DrawModel()
end

function SWEP:DrawWorldModelTranslucent()
	if IsValid(self.Owner) and self:GetHolstering() then return end
	if ss.ProtectedCall(self.PreDrawWorldModelTranslucent, self) then return end
	if IsValid(self.Owner) and self:Crouching() and (self:GetInInk()
	or self:GetNWBool "becomesquid" and IsValid(self.Squid)) then return end

	local cameradistance = 1
	local bone_ent = self.Owner
	if not IsValid(bone_ent) then bone_ent = self end -- When the weapon is dropped
	if self:IsCarriedByLocalPlayer() then
		cameradistance = self:GetCameraFade()
	end

	for k, name in pairs(self.wRenderOrder) do
		local v = self.WElements[name]
		if not v then self.wRenderOrder = nil break end
		if name == "subweaponusable" then
			local fraction = math.Clamp(self.JustUsableTime + 0.15 - CurTime(), 0, 0.15)
			local size = -1600 * (fraction - 0.075)^2 + 20
			v.size = {x = size, y = size}
			v.hide = not IsValid(self.WElements["inktank"].modelEnt) or self:GetInk() < self.Secondary.TakeAmmo * 100
		elseif name == "inktank" and IsValid(self.Owner) then
			bone_ent = self.Owner
		end
		if v.hide then continue end

		local pos, ang = self:GetBoneOrientation(self.WElements, v, bone_ent, not v.bone and "ValveBiped.Bip01_R_Hand")
		if not pos then continue end

		local sprite = v.spriteMaterial
		if v.type == "Model" then
			if not (IsValid(v.modelEnt) or self:RecreateModel(v)) then continue end
			local model = v.modelEnt
			local da = v.angle or Angle()
			local dp = v.pos or Vector()
			if name ~= "weapon" or v.bone ~= "ValveBiped.Bip01_L_Hand" then
				model:SetPos(pos + ang:Forward() * dp.x + ang:Right() * dp.y + ang:Up() * dp.z)
				ang:RotateAroundAxis(ang:Up(), da.y)
				ang:RotateAroundAxis(ang:Right(), da.p)
				ang:RotateAroundAxis(ang:Forward(), da.r)
			else
				model:SetPos(pos + ang:Forward() * dp.x + ang:Right() * dp.y - ang:Up() * dp.z)
				ang:RotateAroundAxis(ang:Up(), da.y)
				ang:RotateAroundAxis(ang:Right(), da.p)
				ang:RotateAroundAxis(ang:Forward(), da.r + 180)
			end
			model:SetAngles(ang)

			local matrix = Matrix()
			matrix:Scale(v.size)

			if model:GetMaterial() ~= v.material then
				if v.material == "" then
					model:SetMaterial ""
				else
					model:SetMaterial(v.material)
				end
			end

			local skin = name == "weapon" and self.Skin or v.skin
			if skin and skin ~= model:GetSkin() then
				model:SetSkin(skin)
			end

			for k, v in pairs(name == "weapon" and self.Bodygroup or v.bodygroup or {}) do
				if model:GetBodygroup(k) == v then continue end
				model:SetBodygroup(k, v)
			end

			if v.surpresslightning then
				render.SuppressEngineLighting(true)
			end

			if v.inktank then
				-- Sub weapon usable meter
				local BombPos = Vector(math.min(-11.9 + self.Secondary.TakeAmmo * 17 * ss.MaxInkAmount / ss.GetMaxInkAmount(), 5.1))
				model:ManipulateBonePosition(model:LookupBone "bip_inktank_bombmeter", BombPos)
				-- Ink remaining
				local ink = -17 + .17 * self:GetInk() * ss.MaxInkAmount / ss.GetMaxInkAmount()
				model:ManipulateBonePosition(model:LookupBone "bip_inktank_ink_core", Vector(ink, 0, 0))
				-- Ink visiblity
				model:SetBodygroup(model:FindBodygroupByName "Ink", ink < -16.5 and 1 or 0)
				-- Ink wave
				for i = 1, 19 do
					if i ~= 10 and i ~= 11 then
						local number = tostring(i)
						if i < 10 then number = "0" .. tostring(i) end
						local bone = model:LookupBone("bip_inktank_ink_" .. number)
						local delta = model:GetManipulateBonePosition(bone).y
						local write = math.Clamp(delta + math.sin(CurTime() + math.pi / 17 * i) / 100, -0.25, 0.25)
						model:ManipulateBonePosition(bone, Vector(0, write, 0))
					end
				end

				model:SetupBones()
			end

			ss.ProtectedCall(self.PreDrawWorldModelElements, self, model, bone_ent, pos, ang, v, matrix)
			model:EnableMatrix("RenderMultiply", matrix)
			render.SetColorModulation(v.color.r / 255, v.color.g / 255, v.color.b / 255)
			render.SetBlend(v.color.a / 255 * cameradistance)
			model:DrawModel()
			model:CreateShadow()
			render.SetBlend(1)
			render.SetColorModulation(1, 1, 1)

			if v.surpresslightning then
				render.SuppressEngineLighting(false)
			end

		elseif v.type == "Sprite" and sprite then
			local drawpos = pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z
			local a = sprite:GetFloat "$alpha"
			local t = sprite:GetFloat "$translucent"
			sprite:SetFloat("$alpha", cameradistance)
			sprite:SetFloat("$translucent", 1)
			render.SetMaterial(sprite)
			render.DrawSprite(drawpos, v.size.x, v.size.y, v.color)
			sprite:SetFloat("$alpha", a or 1)
			sprite:SetFloat("$translucent", t or 0)

		elseif v.type == "Quad" then
			local drawpos = pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z
			ang:RotateAroundAxis(ang:Up(), v.angle.y)
			ang:RotateAroundAxis(ang:Right(), v.angle.p)
			ang:RotateAroundAxis(ang:Forward(), v.angle.r)

			if v.is2d then cam.Start3D2D(drawpos, ang, v.size) end
			ss.ProtectedCall(v.draw_func, self)
			if v.is2d then cam.End3D2D() end
		end
	end
end

-- Show remaining amount of ink tank
function SWEP:CustomAmmoDisplay()
	self.AmmoDisplay = self.AmmoDisplay or {}
	self.AmmoDisplay.Draw = true
	self.AmmoDisplay.PrimaryClip = math.Round(self:GetInk())
	self.AmmoDisplay.PrimaryAmmo = ss.ProtectedCall(self.DisplayAmmo, self) or ss.GetMaxInkAmount()
	return self.AmmoDisplay
end

function SWEP:DrawWeaponSelection(x, y, wide, tall, alpha)
	-- Set us up the texture
	surface.SetDrawColor(255, 255, 255, alpha)
	surface.SetTexture(self.WepSelectIcon)

	-- Lets get a sin wave to make it bounce
	local fsin = math.sin(CurTime() * 10) * (self.BounceWeaponIcon and 5 or 0)

	-- Borders
	x, y, wide = x + 10, y + 10, wide - 20

	-- Draw that mother
	surface.DrawTexturedRect(x + fsin, y - fsin, wide - fsin * 2, tall + fsin * 2)

	-- Draw weapon info box
	self:PrintWeaponInfo(x + wide + 20, y + tall, alpha)
end

function SWEP:DoDrawCrosshair(x, y)
	self.Cursor = self.Owner:GetEyeTrace().HitPos:ToScreen()
	if not ss.GetOption "drawcrosshair" then return end
	x, y = self.Cursor.x, self.Cursor.y

	return ss.ProtectedCall(self.DrawCrosshair, self, x, y)
end

local PUNCH_DAMPING = 9.0
local PUNCH_SPRING_CONSTANT = 65.0
function SWEP:CalcView(ply, pos, ang, fov)
	local f = ss.ProtectedCall(self.CustomCalcView, self, ply, pos, ang, fov)
	if ply:ShouldDrawLocalPlayer() then return pos, ang, f or fov end
	if not isangle(self.ViewPunch) then return pos, ang, f or fov end
	if math.abs(self.ViewPunch.p + self.ViewPunch.y + self.ViewPunch.r) > 0.001
	or math.abs(self.ViewPunchVel.p + self.ViewPunchVel.y + self.ViewPunchVel.r) > 0.001 then
		self.ViewPunch:Add(self.ViewPunchVel * FrameTime())
		self.ViewPunchVel:Mul(math.max(0, 1 - PUNCH_DAMPING * FrameTime()))
		self.ViewPunchVel:Sub(self.ViewPunch * math.Clamp(
			PUNCH_SPRING_CONSTANT * FrameTime(), 0, 2))
		self.ViewPunch:Set(Angle(
			math.Clamp(self.ViewPunch.p, -89, 89),
			math.Clamp(self.ViewPunch.y, -179, 179),
			math.Clamp(self.ViewPunch.r, -89, 89)))
	else
		self.ViewPunch:Zero()
	end

	return pos, ang + self.ViewPunch, f or fov
end

function SWEP:GetCameraFade()
	return math.Clamp(self:GetPos():DistToSqr(EyePos()) / ss.CameraFadeDistance, 0, 1)
end
