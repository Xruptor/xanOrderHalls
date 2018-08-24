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
local menuFrame = CreateFrame("Frame", "xanOrderHall_DDMenu", UIParent, "UIDropDownMenuTemplate")

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
	if not dbplayer.info[LE_GARRISON_TYPE_6_0] then dbplayer.info[LE_GARRISON_TYPE_6_0] = {} end  --Warlords of Draenor
	if not dbplayer.info[LE_GARRISON_TYPE_7_0] then dbplayer.info[LE_GARRISON_TYPE_7_0] = {} end  --Legion
	if not dbplayer.info[LE_GARRISON_TYPE_8_0] then dbplayer.info[LE_GARRISON_TYPE_8_0] = {} end  --Battle for Azeroth
	
end

function XANORDH:HasGarrisonUnlocked()
	--TODO: work on shipyards later
	local hasGarrison = false

	hasGarrison = hasGarrison or C_Garrison.HasGarrison(LE_GARRISON_TYPE_6_0)
	hasGarrison = hasGarrison or C_Garrison.HasShipyard()
	hasGarrison = hasGarrison or C_Garrison.HasGarrison(LE_GARRISON_TYPE_7_0)
	hasGarrison = hasGarrison or C_Garrison.HasGarrison(LE_GARRISON_TYPE_8_0)

	return hasGarrison
end

function XANORDH:ShowCharList()
	if not self.CHListFrame then return end
	if not self:HasGarrisonUnlocked() then return end
	
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
	self:Delay("scanPlayerGarrisons", 0.5, function() self:scanPlayerGarrisons(true) end)
end

function XANORDH:scanPlayerGarrisons(forceDisplay)
	if not self:HasGarrisonUnlocked() then return end
	
	--TODO: work on shipyards later
	local hasGarrison = false
	
	--Warlords of Draenor
	if C_Garrison.HasGarrison(LE_GARRISON_TYPE_6_0) then
		self:getCurrentPlayerData(LE_GARRISON_TYPE_6_0)
		hasGarrison = true
	end
	
	--Legion
	if C_Garrison.HasGarrison(LE_GARRISON_TYPE_7_0) then
		self:getCurrentPlayerData(LE_GARRISON_TYPE_7_0)
		hasGarrison = true
	end
	
	--Battle for Azeroth
	if C_Garrison.HasGarrison(LE_GARRISON_TYPE_8_0) then
		self:getCurrentPlayerData(LE_GARRISON_TYPE_8_0)
		hasGarrison = true
	end
	
	if forceDisplay and hasGarrison then
		self:displayList()
	end
	
end

