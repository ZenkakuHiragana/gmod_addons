
-- do return end -- Uncomment this to disable debugging

AddCSLuaFile()
local ss = SplatoonSWEPs
if not ss then return end

ss.Debug = {}
require "greatzenkakuman/debug"
local d = greatzenkakuman.debug
local sd = ss.Debug

function d.DLoop() end
if CLIENT then hook.Remove("CreateMove", "Test") end
local ShowInkChecked = false -- Draws ink boundary.
local ShowInkDrawn = false -- When ink hits, show ink surface painted by it.
local MovedOnly = false -- ShowInkDrawn but only for surfaces with "moved" tag.
local ShowBlasterRadius = false -- Shows where blaster explosion will be.
local ChargeQuarter = false -- Press Shift to fire any charger at 25% charge.
local DrawInkUVMap = false -- Press Shift to draw ink UV map.
local DrawInkUVBounds = false -- Also draws UV boundary.
local ShowInkSurface = false -- Press E for serverside, Shift for clientside, draws ink surface nearby player #1.
local ShowInkChecked_ServerTime = CurTime()
function sd.ShowInkChecked(r, surf, i)
    if not ShowInkChecked then return end
    local debugv = {Vector(-r.ratio, -1), Vector(r.ratio, -1), Vector(r.ratio, 1), Vector(-r.ratio, 1)}
    for _, v in ipairs(debugv) do v:Rotate(Angle(0, -r.angle)) v:Mul(r.radius) v:Add(r.pos) end
    if CLIENT then d.DTick() end
    if SERVER then
        if CurTime() < ShowInkChecked_ServerTime then return end
        ShowInkChecked_ServerTime = CurTime() + 1
        d.DShort()
    end

    local c = ss.GetColor(r.color)
    d.DColor()
    d.DPoly {
    	ss.To3D(debugv[1], surf.Origins[i], surf.Angles[i]),
    	ss.To3D(debugv[2], surf.Origins[i], surf.Angles[i]),
    	ss.To3D(debugv[3], surf.Origins[i], surf.Angles[i]),
    	ss.To3D(debugv[4], surf.Origins[i], surf.Angles[i]),
    }
    d.DColor(c.r, c.g, c.b)
    for b in pairs(r.bounds) do
        local b1, b2, b3, b4 = unpack(b)
        local v1 = ss.To3D(Vector(b1, b2), surf.Origins[i], surf.Angles[i])
        local v2 = ss.To3D(Vector(b1, b4), surf.Origins[i], surf.Angles[i])
        local v3 = ss.To3D(Vector(b3, b4), surf.Origins[i], surf.Angles[i])
        local v4 = ss.To3D(Vector(b3, b2), surf.Origins[i], surf.Angles[i])
        d.DText(v1, string.format("(%d, %d)", b1, b2))
        d.DText(v3, string.format("(%d, %d)", b3, b4))
        d.DPoly {v1, v2, v3, v4}
    end
end

function sd.ShowInkDrawn(s, c, b, surf, q, moved)
    if not ShowInkDrawn then return end
    if MovedOnly and not moved then return end
    d.DShort()
    d.DColor()
    -- d.DBox(s * ss.PixelsToUV * 500, b * ss.PixelsToUV * 500)
    -- d.DPoint(c * ss.PixelsToUV * 500)
    local v = {}
    for i, w in ipairs(surf.Vertices[q.n]) do v[i] = w.pos end
    d.DPoly(v)
end

