
local rematch = Rematch
local settings

rematch.optionsText = {
	AutoShow={"Auto show","When targeting something with saved pets, and the pets are not already loaded, show the Rematch window and close it when pets load."},
	AutoLoad={"Auto load","When a new target has saved pets not already loaded, load the pets immediately. Note: if you target by right-clicking, it may be too late to load pets!"},
	AutoMouseover={"On mouseover","Instead of waiting to target, auto-load pets when you mouseover something that has a saved team not already loaded."},
	AutoLoadAlways={"Always load","In addition to auto loading at new targets, persistently auto load every time you target (or mouseover if mouseover option enabled)."},
	KeepSummoned={"Keep companion","After a team is loaded, summon back the companion that was at your side before the load."},
	KeepLeveling={"Keep leveling pet","If one of your current pets is a leveling pet, loading a team will not swap out that pet. Instead, only the first two saved pets will load alongside it."},
	DisableShare={"Disable sharing","Disable the Send button and also block any incoming pets sent by others. Import and Export still work."},
	LargeWindow={"Larger window","Make the Rematch window larger for easier viewing."},
	LockWindow={"Lock window","Lock the Rematch window so it can't be dismissed with the Escape key or moved unless Shift is held."},
	LockDrawer={"Lock drawer","Lock the pull-out drawer so it can't be dismissed with the Escape key."},
	AutoConfirm={"Auto confirm","Don't ask for confirmation when saving over an existing team or deleting one."},
	BestOfSpecies={"Auto upgrade","When learning a pet, automatically upgrade any lesser versions of the pet in your saved teams."},
	JumpToTeam={"Jump to key","While the mouse is over the team list or pet browser, hitting a key will jump to the next team or pet that begins with that letter."},
	EmptyMissing={"Empty missing","When a team with missing pets loads and a pet is missing, empty the slot the pet would go to instead of ignoring the slot."},
	StayForBattle={"Stay for battle","When a pet battle begins, keep Rematch on screen instead of hiding it. Note: the window will still close on player combat."},
	ShowSidePanel={"Use side panel","When the window is collapsed, add a pullout panel to the side to manipulate leveling pets and Auto Load status."},
}

rematch.ReflectSetting = {} -- table of functions to run to reflect changes for defined settings

function rematch:InitializeOptions()
	settings = RematchSettings
	local options = rematch.drawer.options
	options.header.text:SetText("Options")
	options.version:SetText("Rematch version "..GetAddOnMetadata("Rematch","Version"))

	-- go through each checkbutton, set its text and run its reflect
	for setting,opt in pairs(rematch.optionsText) do
		options.checks[setting].text:SetText(opt[1])
		options.checks[setting].tooltip = opt[2]
		options.checks[setting].setting = setting
		options.checks[setting]:SetChecked(settings[setting])
		if rematch.ReflectSetting[setting] then
			rematch.ReflectSetting[setting]()
		end
	end
end

function rematch:OptionsOnShow()
	rematch.saved.header:Hide()
end

function rematch:OptionsOnHide()
	rematch.saved.header:Show()
end

function rematch:RematchOptionsButton()
	rematch.drawer.options:Show()
end

function rematch:CheckButtonOnEnter()
	rematch.drawer.options.tooltip.text:SetText(self.tooltip)
end

function rematch:CheckButtonOnLeave()
	rematch.drawer.options.tooltip.text:SetText("")
end

function rematch:CheckButtonOnClick()
	settings[self.setting] = self:GetChecked()
	if rematch.ReflectSetting[self.setting] then
		rematch.ReflectSetting[self.setting](self)
	end
end

function rematch:RematchOptionsOkayButton()
	rematch.drawer.options:Hide()
end

function rematch.ReflectSetting.AutoLoad()
	local autoMouseover = rematch.drawer.options.checks.AutoMouseover
	local autoLoadAlways = rematch.drawer.options.checks.AutoLoadAlways
	if settings.AutoLoad then
		autoMouseover:Enable()
		autoMouseover.text:SetTextColor(1,.82,0)
		autoLoadAlways:Enable()
		autoLoadAlways.text:SetTextColor(1,.82,0)
	else
		autoMouseover:Disable()
		autoMouseover.text:SetTextColor(.5,.5,.5)
		autoLoadAlways:Disable()
		autoLoadAlways.text:SetTextColor(.5,.5,.5)
	end
	rematch.ReflectSetting.AutoMouseover() -- update whether UPDATE_UNIT_MOUSEOVER should be registered
end

function rematch.ReflectSetting.AutoMouseover()
	rematch.drawer.options.checks.AutoMouseover:SetChecked(settings.AutoMouseover)
	if settings.AutoMouseover and settings.AutoLoad then
		rematch:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
	else
		rematch:UnregisterEvent("UPDATE_MOUSEOVER_UNIT")
	end
end

function rematch.ReflectSetting.LargeWindow()
	-- instead of a straight SetScale, we'll adjust position so it stays at the same
	-- relative position on the screen, growing out/in from the bottomleft corner
	local oldScale = rematch:GetEffectiveScale()
	settings.XPos = rematch:GetLeft()
	settings.YPos = rematch:GetBottom()
	rematch:SetScale(settings.LargeWindow and 1.25 or 1.0)
	local newScale = rematch:GetEffectiveScale()
	settings.XPos = (settings.XPos*oldScale)/newScale
	settings.YPos = (settings.YPos*oldScale)/newScale
	rematch:ClearAllPoints()
	rematch:SetPoint("BOTTOMLEFT",settings.XPos,settings.YPos)
	RematchFloatingPetCard:SetScale(settings.LargeWindow and 1.2 or 1)
end

function rematch.ReflectSetting.BestOfSpecies()
	rematch:SetupBestOfSpecies()
end

function rematch:ToggleAutoLoad()
	local checks = rematch.drawer.options.checks
	checks.AutoLoad:Click()
	if not checks:IsVisible() then
		print("\124cffffff00Rematch Auto Load is now",settings.AutoLoad and "\124cff00ff00Enabled" or "\124cffff0000Disabled")
	end
end
