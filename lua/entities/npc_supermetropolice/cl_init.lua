
include "shared.lua"

function ENT:Draw()
    local c = self:Health() / self:GetMaxHealth() * 255
    self:SetColor(Color(255, c, c))
    self:DrawModel()
end
