
--Shared library
if not SplatoonSWEPs then return end

--number miminum boundary size, table of Vectors
--returning AABB(mins, maxs)
function SplatoonSWEPs:GetBoundingBox(minbound, vectors)
	local mins = Vector(math.huge, math.huge, math.huge)
	local maxs = -mins
	for _, v in ipairs(vectors) do
		mins.x = math.min(mins.x, v.x - minbound)
		mins.y = math.min(mins.y, v.y - minbound)
		mins.z = math.min(mins.z, v.z - minbound)
		maxs.x = math.max(maxs.x, v.x + minbound)
		maxs.y = math.max(maxs.y, v.y + minbound)
		maxs.z = math.max(maxs.z, v.z + minbound)
	end
	return mins, maxs
end

--Vector AABB1(mins, maxs), Vector AABB2(mins, maxs) in world coordinates
--returning boolean, whether or not two AABBs intersect together
function SplatoonSWEPs:CollisionAABB(mins1, maxs1, mins2, maxs2)
	return mins1.x < maxs2.x and maxs1.x > mins2.x and
			mins1.y < maxs2.y and maxs1.y > mins2.y and
			mins1.z < maxs2.z and maxs1.z > mins2.z
end

--Vector AABB1(mins, maxs), Vector AABB2(mins, maxs) in world coordinates
--returning boolean, whether or not two AABBs intersect together
function SplatoonSWEPs:CollisionAABB2D(mins1, maxs1, mins2, maxs2)
	return mins1.x < maxs2.x and maxs1.x > mins2.x and
			mins1.y < maxs2.y and maxs1.y > mins2.y
end

--Vector(x, y, z), Vector new system origin, Angle new system angle
--returning localized Vector(x, y, 0)
function SplatoonSWEPs:To2D(source, orgpos, organg)
	local localpos = WorldToLocal(source, angle_zero, orgpos, organg)
	return Vector(localpos.y, localpos.z, 0)
end

--Vector(x, y, 0), Vector system origin in world coordinates, Angle system angle
--returning Vector(x, y, z)
function SplatoonSWEPs:To3D(source, orgpos, organg)
	local localpos = Vector(0, source.x, source.y)
	return (LocalToWorld(localpos, angle_zero, orgpos, organg))
end
