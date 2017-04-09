--[[
	Splashootee is a Splashooter's projectile.
	This prints orange ink if it hit a wall.
]]

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.RenderGroup = RENDERGROUP_TRANSLUCENT
 
ENT.PrintName		= "Splashootee"
ENT.Author			= "Himajin Jichiku"
ENT.Contact			= "none"
ENT.Purpose			= "splat ink"
ENT.Instructions	= "none"

ENT.FallTimer = 10
ENT.SplashNum = 1
ENT.SplashLen = 1
ENT.SplashInit = 1
ENT.V0 = Vector(0, 0, 0)
ENT.InkRadius = 20
ENT.DropInitname = ""
ENT.Dropname = ""
ENT.InkDmgname = ""
ENT.Normal = Vector(0, 0, 0)
ENT.AngleDif = Angle(0, 0, 0)
ENT.size = 0

function ENT:SetupDataTables()
	self:NetworkVar("Vector", 0, "scale")
	self:NetworkVar("Vector", 1, "delta")
	self:NetworkVar("String", 0, "ink")
end
