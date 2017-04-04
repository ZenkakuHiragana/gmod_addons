
SWEP.stoptime = 0
SWEP.healname = ""
SWEP.reloadname = ""
SWEP.inklingname = ""

local ColorNames = {"Orange", "Pink", "Purple", "Blue", "Cyan", "Green"}
local ColorCodes = {Color(255,128,0,255), Color(255,0,255,255), Color(128,0,255,255), Color(0,0,255,255), Color(0,255,255,255), Color(0,0,255,255)}

local squidmdl = "models/props_splatoon/squids/squid_beta.mdl"
local inklingmdl = "models/drlilrobot/splatoon/ply/inkling_" .. (SWEP.gender or "boy") .. ".mdl"

/********************************************************
	SWEP Construction Kit base code
		Created by Clavus
	Available for public use, thread at:
	   facepunch.com/threads/1032378
	   
	   
	DESCRIPTION:
		This script is meant for experienced scripters 
		that KNOW WHAT THEY ARE DOING. Don't come to me 
		with basic Lua questions.
		
		Just copy into your SWEP or SWEP base of choice
		and merge with your own code.
		
		The SWEP.VElements, SWEP.WElements and
		SWEP.ViewModelBoneMods tables are all optional
		and only have to be visible to the client.
********************************************************/

local function SetBullseye(wep)
	if GetConVar("ai_disabled"):GetInt() == 1 then return end
	
	if SERVER then
		if not IsValid(wep.Owner) then
			wep:Remove()
			return
		end
		
		if wep.Owner:IsPlayer() then
			timer.Destroy(wep.inklingname)
			timer.Destroy("think" .. wep:EntIndex())
			return
		end
		
		if wep.poison then
			wep.Owner:StopMoving()
		end
		
		if not IsValid(wep.Owner:GetEnemy()) then
			local e
			
			for _, v in pairs(ents.FindByClass("splashootee")) do
				if v.InkColor ~= wep.InkColor then
					if IsValid(e) then
						if e:GetPos():Distance(wep.Owner:GetPos()) > v:GetPos():Distance(wep.Owner:GetPos()) then
							e = v
						end
					else
						e = v
					end
				end
			end
			
			wep.Owner:SetNPCState(NPC_STATE_COMBAT)
			if IsValid(e) then
				
				local flag = false
				for _,v in pairs(ents.FindInSphere(e:GetPos(), 0.1)) do
					flag = flag or (v:GetClass() == "npc_bullseye")
				end
				
				if not flag then
					local tr = ents.Create("npc_bullseye")
					tr:SetPos(e:GetPos() + e:GetUp() * 80)
					tr:Spawn()
					SafeRemoveEntityDelayed(tr, 10)
					
					wep.Owner:SetLastPosition(e:GetPos())
					wep.Owner:SetEnemy()
					wep.Owner:UpdateEnemyMemory(tr, tr:GetPos())
					wep.Owner:SetSchedule(SCHED_CHASE_ENEMY)
				end
			else
			
				if math.random() > 0.45 then
					local point, isFarFromInk
					local x, y = math.Rand(-1, 1), math.Rand(-1, 1)
					point = wep:GetPos() + Vector(x, y, 0.03) * wep.V0 * wep.FallTimer / 500
					isFarFromInk = true
					for i = 1, 200 do
						if math.abs(x) < 0.05 and math.abs(y) < 0.05 then
							x, y = math.Rand(-1, 1), math.Rand(-1, 1)
							point = wep:GetPos() + Vector(x, y, 0.03) * wep.V0 * wep.FallTimer / 500
						else
							for _,v in pairs(ents.FindInSphere(point, 15)) do
								if v:GetClass() == "splashootee" and v.InkColor == wep.InkColor then
									isFarFromInk = false
								end
							end
							
							if not isFarFromInk then
								x, y = math.Rand(-1, 1), math.Rand(-1, 1)
								point = wep:GetPos() + Vector(x, y, 0.03) * wep.V0 * wep.FallTimer / 500
							else
								break
							end
						end
					end
					
					if isFarFromInk then
						local tr = ents.Create("npc_bullseye")
						tr:SetPos(point)
						tr:Spawn()
						
						wep.Owner:SetLastPosition(point)
						wep.Owner:SetEnemy()
						wep.Owner:UpdateEnemyMemory(tr, tr:GetPos())
						wep.Owner:SetSchedule(SCHED_CHASE_ENEMY)
						SafeRemoveEntityDelayed(tr, 4)
					else
						wep.Owner:SetSchedule(SCHED_PATROL_RUN)
					end
				end
			end
		else
			if wep.Bullseye then
				wep:Bullseye()
			end
			
			if wep.Owner:GetEnemy():GetClass() == "npc_bullseye" then
				local flag = false
				
				for _, v in pairs(ents.FindInSphere(wep.Owner:GetEnemy():GetPos(), 0.5)) do
					flag = flag or not (v:GetClass() == "splashootee" and v.InkColor ~= wep.InkColor)
					if flag then
						break
					end
				end
				flag = flag and (wep.Owner:GetEnemy():GetPos() - wep.Owner:GetPos()):Length() < wep.V0 * wep.FallTimer / 1000
				
				if flag then
					SafeRemoveEntityDelayed(wep.Owner:GetEnemy(), 2)
				end
				
				if wep.Owner:IsCurrentSchedule(SCHED_CHASE_ENEMY) then
					wep:PrimaryAttack()
				end
			end
		end
	end
