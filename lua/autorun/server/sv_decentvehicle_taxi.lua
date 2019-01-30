
-- Copyright © 2018-2030 Decent Vehicle
-- written by ∩(≡＾ω＾≡)∩ (https://steamcommunity.com/id/greatzenkakuman/)
-- and DangerKiddy(DK) (https://steamcommunity.com/profiles/76561198132964487/).

local dvd = DecentVehicleDestination
if not dvd then return end
local UnitPrice = dvd.CVars.Taxi.UnitPrice

dvd.TaxiDrivers = dvd.TaxiDrivers or {}
dvd.TaxiStations = dvd.TaxiStations or {}
local function GetDriver(seat)
	if seat.DecentVehicle then return seat.DecentVehicle end
	if seat.IsScarSeat then
		seat = seat.EntOwner
	elseif IsValid(seat:GetParent()) then
		seat = seat:GetParent()
	else
		for e in pairs(constraint.GetAllConstrainedEntities(seat)) do
			if e.DecentVehicle then
				seat = e
				break
			end
		end
	end
	
	if not (IsValid(seat) and seat:IsVehicle()) then return end
	return seat.DecentVehicle
end

local function GetNearestTaxiDriver(pos)
	local mindistance, taxidriver = math.huge
	for driver in pairs(dvd.TaxiDrivers) do
		local distance = driver:GetPos():DistToSqr(pos)
		if not (IsValid(driver) and driver.IsDVTaxiDriver) then continue end
		if not (driver.Coming or driver.Transporting) and distance < mindistance then
			mindistance, taxidriver = distance, driver
		end
	end
	
	return taxidriver
end

local function StartGoing(ply, ent, dv)
	local route = dvd.GetRouteVector(ent:GetPos(), dv.Destinations)
	if not route or #route == 0 then return end
	
	local distance = 0
	for i, w in ipairs(route) do
		distance = distance + w.Target:Distance(route[math.max(i - 1, 1)].Target)
	end
	
	local unitprice = UnitPrice:GetInt() or 5
	local fare = math.max(unitprice, math.Round(distance / dvd.KmToHU * unitprice, 0))
	if engine.ActiveGamemode() == "darkrp" then
		if ply.DarkRPVars.money < fare then
			ply:ChatPrint(dvd.Texts.Taxi.NotEnoughMoney)
			dv.Caller = nil
			dv.Coming = false
			dv.Transporting = false
			dv.WaitForCaller = false
			return
		end
	end
	
	dv.Coming = false
	dv.Fare = fare
	dv.Transporting = true
	dv.WaitForCaller = false
	dv.WaypointList = route

	ply:ChatPrint(dvd.Texts.Taxi.StartGoing)
end

util.AddNetworkString "Decent Vehicle: Open a taxi menu"
util.AddNetworkString "Decent Vehicle: Call a taxi"
util.AddNetworkString "Decent Vehicle: Exit vehicle"
net.Receive("Decent Vehicle: Call a taxi", function(_, ply)
	local destination = net.ReadString()
	local ent = net.ReadEntity()
	local beginning = ent.IsDVTaxiStation and ent:GetStationName()
	local dv = ent.IsDVTaxiDriver and ent or GetNearestTaxiDriver(ply:GetPos())

	if not dv then ply:ChatPrint(dvd.Texts.Taxi.NoDriverFound) return end
	if dv.Coming or dv.Transporting then return end
	
	local cometo = {}
	local goingto = {}
	for st in pairs(dvd.TaxiStations) do
		if not (IsValid(st) and st.IsDVTaxiStation) then continue end
		local name = st:GetStationName()
		if name == beginning then
			table.insert(cometo, st:GetPos())
		elseif name == destination then
			table.insert(goingto, st:GetPos())
		end
	end
	
	local route = dvd.GetRouteVector(dv.Waypoint and dv.Waypoint.Target or dv:GetPos(), cometo)
	if beginning and (not route or #route == 0) then return end
	
	dv.Destinations = goingto
	if beginning then
		dv.WaypointList = route
		dv.Waypoint, dv.NextWaypoint = nil
		dv.Caller = ply
		dv.Coming = true
		dv.Transporting = false
		ply:ChatPrint(dvd.Texts.Taxi.Coming)
		ply:ChatPrint(dvd.Texts.Taxi.ShowCarName:format(dv.CarName))
	elseif ent.IsDVTaxiDriver then
		StartGoing(ply, ent, dv)
	end
end)

net.Receive("Decent Vehicle: Exit vehicle", function(_, ply)
	local dv = net.ReadEntity()
	local seat = ply:GetVehicle()
	if not IsValid(seat) then return end
	if dv ~= GetDriver(seat) then return end
	ply:ExitVehicle()
end)

hook.Add("Decent Vehicle: OnSaveWaypoints", "Save taxi stations", function(save)
	save.TaxiStations = {}
	for t in pairs(dvd.TaxiStations) do
		if not (IsValid(t) and t.IsDVTaxiStation) then continue end
		table.insert(save.TaxiStations, {
			Name = t:GetStationName(),
			Pos = t:GetPos(),
			Ang = t:GetAngles(),
			ClassName = t:GetClass(),
		})
	end
end)

hook.Add("Decent Vehicle: OnLoadWaypoints", "Load taxi stations", function(source)
	if not source.TaxiStations then return end
	for i, t in ipairs(source.TaxiStations) do
		local station = ents.Create(t.ClassName)
		if not IsValid(station) then continue end
		station:SetPos(t.Pos)
		station:SetAngles(t.Ang)
		station:Spawn()
		station:SetStationName(t.Name)

		local p = station:GetPhysicsObject()
		if IsValid(p) then p:Sleep() end
	end
end)

hook.Add("Decent Vehicle: OnReachedWaypoint", "Taxi reaches", function(self)
	if not self.IsDVTaxiDriver then return end
	if not istable(self.WaypointList) or #self.WaypointList > 0 then return end
	if not self.Caller then return end
	if self.Coming then
		self.WaitForCaller = CurTime() + math.random(30, 50)
		self.Caller:ChatPrint(dvd.Texts.Taxi.Arrived)
	elseif self.Transporting then
		self.WaitForCaller = true
		self.Caller:ChatPrint(dvd.Texts.Taxi.ArrivedDestination)
	end
end)

hook.Add("PlayerEnteredVehicle", "Decent Vehicle: Player entered a taxi", function(ply, seat, role)
	local dv = GetDriver(seat)
	if not (dv and dv.IsDVTaxiDriver) then return end
	if not dv.Caller then
		ply:ChatPrint(dvd.Texts.Taxi.Getin)
		net.Start "Decent Vehicle: Open a taxi menu"
		net.WriteEntity(dv)
		net.Send(ply)
		dv.Caller = ply
		dv.WaitForCaller = true
	elseif ply == dv.Caller then
		if not isnumber(dv.ClearMemory) then
			StartGoing(ply, seat, dv)
		end
		
		dv.ClearMemory = nil
	elseif dv.WaitForCaller then
		ply:ChatPrint(dvd.Texts.Taxi.Busy)
	end 
end)

hook.Add("PlayerLeaveVehicle", "Decent Vehicle: Player left a taxi", function(ply, seat)
	local dv = GetDriver(seat)
	if not (dv and dv.IsDVTaxiDriver) then return end
	if ply ~= dv.Caller then return end
	dv.ClearMemory = CurTime() + 0.1
end)
