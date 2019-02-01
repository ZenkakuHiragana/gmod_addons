
local dvd = DecentVehicleDestination

AddCSLuaFile()
ENT.Base = "npc_decentvehicle"
ENT.PrintName = dvd.Texts.npc_dvtaxi
ENT.Coming = false
ENT.Transporting = false
ENT.Model = "models/player/odessa.mdl"
ENT.IsDVTaxiDriver = true
ENT.WaitForCaller = false

list.Set("NPC", "npc_dvtaxi", {
	Name = ENT.PrintName,
	Class = "npc_dvtaxi",
	Category = "GreatZenkakuMan's NPCs",
})

if CLIENT then return end
function ENT:ShouldStop()
	if self.WaitForCaller then return true end
	return self.BaseClass.ShouldStop(self)
end

function ENT:Think()
	self.BaseClass.Think(self)
	if isnumber(self.WaitForCaller) and CurTime() > self.WaitForCaller
	or isnumber(self.ClearMemory) and CurTime() > self.ClearMemory then
		if IsValid(self.Caller) and self.Caller:IsPlayer() then
			net.Start "Decent Vehicle: The taxi driver says something localized"
			net.WriteUInt(5, 4) -- The passenger got off the taxi
			net.Send(self.Caller)
			if engine.ActiveGamemode() == "darkrp" then
				self.Caller:ChatPrint(dvd.Texts.Taxi.Fare:format(dv.Fare))
				self.Caller:SetDarkRPVar("money", math.max(self.Caller.DarkRPVars.money - dv.Fare, 0))
			end
			
			local seats = self.v:GetChildren()
			if self.v.IsScar then seats = self.v.Seats end
			for i, s in ipairs(seats) do
				if not (IsValid(s) and s:IsVehicle()) then continue end
				if self.v.IsScar and not s.IsScarSeat then continue end
				local p = s:GetDriver()
				if IsValid(p) and p:IsPlayer() and self.Caller ~= p then
					net.Start "Decent Vehicle: The taxi driver says something localized"
					net.WriteUInt(1, 4) -- A new passenger got in the taxi
					net.Send(p)
					net.Start "Decent Vehicle: Open a taxi menu"
					net.WriteEntity(self)
					net.Send(p)
					self.Caller = p
					self.ClearMemory = nil
					self.Coming = false
					self.Transporting = false
					self.WaitForCaller = true
					return true
				end
			end
		end
		
		self.Caller = nil
		self.ClearMemory = nil
		self.Coming = false
		self.Transporting = false
		self.WaitForCaller = nil
		self.WaypointList = {}
	end
	
	return true
end

function ENT:Initialize()
	self.BaseClass.Initialize(self)
	if not IsValid(self.v) then return end
	dvd.TaxiDrivers[self] = true
	if CLIENT or not istable(self.v.VehicleTable) then return end
	self:SetNWString("CarName", self.v.VehicleTable.Name)
end

function ENT:OnRemove()
	self.BaseClass.OnRemove(self)
	dvd.TaxiDrivers[self] = nil
end
