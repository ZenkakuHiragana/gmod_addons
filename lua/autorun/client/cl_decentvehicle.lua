
-- Copyright © 2018-2030 Decent Vehicle
-- written by ∩(≡＾ω＾≡)∩ (https://steamcommunity.com/id/greatzenkakuman/)
-- and DangerKiddy(DK) (https://steamcommunity.com/profiles/76561198132964487/).

-- This script stands for a framework of Decent Vehicle's waypoints.
-- The waypoints are held in a sequential table.
-- They're found by brute-force search.

include "autorun/decentvehicle.lua"

-- Returns if v1 < v2
local VersionConst = Vector(1e8, 1e4, 1)
local function CompareVersion(v1, v2)
	v1 = Vector(tonumber(v1[1]) or 0, tonumber(v1[2]) or 0, tonumber(v1[3]) or 0)
	v2 = Vector(tonumber(v2[1]) or 0, tonumber(v2[2]) or 0, tonumber(v2[3]) or 0)
	return v1:Dot(VersionConst) < v2:Dot(VersionConst)
end

local dvd = DecentVehicleDestination
local function NotifyUpdate(d)
	if not d then return end
	local header = d.description:match "Version[^%c]+" or ""
	dvd.Texts.Version = "Decent Vehicle: " .. header
	
	local showupdates = GetConVar "dv_route_showupdates"
	if not (showupdates and showupdates:GetBool()) then return end
	
	if not file.Exists("decentvehicle", "DATA") then file.CreateDir "decentvehicle" end
	local versionfile = "decentvehicle/version.txt"
	local checkedversion = string.Explode(".", file.Read(versionfile) or "0.0.0")
	local version = string.Explode(".", header:sub(8):Trim())
	if tonumber(checkedversion[1]) > 1e8 then checkedversion = {} end -- Backward compatibility
	if CompareVersion(dvd.Version, version) then
		notification.AddLegacy(dvd.Texts.OldVersionNotify, NOTIFY_ERROR, 15)
	elseif CompareVersion(checkedversion, dvd.Version) then
		notification.AddLegacy("Decent Vehicle " .. header, NOTIFY_GENERIC, 18)
		
		local i = 0
		local description = d.description:sub(1, d.description:find "quote=Decent Vehicle" - 2)
		for update in description:gmatch "%[%*%][^%c]+" do
			timer.Simple(3 * i, function()
				if not showupdates:GetBool() then return end
				notification.AddLegacy(update:sub(4), NOTIFY_UNDO, 6)
			end)
			
			i = i + 1
		end
		
		file.Write(versionfile, string.format("%d.%d.%d",
		dvd.Version[1], dvd.Version[2], dvd.Version[3]))
	end
end

net.Receive("Decent Vehicle: Add a waypoint", function()
	local pos = net.ReadVector()
	local waypoint = {Target = pos, Neighbors = {}}
	table.insert(dvd.Waypoints, waypoint)
end)

net.Receive("Decent Vehicle: Remove a waypoint", function()
	local id = net.ReadUInt(24)
	for _, w in ipairs(dvd.Waypoints) do
		local Neighbors = {}
		for _, n in ipairs(w.Neighbors) do
			if n > id then
				table.insert(Neighbors, n - 1)
			elseif n < id then
				table.insert(Neighbors, n)
			end
		end
		
		w.Neighbors = Neighbors
	end
	
	table.remove(dvd.Waypoints, id)
end)

net.Receive("Decent Vehicle: Add a neighbor", function()
	local from = net.ReadUInt(24)
	local to = net.ReadUInt(24)
	if not dvd.Waypoints[from] then return end
	table.insert(dvd.Waypoints[from].Neighbors, to)
end)

net.Receive("Decent Vehicle: Remove a neighbor", function()
	local from = net.ReadUInt(24)
	local to = net.ReadUInt(24)
	if not dvd.Waypoints[from] then return end
	table.RemoveByValue(dvd.Waypoints[from].Neighbors, to)
end)

net.Receive("Decent Vehicle: Traffic light", function()
	local id = net.ReadUInt(24)
	local traffic = net.ReadEntity()
	if not dvd.Waypoints[id] then return end
	dvd.Waypoints[id].TrafficLight = Either(IsValid(traffic), traffic, nil)
end)

local PopupTexts = {
	dvd.Texts.OnSave,
	dvd.Texts.OnLoad,
	dvd.Texts.OnDelete,
	dvd.Texts.OnGenerate,
}
local Notifications = {
	dvd.Texts.SavedWaypoints,
	dvd.Texts.LoadedWaypoints,
	dvd.Texts.DeletedWaypoints,
	dvd.Texts.GeneratedWaypoints,
}
net.Receive("Decent Vehicle: Save and restore", function()
	local save = net.ReadUInt(dvd.POPUPWINDOW.BITS)
	local Confirm = vgui.Create "DFrame"
	local Text = Label(PopupTexts[save + 1], Confirm)
	local Cancel = vgui.Create "DButton"
	local OK = vgui.Create "DButton"
	Confirm:Add(Cancel)
	Confirm:Add(OK)
	Confirm:SetSize(ScrW() / 5, ScrH() / 5)
	Confirm:SetTitle "Decent Vehicle"
	Confirm:SetBackgroundBlur(true)
	Confirm:ShowCloseButton(false)
	Confirm:Center()
	Cancel:SetText(dvd.Texts.SaveLoad_Cancel)
	Cancel:SetSize(Confirm:GetWide() * 5 / 16, 22)
	Cancel:SetPos(Confirm:GetWide() * 7 / 8 - Cancel:GetWide(), Confirm:GetTall() - 22 - Cancel:GetTall())
	OK:SetText(dvd.Texts.SaveLoad_OK)
	OK:SetSize(Confirm:GetWide() * 5 / 16, 22)
	OK:SetPos(Confirm:GetWide() / 8, Confirm:GetTall() - 22 - OK:GetTall())
	Text:SizeToContents()
	Text:Center()
	Confirm:MakePopup()
	
	function Cancel:DoClick() Confirm:Close() end
	function OK:DoClick()
		net.Start "Decent Vehicle: Save and restore"
		net.WriteUInt(save, dvd.POPUPWINDOW.BITS)
		net.SendToServer()
		notification.AddLegacy(Notifications[save + 1], NOTIFY_GENERIC, 5)
		
		Confirm:Close()
	end
end)

hook.Add("PostCleanupMap", "Decent Vehicle: Clean up waypoints", function()
	table.Empty(dvd.Waypoints)
end)

hook.Add("InitPostEntity", "Decent Vehicle: Load waypoints", function()
	net.Start "Decent Vehicle: Retrive waypoints"
	net.WriteUInt(1, 24)
	net.SendToServer()
	
	steamworks.FileInfo("1587455087", NotifyUpdate)
end)

net.Receive("Decent Vehicle: Retrive waypoints", function()
	local id = net.ReadUInt(24)
	if id < 1 then return end
	local pos = net.ReadVector()
	local traffic = net.ReadEntity()
	if not IsValid(traffic) then traffic = nil end
	local num = net.ReadUInt(14)
	local neighbors = {}
	for i = 1, num do
		table.insert(neighbors, net.ReadUInt(24))
	end
	
	dvd.Waypoints[id] = {
		Target = pos,
		TrafficLight = traffic,
		Neighbors = neighbors,
	}
	
	net.Start "Decent Vehicle: Retrive waypoints"
	net.WriteUInt(id + 1, 24)
	net.SendToServer()
end)

net.Receive("Decent Vehicle: Send waypoint info", function()
	local id = net.ReadUInt(24)
	local waypoint = dvd.Waypoints[id]
	if not waypoint then return end
	waypoint.Group = net.ReadUInt(16)
	waypoint.SpeedLimit = net.ReadFloat()
	waypoint.WaitUntilNext = net.ReadFloat()
	waypoint.UseTurnLights = net.ReadBool()
	waypoint.FuelStation = net.ReadBool()
end)

net.Receive("Decent Vehicle: Clear waypoints", function()
	table.Empty(dvd.Waypoints)
end)

local FuelColor = Color(192, 128, 0)
local Height = vector_up * dvd.WaypointSize / 4
local WaypointMaterial = Material "sprites/sent_ball"
local LinkMaterial = Material "cable/blue_elec"
local TrafficMaterial = Material "cable/redlaser"
local UseTurnLightsMaterial = Material "icon16/arrow_turn_left.png"
hook.Add("PostDrawTranslucentRenderables", "Decent Vehicle: Draw waypoints",
function(bDrawingDepth, bDrawingSkybox)
	local weapon = LocalPlayer():GetActiveWeapon()
	if not IsValid(weapon) then return end
	
	local always = GetConVar "dv_route_showalways"
	local showpoints = GetConVar "dv_route_showpoints"
	local drawdistance = GetConVar "dv_route_drawdistance"
	local distsqr = drawdistance and drawdistance:GetFloat()^2 or 1000^2
	local size = dvd.WaypointSize
	if not always:GetBool() then
		if weapon:GetClass() ~= "gmod_tool" then return end
		local TOOL = LocalPlayer():GetTool()
		if not (TOOL and TOOL.IsDecentVehicleTool) then return end
	end
	
	if bDrawingSkybox or not (showpoints and showpoints:GetBool()) then return end
	for _, w in ipairs(dvd.Waypoints) do
		if w.Target:DistToSqr(EyePos()) > distsqr then continue end
		local visible = EyeAngles():Forward():Dot(w.Target - EyePos()) > 0
		if visible then
			render.SetMaterial(WaypointMaterial)
			render.DrawSprite(w.Target + Height, size, size, w.FuelStation and FuelColor or color_white)
			if w.UseTurnLights then
				render.SetMaterial(UseTurnLightsMaterial)
				render.DrawSprite(w.Target + Height, size, size, color_white)
			end
		end
		
		render.SetMaterial(LinkMaterial)
		for _, link in ipairs(w.Neighbors) do
			local n = dvd.Waypoints[link]
			if n and (visible or EyeAngles():Forward():Dot(n.Target - EyePos()) > 0) then
				local pos = n.Target
				local tex = w.Target:Distance(pos) / 100
				local texbase = 1 - CurTime() % 1
				render.DrawBeam(w.Target + Height, pos + Height, 20, texbase, texbase + tex, color_white)
			end
		end
		
		if IsValid(w.TrafficLight) then
			local pos = w.TrafficLight:GetPos()
			if visible or EyeAngles():Forward():Dot(pos - EyePos()) > 0 then
				local tex = w.Target:Distance(pos) / 100
				render.SetMaterial(TrafficMaterial)
				render.DrawBeam(w.Target + Height, pos, 20, 0, tex, color_white)
			end
		end
	end
end)

hook.Run "Decent Vehicle: PostInitialize"
