-- define the dialog box for reseting config
StaticPopupDialogs["MONKEYSPEED_RESET"] = {
	text = MONKEYSPEED_CONFIRM_RESET,
	button1 = OKAY,
	button2 = CANCEL,
	OnAccept = function()
		MonkeySpeed_ResetConfig();
		if (DEFAULT_CHAT_FRAME) then
			DEFAULT_CHAT_FRAME:AddMessage(MONKEYSPEED_RESET_MSG);
		end
	end,
	timeout = 0,
	exclusive = 1
};


-- Script array, not saved
MonkeySpeed = {};
MonkeySpeed.m_iDeltaTime = 0;

MonkeySpeed.m_fSpeed = 0.0;
MonkeySpeed.m_fSpeedDist = 0.0;
MonkeySpeed.m_bLoaded = false;
MonkeySpeed.m_bVariablesLoaded = false;
MonkeySpeed.m_strPlayer = "";
MonkeySpeed.m_vCurrPos = {};
MonkeySpeed.m_bCalibrate = false;

-- display-side mode filter: push rounded percentages into a ring of size
-- m_iSensitivity; every tick the displayed speed is the most-frequent
-- value in the ring (mean fallback when every slot is unique)
MonkeySpeed.m_iSensitivity = 5;
MonkeySpeed.m_tSpeedWindow = {};
MonkeySpeed.m_iSpeedWindowCount = 0;
MonkeySpeed.m_iSpeedWindowIdx = 0;

-- calibration-side mode filter: fixed-size ring, mode picked once full
MonkeySpeed.m_iCalibWindowSize = 10;
MonkeySpeed.m_tCalibWindow = {};
MonkeySpeed.m_iCalibWindowCount = 0;
MonkeySpeed.m_iCalibWindowIdx = 0;


