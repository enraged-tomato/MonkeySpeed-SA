-- OnLoad Function
function MonkeySpeed_OnLoad(self)

	-- register events
	self:RegisterEvent("VARIABLES_LOADED");
	self:RegisterEvent("UNIT_NAME_UPDATE");			-- this is the event I use to get per character config settings
	self:RegisterEvent("PLAYER_ENTERING_WORLD");	-- this event gives me a good character name in situations where "UNIT_NAME_UPDATE" doesn't even trigger
	self:RegisterEvent("ZONE_CHANGED_NEW_AREA");

	-- register chat slash commands
	-- this command toggles the percent display
	SlashCmdList["MONKEYSPEED_PERCENT"] = MonkeySpeed_TogglePercent;
	SLASH_MONKEYSPEED_PERCENT1 = "/monkeyspeedpercent";
	SLASH_MONKEYSPEED_PERCENT2 = "/mspercent";
	
	-- this command toggles the coloured speed bar display
	SlashCmdList["MONKEYSPEED_BAR"] = MonkeySpeed_ToggleBar;
	SLASH_MONKEYSPEED_BAR1 = "/monkeyspeedbar";
	SLASH_MONKEYSPEED_BAR2 = "/msbar";

	-- this command toggles the whole speed bar display
	SlashCmdList["MONKEYSPEED_DISPLAY"] = MonkeySpeed_ToggleDisplay;
	SLASH_MONKEYSPEED_DISPLAY1 = "/monkeyspeeddisplay";
	SLASH_MONKEYSPEED_DISPLAY2 = "/msdisplay";

	-- this command shows the help listing
	SlashCmdList["MONKEYSPEED_HELP"] = MonkeySpeedSlash_CmdHelp;
	SLASH_MONKEYSPEED_HELP1 = "/monkeyspeed";
	SLASH_MONKEYSPEED_HELP2 = "/mspeed";
	
	-- this command toggles the debug mode
	SlashCmdList["MONKEYSPEED_DEBUG"] = MonkeySpeed_ToggleDebug;
	SLASH_MONKEYSPEED_DEBUG1 = "/monkeyspeeddebug";
	SLASH_MONKEYSPEED_DEBUG2 = "/msdebug";
	
	-- this command toggles the lock
	SlashCmdList["MONKEYSPEED_LOCK"] = MonkeySpeed_ToggleLock;
	SLASH_MONKEYSPEED_LOCK1 = "/monkeyspeedlock";
	SLASH_MONKEYSPEED_LOCK2 = "/mslock";

	-- this command recalibrates the speed calculations for this zone
	SlashCmdList["MONKEYSPEED_CALIBRATE"] = MonkeySpeedSlash_CmdCalibrate;
	SLASH_MONKEYSPEED_CALIBRATE1 = "/monkeyspeedcalibrate";
	SLASH_MONKEYSPEED_CALIBRATE2 = "/mscalibrate";

	-- this command sets the size of the mode-filter sliding window
	SlashCmdList["MONKEYSPEED_SENSITIVITY"] = MonkeySpeedSlash_CmdSensitivity;
	SLASH_MONKEYSPEED_SENSITIVITY1 = "/monkeyspeedsensitivity";
	SLASH_MONKEYSPEED_SENSITIVITY2 = "/mssensitivity";

	-- this command resets all MonkeySpeed settings to defaults
	SlashCmdList["MONKEYSPEED_RESET"] = MonkeySpeedSlash_CmdReset;
	SLASH_MONKEYSPEED_RESET1 = "/monkeyspeedreset";
	SLASH_MONKEYSPEED_RESET2 = "/msreset";

	-- MonkeySpeedFrame:SetBackdropBorderColor(0.75, 0.75, 0.75, 1.0);
	MonkeySpeedFrame:SetBackdropBorderColor(1.0, 0.6901960784313725, 0.0, 1.0);
end

