WireToolSetup.setCategory( "Other" )
WireToolSetup.open( "dv_wiremanager", "Waypoint Manager", "gmod_wire_dvmanager", nil, "Waypoint Managers" )

local dvd = DecentVehicleDestination
if CLIENT then
	language.Add( "Tool.wire_dv_wiremanager.name", dvd.Texts.WireSupport.ToolName)
	language.Add( "Tool.wire_dv_wiremanager.desc", dvd.Texts.WireSupport.ToolDesc)
end
WireToolSetup.BaseLang()
WireToolSetup.SetupMax( 100 )
WireToolSetup.SetupLinking(true, "waypoint")

TOOL.ClientConVar = {
	model = "models/props_c17/lampShade001a.mdl",
}

if SERVER then function TOOL:GetConVars() end end
function TOOL:RightClick(trace)
    if CLIENT then return true end
    if self:GetStage() == 0 then -- stage 0: right-clicking on our own class selects it
        local ent = trace.Entity
        if not IsValid(ent) then return false end
        if self:CheckHitOwnClass(trace) then
            self.Controller = ent
            self:SetStage(1)
            return true
        else
            return false
        end
    elseif self:GetStage() == 1 then -- stage 1: right-clicking on something links it
        if not IsValid(self.Controller) then self:SetStage(0) return end
        local pos = trace.HitPos
        local waypoint, waypointID = dvd.GetNearestWaypoint(pos, dvd.WaypointSize)
        if not waypoint then return false end
        local ply = self:GetOwner()
        local success, message = self.Controller:LinkEnt(waypointID)
        if success then
            if self.SingleLink or not ply:KeyDown(IN_SPEED) then self:SetStage(0) end
            self.HasLinked = true
            WireLib.AddNotify(ply, "Linked waypoint #" .. tostring(waypointID) .. " to the ".. self.Name, NOTIFY_GENERIC, 5)
        else
            WireLib.AddNotify(ply, message or "That entity is already linked to the ".. self.Name, NOTIFY_ERROR, 5, NOTIFYSOUND_DRIP3)
        end

        return success
    end
end

function TOOL:Reload(trace)
    if not trace.HitPos or not IsValid(trace.Entity) or trace.Entity:IsPlayer() then
        self:SetStage(0)
        return false
    end
    if CLIENT then return true end
    if not self:CheckHitOwnClass(trace) then return false end

    self:SetStage(0)
    local ent = trace.Entity
    local ply = self:GetOwner()
    local waypointID = ent:GetNWInt "WaypointID"
    if waypointID < 0 then return false end

    -- Regardless of stage, reloading on our own class clears it
    ent:UnlinkEnt()
    WireLib.AddNotify(ply, "Unlinked waypoint #" .. tostring(waypointID) .. " from the " .. self.Name, NOTIFY_GENERIC, 7)

    return true
end

function TOOL.BuildCPanel(panel)
	WireDermaExts.ModelSelect(panel, "wire_dv_wiremanager_model", list.Get( "[DV] WireManager Model List" ), 4, true)
end
