
local ss = SplatoonSWEPs
if not ss then return end
include "shared.lua"

local function Spin(self, vm, weapon, ply)
	if self:GetCharge() < math.huge or self:GetFireInk() > 0 then
		local sgn = self:GetNWBool "Southpaw" and -1 or 1
		local prog = self:GetFireInk() > 0 and self:GetFireAt() or self:GetChargeProgress(true)
		local b = self:LookupBone "rotate_1" or 0
		local a = self:GetManipulateBoneAngles(b)
		local dy = RealFrameTime() * 60 / self.Primary.Delay * (prog + .1)
		a.y = a.y + sgn * dy
		self:ManipulateBoneAngles(b, a)
		if not IsValid(vm) then return end
		local b = vm:LookupBone "rotate_1" or 0
		local a = vm:GetManipulateBoneAngles(b)
		a.y = a.y + sgn * dy
		vm:ManipulateBoneAngles(b, a)
	end
	
	if not IsValid(vm) then return end
	function vm.GetInkColorProxy()
		return ss.ProtectedCall(self.GetInkColorProxy, self) or ss.vector_one
	end
	
	-- local s = ss.vector_one
	-- if self.ViewModelFlip then s = Vector(1, -1, 1) end
	-- vm:ManipulateBoneScale(vm:LookupBone "root_1" or 0, s)
end

SWEP.PreViewModelDrawn = Spin
SWEP.PreDrawWorldModel = Spin

function SWEP:GetArmPos() return (self:GetADS() or ss.GetOption "DoomStyle") and 5 or 1 end
