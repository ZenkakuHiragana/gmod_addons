
--This lua manages whole ink in map.
SplatoonSWEPs.InkManager = {}
SplatoonSWEPs.InkManager.Think = function()
	
end

hook.Add("Tick", "SplatoonSWEPsDoInkCoroutine", SplatoonSWEPs.InkManager.Think)