-- OnEvent Function
function MonkeySpeed_OnEvent(self, event, ...)
	local arg1 = ...;

	if (event == "VARIABLES_LOADED") then
		-- this event gets called when the player enters the world
		--  Note: on initial login this event will not give a good player name
		
		MonkeySpeed.m_bVariablesLoaded = true;
		
		-- double check that the mod isn't already loaded
		if (not MonkeySpeed.m_bLoaded) then
			
			MonkeySpeed.m_strPlayer = UnitName("player");
			
			-- if MonkeySpeed.m_strPlayer is "Unknown Entity" get out, need a real name
			if (MonkeySpeed.m_strPlayer ~= nil and MonkeySpeed.m_strPlayer ~= UNKNOWNOBJECT) then
				-- should have a valid player name here
				MonkeySpeed_Init();
			end
		end
		
		-- exit this event
		return;
		
	end -- PLAYER_ENTERING_WORLD
	
	if (event == "UNIT_NAME_UPDATE") then
		-- this event gets called whenever a unit's name changes (supposedly)
		--  Note: Sometimes it gets called when unit's name gets set to
		--  "Unknown Entity"
				
		-- double check that we are getting the player's name update
		if (arg1 == "player" and not MonkeySpeed.m_bLoaded) then
			-- this is the first place I know that reliably gets the player name
			MonkeySpeed.m_strPlayer = UnitName("player");
			
			-- if MonkeySpeed.m_strPlayer is "Unknown Entity" get out, need a real name
			if (MonkeySpeed.m_strPlayer ~= nil and MonkeySpeed.m_strPlayer ~= UNKNOWNOBJECT) then
				-- should have a valid player name here
				MonkeySpeed_Init();
			end
		end
		
		-- exit this event
		return;
		
	end -- UNIT_NAME_UPDATE
	if (event == "PLAYER_ENTERING_WORLD") then
		-- this event gets called when the player enters the world
		--  Note: on initial login this event will not give a good player name
		
		-- double check that the mod isn't already loaded
		if (not MonkeySpeed.m_bLoaded) then
			
			MonkeySpeed.m_strPlayer = UnitName("player");
			
			-- if MonkeySpeed.m_strPlayer is "Unknown Entity" get out, need a real name
			if (MonkeySpeed.m_strPlayer ~= nil and MonkeySpeed.m_strPlayer ~= UNKNOWNOBJECT) then
				-- should have a valid player name here
				MonkeySpeed_Init();
			end
		end
		
		-- exit this event
		return;
		
	end -- PLAYER_ENTERING_WORLD
	
	if (event == "ZONE_CHANGED_NEW_AREA") then
		-- this fixes the speed displaying wrong sometimes when you switch areas (thanks Bhaldie)
		SetMapToCurrentZone();

		-- drop the speed window so the new zone's readings aren't biased
		-- by the previous zone's samples
		MonkeySpeed_SpeedClear();

	end -- ZONE_CHANGED_NEW_AREA
end

