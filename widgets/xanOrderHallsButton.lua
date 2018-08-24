--[[-----------------------------------------------------------------------------
xanOrderHallsButton Widget
-------------------------------------------------------------------------------]]
local Type, Version = "xanOrderHallsButton", 1
local AceGUI = LibStub and LibStub("AceGUI-3.0", true)
if not AceGUI or (AceGUI:GetWidgetVersion(Type) or 0) >= Version then return end

-- Lua APIs
local select, pairs = select, pairs

-- WoW APIs
local CreateFrame, UIParent = CreateFrame, UIParent

-- Global vars/functions that we don't upvalue since they might get hooked, or upgraded
-- List them here for Mikk's FindGlobals script
-- GLOBALS: GameFontHighlightSmall

--[[-----------------------------------------------------------------------------
Methods
-------------------------------------------------------------------------------]]
local methods = {
	["OnAcquire"] = function(self)
		-- restore default values
		self:SetHeight(54)
		self:SetWidth(700)
		self:SetName()
		self:SetSummary()
		for i = 1, 9 do
			self.timers[i]:Hide()
		end
		self.availMission:Hide()
	end,

	-- ["OnRelease"] = nil,

	["SetName"] = function(self, text)
		self.name:SetText(text)
	end,
	
	["SetSummary"] = function(self, text)
		self.summary:SetText(text)
	end,
	
}

