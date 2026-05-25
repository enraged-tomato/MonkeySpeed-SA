-- **************************************************************************
-- * MonkeySpeedTitan.lua
-- * TitanPanel integration for MonkeySpeed. No-op when Titan is not loaded.
-- **************************************************************************

if not TitanPanelButton_OnLoad or not TitanUtils_GetButton then return end

local TITAN_ID        = "MonkeySpeed"
local UPDATE_INTERVAL = 0.2

local function GetSpeedColor(spd)
	if spd == nil then
		return "|cff000000"
	elseif spd == 0 then
		return "|cffff0000"
	elseif spd < 100 then
		return "|cffff4000"
	elseif spd == 100 then
		return "|cffff8000"
	elseif spd < 140 then
		return "|cff00ff00"
	elseif spd < 200 then
		return "|cffff00ff"
	elseif spd < 550 then
		return "|cffa060ff"  -- purple, brightened for readability on Titan's dark bar
	else
		return "|cff4488ff"  -- blue, brightened for readability on Titan's dark bar
	end
end

local function MonkeySpeedLoaded()
	return MonkeySpeed and MonkeySpeed.m_bLoaded
end

-- **************************************************************************
-- Plugin registration
-- **************************************************************************
function TitanPanelMonkeySpeedButton_OnLoad(self)
	self.registry = {
		id                  = TITAN_ID,
		category            = "Information",
		version             = "1.0",
		menuText            = "MonkeySpeed",
		buttonTextFunction  = "TitanPanelMonkeySpeedButton_GetButtonText",
		tooltipTitle        = "MonkeySpeed",
		tooltipTextFunction = "TitanPanelMonkeySpeedButton_GetTooltipText",
		controlVariables    = {
			ShowIcon           = false,
			ShowLabelText      = true,
			ShowRegularText    = false,
			ShowColoredText    = false,
			DisplayOnRightSide = false,
		},
		savedVariables = {
			ShowLabelText = 1,
			ShowMonkeyBar = 1,
		},
	}
end

-- **************************************************************************
-- Button text: "MonkeySpeed: " + colored "NN%"
-- Color always follows MonkeySpeed's scheme, independent of Titan's
-- ShowColoredText toggle.
-- **************************************************************************
function TitanPanelMonkeySpeedButton_GetButtonText(id)
	if not MonkeySpeedLoaded() then
		return "MonkeySpeed: ", "|cff000000???|r"
	end
	local spd = MonkeySpeed.m_fSpeed
	if spd == nil then
		return "MonkeySpeed: ", "|cff000000???|r"
	end
	local pct = math.floor(spd + 0.5)
	return "MonkeySpeed: ", GetSpeedColor(spd) .. pct .. "%|r"
end

-- **************************************************************************
-- Tooltip
-- **************************************************************************
function TitanPanelMonkeySpeedButton_GetTooltipText()
	if not MonkeySpeedLoaded() then
		return "MonkeySpeed is not loaded."
	end
	local spd = MonkeySpeed.m_fSpeed
	local pctStr
	if spd == nil then
		pctStr = "???"
	else
		pctStr = math.floor(spd + 0.5) .. "%"
	end
	return "Current speed:\t" .. TitanUtils_GetHighlightText(pctStr) .. "\n" ..
	       "\n" ..
	       TitanUtils_GetNormalText("Right-click for options.")
end

-- **************************************************************************
-- OnUpdate: throttle Titan refresh
-- **************************************************************************
function TitanPanelMonkeySpeedButton_OnUpdate(self, elapsed)
	self.elapsed = (self.elapsed or 0) + elapsed
	if self.elapsed >= UPDATE_INTERVAL then
		self.elapsed = 0
		TitanPanelPluginHandle_OnUpdate({TITAN_ID, TITAN_PANEL_UPDATE_BUTTON})
	end
end

-- **************************************************************************
-- Right-click menu
-- **************************************************************************
function TitanPanelRightClickMenu_PrepareMonkeySpeedMenu()
	if UIDROPDOWNMENU_MENU_LEVEL == 1 then
		TitanPanelRightClickMenu_AddTitle("MonkeySpeed")
		TitanPanelRightClickMenu_AddSpacer()
		TitanPanelRightClickMenu_AddCommand("Calibrate", TITAN_ID, "TitanPanelMonkeySpeedButton_Calibrate")

		-- Custom toggle: AddToggleVar's 4th param is a "related vars" table for
		-- the all-off check, NOT a callback. Build the entry by hand so we can
		-- run our own sync after the flip.
		local info = {}
		info.text             = "Show MonkeySpeed Bar"
		info.checked          = TitanGetVar(TITAN_ID, "ShowMonkeyBar")
		info.keepShownOnClick = 1
		info.func             = function()
			TitanToggleVar(TITAN_ID, "ShowMonkeyBar")
			TitanPanelMonkeySpeedButton_ToggleBar()
		end
		UIDropDownMenu_AddButton(info)
		TitanPanelRightClickMenu_AddToggleLabelText(TITAN_ID)
		TitanPanelRightClickMenu_AddSpacer()
		local L = LibStub and LibStub("AceLocale-3.0", true) and LibStub("AceLocale-3.0"):GetLocale("Titan", true)
		local hideLabel = (L and L["TITAN_PANEL_MENU_HIDE"]) or "Hide"
		TitanPanelRightClickMenu_AddCommand(hideLabel, TITAN_ID, TITAN_PANEL_MENU_FUNC_HIDE)
	end
