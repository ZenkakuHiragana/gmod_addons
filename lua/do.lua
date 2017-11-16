
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

drawface(SplatoonSWEPs.Surfaces.Concave)

if SERVER then return end

local size = 8
local org = LocalPlayer():GetEyeTrace().HitPos
debugoverlay.Box(org, Vector(0, 0, 0), Vector(size, size, 0), 5, Color(0, 255, 0, 128))

do return end

local texsize = 16384 --16384x16384 -> 1GB Texture
local IMaterial = Material("splatoonsweps/splatoonink.vmt")
local newrender = GetRenderTargetEx("newrender", texsize, texsize, RT_SIZE_NO_CHANGE,
MATERIAL_RT_DEPTH_NONE, 2048 + 8192 + 32768 + 8388608, CREATERENDERTARGETFLAGS_HDR, IMAGE_FORMAT_RGBA8888)
local newmat = CreateMaterial("newrender", "UnlitGeneric", {
	["$basetexture"] = newrender:GetName(),
	["$translucent"] = "1",
	["$alphatest"] = "1",
	["$smooth"] = "0",
})
-- local newrender2 = GetRenderTargetEx("newrender2", texsize, texsize, RT_SIZE_NO_CHANGE,
-- MATERIAL_RT_DEPTH_NONE, 2048 + 8192 + 32768 + 8388608, CREATERENDERTARGETFLAGS_HDR, IMAGE_FORMAT_RGBA8888)
-- local newmat2 = CreateMaterial("newrender2", "UnlitGeneric", {
	-- ["$basetexture"] = newrender:GetName(),
	-- ["$translucent"] = "1",
	-- ["$alphatest"] = "1",
	-- ["$smooth"] = "0",
-- })
local capdata = {format = "png", x = 0, y = 0, w = texsize, h = texsize}

render.PushRenderTarget(newrender)
render.OverrideAlphaWriteEnable(true, true)
render.Clear(0, 0, 0, 0, true, true)
render.OverrideAlphaWriteEnable(false)

cam.Start2D()
draw.NoTexture()
surface.SetDrawColor(0, 128, 0, 255)
surface.DrawTexturedRect(0, 0, 128, 128)
surface.SetMaterial(Material("decals/inkcyan"))
surface.SetDrawColor(255, 128, 128, 255)
surface.DrawTexturedRect(128, 128, 512, 512)
cam.End2D()

file.Write("ink1.png", render.Capture(capdata))
-- local DF = vgui.Create("DFrame")
-- DF:SetSize(500, 500)
local DImage = vgui.Create("DHTML")
-- DImage:Dock(FILL)
DImage:SetSize(texsize, texsize)
-- DImage:SetVisible(false)
DImage:SetAlpha(0)
DImage:OpenURL("asset://garrysmod/data/ink1.png")
-- DF:MakePopup()

render.Clear(255, 255, 128, 255)
cam.Start2D()
surface.SetMaterial(Material("decals/inkpink"))
surface.SetDrawColor(255, 255, 255, 255)
surface.DrawTexturedRect(0, 0, 512, 512)
cam.End2D()
render.PopRenderTarget()

local triangles = {}
local imesh = {Mesh(), Mesh()}
local org = Vector(-3700, -300, 600)--Entity(1):GetPos()
local delta = {[2] = vector_origin, [1] = Vector(0, 0, 500)}

local polysize = 5000
for d = 1, 1 do
	triangles = {}
	for i = 1, 1 do
		local dz = i * 0
		for k = 1, 3 do
			table.insert(triangles, {
				pos = org + delta[d] + vector_up * dz,
				u = 0, v = 0,
				color = color_white,
			})
			table.insert(triangles, {
				pos = org + delta[d] + Vector(0, polysize, dz),
				u = 0, v = 1,
				color = color_white,
			})
			table.insert(triangles, {
				pos = org + delta[d] + Vector(polysize, 0, dz),
				u = 1, v = 0,
				color = color_white,
			})
			
			table.insert(triangles, {
				pos = org + delta[d] + Vector(0, polysize, dz),
				u = 0, v = 1,
				color = color_white,
			})
			table.insert(triangles, {
				pos = org + delta[d] + Vector(polysize, polysize, dz),
				u = 1, v = 1,
				color = color_white,
			})
			table.insert(triangles, {
				pos = org + delta[d] + Vector(polysize, 0, dz),
				u = 1, v = 0,
				color = color_white,
			})
		end
	end
	imesh[d]:BuildFromTriangles(triangles)
end

local function Draw()
	-- render.SetMaterial(IMaterial)
	-- imesh[2]:Draw()
	-- if not DImage:GetHTMLMaterial() then return end
	render.SetMaterial(newmat)
	imesh[1]:Draw()
	
	-- if math.random() < 0.05 then
		-- render.ClearRenderTarget(newrender, Color(255, 255, 0))
	-- end
end
hook.Add("PostDrawOpaqueRenderables", "SplatoonSWEPsDrawInk", Draw)
-- hook.Remove("PostDrawOpaqueRenderables", "SplatoonSWEPsDrawInk")

-- local rts = {}
-- for i = 1, 10000 do
	-- table.insert(rts, CreateMaterial("rts" .. tostring(i), 512, 512, false))
-- end



-- local RT = GetRenderTarget( "SomeRT", 512, 512, false )
-- local RenderWidth = 512
-- local RenderHeight = 512

-- local MaterialFile = "dsflae/shrnuinh" -- Make a texture that is about the size of your render target
-- local screenMat = Material(MaterialFile)
-- local screenTex = surface.GetTextureID( MaterialFile )
-- local OldTex = nil
-- print(screenTex)

-- hook.Add( "HUDPaint", "TestScreen", function()
	-- render.PushRenderTarget( RT )
		-- render.Clear( 0, 0, 0, 255 )
		-- render.RenderView({
			-- x = 0,
			-- y = 0,
			-- w = RenderWidth,
			-- h = RenderHeight,
			-- origin = EyePos(),
			-- angles = EyeAngles(),
			-- drawhud = false,
			-- drawviewmodel = false,
			-- dopostprocess = false,
		-- })
	-- render.PopRenderTarget()

	-- OldTex = screenMat:GetTexture( "$basetexture" )
	-- screenMat:SetTexture( "$basetexture", RT )

	-- surface.SetTexture( screenTex )
	-- surface.SetDrawColor( 255, 255, 255, 1 )
	-- surface.DrawTexturedRect( 32, 32, 256, 256 )

	-- screenMat:SetTexture( "$basetexture", OldTex )
-- end )
-- hook.Remove("HUDPaint", "TestScreen")