if ShowBlasterRadius then
    function d.DLoop() -- Show blaster explosion radius
        local ply = player.GetByID(1)
        if not IsValid(ply) then return end
        local w = ss.IsValidInkling(ply)
        if not w then return end
        if not w.IsBlaster then return end
        local pos, dir = w:GetFirePosition()
        local ink = {
            DamageClose = w.Primary.DamageClose,
            DamageMiddle = w.Primary.DamageMiddle,
            DamageFar = w.Primary.DamageFar,
            ColRadiusClose = w.Primary.ColRadiusClose,
            ColRadiusMiddle = w.Primary.ColRadiusMiddle,
            ColRadiusFar = w.Primary.ColRadiusFar,
            endpos = pos + dir * w:GetRange(),
        }
        d.DTick()
        d.DColor()
        d.DPoint(ink.endpos, false)
        d.DColor(0, 255, 0, 16)
        d.DSphere(ink.endpos, ink.ColRadiusFar, false)
        d.DColor()
        for _, e in ipairs(ents.FindInSphere(ink.endpos, ink.ColRadiusFar)) do
            if not IsValid(e) or e:Health() <= 0 or e == ply then continue end
            local dmg = ink.DamageClose
            local dist = Vector()
            local maxs, mins = e:OBBMaxs(), e:OBBMins()
            local origin = e:LocalToWorld(e:OBBCenter())
            d.DABox(e:GetPos(), mins, maxs, e:GetAngles())
            local size = (maxs - mins) / 2
            for i, dir in pairs {x = e:GetForward(), y = e:GetRight(), z = e:GetUp()} do
                local segment = dir:Dot(ink.endpos - origin)
                local sign = segment == 0 and 0 or segment > 0 and 1 or -1
                segment = math.abs(segment)
                if segment <= size[i] then continue end
                dist = dist + sign * (size[i] - segment) * dir
            end
            d.DVector(ink.endpos, dist)

            dist = dist:Length()
            if dist > ink.ColRadiusMiddle then
                d.DColor(0, 255, 0)
                d.DSphere(ink.endpos, ink.ColRadiusMiddle, false)
                dmg = math.Remap(dist, ink.ColRadiusMiddle, ink.ColRadiusFar, ink.DamageMiddle, ink.DamageFar)
            elseif dist > ink.ColRadiusClose then
                d.DColor(255, 255, 0, 16)
                d.DSphere(ink.endpos, ink.ColRadiusMiddle, false)
                d.DColor(255, 255, 0)
                d.DSphere(ink.endpos, ink.ColRadiusClose, false)
                dmg = math.Remap(dist, ink.ColRadiusClose, ink.ColRadiusMiddle, ink.DamageClose, ink.DamageMiddle)
            end

            d.DSText(.01, .01, dmg)
        end
    end
end

if CLIENT then
    if ChargeQuarter then
        local t = CurTime() -- Charge 25%
        hook.Add("CreateMove", "Test", function(c)
            if not c:KeyDown(IN_SPEED) then return end
            if CurTime() < t then return end
            local p = LocalPlayer()
            local w = ss.IsValidInkling(p)
            if not (w and w.GetChargeProgress) then return end
            local r = w:GetChargeProgress(true)
            if r < .25 then
                c:SetButtons(bit.bor(c:GetButtons(), IN_ATTACK))
            else
                t = CurTime() + 1
            end
        end)
    end

    if DrawInkUVMap then
        local c = 500
        function d.DLoop() -- Draw ink UV map
            -- setpos 0 250 500; setang 90 -90 0
            local ply = LocalPlayer()
            if not ply:KeyPressed(IN_SPEED) then return end
            d.DShort()
            d.DColor(255, 255, 255)
            d.DPoly {Vector(0, 0), Vector(0, c), Vector(c, c), Vector(c, 0)}
            d.DColor(255, 0, 0)
            d.DVector(Vector(c, 0), Vector(c, 0))
            d.DColor(0, 255, 0)
            d.DVector(Vector(0, c), Vector(0, c))
            d.DColor()
            local surf = ss.SequentialSurfaces
            for i, v in ipairs(surf.Vertices) do
                local t = {}
                for i, w in ipairs(v) do t[i] = Vector(w.u, w.v) * c end
                d.DPoly(t)
            end

            if not DrawInkUVBounds then return end
            d.DColor(255, 255, 255)
            for i, u in ipairs(surf.u) do
                local v = surf.v[i]
                local bu, bv = surf.Bounds[i].x * ss.UnitsToUV, surf.Bounds[i].y * ss.UnitsToUV
                d.DVector(Vector(u, v) * c, vector_up * c / 500)
                d.DPoly {
                    Vector(u, v) * c,
                    Vector(u + bu, v) * c,
                    Vector(u + bu, v + bv) * c,
                    Vector(u, v + bv) * c,
                }
            end
        end
    end
end

if ShowInkSurface then
    local key = SERVER and IN_USE or IN_SPEED
    function d.DLoop()
        local ply = player.GetByID(1)
        if not IsValid(ply) then return end
        if not ply:KeyPressed(key) then return end
        d.DShort()
        d.DColor()
        for node in ss.BSPPairs {ply:GetPos()} do
            local surf = SERVER and node.Surfaces or ss.SequentialSurfaces
            for i, index in pairs(SERVER and surf.Indices or node.Surfaces) do
                local v = {}
                for k, w in ipairs(surf.Vertices[i]) do v[k] = SERVER and w or w.pos end
                d.DPoly(v)
            end
        end
    end
end