end

-- **************************************************************************
-- Menu callbacks
-- **************************************************************************
function TitanPanelMonkeySpeedButton_Calibrate()
	if MonkeySpeedLoaded() and MonkeySpeedSlash_CmdCalibrate then
		MonkeySpeedSlash_CmdCalibrate(nil)
	end
end

function TitanPanelMonkeySpeedButton_ToggleBar()
	local show = TitanGetVar(TITAN_ID, "ShowMonkeyBar")
	if MonkeySpeedConfig then
		MonkeySpeedConfig.m_bDisplay = show and true or false
	end
	-- Safe to truly Hide() now: the OnUpdate that maintains MonkeySpeed.m_fSpeed
	-- runs on a separate driver frame (see bottom of file), independent of
	-- MonkeySpeedFrame's visibility.
	if MonkeySpeedFrame then
		if show then MonkeySpeedFrame:Show() else MonkeySpeedFrame:Hide() end
	end
end

-- **************************************************************************
-- Create the plugin button programmatically (no XML required).
-- We must:
--   1) Create the button inheriting TitanPanelComboTemplate
--   2) Explicitly create the $parentRightClickMenu child frame — Titan's
--      right-click handler looks it up by name via _G; template child
--      frames are not always materialised when inherited from Lua.
--   3) Call our OnLoad (assigns self.registry) BEFORE TitanPanelButton_OnLoad
--      (queues registration which reads self.registry).
-- **************************************************************************
-- Parent the button to an *unnamed* wrapper frame, mirroring TitanSpeed.xml's
-- structure. Titan's TitanUtils_GetButtonIDFromMenu walks menu->button->parent;
-- if the button's parent has a name, it mis-identifies the plugin as a child
-- button and right-click silently fails to find the menu prepare function.
local parentFrame = CreateFrame("Frame", nil, UIParent)
local btn = CreateFrame("Button", "TitanPanelMonkeySpeedButton", parentFrame, "TitanPanelComboTemplate")
btn:SetFrameStrata("FULLSCREEN")
btn:SetToplevel(true)
btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")

if not _G["TitanPanelMonkeySpeedButtonRightClickMenu"] then
	local menu = CreateFrame("Frame", "TitanPanelMonkeySpeedButtonRightClickMenu", btn, "UIDropDownMenuTemplate")
	menu:SetID(1)
	menu:Hide()
end

btn:SetScript("OnUpdate", TitanPanelMonkeySpeedButton_OnUpdate)
btn:SetScript("OnClick",  function(self, button) TitanPanelButton_OnClick(self, button) end)
btn:SetScript("OnEnter",  function(self) TitanPanelButton_OnEnter(self) end)
btn:SetScript("OnLeave",  function(self) TitanPanelButton_OnLeave(self) end)

-- Inheriting TitanPanelComboTemplate already fired TitanPanelButton_OnLoad,
-- which queued this frame for registration. We only need to populate
-- self.registry before Titan processes the queue (at PLAYER_LOGIN).
TitanPanelMonkeySpeedButton_OnLoad(btn)

-- **************************************************************************
-- Decouple MonkeySpeed's update loop from MonkeySpeedFrame's visibility.
--
-- MonkeySpeed.m_fSpeed is recalculated in MonkeySpeed_OnUpdate (see
-- MonkeySpeed.lua). That handler was originally wired to MonkeySpeedFrame
-- itself, which means hiding the bar would stop the update loop and freeze
-- the Titan readout. We route the tick through a dedicated, always-shown,
-- invisible Frame parented to UIParent instead. The original handler on
-- MonkeySpeedFrame is cleared to avoid double-ticking the delta-time.
-- **************************************************************************
local driver = CreateFrame("Frame", nil, UIParent)
driver:SetScript("OnUpdate", function(_, elapsed)
	if MonkeySpeedFrame and MonkeySpeed_OnUpdate then
		MonkeySpeed_OnUpdate(MonkeySpeedFrame, elapsed)
	end
end)

if MonkeySpeedFrame then
	MonkeySpeedFrame:SetScript("OnUpdate", nil)
end
