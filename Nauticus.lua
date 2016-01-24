-- declard color codes for console messages
local RED     = "|cffff0000"
local GREEN   = "|cff00ff00"
local BLUE    = "|cff0000ff"
local MAGENTA = "|cffff00ff"
local YELLOW  = "|cffffff00"
local CYAN    = "|cff00ffff"
local WHITE   = "|cffffffff"
local ORANGE  = "|cffffba00"

local Nauticus = Nauticus
local transitData = Nauticus.transitData
local L = Naut_localise

-- global variables
--known_times = {};
Nauticus.activeTransitName = ""
Nauticus.activeSelect = 1
Nauticus.activeTransit = -1
Nauticus.lowestNameTime = "--"
Nauticus.icon = "NauticusLogo"
Nauticus.activeData = { [0] = 0, [1] = 0 }
Nauticus.tempText = ""
Nauticus.tempTextCount = 0
Nauticus.updateNow = false

-- local variables
local vars_loaded = false
local update_int = 0.5
local ctime_elapse = 0
local oldx, oldy = 0, 0
local lastcheck = 0
local lastcheck_timeout = 10
local dataChannel = "NauticSync"
local nautVersion = "2.0"
local nautVersionNum = 200
--local protoVersion = "1.7"
local newVerAvail = false
local req_timeout
local knownTimesReq = {}
local dropdownvalues = {}
local dropdownindex = {}

local prox = 0.001
local debug = false

local alarmSet = false
local alarmDinged = false
local alarmOffset = 20
local alarmCountdown = 0

local Pre_ChatFrame_OnEvent

function Nauticus:OnLoad()

	this:RegisterEvent("VARIABLES_LOADED")
	this:RegisterEvent("PLAYER_LOGIN")
	this:RegisterEvent("CHAT_MSG_CHANNEL")
	this:RegisterEvent("ZONE_CHANGED_NEW_AREA")
	this:RegisterEvent("CHAT_MSG_SYSTEM")
	this:RegisterEvent("CHAT_MSG_CHANNEL_JOIN")
	this:RegisterEvent("CHAT_MSG_CHANNEL_NOTICE")

	-- register slash command
	SLASH_NAUT1 = "/nauticus"
	SLASH_NAUT2 = "/naut"

	SlashCmdList["NAUT"] = function(msg)
		Naut_SlashCommandHandler(msg)
	end

	Pre_ChatFrame_OnEvent = ChatFrame_OnEvent
	ChatFrame_OnEvent = Naut_ChatFrame_OnEvent

end

function Naut_ChatFrame_OnEvent(event)
	if ((event == "CHAT_MSG_CHANNEL") and (string.lower(arg9) == string.lower(dataChannel))) then
		-- silence
		if (debug) then
			return Pre_ChatFrame_OnEvent(event)
		end
	else
		return Pre_ChatFrame_OnEvent(event)
	end
end

