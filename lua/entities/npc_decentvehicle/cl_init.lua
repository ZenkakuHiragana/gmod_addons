include "shared.lua"
include "playermeta.lua"

function ENT:Draw()
	self:DrawModel()
end

function ENT:Initialize()
	self:SetModel(self.Modelname)
	self:SetMoveType(MOVETYPE_NONE)
end

local dvd = DecentVehicleDestination
local Height = vector_up * dvd.WaypointSize / 4
local WaypointMaterial = Material "sprites/sent_ball"
local LinkMaterial = Material "cable/blue_elec"
hook.Add("PostDrawTranslucentRenderables", "Decent Vehicle: Draw waypoints",
function(bDrawingDepth, bDrawingSkybox)
	if bDrawingSkybox then return end
	for _, w in ipairs(dvd.Waypoints) do
		render.SetMaterial(WaypointMaterial)
		render.DrawSprite(w.Target + Height, dvd.WaypointSize, dvd.WaypointSize, color_white)
		render.SetMaterial(LinkMaterial)
		for _, n in ipairs(w.Neighbors) do
			local pos = dvd.Waypoints[n].Target
			local tex = w.Target:Distance(pos) / 100
			render.StartBeam(2)
			render.AddBeam(w.Target + Height, 20, 1 - CurTime() % 1, color_white)
			render.AddBeam(pos + Height, 20, 1 - CurTime() % 1 + tex, color_white)
			render.EndBeam()
		end
	end
end)
