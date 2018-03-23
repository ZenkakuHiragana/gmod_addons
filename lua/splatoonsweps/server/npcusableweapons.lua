
local ss = SplatoonSWEPs
if not ss then return end

list.Add("NPCUsableWeapons", {class = "weapon_splattershot", title = ss.PrintName.weapon_splattershot})
list.Add("NPCUsableWeapons", {class = "weapon_aerospray_mg", title = ss.PrintName.weapon_aerospray_mg})

for _, c in ipairs(ss.WeaponClassNames) do
	list.Add("NPCUsableWeapons", {class = c, title = ss.PrintName[c]})
end

