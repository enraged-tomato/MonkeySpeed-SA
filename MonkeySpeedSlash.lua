function MonkeySpeedSlash_CmdHelp()
	if (DEFAULT_CHAT_FRAME == nil) then
		return;
	end
	local lines = {
		"|cffffa500MonkeySpeed commands:|r",
		"  /mspeed, /monkeyspeed - show this help",
		"  /msdisplay - toggle the whole speedometer frame",
		"  /mspercent - toggle the percentage text",
		"  /msbar - toggle the coloured speed bar",
		"  /mslock - lock or unlock the frame position",
		"  /mscalibrate [N] - recalibrate this zone on foot; N = number of 0.1s samples (default 10)",
		"  /mssensitivity [N] - size of the mode-filter window, 1-30 (default 5)",
		"  /msdebug - toggle debug messages",
		"  /msreset - reset all settings to defaults",
	};
	for _, line in ipairs(lines) do
		DEFAULT_CHAT_FRAME:AddMessage(line);
	end
end

function MonkeySpeed_TogglePercent()
	-- if not loaded yet then get out
	if (MonkeySpeed.m_bLoaded == false) then
		return;
	end
	
	if (MonkeySpeedConfig.m_bDisplayPercent) then
		MonkeySpeedConfig.m_bDisplayPercent = false;
		MonkeySpeedText:Hide();
	else
		MonkeySpeedConfig.m_bDisplayPercent = true;
		MonkeySpeedText:Show();
	end
end

function MonkeySpeed_ToggleBar()
	-- if not loaded yet then get out
	if (MonkeySpeed.m_bLoaded == false) then
		return;
	end
	
	if (MonkeySpeedConfig.m_bDisplayBar) then
		MonkeySpeedConfig.m_bDisplayBar = false;
		MonkeySpeedBar:Hide();
	else
		MonkeySpeedConfig.m_bDisplayBar = true;
		MonkeySpeedBar:Show();
	end
end

function MonkeySpeed_ToggleDisplay()
	-- if not loaded yet then get out
	if (MonkeySpeed.m_bLoaded == false) then
		return;
	end
	
	if (MonkeySpeedConfig.m_bDisplay) then
		MonkeySpeedConfig.m_bDisplay = false;
		MonkeySpeedFrame:Hide();
	else
		MonkeySpeedConfig.m_bDisplay = true;
		MonkeySpeedFrame:Show();
	end
end

function MonkeySpeed_ToggleDebug()
	-- if not loaded yet then get out
	if (MonkeySpeed.m_bLoaded == false) then
		return;
	end
	
	MonkeySpeedConfig.m_bDebugMode = not MonkeySpeedConfig.m_bDebugMode;
end

function MonkeySpeed_ToggleLock()
	-- if not loaded yet then get out
	if (MonkeySpeed.m_bLoaded == false) then
		return;
	end
	
	MonkeySpeedConfig.m_bLocked = not MonkeySpeedConfig.m_bLocked;
end

function MonkeySpeedSlash_CmdShowPercent(bShow)
	-- if not loaded yet then get out
	if (MonkeySpeed.m_bLoaded == false) then
		return;
	end
	
	if (bShow == true) then
		MonkeySpeedConfig.m_bDisplayPercent = true;
		MonkeySpeedText:Show();
	else
		MonkeySpeedConfig.m_bDisplayPercent = false;
		MonkeySpeedText:Hide();
	end
end

function MonkeySpeedSlash_CmdShowBar(bShow)
	-- if not loaded yet then get out
	if (MonkeySpeed.m_bLoaded == false) then
		return;
	end
	
	if (bShow == true) then
		MonkeySpeedConfig.m_bDisplayBar = true;
		MonkeySpeedBar:Show();
	else
		MonkeySpeedConfig.m_bDisplayBar = false;
		MonkeySpeedBar:Hide();
	end
end

function MonkeySpeedSlash_CmdOpen(bOpen)
	-- if not loaded yet then get out
	if (MonkeySpeed.m_bLoaded == false) then
		return;
	end
	
	if (bOpen == true) then
		MonkeySpeedConfig.m_bDisplay = true;
		MonkeySpeedFrame:Show();
	else
		MonkeySpeedConfig.m_bDisplay = false;
		MonkeySpeedFrame:Hide();
	end
end

function MonkeySpeedSlash_CmdLock(bLock)
	-- if not loaded yet then get out
	if (MonkeySpeed.m_bLoaded == false) then
		return;
	end
	
	MonkeySpeedConfig.m_bLocked = bLock;
end

function MonkeySpeedSlash_CmdCalibrate(cmd)
	-- if not loaded yet then get out
	if (MonkeySpeed.m_bLoaded == false) then
		return;
	end
	
	-- cmd is the number of samples to collect (each sample = 0.1s).
	-- Calibration always assumes the user is on foot at 100% speed.
	local n = tonumber(cmd);
	if (n == nil) then n = 10; end
	n = floor(n + 0.5);
	if (n < 2)   then n = 2;   end
	if (n > 100) then n = 100; end

	MonkeySpeed.calibrateSpeed = 1;
	MonkeySpeed.m_iCalibWindowSize = n;
	MonkeySpeed_CalibClear();
	MonkeySpeed.m_bCalibrate = true;

	if (DEFAULT_CHAT_FRAME) then
		DEFAULT_CHAT_FRAME:AddMessage(format("|cffffa500MonkeySpeed:|r calibrating — run forward on foot at a constant speed for ~%.1f seconds (%d samples).", n * 0.1, n));
	end
end

function MonkeySpeedSlash_CmdSensitivity(cmd)
	-- if not loaded yet then get out
	if (MonkeySpeed.m_bLoaded == false) then
		return;
	end

	local n = tonumber(cmd);
	if (n == nil) then
		if (DEFAULT_CHAT_FRAME) then
			DEFAULT_CHAT_FRAME:AddMessage(format("MonkeySpeed: sensitivity = %d (usage: /mssensitivity 1-30 sliding-window samples; 1 = no filter, 5 = default)", MonkeySpeed.m_iSensitivity or 5));
		end
		return;
	end

	n = floor(n + 0.5);
	if (n < 1)  then n = 1;  end
	if (n > 30) then n = 30; end

	MonkeySpeed.m_iSensitivity = n;
	MonkeySpeedConfig.m_iSensitivity = n;
	MonkeySpeed_SpeedClear();

	if (DEFAULT_CHAT_FRAME) then
		DEFAULT_CHAT_FRAME:AddMessage(format("MonkeySpeed: sensitivity set to %d", n));
	end
end

function MonkeySpeedSlash_CmdSetWidth(iWidth)
	if (iWidth >= 48 and iWidth <= 256) then
		MonkeySpeedConfig.m_iFrameWidth = iWidth;
		MonkeySpeedFrame:SetWidth(MonkeySpeedConfig.m_iFrameWidth);
		MonkeySpeedBar:SetWidth(MonkeySpeedConfig.m_iFrameWidth - 10);
		--MonkeySpeed_Refresh();
	end
end

function MonkeySpeedSlash_CmdReset()
	-- if not loaded yet then get out
	if (MonkeySpeed.m_bLoaded == false) then
		return;
	end

	StaticPopup_Show("MONKEYSPEED_RESET");
end
