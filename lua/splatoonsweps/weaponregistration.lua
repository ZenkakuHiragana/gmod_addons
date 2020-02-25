
AddCSLuaFile()
local ss = SplatoonSWEPs
if not ss then return end

local weaponslot = {
	weapon_splatoonsweps_roller = 0,
	weapon_splatoonsweps_shooter = 1,
	weapon_splatoonsweps_blaster_base = 2,
	weapon_splatoonsweps_splatling = 3,
	weapon_splatoonsweps_charger = 4,
	weapon_splatoonsweps_slosher_base = 5,
}
local function SetupIcons(SWEP)
	if SERVER then return end
	local icon = "entities/" .. SWEP.ClassName
	if not file.Exists(("materials/%s.vmt"):format(icon), "GAME") then
		icon = "weapons/swep"
	end

	if not killicon.Exists(SWEP.ClassName) then
		killicon.Add(SWEP.ClassName, icon, color_white) -- Weapon killicon
	end

	SWEP.WepSelectIcon = surface.GetTextureID(icon) -- Weapon select icon
end

local function PrecacheModels(t)
	for _, m in ipairs(t) do
		if file.Exists(m, "GAME") then
			util.PrecacheModel(m)
		end
	end
end

hook.Add("PreGamemodeLoaded", "SplatoonSWEPs: Register weapon classes", function()
	if not ss.GetOption "enabled" then return end

	local oldSWEP = SWEP
	local WeaponList = list.GetForEdit "Weapon"
	for base in pairs(weaponslot) do
		local LuaFolderPath = "weapons/" .. base
		for i, LuaFilePath in ipairs(file.Find(LuaFolderPath .. "/weapon_*.lua", "LUA")) do
			local ClassName = "weapon_splatoonsweps_" .. LuaFilePath:StripExtension():sub(8)
			LuaFilePath = ("%s/%s"):format(LuaFolderPath, LuaFilePath)

			if SERVER then AddCSLuaFile(LuaFilePath) end
			SWEP = {
				Base = base,
				ClassName = ClassName,
				Folder = LuaFolderPath,
			}

			include(LuaFilePath)
			local modelpath = "models/splatoonsweps/%s/"
			SWEP.ModelPath = SWEP.ModelPath or modelpath:format(SWEP.ClassName)
			SWEP.ViewModel = SWEP.ModelPath .. "c_viewmodel.mdl"
			SWEP.ViewModel0 = SWEP.ModelPath .. "c_viewmodel.mdl"
			SWEP.ViewModel1 = SWEP.ModelPath .. "c_viewmodel2.mdl"
			SWEP.ViewModel2 = SWEP.ModelPath .. "c_viewmodel3.mdl"
			SWEP.WorldModel = SWEP.ModelPath .. "w_right.mdl"
			SWEP.Category = ss.Text.Category
			SWEP.PrintName = ss.Text.PrintNames[SWEP.ClassName]
			SWEP.Slot = weaponslot[SWEP.Base]
			SWEP.SlotPos = i
			SetupIcons(SWEP)
			PrecacheModels {SWEP.ViewModel0, SWEP.ViewModel1, SWEP.ViewModel2, SWEP.WorldModel, SWEP.ModelPath .. "w_left.mdl"}

			for _, v in ipairs(SWEP.Variations or {}) do
				v.ClassName = v.ClassName and "weapon_splatoonsweps_" .. v.ClassName
				or ("%s_%s"):format(SWEP.ClassName, v.Suffix)

				local UniqueModelPath = modelpath:format(v.ClassName)
				v.Base = base
				v.Category = ss.Text.Category
				v.PrintName = ss.Text.PrintNames[v.ClassName]
				v.ModelPath = v.ModelPath or file.Exists(UniqueModelPath, "GAME") and UniqueModelPath or SWEP.ModelPath
				v.ViewModel = v.ModelPath .. "c_viewmodel.mdl"
				v.ViewModel0 = v.ModelPath .. "c_viewmodel.mdl"
				v.ViewModel1 = v.ModelPath .. "c_viewmodel2.mdl"
				v.ViewModel2 = v.ModelPath .. "c_viewmodel3.mdl"
				v.WorldModel = v.ModelPath .. "w_right.mdl"
				v = table.Merge(table.Copy(SWEP), v)
				SetupIcons(v)
				PrecacheModels {v.ViewModel0, v.ViewModel1, v.ViewModel2, v.WorldModel, v.ModelPath .. "w_left.mdl"}
				setmetatable(v, {__index = SWEP})
				weapons.Register(v, v.ClassName)
				table.Merge(WeaponList[v.ClassName], {
					Base = base,
					ClassID = table.KeyFromValue(ss.WeaponClassNames, v.ClassName),
					Customized = v.Customized,
					IsSplatoonWeapon = true,
					SheldonsPicks = v.SheldonsPicks,
					Spawnable = SERVER,
					SpecialWeapon = v.Special,
					SubWeapon = v.Sub,
				})
			end

			if not SWEP.Slot then
				local BaseTable = weapons.Get(SWEP.Base)
				SWEP.Slot = BaseTable and BaseTable.Slot or 0
			end

			weapons.Register(SWEP, SWEP.ClassName)
			table.Merge(WeaponList[SWEP.ClassName], {
				Base = base,
				ClassID = table.KeyFromValue(ss.WeaponClassNames, SWEP.ClassName),
				Customized = SWEP.Customized,
				IsSplatoonWeapon = true,
				SheldonsPicks = SWEP.SheldonsPicks,
				Spawnable = SERVER,
				SpecialWeapon = SWEP.Special,
				SubWeapon = SWEP.Sub,
			})
		end
	end

	SWEP = oldSWEP
end)

hook.Add("PopulateMenuBar", "SplatoonSWEPs: NPC weapon menu", function(menu)
	local menulist = menu:AddOrGetMenu "#menubar.npcs"
	local submenu = menulist:AddSubMenu(ss.Text.NPCWeaponMenu)
	local WeaponCategories = {}
	local WeaponList = list.Get "Weapon"
	submenu:SetDeleteSelf(false)

	for classname, weapontable in pairs(WeaponList) do
		if weapontable.IsSplatoonWeapon then
			local c = ss.Text.CategoryNames[weapontable.Base]
			WeaponCategories[c] = WeaponCategories[c] or {}
			WeaponCategories[c][#WeaponCategories[c] + 1] = {
				class = classname,
				title = ss.Text.PrintNames[classname],
			}
		end
	end

	for category, data in SortedPairs(WeaponCategories) do
		local m = submenu:AddSubMenu(category)
		m:SetDeleteSelf(false)
		table.SortByMember(data, "title", true)
		for _, v in ipairs(data) do
			m:AddCVar(v.title, "gmod_npcweapon", v.class)
		end
	end
end)

if CLIENT then return end
local NPCWeaponList = list.GetForEdit "NPCUsableWeapons"
local WeaponList = list.Get "Weapon"
hook.Add("PlayerSpawnNPC", "SplatoonSWEPs: Apply NPC Weapon", function(ply, npc, w)
    if NPCWeaponList[w] then return end
    local weapontable = WeaponList[w]
    if not weapontable then return end
    if not weapontable.IsSplatoonWeapon then return end
    NPCWeaponList[w] = {
        class = w,
        title = ss.Text.PrintNames[w],
    }
end)