function Nauticus:OnUpdate(elapse)

	if (req_timeout ~= nil) then
		req_timeout = req_timeout - elapse
		if (req_timeout <= 0) then
			local highPlayer = {}
			local highTimestamp = {}
			local highTime = {}
			local tmpTransTimestamps = {}

			for playerName, data in pairs(knownTimesReq) do
				for transport, transData in pairs(data) do
					if (tmpTransTimestamps[transport] == nil) then
						highPlayer[transport] = playerName
						highTimestamp[transport] = transData.timestamp
						highTime[transport] = transData.time
					elseif (tmpTransTimestamps[transport] > highTimestamp[transport]) then
						highPlayer[transport] = playerName
						highTimestamp[transport] = transData.timestamp
						highTime[transport] = transData.time
					end
				end
			end

			-- highest timestamp wins
			for transport, timestamp in pairs(highTimestamp) do
				nautSavedVars.timestamps[transport] = highTimestamp[transport]
				nautSavedVars.knownTimes[transport] = highTime[transport]
				req_timeout = nil
				knownTimesReq = {}

				if (debug) then
					Naut_DebugMessage("["..highPlayer[transport].."] has most recent transport time: "..
						highTime[transport]..", with timestamp: ".. highTimestamp[transport].." for ".. transport)
				end
			end
		end
	end

	if alarmDinged then
		alarmCountdown = alarmCountdown - elapse
		if (0 > alarmCountdown) then
			alarmSet = false
			alarmDinged = false
			PlaySound("AuctionWindowClose")
		end
	end

	ctime_elapse = ctime_elapse + elapse
	if (ctime_elapse > update_int or Nauticus.updateNow) then
		ctime_elapse = 0

		if ( (self.activeTransit ~= -1) and (nautSavedVars.knownTimes[self.activeTransit] ~= nil) ) then
			local transit = self.activeTransit
			local cycle = Naut_CalcTripCycle(transit)
			local platform = Nauticus_CalcIndexByCycle(transit, cycle)

			local lowestTime = 500

			for index, data in pairs(transitData[transit..'_plats']) do
				local platname

				if (nautSavedVars.config.CityAlias) then
					platname = data.alias
				else
					platname = data.name
				end

				getglobal("NautFramePlat"..(index+1).."Name"):SetText(platname)

				if (data.index == platform) then
					local depart_time = Naut_CalcTripCycleTimeByIndex(transit, platform) - cycle

					if (alarmSet and not alarmDinged and depart_time < alarmOffset) then
						alarmDinged = true
						alarmCountdown = depart_time
						PlaySoundFile("Sound\\Spells\\PVPFlagTakenHorde.wav")
					end

					local formatted_depart_time
	
					if (depart_time > 59) then
						formatted_depart_time = format("%0.0f", math.floor(depart_time/60)).."m "
							..format("%0.0f", depart_time-(math.floor(depart_time/60)*60)).."s"
					else
						formatted_depart_time = format("%0.0f", depart_time).."s"
					end

					local color

					if (depart_time > 30) then
						color = YELLOW
					else
						color = RED
					end

					getglobal("NautFramePlat"..(index+1).."ArrivalDepature"):SetText(color.."Dep: ".. formatted_depart_time)
					Nauticus.activeData[index] = -depart_time

					lowestTime = -500
					Nauticus.lowestNameTime = data.ebv..color.." "..formatted_depart_time
					Nauticus.icon = "Departing"
				else
					local arrival_time
					local cycleTime = Naut_CalcTripCycleTimeByIndex(transit, data.index-1)

					if (cycleTime > cycle) then
						arrival_time = cycleTime - cycle
					else
						arrival_time = transitData[transit..'_time'] - cycle
						arrival_time = arrival_time + cycleTime
					end

					local formatted_arrival_time
	
					if (arrival_time > 59) then
						formatted_arrival_time = format("%0.0f", math.floor(arrival_time/60)).."m "
							..format("%0.0f", arrival_time-(math.floor(arrival_time/60)*60)).."s"
					else
						formatted_arrival_time = format("%0.0f", arrival_time).."s"
					end

					getglobal("NautFramePlat"..(index+1).."ArrivalDepature"):SetText(GREEN.."Arr: ".. formatted_arrival_time)
					Nauticus.activeData[index] = arrival_time

					if (arrival_time < lowestTime) then
						lowestTime = arrival_time
						Nauticus.lowestNameTime = data.ebv.." "..GREEN..formatted_arrival_time
						Nauticus.icon = "Transit"
					end

				end

			end

			if (Nauticus.updateNow and NauticusFu ~= nil) then
				NauticusFu:Update()
			end

		end

		Nauticus.updateNow = false
	end

	lastcheck = lastcheck + elapse
	if (0.2 > lastcheck) then return end
	lastcheck = 0

	lastcheck_timeout = lastcheck_timeout + elapse
	if (lastcheck_timeout <= 10.0) then return end

	if IsInInstance() --[[or IsSwimming()]] then return end

	if (MapLibrary and MapLibrary.Ready) then
		--if MapLibrary.InInstance() then return; end
		-- try to get player coords without zooming map
		x, y = MapLibrary.GetWorldPosition("player", nil, 1)
		if not x then
			if WorldMapFrame:IsVisible() or ( AlphaMapFrame and AlphaMapFrame:IsVisible() ) then return end
			-- only force map change as last resort, should only happen out to sea etc.
			-- (but not while map mod visible, hopefully they stopped listening for WORLD_MAP_UPDATES)
			x, y = MapLibrary.GetWorldPosition("player", nil, nil)
			if not x then return end -- this shouldn't happen?
		end
	else
		-- fallback purposes only, will be deprecated eventually when integrate ML functionality
		if WorldMapFrame:IsVisible() or ( AlphaMapFrame and AlphaMapFrame:IsVisible() ) then return end
		local cont, zone = GetCurrentMapContinent(), GetCurrentMapZone()
		SetMapZoom(0)
		x, y = GetPlayerMapPosition("player")
		SetMapZoom(cont, zone)
	end

	-- have we moved by at least half the proximity range?
	if (not ( abs(x - oldx) <= (prox/2)
		and abs(y - oldy) <= (prox/2) ) ) then

		oldx, oldy = x, y

		--check X/Y coords against all triggers for all transports
		for t = 1, table.getn(transitData.transports), 1 do
			local transit = transitData.transports[t].label

			for i, index in pairs(transitData[transit..'_triggers']) do

				if ( abs(x - transitData[transit..'_data'].x[index]) <= prox  and
					abs(y - transitData[transit..'_data'].y[index]) <= prox ) then

					Naut_SetKnownTime(index, transit)
					return
				end
			end
		end
	end