function XANORDH:getCurrentPlayerData(garrisonType)
	if not self.CHListFrame then return end
	if not garrisonType or not C_Garrison.HasGarrison(garrisonType) then return end

	dbplayer.info[garrisonType] = {} --reset it, clear out old data
	
	--https://github.com/tomrus88/BlizzardInterfaceCode/blob/master/Interface/AddOns/Blizzard_OrderHallUI/Blizzard_OrderHallTalents.lua
	
	local primaryCurrency, _ = C_Garrison.GetCurrencyTypes(garrisonType)
	local currencyName, amount, currencyTexture = GetCurrencyInfo(primaryCurrency)
	dbplayer.info[garrisonType].currency = { ["name"]=currencyName, ["amount"]=amount, ["currencyTexture"]=currencyTexture }
	
	local championCount = C_Garrison.GetNumFollowers(LE_FOLLOWER_TYPE_GARRISON_7_0)
	dbplayer.info[garrisonType].championCount = championCount
	
	local buildings = C_Garrison.GetBuildings(garrisonType)
	dbplayer.info[garrisonType].buildings = {}
	for i = 1, #buildings do
		local buildingID = buildings[i].buildingID
		if ( buildingID) then
			local name, texture, shipmentCapacity, shipmentsReady, shipmentsTotal, creationTime, duration, timeleftString, itemName, itemIcon, itemQuality, itemID = C_Garrison.GetLandingPageShipmentInfo(buildingID)
			if ( name ) then
				dbplayer.info[garrisonType].buildings[i] = {
					["name"] = name,
					["texture"] = texture,
					["shipmentCapacity"] = shipmentCapacity,
					["shipmentsReady"] = shipmentsReady,
					["shipmentsTotal"] = shipmentsTotal,
					["creationTime"] = creationTime,
					["duration"] = duration,
					["timeleftString"] = timeleftString,
					["itemName"] = itemName,
					["itemIcon"] = itemIcon,
					["itemQuality"] = itemQuality,
					["itemID"] = itemID,
				}
			end
		end
	end
	
	local followerShipments = C_Garrison.GetFollowerShipments(garrisonType)
	dbplayer.info[garrisonType].followers = {}
	for i = 1, #followerShipments do
		local name, texture, shipmentCapacity, shipmentsReady, shipmentsTotal, creationTime, duration, timeleftString, _, _, _, _, followerID = C_Garrison.GetLandingPageShipmentInfoByContainerID(followerShipments[i])
		if ( name ) then
			dbplayer.info[garrisonType].followers[i] = {
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
	
	local looseShipments = C_Garrison.GetLooseShipments(garrisonType)
	dbplayer.info[garrisonType].shipments = {}
	if (looseShipments) then
		for i = 1, #looseShipments do
			local name, texture, shipmentCapacity, shipmentsReady, shipmentsTotal, creationTime, duration, timeleftString, _, _, _, _, followerID = C_Garrison.GetLandingPageShipmentInfoByContainerID(looseShipments[i])
			if ( name ) then
				dbplayer.info[garrisonType].shipments[i] = {
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
	local uiTextureKit, classAgnostic, talentTrees = C_Garrison.GetTalentTreeInfoForID(garrisonType, select(3, UnitClass("player")));
  
	dbplayer.info[garrisonType].talents = {}
	if (talentTrees) then
		local completeTalentID = C_Garrison.GetCompleteTalent(garrisonType)
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
					dbplayer.info[garrisonType].talents[iCount] = {
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
	if not dbplayer.info[garrisonType].missions then dbplayer.info[garrisonType].missions = {} end
	local currentMissions = C_Garrison.GetAvailableMissions(LE_FOLLOWER_TYPE_GARRISON_7_0)

	local iCount = 0
	dbplayer.info[garrisonType].missions.currentMissions = {}
	if currentMissions then
		for i, missionInfo in pairs(currentMissions) do
			iCount = iCount + 1
			dbplayer.info[garrisonType].missions.currentMissions[iCount] = {
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
	dbplayer.info[garrisonType].missions.inProgress = {}
	if inProgressMissions then
		for i, missionInfo in pairs(inProgressMissions) do
			iCount = iCount + 1
			dbplayer.info[garrisonType].missions.inProgress[iCount] = {
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
	
	local garrisonType = LE_GARRISON_TYPE_7_0
	
	for realm, rd in pairs(dbglobal) do
		for k, v in pairs(rd) do
		
			local allowPass = false
			local iCount = 0
			local showPlayer = false
			local playerName = getClassColor(k or "Unknown", v.class)
			local summary = realm
			
			--only work with characters that have at least one champion unlocked.  Otherwise they don't have the order hall stuff unlocked yet
			if v.info[garrisonType].championCount and v.info[garrisonType].championCount > 0 then
				allowPass = true
			end
			
			if allowPass then
				
				local label = AceGUI:Create("xanOrderHallsButton")
				label:SetName(playerName)
				label.playerName = k --for sorting
				
				if v.info[garrisonType].currency then
					summary = summary.."  "..GREEN_FONT_COLOR_CODE..">|r  "..format([[|T%s:0|t]], v.info[garrisonType].currency.currencyTexture).." "..v.info[garrisonType].currency.amount
					showPlayer = true
				end
				
				label:SetSummary(summary)
				
				--hide all the timers just in case
				for i = 1, #label.timers do
					label.timers[i]:Hide()
				end
				
				--TODO: show building shipments as resources next to the garrison resources
				
				--now lets do the timers
				-->>>Followers (unit squads and such)
				if v.info[garrisonType].followers then
					for i = 1, #v.info[garrisonType].followers do
						iCount = iCount + 1
						label.timers[iCount].AltDone:Hide()
						label.timers[iCount].isComplete = false
						label.timers[iCount]:SetScript("OnEnter", Swipe_OnEnter)
						label.timers[iCount]:SetScript("OnLeave", Swipe_OnLeave)
						label.timers[iCount].Swipe:SetScript("OnCooldownDone", Swipe_OnDone)
						label.timers[iCount].Icon:SetTexture(v.info[garrisonType].followers[i].texture) --SetPortraitToTexture doesn't work with Followers
						label.timers[iCount].Icon:SetDesaturated(true)
						label.timers[iCount]:Show()
						
						local readyCount = v.info[garrisonType].followers[i].shipmentsReady or 0
						local totalCount = v.info[garrisonType].followers[i].shipmentsTotal or 0
						local duration = v.info[garrisonType].followers[i].duration or 0
						local creationTime = v.info[garrisonType].followers[i].creationTime or 0
						local timeLeft = (creationTime + duration) - GetServerTime()
						if timeLeft < 0 then timeLeft = 0 end
						
						label.timers[iCount].ShowCountOnComplete = false
						label.timers[iCount].Count:SetFormattedText(GARRISON_LANDING_SHIPMENT_COUNT, readyCount, totalCount)
						label.timers[iCount].TooltipTitle = v.info[garrisonType].followers[i].name or nil
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
				if v.info[garrisonType].shipments then
					for i = 1, #v.info[garrisonType].shipments do
						iCount = iCount + 1
						label.timers[iCount].AltDone:Hide()
						label.timers[iCount].isComplete = false
						label.timers[iCount]:SetScript("OnEnter", Swipe_OnEnter)
						label.timers[iCount]:SetScript("OnLeave", Swipe_OnLeave)
						label.timers[iCount].Swipe:SetScript("OnCooldownDone", Swipe_OnDone)
						SetPortraitToTexture(label.timers[iCount].Icon, v.info[garrisonType].shipments[i].texture)
						label.timers[iCount].Icon:SetDesaturated(true)
						label.timers[iCount]:Show()
						
						local readyCount = v.info[garrisonType].shipments[i].shipmentsReady or 0
						local totalCount = v.info[garrisonType].shipments[i].shipmentsTotal or 0
						local duration = v.info[garrisonType].shipments[i].duration or 0
						local creationTime = v.info[garrisonType].shipments[i].creationTime or 0
						local timeLeft = (creationTime + duration) - GetServerTime()
						if timeLeft < 0 then timeLeft = 0 end
						
						label.timers[iCount].ShowCountOnComplete = false
						label.timers[iCount].Count:SetFormattedText(GARRISON_LANDING_SHIPMENT_COUNT, readyCount, totalCount)
						label.timers[iCount].TooltipTitle = v.info[garrisonType].shipments[i].name or nil
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
				if v.info[garrisonType].talents then
					for i = 1, #v.info[garrisonType].talents do
						iCount = iCount + 1
						label.timers[iCount].AltDone:Hide()
						label.timers[iCount].isComplete = false
						label.timers[iCount]:SetScript("OnEnter", Swipe_OnEnter)
						label.timers[iCount]:SetScript("OnLeave", Swipe_OnLeave)
						label.timers[iCount].Swipe:SetScript("OnCooldownDone", Swipe_OnDone)
						SetPortraitToTexture(label.timers[iCount].Icon, v.info[garrisonType].talents[i].texture)
						label.timers[iCount].Icon:SetDesaturated(true)
						label.timers[iCount]:Show()
						
						local duration = v.info[garrisonType].talents[i].researchDuration or 0
						local creationTime = v.info[garrisonType].talents[i].researchStartTime or 0
						local timeLeft = (creationTime + duration) - GetServerTime()
						if timeLeft < 0 then timeLeft = 0 end
						
						label.timers[iCount].ShowCountOnComplete = false
						label.timers[iCount].Count:SetText(nil)
						label.timers[iCount].TooltipTitle = v.info[garrisonType].talents[i].name or nil
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
				if v.info[garrisonType].missions and v.info[garrisonType].missions.inProgress then
					local missionCount = 0
					local missionCompleted = 0
					local ceilMissionTime = 0
					local ceilMissionTimeDuration = 0
					
					for i = 1, #v.info[garrisonType].missions.inProgress do
						if v.info[garrisonType].missions.inProgress[i].name then
							missionCount = missionCount + 1
							
							if v.info[garrisonType].missions.inProgress[i].missionEndTime then
								if v.info[garrisonType].missions.inProgress[i].missionEndTime > ceilMissionTime then
									ceilMissionTime = v.info[garrisonType].missions.inProgress[i].missionEndTime
									ceilMissionTimeDuration = v.info[garrisonType].missions.inProgress[i].durationSeconds
								end
								if v.info[garrisonType].missions.inProgress[i].missionEndTime <= GetServerTime() then
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
				if v.info[garrisonType].missions and v.info[garrisonType].missions.currentMissions then
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
					
					for i = 1, #v.info[garrisonType].missions.currentMissions do
						if v.info[garrisonType].missions.currentMissions[i].name then
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
	self:Delay("scanPlayerGarrisons", 0.5, function() self:displayList() end)
	
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

function XANORDH:CreateMenu()

	local ddMenu = { { text = "Select an Option", notCheckable = true, isTitle = true} }
		
	if C_Garrison.HasGarrison(LE_GARRISON_TYPE_6_0) then
		tinsert(ddMenu, { text = "|cFF20ff20(WoD)|r Garrison", notCheckable = true, func = function()
			ShowGarrisonLandingPage(LE_GARRISON_TYPE_6_0)
			GarrisonLandingPageTab_SetTab(GarrisonLandingPageTab1)
		end }
		)
	else
		tinsert(ddMenu, { text = "|cFF20ff20(WoD)|r Garrison", notCheckable = true, disabled = true}
		)
	end
	
	if C_Garrison.HasGarrison(LE_GARRISON_TYPE_7_0) then
		tinsert(ddMenu, { text = "|cFF20ff20(Legion)|r Order Hall", notCheckable = true, func = function()
			ShowGarrisonLandingPage(LE_GARRISON_TYPE_7_0)
			GarrisonLandingPageTab_SetTab(GarrisonLandingPageTab1)
		end }
		)
	else
		tinsert(ddMenu, { text = "Order Hall (Not Unlocked)", notCheckable = true, disabled = true}
		)
	end
	
	if C_Garrison.HasGarrison(LE_GARRISON_TYPE_8_0) then
		tinsert(ddMenu, { text = "|cFF20ff20(BfA)|r War Report", notCheckable = true, func = function()
			ShowGarrisonLandingPage(LE_GARRISON_TYPE_8_0)
			GarrisonLandingPageTab_SetTab(GarrisonLandingPageTab1)
		end }
		)
	else
		tinsert(ddMenu, { text = "War Report (Not Unlocked)", notCheckable = true, disabled = true}
		)
	end
	
	tinsert(ddMenu, { text = "|cFF20ff20Display Characters|r", notCheckable = true, func = function()
		self:ShowCharList()
	end }
	)
	
	tinsert(ddMenu, { text = " ", notCheckable = true, disabled = true } )
	tinsert(ddMenu, { text = "Cancel", notCheckable = true, func = function(self) self:Hide() end }
	)

	return ddMenu
end

function XANORDH:HookOrderHallFrame()
	if self.CHListFrame then return end

	hooksecurefunc("ShowGarrisonLandingPage", function(pageNum)
		self:SetupCharList()
		if GarrisonLandingPage.selectedTab == 10 then
			self:ShowCharList()
		end
	end)
	
	GarrisonLandingPageMinimapButton:EnableMouse(true)
	GarrisonLandingPageMinimapButton:SetScript("OnMouseUp",function(self, event, value)
		if event == "RightButton" then
			menuFrame:SetPoint("RIGHT", GarrisonLandingPageMinimapButton, "LEFT")
			local ddMenu = XANORDH:CreateMenu()
			EasyMenu(ddMenu, menuFrame, menuFrame, 0 , 0, "MENU")
		end
		if not _GarrisonLandingPageTab_SetTab then
			_GarrisonLandingPageTab_SetTab = GarrisonLandingPageTab_SetTab
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
		frame:HookScript("OnShow", 	self.HookOrderHallFrame)
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
local eventFrame = CreateFrame("frame", "XCH_EventFrame", UIParent)
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
			XANORDH:Delay(event, 0.5, function() XANORDH:scanPlayerGarrisons() end)
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
	self:Delay("ChatCommand", 0.5, function() self:ShowCharList() end)
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
