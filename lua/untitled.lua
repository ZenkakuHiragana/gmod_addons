
SplatoonSWEPs = SplatoonSWEPs or {}
local function isfunction(v) return type(v) == "function" end
local function istable(v) return type(v) == "table" end
local function PrintTable(t) for k, v in pairs(t) do print(k, v) end end
if not SplatoonSWEPs then return end

local meta_operators = {"__add", "__concat", "__div", "__eq", "__le", "__len", "__lt", "__mod", "__mul", "__pow", "__sub", "__unm",}
local function createInstance(self, ...)
	local instance = setmetatable({}, self)
	local initializeTable = instance
	while initializeTable and isfunction(initializeTable.init) do
		initializeTable:init(...)
		initializeTable = initializeTable.BaseClass
	end
	return instance
end

local classname_stack, classfunc, class = {}, {}, nil
local function define_class(classdata, baseclass)
	if istable(baseclass) then
		local baseclass, classname = baseclass[1], table.remove(classname_stack)
		classdata.BaseClass = baseclass
		classdata.__index = classdata.__index or classdata
		classdata.__tostring = classdata.__tostring or getmetatable(classdata).__tostring
		for k, m in ipairs(meta_operators) do
			classdata[m] = classdata[m] or (classdata.BaseClass and classdata.BaseClass[m])
		end
		SplatoonSWEPs[classname] = setmetatable(classdata, {__index = classdata.BaseClass, __call = createInstance, __tostring = classdata.__tostring})
		class = SplatoonSWEPs[classname_stack[#classname_stack]] or define_class
	else
		local classname = istable(classdata) and baseclass or classdata
		SplatoonSWEPs[classname] = setmetatable({}, {__call = define_class, __tostring = function() return classname end})
		table.insert(classname_stack, classname)
		class = SplatoonSWEPs[classname]
		return SplatoonSWEPs[classname]
	end
end
class = define_class
table.insert(classname_stack, define_class)

class "testclass1" do
	local child = class "child" do
		function class:init(v)
			print("testclass1 -> child init")
			self.value = v or 100
		end
		function class:show()
			print("testclass1 -> child show", self.value)
		end
	end class {}
	
	function class:init(v)
		print "Testclass1 init"
		self.value = v
		self.identifier = v * 2 + 3
	end
	function class:hoge()
		print "Testclass1 hoge"
	end
	function class:show()
		print("Testclass1 show", self.base, self.child, self.const)
	end
	function class.__eq(c1, c2)
		print("__eq", c1, c2)
		return true
	end
	class.const = 1
	class.base = true
	class.table = {}
end class {}

local testclass2 = class "testclass2" do
	function class:init(v)
		print "Testclass2 init"
		self.value = v
	end
	class.child = true
end class {SplatoonSWEPs.testclass1}

local c1 = SplatoonSWEPs.testclass1(1.111)
local c12 = SplatoonSWEPs.testclass1(2.222)
local c2 = testclass2(1.111)
c12.const = 2
print(SplatoonSWEPs.testclass1, testclass2, tostring(c1), c2)
c1:hoge()
c2:hoge()
c1:show()
c12:show()
c2:show()
print(c1 == c2)