end

--TODO: store last indexes of all transports?
local lastIndex = 1
function Nauticus_CalcIndexByCycle(transit, cycle)
	local offsets = transitData[transit..'_data'].offset

	if ( (lastIndex > table.getn(offsets) ) or
		(lastIndex > 1 and offsets[lastIndex-1] > cycle) ) then lastIndex = 1 end

	for i = lastIndex, table.getn(offsets) do
		if (offsets[i] > cycle) then
			lastIndex = i
			return i
		end
	end

	--should never get here but just in case of math errors?
	return 1
end

--[[function Nauticus_CalcIndexByCycle(transit, cycle)
	local offsets = transitData[transit..'_data'].offset

	for i = 1, table.getn(offsets) do
		if (offsets[i] > cycle) then
			return i
		end
	end

	--should never get here but just in case of math errors
	return 1
end]]

function Naut_CalcTripCycleTimeByIndex(transit, index)
	if index == 0 then return 0 end
	return transitData[transit..'_data'].offset[index]
end

function Naut_CalcTripCycle(transit)
	return math.mod(GetTime() - nautSavedVars.knownTimes[transit], transitData[transit..'_time'])
end

function Naut_SetKnownTime(value, transit)

	lastcheck_timeout = 0

	local sum_time = Naut_CalcTripCycleTimeByIndex(transit, value)

	nautSavedVars.knownTimes[transit] = GetTime() - sum_time
	nautSavedVars.knownTimes.uptime = GetTime()

	if (debug) then
		Naut_DebugMessage(transit..", cycle time: "..sum_time)
	end

	nautSavedVars.timestamps[transit] = time()

	Naut_SendMessage("KNOW "..transit.." "..(math.floor(sum_time*1000)/1000).." "
		..nautSavedVars.timestamps[transit])

end

function Naut_TransportSelect_Initialize()
	local info
	dropdownvalues = {}

	for i = 0, table.getn(transitData.transports), 1 do
		dropdownindex[transitData.transports[i].label] = i

		local textdesc
		if (nautSavedVars.config.CityAlias) then
			if (nautSavedVars.knownTimes[transitData.transports[i].label]) then
				textdesc = GREEN..transitData.transports[i].namealias
			else
				textdesc = transitData.transports[i].namealias
			end
		else
			if (nautSavedVars.knownTimes[transitData.transports[i].label]) then
				textdesc = GREEN..transitData.transports[i].name
			else
				textdesc = transitData.transports[i].name
			end
		end

		info = {
			text = textdesc;
			func = Naut_TransportSelect_OnClick;
		}

		local addtrans = false
		if (nautSavedVars.config.FactionSpecific) then
			local faction = UnitFactionGroup("player")

			if ((transitData.transports[i].faction == faction) or (transitData.transports[i].faction == "Neutral")) then
				addtrans = true
			end
		else
			addtrans = true
		end

		if (nautSavedVars.config.ZoneSpecific and (addtrans)) then
			local zonestr = string.lower(transitData.transports[i].name)
			local czonestr = string.lower(GetRealZoneText())
			if (not string.find(zonestr, czonestr)) then
				addtrans = false
			end
		end

		if ((addtrans) or (transitData.transports[i].faction == -1)) then
			UIDropDownMenu_AddButton(info)
			table.insert(dropdownvalues, transitData.transports[i].label)
		end
	end

