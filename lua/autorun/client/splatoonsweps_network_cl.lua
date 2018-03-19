
--net.Receive's
local ss = SplatoonSWEPs
if not ss then return end

--Mesh limitation is
-- 10922 = 32767 / 3 with mesh.Begin(),
-- 21845 = 65535 / 3 with BuildFromTriangles()
local MAX_TRIANGLES = math.floor(32768 / 3)
local INK_SURFACE_DELTA_NORMAL = .8 --Distance between map surface and ink mesh
local DamageSounds = {"TakeDamage", "DealDamage", "DealDamageCritical"}
local surf = ss.SequentialSurfaces
local function AddInkQueue()
	local facenumber = net.ReadInt(ss.SURFACE_INDEX_BITS)
	local color = net.ReadUInt(ss.COLOR_BITS)
	local pos = net.ReadVector()
	local radius = net.ReadFloat()
	local inkangle = net.ReadFloat()
	local inktype = net.ReadUInt(4)
	local ratio = net.ReadFloat()
	return table.insert(ss.InkQueue, {
		c = color,
		dispflag = facenumber < 0 and 0 or 1,
		done = 0,
		inkangle = inkangle,
		n = math.abs(facenumber),
		pos = pos,
		r = radius,
		ratio = ratio,
		t = inktype,
	})
end

net.Receive("SplatoonSWEPs: DrawInk", AddInkQueue)
net.Receive("SplatoonSWEPs: Send error message from server", function(...)
	local msg = net.ReadString()
	local icon = net.ReadUInt(3)
	local duration = net.ReadUInt(4)
	notification.AddLegacy(msg, icon, duration)
end)

net.Receive("SplatoonSWEPs: Play damage sound", function(...)
	surface.PlaySound(ss[DamageSounds[net.ReadUInt(2)]])
end)

