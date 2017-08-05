
--This lua manages whole ink in map.

local MAX_COROUTINES = 10
local inkdegrees = 45
local move_normal_distance = 0.5
local PaintQueue = {}
local InkGroup = {}
util.AddNetworkString("SplatoonSWEPs: Broadcast ink vertices")
util.AddNetworkString("SplatoonSWEPs: Finalize ink refreshment")
util.AddNetworkString("SplatoonSWEPs: ")

local RadianBaseVector = Vector(0, 1, 0)
local function SortByRadian(verts)
	local sort, center, vec = {}, vector_origin, vector_origin
	for i, v in ipairs(verts) do
		center = center + v
	end
	center = center / #verts
	for i, v in ipairs(verts) do
		vec = (v - center):GetNormalized()
		verts[i] = {v, rad = math.atan2(RadianBaseVector:Cross(vec).x, RadianBaseVector:Dot(vec))}
	end
	table.SortByMember(verts, "rad", true)
	for i, v in ipairs(verts) do
		verts[i] = v[1]
	end
end

--pA = {pA1, pA2, pA3}, pB = {pB1, pB2, pB3},  WorldToLocal()'d respectively.
local function BuildIntersection(pA, pB, bool)
	local A, B, both = {["A"] = true}, {["B"] = true}, {["A"] = true, ["B"] = true}
	local lines = {
		[pA[1]] = {
			pos = pA[2],
			left = A,
			right = {},
		},
		[pA[2]] = {
			pos = pA[3],
			left = A,
			right = {},
		},
		[pA[3]] = {
			pos = pA[1],
			left = A,
			right = {},
		},
		[pB[1]] = {
			pos = pB[2],
			left = B,
			right = {},
		},
		[pB[2]] = {
			pos = pB[3],
			left = B,
			right = {},
		},
		[pB[3]] = {
			pos = pB[1],
			left = B,
			right = {},
		},
	}
	local function modifylines(iP, P, i, isA)
		if iP[1] then
			if iP[2] then -- pA[a]->pA[a + 1] => pA[a]->iP[1].pos->iP[2].pos->pA[a + 1]
				if iP[1].fraction > iP[2].fraction then
					iP[1], iP[2] = iP[2], iP[1]
				end
				lines[P[i]] = {
					pos = iP[1].pos,
					left = isA and A or B,
					right = {},
				}
				lines[iP[1].pos] = {
					pos = iP[2].pos,
					left = both,
					right = not isA and A or B,
				}
				lines[iP[2].pos] = {
					pos = P[i % 3 + 1],
					left = isA and A or B,
					right = {},
				}
			else -- pA[a]->pA[a + 1] => pA[a]->iP[1].pos->pA[a + 1]
				local newleft = iP[1].isin and both or (isA and A or B)
				local newleft2 = not iP[1].isin and both or (isA and A or B)
				local newright = iP[1].isin and (not isA and A or B) or {}
				local newright2 = not iP[1].isin and (not isA and A or B) or {}
				lines[P[i]] = {
					pos = iP[1].pos,
					left = newleft,
					right = newright,
				}
				lines[iP[1].pos] = {
					pos = P[i % 3 + 1],
					left = newleft2,
					right = newright2,
				}
			end
		end
	end
	
	
	local AinB, BinA = true, {true, true, true}
	local vA = {pA[2] - pA[1], pA[3] - pA[2], pA[1] - pA[3]} --Direction vectors
	local vB = {pB[2] - pB[1], pB[3] - pB[2], pB[1] - pB[3]}
	local cross, crossA, crossB = vector_origin, vector_origin, vector_origin --Temporary variables
	local iA, iB, intersection = {{}, {}, {}}, {{}, {}, {}}, vector_origin
	for a = 1, 3 do
		AinB = true
		for b = 1, 3 do
			cross = vB[b]:Cross(vA[a]).x
			crossA = vB[b]:Cross(pB[b] - pA[a]).x / cross
			crossB = vA[a]:Cross(pB[b] - pA[a]).x / cross
			if crossA > 0 and crossA < 1 and crossB > 0 and crossB < 1 then
				intersection = pB[b] + crossB * vB[b]
				table.insert(iA[a], {
					pos = intersection,
					fraction = crossA,
					isin = vA[a]:Cross(pB[b] - pA[a]).x < 0,
					a = a, b = b
				})
				table.insert(iB[b], {
					pos = Vector(intersection),
					fraction = crossB,
					isin = vB[b]:Cross(pA[a] - pB[b]).x < 0,
					a = a, b = b
				})
			end
			AinB = AinB and vB[b]:Cross(pA[a] - pB[b]).x > 0
			BinA[b] = BinA[b] and vA[a]:Cross(pB[b] - pA[a]).x > 0
		end
		
		modifylines(iA[a], pA, a, true)
		if AinB then
			lines[pA[a]].left = both
			lines[pA[a]].right = B
		end
	end
	for b = 1, 3 do
		modifylines(iB[b], pB, b, false)
		if BinA[b] then
			lines[pB[b]].left = both
			lines[pB[b]].right = A
		end
	end
	
	local result, filter = {}, {}
	for i, v in pairs(lines) do
		if bool == "AND" and v.left.A and v.left.B
			or bool == "A" and v.left.A and not v.left.B then
			filter[i] = v
		elseif bool == "A" and v.right.A and not v.right.B then
			filter[v.pos] = {
				pos = i,
				left = v.right,
				right = v.left,
			}
		end
	end
	
	local prev = Vector(-1, -1, -1)
	for i = 1, 60 do
		if table.Count(filter) == 0 then break end
		if not filter[prev] then
			for k, v in pairs(filter) do
				if k == prev then
					prev = k
					break
				end
			end
			
			if not filter[prev] then
				for k, v in pairs(filter) do
					prev = k
					break
				end
				table.insert(result, {})
				if #result > 1 then SortByRadian(result[#result - 1]) end
			end
		end
		if filter[prev] then
			table.insert(result[#result], filter[prev].pos)
			prev, filter[prev] = filter[prev].pos, nil
		end
	end	
	return result
end

local function OverwriteInk(meshvertex, triangles, pos, normal, color)
	--Listing up existing ink mesh
	local meshvertex_exist, meshfinalize = {}, {}
	local chunksize = SplatoonSWEPs.ChunkSize
	for k, v in ipairs(triangles) do --For each new triangles
		local ang = normal:Angle()
		local gx, gy, gz = {}, {}, {} --Register new ink to grids
		local addlist = {}
		for i = 1, 3 do
			local v1 = v[i]
			local v2 = v[i % 3 + 1]
			local dir = v2 - v1
			local x1, y1, z1 = v1.x - v1.x % chunksize, v1.y - v1.y % chunksize, v1.z - v1.z % chunksize
			local x2, y2, z2 = v2.x - v2.x % chunksize, v2.y - v2.y % chunksize, v2.z - v2.z % chunksize
			if x1 > x2 then x1, x2 = x2, x1 end
			if y1 > y2 then y1, y2 = y2, y1 end
			if z1 > z2 then z1, z2 = z2, z1 end
			for x = x1, x2, chunksize do gx[x - x % chunksize] = true end
			for y = y1, y2, chunksize do gy[y - y % chunksize] = true end
			for z = z1, z2, chunksize do gz[z - z % chunksize] = true end
			for x in pairs(gx) do
				for y in pairs(gy) do
					for z in pairs(gz) do
						addlist[Vector(x, y, z)] = true
					end
				end
			end
			gz, gy, gz = {}, {}, {}
		end
		
		--Overwriting ink
		local meshtemp, g = {}, {}
		local verts, pA, pB = {}, {}, {}
		local tb, AinB, BinA, AoutB, BoutA, lineA, lineB = {}, {}, {}, {}, {}, {}, {}
		-- for a in pairs(addlist) do
			-- if gx[a.x] and gy[a.y] and gz[a.z] then continue end
			-- gx[a.x], gy[a.y], gz[a.z] = true, true, true
			g = InkGroup--[a.x][a.y][a.z]
			
			verts = {} --verts = existing ink - new ink
			local v = {
				Vector(0, 0, 0), Vector(0, 100, 0), Vector(0, 70, 70),
				normal = Vector(1, 0, 0), color = Vector(255, 255, 255),
			}
			local tri = {
				Vector(0, 30, 60), Vector(0, 90, 50), Vector(0, 80, 10),
				normal = Vector(1, 0, 0), color = Vector(255, 255, 255),
			}
			v, tri = tri, v
			tri = table.Sanitise(tri)
			
		--	for tri in pairs(g) do --Iterate all triangles of ink mesh in grids
				local desanitised = table.DeSanitise(tri)
				if table.Count(desanitised) <= 0 then continue end
				if not desanitised.normal:IsEqualTol(v.normal, 0.0001) then continue end
				for i = 1, 3 do
					pA[i] = desanitised[i]	--WorldToLocal(desanitised[i], angle_zero, pos, ang)
					pB[i] = v[i]			--WorldToLocal(v[i], angle_zero, pos, ang)
					pA[i].x, pB[i].x = 0, 0
				end
				
				if (pA[2] - pA[1]):Cross(pA[3] - pA[2]).x * (pB[2] - pB[1]):Cross(pB[3] - pB[2]).x < 0 then
					pB[1], pB[2], pB[3] = pB[3], pB[2], pB[1]
				end
				
				debugoverlay.Line(pA[1], pA[2], 5, Color(0,255,0), true)
				debugoverlay.Line(pA[2], pA[3], 5, Color(0,255,0), true)
				debugoverlay.Line(pA[3], pA[1], 5, Color(0,255,0), true)
				debugoverlay.Line(pB[1]+Vector(1,0,0), pB[2]+Vector(1,0,0), 5, Color(255,255,0), true)
				debugoverlay.Line(pB[2]+Vector(1,0,0), pB[3]+Vector(1,0,0), 5, Color(255,255,0), true)
				debugoverlay.Line(pB[3]+Vector(1,0,0), pB[1]+Vector(1,0,0), 5, Color(255,255,0), true)
				tb = BuildIntersection(pA, pB, "A")
				tb.color = desanitised.color
				tb.plane = {
					pos = desanitised[1],
					normal = desanitised.normal
				}
					
				verts[tb] = true
				g[tri] = nil
		--	end
			
			local t, plus1, minus1, delta, including = {}, 1, -1, 0, false
			local v12, v23, v31, vtemp, p = vector_origin, vector_origin, vector_origin, vector_origin, {}
			local planepos, planenormal, planecolor = vector_origin, vector_origin, nil
			for poly in pairs(verts) do --poly = {{vertices}, ...}
				if #poly == 0 then continue end
				tb, meshtemp = {}, {} --tb = {Triangles}, meshtemp = {MeshVertex}
				planepos, planenormal, planecolor = poly.plane.pos, poly.plane.normal, poly.color
				
				--Split into triangles
				for index, vertices in ipairs(poly) do
					for k, vec in ipairs(vertices) do
						delta = 0
						plus1 = (k + delta) % #vertices + 1
						minus1 = (#vertices + k - 2) % #vertices + 1
						while plus1 ~= minus1 do
							t = {vertices[minus1], vec, vertices[plus1]}
							v12 = t[2] - t[1]
							v23 = t[3] - t[2]
							v31 = t[1] - t[3]
							including = false
							for i = 1, #vertices do
								if i == k or i == plus1 or i == minus1 then continue end
								if v12:Cross(vertices[i] - t[1]).x <= 0 and
									v23:Cross(vertices[i] - t[2]).x <= 0 and
									v31:Cross(vertices[i] - t[3]).x <= 0 then
									including = true
									break
								end
							end
							
							if v12:Cross(v23).x <= 0 and not including then
								for i = 1, 3 do
									p[i] = LocalToWorld(t[i], angle_zero, pos, ang)
									p[i] = p[i] - (planenormal:Dot(p[i] - planepos)
											/ planenormal:Dot(normal)) * normal
									
									table.insert(meshtemp, { --MeshVertex
										pos = p[i],
										u = math.abs(t[i].y) / 50,
										v = math.abs(t[i].z) / 50,
										color = planecolor,
									})
								end
								t = { --Triangle
									p[1], p[2], p[3],
									color = planecolor,
									area = (p[2] - p[1]):Cross(p[3] - p[1]).x / 2,
									normal = planenormal,
								}
								table.insert(tb, t)
								g[table.Sanitise(t)] = true
								break
							end
							
							delta = delta + 1
							plus1 = (k + delta) % #vertices + 1
						end
					end
				end
				
				table.insert(meshvertex_exist, meshtemp)
				table.insert(meshfinalize, {pos = planepos, normal = planenormal, color = planecolor})
			end
			g[table.Sanitise(v)] = true
			break
	--	end
		-- for santised in pairs(g) do
			-- local t = table.DeSanitise(santised)
			-- if not t[1] then continue end
				-- debugoverlay.Line(t[1], t[2], 5, Color(t.color.x, t.color.y, t.color.z), true)
				-- debugoverlay.Line(t[2], t[3], 5, Color(t.color.x, t.color.y, t.color.z), true)
				-- debugoverlay.Line(t[3], t[1], 5, Color(t.color.x, t.color.y, t.color.z), true)
		-- end
	end
	
	table.insert(meshvertex_exist, meshvertex)
	table.insert(meshfinalize, {pos = pos, normal = normal, color = color})
	
	-- local sendcolor, sendpos, sendnormal = color_white, vector_origin, vector_origin
	-- for i, m in ipairs(meshvertex_exist) do
		-- local send = {} --32 bytes per vertex
		-- for k = 1, (65536 - 3) / 32 - 3 do
			-- table.insert(send, m[k])
			-- if k > #m then break end
		-- end
		
		-- for k, s in ipairs(send) do
			-- net.Start("SplatoonSWEPs: Broadcast ink vertices")
			-- net.WriteTable(s)
			-- net.Broadcast()
		-- end
		
		-- sendcolor = meshfinalize[i].color
		-- sendpos = meshfinalize[i].pos
		-- sendnormal = meshfinalize[i].normal
		-- net.Start("SplatoonSWEPs: Finalize ink refreshment")
		-- net.WriteVector(Vector(sendcolor.r / 255, sendcolor.g / 255, sendcolor.b / 255))
		-- net.WriteVector(sendpos)
		-- net.WriteVector(sendnormal)
		-- net.Broadcast()
	-- end
end

local function QueueCoroutine(pos, normal, ang, radius, color, polys)
	local tb, triangles = {}, {} --Result vertices table
	local surf = {} --Surfaces that are affected by painting
	local radiusSqr = radius^2
	local targetsurf = SplatoonSWEPs.Check(pos)
	for s in pairs(targetsurf) do --This section searches surfaces in chunk.
		if not istable(s) then continue end
		if not (s.normal and s.vertices) then continue end
		--Surfaces that have almost same normal as the given data.
		if s.normal:Dot(normal) > math.cos(math.rad(inkdegrees)) then
			--Surface.Z is near HitPos
			local dot1 = s.normal:Dot(s.vertices[1] - pos)
			if math.abs(dot1) < radius * math.cos(math.rad(inkdegrees)) then
				for k = 1, 3 do
					--Vertices is within InkRadius
					local v1 = s.vertices[1]
					local rel1 = v1 - pos
					local v2 = s.vertices[k % 3 + 1]
					local rel2 = v2 - pos
					local line = v2 - v1 --now v1 and v2 are relative vector
					v1, v2 = rel1 - normal * normal:Dot(rel1), rel2 - normal * normal:Dot(rel2)
					if line:GetNormalized():Cross(v1):Dot(normal) < radius then
						if (v1:Dot(line) < 0 and v2:Dot(line) > 0) or
							math.min(v2:LengthSqr(), v1:LengthSqr()) < radiusSqr then
							surf[{
								s.vertices[1] - s.normal * move_normal_distance,
								s.vertices[2] - s.normal * move_normal_distance,
								s.vertices[3] - s.normal * move_normal_distance
							}] = true
							break
						end
					end
				end --for k = 1, 3
			end --if dot1 > 0
		end --if s.normal:Dot
	end --for #SplatoonSWEPs.Surface
	
	coroutine.yield()
	
	local verts = {} --Vertices for polygon that we attempt to draw
	local pA, pB, vertexlist = {}, {}, {}
	for _, reference in ipairs(polys) do
		pA = {
			reference[1] * radius,
			reference[2] * radius,
			reference[3] * radius,
		}
		for drawable in pairs(surf) do
			for i = 1, 3 do
				pB[i] = WorldToLocal(drawable[i], angle_zero, pos, ang)
				pB[i].x = 0
			end
	-- debugoverlay.Line(pA[1], pA[2], 2, Color(0, 255, 0), true)
	-- debugoverlay.Line(pA[2], pA[3], 2, Color(0, 255, 0), true)
	-- debugoverlay.Line(pA[3], pA[1], 2, Color(0, 255, 0), true)
	-- debugoverlay.Line(pB[1], pB[2], 2, Color(255, 255, 0), true)
	-- debugoverlay.Line(pB[2], pB[3], 2, Color(255, 255, 0), true)
	-- debugoverlay.Line(pB[3], pB[1], 2, Color(255, 255, 0), true)
			vertexlist = BuildIntersection(pA, pB, "AND")
			
			vertexlist.plane = {
				pos = drawable[1],
				normal = (drawable[2] - drawable[1]):Cross(drawable[3] - drawable[2]):GetNormalized()
			}
			verts[vertexlist] = true
		end
	end
	
	-- pA = {
		-- Vector(0, 0, 0),
		-- Vector(0, 100, 0),
		-- Vector(0, 70, 70),
	-- }
	-- pB = {
		-- Vector(0, -10, -10),
		-- Vector(0, 110, -10),
		-- Vector(0, 80, 90),
	-- }
	-- PrintTable(BuildIntersection(pA, pB, "AND"))
	-- local i = 1
	-- for k, v in pairs(verts) do
		-- if #k > 0 then
			-- print("vertex") PrintTable(k)
			-- i = i + 1 if i > 5 then break end
		-- end
	-- end
	
	coroutine.yield()
	--split polygons into triangles
	--get back to world coordinate
	local meshvertex, tri1, tri2, trivector = {}, {}, {}, vector_origin
	local i, i1, tri_index = 1, 1, 1
	local planepos, planenormal, v1, v2 = vector_origin, vector_origin, vector_origin, vector_origin
	for polygons in pairs(verts) do
		if #polygons == 0 then continue end
		planepos = polygons.plane.pos
		planenormal = polygons.plane.normal
		for _, poly in ipairs(polygons) do
			if #poly < 3 then print("invalid polygon: ", #poly) continue end
			i = 1
			while i <= #poly do
				trivector = LocalToWorld(poly[i], angle_zero, pos, ang)
				trivector = trivector - (planenormal:Dot(trivector - planepos) / planenormal:Dot(normal)) * normal
				tb = {pos = trivector,
					u = math.abs(poly[i].y) / radius,
					v = math.abs(poly[i].z) / radius,
					color = color,
				}
				
				if i > 3 then
					i1 = i % 2 == 1 and 1 or 2
					tri_index = #meshvertex - i1
					tri1 = meshvertex[#meshvertex]
					tri2 = meshvertex[tri_index]
					v1 = tri2.pos - tri1.pos
					v2 = trivector - tri1.pos
					cross = v1:Cross(v2)
					if cross:Dot(planenormal) < 0 then
						tri2, tb = tb, tri2
					end
					debugoverlay.Line(tri1.pos, tri2.pos, 2, Color(0,255,0),true)
					debugoverlay.Line(tri2.pos, tb.pos, 2, Color(0,255,0),true)
					debugoverlay.Line(tb.pos, tri1.pos, 2, Color(0,255,0),true)
					table.insert(meshvertex, tri1)
					table.insert(meshvertex, tri2)
					table.insert(meshvertex, tb)
					table.insert(triangles, {
						tri1.pos, tri2.pos, tb.pos,
						u = {tri1.u, tri2.u, tb.u},
						v = {tri1.v, tri2.v, tb.v},
						color = color,
						normal = planenormal,
						area = (tri2.pos - tri1.pos):Cross(tb.pos - tri1.pos).x / 2,
					})
					i = i + 1
				else
					v1 = LocalToWorld(poly[i + 1], angle_zero, pos, ang)
					v2 = LocalToWorld(poly[i + 2], angle_zero, pos, ang)
					v1 = v1 - (planenormal:Dot(v1 - planepos) / planenormal:Dot(normal)) * normal
					v2 = v2 - (planenormal:Dot(v2 - planepos) / planenormal:Dot(normal)) * normal
					cross = (v1 - trivector):Cross(v2 - trivector)
					tri1 = {
						pos = v1,
						u = math.abs(poly[i + 1].y) / radius,
						v = math.abs(poly[i + 1].z) / radius,
						color = color,
					}
					tri2 = {
						pos = v2,
						u = math.abs(poly[i + 2].y) / radius,
						v = math.abs(poly[i + 2].z) / radius,
						color = color,
					}
					if cross:Dot(planenormal) < 0 then
						tri1, tri2 = tri2, tri1
						v1, v2 = v2, v1
					end
					-- print(tri1.pos, tri2.pos, tb.pos, #poly, poly[1], poly[2], poly[3])
					-- debugoverlay.Line(tri1.pos, tri2.pos, 2, Color(0,255,0),true)
					-- debugoverlay.Line(tri2.pos, tb.pos, 2, Color(0,255,0),true)
					-- debugoverlay.Line(tb.pos, tri1.pos, 2, Color(0,255,0),true)
					table.insert(meshvertex, tb)
					table.insert(meshvertex, tri1)
					table.insert(meshvertex, tri2)
					table.insert(triangles, {
						trivector, v1, v2,
						u = {tb.u, tri1.u, tri2.u},
						v = {tb.v, tri1.v, tri2.v},
						color = color,
						normal = planenormal,
						area = (poly[i + 1] - poly[i]):Cross(poly[i + 2] - poly[i]).x / 2,
					})
					i = i + 3
				end
				debugoverlay.Line(poly[1], poly[2], 2, Color(0,255,0),true)
				debugoverlay.Line(poly[2], poly[3], 2, Color(0,255,0),true)
				debugoverlay.Line(poly[3], poly[1], 2, Color(0,255,0),true)
			end
		end
	end
	
	net.Start("SplatoonSWEPs: ")
	net.WriteTable(meshvertex)
	net.WriteVector(Vector(color.r / 255, color.g / 255, color.b / 255))
	net.WriteVector(pos)
	net.WriteVector(normal)
	net.Broadcast()
	
	coroutine.yield(meshvertex, triangles)
end

local function ProcessQueue()
	local done = 0
	while true do
		local queue = table.Copy(PaintQueue)
		for i, v in ipairs(queue) do
			if coroutine.status(v.co) == "dead" then
				queue[i] = nil
				continue
			end
			
			local ok, meshvertex, triangles = coroutine.resume(
				v.co, v.pos, v.normal, v.ang, v.radius, v.color, v.polys)
			print("coroutine end: ", ok, meshvertex)
			if ok and meshvertex and triangles then
				queue[i] = nil				
				coroutine.yield()
			--	OverwriteInk(meshvertex, triangles, v.pos, v.normal, v.color)
			elseif not ok then
				queue[i] = nil
			end
			
			done = done + 1
			if done > 20 then
				coroutine.yield()
				done = 0
			end
		end
		done = 0
		coroutine.yield()
	end
end

--Do a list of coroutines.
local function DoCoroutines()
	while true do
		local self = SplatoonSWEPsInkManager
		local threads = self.Threads
		local done = 0
		for i, co in pairs(threads) do
			--Give a silent warning to developers if Think(n) has returned
			if coroutine.status(co)  == "dead" then
				Msg(self, "\tSplatoonSWEPs Warning: Coroutine " .. i .. " has finished executing\n")
				threads[i] = nil
				continue
			end
			--Continue Think's execution
			local ok, message = coroutine.resume(co)
			if not ok then
				ErrorNoHalt(self, "SplatoonSWEPs Error: ", message, "\n")
			end
			
			done = done + 1
			if done > MAX_COROUTINES then
				coroutine.yield()
				done = 0
			end
		end
		done = 0
		coroutine.yield()
	end
end

SplatoonSWEPsInkManager = {
	DoCoroutines = coroutine.create(DoCoroutines),
	Threads = {
		ProcessQueue = coroutine.create(ProcessQueue),
		Think2 = nil,
	},
	Think = function()
		local self = SplatoonSWEPsInkManager
		if coroutine.status(self.DoCoroutines) ~= "dead" then
			local ok, message = coroutine.resume(self.DoCoroutines)
			if not ok then
				ErrorNoHalt(self, "SplatoonSWEPs Error: ", message, "\n")
			end
		end
	end,
	AddQueue = function(pos, normal, ang, radius, color, polys)
		table.insert(PaintQueue, {
			pos = pos,
			normal = normal,
			ang = ang,
			radius = radius,
			color = color,
			polys = polys,
			co = coroutine.create(QueueCoroutine),
		})
	end,
}

local function InitTriangles()
	if not SplatoonSWEPs then return end
	local chunksize = SplatoonSWEPs.ChunkSize
	local mapsize = SplatoonSWEPs.MapSize
	local grid = {}
	if not mapsize then timer.Simple(0.2, InitTriangles) return end
	for x = -mapsize, mapsize, chunksize do
		grid[x - x % chunksize] = {} -- = grid[x]
		for y = -mapsize, mapsize, chunksize do
			grid[x - x % chunksize][y - y % chunksize] = {} -- = grid[x][y]
			for z = -mapsize, mapsize, chunksize do
				grid[x - x % chunksize][y - y % chunksize][z - z % chunksize] = {} -- = grid[x][y][z]
			end
		end
	end
	
	InkGroup = grid
end
hook.Add("Tick", "SplatoonSWEPsDoInkCoroutines", SplatoonSWEPsInkManager.Think)
hook.Add("InitPostEntity", "SplatoonSWEPsInitializeInkTable", InitTriangles)

function ClearInk()
	PaintQueue = {}
	InitTriangles()
end

include "splatoon_geometry.lua"