end

function Naut_TransportSelect_PreInitialize()
	local info

	info = {
		text = 'loading variables';
		func = Naut_TransportSelect_OnClick;
	}
	UIDropDownMenu_AddButton(info)
end

function Naut_TransportSelect_OnShow()

	if (vars_loaded) then
		Naut_TransportSelect_OnLoaded()
		UIDropDownMenu_SetWidth(162)
		return
	end

	UIDropDownMenu_ClearAll(NautFrameTransportSelect)
	UIDropDownMenu_Initialize(NautFrameTransportSelect, Naut_TransportSelect_PreInitialize)
	UIDropDownMenu_SetSelectedID(NautFrameTransportSelect, 1)
	UIDropDownMenu_SetWidth(162)
end

function Naut_TransportSelect_OnLoaded()
	UIDropDownMenu_ClearAll(NautFrameTransportSelect)
	UIDropDownMenu_Initialize(NautFrameTransportSelect, Naut_TransportSelect_Initialize)
	UIDropDownMenu_SetSelectedID(NautFrameTransportSelect, Nauticus.activeSelect)
end

function Naut_TransportSelect_OnClick()
	-- cannot change selection while data request is in process
	if (req_timeout ~= nil) then return end

	local i = this:GetID()
	UIDropDownMenu_SetSelectedID(NautFrameTransportSelect, i)
	Nauticus.activeTransit = dropdownvalues[i]
	Nauticus.activeSelect = i

	if (nautSavedVars.config.CityAlias) then
		Nauticus.activeTransitName = transitData.transports[dropdownindex[Nauticus.activeTransit] ].namealias
	else
		Nauticus.activeTransitName = transitData.transports[dropdownindex[Nauticus.activeTransit] ].name
	end

	if (nautSavedVars.knownTimes[Nauticus.activeTransit] == nil) then
		Naut_SendMessage("REQ "..Nauticus.activeTransit)
	end

	Naut_TransportSelect_SetNone()
end

function Naut_TransportSelect_SetNone()

	if (Nauticus.activeTransit == -1) then
		if (debug) then
			Naut_DebugMessage("_OnClick - no transit")
		end

		for index = 1, 2 do
			getglobal("NautFramePlat"..(index).."Name"):SetText(L["NONESELECT"])
			getglobal("NautFramePlat"..(index).."ArrivalDepature"):SetText("-- N/A --")
		end

		Nauticus.lowestNameTime = "--"
		Nauticus.icon = "NauticusLogo"

	elseif (nautSavedVars.knownTimes[Nauticus.activeTransit] == nil) then
		local transit = Nauticus.activeTransit

		if (debug) then
			Naut_DebugMessage("_OnClick - unknown transit: "..transit)
		end

		for index, data in pairs(transitData[transit..'_plats']) do
			local platname

			if (nautSavedVars.config.CityAlias) then
				platname = data.alias
			else
				platname = data.name
			end

			getglobal("NautFramePlat"..(index+1).."Name"):SetText(platname)
			getglobal("NautFramePlat"..(index+1).."ArrivalDepature"):SetText("-- N/A --")
		end

		Nauticus.lowestNameTime = "N/A"
		Nauticus.icon = "NauticusLogo"

	else
		lastIndex = 1

	end

end

function Naut_TransportRequestData(transport)
	Naut_SendMessage("REQ "..transport)

	if (debug) then
		Naut_DebugMessage("Data requested for transport ".. transport)
	end
end

