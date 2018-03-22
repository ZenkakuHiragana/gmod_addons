
include "autorun/debug.lua"

local c = 1000
local sp = SplatoonSWEPs
if CLIENT then
	local surf = sp.SequentialSurfaces
	-- for k in SortedPairsByValue(surf.Areas, true) do
		-- local p = surf.Vertices[k]
		-- local center = vector_origin
		-- for i, v in ipairs(p) do
			-- local w = p[i % #p + 1]
			-- DebugLine(Vector(v.u, v.v) * c, Vector(w.u, w.v) * c, true)
			-- DebugLine(v.pos, w.pos)
			-- center = center + v.pos
		-- end
		-- center = center / #p
		-- DebugVector(center, surf.Normals[k] * 5000)
		-- DebugPoint(center)
		-- print(surf.Texname[k], surf.Areas[k])
		-- break
	-- end
	debugoverlay.Line(vector_origin, Vector(c), 5, Color(255, 255, 0), true)
	debugoverlay.Line(vector_origin, Vector(0, c), 5, Color(255, 255, 0), true)
	debugoverlay.Line(vector_origin, Vector(c, 0, c), 5, Color(255, 255, 0), true)
	debugoverlay.Line(Vector(c, c), Vector(c), 5, Color(255, 255, 0), true)
	debugoverlay.Line(Vector(c, c), Vector(0, c), 5, Color(255, 255, 0), true)
	for k, p in ipairs(surf.Vertices) do
		-- if k < 8756 - 170 then continue end
		-- if k > 8756 + 100 then continue end
		-- print(surf.Texname[k])
		for i, v in ipairs(p) do
			local v = p[i]
			local w = p[i % #p + 1]
			print(v.u, v.v)
			DebugLine(Vector(v.u, v.v) * c, Vector(w.u, w.v) * c, true)
			-- DebugLine(v.pos, w.pos, true)
		end
		-- for k, v in ipairs(surf.Vertices[q.n]) do
			-- local w = surf.Vertices[q.n][k % #surf.Vertices[q.n] + 1]
			-- DebugLine(v.pos, w.pos, true)
			-- DebugLine(Vector(v.u,v.v)*1000, Vector(w.u,w.v)*1000, true)
		-- end
	end
	
	for k, d in pairs(sp.Displacements) do
		for _, v in pairs(d.Positions) do
			DebugText(v.pos, _)
		end
	end

	-- for k, u in pairs(surf.u) do
		-- local v = surf.v[k]
		-- local bound = surf.Bounds[k]
		-- local start = Vector(u, v) * c
		-- DebugBox(start, start + sp:UnitsToUV(bound) * c)
	-- end
	
	local n, b, m = #surf.Areas, sp.AreaBound, 0
	local xy, yx, x, y = 0, 0, 0, 0
	for k, v in SortedPairsByValue(surf.Areas, true) do m = v break end
	for k, v in ipairs(surf.Bounds) do
		if math.abs(v.y) < 1e-10 then print(v.y) end
		xy = xy + v.x / v.y
		yx = yx + v.y / v.x
		x = x + v.x
		y = y + v.y
	end
	xy, yx, x, y = xy / #surf.Bounds, yx / #surf.Bounds, x / #surf.Bounds, y / #surf.Bounds
	SetClipboardText(table.concat({n, b, m, xy, yx, x, y}, "\t"))
	print(xy, yx, x, y)
	return
end

-- for p in sp:BSPPairsAll() do
	-- local surf = p.Surfaces
	-- for i, max in ipairs(surf.Maxs) do
		-- local min = surf.Mins[i]
		-- DebugBox(max, min)
	-- end
-- end


-- local mat = Material("splatoonsweps/inkshot/mask/shot" .. tostring(i) .. ".png")
-- local width, height = mat:Width(), mat:Height()
-- local write = string.char(width, height)
-- for h = 1, height do
	-- for w = 1, width do
		-- local isink = mat:GetColor(w - 1, h - 1).r > 127
		-- write = write .. (isink and "1" or "0")
	-- end
-- end

-- file.Write("shot" .. tostring(i) .. ".txt", write)
-- lua_run for _, p in ipairs(player.GetAll()) do if not p:IsBot() then continue end p:StripWeapons() p:Give "weapon_shooter" end