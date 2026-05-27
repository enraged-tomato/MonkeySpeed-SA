-- **************************************************************************
-- * MonkeySpeedTitan.lua
-- * TitanPanel integration for MonkeySpeed. No-op when Titan is not loaded.
-- **************************************************************************

if not TitanPanelButton_OnLoad or not TitanUtils_GetButton then return end

local TITAN_ID        = "MonkeySpeed"
local UPDATE_INTERVAL = 0.1

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
-- OnUpdate: doubles as a fallback driver for MonkeySpeed's update loop.
--
-- MonkeySpeed.m_fSpeed is normally maintained by MonkeySpeedFrame's own
-- OnUpdate handler. When the bar is hidden that handler stops firing, so we
-- step in here — but ONLY while the bar is hidden, to avoid double-ticking
-- m_iDeltaTime when both drivers are live. When neither the bar nor the
-- Titan widget is shown, no ticks happen at all (this OnUpdate doesn't fire
-- while its host button is hidden), so the speed calc costs zero CPU.
-- **************************************************************************
function TitanPanelMonkeySpeedButton_OnUpdate(self, elapsed)
	if MonkeySpeedFrame and not MonkeySpeedFrame:IsShown()
	   and MonkeySpeed_OnUpdate and MonkeySpeedLoaded() then
		MonkeySpeed_OnUpdate(MonkeySpeedFrame, elapsed)
	end

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

	if MonkeySpeedFrame then
		if show then MonkeySpeedFrame:Show() else MonkeySpeedFrame:Hide() end
	end
end

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