function Naut_Minimize_OnClick()
	nautSavedVarsPC.config.ShowLowerGUI = not nautSavedVarsPC.config.ShowLowerGUI
	Naut_UpdateUI()
end

function Naut_UpdateUI()

	if nautSavedVarsPC.config.ShowLowerGUI then
		NautHeaderFrame:SetWidth(210)
		NautHeaderFrameAddonName:Show()
		NautHeaderFrameOptionsButton:Show()
		NautFrame:Show()
		NautHeaderFrameMinimizeButton:SetNormalTexture("Interface\\Buttons\\UI-MinusButton-UP")
		NautHeaderFrameMinimizeButton:SetPushedTexture("Interface\\Buttons\\UI-MinusButton-DOWN")

		local _, centre = NautHeaderFrame:GetCenter()
		NautFrame:ClearAllPoints()
		if centre < (GetScreenHeight()/2) then
			NautFrame:SetPoint("BOTTOM", NautHeaderFrame, "TOP", 0, -5)
		else
			NautFrame:SetPoint("TOP", NautHeaderFrame, "BOTTOM", 0, 5)
		end

	else
		NautFrame:Hide()
		NautHeaderFrameMinimizeButton:SetNormalTexture("Interface\\Buttons\\UI-PlusButton-UP")
		NautHeaderFrameMinimizeButton:SetPushedTexture("Interface\\Buttons\\UI-PlusButton-DOWN")
		NautHeaderFrameOptionsButton:Hide()
		NautHeaderFrameAddonName:Hide()

		-- initialise anchor
		local right = NautHeaderFrame:GetRight()
		local top = NautHeaderFrame:GetTop()

		if ((top ~= nil) and (right ~= nil)) then
			NautHeaderFrame:ClearAllPoints()
			NautHeaderFrame:SetPoint("TOPRIGHT", UIParent, "BOTTOMLEFT", right, top)
		end

		NautHeaderFrame:SetWidth(64)
	end

end

function Naut_Close_OnClick()
	NautHeaderFrame:Hide()
	nautSavedVarsPC.config.ShowGUI = false
	DEFAULT_CHAT_FRAME:AddMessage(YELLOW.. "Nauticus -- GUI Closed! ("..GREEN.."Type /naut to show again"..YELLOW..")")
end

function Naut_Options_OnClick()

	if ( not NautOptionsFrame:IsVisible() ) then
		NautOptionsFrame:Show()
	else
		NautOptionsFrame:Hide()
	end

end

function Naut_OptionsSave_OnClick()

	nautSavedVars.config.ZoneGUI = NautOptionsFrameOptZoneGUI:GetChecked()
	nautSavedVars.config.FactionSpecific = NautOptionsFrameOptFactionSpecific:GetChecked()
	nautSavedVars.config.ZoneSpecific = NautOptionsFrameOptZoneSpecific:GetChecked()
	nautSavedVars.config.CityAlias = NautOptionsFrameOptCityAlias:GetChecked()

	-- refresh dropdown with current options applied
	Naut_TransportSelect_OnLoaded()
	NautOptionsFrame:Hide()

end

function Naut_OptionsClose_OnClick()

	if (nautSavedVars.config.ZoneGUI) then
		NautOptionsFrameOptZoneGUI:SetChecked()
	end
	if (nautSavedVars.config.FactionSpecific) then
		NautOptionsFrameOptFactionSpecific:SetChecked()
	end
	if (nautSavedVars.config.ZoneSpecific) then
		NautOptionsFrameOptZoneSpecific:SetChecked()
	end
	if (nautSavedVars.config.CityAlias) then
		NautOptionsFrameOptCityAlias:SetChecked()
	end
	NautOptionsFrame:Hide()

end

