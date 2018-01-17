
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
	debugoverlay.Line(Vector(c, c), Vector(c), 5, Color(255, 255, 0), true)
	debugoverlay.Line(Vector(c, c), Vector(0, c), 5, Color(255, 255, 0), true)
	for k, p in ipairs(surf.Vertices) do
		-- if k < 8756 - 170 then continue end
		-- if k > 8756 + 100 then continue end
		-- print(surf.Texname[k])
		for i, v in ipairs(p) do
			local v = p[i]
			local w = p[i % #p + 1]
			DebugLine(Vector(v.u, v.v) * c, Vector(w.u, w.v) * c, true)
			-- DebugLine(v.pos, w.pos, true)
		end
	end

	-- for k, u in pairs(surf.u) do
		-- local v = surf.v[k]
		-- local bound = surf.Bounds[k]
		-- local start = Vector(u, v) * c
		-- DebugBox(start, start + sp:UnitsToUV(bound) * c)
	-- end
	return
end

-- for p in sp:BSPPairsAll() do
	-- local surf = p.Surfaces
	-- for i, max in ipairs(surf.Maxs) do
		-- local min = surf.Mins[i]
		-- DebugBox(max, min)
	-- end
-- end

