
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
		-- table.insert(q, v.RootNode)
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
-- debugoverlay.Line(Vector(0, 0, 0) * c, Vector(1, 0, 1) * c, 5, Color(255, 255, 0), true)
-- debugoverlay.Line(Vector(0, 0, 0) * c, Vector(1, 0, 0) * c, 5, Color(255, 255, 0), true)
-- debugoverlay.Line(Vector(1, 0, 0) * c, Vector(1, 1, 0) * c, 5, Color(255, 255, 0), true)
-- debugoverlay.Line(Vector(1, 1, 0) * c, Vector(0, 1, 0) * c, 5, Color(255, 255, 0), true)
-- debugoverlay.Line(Vector(0, 1, 0) * c, Vector(0, 0, 0) * c, 5, Color(255, 255, 0), true)

for i, f in ipairs(SplatoonSWEPs.SortedSurfaces) do
	-- f = SplatoonSWEPs.SortedSurfaces[3]
	-- local t = f.Vertices2D
	local t = f.MeshVertex or {}
	for k, v in ipairs(t) do
		local w = t[k % #t + 1]
		-- print(v.u, v.v)
		-- DebugLine(Vector(v.u, v.v, 0) * c, Vector(w.u, w.v, 0) * c, true)
		-- if i == 3 then DebugLine(v.pos, w.pos, true) end
		-- if i == 3 then DebugLine(v, w, true) DebugText(v, k) end
	end
	-- if i > 3 then break end
end

-- if SERVER then return end

-- SplatoonSWEPs.RenderTarget.Material:SetVector("$envmaptint", Vector(1, 1, 1))
-- SplatoonSWEPs.RenderTarget.Material:SetVector("$reflectivity", Vector(0.5, 0.5, 0.5))
-- SplatoonSWEPs.RenderTarget.WaterMaterial:SetInt("$masked", 0)
SplatoonSWEPs.RenderTarget.WaterMaterial:SetFloat("$refractamount", 3.5)
SplatoonSWEPs.RenderTarget.WaterMaterial:SetVector("$refracttint", Vector(.9, .9, .9))
-- SplatoonSWEPs.RenderTarget.WaterMaterial:SetInt("$translucent", 1)
-- SplatoonSWEPs.RenderTarget.WaterMaterial:SetFloat("$alpha", .1)
-- SplatoonSWEPs.RenderTarget.WaterMaterial:SetInt("$bluramount", 2)
-- debugoverlay.Box(org, -Vector(size/2, size/2, 0), Vector(size/2, size/2, 0), 5, Color(0, 255, 0, 128))
-- surface.SetMaterial(Material "splatoonsweps/splatoonink")
-- surface.DrawTexturedRect(0, 0, 512, 512)

-- local p = LocalPlayer():GetEyeTrace()
-- local n = p.HitNormal
-- p = p.HitPos
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
	-- local start = face.MeshVertex.origin
	-- local endpos = start + SplatoonSWEPs:UnitsToUV(face.Vertices2D.bound)
	-- local spx, epx = start * lightmapsize, endpos * lightmapsize
	-- for u = spx.x, epx.x do
		-- for v = spx.y, epx.y do
			-- local pos2d = SplatoonSWEPs:UVToUnits(Vector(u, v, 0) / lightmapsize - face.MeshVertex.origin)
			-- local pos = SplatoonSWEPs:To3D(pos2d, face.origin, face.Vertices2D.angle)
			-- DebugPoint(pos + face.Parent.normal * 2, 5, true)
			-- DebugPoint(Vector(u, v, 0) / lightmapsize * c, 5, true)
			-- print(render.GetLightColor(pos + face.Parent.normal * 0.00002):ToColor())
		-- end
	-- end
	
	-- for i, v in ipairs(face.Vertices2D) do
		-- DebugPoint(SplatoonSWEPs:To3D(v, face.origin, face.Vertices2D.angle), 5, true)
	-- end
	-- break
-- end

local function lighttest()
	draw.NoTexture()
	surface.SetFont "ChatFont"
	surface.SetTextColor(128, 128, 128, 255)
	local t = LocalPlayer():GetEyeTrace()
	local p, n = t.HitPos, t.HitNormal
	local amb = render.GetAmbientLightColor()
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
		p = p + n * 100
		light = render.ComputeLighting(p, n)
		color = render.GetLightColor(p)
	end
end
hook.Remove("HUDPaint", "test")
-- hook.Add("HUDPaint", "test", lighttest)