local function Nauticus_InitialiseConfig()

	vars_loaded = true

	-- initialize saved variables
	if (nautSavedVars == nil) then
		nautSavedVars = {}
		nautSavedVars.knownTimes = {}
		nautSavedVars.timestamps = {}
	end

	local savedVars = nautSavedVars

	if (nautSavedVarsPC == nil) then
		nautSavedVarsPC = {}
	end

	local savedVarsPC = nautSavedVarsPC

	if (savedVars.config == nil) then
		savedVars.config = {}
		savedVars.config.ZoneGUI = false
		savedVars.config.FactionSpecific = true
		savedVars.config.ZoneSpecific = false
		savedVars.config.CityAlias = true
	end

	local cfg = savedVars.config

	if (savedVarsPC.config == nil) then
		savedVarsPC.config = {}
	end

	local cfgPC = savedVarsPC.config

	if (cfg.dataChannel == nil) then
		cfg.dataChannel = dataChannel
	end
	--[[if (savedVars.protoVersion == nil) then
		savedVars.protoVersion = protoVersion
	end
	if (savedVars.protoVersion ~= protoVersion) then
		-- if protocol is different, reset data
		savedVars.knownTimes = {}
		savedVars.protoVersion = protoVersion

		if (debug) then
			Naut_DebugMessage(YELLOW.. "Nauticus - DEBUG - ".. RED .."Protocol changed, data reset!!")
		end
	end]]

	if (cfgPC.ShowGUI == nil) then
		cfgPC.ShowGUI = true
	end

	if (cfgPC.ShowLowerGUI == nil) then
		cfgPC.ShowLowerGUI = true
	end

	-- set GUI options
	if (cfg.ZoneGUI) then
		NautOptionsFrameOptZoneGUI:SetChecked()
	end
	if (cfg.FactionSpecific) then
		NautOptionsFrameOptFactionSpecific:SetChecked()
	end
	if (cfg.ZoneSpecific) then
		NautOptionsFrameOptZoneSpecific:SetChecked()
	end
	if (cfg.CityAlias) then
		NautOptionsFrameOptCityAlias:SetChecked()
	end

	Naut_TransportSelect_OnLoaded()

	dataChannel = cfg.dataChannel

	if (cfgPC.ShowLowerGUI) then
		NautFrame:Show()
	else
		NautFrame:Hide()
	end

	if (cfgPC.ShowGUI) then
		NautHeaderFrame:Show()
	else
		NautHeaderFrame:Hide()
	end

	if ((savedVars.agedTimestamp ~= nil) and (savedVars.agedTimestamp > time())) then
		savedVars.agedTimestamp = time()
		--DEFAULT_CHAT_FRAME:AddMessage("Nauticus: Aged timestamp was too old, setting oldest timestamp to current system time.");
	end

	NautHeaderFrameAddonName:SetText("Nauticus v"..nautVersion);
	NautOptionsFrameOptionsTitle:SetText("Nauticus Options (v"..nautVersion..")")
	DEFAULT_CHAT_FRAME:AddMessage(YELLOW.. "Nauticus v"..nautVersion.." -- Loaded. (type /nauticus to toggle interface)")

	if (savedVars.knownTimes.uptime ~= nil) and ( savedVars.knownTimes.uptime > GetTime() ) then
		-- since uptime is less than last known zep time, reset must have occured
		-- clear known times
		savedVars.knownTimes = {}
		savedVars.knownTimes.uptime = GetTime()

		--DEFAULT_CHAT_FRAME:AddMessage(YELLOW.. "Nauticus -- ".. RED .."Sync Data Out-Of-Date ... Data Reset!");
	end

end

function Naut_SendMessage(msg)
	SendChatMessage(msg, "CHANNEL", nil, GetChannelName(dataChannel) )
end

