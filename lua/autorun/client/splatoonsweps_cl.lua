
--Clientside ink manager
local InkAlpha = 160
local MeshColor = ColorAlpha(color_white, InkAlpha)
SplatoonSWEPs = SplatoonSWEPs or {
	IMesh = {Mesh()},
	MeshTriangles = {{}},
	RenderTarget = {
		Name = "splatoonsweps_rendertarget",
	},
	SortedSurfaces = {},
	Surfaces = {Area = 0, AreaBound = 0, LongestEdge = 0},
}
include "../splatoonsweps_shared.lua"
include "../splatoonsweps_bsp.lua"
include "../splatoonsweps_const.lua"
include "splatoonsweps_userinfo.lua"
include "splatoonsweps_inkmanager_cl.lua"
include "splatoonsweps_network_cl.lua"

function SplatoonSWEPs:GetRTSize()
	return SplatoonSWEPs.RTSize[SplatoonSWEPs:GetConVarInt "RTResolution"]
end

function SplatoonSWEPs:ClearAllInk()
	render.PushRenderTarget(SplatoonSWEPs.RenderTarget.Texture)
	render.OverrideAlphaWriteEnable(true, true)
	render.ClearDepth()
	render.ClearStencil()
	render.Clear(0, 0, 0, 0)
	render.OverrideAlphaWriteEnable(false)
	render.PopRenderTarget()
	game.GetWorld():RemoveAllDecals()
end

local INK_SURFACE_DELTA_NORMAL = 0.8 --Distance between map surface and ink mesh
local function Initialize()
	local self = SplatoonSWEPs
	self.BSP:Init() --Parsing BSP file
	self.BSP = nil
	
	local rtsize = SplatoonSWEPs:GetRTSize()
	local rtarea = rtsize^2
	local rtmergin = 2 / rtsize
	local rtmerginSqr = rtmergin^2
	local function GetUV(convertunit)
		local u, v, nextV = 0, 0, 0
		local convSqr = convertunit^2
		for _, face in ipairs(SplatoonSWEPs.SortedSurfaces) do --Using next-fit approach
			-- if face.Vertices2D.Area / convSqr < rtmerginSqr then continue end
			local bound = face.Vertices2D.bound / convertunit
			nextV = math.max(nextV, bound.y)
			if 1 - u < bound.x then 
				u, v, nextV = 0, v + nextV + rtmergin, bound.y
			end
			
			for i, vertex in ipairs(face.Vertices2D) do
				local UV = vertex / convertunit --Get UV coordinates
				face.MeshVertex[i] = {
					color = MeshColor,
					pos = face.Vertices[i] + face.Parent.normal * INK_SURFACE_DELTA_NORMAL,
					u = UV.x + u,
					v = UV.y + v,
				}
			end
			
			face.MeshVertex.origin = Vector(u, v, 0)
			u = u + bound.x + rtmergin --Advance U-coordinate
		end
		
		return v + nextV
	end
	
	--Ratio[(units^2 / pixel^2)^1/2 -> units/pixel]
	self.RenderTarget.Ratio = math.max(math.sqrt(self.Surfaces.AreaBound / rtarea), self.Surfaces.LongestEdge / rtsize)
	table.sort(self.SortedSurfaces, function(a, b) return a.Vertices2D.Area > b.Vertices2D.Area end)
	
	--convertunit[pixel * units/pixel -> units]
	local convertunit = rtsize * self.RenderTarget.Ratio
	local maxY = GetUV(convertunit) --UV mapping to map geometry
	while maxY > 1 do
		convertunit = convertunit * ((maxY - 1) * 0.475 + 1.0005)
		maxY = GetUV(convertunit)
	end
	
	--Building MeshVertex
	local build = 1
	for _, face in ipairs(self.SortedSurfaces) do
		for i = 3, #face.MeshVertex do
			table.insert(self.MeshTriangles[build], face.MeshVertex[i - 1])
			table.insert(self.MeshTriangles[build], face.MeshVertex[i])
			table.insert(self.MeshTriangles[build], face.MeshVertex[1])
		end
		
		if #self.MeshTriangles[build] >= 65535 then
			build = build + 1
			self.MeshTriangles[build] = {}
			self.IMesh[build] = Mesh()
		end
	end
	
	for i, t in ipairs(self.MeshTriangles) do
		self.IMesh[i]:BuildFromTriangles(t)
	end
	
	--Creating a RenderTarget
	self.RenderTarget.Texture = GetRenderTargetEx(
		self.RenderTarget.Name,
		rtsize, rtsize,
		RT_SIZE_NO_CHANGE,
		MATERIAL_RT_DEPTH_NONE,
		2048 + 8192 + 32768 + 8388608,
		CREATERENDERTARGETFLAGS_HDR,
		IMAGE_FORMAT_RGBA8888
	)
	self.RenderTarget.Material = CreateMaterial(
		self.RenderTarget.Name,
		"UnlitGeneric",
		{
			["$basetexture"] = self.RenderTarget.Texture:GetName(),
			["$envmap"] = "env_cubemap",
			["$envmaptint"] = "[.2 .2 .2]",
			["$translucent"] = "1",
			["$smooth"] = "1",
			["$vertexalpha"] = "1",
			["$vertexcolor"] = "1",
		}
	)
	
	self:ClearAllInk()
	function SplatoonSWEPs:PixelsToUnits(pixels) return pixels * self.RenderTarget.Ratio end
	function SplatoonSWEPs:PixelsToUV(pixels) return pixels / rtsize end
	function SplatoonSWEPs:UnitsToPixels(units) return units / self.RenderTarget.Ratio end
	function SplatoonSWEPs:UnitsToUV(units) return units / convertunit end
	function SplatoonSWEPs:UVToPixels(uv) return uv * rtsize end
	function SplatoonSWEPs:UVToUnits(uv) return uv * convertunit end
	self.RenderTarget.Ratio = convertunit / rtsize
	self.RenderTarget.Ready = true
	print(#self.IMesh)
end

hook.Add("InitPostEntity", "SplatoonSWEPs: Clientside Initialization", Initialize)
