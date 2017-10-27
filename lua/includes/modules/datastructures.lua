assert(SZL, "SZL is required.")
if getfenv() ~= SZL then setfenv(1, SZL) end

--Basic container class
--Stack
--Queue

SZL.DataStructures = true
function Stack() makeclass()
	local data = {}
	function clear() data = {} end
	function isempty() return size() == 0 end
	function pop() return table.remove(data) end
	function push(addend) table.insert(data, addend) end
	function size() return #data end
	function top() return data[size()] end
return (endclass()) end

function Queue(initsize) makeclass()
	local AddMemoryBlock = 16
	if not isnumber(initsize) then initsize = AddMemoryBlock end
	local front, back, count, data, size = 1, 1, 0, {}, AddMemoryBlock
	local capacity = initsize
	
	function enqueue(addend)
		if not isfull() then
			data[back] = addend
			back = back % capacity + 1
			count = count + 1
		else
			print("buffer overflow", count)
			local newdata, back, count, cap = {}, 1, 0, capacity + AddMemoryBlock
			while not isempty() do
				newdata[back] = dequeue()
				back = back % cap + 1
				count = count + 1
			end
			
			front = 1
			back = back
			count = count
			capacity = cap
			data = newdata
			enqueue(addend)
		end
	end

	function dequeue()
		if not isempty() then
			local data = data[front]
			front = front % capacity + 1
			count = count - 1
			return data
		end
	end

	function top() if not isempty() then return data[front] end end
	function size() return count end
	function isfull() return count >= capacity end
	function isempty() return count <= 0 end
return (endclass()) end