function Naut_ParseMessage(arg1, arg2)

	local Args = Naut_GetArgs(arg1, " ")
	local numArgs = table.getn(Args)

	if (numArgs <= 1) then return end

	local command = Args[1]
	--[[local version = Args[2]

	if (tonumber(protoVersion) < tonumber(version)) and (not newVerAvail) then
		newVerAvail = true
		DEFAULT_CHAT_FRAME:AddMessage(YELLOW.."Nauticus ::"..RED.." "..L["NEWVERSION"])
		return
	end]]

	if command == "REQVER" then
		-- if our client was around for a server shutdown or restart,
		-- let other clients know data before this date is out-of-date
		if (nautSavedVars.agedTimestamp ~= nil) then
			Naut_SendMessage("DATED "..nautSavedVars.agedTimestamp)
		end

		Naut_SendMessage("VER "..nautVersionNum)

	elseif command == "VER" then
		local clientversion = Args[2]

		if ((tonumber(nautVersionNum) < tonumber(clientversion)) and (not newVerAvail)) then
			newVerAvail = true
			DEFAULT_CHAT_FRAME:AddMessage(YELLOW.."Nauticus ::"..RED.." "..L["NEWVERSION"])
			return
		end

	-- DATED:ver:timestamp
	elseif command == "DATED" then
		local dated_timestamp = tonumber(Args[2])
		if ((nautSavedVars.agedTimestamp ~= nil) and (nautSavedVars.agedTimestamp < dated_timestamp) and (dated_timestamp < time()))  then
			nautSavedVars.agedTimestamp = dated_timestamp
		elseif ((nautSavedVars.agedTimestamp == nil) and (dated_timestamp < time())) then
			nautSavedVars.agedTimestamp = dated_timestamp
		end

		-- check to see any of this clients data is older than last aged timestamp
		-- if so clear it
		for transport, time in pairs(nautSavedVars.knownTimes) do
			if ( (nautSavedVars.timestamps[transport] ~= nil) and
				(nautSavedVars.agedTimestamp ~= nil) and
				(nautSavedVars.timestamps[transport] < nautSavedVars.agedTimestamp)) then

				nautSavedVars.knownTimes[transport] = nil
				nautSavedVars.timestamps[transport] = nil

				if (debug) then
					Naut_DebugMessage(transport.." timestamp is too old, removing.")
				end
			end
		end

	-- KNOWN:ver:transit:index
	elseif command == "KNOW" then
		local transit = Args[2]
		local value = tonumber(Args[3])
		local timestamp = tonumber(Args[4])

		nautSavedVars.knownTimes[transit] = GetTime() - value --sum_time
		nautSavedVars.timestamps[transit] = timestamp --time()

		if (debug) then
			Naut_DebugMessage(RED.."Zep Time Broadcast Received from "..arg2.." - "
				..transit.." Zep Time Set: "..nautSavedVars.knownTimes[transit])
		end

	-- REQ:ver:transit
	elseif command == "REQ" then
		local transit = Args[2]

		if (debug) then
			Naut_DebugMessage(arg2.." requested ".. transit)
		end

		--NOTE: cycle+timestamp = bad, want: timestamp-(time()-(GetTime()-knowntime))?
		if (nautSavedVars.knownTimes[transit] ~= nil) then
			local cycle = Naut_CalcTripCycle(transit)

			Naut_SendMessage("RESP "..transit.." "
				..(math.floor(cycle*1000)/1000).." "..nautSavedVars.timestamps[transit])
		end

	-- RESP:ver:transit:time:timestamp
	elseif command == "RESP" then
		local transit = Args[2]
		local time = tonumber(Args[3])
		local timestamp = tonumber(Args[4])

		if (nautSavedVars.knownTimes[transit] == nil) then
			req_timeout = 1
			if (knownTimesReq[arg2] == nil) then
				knownTimesReq[arg2] = {}
			end
			knownTimesReq[arg2][transit] = {}
			knownTimesReq[arg2][transit].timestamp = timestamp
			knownTimesReq[arg2][transit].time = GetTime() - time

			if (debug) then
				Naut_DebugMessage(RED.."Zep Time Broadcast Received from "..arg2.." - "
					..transit.." Zep Time Set: "..knownTimesReq[arg2][transit].time)
			end
		end

		Nauticus.tempText = RED.."Receiving Data.."
		Nauticus.tempTextCount = 2

	end

end