-- OnUpdate Function (heavily based off code in Telo's Clock)
function MonkeySpeed_OnUpdate(self, elapsed)

	-- if the speedometer's not loaded yet, just exit
	if (not MonkeySpeed.m_bLoaded) then
		return;
	end
	
	-- how long since the last update?
	MonkeySpeed.m_iDeltaTime = MonkeySpeed.m_iDeltaTime + elapsed;
	
	-- update the speed calculation
	MonkeySpeed.m_vCurrPos.x, MonkeySpeed.m_vCurrPos.y = GetPlayerMapPosition("player");
	MonkeySpeed.m_vCurrPos.x = MonkeySpeed.m_vCurrPos.x + 0.0;
	MonkeySpeed.m_vCurrPos.y = MonkeySpeed.m_vCurrPos.y + 0.0;

	if (MonkeySpeed.m_vCurrPos.x) then
		local dist;
		
		-- travel speed ignores Z-distance (i.e. you run faster up or down hills)	
		-- x and y coords are not square, had to weight the x by 2.25 to make the readings match the y axis.
		dist = math.sqrt(
				((MonkeySpeed.m_vLastPos.x - MonkeySpeed.m_vCurrPos.x) * (MonkeySpeed.m_vLastPos.x - MonkeySpeed.m_vCurrPos.x) * 2.25 ) +
				((MonkeySpeed.m_vLastPos.y - MonkeySpeed.m_vCurrPos.y) * (MonkeySpeed.m_vLastPos.y - MonkeySpeed.m_vCurrPos.y)));
		
		MonkeySpeed.m_fSpeedDist = MonkeySpeed.m_fSpeedDist + dist;
		if (MonkeySpeed.m_iDeltaTime >= .1) then

			-- The map coords seem to be a different scale in different zones. Figure out which zone we're in
			local zonenum;
			local zonename;
			local contnum;
			local baserate;

			zonenum = GetCurrentMapZone();
			zonename = GetZoneText();
			

			if (zonenum ~= 0) then
				contnum = GetCurrentMapContinent();
				
				-- throws a nil error when entering a previously un-encountered zone.
				if MonkeySpeedConfig.m_ZoneBaseline[contnum] == nil then
					MonkeySpeedConfig.m_ZoneBaseline[contnum] = {}
				end
				if (MonkeySpeedConfig.m_ZoneBaseline[contnum][zonenum] == nil) then
					MonkeySpeedConfig.m_ZoneBaseline[contnum][zonenum] = {zid=zonenum, rate=.0001, name=zonename};
				end

				if (MonkeySpeed.m_bCalibrate == true) then
					local fRate, modeCount, zeroCount, size = MonkeySpeed_CalibPush(MonkeySpeed.m_fSpeedDist / MonkeySpeed.m_iDeltaTime / MonkeySpeed.calibrateSpeed);
					if (fRate) then
						MonkeySpeedConfig.m_ZoneBaseline[contnum][zonenum].rate = fRate;
						MonkeySpeedConfig.m_ZoneBaseline[contnum][zonenum].name = zonename;
						MonkeySpeed.m_bCalibrate = false;
						MonkeySpeed_CalibReport(modeCount, zeroCount, size);
					end
				end

				baserate = MonkeySpeedConfig.m_ZoneBaseline[contnum][zonenum].rate;
				
				if (MonkeySpeedConfig.m_ZoneBaseline[contnum][zonenum].name == nil) then
					MonkeySpeedConfig.m_ZoneBaseline[contnum][zonenum].name = zonename;
				end

				if (MonkeySpeedConfig.m_bDebugMode == true) then
					-- Debug code for figuring out new zone rates

					if (DEFAULT_CHAT_FRAME) then
						if (dist ~= 0) then
							DEFAULT_CHAT_FRAME:AddMessage(format("ZoneBaseline cont="..contnum.."  zid="..zonenum.."  rate=%.5f", 
								(MonkeySpeed.m_fSpeedDist / MonkeySpeed.m_iDeltaTime)));
						end
					end
				end
				
			else
				-- special zones

				if (MonkeySpeed.m_bCalibrate == true) then
					local fRate, modeCount, zeroCount, size = MonkeySpeed_CalibPush(MonkeySpeed.m_fSpeedDist / MonkeySpeed.m_iDeltaTime / MonkeySpeed.calibrateSpeed);
					if (fRate) then
						MonkeySpeedConfig.m_SpecialZoneBaseline[zonename] = fRate;
						MonkeySpeed.m_bCalibrate = false;
						MonkeySpeed_CalibReport(modeCount, zeroCount, size);
					end
				end

				baserate = MonkeySpeedConfig.m_SpecialZoneBaseline[zonename];

				if (MonkeySpeedConfig.m_bDebugMode == true) then
					-- Debug code for figuring out new zone rates

					if (DEFAULT_CHAT_FRAME) then
						if (dist ~= 0) then
							DEFAULT_CHAT_FRAME:AddMessage(format("SpecialZoneBaseline  name=" .. zonename .. "  rate=%.5f",
								(MonkeySpeed.m_fSpeedDist / MonkeySpeed.m_iDeltaTime)));
						end
					end
				end
			end


			if (baserate ~= nil and baserate ~= 0) then

				-- push the raw rounded percentage into the sliding window
				-- and display the mode (most-frequent value), falling back
				-- to the mean when every slot is unique
				local iInstant = MonkeySpeed_Round(((MonkeySpeed.m_fSpeedDist / MonkeySpeed.m_iDeltaTime) / baserate) * 100);
				MonkeySpeed.m_fSpeed = MonkeySpeed_SpeedPush(iInstant);
	
				MonkeySpeed.m_fSpeedDist = 0.0;
				MonkeySpeed.m_iDeltaTime = 0.0;
	
				if (MonkeySpeedConfig.m_bDisplayPercent) then
					-- Set the text for the speedometer
					MonkeySpeedText:SetText(format("%d%%", MonkeySpeed.m_fSpeed));
				end
	
				if (MonkeySpeedConfig.m_bDisplayBar) then
					-- Set the colour of the bar
					if (MonkeySpeed.m_fSpeed == 0.0) then
						MonkeySpeedBar:SetVertexColor(1, 0, 0);
					elseif (MonkeySpeed.m_fSpeed < 100.0) then
						MonkeySpeedBar:SetVertexColor(1, 0.25, 0);
					elseif (MonkeySpeed.m_fSpeed == 100.0) then
						MonkeySpeedBar:SetVertexColor(1, 0.5, 0);
					elseif ((MonkeySpeed.m_fSpeed > 100.0) and (MonkeySpeed.m_fSpeed < 140.0)) then
						MonkeySpeedBar:SetVertexColor(0, 1, 0);
					elseif ((MonkeySpeed.m_fSpeed >= 140.0) and (MonkeySpeed.m_fSpeed < 200.0)) then
						MonkeySpeedBar:SetVertexColor(1, 0, 1);
					elseif ((MonkeySpeed.m_fSpeed >= 200.0) and (MonkeySpeed.m_fSpeed < 550.0)) then
						MonkeySpeedBar:SetVertexColor(0.5, 0, 1);
					elseif (MonkeySpeed.m_fSpeed >= 550.0) then
						MonkeySpeedBar:SetVertexColor(0, 0, 1);
					end
				end
			else
				if (MonkeySpeedConfig.m_bDisplayPercent) then
					-- Set the text for the speedometer
					MonkeySpeedText:SetText("???%");
				end
	
				if (MonkeySpeedConfig.m_bDisplayBar) then
					-- Set the colour of the bar
					MonkeySpeedBar:SetVertexColor(0, 0, 0);
				end
			end
		end

		MonkeySpeed.m_vLastPos.x = MonkeySpeed.m_vCurrPos.x;
		MonkeySpeed.m_vLastPos.y = MonkeySpeed.m_vCurrPos.y;
		MonkeySpeed.m_vLastPos.z = MonkeySpeed.m_vCurrPos.z;
	end
end

-- when the mouse goes over the main frame, this gets called
function MonkeySpeed_OnEnter(self)
	-- put the tool tip in the default position
	GameTooltip_SetDefaultAnchor(GameTooltip, self);
	
	-- set the tool tip text
	GameTooltip:SetText(MONKEYSPEED_TITLE_VERSION, 1.0, 0.5, 0, 1);
	GameTooltip:AddLine(MONKEYSPEED_DESCRIPTION, GRAY_FONT_COLOR.r, GRAY_FONT_COLOR.g, GRAY_FONT_COLOR.b, 1);
	GameTooltip:Show();
end

function MonkeySpeed_OnMouseDown(button)
	-- if not loaded yet then get out
	if (MonkeySpeed.m_bLoaded == false) then
		return;
	end

	if (button == "LeftButton" and MonkeySpeedConfig.m_bLocked == false) then
		MonkeySpeedFrame:StartMoving();
	elseif (button == "RightButton") then
		MonkeySpeedSlash_CmdCalibrate(nil);
	end
end

function MonkeySpeed_OnMouseUp(button)
	-- if not loaded yet then get out
	if (MonkeySpeed.m_bLoaded == false) then
		return;
	end

	if (button == "LeftButton") then
		MonkeySpeedFrame:StopMovingOrSizing();
	end
end

function MonkeySpeed_ParsePosition(position)
	local x, y, z;
	local iStart, iEnd;

	iStart, iEnd, x, y = string.find(position, "^(.-), (.-)$");

	if( x ) then
		return x + 0.0, y + 0.0;
	end
	return nil, nil;
end

function MonkeySpeed_Round(x)
	if(x - floor(x) > 0.5) then
		x = x + 0.5;
	end
	return floor(x);
end

-- reset the display ring buffer
function MonkeySpeed_SpeedClear()
	MonkeySpeed.m_tSpeedWindow = {};
	MonkeySpeed.m_iSpeedWindowCount = 0;
	MonkeySpeed.m_iSpeedWindowIdx = 0;
end

-- push an integer percentage sample and return the value to display:
-- the mode of the window, or the mean when every sample is unique
function MonkeySpeed_SpeedPush(iValue)
	local size = MonkeySpeed.m_iSensitivity;
	if (size == nil or size < 1) then size = 1; end

	MonkeySpeed.m_iSpeedWindowIdx = (MonkeySpeed.m_iSpeedWindowIdx % size) + 1;
	MonkeySpeed.m_tSpeedWindow[MonkeySpeed.m_iSpeedWindowIdx] = iValue;
	if (MonkeySpeed.m_iSpeedWindowCount < size) then
		MonkeySpeed.m_iSpeedWindowCount = MonkeySpeed.m_iSpeedWindowCount + 1;
	end

	local filled = MonkeySpeed.m_iSpeedWindowCount;
	local counts = {};
	local bestVal = iValue;
	local bestCount = 0;
	local sum = 0;
	for i = 1, filled do
		local v = MonkeySpeed.m_tSpeedWindow[i];
		sum = sum + v;
		counts[v] = (counts[v] or 0) + 1;
		if (counts[v] > bestCount) then
			bestCount = counts[v];
			bestVal = v;
		end
	end

	if (bestCount <= 1 and filled > 1) then
		return MonkeySpeed_Round(sum / filled);
	end
	return bestVal;
end

-- reset the calibration ring buffer
function MonkeySpeed_CalibClear()
	MonkeySpeed.m_tCalibWindow = {};
	MonkeySpeed.m_iCalibWindowCount = 0;
	MonkeySpeed.m_iCalibWindowIdx = 0;
end

-- push a raw rate sample; return nil until the window is full, then
-- return (rate, modeCount, zeroCount, size). Rate is the mode (most-
-- frequent 5-decimal bucket) or the mean when every sample is unique.
-- Buffer is cleared in either case.
function MonkeySpeed_CalibPush(fRate)
	local size = MonkeySpeed.m_iCalibWindowSize or 10;

	MonkeySpeed.m_iCalibWindowIdx = (MonkeySpeed.m_iCalibWindowIdx % size) + 1;
	MonkeySpeed.m_tCalibWindow[MonkeySpeed.m_iCalibWindowIdx] = fRate;
	if (MonkeySpeed.m_iCalibWindowCount < size) then
		MonkeySpeed.m_iCalibWindowCount = MonkeySpeed.m_iCalibWindowCount + 1;
	end

	if (MonkeySpeed.m_iCalibWindowCount < size) then
		return nil;
	end

	local counts = {};
	local firstSample = {};
	local bestKey = nil;
	local bestCount = 0;
	local zeroCount = 0;
	local sum = 0;
	for i = 1, size do
		local v = MonkeySpeed.m_tCalibWindow[i];
		sum = sum + v;
		if (v == 0) then
			zeroCount = zeroCount + 1;
		end
		local key = format("%.5f", v);
		counts[key] = (counts[key] or 0) + 1;
		if (firstSample[key] == nil) then
			firstSample[key] = v;
		end
		if (counts[key] > bestCount) then
			bestCount = counts[key];
			bestKey = key;
		end
	end

	local result;
	if (bestCount <= 1) then
		result = sum / size;
	else
		result = firstSample[bestKey];
	end

	MonkeySpeed_CalibClear();
	return result, bestCount, zeroCount, size;
end

-- print the post-calibration summary: always emits "done", plus warnings
-- for zero-speed samples or a weak mode (jittery readings).
function MonkeySpeed_CalibReport(modeCount, zeroCount, size)
	if (DEFAULT_CHAT_FRAME == nil) then
		return;
	end
	DEFAULT_CHAT_FRAME:AddMessage("|cffffa500MonkeySpeed:|r calibration done.");
	if (zeroCount and zeroCount > 0) then
		DEFAULT_CHAT_FRAME:AddMessage(format("|cffff5555MonkeySpeed:|r %d of %d samples were zero. Keep moving forward on foot at a constant speed for the whole calibration, then try /mscalibrate again.", zeroCount, size));
	end
	if (modeCount and size and modeCount * 100 <= size * 40) then
		DEFAULT_CHAT_FRAME:AddMessage(format("|cffff5555MonkeySpeed:|r readings were jittery (best match %d/%d). Consider /mscalibrate %d for a larger sample.", modeCount, size, math.min(size * 2, 100)));
	end
end