end

function SWEP:Initialize()

	// other initialize code goes here

	if CLIENT then
		self.WepSelectIcon = surface.GetTextureID("vgui/entities/" .. self:GetClass() or "splattershot")
		
		// Create a new table for every weapon instance
		self.VElements = table.FullCopy( self.VElements )
		self.WElements = table.FullCopy( self.WElements )
		self.ViewModelBoneMods = table.FullCopy( self.ViewModelBoneMods )
		
		self:CreateModels(self.VElements) // create viewmodels
		self:CreateModels(self.WElements) // create worldmodels
		
		// init view model bone build function
		if IsValid(self.Owner) and self.Owner:IsPlayer() then
			local vm = self.Owner:GetViewModel()
			if IsValid(vm) then
				self:ResetBonePositions(vm)
				
				// Init viewmodel visibility
				if (self.ShowViewModel == nil or self.ShowViewModel) then
					vm:SetColor(Color(255,255,255,255))
				else
					// we set the alpha to 1 instead of 0 because else ViewModelDrawn stops being called
					vm:SetColor(Color(255,255,255,1))
					// ^ stopped working in GMod 13 because you have to do Entity:SetRenderMode(1) for translucency to kick in
					// however for some reason the view model resets to render mode 0 every frame so we just apply a debug material to prevent it from drawing
					vm:SetMaterial("Debug/hsv")			
				end
			end
		end
		
		if self.ClientInit then
			self:ClientInit()
		end
	elseif self.Owner:IsNPC() then
		if not timer.Exists(self.inklingname) then
			self.inklingname = "inkling" .. self:EntIndex()
			timer.Create(self.inklingname, 0.5, 0, function() SetBullseye(self) end)
		end
		
		self.Owner:AddRelationship("npc_bullseye D_HT 99")
		self:SetSaveValue("m_fMaxRange1", self.NPCRange or (self.V0 * self.FallTimer / 500))
		self:SetSaveValue("m_fMaxRange2", self.NPCRange or (self.V0 * self.FallTimer / 500))
		self:SetSaveValue("m_fMinRange1", 20)
		self:SetSaveValue("m_fMinRange2", 20)
		
		timer.Create("think" .. self:EntIndex(), 0.1, 0, function()
			if IsValid(self) and IsValid(self.Owner) then
				self.reload = self.ReloadSpeed
				self.heal = self.HealSpeed
				self:Think()
			end
		end)
	end
	if self.Init then
		self:Init()
	end
	
	self:SetHoldType(self.HoldType)
	self:SetMdl()
end

