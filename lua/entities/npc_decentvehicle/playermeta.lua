
function ENT:CarCollide() end --For SCAR base
function ENT:PlayerEnteredSCar() end --For SCAR base
function ENT:InVehicle() return true end
function ENT:GetVehicle() return self.v end
function ENT:GetViewEntity() return NULL end
function ENT:SetEyeAngles() end
function ENT:UniqueID() return player.GetByID(1):UniqueID() end

if SERVER then
	function ENT:SendHint() end
	
	local InfoNum = {
		cl_simfphys_ctenable = 1,
		cl_simfphys_ctmul = .7,
		cl_simfphys_ctang = 15,
		cl_simfphys_auto = 1
	}
	function ENT:GetInfoNum(key, default) --For Simfphys Vehicles
		return InfoNum[key] or isnumber(default) and default or 0
	end
	
	function ENT:KeyDown(key)
		return key == IN_FORWARD and self.Throttle > 0
		or key == IN_BACK and self.Throttle < 0
		or key == IN_MOVELEFT and self.Steering < 0
		or key == IN_MOVERIGHT and self.Steering > 0
		or key == IN_JUMP and self.HandBrake
		or false
	end
	
	local vehiclemeta = FindMetaTable "Vehicle"
	local GetDriver = vehiclemeta.GetDriver
	function vehiclemeta:GetDriver(...)
		return not self.IsSimfphyscar and self.DecentVehicle or GetDriver(self, ...)
	end
else
	function ENT:KeyDown() return false end
end
