
local XANORDH = select(2, ...) --grab the addon namespace
XANORDH = LibStub("AceAddon-3.0"):NewAddon(XANORDH, "xanOrderHalls", "AceEvent-3.0", "AceConsole-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("xanOrderHalls", true)
local AceGUI = LibStub("AceGUI-3.0")

local dbglobal
local dbplayer
local realmN
local playerN
local playerClass
local playerLevel
local playerFaction
local _GarrisonLandingPageTab_SetTab

local debugf = tekDebug and tekDebug:GetFrame("xanOrderHalls")

function XANORDH:Debug(...)
    if debugf then debugf:AddMessage(string.join(", ", tostringall(...))) end
end

function XANORDH:setupDB()
	realmN = GetRealmName()
	playerN = UnitName("player")
	playerFaction = UnitFactionGroup("player")
	playerClass =  select(2, UnitClass("player"))
	playerLevel = UnitLevel("player")
	
	if not XOH_DB then XOH_DB = {} end
	
	dbglobal = XOH_DB
	dbglobal[realmN] = dbglobal[realmN] or {}
	dbglobal[realmN][playerN] = dbglobal[realmN][playerN] or {}
	dbplayer = dbglobal[realmN][playerN]
	
	if not dbplayer.class then dbplayer.class = playerClass end
	if not dbplayer.faction then dbplayer.faction = playerFaction end
	if not dbplayer.level then dbplayer.level = playerLevel end
	if not dbplayer.info then dbplayer.info = {} end
	
end

function XANORDH:ShowCharList()
	if not self.CHListFrame then return end

	if not _GarrisonLandingPageTab_SetTab then
		_GarrisonLandingPageTab_SetTab = GarrisonLandingPageTab_SetTab
	end
	if GarrisonLandingPage and not GarrisonLandingPage:IsShown() then
		ShowGarrisonLandingPage()
	end
	_GarrisonLandingPageTab_SetTab(GarrisonLandingPageTab1)
	GarrisonLandingPageReport:Hide()
	self.CHListFrame:Show()
	GarrisonLandingPage.selectedTab = 10
	PanelTemplates_SelectTab(self.CHListFrame.Tab)
	PanelTemplates_DeselectTab(GarrisonLandingPageTab1)
	
	--update the data and then force a display of the character list
	XANORDH:Delay("getCurrentPlayerData", 0.5, function() XANORDH:getCurrentPlayerData(true) end)
end

function XANORDH:getCurrentPlayerData(forceDisplay)
	if not self.CHListFrame then return end

	dbplayer.info = {} --reset it, clear out old data
	
	--https://github.com/tomrus88/BlizzardInterfaceCode/blob/master/Interface/AddOns/Blizzard_OrderHallUI/Blizzard_OrderHallTalents.lua
	
	local primaryCurrency, _ = C_Garrison.GetCurrencyTypes(LE_GARRISON_TYPE_7_0)
	local currencyName, amount, currencyTexture = GetCurrencyInfo(primaryCurrency)
	dbplayer.info.currency = { ["name"]=currencyName, ["amount"]=amount, ["currencyTexture"]=currencyTexture }
	
	local championCount = C_Garrison.GetNumFollowers(LE_FOLLOWER_TYPE_GARRISON_7_0)
	dbplayer.info.championCount = championCount
	
	local followerShipments = C_Garrison.GetFollowerShipments(LE_GARRISON_TYPE_7_0)
	dbplayer.info.followers = {}
	for i = 1, #followerShipments do
		local name, texture, shipmentCapacity, shipmentsReady, shipmentsTotal, creationTime, duration, timeleftString, _, _, _, _, followerID = C_Garrison.GetLandingPageShipmentInfoByContainerID(followerShipments[i])
		if ( name ) then
			dbplayer.info.followers[i] = {
				["name"] = name,
				["shipmentCapacity"] = shipmentCapacity,
				["shipmentsReady"] = shipmentsReady,
				["shipmentsTotal"] = shipmentsTotal,
				["creationTime"] = creationTime,
				["duration"] = duration,
				["timeleftString"] = timeleftString,
				["followerID"] = followerID,
				["texture"] = texture,
			}
		end
	end
	
	local looseShipments = C_Garrison.GetLooseShipments(LE_GARRISON_TYPE_7_0)
	dbplayer.info.shipments = {}
	if (looseShipments) then
		for i = 1, #looseShipments do
			local name, texture, shipmentCapacity, shipmentsReady, shipmentsTotal, creationTime, duration, timeleftString, _, _, _, _, followerID = C_Garrison.GetLandingPageShipmentInfoByContainerID(looseShipments[i])
			if ( name ) then
				dbplayer.info.shipments[i] = {
					["name"] = name,
					["shipmentsReady"] = shipmentsReady,
					["shipmentsTotal"] = shipmentsTotal,
					["creationTime"] = creationTime,
					["duration"] = duration,
					["timeleftString"] = timeleftString,
					["texture"] = texture,
				}
			end
		end
	end

	local iCount = 0
	local talentTrees = C_Garrison.GetTalentTrees(LE_GARRISON_TYPE_7_0, select(3, UnitClass("player")))
	dbplayer.info.talents = {}
	if (talentTrees) then
		local completeTalentID = C_Garrison.GetCompleteTalent(LE_GARRISON_TYPE_7_0)
		for treeIndex, tree in ipairs(talentTrees) do
			for talentIndex, talent in ipairs(tree) do
				local showTalent = false
				if (talent.isBeingResearched) then
					showTalent = true
				end
				if (talent.id == completeTalentID) then
					showTalent = true
				end
				if (showTalent) then
					iCount = iCount + 1
					dbplayer.info.talents[iCount] = {
						["name"] = talent.name,
						["isBeingResearched"] = talent.isBeingResearched,
						["researchStartTime"] = talent.researchStartTime,
						["researchDuration"] = talent.researchDuration,
						["timeleftString"] = SecondsToTime(talent.researchDuration),
						["texture"] = talent.icon,
					}
				end
			end
		end
	end

	--https://github.com/tomrus88/BlizzardInterfaceCode/blob/master/Interface/AddOns/Blizzard_AdventureMap/AM_ZoneSummaryDataProvider.lua
	if not dbplayer.info.missions then dbplayer.info.missions = {} end
	local currentMissions = C_Garrison.GetAvailableMissions(LE_FOLLOWER_TYPE_GARRISON_7_0)

	local iCount = 0
	dbplayer.info.missions.currentMissions = {}
	if currentMissions then
		for i, missionInfo in pairs(currentMissions) do
			iCount = iCount + 1
			dbplayer.info.missions.currentMissions[iCount] = {
				["name"] = missionInfo.name,
				["missionID"] = missionInfo.missionID,
				["completed"] = missionInfo.completed,
				["inProgress"] = missionInfo.inProgress,
				["missionEndTime"] = missionInfo.missionEndTime,
				["durationSeconds"] = missionInfo.durationSeconds,
				["offerTimeRemaining"] = missionInfo.offerTimeRemaining,
				["offerEndTime"] = missionInfo.offerEndTime,
				["duration"] = missionInfo.duration,
				["typeAtlas"] = missionInfo.typeAtlas,
			}
		end
	end

	local inProgressMissions = C_Garrison.GetInProgressMissions(LE_FOLLOWER_TYPE_GARRISON_7_0)
	local iCount = 0
	dbplayer.info.missions.inProgress = {}
	if inProgressMissions then
		for i, missionInfo in pairs(inProgressMissions) do
			iCount = iCount + 1
			dbplayer.info.missions.inProgress[iCount] = {
				["name"] = missionInfo.name,
				["missionID"] = missionInfo.missionID,
				["completed"] = missionInfo.completed,
				["inProgress"] = missionInfo.inProgress,
				["missionEndTime"] = missionInfo.missionEndTime,
				["durationSeconds"] = missionInfo.durationSeconds,
				["offerTimeRemaining"] = missionInfo.offerTimeRemaining,
				["timeLeft"] = missionInfo.timeLeft,
				["duration"] = missionInfo.duration,
				["timeLeftSeconds"] = missionInfo.timeLeftSeconds,
				["timeleftString"] = SecondsToTime(missionInfo.timeLeftSeconds),
				["typeAtlas"] = missionInfo.typeAtlas,
			}
		end
	end
	
	if forceDisplay then
		XANORDH:displayList()
	end
end

local function rgbhex(r, g, b)
	if type(r) == "table" then
		if r.r then
			r, g, b = r.r, r.g, r.b
		else
			r, g, b = unpack(r)
		end
	end
	return string.format("|cff%02x%02x%02x", (r or 1) * 255, (g or 1) * 255, (b or 1) * 255)
end

local function getClassColor(sName, sClass)
	if sName ~= "Unknown" and sClass and RAID_CLASS_COLORS[sClass] then
		return rgbhex(RAID_CLASS_COLORS[sClass])..sName.."|r"
	end
	return sName
end

function XANORDH:displayList()
	if not self.CHListFrame then return end
	if not self.CHListFrame:IsShown() then return end

	self.CHListFrame.scrollframe:ReleaseChildren() --clear out the scrollframe
	
	local function Swipe_OnEnter(self)
		if self.TooltipMSG then
			GameTooltip:SetOwner(self, "ANCHOR_LEFT")
			GameTooltip:SetText(self.TooltipTitle)
			GameTooltip:AddLine(GREEN_FONT_COLOR_CODE..self.TooltipType.."|r")
			if self.isComplete then
				if self.TooltipMSG3 then
					GameTooltip:AddLine(self.TooltipMSG3)
				end
				GameTooltip:AddLine(ORANGE_FONT_COLOR_CODE..L.ReadyPickup.."|r")
			else
				GameTooltip:AddLine(self.TooltipMSG)
				if self.TooltipMSG2 then
					GameTooltip:AddLine(self.TooltipMSG2)
				end
			end
			GameTooltip:Show()
		end
	end
	local function Swipe_OnLeave(self)
		if GameTooltip:IsOwned(self) then
			GameTooltip:Hide()
		end
	end
	local function Swipe_OnDone(self)
		self:GetParent().AltDone:Show()
		if not self:GetParent().ShowCountOnComplete then
			self:GetParent().Count:SetText(nil)
		end
		self.isComplete = true
	end
	
	local displayTimers = {}
	
	for realm, rd in pairs(dbglobal) do
		for k, v in pairs(rd) do
		
			local allowPass = false
			local iCount = 0
			local showPlayer = false
			local playerName = getClassColor(k or "Unknown", v.class)
			local summary = realm
			
			--only work with characters that have at least one champion unlocked.  Otherwise they don't have the order hall stuff unlocked yet
			if v.info.championCount and v.info.championCount > 0 then
				allowPass = true
			end
			
			if allowPass then
				
				local label = AceGUI:Create("xanOrderHallsButton")
				label:SetName(playerName)
				label.playerName = k --for sorting
				
				if v.info.currency then
					summary = summary.."  "..GREEN_FONT_COLOR_CODE..">|r  "..format([[|T%s:0|t]], v.info.currency.currencyTexture).." "..v.info.currency.amount
					showPlayer = true
				end
				
				label:SetSummary(summary)
				
				--hide all the timers just in case
				for i = 1, #label.timers do
					label.timers[i]:Hide()
				end
				
				--now lets do the timers
				-->>>Followers (unit squads and such)
				if v.info.followers then
					for i = 1, #v.info.followers do
						iCount = iCount + 1
						label.timers[iCount].AltDone:Hide()
						label.timers[iCount].isComplete = false
						label.timers[iCount]:SetScript("OnEnter", Swipe_OnEnter)
						label.timers[iCount]:SetScript("OnLeave", Swipe_OnLeave)
						label.timers[iCount].Swipe:SetScript("OnCooldownDone", Swipe_OnDone)
						label.timers[iCount].Icon:SetTexture(v.info.followers[i].texture) --SetPortraitToTexture doesn't work with Followers
						label.timers[iCount].Icon:SetDesaturated(true)
						label.timers[iCount]:Show()
						
						local readyCount = v.info.followers[i].shipmentsReady or 0
						local totalCount = v.info.followers[i].shipmentsTotal or 0
						local duration = v.info.followers[i].duration or 0
						local creationTime = v.info.followers[i].creationTime or 0
						local timeLeft = (creationTime + duration) - GetServerTime()
						if timeLeft < 0 then timeLeft = 0 end
						
						label.timers[iCount].ShowCountOnComplete = false
						label.timers[iCount].Count:SetFormattedText(GARRISON_LANDING_SHIPMENT_COUNT, readyCount, totalCount)
						label.timers[iCount].TooltipTitle = v.info.followers[i].name or nil
						label.timers[iCount].TooltipMSG = "|cFFFFFFFF"..TIME_REMAINING.."|r "..tostring(SecondsToTime(timeLeft))
						label.timers[iCount].TooltipMSG2 = format(GARRISON_LANDING_COMPLETED, readyCount, totalCount)
						label.timers[iCount].TooltipMSG3 = nil
						label.timers[iCount].TooltipType = L.Troops
						label.timers[iCount].Swipe:SetCooldownUNIX(creationTime, duration)
						
						if readyCount == totalCount or ( GetServerTime() >= (creationTime + duration) ) then
							label.timers[iCount].AltDone:Show()
							label.timers[iCount].isComplete = true
							label.timers[iCount].Count:SetText(nil)
						else
							label.timers[iCount].AltDone:Hide()
						end
						showPlayer = true
					end
				end
				
				-->>>Shipments
				if v.info.shipments then
					for i = 1, #v.info.shipments do
						iCount = iCount + 1
						label.timers[iCount].AltDone:Hide()
						label.timers[iCount].isComplete = false
						label.timers[iCount]:SetScript("OnEnter", Swipe_OnEnter)
						label.timers[iCount]:SetScript("OnLeave", Swipe_OnLeave)
						label.timers[iCount].Swipe:SetScript("OnCooldownDone", Swipe_OnDone)
						SetPortraitToTexture(label.timers[iCount].Icon, v.info.shipments[i].texture)
						label.timers[iCount].Icon:SetDesaturated(true)
						label.timers[iCount]:Show()
						
						local readyCount = v.info.shipments[i].shipmentsReady or 0
						local totalCount = v.info.shipments[i].shipmentsTotal or 0
						local duration = v.info.shipments[i].duration or 0
						local creationTime = v.info.shipments[i].creationTime or 0
						local timeLeft = (creationTime + duration) - GetServerTime()
						if timeLeft < 0 then timeLeft = 0 end
						
						label.timers[iCount].ShowCountOnComplete = false
						label.timers[iCount].Count:SetFormattedText(GARRISON_LANDING_SHIPMENT_COUNT, readyCount, totalCount)
						label.timers[iCount].TooltipTitle = v.info.shipments[i].name or nil
						label.timers[iCount].TooltipMSG = "|cFFFFFFFF"..TIME_REMAINING.."|r "..tostring(SecondsToTime(timeLeft))
						label.timers[iCount].TooltipMSG2 = format(GARRISON_LANDING_COMPLETED, readyCount, totalCount)
						label.timers[iCount].TooltipMSG3 = nil
						label.timers[iCount].TooltipType = L.Shipment
						label.timers[iCount].Swipe:SetCooldownUNIX(creationTime, duration)
						
						if readyCount == totalCount or ( GetServerTime() >= (creationTime + duration) ) then
							label.timers[iCount].AltDone:Show()
							label.timers[iCount].isComplete = true
							label.timers[iCount].Count:SetText(nil)
						else
							label.timers[iCount].AltDone:Hide()
						end
						showPlayer = true
					end
				end
				
				-->>>Talents
				if v.info.talents then
					for i = 1, #v.info.talents do
						iCount = iCount + 1
						label.timers[iCount].AltDone:Hide()
						label.timers[iCount].isComplete = false
						label.timers[iCount]:SetScript("OnEnter", Swipe_OnEnter)
						label.timers[iCount]:SetScript("OnLeave", Swipe_OnLeave)
						label.timers[iCount].Swipe:SetScript("OnCooldownDone", Swipe_OnDone)
						SetPortraitToTexture(label.timers[iCount].Icon, v.info.talents[i].texture)
						label.timers[iCount].Icon:SetDesaturated(true)
						label.timers[iCount]:Show()
						
						local duration = v.info.talents[i].researchDuration or 0
						local creationTime = v.info.talents[i].researchStartTime or 0
						local timeLeft = (creationTime + duration) - GetServerTime()
						if timeLeft < 0 then timeLeft = 0 end
						
						label.timers[iCount].ShowCountOnComplete = false
						label.timers[iCount].Count:SetText(nil)
						label.timers[iCount].TooltipTitle = v.info.talents[i].name or nil
						label.timers[iCount].TooltipMSG = "|cFFFFFFFF"..TIME_REMAINING.."|r "..tostring(SecondsToTime(timeLeft))
						label.timers[iCount].TooltipMSG2 = nil
						label.timers[iCount].TooltipMSG3 = nil
						label.timers[iCount].TooltipType = L.Talent
						label.timers[iCount].Swipe:SetCooldownUNIX(creationTime, duration)
						
						if ( GetServerTime() >= (creationTime + duration) ) then
							label.timers[iCount].AltDone:Show()
							label.timers[iCount].isComplete = true
							label.timers[iCount].Count:SetText(nil)
							label.timers[iCount].TooltipMSG2 = format(GARRISON_LANDING_COMPLETED, 1, 1)
						else
							label.timers[iCount].AltDone:Hide()
						end
						showPlayer = true
					end
				end

				-->>>In Progress Missions
				if v.info.missions.inProgress then
					local missionCount = 0
					local missionCompleted = 0
					local ceilMissionTime = 0
					local ceilMissionTimeDuration = 0
					
					for i = 1, #v.info.missions.inProgress do
						if v.info.missions.inProgress[i].name then
							missionCount = missionCount + 1
							
							if v.info.missions.inProgress[i].missionEndTime then
								if v.info.missions.inProgress[i].missionEndTime > ceilMissionTime then
									ceilMissionTime = v.info.missions.inProgress[i].missionEndTime
									ceilMissionTimeDuration = v.info.missions.inProgress[i].durationSeconds
								end
								if v.info.missions.inProgress[i].missionEndTime <= GetServerTime() then
									missionCompleted = missionCompleted + 1
								end
							end
						end
					end
					if missionCount > 0 then
						iCount = iCount + 1
						label.timers[iCount].AltDone:Hide()
						label.timers[iCount].isComplete = false
						label.timers[iCount]:SetScript("OnEnter", Swipe_OnEnter)
						label.timers[iCount]:SetScript("OnLeave", Swipe_OnLeave)
						label.timers[iCount].Swipe:SetScript("OnCooldownDone", Swipe_OnDone)
						label.timers[iCount].Icon:SetAtlas("ClassHall-CombatIcon-Desaturated")
						label.timers[iCount].Icon:SetDesaturated(false)
						label.timers[iCount]:Show()
						
						local duration = ceilMissionTimeDuration
						local creationTime = ceilMissionTime - ceilMissionTimeDuration
						
						label.timers[iCount].ShowCountOnComplete = true
						label.timers[iCount].Count:SetFormattedText(GARRISON_LANDING_SHIPMENT_COUNT, missionCompleted, missionCount)
						label.timers[iCount].TooltipTitle = L.MissionsInProgress
						label.timers[iCount].TooltipMSG = L.TotalInProgress..": |cFFFFFFFF"..missionCount.."|r"
						label.timers[iCount].TooltipMSG2 = nil
						label.timers[iCount].TooltipMSG3 = format(GARRISON_LANDING_COMPLETED, missionCompleted, missionCount)
						label.timers[iCount].TooltipType = L.Missions
						label.timers[iCount].Swipe:SetCooldownUNIX(creationTime, duration)

						if missionCount == missionCompleted or ( GetServerTime() >= ceilMissionTime ) then
							label.timers[iCount].AltDone:Show()
							label.timers[iCount].isComplete = true
						else
							label.timers[iCount].AltDone:Hide()
						end
						showPlayer = true
					end
				end
				
				-->>>Current Missions Available
				if v.info.missions.currentMissions then
					local missionCount = 0
					local rightXOffset = 0
					
					if iCount > 0 then
						rightXOffset = select(4, label.timers[iCount]:GetPoint())
						rightXOffset = rightXOffset - label.timers[iCount]:GetWidth()
						rightXOffset = rightXOffset - 21
					else
						--get the location if the first one
						rightXOffset = select(4, label.timers[1]:GetPoint())
					end
					
					for i = 1, #v.info.missions.currentMissions do
						if v.info.missions.currentMissions[i].name then
							missionCount = missionCount + 1
						end
					end
					if missionCount > 0 then
						label.availMission.isComplete = false
						label.availMission:SetPoint("RIGHT", rightXOffset, 0)
						label.availMission:SetScript("OnEnter", Swipe_OnEnter)
						label.availMission:SetScript("OnLeave", Swipe_OnLeave)
						label.availMission.Count:SetText(missionCount)
						label.availMission.TooltipTitle = L.MissionsAvailable
						label.availMission.TooltipMSG = L.TotalAvailable..": |cFFFFFFFF"..missionCount.."|r"
						label.availMission.TooltipMSG2 = nil
						label.availMission.TooltipMSG3 = nil
						label.availMission.TooltipType = L.Missions
						label.availMission:Show()
						showPlayer = true
					end
				end
				
				--add to our table to sort afterwards
				if showPlayer then
					table.insert(displayTimers, label )
				end
				
			end
			
		end
		
	end

	--display the bars sorted
	if #displayTimers > 0 then
		table.sort(displayTimers, function(a,b) return (a.playerName < b.playerName) end)
		
		for i = 1, #displayTimers do
			local spacer = AceGUI:Create("SimpleGroup")
			spacer:SetLayout("Flow")
			spacer:SetFullWidth(true)
			spacer:SetHeight(100)
			spacer:AddChild(displayTimers[i])
			self.CHListFrame.scrollframe:AddChild(spacer)
		end
	end
				
end

function XANORDH:SetupCharList()
	if self.CHListFrame then return end
	
	--get the current player data, we have to wait a second as sometimes there is a delay with data grab
	XANORDH:Delay("getCurrentPlayerData", 0.5, function() XANORDH:displayList() end)
	
	local frame = CreateFrame("Frame", "xanOrderHallsCharList", GarrisonLandingPage)
	self.CHListFrame = frame
	frame:Hide()
	frame:SetAllPoints()
	
	local addonTitle = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	addonTitle:SetPoint("CENTER", frame:GetParent().HeaderBar, "TOP", 0, 15)
	addonTitle:SetText("xanOrderHalls")
	
	local textTitle = frame:CreateFontString(nil, "ARTWORK", "QuestFont_Enormous")
	textTitle:SetPoint("LEFT", frame:GetParent().HeaderBar, "LEFT", 26, 0)
	textTitle:SetText(L.CharacterList)
	
	local tab = CreateFrame("Button", "xanOrderHallsCharListTab", GarrisonLandingPage, "GarrisonLandingPageTabTemplate")
	tab:ClearAllPoints()
	tab:SetPoint("LEFT", GarrisonLandingPage, "BOTTOMRIGHT", -150, 0)
	tab:SetText(L.CharacterList)
	tab:Hide() --we do this to refresh the button for the size
	tab:Show() --we do this to refresh the button for the size
	frame.Tab = tab
	
	local scrollframe = AceGUI:Create("ScrollFrame")
	scrollframe:SetHeight(380)
	scrollframe:SetWidth(740)
	scrollframe:SetLayout("Flow")
	scrollframe.frame:SetParent(frame)
	scrollframe.frame:SetPoint("RIGHT", -40, -30)
	scrollframe.frame:Show()
	
	frame.scrollframe = scrollframe

	if not _GarrisonLandingPageTab_SetTab then
		_GarrisonLandingPageTab_SetTab = GarrisonLandingPageTab_SetTab
	end
	function GarrisonLandingPageTab_SetTab(...)
		if ... == frame.Tab then
			self:ShowCharList()
		else
			_GarrisonLandingPageTab_SetTab(...)
			frame:Hide()
			PanelTemplates_DeselectTab(frame.Tab)
		end
	end

end

function XANORDH:HookOrderHallFrame()
	if self.CHListFrame then return end

	hooksecurefunc("ShowGarrisonLandingPage", function(pageNum)
		self:SetupCharList()
		if GarrisonLandingPage.selectedTab == 10 then
			self:ShowCharList()
		end
	end)
	
	GarrisonLandingPageMinimapButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	GarrisonLandingPageMinimapButton:HookScript("OnClick", function(self, button)
		if button == "RightButton" then
			XANORDH:ShowCharList()
		end
		if GarrisonLandingPage.garrTypeID ~= 3 then
			XANORDH:SetupCharList()
		end
	end)
	
	--force the GarrisonUI to load otherwise we cannot access the API and XML frames
	LoadAddOn("Blizzard_GarrisonUI") 
	
	if IsAddOnLoaded("Blizzard_GarrisonUI") then
		self:SetupCharList()
	end
end


function XANORDH:forceLoad(frame)
	if self.CHListFrame then return end

	if frame:IsShown() then
		self:HookOrderHallFrame()
	else
		frame:HookScript("OnShow", 	XANORDH.HookOrderHallFrame)
	end
end

function XANORDH:OnInitialize()
	if IsAddOnLoaded("Blizzard_GarrisonUI") then
		self:forceLoad(GarrisonLandingPage)
		self:forceLoad(GarrisonMissionFrame)
		self:forceLoad(GarrisonShipyardFrame)
		self:forceLoad(GarrisonRecruiterFrame)
	end
end

----------------------
--      Enable      --
----------------------
local delayCount = {}
local eventFrame = CreateFrame("frame","XCH_EventFrame",UIParent)
local spamCheck = false

local events = {
	["GARRISON_MISSION_COMPLETE_RESPONSE"] = true,
	["GARRISON_MISSION_BONUS_ROLL_COMPLETE"] = true,
	--["GARRISON_SHOW_LANDING_PAGE"] = true,
	["GARRISON_MISSION_STARTED"] = true,
	["GARRISON_MISSION_NPC_OPENED"] = true,
	["GARRISON_MISSION_NPC_CLOSED"] = true,
	["GARRISON_SHIPYARD_NPC_OPENED"] = true,
	["GARRISON_SHIPYARD_NPC_CLOSED"] = true,
	["GARRISON_TALENT_NPC_OPENED"] = true,
	["GARRISON_TALENT_NPC_CLOSED"] = true,
	["GARRISON_TALENT_UPDATE"] = true,
	["GARRISON_TALENT_COMPLETE"] = true,
	["CURRENCY_DISPLAY_UPDATE"] = true,
	["GARRISON_LANDINGPAGE_SHIPMENTS"] = true,
	["GARRISON_SHIPMENT_RECEIVED"] = true,
	["SHIPMENT_CRAFTER_OPENED"] = true,
	["SHIPMENT_CRAFTER_CLOSED"] = true,
	["SHIPMENT_UPDATE"] = true, --this is spammed like crazy during active shipments, so lets control it
}

eventFrame:SetScript("OnUpdate",
	function( self, elapsed )
		if #delayCount > 0 then
			for i = #delayCount, 1, -1 do
				if delayCount[i].endTime and delayCount[i].endTime <= GetTime() then
					local func = delayCount[i].callbackFunction
					tremove(delayCount, i)
					func()
				end
			end
		end
	end
)

eventFrame:SetScript("OnEvent", function(self, event, ...) 
	if events[event] then
	
		if event ~= "SHIPMENT_UPDATE" or spamCheck then
			--get the current player data, we have to wait a second as sometimes there is a delay with data grab
			XANORDH:Delay(event, 0.5, function() XANORDH:getCurrentPlayerData() end)
		end
		
		--we have to control SHIPMENT_UPDATE because it's spammed too much.  So lets only allow it once per every other event.
		--reasons SHIPMENT_UPDATE gets spammed every 0.2 seconds varies based on mission timers I've found.
		if event ~= "SHIPMENT_UPDATE" and not spamCheck then
			--we only want to register this if any other event is fired and only once at a time
			spamCheck = true
		elseif event == "SHIPMENT_UPDATE" and spamCheck then
			spamCheck = false
		end
		
	end
end)

function XANORDH:ChatCommand(input)
	ShowGarrisonLandingPage()
	self:Delay("ChatCommand", 0.5, function() XANORDH:ShowCharList() end)
end

function XANORDH:OnEnable()
	self:setupDB()
	self:HookOrderHallFrame()
	
	for k, v in pairs(events) do
		eventFrame:RegisterEvent(k)
	end
	
	--register the slash command
	self:RegisterChatCommand("xoh", "ChatCommand")
	self:RegisterChatCommand("xanorderhalls", "ChatCommand")
	self:RegisterChatCommand("xanoh", "ChatCommand")
end

function XANORDH:Delay(name, duration, callbackFunction, force)
	for k, q in ipairs(delayCount) do
		if q.name == name then
			--don't run the same delay more than once, we can however refresh it
			q.duration = duration
			q.endTime = (GetTime()+duration)
			q.callbackFunction = callbackFunction
			return
		end
	end
	tinsert(delayCount, {name=name, duration=duration, endTime=(GetTime()+duration), callbackFunction=callbackFunction})
end