function Nauticus:OnEvent(event)

	if (event == "VARIABLES_LOADED") then
		Nauticus_InitialiseConfig()

	elseif (event == "PLAYER_LOGIN") then
		if not nautSavedVarsPC.config.ShowLowerGUI then
			-- initialise anchor
			local right = NautHeaderFrame:GetRight()
			local top = NautHeaderFrame:GetTop()
	
			if (top ~= nil) and (right ~= nil) then
				NautHeaderFrame:SetPoint("TOPRIGHT", UIParent, "BOTTOMLEFT", right-146, top)
			end
		end
		Naut_TransportSelect_SetNone()
		Naut_UpdateUI()

	elseif (event == "CHAT_MSG_SYSTEM") then
		-- server is going down. clear zep times, also record down time server went down so we can inform
		-- other clients that their data is out of date if their data timestamp is less than server reset
		if (string.find(string.lower(arg1), "restart in") or
			string.find(string.lower(arg1), "shutdown in")) then

			nautSavedVars.knownTimes = {}
			nautSavedVars.agedTimestamp = time()
		end

	-- if we joined a channel
	elseif (event == "CHAT_MSG_CHANNEL_NOTICE") then
		-- automatically join data channel
		JoinChannelByName(dataChannel)

		if (arg9 == dataChannel) then
			Naut_SendMessage("REQVER "..nautVersionNum)

			-- transmit all our known data when someone joins a channel
			for index, data in pairs(transitData.transports) do
				if ( (data.label ~= -1) and (nautSavedVars.knownTimes[data.label] == nil) ) then
					Naut_TransportRequestData(data.label)
				end
			end
		end

	elseif (event == "CHAT_MSG_CHANNEL") and (arg9 == dataChannel) and (arg2 ~= UnitName("player")) then
		Naut_ParseMessage(arg1, arg2)

	elseif (event == "ZONE_CHANGED_NEW_AREA") then

		-- show GUI when zone change contains a transport
		if (not nautSavedVars.config.ZoneGUI) then return end

		-- open GUI if entering zone with transport
		for index, zone_data in pairs(transitData.transports) do
			if (zone_data.label ~= -1) then
				local plat_data = transitData[zone_data.label..'_plats']
				if (plat_data ~= nil) then
					for index, trans_data in pairs(plat_data) do
						if trans_data.name == GetRealZoneText() then
							NautHeaderFrame:Show()
							NautFrame:Show()
						end
					end
				end
			end
		end

	end

end

function Naut_ToggleAlarm()
	alarmSet = not alarmSet
	if not alarmSet then alarmDinged = false end
	local is
	if alarmSet then is = RED.."ON|r" else is = GREEN.."OFF|r" end
	DEFAULT_CHAT_FRAME:AddMessage(YELLOW.."Nauticus - Alarm is now: "..is)
	PlaySound("AuctionWindowOpen")
end

function Naut_IsAlarmSet()
	return alarmSet or alarmDinged
end

function Naut_SlashCommandHandler(msg)

	local msgArgs
	local numArgs

	--msg = string.lower(msg);
	msgArgs = Naut_GetArgs(msg, " ")
	if msgArgs[1] then
		msgArgs[1] = string.lower(msgArgs[1])
	end

	numArgs = table.getn(msgArgs)

	if (numArgs == 0) then
		DEFAULT_CHAT_FRAME:AddMessage(YELLOW.."Nauticus - Display GUI")
		NautHeaderFrame:Show()
		nautSavedVarsPC.config.ShowGUI = true

	elseif (numArgs == 1) then

		if (msgArgs[1] == "reset") then
			DEFAULT_CHAT_FRAME:AddMessage(RED.."Nauticus - Session Reset!")
			nautSavedVars.knownTimes = {}
		end

	elseif (numArgs == 2) then

		if (msgArgs[1] == "channel") then
			LeaveChannelByName(dataChannel)
			nautSavedVars.config.dataChannel = msgArgs[2]
			dataChannel = nautSavedVars.config.dataChannel
			JoinChannelByName(dataChannel)
			DEFAULT_CHAT_FRAME:AddMessage(YELLOW.."Nauticus - Data channel set to ["..dataChannel.."]")
		end

	end

end

-- extract key/value from message
function Naut_GetArgs(message, separator)

	local args = {}
	local i = 0

	-- search for seperators in the string and return the separated data
	for value in string.gmatch(message, "[^"..separator.."]+") do
		i = i + 1
		args[i] = value
	end

	return args
end

function Naut_DebugMessage(msg)
	ChatFrame4:AddMessage("[Naut]: "..msg)
end
