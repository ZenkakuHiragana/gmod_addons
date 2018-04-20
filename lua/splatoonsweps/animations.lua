
-- Some codes for player do not become squid and is in fence.
local ss = SplatoonSWEPs
if not ss then return end

-- hook.Add("UpdateAnimations", "SplatoonSWEPs: Handle animations for those who is in fence", function(ply, velocity, maxgroundspeed)
	-- if not ply:Crouching() then return end
	-- local w = ss:IsValidInkling(ply)
	-- if not (w and w:GetInFence()) then return end
	
	-- local len = velocity:Length()
	-- local movement = 1.0
	-- if len > 0.2 then
		-- movement = len / maxseqgroundspeed
	-- end
	
	-- local rate = math.min(movement, 2)

	if we're under water we want to constantly be swimming..
	-- if ply:WaterLevel() >= 2 then
		-- rate = math.max(rate, 0.5)
	-- elseif len >= 1000 then 
		-- rate = 0.1
	-- end
	
	-- ply:SetPlaybackRate(rate)
-- end)