net.Receive("SplatoonSWEPs: Receive ink surface", function(...)
	local mode = net.ReadUInt(ss.SETUP_BITS)
	if mode == ss.SETUPMODE.BEGIN then
		ss.AreaBound = net.ReadFloat()
		ss.AspectSum = net.ReadFloat()
		ss.AspectSumX = net.ReadFloat()
		ss.AspectSumY = net.ReadFloat()
		ss.AdvanceProgress = 1 / net.ReadUInt(32)
		net.Start "SplatoonSWEPs: Setup ink surface"
		net.WriteUInt(ss.SETUPMODE.SURFACE, ss.SETUP_BITS)
		net.SendToServer()
		return
	elseif mode == ss.SETUPMODE.SURFACE then
		net.Start "SplatoonSWEPs: Setup ink surface"
		if net.ReadBool() then
			net.WriteUInt(ss.SETUPMODE.DISPLACEMENT, ss.SETUP_BITS)
			net.SendToServer()
			return
		end
		
		net.WriteUInt(ss.SETUPMODE.SURFACE, ss.SETUP_BITS)
		for loop = 1, 100 do
			local i = net.ReadInt(ss.SURFACE_INDEX_BITS)
			if i == 0 then break end
			surf.Angles[i] = net.ReadAngle()
			surf.Areas[i] = net.ReadFloat()
			surf.Bounds[i] = net.ReadVector()
			surf.Normals[i] = net.ReadVector()
			surf.Origins[i] = net.ReadVector()
			surf.Vertices[i] = {}
			local n = net.ReadUInt(ss.FACEVERT_BITS)
			for k = 1, n do
				table.insert(surf.Vertices[i], net.ReadVector())
			end
			
			ss.SetupProgress = ss.SetupProgress + ss.AdvanceProgress
		end
		net.SendToServer()
		return
	elseif mode == ss.SETUPMODE.DISPLACEMENT then
		net.Start "SplatoonSWEPs: Setup ink surface"
		if net.ReadBool() then
			net.WriteUInt(ss.SETUPMODE.INKDATA, ss.SETUP_BITS)
			net.SendToServer()
			
			local numareas = #surf.Areas
			local rtsize = math.min(ss.RTSize[ss:GetConVarInt "RTResolution"], render.MaxTextureWidth(), render.MaxTextureHeight())
			local rtarea = rtsize^2
			local rtmergin = 4 / rtsize --arearatio[units/pixel]
			local arearatio = .0050455266963 * (ss.AreaBound * ss.AspectSum * ss.AspectSumX / ss.AspectSumY / numareas / 2500 + numareas)^.523795515713613
			local convertunit = rtsize * arearatio --convertunit[pixel * units/pixel -> units]
			local sortedsurfs, movesurfs = {}, {}
			local NumMeshTriangles, nummeshes, dv, divuv, half = 0, 1, 0, 1
			local u, v, nv, bu, bv, bk = 0, 0, 0 --cursor(u, v), shelf height, rectangle size(u, v), beginning of k
			function ss:PixelsToUnits(pixels) return pixels * arearatio end
			function ss:PixelsToUV(pixels) return pixels / rtsize end
			function ss:UnitsToPixels(units) return units / arearatio end
			function ss:UnitsToUV(units) return units / convertunit end
			function ss:UVToPixels(uv) return uv * rtsize end
			function ss:UVToUnits(uv) return uv * convertunit end
			for k in SortedPairsByValue(surf.Areas, true) do
				table.insert(sortedsurfs, k)
				NumMeshTriangles = NumMeshTriangles + #surf.Vertices[k] - 2
				
				bu, bv = surf.Bounds[k].x / convertunit, surf.Bounds[k].y / convertunit
				nv = math.max(nv, bv) --UV-coordinate placement, using next-fit approach
				if u + bu > 1 then --Creating a new shelf
					if v + nv + rtmergin > 1 then table.insert(movesurfs, {id = bk, v = v}) end
					u, v, nv = 0, v + nv + rtmergin, bv
				end
				
				if u == 0 then bk = #sortedsurfs end --The first element of the current shelf
				for i, vt in ipairs(surf.Vertices[k]) do --Get UV coordinates
					local meshvert = vt + surf.Normals[k] * INK_SURFACE_DELTA_NORMAL
					local UV = ss:To2D(vt, surf.Origins[k], surf.Angles[k]) / convertunit
					surf.Vertices[k][i] = {pos = meshvert, u = UV.x + u, v = UV.y + v}
				end
				
				if ss.Displacements[k] then
					NumMeshTriangles = NumMeshTriangles + #ss.Displacements[k].Triangles - 2
					for i = 0, #ss.Displacements[k].Positions do
						local vt = ss.Displacements[k].Positions[i]
						local meshvert = vt.pos - surf.Normals[k] * surf.Normals[k]:Dot(vt.vec * vt.dist)
						local UV = ss:To2D(meshvert, surf.Origins[k], surf.Angles[k]) / convertunit
						vt.u, vt.v = UV.x + u, UV.y + v
					end
				end
				
				surf.u[k], surf.v[k] = u, v
				u = u + bu + rtmergin --Advance U-coordinate
			end
			
			if v + nv > 1 and #movesurfs > 0 then
				local min, halfv = math.huge, movesurfs[#movesurfs].v / 2 + .5
				for _, m in ipairs(movesurfs) do
					local v = math.abs(m.v - halfv)
					if v < min then min, half = v, m end
				end
				
				dv = half.v - 1
				divuv = math.max(half.v, v + nv - dv)
				arearatio = arearatio * divuv
				convertunit = convertunit * divuv
			end
			
			print("Total mesh triangles: ", NumMeshTriangles)
			
			for i = 1, math.ceil(NumMeshTriangles / MAX_TRIANGLES) do
				table.insert(ss.IMesh, Mesh(ss.RenderTarget.Material))
			end
			
			--Building MeshVertex
			mesh.Begin(ss.IMesh[nummeshes], MATERIAL_TRIANGLES, math.min(NumMeshTriangles, MAX_TRIANGLES))
			local function ContinueMesh()
				if mesh.VertexCount() < MAX_TRIANGLES * 3 then return end
				mesh.End()
				mesh.Begin(ss.IMesh[nummeshes + 1], MATERIAL_TRIANGLES,
				math.min(NumMeshTriangles - MAX_TRIANGLES * nummeshes, MAX_TRIANGLES))
				nummeshes = nummeshes + 1
			end
			
			for sortedID, k in ipairs(sortedsurfs) do
				if half and sortedID >= half.id then
					surf.Angles[k]:RotateAroundAxis(surf.Normals[k], -90)
					surf.Bounds[k].x, surf.Bounds[k].y, surf.u[k], surf.v[k], surf.Moved[k]
						= surf.Bounds[k].y, surf.Bounds[k].x, surf.v[k] - dv, surf.u[k], true
					for _, vertex in ipairs(surf.Vertices[k]) do
						vertex.u, vertex.v = vertex.v - dv, vertex.u
					end
					
					if ss.Displacements[k] then
						for i = 0, #ss.Displacements[k].Positions do
							local vertex = ss.Displacements[k].Positions[i]
							vertex.u, vertex.v = vertex.v - dv, vertex.u
						end
					end
				end
				
				surf.u[k], surf.v[k] = surf.u[k] / divuv, surf.v[k] / divuv
				if ss.Displacements[k] then
					local verts = ss.Displacements[k].Positions
					for _, v in pairs(verts) do v.u, v.v = v.u / divuv, v.v / divuv end
					for _, v in ipairs(surf.Vertices[k]) do v.u, v.v = v.u / divuv, v.v / divuv end
					for _, t in ipairs(ss.Displacements[k].Triangles) do
						local tv = {verts[t[1]], verts[t[2]], verts[t[3]]}
						local n = (tv[1].pos - tv[2].pos):Cross(tv[3].pos - tv[2].pos):GetNormalized()
						for _, p in ipairs(tv) do
							mesh.Normal(n)
							mesh.Position(p.pos + n * INK_SURFACE_DELTA_NORMAL)
							mesh.TexCoord(0, p.u, p.v)
							mesh.TexCoord(1, p.u, p.v)
							mesh.AdvanceVertex()
						end
						
						ContinueMesh()
					end
					-- ss.Displacements[k] = nil
				else
					for t, v in ipairs(surf.Vertices[k]) do
						v.u, v.v = v.u / divuv, v.v / divuv
						if t < 3 then continue end
						for _, i in ipairs {t - 1, t, 1} do
							local v = surf.Vertices[k][i]
							mesh.Normal(surf.Normals[k])
							mesh.Position(v.pos)
							mesh.TexCoord(0, v.u, v.v)
							mesh.TexCoord(1, v.u, v.v)
							mesh.AdvanceVertex()
						end
						
						ContinueMesh()
					end
				end
				-- surf.Areas[k], surf.Vertices[k] = nil
			end
			mesh.End()
			
			-- surf.Areas, ss.Displacements, surf.Vertices, surf.AreaBound = nil
			ss:ClearAllInk()
			collectgarbage "collect"
			return
		end
		
		ss.SetupProgress = ss.SetupProgress + ss.AdvanceProgress
		net.WriteUInt(ss.SETUPMODE.DISPLACEMENT, ss.SETUP_BITS)
		local i = net.ReadInt(ss.SURFACE_INDEX_BITS)
		local power = 2^(net.ReadUInt(2) + 1) + 1
		ss.Displacements[i] = {Positions = {}, Triangles = {}}
		for k = 0, net.ReadUInt(9) do
			local v = {u = 0, v = 0}
			v.pos = net.ReadVector()
			v.vec = net.ReadVector()
			v.dist = net.ReadFloat()
			ss.Displacements[i].Positions[k] = v
			
			local tri_inv = k % 2 == 0 --Generate triangles from displacement mesh.
			if k % power < power - 1 and math.floor(k / power) < power - 1 then
				table.insert(ss.Displacements[i].Triangles, {tri_inv and k + power + 1 or k + power, k + 1, k})
				table.insert(ss.Displacements[i].Triangles, {tri_inv and k or k + 1, k + power, k + power + 1})
			end
		end
		
		net.SendToServer()
		return
	elseif mode == ss.SETUPMODE.INKDATA then
		if net.ReadBool() then
			ss.SetupProgress, ss.AdvanceProgress = nil
			ss.RenderTarget.Ready = true
			return
		end
		
		net.Start "SplatoonSWEPs: Setup ink surface"
		net.WriteUInt(ss.SETUPMODE.INKDATA, ss.SETUP_BITS)
		net.SendToServer()
		AddInkQueue()
	end
end)
