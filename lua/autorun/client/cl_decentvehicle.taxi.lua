
-- Copyright © 2018-2030 Decent Vehicle
-- written by ∩(≡＾ω＾≡)∩ (https://steamcommunity.com/id/greatzenkakuman/)
-- and DangerKiddy(DK) (https://steamcommunity.com/profiles/76561198132964487/).

local dvd = DecentVehicleDestination
if not dvd then return end	

net.Receive("Decent Vehicle: Open a taxi menu", function()
	local st = net.ReadEntity()
	local DFrame = vgui.Create "DFrame"
	local stations = {}
	for k, v in ipairs(ents.GetAll()) do
		if not v.IsDVTaxiStation then continue end
		local name = v:GetStationName()
		if st.IsDVTaxiStation and name == st:GetStationName() then continue end
		stations[name] = true
	end
	
	DFrame:SetTitle "DV Taxi"
	DFrame:Center()
	DFrame:SetSize(200, 100)
	DFrame:SetSizable(true)
	DFrame:SetVisible(true)
	DFrame:SetDraggable(true)
	DFrame:ShowCloseButton(true)
	DFrame:MakePopup()
	function DFrame:OnClose()
		if DFrame.Called then return end
		if st.IsDVTaxiStation then return end
		net.Start "Decent Vehicle: Exit vehicle"
		net.WriteEntity(st)
		net.SendToServer()
	end
	
	if st.IsDVTaxiStation then
		local CurrentLocation = Label(st:GetStationName(), DFrame)
		CurrentLocation:Dock(TOP)
	end

	local DComboBox = vgui.Create("DComboBox", DFrame)
	DComboBox:Dock(TOP)
	for name in pairs(stations) do
		DComboBox:AddChoice(name)
	end

	local DButton = vgui.Create("DButton", DFrame)
	DButton:SetText(dvd.Texts.Taxi.Button)
	DButton:Dock(TOP)
	function DButton:DoClick()
		if DComboBox:GetValue() == "" then return DFrame:Close() end
		net.Start "Decent Vehicle: Call a taxi"
		net.WriteString(DComboBox:GetValue())
		net.WriteEntity(st)
		net.SendToServer()
		DFrame.Called = true
		DFrame:Close()
	end
end)