function MonkeySpeed_Init()
		
	-- double check that we didn't already load
	if ((MonkeySpeed.m_bLoaded == false) and (MonkeySpeed.m_bVariablesLoaded == true)) then

		if (not MonkeySpeedConfig) then
			MonkeySpeedConfig = {};
		end

		-- now we're ready to calculate speed
		MonkeySpeed.m_vLastPos = {};
		MonkeySpeed.m_vLastPos.x, MonkeySpeed.m_vLastPos.y = GetPlayerMapPosition("player");


		-- set the defaults if the values weren't loaded by the SavedVariables.lua
		if (MonkeySpeedConfig.m_bDisplay == nil) then
			MonkeySpeedConfig.m_bDisplay = true;
		end
		if (MonkeySpeedConfig.m_bDisplayPercent == nil) then
			MonkeySpeedConfig.m_bDisplayPercent = true;
		end
		if (MonkeySpeedConfig.m_bDisplayBar == nil) then
			MonkeySpeedConfig.m_bDisplayBar = true;
		end
		if (MonkeySpeedConfig.m_fUpdateRate == nil) then
			MonkeySpeedConfig.m_fUpdateRate = 0.5;
		end
		if (MonkeySpeedConfig.m_bDebugMode == nil) then
			MonkeySpeedConfig.m_bDebugMode = false;
		end
		if (MonkeySpeedConfig.m_bLocked == nil) then
			MonkeySpeedConfig.m_bLocked = false;
		end
		if (MonkeySpeedConfig.m_iFrameWidth == nil) then
			MonkeySpeedConfig.m_iFrameWidth = 46;
		end
		if (MonkeySpeedConfig.m_iSensitivity == nil) then
			MonkeySpeedConfig.m_iSensitivity = 5;
		end
		MonkeySpeed.m_iSensitivity = MonkeySpeedConfig.m_iSensitivity;

		-- quel fix to make the contnum an index into the ZoneBaseline table
		if (MonkeySpeedConfig.m_ZoneBaseline == nil) then
			MonkeySpeedConfig.m_ZoneBaseline = {
				{
					{zid=1,  rate=0.001820806197639339, name="Orgrimmar"},
					{zid=2,  rate=0.002070324492350493, name="Azshara"},
					{zid=3,  rate=0.00257938203064122,  name="Darkshore"},
					{zid=4,  rate=0.003218462697409648},
					{zid=5,  rate=0.00233539403201015,  name="Desolace"},
					{zid=6,  rate=0.001985833998241373, name="Durotar"},
					{zid=7,  rate=0.002000260433336382, name="Dustwallow Marsh"},
					{zid=8,  rate=0.001985697927468335, name="Felwood"},
					{zid=9,  rate=0.001999796525950309, name="Undercity"},
					{zid=10, rate=0.001825523256178235},
					{zid=11, rate=0.002043953860364595, name="Mulgore"},
					{zid=12, rate=0.007484216981120653, name="Orgrimmar"},
					{zid=13, rate=0.002043558777672257, name="Ashenvale"},
					{zid=14, rate=0.002150041310120119, name="Stonetalon Mountains"},
					{zid=15, rate=0.001520894865555426, name="Tanaris"},
					{zid=16, rate=0.002150478811359044},
					{zid=17, rate=0.001036107175689988, name="The Barrens"},
					{zid=18, rate=0.002386177853487009, name="Thousand Needles"},
					{zid=19, rate=0.01005990999001987,  name="Thunder Bluff"},
					{zid=20, rate=0.009938937314186113, name="Ashenvale"},
					{zid=21, rate=0.002386269972812934, name="Ashenvale"},
					{zid=22, rate=0.01005761601713153},
					{zid=23, rate=0.002838146668839583},
					{zid=24, rate=0.001478499888969668},
					{zid=25, rate=0.0001}
				},
				{
					{zid=1,  rate=0.003750287711962299, name="Tirisfal Glades"},
					{zid=2,  rate=0.002916654945165441, name="Arathi Highlands"},
					{zid=3,  rate=0.004221287078060015, name="Undercity"},
					{zid=4,  rate=0.00313459219957742,  name="Ashenvale"},
					{zid=5,  rate=0.003586150398380203, name="Durotar"},
					{zid=6,  rate=0.004200751773520065},
					{zid=7,  rate=0.002133008700431164, name="Tirisfal Glades"},
					{zid=8,  rate=0.003885132686676924, name="Duskwood"},
					{zid=9,  rate=0.00271264820476215,  name="Undercity"},
					{zid=10, rate=0.003024722496557702, name="Orgrimmar"},
					{zid=11, rate=0.003281351221939533, name="Hillsbrad Foothills"},
					{zid=12, rate=0.003181724673004079},
					{zid=13, rate=0.00328166290809318,  name="Thunder Bluff"},
					{zid=14, rate=0.01327348777806501},
					{zid=15, rate=0.003156057393687188, name="Durotar"},
					{zid=16, rate=0.002499931404173558, name="Silverpine Forest"},
					{zid=17, rate=0.004836815394038805},
					{zid=18, rate=0.004703745601507035, name="Undercity"},
					{zid=19, rate=0.008677712100068411},
					{zid=20, rate=0.002500077023455918, name="Hillsbrad Foothills"},
					{zid=21, rate=0.002323338289368138, name="Tirisfal Glades"},
					{zid=22, rate=0.00164592404573333,  name="Ashenvale"},
					{zid=23, rate=0.010939068231094,    name="Undercity"},
					{zid=24, rate=0.002727237845309258},
					{zid=25, rate=0.002324102645181357, name="Undercity"},
					{zid=26, rate=0.01093611527111662,  name="Undercity"},
					{zid=27, rate=0.002441762127737395},
					{zid=28, rate=0.003002128405179666},
					{zid=29, rate=0.002539378551295865},
					{zid=30, rate=0.0001}
				},
				{
					{zid=1,  rate=0.001935700289836371},
					{zid=2,  rate=0.00203318351992493},
					{zid=3,  rate=0.001900039363242876},
					{zid=4,  rate=0.001883515186843005},
					{zid=5,  rate=0.001909060476440717},
					{zid=6,  rate=0.008039272332136098},
					{zid=7,  rate=0.001944384338958065},
					{zid=8,  rate=0.002088313733170485},
					{zid=9,  rate=0.0001},
					{zid=10, rate=0.0001}
				}
			};
		end
		
		if (MonkeySpeedConfig.m_SpecialZoneBaseline == nil) then
			MonkeySpeedConfig.m_SpecialZoneBaseline = {
					[MONKEYSPEED_BLACKROCK] = 0.0002983199214410154,
					[MONKEYSPEED_WARSONG] = 0.009159138767039199,
					[MONKEYSPEED_ALTERAC] = 0.002477872662261515,
					[MONKEYSPEED_ARATHI] = 0.005978692329518227
			};
		end
		
		-- show or hide the right options
		if (MonkeySpeedConfig.m_bDisplay) then
			MonkeySpeedFrame:Show();
		else
			MonkeySpeedFrame:Hide();
		end
		
		if (MonkeySpeedConfig.m_bDisplayPercent) then
			MonkeySpeedText:Show();
		else
			MonkeySpeedText:Hide();
		end
		
		if (MonkeySpeedConfig.m_bDisplayBar) then
			MonkeySpeedBar:Show();
		else
			MonkeySpeedBar:Hide();
		end

		MonkeySpeedSlash_CmdSetWidth(MonkeySpeedConfig.m_iFrameWidth);
		
		-- All variables are loaded now
		MonkeySpeed.m_bLoaded = true;
		
		-- print out a nice message letting the user know the addon loaded
		if (DEFAULT_CHAT_FRAME) then
			DEFAULT_CHAT_FRAME:AddMessage(MONKEYSPEED_LOADED);
		end
	end
end

function MonkeySpeed_ResetConfig()
	-- set the defaults if the values weren't loaded by the SavedVariables.lua
	MonkeySpeedConfig.m_bDisplay = true;
	MonkeySpeedConfig.m_bDisplayPercent = true;
	MonkeySpeedConfig.m_bDisplayBar = true;
	MonkeySpeedConfig.m_fUpdateRate = 0.5;
	MonkeySpeedConfig.m_bDebugMode = false;
	MonkeySpeedConfig.m_bLocked = false;
	MonkeySpeedConfig.m_iFrameWidth = 46;
	MonkeySpeedConfig.m_iSensitivity = 5;
	MonkeySpeed.m_iSensitivity = 5;

	-- show or hide the right options
	-- update the frame
	MonkeySpeedFrame:ClearAllPoints();
	MonkeySpeedFrame:SetPoint("CENTER", "UIParent", "CENTER", 0, 0);
	MonkeySpeedFrame:Show();
	
	MonkeySpeedText:Show();
	MonkeySpeedBar:Show();

	MonkeySpeedSlash_CmdSetWidth(MonkeySpeedConfig.m_iFrameWidth);
end