--[[-----------------------------------------------------------------------------
Constructor
-------------------------------------------------------------------------------]]
local function Constructor()

	local name = "xanOrderHallsButton" .. AceGUI:GetNextWidgetNum(Type)
	local frame = CreateFrame("Frame", name, UIParent)
	frame:EnableMouse(false)
	frame:Hide()
	
	local texture1 = frame:CreateTexture(nil, "BACKGROUND", nil, 0)
	texture1:SetAtlas("GarrMission_MissionParchment")
	texture1:SetHorizTile(true)
	texture1:SetVertTile(true)
	texture1:SetVertexColor(0.75, 0.52, 0.05)
	texture1:SetAllPoints()
	
	local texture2 = frame:CreateTexture(nil, "BACKGROUND", nil, 1)
	texture2:SetAtlas("!GarrMission_Bg-Edge", true)
	texture2:SetVertTile(true)
	texture2:SetPoint("TOPLEFT", -10, 0)
	texture2:SetPoint("BOTTOMLEFT", -10, 0)
	texture2:SetVertexColor(0.75, 0.52, 0.05)
	
	local texture3 = frame:CreateTexture(nil, "BACKGROUND", nil, 1)
	texture3:SetAtlas("!GarrMission_Bg-Edge", true)
	texture3:SetVertTile(true)
	texture3:SetPoint("TOPRIGHT", 10, 0)
	texture3:SetPoint("BOTTOMRIGHT", 10, 0)
	texture3:SetVertexColor(1, 0.8, 0.65)
	texture3:SetTexCoord(1,0, 0,1)
	
	local texture4 = frame:CreateTexture(nil, "BORDER")
	texture4:SetAtlas("_GarrMission_TopBorder", true)
	texture4:SetPoint("TOPLEFT", 20, 4)
	texture4:SetPoint("TOPRIGHT", -20, 4)
	
	local texture5 = frame:CreateTexture(nil, "BORDER")
	texture5:SetAtlas("_GarrMission_TopBorder", true)
	texture5:SetPoint("BOTTOMLEFT", 20, -4)
	texture5:SetPoint("BOTTOMRIGHT", -20, -4)
	texture5:SetTexCoord(0,1, 1,0)
	
	local texture6 = frame:CreateTexture(nil, "BORDER", nil, 1)
	texture6:SetAtlas("GarrMission_TopBorderCorner", true)
	texture6:SetPoint("TOPLEFT", -5, 4)
	
	local texture7 = frame:CreateTexture(nil, "BORDER", nil, 1)
	texture7:SetAtlas("GarrMission_TopBorderCorner", true)
	texture7:SetPoint("TOPRIGHT", 6, 4)
	texture7:SetTexCoord(1,0, 0,1)
	
	local texture8 = frame:CreateTexture(nil, "BORDER", nil, 1)
	texture8:SetAtlas("GarrMission_TopBorderCorner", true)
	texture8:SetPoint("BOTTOMLEFT", -5, -4)
	texture8:SetTexCoord(0,1, 1,0)
	
	local texture9 = frame:CreateTexture(nil, "BORDER", nil, 1)
	texture9:SetAtlas("GarrMission_TopBorderCorner", true)
	texture9:SetPoint("BOTTOMRIGHT", 6, -4)
	texture9:SetTexCoord(1,0, 1,0)
	
	local texture10 = frame:CreateTexture(nil, "BACKGROUND", nil, 6)
	texture10:SetColorTexture(0,0,0,0.25)
	texture10:SetPoint("BOTTOMRIGHT", -2, 2)
	texture10:SetPoint("TOPLEFT", 2, -2)
	
	local title = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlightHuge")
	title:ClearAllPoints()
	title:SetPoint("LEFT", 14, 6)
	
	local summary = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	summary:ClearAllPoints()
	summary:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -1)
	
	local timers = {}
	local lastTimer

	for i = 1, 9 do
		local swipe = CreateFrame("Frame", nil, frame, "GarrisonLandingPageReportShipmentStatusTemplate")
		--swipe.Swipe:SetSwipeColor(53/255, 136/255, 1)
		swipe:SetScale(42/64)
		swipe:SetPoint("RIGHT", (40 -55*i) / swipe:GetScale(), 0)
		swipe.Done:Hide()
		--swipe.Done:SetColorTexture(53/255, 136/255, 1, 0.3)
		swipe.BG:Show()
		swipe.Border:Show()
		swipe.Border:SetDrawLayer("BORDER", -1)
		swipe.AltDone = swipe:CreateTexture(nil, "OVERLAY")
		swipe.AltDone:SetTexture("Interface/Garrison/Garr_TimerFill")
		swipe.AltDone:SetSize(90.5, 90.5)
		swipe.AltDone:SetPoint("CENTER")
		swipe.AltDone:Hide()
		--swipe.AltDone:SetColorTexture(53/255, 136/255, 1, 0.3)
		swipe.Count:ClearAllPoints()
		swipe.Count:SetPoint("CENTER")
		swipe.Count:SetFont("Fonts\\FRIZQT__.TTF", 18, "THINOUTLINE")
		--swipe.Count:SetShadowOffset(1, -1)
		swipe.Count:SetShadowColor(0, 0, 0, 0)
		swipe.Count:SetTextColor(1, 1, 1, 1)
		swipe:Hide()
		lastTimer = swipe
		timers[i] = swipe
	end
	
	local availMission = CreateFrame("Frame", nil, frame)
	availMission:SetSize(lastTimer:GetWidth(), lastTimer:GetHeight())
	availMission:SetScale(42/64)
	availMission:SetPoint("RIGHT", 0, 0)
	local availMissionIcon = availMission:CreateTexture(nil, "BACKGROUND", nil, 0)
	availMissionIcon:SetAtlas("ClassHall-QuestIcon-Desaturated", true)
	availMissionIcon:SetAllPoints()
	availMission.Icon = availMissionIcon
	local availMissionText = availMission:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	availMissionText:ClearAllPoints()
	availMissionText:SetPoint("CENTER", availMission, "CENTER", 0, 0)
	availMissionText:SetFont("Fonts\\FRIZQT__.TTF", 18, "THINOUTLINE")
	availMissionText:SetShadowColor(0, 0, 0, 0)
	availMissionText:SetTextColor(1, 1, 1, 1)
	availMissionText:SetText(nil)
	availMission.Count = availMissionText
	availMission:Hide()

	local widget = {
		name  = title,
		summary = summary,
		frame = frame,
		timers = timers,
		type  = Type,
		availMission = availMission,
	}
	for method, func in pairs(methods) do
		widget[method] = func
	end

	return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)