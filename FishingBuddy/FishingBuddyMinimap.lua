-- Minimap Button Handling

FishingBuddy.Minimap = {};

local FL = LibStub("LibFishing-1.0");

local icon = LibStub("LibDBIcon-1.0");
local broker = LibStub:GetLibrary("LibDataBroker-1.1")

local GSB = FishingBuddy.GetSettingBool;

local function Minimap_OnClick(self, button, down)
	if ( button == "RightButton" ) then
		ToggleFishingBuddyFrame("FishingOptionsFrame");
	elseif ( FishingBuddy.IsSwitchClick("MinimapClickToSwitch") ) then
		FishingBuddy.Command(FBConstants.SWITCH);
	else
		ToggleFishingBuddyFrame("FishingLocationsFrame");
	end
end

local MinimapOptions = {
	["MinimapButtonVisible"] = {
		["text"] = FBConstants.CONFIG_MINIMAPBUTTON_ONOFF,
		["tooltip"] = FBConstants.CONFIG_MINIMAPBUTTON_INFO,
		["v"] = 1,
		["default"] = 0,
	},
	["MinimapClickToSwitch"] = {
		["text"] = FBConstants.CLICKTOSWITCH_ONOFF,
		["tooltip"] = FBConstants.CLICKTOSWITCH_INFO,
		["v"] = 1,
		["default"] = 0,
		["deps"] = { ["MinimapButtonVisible"] = "d", },
	},
};

local function setter(setting, value)
	if (setting == "MinimapButtonVisible") then
		FishingBuddy_Player["MinimapData"].hide = (not value or value == 0);
	else
		FishingBuddy.BaseSetSetting(setting, value);
	end
end

local function getter(setting)
	if (setting == "MinimapButtonVisible") then
		if (not FishingBuddy_Player["MinimapData"].hide) then
			return 1;
		else
			return 0;
		end
	else
		return FishingBuddy.BaseGetSetting(setting);
	end
end

local MinimapEvents = {};
MinimapEvents[FBConstants.OPT_UPDATE_EVT] = function()
	if (icon:IsRegistered(FBConstants.NAME)) then
		FishingBuddy_Player["MinimapData"].hide = not GSB("MinimapButtonVisible");
		icon:Refresh(FBConstants.NAME, FishingBuddy_Player["MinimapData"]);
	end
end

MinimapEvents["VARIABLES_LOADED"] = function()
	local _, info;
	
	if ( not FishingBuddy_Player["MinimapData"] ) then
		FishingBuddy_Player["MinimapData"] = { hide=false };
	end

	if ( not icon:IsRegistered(FBConstants.NAME) ) then
		local data = {
				icon = "Interface\\Icons\\Trade_Fishing",
				OnClick = Minimap_OnClick,
			};
		
		icon:Register(FBConstants.NAME, data, FishingBuddy_Player["MinimapData"]);
	end
end

FishingBuddy.OptionsFrame.HandleOptions(GENERAL, nil, MinimapOptions, setter, getter);
FishingBuddy.RegisterHandlers(MinimapEvents);