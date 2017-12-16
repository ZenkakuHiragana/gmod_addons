

-- local vs = SplatoonSWEPs.BSP:GetLump(SplatoonSWEPs.LUMP.VERTEXES).data
-- local edg = SplatoonSWEPs.BSP:GetLump(SplatoonSWEPs.LUMP.SURFEDGES).data
-- local ofaces = SplatoonSWEPs.BSP:GetLump(SplatoonSWEPs.LUMP.ORIGINALFACES).data
-- local faces = SplatoonSWEPs.BSP:GetLump(SplatoonSWEPs.LUMP.FACES).data
local function doit()
	for k, v in pairs(vs) do
		debugoverlay.Cross(v, 5, 5, Color(0, 255, 0), false)
	end
end
-- local function doit()
	-- for k, v in pairs(edg) do
		-- debugoverlay.Line(v.start, v.endpos, 5, Color(0, 255, 0), false)
	-- end
-- end
-- local function doit()
	-- for k, v in ipairs(ofaces) do
		-- for i = 0, #v.Vertices do
			-- debugoverlay.Line(v.Vertices[i], v.Vertices[(i + 1) % (#v.Vertices + 1)], 5, Color(0, 255, 0), false)
		-- end
		-- if v.DispInfoTable then
			-- v = v.DispInfoTable.DispVerts
			-- for i = 0, #v do
				-- debugoverlay.Cross(v[i].pos, 5, 5, Color(0, 255, 255), false)
			-- end
		-- end
	-- end
-- end
local mins, maxs = Vector(-100, -100, -64), Vector(100, 100, 64)
local function drawface(f, p)
	local time = CurTime()
	for k, v in ipairs(f or faces) do
		-- local mi, ma = mins + p, maxs + p
		-- local vmin, vmax = v.mins, v.maxs
		-- if v.DispInfoTable then vmin, vmax = v.DispInfoTable.mins, v.DispInfoTable.maxs end
		-- if  mi.x > vmax.x or ma.x < vmin.x or
			-- mi.y > vmax.y or ma.y < vmin.y or
			-- mi.z > vmax.z or ma.z < vmin.z then
			-- continue
		-- end
		
		if v.DispInfoTable then
			-- debugoverlay.Box(vector_origin, v.DispInfoTable.mins, v.DispInfoTable.maxs, 3, Color(0, 255, 255, 128))
			if v.DispInfoTable.DispVerts then
				for i = 0, #v.DispInfoTable.DispVerts do
					debugoverlay.Cross(v.DispInfoTable.DispVerts[i].pos, 10, 5, Color(0, 255, 255), false)
					debugoverlay.Text(v.DispInfoTable.DispVerts[i].pos, i, 5)
				end
			end
			for _, t in ipairs(v.DispInfoTable.Triangles) do
				for i = 0, #t.Vertices do
					debugoverlay.Line(t.Vertices[i], t.Vertices[(i + 1) % (#t.Vertices + 1)], 5, Color(0, 255, 255), false)
				end
				debugoverlay.Line(t.Vertices[0], t.Vertices[0] + t.normal * 50, 5, Color(0, 255, 255), false)
			end
		else
			local center = vector_origin
			for i = 0, #v.Vertices do
				debugoverlay.Text(v.Vertices[i], i, 5)
				debugoverlay.Line(v.Vertices[i], v.Vertices[(i + 1) % (#v.Vertices + 1)], 5, Color(0, 255, 0), false)
				center = center + v.Vertices[i]
			end
			center = center / (#v.Vertices + 1)
			
			for i = 0, #v.Vertices do
				local d1, d2 = (v.Vertices[i] - center) / 2, (v.Vertices[(i + 1) % (#v.Vertices + 1)] - center) / 2
				debugoverlay.Line(v.Vertices[i], v.Vertices[i] - d1, 5, Color(0, 255, 0), false)
				debugoverlay.Line(v.Vertices[(i + 1) % (#v.Vertices + 1)], v.Vertices[(i + 1) % (#v.Vertices + 1)] - d2, 5, Color(0, 255, 0), false)
				debugoverlay.Line(v.Vertices[i] - d1, v.Vertices[(i + 1) % (#v.Vertices + 1)] - d2, 5, Color(0, 255, 0), false)
			end
			-- for _, v in ipairs(v.Polygon[1]) do print(v) end
		end
	end
	-- print("time:", CurTime() - time)
end

local function doit()
	local p = Entity(1):GetEyeTrace().HitPos
	local q = {SplatoonSWEPs.BSP:GetWorldRoot()}
	-- local q = {}
	-- for i, v in pairs(SplatoonSWEPs.BSP:GetLump(SplatoonSWEPs.LUMP.MODELS).data) do
		-- table.insert(q, v)
	-- end
	-- debugoverlay.Box(p, mins, maxs, 3, Color(0, 255, 0, 128))
	while #q > 0 do
		local n = table.remove(q, 1)
		if not n.IsLeaf then
			local infront, behind = n:GetChildren(p)
			table.insert(q, infront)
			if n:Across(mins, maxs, p) then
				table.insert(q, behind)
			end
		end
		drawface(n.FaceTable, p)
	end
end

include "autorun/debug.lua"
local c = 1000
debugoverlay.Line(Vector(0, 0, 0) * c, Vector(1, 0, 1) * c, 5, Color(255, 255, 0), true)
debugoverlay.Line(Vector(0, 0, 0) * c, Vector(1, 0, 0) * c, 5, Color(255, 255, 0), true)
debugoverlay.Line(Vector(1, 0, 0) * c, Vector(1, 1, 0) * c, 5, Color(255, 255, 0), true)
debugoverlay.Line(Vector(1, 1, 0) * c, Vector(0, 1, 0) * c, 5, Color(255, 255, 0), true)
debugoverlay.Line(Vector(0, 1, 0) * c, Vector(0, 0, 0) * c, 5, Color(255, 255, 0), true)

for k, f in ipairs(SplatoonSWEPs.SequentialSurfaces.Vertices) do
	for i, v in ipairs(f) do
		-- v = SplatoonSWEPs:To2D(v, SplatoonSWEPs.SequentialSurfaces.Origins[k], SplatoonSWEPs.SequentialSurfaces.Angles[k])
		local w = f[i % #f + 1]
		v = SplatoonSWEPs:UnitsToUV(v) + SplatoonSWEPs.SequentialSurfaces.UVorigins[k]
		w = SplatoonSWEPs:UnitsToUV(w) + SplatoonSWEPs.SequentialSurfaces.UVorigins[k]
		DebugLine(v * c, w * c, true)
		DebugLine(v, w, true)
	end
end

-- if SERVER then return end

-- SplatoonSWEPs.RenderTarget.Material:SetVector("$envmaptint", Vector(1, 1, 1))
-- SplatoonSWEPs.RenderTarget.Material:SetVector("$reflectivity", Vector(0.5, 0.5, 0.5))
-- SplatoonSWEPs.RenderTarget.WaterMaterial:SetInt("$translucent", 1)
-- SplatoonSWEPs.RenderTarget.WaterMaterial:SetFloat("$refractamount", 3.5)
-- SplatoonSWEPs.RenderTarget.WaterMaterial:SetVector("$refracttint", Vector(.9, .9, .9))
-- debugoverlay.Box(org, -Vector(size/2, size/2, 0), Vector(size/2, size/2, 0), 5, Color(0, 255, 0, 128))
-- surface.SetMaterial(Material "splatoonsweps/splatoonink")
-- surface.DrawTexturedRect(0, 0, 512, 512)

local tr = (CLIENT and LocalPlayer() or Entity(1)):GetEyeTrace()
local n = tr.HitNormal
local p = tr.HitPos
-- p = p - n
-- DebugPoint(p, 1, true)
-- local color = render.ComputeLighting(p, n):ToColor()
-- print(color)

-- hook.Remove("HUDPaint", "test")
-- hook.Add("HUDPaint", "test", function()
	-- surface.SetDrawColor(color)
	-- surface.DrawRect(0, 32, 64, 64)
-- end)

-- local lightmapsize = SplatoonSWEPs:GetRTSize() * SplatoonSWEPs.RenderTarget.LightmapScale
-- for _, face in ipairs(SplatoonSWEPs.SortedSurfaces) do
	-- if _ == 1 then continue end
	-- local start = face.UVorigin
	-- local endpos = start + SplatoonSWEPs:UnitsToUV(face.Vertices2D.bound)
	-- local spx, epx = start * lightmapsize, endpos * lightmapsize
	-- for u = spx.x, epx.x do
		-- for v = spx.y, epx.y do
			-- local pos2d = SplatoonSWEPs:UVToUnits(Vector(u, v, 0) / lightmapsize - face.UVorigin)
			-- local pos = SplatoonSWEPs:To3D(pos2d, face.origin, face.Vertices2D.angle)
			-- DebugPoint(pos + face.normal * 2, 5, true)
			-- DebugPoint(Vector(u, v, 0) / lightmapsize * c, 5, true)
			-- print(render.GetLightColor(pos + face.normal * 0.00002):ToColor())
		-- end
	-- end
	
	-- for i, v in ipairs(face.Vertices2D) do
		-- DebugPoint(SplatoonSWEPs:To3D(v, face.origin, face.angle), 5, true)
	-- end
	-- break
-- end

local flag = true
local function lighttest()
	draw.NoTexture()
	surface.SetFont "ChatFont"
	surface.SetTextColor(128, 128, 128, 255)
	local t = LocalPlayer():GetEyeTrace()
	local p, n = t.HitPos, t.HitNormal
	local amb = render.GetAmbientLightColor()
	if flag then flag = false
		print("Length: ", amb:Length())
		print("LengthSqr", amb:LengthSqr())
		print("Average: ", (amb.x + amb.y + amb.z) / 3)
		print("Grayscale: ", 0.298912 * amb.x + 0.586611 * amb.y + 0.114478 * amb.z)
	end
	local light = render.ComputeLighting(p, n)
	local color = render.GetLightColor(p)
	local x, y = 0, 1
	for x = 0, 1 do
		local y = 1
		for text, vec in pairs {
			["CpLight"] = light,
			["GetColor"] = color,
			["Avg."] = (light + color + amb / 5) / 2.2,
			["Amb."] = amb,
		} do
			surface.SetDrawColor(vec:ToColor())
			surface.DrawRect(10 + x * 140, y * 80, 128, 64)
			surface.SetTextPos(10 + x * 140, y * 80)
			surface.DrawText(text)
			y = y + 1
		end
		p = p + n
		light = render.ComputeLighting(p, n)
		color = render.GetLightColor(p)
	end
end
-- hook.Remove("HUDPaint", "test")
-- hook.Add("HUDPaint", "test", lighttest)

-- local l = SplatoonSWEPs:FindLeaf {LocalPlayer():GetPos(), LocalPlayer():GetPos() + vector_up * 50}
-- print(l, l and l.id, l and l.IsLeaf)
-- for i, v in ipairs(l.Surfaces) do DebugPoly(v.Vertices, true) end
-- PrintTable(l, 0, {[l.ParentNode] = true, [l.Surfaces] = true})
-- for k, v in pairs(SplatoonSWEPs.BSP:GetLump(SplatoonSWEPs.LUMP.LEAFS).data) do
	-- print(k, v, v.id)
-- end

-- PrintTable(tr)
-- print(util.GetSurfacePropName(tr.SurfaceProps))
-- local cvar = SplatoonSWEPs:GetConVar "InkColor"
-- cvar:SetInt(cvar:GetInt() % SplatoonSWEPs.MAX_COLORS + 1)

-- local ccode = Entity(1):GetActiveWeapon().ColorCode
-- if not ccode then return end

-- local leaf = SplatoonSWEPs:FindLeaf {p + n, p - n}
-- PrintTable(leaf.Surfaces[1].InkCircles)
-- for i, leafface in ipairs(leaf.Surfaces.InkCircles) do
	-- for r, z in pairs(leafface) do
		-- DebugVector(SplatoonSWEPs:To3D(r.pos, leaf.Surfaces.Origins[i], leaf.Surfaces.Angles[i]), leaf.Surfaces.Normals[i] * 50)
		-- for b in pairs(r.bounds) do
			-- DebugBox(SplatoonSWEPs:To3D(b.mins, leaf.Surfaces.Origins[i], leaf.Surfaces.Angles[i]),
				-- SplatoonSWEPs:To3D(b.maxs, leaf.Surfaces.Origins[i], leaf.Surfaces.Angles[i]))
		-- end
	-- end
-- end

-- local bound = Vector(20, 20, 20)
-- for node in SplatoonSWEPs:BSPPairs {p} do
	-- for k, f in ipairs(node.Surfaces) do
		-- if f.normal:Dot(n) <= 0.8 then continue end
		-- if not SplatoonSWEPs:CollisionAABB(p - bound, p + bound, f.mins, f.maxs) then continue end
		-- local p2d = SplatoonSWEPs:To2D(p, f.origin, f.angle)
		-- for r, z in SortedPairsByValue(f.InkRectangles, true) do
			-- if p2d:DistToSqr(r.pos) < r.radius^2 then
				-- if ccode == r.color then
					-- Entity(1):SetHealth(Entity(1):Health() + 1000)
				-- else
					-- Entity(1):TakeDamage(10)
				-- end
				-- break
			-- end
		-- end
	-- end
-- end