if CLIENT then
	
	SWEP.DrawAmmo = true
	SWEP.DrawCrosshair = true
	
	SWEP.vRenderOrder = nil
	function SWEP:ViewModelDrawn()
		
		if (not IsValid(self)) or (not IsValid(self.Owner)) then return end
		local vm = self.Owner:GetViewModel()
		if not self.VElements then return end
		
		self:UpdateBonePositions(vm)
		if not self.vRenderOrder then
			// we build a render order because sprites need to be drawn after models
			self.vRenderOrder = {}
			for k, v in pairs(self.VElements) do
				if v.type == "Model" then
					table.insert(self.vRenderOrder, 1, k)
				elseif v.type == "Sprite" or v.type == "Quad" then
					table.insert(self.vRenderOrder, k)
				end
			end
		end
		
		if IsValid(self.Owner) then
			bone_ent = self.Owner
		else
			// when the weapon is dropped
			bone_ent = self
		end
		
		for k, name in ipairs(self.vRenderOrder) do
			
			local v = self.VElements[name]
			if not v then self.vRenderOrder = nil break end
			if v.hide then continue end
			
			local model = v.modelEnt
			local sprite = v.spriteMaterial
			if not v.bone then continue end
			
			local pos, ang = self:GetBoneOrientation(self.VElements, v, vm)
			if not pos then continue end
			
			if v.type == "Model" and IsValid(model) then
				
				model.ProxyentPaintColor = self
				model.ProxyentPaintColor.GetPaintVector = function()
					if not IsValid(self) then return Vector(0, 0, 0) end
					return Vector(self.ProjColor.r / 255, self.ProjColor.g / 255, self.ProjColor.b / 255)
				end
				bone_ent.ProxyentPaintColor = bone_ent
				bone_ent.ProxyentPaintColor.GetPaintVector = function()
					if not IsValid(self) then return Vector(0, 0, 0) end
					return Vector(self.ProjColor.r / 255, self.ProjColor.g / 255, self.ProjColor.b / 255)
				end
				
				model:SetPos(pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z)
				ang:RotateAroundAxis(ang:Up(), v.angle.y)
				ang:RotateAroundAxis(ang:Right(), v.angle.p)
				ang:RotateAroundAxis(ang:Forward(), v.angle.r)
				
				model:SetAngles(ang)
				local matrix = Matrix()
				matrix:Scale(v.size)
				
				if v.material == "" then
					model:SetMaterial("")
				elseif model:GetMaterial() ~= v.material then
					model:SetMaterial( v.material )
				end
				
				if v.skin and v.skin != model:GetSkin() then
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
				
				if self.PreViewModelDrawn then
					self:PreViewModelDrawn(model, bone_ent, ang, pos, v, matrix)
				end
				
				model:EnableMatrix( "RenderMultiply", matrix )
				render.SetColorModulation(v.color.r/255, v.color.g/255, v.color.b/255)
				render.SetBlend(v.color.a/255)
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
	
	SWEP.wRenderOrder = nil
	function SWEP:DrawWorldModel()
		
		if self.ShowWorldModel == nil or self.ShowWorldModel then
			self:DrawModel()
		end
		
		if not self.WElements then return end
		
		if not self.wRenderOrder then
		
			self.wRenderOrder = {}
			for k, v in pairs(self.WElements) do
				if v.type == "Model" then
					table.insert(self.wRenderOrder, 1, k)
				elseif v.type == "Sprite" or v.type == "Quad" then
					table.insert(self.wRenderOrder, k)
				end
			end
		end
		
		if IsValid(self.Owner) then
			bone_ent = self.Owner
		else
			// when the weapon is dropped
			bone_ent = self
		end
		
		for k, name in pairs(self.wRenderOrder) do
		
			local v = self.WElements[name]
			if not v then self.wRenderOrder = nil break end
			if v.hide then continue end
			
			local pos, ang
			if v.bone then
				pos, ang = self:GetBoneOrientation(self.WElements, v, bone_ent)
			else
				pos, ang = self:GetBoneOrientation(self.WElements, v, bone_ent, "ValveBiped.Bip01_R_Hand")
			end
			
			if not pos then continue end
			
			local model = v.modelEnt
			local sprite = v.spriteMaterial
			
			if v.type == "Model" and IsValid(model) then
				
				model.ProxyentPaintColor = model
				model.ProxyentPaintColor.GetPaintVector = function()
					if not IsValid(self) then return Vector(0, 0, 0) end
					return Vector(self.ProjColor.r / 255, self.ProjColor.g / 255, self.ProjColor.b / 255)
				end
				bone_ent.ProxyentPaintColor = bone_ent
				bone_ent.ProxyentPaintColor.GetPaintVector = function()
					if not IsValid(self) then return Vector(0, 0, 0) end
					return Vector(self.ProjColor.r / 255, self.ProjColor.g / 255, self.ProjColor.b / 255)
				end
				
				model:SetPos(pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z)
				ang:RotateAroundAxis(ang:Up(), v.angle.y)
				ang:RotateAroundAxis(ang:Right(), v.angle.p)
				ang:RotateAroundAxis(ang:Forward(), v.angle.r)
				
				model:SetAngles(ang)
				local matrix = Matrix()
				matrix:Scale(v.size)
				
				if v.material == "" then
					model:SetMaterial("")
				elseif model:GetMaterial() ~= v.material then
					model:SetMaterial(v.material)
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
				
				if self.PreDrawWorldModel then
					self:PreDrawWorldModel(model, bone_ent, ang, pos, v, matrix)
				end
				
				model:EnableMatrix("RenderMultiply", matrix)
				render.SetColorModulation(v.color.r/255, v.color.g/255, v.color.b/255)
				render.SetBlend(v.color.a/255)
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
				v.draw_func( self )
				cam.End3D2D()
			end
		end
	end
	
	function SWEP:GetBoneOrientation( basetab, tab, ent, bone_override )
		
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
			
			pos, ang = Vector(0,0,0), Angle(0,0,0)
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
	
	function SWEP:CreateModels( tab )
		
		if not tab then return end
		
		// Create the clientside models here because Garry says we can't do it in the render hook
		for k, v in pairs(tab) do
			if v.type == "Model" and v.model and v.model ~= "" and (not IsValid(v.modelEnt) or v.createdModel ~= v.model) and 
					string.find(v.model, ".mdl") and file.Exists (v.model, "GAME") then
				
				v.modelEnt = ClientsideModel(v.model, RENDER_GROUP_VIEW_MODEL_OPAQUE)
				if IsValid(v.modelEnt) then
					v.modelEnt:SetPos(self:GetPos())
					v.modelEnt:SetAngles(self:GetAngles())
					v.modelEnt:SetParent(self)
					v.modelEnt:SetNoDraw(true)
					v.createdModel = v.model
				else
					v.modelEnt = nil
				end
				
			elseif v.type == "Sprite" and v.sprite and v.sprite != "" and (not v.spriteMaterial or v.createdSprite ~= v.sprite) 
				and file.Exists ("materials/"..v.sprite..".vmt", "GAME") then
				
				local name = v.sprite.."-"
				local params = { ["$basetexture"] = v.sprite }
				// make sure we create a unique name based on the selected options
				local tocheck = { "nocull", "additive", "vertexalpha", "vertexcolor", "ignorez" }
				for i, j in pairs(tocheck) do
					if v[j] then
						params["$"..j] = 1
						name = name.."1"
					else
						name = name.."0"
					end
				end
				
				v.createdSprite = v.sprite
				v.spriteMaterial = CreateMaterial(name,"UnlitGeneric",params)
			end
		end
	end
	
	local allbones
	local hasGarryFixedBoneScalingYet = false
	function SWEP:UpdateBonePositions(vm)
		
		if self.ViewModelBoneMods then
			if not vm:GetBoneCount() then return end
			
			// !! WORKAROUND !! //
			// We need to check all model names :/
			local loopthrough = self.ViewModelBoneMods
			if not hasGarryFixedBoneScalingYet then
				allbones = {}
				for i = 0, vm:GetBoneCount() do
					local bonename = vm:GetBoneName(i)
					if self.ViewModelBoneMods[bonename] then 
						allbones[bonename] = self.ViewModelBoneMods[bonename]
					else
						allbones[bonename] = { 
							scale = Vector(1,1,1),
							pos = Vector(0,0,0),
							angle = Angle(0,0,0)
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
				local s = Vector(v.scale.x,v.scale.y,v.scale.z)
				local p = Vector(v.pos.x,v.pos.y,v.pos.z)
				local ms = Vector(1,1,1)
				if (!hasGarryFixedBoneScalingYet) then
					local cur = vm:GetBoneParent(bone)
					while(cur >= 0) do
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
				if vm:GetManipulateBoneAngles(bone) ~= v.angle then
					vm:ManipulateBoneAngles(bone, v.angle)
				end
				if vm:GetManipulateBonePosition(bone) ~= p then
					vm:ManipulateBonePosition(bone, p)
				end
			end
		else
			self:ResetBonePositions(vm)
		end
	end
	
	function SWEP:ResetBonePositions(vm)
		
		if not vm:GetBoneCount() then return end
		for i = 0, vm:GetBoneCount() do
			vm:ManipulateBoneScale(i, Vector(1, 1, 1))
			vm:ManipulateBoneAngles(i, Angle(0, 0, 0))
			vm:ManipulateBonePosition(i, Vector(0, 0, 0))
		end
	end
	
	/**************************
		Global utility code
	**************************/
	
	// Fully copies the table, meaning all tables inside this table are copied too and so on (normal table.Copy copies only their reference).
	// Does not copy entities of course, only copies their reference.
	// WARNING: do not use on tables that contain themselves somewhere down the line or you'll get an infinite loop
	function table.FullCopy( tab )
		if not tab then return nil end
		
		local res = {}
		for k, v in pairs(tab) do
			if type(v) == "table" then
				res[k] = table.FullCopy(v) // recursion ho!
			elseif type(v) == "Vector" then
				res[k] = Vector(v.x, v.y, v.z)
			elseif type(v) == "Angle" then
				res[k] = Angle(v.p, v.y, v.r)
			else
				res[k] = v
			end
		end
		
		return res
	end
	
elseif SERVER then
	
	SWEP.weight = 5
	
	SWEP.AutoSwitchTo = false
	SWEP.AutoSwitchFrom = false
end

function SWEP:GetCatabilities()
	return CAP_MOVE_SHOOT + CAP_INNATE_RANGE_ATTACK1 + CAP_INNATE_RANGE_ATTACK2
		 + CAP_INNATE_MELEE_ATTACK1 + CAP_INNATE_MELEE_ATTACK2
		 + CAP_WEAPON_RANGE_ATTACK1 + CAP_WEAPON_RANGE_ATTACK2
		 + CAP_WEAPON_MELEE_ATTACK1 + CAP_WEAPON_MELEE_ATTACK2
		 + CAP_USE + CAP_OPEN_DOORS + CAP_AUTO_DOORS + CAP_SKIP_NAV_GROUND_CHECK
		 -- + CAP_USE_SHOT_REGULATOR
end

function SWEP:Reload()
	if SERVER and self.Owner:IsNPC() then
		if self.ReloadingTime and CurTime() <= self.ReloadingTime then
			self.Owner:RemoveFlags(FL_DUCK)
			return
		end
		
		if self:Clip1() < self.Primary.ClipSize then
			
		--	self.Owner:AddFlags(FL_DUCK)
			self:DefaultReload( ACT_VM_RELOAD )
			local AnimationTime = 3
			self.ReloadingTime = CurTime() + AnimationTime
			self:SetNextPrimaryFire(CurTime() + AnimationTime)
			self:SetNextSecondaryFire(CurTime() + AnimationTime)
			
		end
	end
end

function SWEP:SetMdl()
	local c = GetConVar("cl_splatoon_gender")
	if c:GetInt() == 1 then
		self.gender = "boy"
	else
		self.gender = "girl"
	end
	
	squidmdl = "models/props_splatoon/squids/squid_beta.mdl"
	inklingmdl = "models/drlilrobot/splatoon/ply/inkling_" .. (self.gender or "boy") .. ".mdl"
	if c:GetInt() == 2 then
		squidmdl = "models/props_splatoon/squids/octopus_beta.mdl"
		inklingmdl = "models/drlilrobot/splatoon/ply/octoling.mdl"
	end
	
	c = GetConVar("cl_splatoon_inkcolor")
	if self.Owner:IsNPC() then
		c = GetConVar("sv_splatoon_npc_inkcolor")
	end
	if c:GetInt() > 0 and c:GetInt() < 6 then
		self.InkColor = ColorNames[c:GetInt()]
		self.ProjColor = ColorCodes[c:GetInt()]
	end
end

local function LimitSpeed(ply, data)
	if not IsValid(ply) then return end
	if not IsValid(ply:GetActiveWeapon()) then return end
	local s, sxy, d, m = ply:GetVelocity(), 0,
			ply:GetVelocity():GetNormalized():Dot(Vector(0, 0, -1)),
			ply:GetActiveWeapon().maxspeed
	sxy = math.sqrt(s.x * s.x + s.y * s.y)
	
	if not m then return end
	if ply:GetActiveWeapon().poison then
		m = m / 2
	end
	if math.abs(s.z) > m then
		if d < -0.8660254 then
			s.z = (s.z / math.abs(s.z)) * m / 3
		elseif d < 0.7071458 then
			s.z = (s.z / math.abs(s.z)) * m
		end
	end
	if math.abs(Vector(s.x, s.y, 0):GetNormalized():Dot(ply:GetForward())) > 0.9 then
		s.z = s.z + (s.z * 0.01 * sxy / m)
	end
	
	if sxy > m then
		s.x = s.x * m / sxy
		s.y = s.y * m / sxy
	end
	data:SetVelocity(s)
end

function SWEP:Deploy()
	if IsValid(self.Owner) and self.Owner:IsPlayer() then
		hook.Add("Move", "Limit Squid's Speed", LimitSpeed)
		self.Owner:SetPlayerColor(Vector(self.ProjColor.r / 255, self.ProjColor.g / 255, self.ProjColor.b / 255))
		self.Owner:SetJumpPower(250)
		self.maxspeed = 250
		self.Owner:DoAnimationEvent(PLAYERANIMEVENT_ATTACK_PRIMARY)
		self.Owner:SetRenderMode(RENDERMODE_NORMAL)
	end
	
	self.reload = self.ReloadSpeed * 3.3333333
	self.heal = self.HealSpeed * 10
	self.ShootCount = 0
	
	self.crouched = self.Owner:GetCrouchedWalkSpeed()
	self.walkspeed = self.Owner:GetWalkSpeed()
	self.runspeed = self.Owner:GetRunSpeed()
	self.jump = self.Owner:GetJumpPower()
	self.color = self.Owner:GetColor()
	
	self:SetMdl()
	if SERVER then
		self.Owner:SendLua("if LocalPlayer():GetActiveWeapon().BaseClass and LocalPlayer():GetActiveWeapon().BaseClass.SetMdl then LocalPlayer():GetActiveWeapon().BaseClass.SetMdl(LocalPlayer():GetActiveWeapon()) end")
	end
	
	if self.AdditionalDeploy then
		self:AdditionalDeploy()
	end
	
	return true
end

function SWEP:Holster()
	timer.Destroy(self.healname)
	timer.Destroy(self.reloadname)
	timer.Destroy(self.inklingname)
	
	if not IsValid(self.Owner) or self.Owner:IsNPC() then
		timer.Destroy("think" .. self:EntIndex())
		return true
	end
	
	self.inInk = false
	self.throw = false
	self:SetNWBool("throw", false)
	self.maxspeed = 250
	hook.Remove("Move", "Limit Squid's Speed")
	
	if IsValid(self) and IsValid(self.Owner) then
		if self.Owner:IsPlayer() then
			self.Owner:SetCrouchedWalkSpeed(self.crouched or 0.6)
			self.Owner:SetWalkSpeed(self.walkspeed or 250)
			self.Owner:SetRunSpeed(self.runspeed or 500)
			self.Owner:SetJumpPower(self.jump or 200)
			self.Owner:SetColor(self.color or Color(255,255,255,255))
			self.Owner:DoAnimationEvent(PLAYERANIMEVENT_ATTACK_PRIMARY)
			self.Owner:SetNoDraw(false)
			self.Owner:SetRenderMode(RENDERMODE_NORMAL)
			self.Owner:RemoveFlags(FL_NOTARGET)
			
			self.Owner:ManipulateBoneAngles(0, Angle(0, 0, 0))
			
			local isinkling = GetConVar("cl_splatoon_isinkling")
			if isinkling and isinkling:GetInt() == 1 then
				self:SetMdl()
				self.Owner:SetModel(inklingmdl)
			end
		end
	end
	
	if CLIENT and IsValid(self.Owner) and self.Owner:IsPlayer() then
		self:SetMdl()
		local vm = self.Owner:GetViewModel()
		if IsValid(vm) then
			self:ResetBonePositions(vm)
		end
		
		self.Owner:ManipulateBoneAngles(0, Angle(0, 0, 0))
	end
	
	if self.AdditionalHolster then
		self:AdditionalHolster()
	end
	
	return true
end

function SWEP:OnRemove()
	self:Holster()
end

function SWEP:SetNextReloadTime(time)
	self.stoptime = CurTime() + time / 60
end

local function ReloadInk(wep)
	if CurTime() > wep.stoptime and wep:Clip1() < wep.Primary.ClipSize then
		local a = wep:Clip1() + (wep.RelInk or 1)
		if a > wep.Primary.ClipSize then a = wep.Primary.ClipSize end
		
		wep:SetClip1(a)
	end
end

local function Heal(wep)
	if IsValid(wep) and IsValid(wep.Owner) then
		if wep.Owner:Health() < 100 then
			wep.Owner:SetHealth(wep.Owner:Health() + 1)
		end
	else
		timer.Destroy(wep.healname)
	end
end

function SWEP:Think()
	if SERVER then
		if IsValid(self.Owner) then
			if not timer.Exists(self.healname) then
				self.healname = "healing" .. self:EntIndex()
				timer.Create(self.healname, self.heal, 0, function() Heal(self) end)
			end
			if not timer.Exists(self.reloadname) then
				self.reloadname = "reloading!" .. self:EntIndex()
				timer.Create(self.reloadname, self.reload, 0, function() ReloadInk(self) end)
			end
			
			if (self.Owner == self) or (self.Owner:Health() <= 0) then
				self:Remove()
				return
			end
		else
			self:Remove()
			return
		end
		
		local isinkling = GetConVar("cl_splatoon_isinkling")
		if self.Owner:IsPlayer() and self.Owner:Crouching() and isinkling:GetInt() == 1 then
			
			if self.wepAnim ~= ACT_VM_HOLSTER and not self.throw then
				self.wepAnim = ACT_VM_HOLSTER
				self:SendWeaponAnim(ACT_VM_HOLSTER)
			end
			
			self.throw = false
			self:SetNWBool("throw", false)
			
			for k,v in pairs(self.Owner:GetChildren()) do
				v:SetNoDraw(true)
			end
			
			if self.Owner:GetModel() ~= squidmdl then
				self.Owner:SetModel(squidmdl)
			end
			
			self.Owner:SetNoDraw(self.inInk)
			self:SetNoDraw(true)
			
			if self.inInk then
				self.maxspeed = 460
				if (self.Owner:KeyDown(IN_FORWARD) or self.Owner:KeyDown(IN_JUMP)) and
					self.Owner:EyeAngles().pitch < -45 then
					self.Owner:SetVelocity(self.Owner:GetForward() * self.SwimSpeed * self.Owner:EyeAngles().pitch / -90)
				elseif not self.Owner:KeyDown(IN_JUMP) and self.Owner:GetVelocity().z > 0 then
					self.Owner:SetVelocity(Vector(0, 0, self.Owner:GetVelocity().z / -8))
				end
				
				if self.heal ~= self.HealSpeed then
					self.heal = self.HealSpeed
					timer.Adjust(self.healname, self.heal, 0, function() Heal(self) end)
				end
				if self.reload ~= self.ReloadSpeed then
					self.reload = self.ReloadSpeed
					timer.Adjust(self.reloadname, self.reload, 0, function() ReloadInk(self) end)
				end
				
				self.Owner:SetWalkSpeed(460)
				self.Owner:SetRunSpeed(460)
				self.Owner:SetCrouchedWalkSpeed(1)
				self.Owner:SetRenderMode(RENDERMODE_NONE)
				self.Owner:SetColor(Color(0,0,0,0))
				self.Owner:AddFlags(FL_NOTARGET)
				
			else
				self.maxspeed = 350
				if not self.Owner:KeyDown(IN_JUMP) and self.Owner:GetVelocity().z > 0 then
					self.Owner:SetVelocity(Vector(0, 0, self.Owner:GetVelocity().z / -8))
				end
				
				if self.heal ~= self.HealSpeed * 10 then
					self.heal = self.HealSpeed * 10
					timer.Adjust(self.healname, self.heal, 0, function() Heal(self) end)
				end
				if self.reload < self.ReloadSpeed * 3.3333333 then
					self.reload = self.ReloadSpeed * 3.3333333
					timer.Adjust(self.reloadname, self.reload, 0, function() ReloadInk(self) end)
				end
				
				self.Owner:SetWalkSpeed(230)
				self.Owner:SetRunSpeed(230)
				self.Owner:SetCrouchedWalkSpeed(0.6)
				self.Owner:SetRenderMode(RENDERMODE_NORMAL)
				self.Owner:SetColor(self.ProjColor)
				self.Owner:RemoveFlags(FL_NOTARGET)
				
				local a = (self.Owner:GetVelocity() + self.Owner:GetForward() * 40):Angle()
				if self.Owner:GetVelocity():LengthSqr() < 16 then
					a.pitch = 0
				elseif a.pitch > 45 and a.pitch <= 90 then
					a.pitch = 45
				elseif a.pitch >= 270 and a.pitch < 300 then
					a.pitch = 300
				end
				self.Owner:ManipulateBoneAngles(0, Angle(0, 180, 90 + a.pitch))
			end
			
			if self.IsSquid then
				self:IsSquid(isinkling)
			end
		else
			self.inInk = false
			if self.Owner:IsPlayer() then
				if self.wepAnim ~= ACT_VM_IDLE and not self.throw then
					self.wepAnim = ACT_VM_IDLE
					self:SendWeaponAnim(ACT_VM_IDLE)
				end
				
				if self.heal ~= self.HealSpeed * 10 then
					self.heal = self.HealSpeed * 10
					timer.Adjust(self.healname, self.heal, 0, function() Heal(self) end)
				end
				if self.reload < self.ReloadSpeed * 3.3333333 then
					self.reload = self.ReloadSpeed * 3.3333333
					timer.Adjust(self.reloadname, self.reload, 0, function() ReloadInk(self) end)
				end
				
				self.maxspeed = 250
				self.Owner:SetCrouchedWalkSpeed(0.6)
				
				if isinkling:GetInt() == 1 and self.Owner:GetModel() ~= inklingmdl then
					self.Owner:SetModel(inklingmdl)
					self.Owner:ManipulateBoneAngles(0, Angle(0, 0, 0))
				end
				self.Owner:SetNoDraw(false)
				self.Owner:SetRenderMode(RENDERMODE_NORMAL)
				self.Owner:SetColor(Color(255,255,255,255))
				self.Owner:RemoveFlags(FL_NOTARGET)
				
				for k,v in pairs(self.Owner:GetChildren()) do
					v:SetNoDraw(false)
				end
				
				self:SetNoDraw(false)
				
				if self.throw then
					if not self.Owner:KeyDown(IN_ATTACK2) then
						self:Throw()
					else
						if self.wepAnim ~= ACT_VM_IDLE_LOWERED then
							self.wepAnim = ACT_VM_IDLE_LOWERED
							self:SendWeaponAnim(ACT_VM_IDLE_LOWERED)
						end
					end
				end
			else
				if IsValid(self.Owner) and GetConVar("ai_disabled"):GetInt() ~= 1 then
					if self.Owner:IsCurrentSchedule(SCHED_RANGE_ATTACK2) then--or
						--self.Owner:GetSequence() == ACT_SIGNAL1 then
						self:SecondaryAttack()
					elseif self.Owner:IsCurrentSchedule(SCHED_MELEE_ATTACK1) or self.Owner:IsCurrentSchedule(SCHED_MELEE_ATTACK2) then
						self.Owner:ClearSchedule()
						self.Owner:SetSchedule(SCHED_RANGE_ATTACK1)
					end
					
					if math.random(0, 60) == 30 then
						self:SecondaryAttack()
					end
				end
			end
			
			if self.IsInkling then
				self:IsInkling(isinkling)
			end
		end
	elseif CLIENT and IsValid(self) and IsValid(self.Owner) and self.Owner:IsPlayer() then
		if self:GetNWBool("throw", false) then
			self:SetWeaponHoldType("grenade")
			for k, v in pairs(self.WElements or {}) do
				v.hide = true
			end
		else
			self:SetWeaponHoldType(self.HoldType)
			for k, v in pairs(self.WElements or {}) do
				v.hide = false
			end
		end
		
		if self.ClientThink then
			self:ClientThink(self:GetNWBool("throw", false))
		end
	end
end
