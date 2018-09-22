
AddCSLuaFile()

ENT.classname = "nextbot_tracer_hostile"

ENT.Base = "nextbot_tracer"
ENT.Type = "nextbot"

ENT.PrintName = "Nextbot Tracer(Hostile)"
ENT.Author = "GreatZenkakuMan"
ENT.Contact = ""
ENT.Purpose = ""
ENT.Spawnable = false
ENT.AutomaticFrameAdvance = true

local classname_hostile = ENT.classname
if SERVER then
	ENT.NPCClass = CLASS_COMBINE
	ENT.Relationship = {
		[CLASS_NONE] = D_NU,
		[CLASS_PLAYER] = D_HT,
		[CLASS_PLAYER_ALLY] = D_HT,
		[CLASS_PLAYER_ALLY_VITAL] = D_HT,
		[CLASS_ANTLION] = D_HT,
		[CLASS_BARNACLE] = D_HT,
		[CLASS_BULLSEYE] = D_NU,
		[CLASS_CITIZEN_PASSIVE] = D_HT,
		[CLASS_CITIZEN_REBEL] = D_HT,
		[CLASS_COMBINE] = D_LI,
		[CLASS_COMBINE_GUNSHIP] = D_NU,
		[CLASS_CONSCRIPT] = D_NU,
		[CLASS_HEADCRAB] = D_HT,
		[CLASS_MANHACK] = D_NU,
		[CLASS_METROPOLICE] = D_LI,
		[CLASS_MILITARY] = D_LI,
		[CLASS_SCANNER] = D_LI,
		[CLASS_STALKER] = D_LI,
		[CLASS_VORTIGAUNT] = D_HT,
		[CLASS_ZOMBIE] = D_HT,
		[CLASS_PROTOSNIPER] = D_LI,
		[CLASS_MISSILE] = D_FR,
		[CLASS_FLARE] = D_NU,
		[CLASS_EARTH_FAUNA] = D_NU,
		[CLASS_HACKED_ROLLERMINE] = D_HT,
		[CLASS_COMBINE_HUNTER] = D_LI,
	}
	
	local targetname = "NextbotTracerRelationship(Hostile)"
	hook.Add("OnEntityCreated", "NextbotTracerIsAlone!(Hostile)", function(e)
		if IsValid(e) and e:GetClass() ~= classname_hostile and isfunction(e.AddEntityRelationship) then
			local t = targetname .. e:EntIndex()
			timer.Create(t, 1, 0, function()
				if not IsValid(e) then timer.Remove(t) return end
				for k, v in pairs(ents.FindByClass(classname_hostile)) do
					if IsValid(v) then e:AddEntityRelationship(v, v:Disposition(e), 0) end
				end
			end)
		end
	end)
	
	--Receiving serverside sound.
	hook.Add("EntityEmitSound", "NextbotTracerHearsSoundHostile", function(t)
		if not IsValid(t.Entity) then return end
		for k, v in pairs(ents.FindByClass(classname_hostile)) do
			if t.Entity == v then return end
			if IsValid(v) and isfunction(v.OnHearSound) and v.IsInitialized and v:IsHearingSound(t) then
				v:OnHearSound(t)
			end
		end
	end)

	--Receiving clientside sound.
	util.AddNetworkString("NextbotTracerHearsSoundHostile")
	net.Receive("NextbotTracerHearsSoundHostile", function(len, ply)
		local bot = net.ReadEntity()
		local t = net.ReadTable()
		if IsValid(bot) and IsValid(t.Entity) and bot:GetClass() == classname_hostile and isfunction(bot.OnHearSound) then
			bot:OnHearSound(t)
		end
	end)
else
	language.Add(classname_hostile, ENT.PrintName)
	hook.Add("EntityEmitSound", "NextbotTracerHearsSoundHostile", function(t)
		if not IsValid(t.Entity) then return end
		for k, v in pairs(ents.FindByClass(classname_hostile)) do
			if t.Entity == v then return end
			if IsValid(v) and v.IsInitialized and v:IsHearingSound(t) then
				net.Start("NextbotTracerHearsSoundHostile")
				net.WriteEntity(v)
				net.WriteTable(t)
				net.SendToServer()
			end
		end
	end)
end

list.Set("NPC", ENT.classname, {
	Name = ENT.PrintName,
	Class = ENT.classname,
	Category = "Overwatch"
})
