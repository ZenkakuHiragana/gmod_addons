
local ss = SplatoonSWEPs
if not ss then return end

local function PrecacheArc(cx, cy, radius, thickness, startang, endang, roughness)
	local triarc, inner, outer = {}, {}, {}
	local step = math.max(roughness or 20, 1) -- Define step
	local thickness = thickness or radius
	local startang, endang = startang or 0, endang or 360 -- Correct start/end ang
	if startang > endang then endang = endang + 360 end

	-- Create the inner and outer circle's points.
	for t, r in pairs {[inner] = radius - thickness, [outer] = radius} do
		for deg = startang, endang, step do
			local rad = math.rad(deg)
			local rx, ry = math.cos(rad) * r, math.sin(rad) * r
			t[#t + 1] = {
				x = cx + rx, y = cy - ry,
				u = .5 + rx / radius,
				v = .5 - ry / radius,
			}
		end
	end

	-- Triangulate the points.
	for tri = 1, #inner * 2 do -- Twice as many triangles as there are degrees.
		local p1 = outer[math.floor(tri / 2) + 1]
		local p2 = (tri % 2 > 0 and inner or outer)[math.floor(tri / 2 + .5)]
		local p3 = inner[math.floor(tri / 2 + .5) + 1]
		triarc[#triarc + 1] = {p1, p2, p3}
	end

	-- Return a table of triangles to draw.
	return triarc
end

-- Draws an arc on your screen.
-- startang and endang are in degrees,
-- radius is the total radius of the outside edge to the center.
-- cx, cy are the x,y coordinates of the center of the arc.
-- roughness determines how many triangles are drawn. Number between 1-360; 2 or 3 is a good number.
function ss.DrawArc(cx, cy, radius, thickness, startang, endang, roughness)
	for _, v in ipairs(PrecacheArc(cx, cy, radius, thickness, startang, endang, roughness)) do
		surface.DrawPoly(v)
	end
end
