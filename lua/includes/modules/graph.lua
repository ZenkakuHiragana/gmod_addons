assert(SZL, "SZL is required.")
if getfenv() ~= SZL then setfenv(1, SZL) end

--Classes about graph structure
--Node
--k-d Tree (k = 1, 2, 3)
--Binary Tree
--Binary Search Tree (Ordered)
--AVL Tree
--Binary Heap

SZL.Graph = true
if not SZL.DataStructures then include "datastructures.lua" end
local function isnode(value)
	return istable(value) and tostring(value) == "Node"
end

local NodeMeta = {
	__tostring = function(op) return "Node" end,
	__eq = function(op1, op2)
		if not (isfunction(op1.get) and isfunction(op2.get)) then return false end
		return op1.get() == op2.get()
	end,
}
function Node(initdata) makeclass()
	local data, containerKey = initdata
	local adjacentTo = {}
	function get() return data end
	function getKey() return containerKey end
	function setKey(key) containerKey = key end
	function getChildren() return adjacentTo end
	function getChild(key) return adjacentTo[key] end
	function isleaf() return not next(adjacentTo) end
	function setlink(key, node) adjacentTo[key] = node end
	removelink = setlink
return (endclass(NodeMeta)) end

local SpacePartitionBitmasks = {
	{},
	{0x00FF00FF, 0x0F0F0F0F, 0x33333333, 0x55555555},
	{0x0000F00F, 0x000C30C3, 0x00249249},
}
function SpacePartitionTree(dimension, rootsize, depth, origin) makeclass()
	bitmask = SpacePartitionBitmasks[assert(dimension > 0 and dimension < 4 and dimension,
		"SZL SpacePartitionTree: Dimension must be within the range of 1 to 3!")]
	shiftmask =  bit.lshift(1, dimension) - 1
	origin = isvector(origin) and {origin.x, origin.y, origin.z}
			or istable(origin) and origin
			or {select(4 - dimension, 0, 0, 0)}
	local nodes = {}
	local size = rootsize
	local unitsize = rootsize / 2^depth
	local twopower = 2^dimension
	local pow = twopower^depth - 1
	local function bitSeparate(index)
		local result = index
		for i, mask in ipairs(bitmask) do
			result = bit.band(mask, bit.bor(result, bit.lshift(result, 8 / 2^(i - 1))))
		end
		return result
	end

	local function getMortonToIndex(morton) return pow / (twopower - 1) + morton + 1 end
	local function getMortonNumber(components)
		local bitarg = {}
		for i, x in ipairs(components) do
			table.insert(bitarg, bit.lshift(bitSeparate(math.floor(x / unitsize)), i - 1))
		end
		return math.min(bit.bor(unpack(bitarg)), twopower^depth - 1)
	end

	local function getIndex(...) return getMortonToIndex(getMortonNumber(...)) end
	local function getIndexBound(mins, maxs)
		if not maxs then maxs = isvector(mins) and mins or mins.x and mins.y and {mins.x, mins.y} or {unpack(mins)} end
		if isvector(mins) then mins = {mins.x, mins.y, mins.z} end
		if isvector(maxs) then maxs = {maxs.x, maxs.y, maxs.z} end
		for i = 1, dimension do
			mins[i] = mins[i] - origin[i]
			maxs[i] = maxs[i] - origin[i]
		end
		local morton = getMortonNumber(maxs)
		local xor = bit.bxor(getMortonNumber(mins), morton)
		local spacelevel, shift = depth, 0
		for i = 0, depth - 1 do
			if bit.band(xor, bit.lshift(shiftmask, i * dimension)) ~= 0 then
				spacelevel = depth - 1 - i
				shift = (i + 1) * dimension
			end
		end
		return (twopower^spacelevel - 1) / (twopower - 1) + bit.rshift(morton, shift) + 1
	end
	
	function getroot() return nodes[1] end
	function get(index) return nodes[index] end
	function set(newnode, key)
		if not isnode(newnode) then
			newnode = Node(newnode)
		end
		
		nodes[key] = newnode
		newnode.setKey(key)
	end

	function add(obj, mins, maxs)
		local index = getIndexBound(mins, maxs)
		if not nodes[index] then
			set({}, index)
			local child, parent = index, index
			while parent > 1 do
				parent = math.floor(((parent - 2) / twopower) + 1)
				if not nodes[parent] then set({}, parent) end
				nodes[parent].setlink(child % 2^dimension + 1, nodes[child])
				child = parent
			end
		end
		table.insert(nodes[index].get(), {get = obj, parent = index})
		return index
	end
	
	function foreach(func)
		for key, node in pairs(nodes) do
			local result = func(node, key)
			if result then return result, node, key end
		end
	end
	
	function search(value)
		local found, node, key = foreach(function(self, node, key) return node.get() == value end)
		return node, key
	end
	
	function boundpairs(mins, maxs)
		local indexbound = getIndexBound(mins, maxs)
		local reserve, q = {nodes[indexbound]}, {}
		while #reserve > 0 do
			local node = table.remove(reserve, 1)
			local data = node and node.get() or {}
			table.insert(q, #data > 0 and data or nil)
			for _, child in pairs(node.getChildren()) do
				table.insert(reserve, child)
			end
		end
		while indexbound > 1 do
			indexbound = math.floor(((indexbound - 2) / twopower) + 1)
			local node = nodes[indexbound]
			table.insert(q, node and node.get() or nil)
		end
		
		local i, itrnode = 0, table.remove(q, 1) or {}
		return function()
			i = i + 1
			if i > #itrnode then
				i = 1
				itrnode = table.remove(q, 1)
				if not itrnode then return end
			end
			return itrnode and itrnode[i] and itrnode[i].get
		end
	end
	
	function show()
		foreach(function(node, key)
			print("key", "=", key)
			if istable(node.get()) then
				print("value", "=")
				PrintTable(node.get())
				print "\n"
			else
				print("value", "=", node.get(), "\n")
			end
		end)
	end
return (endclass()) end

local DIR = enum {"LEFT", "RIGHT"}
function BinaryTree() makeclass()
	local root
	function BinaryNode(data) makeclass(Node(data))
		function getleft() return getChild(DIR.LEFT) end
		function getright() return getChild(DIR.RIGHT) end
		function setleft(node) setlink(DIR.LEFT, node) end
		function setright(node) setlink(DIR.RIGHT, node) end
	return (endclass(NodeMeta)) end
	
	function getroot() return root end
	function setroot(node)
		if istable(node) and isfunction(node.setParent) then node.setParent(false) end
		root = node
	end
	
	function add(node, parent, isright)
		if not isnode(node) then
			node = BinaryNode(node)
		end
		
		local key = isright and DIR.RIGHT or DIR.LEFT
		if parent then
			if parent.getChild(key) then
				node.setleft(parent.getChild(key).getleft())
				node.setright(parent.getChild(key).getright())
			end
			parent.setlink(key, node)
		else
			if root then
				node.setleft(root.getleft())
				node.setright(root.getright())
			end
			setroot(node)
		end
	end
	
	function foreach(func, buff)
		local q = Queue(buff)
		q.enqueue(getroot())
		while not q.isempty() do
			local node = q.dequeue()
			if node then
				local result = func(node)
				if result then return result end
				q.enqueue(node.getleft())
				q.enqueue(node.getright())
			end
		end
	end
return (endclass()) end

function BinarySearchTree() makeclass(BinaryTree()) --sorted tree: LEFT <= Parent < RIGHT
	function get(value, __eq, __lt)
		if not value then return false end
		local node, node_parent = getroot(), false
		while node do
			local eq = __eq and __eq(node.get(), value)
			if not __eq then eq = node.get() == value end
			if eq then
				return node, node_parent
			else
				node_parent = node
				local lt = __lt and __lt(node.get(), value)
				if not __lt then lt = node.get() < value end
				if lt then
					node = node.getright()
				else
					node = node.getleft()
				end
			end
		end
		return false, node_parent
	end
	
	function add(node, __eq, __lt)
		if not isnode(node) then node = BinaryNode(node) end
		local found, parent = get(node.get(), __eq, __lt)
		local isright = parent and parent.get() < node.get()
		BaseClass.add(node, parent, isright)
		return node, isright
	end
	
	function remove(value, __eq, __lt)
		local node, parent = get(value, __eq, __lt)
		if not node then return end
		local child = node.getleft() or node.getright()
		if node.getleft() and node.getright() then
			child = node.getleft()
			local upvalue = node
			while child.getright() do
				upvalue = child
				child = child.getright()
			end
			child.setright(node.getright())
			local __ne = __eq and not __eq(node.getleft(), child)
			if not __eq then __ne = node.getleft() ~= child end
			if __ne then
				upvalue.setright(child.getleft())
				child.setleft(node.getleft())
			end
		end
		
		if parent then
			parent.setlink(parent.get() < value and DIR.RIGHT or DIR.LEFT, child)
		else
			setroot(child)
		end
		return node
	end
	
	function getmax(node)
		local max = node or getroot()
		while max.getright() do
			max = max.getright()
		end
		return max
	end
	
	function getmin(node)
		local min = node or getroot()
		while min.getleft() do
			min = min.getleft()
		end
		return min
	end
	
	function getadjacent(value, __eq, __lt)
		local node, above, below, belownode = getroot()
		while node do
			local __gt = __lt and not __lt(node.get(), value)
			if not __lt then __gt = node.get() > value end
			if __gt then
				above = node.get()
				node = node.getleft()
			else
				local __ne = __eq and not __eq(node.get(), value)
				if not __eq then __ne = node.get() ~= value end
				if __ne then
					below = node.get()
				else
					belownode = node
				end
				node = node.getright()
			end
		end
		
		if belownode and belownode.getleft() then below = getmax(belownode.getleft()).get() end
		return above, below
	end
	
	function getnext(value, __lt)
		local node, above = getroot()
		while node do
			local __gt = __lt and not __lt(node.get(), value)
			if not __lt then __gt = node.get() > value end
			if __gt then
				above = node.get()
				node = node.getleft()
			else
				node = node.getright()
			end
		end
		
		return above
	end
	
	function getprev(value, __lt)
		local node, below = getroot()
		while node do
			local lt = __lt and __lt(node.get(), value)
			if not __lt then lt = node.get() < value end
			if lt then
				below = node.get()
				node = node.getright()
			else
				node = node.getleft()
			end
		end
		
		return below
	end
return (endclass()) end

function AVLTree() makeclass(BinarySearchTree())
	local function AVLNode(data) makeclass(BinaryNode(data))
		local bias, height, parent, parentkey = 0, 1, nil, nil
		local function getchildheight()
			local left, right = getleft(), getright()
			if left then left = left.getheight() else left = 0 end
			if right then right = right.getheight() else right = 0 end
			return left, right
		end
		
		function getParent() return parent end
		function setParent(p) parent = p end
		function getParentKey() return parentkey end
		function setParentKey(key) parentkey = key end
		function getleft() return getChild(DIR.LEFT) end
		function getright() return getChild(DIR.RIGHT) end
		function setleft(node) setlink(DIR.LEFT, node) end
		function setright(node) setlink(DIR.RIGHT, node) end
		function getbias()
			local left, right = getchildheight()
			return left - right
		end
		function getheight() return height end
		function setlink(key, node)
			getChildren()[key] = node
			if node then
				node.setParent(self)
				node.setParentKey(key)
			end
		end
		function refresh()
			height = math.max(getchildheight()) + 1
		end
	return (endclass(NodeMeta)) end
	
	local function replace(before, after)
		local parent = before.getParent()
		if parent then
			local direction = parent.getleft() == before and DIR.LEFT or DIR.RIGHT
			parent.setlink(direction, after)
		else
			setroot(after)
		end
	end
	
	local function rotateL(v)
		local u = v.getright()
		replace(v, assert(u, "can't rotate left"))
		v.setright(u.getleft())
		u.setleft(v)
		v.refresh()
		u.refresh()
		return u
	end
	
	local function rotateR(u)
		local v = u.getleft()
		replace(u, assert(v, "can't rotate right"))
		u.setleft(v.getright())
		v.setright(u)
		u.refresh()
		v.refresh()
		return v
	end
	
	local function rotateLR(node)
		rotateL(node.getleft())
		return rotateR(node)
	end
	
	local function rotateRL(node)
		rotateR(node.getright())
		return rotateL(node)
	end
	
	local function balance(bInsert, isleft, node)
		local fromleft = isleft
		while node do
			local bias, height = node.getbias(), node.getheight()
			if math.abs(bias) > 1 then
				if fromleft == bInsert then
					if bias > 1 then
						node = node.getleft().getbias() >= 0 and rotateR(node) or rotateLR(node)
					end
				elseif bias < -1 then
					node = node.getright().getbias() <= 0 and rotateL(node) or rotateRL(node)
				end
			else
				node.refresh()
			end
			
			fromleft, node = node.getParentKey() == DIR.LEFT, node.getParent()
			if not node or height == node.getheight() then break end
		end
	end
	
	function add(value, __eq, __lt)
		if value == nil then return end
		local node = AVLNode(value)
		BaseClass.add(node, __eq, __lt)
		balance(true, node.getParentKey() == DIR.LEFT, node.getParent())
	end
	
	function remove(value, __eq, __lt)
		local node, parent = get(value, __eq, __lt)
		-- assert(node, tostring(value))
		if not node then return end
		local child = node.getright()
		local balancenode, key = child, DIR.RIGHT
		if not balancenode then
			balancenode = node.getParent()
			key = node.getParentKey()
		end
		
		if node.getleft() then
			key = DIR.LEFT
			balancenode = node.getleft()
			child = getmax(node.getleft())
			child.setright(node.getright())
			local __ne = __eq and not __eq(node.getleft(), child)
			if not __eq then __ne = node.getleft() ~= child end
			if __ne then
				key = child.getParentKey()
				balancenode = child.getParent()
				child.getParent().setright(child.getleft())
				child.setleft(node.getleft())
			end
		end
		
		if parent then
			parent.setlink(node.getParentKey(), child)
		else
			setroot(child)
		end
		balance(false, key == DIR.LEFT, balancenode)
	end
	
	function checkbalanced()
		foreach(function(node)
			if math.abs(node.getbias()) > 1 then
				print "unbalanced"
				return true
			end
		end)
	end
	
	function show(node)
		node = node or getroot()
		if not node then return end
		foreach(function(node)
			local left, right, parent = node.getleft(), node.getright(), node.getParent()
			if left then left = left.get() end
			if right then right = right.get() end
			if parent then parent = parent.get() end
			print("   " .. tostring(parent))
			print "   |"
			print("   " .. tostring(node.get()), "height: " .. tostring(node.getheight()), "bias: " .. tostring(node.getbias()))
			print " /   \\"
			print(tostring(left) .. "     " .. tostring(right))
			print "--------------------------------"
		end)
	end
return (endclass()) end

function BinaryHeap(ismaxheap) makeclass()
	local nodes, nodeindex = {}, {}
	local function compare(op1, op2)
		if not (op1 and op2) then
			return false
		elseif ismaxheap then
			return op1 < op2
		else
			return op1 > op2
		end
	end
	
	local function getlowerchild(parent)
		local left, right = 2 * parent, 2 * parent + 1
		return compare(nodes[left], nodes[right]) and right or left
	end
	
	local function raise(value, index)
		local parent = math.floor(index / 2)
		while index > 1 and compare(nodes[parent], value) do
			nodes[index], nodes[parent] = nodes[parent], nodes[index]
			nodeindex[nodes[index]], nodeindex[nodes[parent]] = index, parent
			index, parent = parent, math.floor(parent / 2)
		end
		return index
	end
	
	local function lower(value, index)
		local child = getlowerchild(index)
		while child <= #nodes and compare(nodes[index], nodes[child]) do
			nodes[index], nodes[child] = nodes[child], nodes[index]
			nodeindex[nodes[index]], nodeindex[nodes[child]] = index, child
			index, child = child, getlowerchild(child)
		end
		return index
	end
	
	function root() return nodes[1] end
	function size() return #nodes end
	function isempty() return size() == 0 end
	function ismember(value) return nodeindex[value] end
	function add(value)
		if value ~= nil then
			local index = #nodes + 1
			nodes[index], nodeindex[value] = value, index
			raise(value, index)
		end
	end
	
	function remove(value)
		local removed = value or root()
		local removedindex = nodeindex[value] or 1
		local leaf = nodes[#nodes]
		nodeindex[removed] = nil
		if removedindex < #nodes then
			nodes[#nodes], nodes[removedindex] = nil, leaf
			nodeindex[leaf] = removedindex
			refresh(leaf)
		else
			nodes[#nodes], nodeindex[leaf] = nil, nil
		end
		return removed
	end
	
	function removeif(value)
		if nodeindex[value] then remove(value) end
	end
	
	function refresh(value)
		local index = nodeindex[value]
		if not index then return
		elseif lower(value, index) == index then
			raise(value, index)
		end
	end
	
	function show()
		for i, v in ipairs(nodes) do
			print(i, "=", v)
		end
	end
	
	function isvalid()
		for i, v in ipairs(nodes) do
			local cp1, cp2 = i * 2 <= #nodes, i * 2 + 1 <= #nodes
			if cp1 then cp1 = compare(nodes[i * 2], v) else cp1 = true end
			if cp2 then cp2 = compare(nodes[i * 2 + 1], v) else cp2 = true end
			print(cp1, cp2, nodeindex[v] == i, nodes[nodeindex[v] or -1] == v)
		end
	end	
return (endclass()) end
