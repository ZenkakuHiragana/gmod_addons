
--Since navigation mesh is shit, I use old AI node system.
--Source is from Nodegraph Editor.

NODE_TYPE_GROUND = 2
NODE_TYPE_AIR = 3
NODE_TYPE_CLIMB = 4
NODE_TYPE_WATER = 5

local AINET_VERSION_NUMBER = 37
local NUM_HULLS = 10
local MAX_NODES = 1500

NEXTBOT_m_nodegraph = NEXTBOT_m_nodegraph or nil

--[[
ENT.m_nodegraph = {
	nodes = {
		a number of node object sorted by ID
		{
			pos = Center position,
			yaw = Angle of this node,
			offset = flOffsets,
			type = NODE_TYPE_*,
			info = nodeinfo,
			zone = zone,
			neighbor = {
				Adjacent node objects.
			},
			numneighbors = #neighbor,
			link = {
				Links that connect this node.
			},
			numlinks = #link
		}
	},
	links = {
		src = (The node object of soure),
		dest = (The node object of destintion),
		srcID = (The ID of source node),
		destID = (The ID of destination node),
	},
	lookup = { --what is this?
		a number of Lookup values.
	},
}
]]

local SIZEOF_INT = 4
local SIZEOF_SHORT = 2
local function toUShort(b)
	local i = {string.byte(b,1,SIZEOF_SHORT)}
	return i[1] +i[2] *256
end
local function toInt(b)
	local i = {string.byte(b,1,SIZEOF_INT)}
	i = i[1] +i[2] *256 +i[3] *65536 +i[4] *16777216
	if(i > 2147483647) then return i -4294967296 end
	return i
end
local function ReadInt(f) return toInt(f:Read(SIZEOF_INT)) end
local function ReadUShort(f) return toUShort(f:Read(SIZEOF_SHORT)) end

function ENT:ParseFile(f)
	if NEXTBOT_m_nodegraph then return end
	local path = f or "maps/graphs/" .. game.GetMap() .. ".ain"
	f = file.Open(path,"rb","GAME")
	if not f then return end
	
	local ainet_ver = ReadInt(f)
	local map_ver = ReadInt(f)
	local nodegraph = {
		ainet_version = ainet_ver,
		map_version = map_ver
	}
	if ainet_ver ~= AINET_VERSION_NUMBER then
		MsgN("Unknown graph file")
		return
	end
	local numNodes = ReadInt(f)
	if numNodes > MAX_NODES or numNodes < 0 then
		MsgN("Graph file has an unexpected amount of nodes")
		return
	end
	
	local nodes = {}
	for i = 1, numNodes do
		local v = Vector(f:ReadFloat(),f:ReadFloat(),f:ReadFloat())
		local yaw = f:ReadFloat()
		local flOffsets = {}
		for i = 1, NUM_HULLS do
			flOffsets[i] = f:ReadFloat()
		end
		local nodetype = f:ReadByte()
		local nodeinfo = ReadUShort(f)
		local zone = f:ReadShort()
		
		local node = {
			pos = v,
			yaw = yaw,
			offset = flOffsets,
			type = nodetype,
			info = nodeinfo,
			zone = zone,
			neighbor = {},
			numneighbors = 0,
			link = {},
			numlinks = 0
		}
		table.insert(nodes, node)
	end
	
	local numLinks = ReadInt(f)
	local links = {}
	for i = 1, numLinks do
		local link = {}
		local srcID = f:ReadShort()
		local destID = f:ReadShort()
		local nodesrc = nodes[srcID + 1]
		local nodedest = nodes[destID + 1]
		if nodesrc and nodedest then
			table.insert(nodesrc.neighbor, nodedest)
			nodesrc.numneighbors = nodesrc.numneighbors + 1
			table.insert(nodesrc.link, link)
			nodesrc.numlinks = nodesrc.numlinks + 1
			link.src = nodesrc
			link.srcID = srcID + 1
			
			table.insert(nodedest.neighbor, nodesrc)
			nodedest.numneighbors = nodedest.numneighbors + 1
			table.insert(nodedest.link, link)
			nodedest.numlinks = nodedest.numlinks + 1
			link.dest = nodedest
			link.destID = destID + 1
		else MsgN("Unknown link source or destination " .. srcID .. " " .. destID) end
		local moves = {}
		for i = 1, NUM_HULLS do
			moves[i] = f:ReadByte()
		end
		link.move = moves
		table.insert(links, link)
	end
	
	local lookup = {}
	for i = 1, numNodes do
		table.insert(lookup, ReadInt(f))
	end
	f:Close()
	nodegraph.nodes = nodes
	nodegraph.links = links
	nodegraph.lookup = lookup
	NEXTBOT_m_nodegraph = nodegraph
	return nodegraph
end

--Get the nearest node from the given position.
function ENT:GetNearestNode(pos)
	local pos = pos or self:GetPos()
	local dist, nearest, node = math.huge, math.huge, nil
	for i, n in ipairs(NEXTBOT_m_nodegraph.nodes) do
		dist = pos:DistToSqr(n.pos)
		if n.type == NODE_TYPE_GROUND and nearest > dist then
			nearest = dist
			node = n
		end
	end
	return node
end

--Find a path to the given position.
function ENT:FindPath(dest)
	local goal = self:GetNearestNode(dest)
	local begin = self:GetNearestNode()
	if not (goal and begin) then return end
	
	local result, open, closed = {}, {}, {}
	local cost, estimated = 0, self:GetPos():DistToSqr(dest)
	local totalcost = estimated
	open[self:GetNearestNode()] = {
		parent = nil,
		totalcost = totalcost,
		cost = 0,
		heuristic = estimated
	}
	
	local index = 0
	for i, n in pairs(open) do index = index + 1 end
	while index > 0 do
		local c, near = 0, math.huge
		for i, n in pairs(open) do
			c = n.totalcost
			if near > c then near, test = c, i end
		end
		closed[test] = {
			parent = open[test].parent,
			totalcost = open[test].totalcost,
			cost = open[test].cost,
			heuristic = open[test].heuristic,
		}
		open[test] = nil
		
		if test.pos == goal.pos then break end
		for i, n in pairs(test.neighbor) do
			if util.TraceHull({
				start = test.pos + vector_up, endpos = n.pos + vector_up,
				maxs = self:OBBMaxs(), mins = self:OBBMins(),
				filter = self, mask = MASK_NPCSOLID
			}).Hit then continue end
			if (n.pos - test.pos):Length2DSqr() > math.abs(n.pos.z - test.pos.z)^2 and
				n.type == NODE_TYPE_GROUND then
				cost = closed[test].cost
				estimated = test.pos:DistToSqr(n.pos) + n.pos:DistToSqr(dest)
				totalcost = cost + estimated
				if not (open[n] or closed[n]) then
				--	(open[n] and closed[test].totalcost > totalcost) or
				--	(closed[n] and closed[n].totalcost > totalcost) then
				
					open[n] = {
						parent = test,
						totalcost = totalcost,
						cost = cost,
						heuristic = estimated,
					}
					closed[n] = nil
				end
			end
		end
		
		coroutine.yield()
		index = 0
		for i, n in pairs(open) do index = index + 1 end
	end
	
	table.insert(result, closed[goal])
	
	while closed[test] and closed[test].parent do
		debugoverlay.Line(test.pos, closed[test].parent.pos, 5, Color(255, 255, 0, 255), true)
		debugoverlay.Axis(closed[test].parent.pos, angle_zero, 100, 5, true)
		test = closed[test].parent
		table.insert(result, closed[test])
	end
	
	return closed, goal
end