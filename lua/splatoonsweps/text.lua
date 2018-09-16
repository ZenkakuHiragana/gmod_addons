
-- Weapon names, descriptions, and other texts.

local ss = SplatoonSWEPs
if not ss then return end
function ss.GetColorName(colorid)
	return ss.Text.ColorNames[colorid or math.random(self.MAX_COLORS)]
end

local function TableToString(t)
	local str = ""
	for i, v in ipairs(t) do
		if i > 1 then str = str .. "\n" end
		str = str .. tostring(i) .. ":\t" .. tostring(v)
	end
	
	return str
end

local lang = GetConVar "gmod_language" :GetString()
local function ReadText(name)
	local json = ss.ReadJSON("text/en/" .. name)
	local localized = ss.ReadJSON("text/" .. lang .. "/" .. name)
	for k, v in pairs(localized) do
		if v == "" then continue end
		json[k] = v
	end
	
	return json
end

ss.Text = ReadText "misc"
ss.Text.PrintNames = ReadText "printnames"
ss.Text.PrintNames2 = ReadText "printnames2"
ss.Text.ColorNames = ReadText "colornames"
ss.Text.PlayermodelNames = ReadText "pmnames"
ss.Text.RTResolutionName = ReadText "rtresnames"
ss.Text.Error = ReadText "error"
ss.Text.Options = ReadText "options"
ss.Text.CVarDescription = ReadText "cvars"
ss.Text.CVarDescription.InkColor = ss.Text.CVarDescription.InkColor .. TableToString(ss.Text.ColorNames)
ss.Text.CVarDescription.Playermodel = ss.Text.CVarDescription.Playermodel .. TableToString(ss.Text.PlayermodelNames)

if SERVER then return end
language.Add("Cleanup_" .. ss.CleanupTypeInk, ss.Text.CleanupInk)
language.Add("Cleaned_" .. ss.CleanupTypeInk, ss.Text.CleanupInkMessage)
steamworks.RequestPlayerInfo("76561198013738310", function(name) ss.Text.Author = name end)
