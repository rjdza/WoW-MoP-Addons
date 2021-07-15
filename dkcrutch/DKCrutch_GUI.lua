-------------------------------------------------------------------------------
-- DKCrutch Gui functions
--
-- GUI functions and structures for DKCrutch
-------------------------------------------------------------------------------

local L = DKCrutch.Locals

function DKCrutch:CreateCheckButton(name, parent, table, field, radio)
	local button
	if radio then
		button = CreateFrame('CheckButton', parent:GetName() .. name, parent, 'SendMailRadioButtonTemplate')
	else
		button = CreateFrame('CheckButton', parent:GetName() .. name, parent, 'OptionsCheckButtonTemplate')
	end
	local frame = _G[button:GetName() .. 'Text']
	frame:SetText(name)
	frame:SetTextColor(1, 1, 1, 1)
	frame:SetFontObject(GameFontNormal)
	button:SetScript("OnShow", 
		function (self) 
			self:SetChecked(table[field]) 
			self.origValue = table[field] or self.origValue
		end 
	)
	if radio then
		button:SetScript("OnClick", 
			function (self, button, down)
				this:SetChecked(1)
				table[field] = not table[field]
			end 
		)
	else
		button:SetScript("OnClick", 
			function (self, button, down) 
				table[field] = not table[field]
			end
		)
	end

	function button:Restore() 
		table[field] = self.origValue 
	end 
	return button 
end

function DKCrutch:CreateSlider(text, parent, low, high, step)
	local name = parent:GetName() .. text
	local slider = CreateFrame('Slider', name, parent, 'OptionsSliderTemplate')
	slider:SetScript('OnMouseWheel', Slider_OnMouseWheel)
	slider:SetMinMaxValues(low, high)
	slider:SetValueStep(step)
	slider:EnableMouseWheel(true)
	_G[name .. 'Text']:SetText(text)
	_G[name .. 'Low']:SetText('')
	_G[name .. 'High']:SetText('')
	local text = slider:CreateFontString(nil, 'BACKGROUND')
	text:SetFontObject('GameFontHighlightSmall')
	text:SetPoint('LEFT', slider, 'RIGHT', 7, 0)
	slider.valText = text
	return slider
end

function DKCrutch:CreateButton(text, parent)
	local name = parent:GetName() .. text
	local button = CreateFrame('Button', name, parent, 'UIPanelButtonTemplate')
	_G[name .. 'Text']:SetText(text)
	local text = button:CreateFontString(nil, 'BACKGROUND')
	text:SetFontObject('GameFontHighlightSmall')
	text:SetPoint('LEFT', button, 'RIGHT', 7, 0)
	button.valText = text
	return button
end

function DKCrutch:CreateDropDownMenu(text, parent, dbTree, varName, itemList, width)
	local name = parent:GetName() .. text
    local menu = CreateFrame("Frame", name, parent, "UIDropDownMenuTemplate");
    menu.displayMode = "MENU"

	local frame = _G[menu:GetName() .. 'Text']
	frame:SetText(text)
	frame:SetTextColor(1, 1, 1, 1)
	frame:SetFontObject(GameFontNormal)

    menu:EnableMouse(true);
    if(width) then
        _G.UIDropDownMenu_SetWidth(menu, width);
    end
    menu.itemList = itemList or {};
    menu.init = function()
            for i=1, #menu.itemList do
                if(not menu.itemList[i].hooked) then
                    local func = menu.itemList[i].func or function(self) end;
                    menu.itemList[i].func = function(self, arg1, arg2)
                        self = self or _G.this; -- wotlk/tbc hack
                        dbTree[varName] = self.value;
                        _G.UIDropDownMenu_SetSelectedValue(menu, self.value);
                        func(self, arg1, arg2);
                    end
                    menu.itemList[i].hooked = true;
                end
                local info = _G.UIDropDownMenu_CreateInfo();
                for k,v in pairs(menu.itemList[i]) do
                    info[k] = v;
                end
                _G.UIDropDownMenu_AddButton(info, _G.UIDROPDOWNMENU_MENU_LEVEL);
            end
        end
    menu:SetScript("OnShow", function(self)
            _G.UIDropDownMenu_Initialize(self, self.init);
            _G.UIDropDownMenu_SetSelectedValue(self, dbTree[varName]);
        end);
    menu.SetValue = function(self, value)
            _G.UIDropDownMenu_SetSelectedValue(self, value);
        end;
    menu:Hide(); menu:Show();
    return menu;
end

function DKCrutch:ApplySettings()
	DKCrutch:InitSettings()
	if (not DKCrutchDB.locked) then
		DKCrutch:UnLockFrames()
	else
		if (DKCrutch.displayFrame) then
			DKCrutch.displayFrame:EnableMouse(false)
			DKCrutch.displayFrame:SetMovable(false)
			DKCrutch.displayFrame:SetBackdropColor(0, 0, 0, .0)
			DKCrutch.advisorFrame:EnableMouse(false)
			DKCrutch.advisorFrame:SetMovable(false)
			DKCrutch.advisorFrame:SetBackdropColor(0, 0, 0, .0)
			DKCrutch.procFrame:EnableMouse(false)
			DKCrutch.procFrame:SetMovable(false)
			DKCrutch.procFrame:SetBackdropColor(0, 0, 0, .0)
			DKCrutch.weaponFrame:EnableMouse(false)
			DKCrutch.weaponFrame:SetMovable(false)
			DKCrutch.weaponFrame:SetBackdropColor(0, 0, 0, .0)
			DKCrutch.runicFrame:EnableMouse(false)
			DKCrutch.runicFrame:SetMovable(false)
			DKCrutch.debuffFrame:EnableMouse(false)
			DKCrutch.debuffFrame:SetMovable(false)
			DKCrutch.swingFrame:EnableMouse(false)
			DKCrutch.swingFrame:SetMovable(false)
		end
	end
	if ( DKCrutchDB.enabled ) then
		DKCrutch.eventFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
		DKCrutch.eventFrame:RegisterEvent("RUNE_POWER_UPDATE")
		DKCrutch.eventFrame:RegisterEvent("RUNE_TYPE_UPDATE")
		DKCrutch.eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
		if (DKCrutch.displayFrame) then
			DKCrutch.displayFrame:Show()
			if (not DKCrutchDB.advisorDisabled) then
				DKCrutch.advisorFrame:Show()
			else
				DKCrutch.advisorFrame:Hide()
			end
			if (not DKCrutchDB.procDisabled) then
				DKCrutch.procFrame:Show()
			else
				DKCrutch.procFrame:Hide()
			end
			if (not DKCrutchDB.runicDisabled) then
				DKCrutch.runicFrame:Show()
			else
				DKCrutch.runicFrame:Hide()
			end
			if (not DKCrutchDB.weaponDisabled) then
				DKCrutch.weaponFrame:Show()
			else
				DKCrutch.weaponFrame:Hide()
			end
			if (not DKCrutchDB.runeDisabled) then
				DKCrutch.displayFrame:Show()
			else
				DKCrutch.displayFrame:Hide()
			end
			if (not DKCrutchDB.swingDisabled) then
				DKCrutch.swingFrame:Show()
			else
				DKCrutch.swingFrame:Hide()
			end
		end
	else
		DKCrutch.eventFrame:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
		DKCrutch.eventFrame:UnregisterEvent("RUNE_POWER_UPDATE")
		DKCrutch.eventFrame:UnregisterEvent("RUNE_TYPE_UPDATE")
		DKCrutch.eventFrame:UnregisterEvent("PLAYER_TARGET_CHANGED")
		if (DKCrutch.displayFrame) then
			DKCrutch.displayFrame:Hide()
			DKCrutch.advisorFrame:Hide()
			DKCrutch.procFrame:Hide()
			DKCrutch.weaponFrame:Hide()
			DKCrutch.runicFrame:Hide()
			DKCrutch.debuffFrame:Hide()
			DKCrutch.swingFrame:Hide()
		end
	end
	if (DKCrutch.displayFrame) then
		DKCrutch.displayFrame:SetAlpha(DKCrutchDB.runes.alpha)
		DKCrutch.displayFrame:SetScale(DKCrutchDB.runes.scale)
		DKCrutch.advisorFrame:SetAlpha(DKCrutchDB.advisor.alpha)
		DKCrutch.advisorFrame:SetScale(DKCrutchDB.advisor.scale)
		DKCrutch.procFrame:SetAlpha(DKCrutchDB.proc.alpha)
		DKCrutch.procFrame:SetScale(DKCrutchDB.proc.scale)
		DKCrutch.weaponFrame:SetAlpha(DKCrutchDB.weapon.alpha)
		DKCrutch.weaponFrame:SetScale(DKCrutchDB.weapon.scale)
		DKCrutch.runicFrame:SetAlpha(DKCrutchDB.runic.alpha)
		DKCrutch.runicFrame:SetScale(DKCrutchDB.runic.scale)
		DKCrutch.debuffFrame:SetAlpha(DKCrutchDB.debuff.alpha)
		DKCrutch.debuffFrame:SetScale(DKCrutchDB.debuff.scale)
		DKCrutch.swingFrame:SetAlpha(DKCrutchDB.swing.alpha or 1)
		DKCrutch.swingFrame:SetScale(DKCrutchDB.swing.scale or 1)
	end
end

function DKCrutch:StoreUIValues()
    for i,v in pairs(DKCrutchDB) do
		DKCrutch.prevDB[i]=v
    end
end

function DKCrutch:ReStoreUIValues()
    for i,v in pairs(DKCrutch.prevDB) do
		DKCrutchDB[i]=v
    end
end

function DKCrutch:CreateConfig()
	DKCrutch.configPanel = CreateFrame( "Frame", "DKCrutchConfigPanel", UIParent );
	-- Register in the Interface Addon Options GUI
	-- Set the name for the Category for the Options Panel
	DKCrutch.configPanel.name = "DKCrutch";
	
	local EnableBtn = DKCrutch:CreateCheckButton(L.CONFIG_ENABLED, DKCrutch.configPanel, DKCrutchDB, "enabled", false)
	EnableBtn:SetPoint('TOPLEFT', 10, -8) 

	local LockBtn = DKCrutch:CreateCheckButton(L.CONFIG_LOCK_FRAMES, DKCrutch.configPanel, DKCrutchDB, "locked", false)
	LockBtn:SetPoint('TOPLEFT', 10, -38) 

	local Scale = DKCrutch:CreateSlider(L.CONFIG_SPELL_ADV_SCALE, DKCrutch.configPanel, .25, 3, .1)
	Scale:SetScript('OnShow', function(self)
		self.onShow = true
		self:SetValue(DKCrutchDB.advisor.scale)
		self.onShow = nil
	end)
	Scale:SetScript('OnValueChanged', function(self, value)
		self.valText:SetText(format('%.1f', value))
		if not self.onShow then
			DKCrutchDB.advisor.scale=value
			DKCrutch.advisorFrame:SetScale(value)
			
		end
	end)
	Scale:SetPoint("TOPLEFT",10,-98)
	Scale:Show()

	local Alpha = DKCrutch:CreateSlider(L.CONFIG_SPELL_ADV_ALPHA, DKCrutch.configPanel, .0, 1, .1)
	Alpha:SetScript('OnShow', function(self)
		self.onShow = true
		self:SetValue(DKCrutchDB.advisor.alpha)
		self.onShow = nil
	end)
	Alpha:SetScript('OnValueChanged', function(self, value)
		self.valText:SetText(format('%.1f', value))
		if not self.onShow then
			DKCrutchDB.advisor.alpha=value
			DKCrutch.advisorFrame:SetAlpha(value)
		end
	end)
	Alpha:SetPoint("TOPLEFT",200,-98)
	Alpha:Show()

	local advisorDisableBtn = DKCrutch:CreateCheckButton(L.CONFIG_DISABLE_ADVISOR, DKCrutch.configPanel, DKCrutchDB, "advisorDisabled", false)
	advisorDisableBtn:SetPoint('TOPLEFT', 10, -118) 

	local RuneScale = DKCrutch:CreateSlider(L.CONFIG_RUNE_TRACKER_SCALE, DKCrutch.configPanel, .25, 3, .1)
	RuneScale:SetScript('OnShow', function(self)
		self.onShow = true
		self:SetValue(DKCrutchDB.runes.scale)
		self.onShow = nil
	end)
	RuneScale:SetScript('OnValueChanged', function(self, value)
		self.valText:SetText(format('%.1f', value))
		if not self.onShow then
			DKCrutchDB.runes.scale=value
			DKCrutch.displayFrame:SetScale(value)
		end
	end)
	RuneScale:SetPoint("TOPLEFT",10,-158)
	RuneScale:Show()

	local RuneAlpha = DKCrutch:CreateSlider(L.CONFIG_RUNE_TRACKER_ALPHA, DKCrutch.configPanel, .0, 1, .1)
	RuneAlpha:SetScript('OnShow', function(self)
		self.onShow = true
		self:SetValue(DKCrutchDB.runes.alpha)
		self.onShow = nil
	end)
	RuneAlpha:SetScript('OnValueChanged', function(self, value)
		self.valText:SetText(format('%.1f', value))
		if not self.onShow then
			DKCrutchDB.runes.alpha=value
			DKCrutch.displayFrame:SetAlpha(value)
		end
	end)
	RuneAlpha:SetPoint("TOPLEFT",200,-158)
	RuneAlpha:Show()
	
	local runeDisableBtn = DKCrutch:CreateCheckButton(L.CONFIG_DISABLE_RUNE, DKCrutch.configPanel, DKCrutchDB, "runeDisabled", false)
	runeDisableBtn:SetPoint('TOPLEFT', 10, -178) 


	local procScale = DKCrutch:CreateSlider(L.CONFIG_PROC_SCALE, DKCrutch.configPanel, .25, 3, .1)
	procScale:SetScript('OnShow', function(self)
		self.onShow = true
		self:SetValue(DKCrutchDB.proc.scale)
		self.onShow = nil
	end)
	procScale:SetScript('OnValueChanged', function(self, value)
		self.valText:SetText(format('%.1f', value))
		if not self.onShow then
			DKCrutchDB.proc.scale=value
			DKCrutch.procFrame:SetScale(value)
		end
	end)
	procScale:SetPoint("TOPLEFT",10,-218)
	procScale:Show()

	local procAlpha = DKCrutch:CreateSlider(L.CONFIG_PROC_ALPHA, DKCrutch.configPanel, .0, 1, .1)
	procAlpha:SetScript('OnShow', function(self)
		self.onShow = true
		self:SetValue(DKCrutchDB.proc.alpha)
		self.onShow = nil
	end)
	procAlpha:SetScript('OnValueChanged', function(self, value)
		self.valText:SetText(format('%.1f', value))
		if not self.onShow then
			DKCrutchDB.proc.alpha=value
			DKCrutch.procFrame:SetAlpha(value)
		end
	end)
	procAlpha:SetPoint("TOPLEFT",200,-218)
	procAlpha:Show()

	local procDisableBtn = DKCrutch:CreateCheckButton(L.CONFIG_DISABLE_PROC, DKCrutch.configPanel, DKCrutchDB, "procDisabled", false)
	procDisableBtn:SetPoint('TOPLEFT', 10, -238) 

	local runicScale = DKCrutch:CreateSlider(L.CONFIG_RUNIC_SCALE, DKCrutch.configPanel, .25, 3, .1)
	runicScale:SetScript('OnShow', function(self)
		self.onShow = true
		self:SetValue(DKCrutchDB.runic.scale)
		self.onShow = nil
	end)
	runicScale:SetScript('OnValueChanged', function(self, value)
		self.valText:SetText(format('%.1f', value))
		if not self.onShow then
			DKCrutchDB.runic.scale=value
			DKCrutch.runicFrame:SetScale(value)
			
		end
	end)
	runicScale:SetPoint("TOPLEFT",10,-278)
	runicScale:Show()

	local runicAlpha = DKCrutch:CreateSlider(L.CONFIG_RUNIC_ALPHA, DKCrutch.configPanel, .0, 1, .1)
	runicAlpha:SetScript('OnShow', function(self)
		self.onShow = true
		self:SetValue(DKCrutchDB.runic.alpha)
		self.onShow = nil
	end)
	runicAlpha:SetScript('OnValueChanged', function(self, value)
		self.valText:SetText(format('%.1f', value))
		if not self.onShow then
			DKCrutchDB.runic.alpha=value
			DKCrutch.runicFrame:SetAlpha(value)
		end
	end)
	runicAlpha:SetPoint("TOPLEFT",200,-278)
	runicAlpha:Show()

	local runicDisableBtn = DKCrutch:CreateCheckButton(L.CONFIG_DISABLE_RUNIC, DKCrutch.configPanel, DKCrutchDB, "runicDisabled", false)
	runicDisableBtn:SetPoint('TOPLEFT', 10, -298) 

	local debuffScale = DKCrutch:CreateSlider(L.CONFIG_DEBUFF_SCALE, DKCrutch.configPanel, .25, 3, .1)
	debuffScale:SetScript('OnShow', function(self)
		self.onShow = true
		self:SetValue(DKCrutchDB.debuff.scale)
		self.onShow = nil
	end)
	debuffScale:SetScript('OnValueChanged', function(self, value)
		self.valText:SetText(format('%.1f', value))
		if not self.onShow then
			DKCrutchDB.debuff.scale=value
			DKCrutch.debuffFrame:SetScale(value)
			
		end
	end)
	debuffScale:SetPoint("TOPLEFT",10,-338)
	debuffScale:Show()

	local debuffAlpha = DKCrutch:CreateSlider(L.CONFIG_DEBUFF_ALPHA, DKCrutch.configPanel, .0, 1, .1)
	debuffAlpha:SetScript('OnShow', function(self)
		self.onShow = true
		self:SetValue(DKCrutchDB.debuff.alpha)
		self.onShow = nil
	end)
	debuffAlpha:SetScript('OnValueChanged', function(self, value)
		self.valText:SetText(format('%.1f', value))
		if not self.onShow then
			DKCrutchDB.debuff.alpha=value
			DKCrutch.debuffFrame:SetAlpha(value)
		end
	end)
	debuffAlpha:SetPoint("TOPLEFT",200,-338)
	debuffAlpha:Show()

	local debuffDisableBtn = DKCrutch:CreateCheckButton(L.CONFIG_DISABLE_DEBUFF, DKCrutch.configPanel, DKCrutchDB, "debuffDisabled", false)
	debuffDisableBtn:SetPoint('TOPLEFT', 10, -358)

	local weaponScale = DKCrutch:CreateSlider(L.CONFIG_WEAPON_SCALE, DKCrutch.configPanel, .25, 3, .1)
	weaponScale:SetScript('OnShow', function(self)
		self.onShow = true
		self:SetValue(DKCrutchDB.weapon.scale)
		self.onShow = nil
	end)
	weaponScale:SetScript('OnValueChanged', function(self, value)
		self.valText:SetText(format('%.1f', value))
		if not self.onShow then
			DKCrutchDB.weapon.scale=value
			DKCrutch.weaponFrame:SetScale(value)
		end
	end)
	weaponScale:SetPoint("TOPLEFT",10,-398)
	weaponScale:Show()

	local weaponAlpha = DKCrutch:CreateSlider(L.CONFIG_WEAPON_ALPHA, DKCrutch.configPanel, .0, 1, .1)
	weaponAlpha:SetScript('OnShow', function(self)
		self.onShow = true
		self:SetValue(DKCrutchDB.weapon.alpha)
		self.onShow = nil
	end)
	weaponAlpha:SetScript('OnValueChanged', function(self, value)
		self.valText:SetText(format('%.1f', value))
		if not self.onShow then
			DKCrutchDB.weapon.alpha=value
			DKCrutch.weaponFrame:SetAlpha(value)
		end
	end)
	weaponAlpha:SetPoint("TOPLEFT",200,-398)
	weaponAlpha:Show()

	local weaponDisableBtn = DKCrutch:CreateCheckButton(L.CONFIG_DISABLE_WEAPON, DKCrutch.configPanel, DKCrutchDB, "weaponDisabled", false)
	weaponDisableBtn:SetPoint('TOPLEFT', 10, -418) 

	local swingScale = DKCrutch:CreateSlider(L.CONFIG_SWING_SCALE, DKCrutch.configPanel, .25, 3, .1)
	swingScale:SetScript('OnShow', function(self)
		self.onShow = true
		self:SetValue(DKCrutchDB.swing.scale)
		self.onShow = nil
	end)
	swingScale:SetScript('OnValueChanged', function(self, value)
		self.valText:SetText(format('%.1f', value))
		if not self.onShow then
			DKCrutchDB.swing.scale=value
			DKCrutch.swingFrame:SetScale(value)
		end
	end)
	swingScale:SetPoint("TOPLEFT",10,-458)
	swingScale:Show()

	local swingAlpha = DKCrutch:CreateSlider(L.CONFIG_SWING_ALPHA, DKCrutch.configPanel, .0, 1, .1)
	swingAlpha:SetScript('OnShow', function(self)
		self.onShow = true
		self:SetValue(DKCrutchDB.swing.alpha)
		self.onShow = nil
	end)
	swingAlpha:SetScript('OnValueChanged', function(self, value)
		self.valText:SetText(format('%.1f', value))
		if not self.onShow then
			DKCrutchDB.swing.alpha=value
			DKCrutch.swingFrame:SetAlpha(value)
		end
	end)
	swingAlpha:SetPoint("TOPLEFT",200,-458)
	swingAlpha:Show()

	local swingDisableBtn = DKCrutch:CreateCheckButton(L.CONFIG_DISABLE_SWING, DKCrutch.configPanel, DKCrutchDB, "swingDisabled", false)
	swingDisableBtn:SetPoint('TOPLEFT', 10, -478) 

	local ResetBtn = DKCrutch:CreateButton(L.CONFIG_RESET_POSITIONS, DKCrutch.configPanel)
	ResetBtn:SetWidth(160)
	ResetBtn:SetHeight(22)
	ResetBtn:SetScript('OnClick', function()
		DKCrutch:ResetPosition()
	end)
	ResetBtn:SetPoint("TOPLEFT",10,-508)
	ResetBtn:Show()
	
	DKCrutch.configPanel.okay = function()
		DKCrutch:ApplySettings()
	end
	DKCrutch.configPanel.cancel = function()
		-- cancel button pressed, revert changes
		DKCrutch:ReStoreUIValues()
		DKCrutch:ApplySettings()
	end
	DKCrutch.configPanel.default = function()
		-- default button pressed, reset setting
		DKCrutch:ResetDB(true)
		DKCrutch:ResetPosition()
	end

	-- always show frame if config panel is open
	DKCrutch.configPanel:SetScript('OnShow', function(self)
		self.onShow = true
		self.onShow = nil
	end)
	DKCrutch.configPanel:SetScript('OnHide', function(self)
		self.onHide = true
		self.onHide = nil
	end)
	-- Fix broken InterfaceOptionsFrame_OpenToCategory function
	-- Bail out if already loaded and up to date
	local MAJOR, MINOR = "InterfaceOptionsFix", 1
	if _G[MAJOR] and _G[MAJOR].version >= MINOR then return end

	-- Reuse the existing frame or create a new one
	local frame = _G[MAJOR] or CreateFrame("Frame", MAJOR, _G.InterfaceOptionsFrame)
	frame.version = MINOR

	-- Hook once and the call the possibly upgraded methods
	if not frame.Saved_InterfaceOptionsFrame_OpenToCategory then
		-- Save the unhooked function
		frame.Saved_InterfaceOptionsFrame_OpenToCategory = _G.InterfaceOptionsFrame_OpenToCategory
		hooksecurefunc("InterfaceOptionsFrame_OpenToCategory", function(...)
			return frame:InterfaceOptionsFrame_OpenToCategory(...)
		end)

		-- Please note that the frame is a child of InterfaceOptionsFrame, so OnUpdate won't called before InterfaceOptionsFrame is shown
		frame:SetScript('OnUpdate', function(_, ...)
			return frame:OnUpdate(...)
		end)
	end

	-- This will be called twice on first open : 
	-- 1) with the panel which is actually wanted,
	-- 2) with the "Control" panel from InterfaceOptionsFrame_OnShow (this is what actually cause the bug). 
	function frame:InterfaceOptionsFrame_OpenToCategory(panel)
		self.panel = panel
	end

	function frame:OnUpdate()
		local panel = self.panel
		
		-- Clean up
		self:SetScript('OnUpdate', nil)
		self:Hide()
		self.panel = nil
		self.InterfaceOptionsFrame_OpenToCategory = function() end

		-- Call the original InterfaceOptionsFrame_OpenToCategory with the last panel
		self.Saved_InterfaceOptionsFrame_OpenToCategory(panel)
	end

	-- Add the panel to the Interface Options
	InterfaceOptions_AddCategory(DKCrutch.configPanel)
end

function DKCrutch:ResetDB()
	if (not DKCrutchDB.runes) or (force) then
		DKCrutchDB.runes = {
			["x"] = -180,
			["y"] = 0,
			["scale"] = 1,
			["alpha"] = 1,
			["relativePoint"] = "CENTER",
		}
	end
	if (not DKCrutchDB.advisor) or (force) then
		DKCrutchDB.advisor = {
			["x"] = 180,
			["y"] = 0,
			["scale"] = 1,
			["alpha"] = 1,
			["relativePoint"] = "CENTER",
		}
	end
	if (not DKCrutchDB.proc) or (force) then
		DKCrutchDB.proc = {
			["x"] = 0,
			["y"] = 90,
			["scale"] = 1,
			["alpha"] = 1,
			["relativePoint"] = "CENTER",
		}
	end
	if (not DKCrutchDB.weapon) or (force) then
		DKCrutchDB.weapon = {
			["x"] = 0,
			["y"] = 122,
			["scale"] = 1,
			["alpha"] = 1,
			["relativePoint"] = "CENTER",
		}
	end
	if (not DKCrutchDB.runic) or (force) then
		DKCrutchDB.runic = {
			["x"] = 90,
			["y"] = 90,
			["scale"] = 1,
			["alpha"] = 1,
			["relativePoint"] = "CENTER",
		}
	end
	if (not DKCrutchDB.debuff) or (force) then
		DKCrutchDB.debuff = {
			["x"] = 0,
			["y"] = 180,
			["scale"] = 1,
			["alpha"] = 1,
			["relativePoint"] = "CENTER",
		}
	end
	if (not DKCrutchDB.swing) or (force) then
		DKCrutchDB.swing = {
			["x"] = -20,
			["y"] = 180,
			["scale"] = 1,
			["alpha"] = 1,
			["relativePoint"] = "CENTER",
		}
	end
	if (force) then
		DKCrutchDB.locked = false
		DKCrutchDB.enabled = true
		DKCrutchDB.advisorDisabled = false
		DKCrutchDB.procDisabled = false
		DKCrutchDB.weaponDisabled = false
		DKCrutchDB.runicDisabled = false
		DKCrutchDB.debuffDisabled = false
		DKCrutchDB.swingDisabled = false
	end
end

function DKCrutch.Options(msg)
	if (msg=='debug') then
		if (DKCrutch.DebugMode) then
			DKCrutch:Debug("Debug ended", GetTime())
		end
		DKCrutch.DebugMode = not ( DKCrutch.DebugMode )
		local debugStatus = "disabled"
		if (DKCrutch.DebugMode) then
			DKCrutch.DebugChat = DKCrutch:GetDebugFrame()
			debugStatus = "enabled. Using frame: " .. DKCrutch.DebugChat:GetID()
			DKCrutch:Debug("Debug started", GetTime())
		end
		DEFAULT_CHAT_FRAME:AddMessage("DKCrutch Debug " .. debugStatus)
	else
		InterfaceOptionsFrame_OpenToCategory(getglobal("DKCrutchConfigPanel"))
	end
end

function DKCrutch:adjustDeathTracker()
	if DKCrutch.deathTracker then
		if (DKCrutch.talent == "frost") then
			DKCrutch.deathTracker:SetStatusBarTexture("Interface\\AddOns\\DKCrutch\\media\\death.tga")
			DKCrutch.deathTracker:SetMinMaxValues(0,20)
		else
			DKCrutch.deathTracker:SetStatusBarTexture("Interface\\AddOns\\DKCrutch\\media\\death4.tga")
			DKCrutch.deathTracker:SetMinMaxValues(0,40)
		end
	end
end

function DKCrutch:ResetPosition()
	DKCrutchDB.runes.x = 0
	DKCrutchDB.runes.y = -100
	DKCrutchDB.runes.relativePoint = "CENTER"
	DKCrutchDB.advisor.x = -100
	DKCrutchDB.advisor.y = 0
	DKCrutchDB.advisor.relativePoint = "CENTER"
	DKCrutchDB.proc.x = 0
	DKCrutchDB.proc.y = 90
	DKCrutchDB.proc.relativePoint = "CENTER"
	DKCrutchDB.weapon.x = 0
	DKCrutchDB.weapon.y = 122
	DKCrutchDB.weapon.relativePoint = "CENTER"
	DKCrutchDB.runic.x = 90
	DKCrutchDB.runic.y = 90
	DKCrutchDB.runic.relativePoint = "CENTER"
	DKCrutchDB.debuff.x = 0
	DKCrutchDB.debuff.y = 180
	DKCrutchDB.debuff.relativePoint = "CENTER"
	DKCrutchDB.swing.x = -20
	DKCrutchDB.swing.y = 180
	DKCrutchDB.swing.relativePoint = "CENTER"

	DKCrutch.displayFrame:ClearAllPoints()
	DKCrutch.displayFrame:SetPoint(DKCrutchDB.runes.relativePoint,DKCrutchDB.runes.x,DKCrutchDB.runes.y)
	DKCrutch.advisorFrame:ClearAllPoints()
	DKCrutch.advisorFrame:SetPoint(DKCrutchDB.advisor.relativePoint,DKCrutchDB.advisor.x,DKCrutchDB.advisor.y)
	DKCrutch.procFrame:ClearAllPoints()
	DKCrutch.procFrame:SetPoint(DKCrutchDB.proc.relativePoint,DKCrutchDB.proc.x,DKCrutchDB.proc.y)
	DKCrutch.weaponFrame:ClearAllPoints()
	DKCrutch.weaponFrame:SetPoint(DKCrutchDB.weapon.relativePoint,DKCrutchDB.weapon.x,DKCrutchDB.weapon.y)
	DKCrutch.debuffFrame:ClearAllPoints()
	DKCrutch.debuffFrame:SetPoint(DKCrutchDB.debuff.relativePoint,DKCrutchDB.debuff.x,DKCrutchDB.debuff.y)
	DKCrutch.swingFrame:ClearAllPoints()
	DKCrutch.swingFrame:SetPoint(DKCrutchDB.swing.relativePoint,DKCrutchDB.swing.x,DKCrutchDB.swing.y)
end

function DKCrutch:MakeDraggable(frame,store)
	frame:Show()
	if (store ~= "runic") then
		frame:SetBackdropColor(0, 0, 0, .3)
	end
	frame:EnableMouse(true)
	frame:SetMovable(true)
	frame:SetClampedToScreen(true)
	frame:SetScript("OnMouseDown", function(self) self:StartMoving(); self:SetBackdropColor(0, 0, 0, .6); end)
	frame:SetScript("OnMouseUp", function(self)
		self:StopMovingOrSizing()
		if (store ~= "runic") then
			if (DKCrutch.locked) then
				self:SetBackdropColor(0, 0, 0, 0)
			else
				self:SetBackdropColor(0, 0, 0, .3)
			end
		end
		local _,_,rp,x,y = self:GetPoint()
		DKCrutchDB[store]["x"] = x
		DKCrutchDB[store]["y"] = y
		DKCrutchDB[store]["relativePoint"] = rp
	end)
	frame:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing();
		if (store ~= "runic") then
			if (DKCrutch.locked) then
				self:SetBackdropColor(0, 0, 0, 0)
			else
				self:SetBackdropColor(0, 0, 0, .3)
			end
		end
		local _,_,rp,x,y = self:GetPoint()
		DKCrutchDB[store]["x"] = x
		DKCrutchDB[store]["y"] = y
		DKCrutchDB[store]["relativePoint"] = rp
	end)
end

function DKCrutch:ShowHideFrames( visible )
	if (visible) then
		DKCrutch.displayFrame:Show();
		DKCrutch.advisorFrame:Show();
		DKCrutch.procFrame:Show();
		DKCrutch.weaponFrame:Show();
		DKCrutch.runicFrame:Show();
		DKCrutch.debuffFrame:Show();
		DKCrutch.swingFrame:Show();
	else
		DKCrutch.displayFrame:Hide();
		DKCrutch.advisorFrame:Hide();
		DKCrutch.procFrame:Hide();
		DKCrutch.weaponFrame:Hide();
		DKCrutch.runicFrame:Hide();
		DKCrutch.debuffFrame:Hide();
		DKCrutch.swingFrame:Hide();
	end
end

function DKCrutch:UnLockFrames()
	DKCrutch:MakeDraggable(DKCrutch.displayFrame,"runes")
	DKCrutch:MakeDraggable(DKCrutch.advisorFrame,"advisor")
	DKCrutch:MakeDraggable(DKCrutch.procFrame,"proc")
	DKCrutch:MakeDraggable(DKCrutch.weaponFrame,"weapon")
	DKCrutch:MakeDraggable(DKCrutch.runicFrame,"runic")
	DKCrutch:MakeDraggable(DKCrutch.debuffFrame,"debuff")
	DKCrutch:MakeDraggable(DKCrutch.swingFrame,"swing")
end

function DKCrutch:CreateGUI()
	local displayFrame = CreateFrame("Frame","DKCrutchDisplayFrame",UIParent)
	displayFrame:SetFrameStrata("BACKGROUND")
	displayFrame:SetWidth(84)
	displayFrame:SetHeight(64)
	displayFrame:SetBackdrop({
          bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", tile = true, tileSize = 32,
	})
	displayFrame:SetBackdropColor(0, 0, 0, .0)
	displayFrame:SetAlpha(DKCrutchDB.runes.alpha)
	displayFrame:SetPoint(DKCrutchDB.runes.relativePoint,DKCrutchDB.runes.x,DKCrutchDB.runes.y)

	displayFrame:SetScript("OnUpdate", function(this, elapsed)
		DKCrutch:OnUpdate(elapsed)
	end)

	local iconTexture = displayFrame:CreateTexture(nil,"BACKGROUND")
	iconTexture:SetTexture("Interface\\AddOns\\DKCrutch\\media\\icons.tga", true)
	iconTexture:SetWidth(16)
	iconTexture:SetHeight(64)
	iconTexture:SetPoint('TOPLEFT',displayFrame,0,0)

	for i=1,3,1 do
		local runes = CreateFrame("StatusBar", nil, displayFrame)
		if (i==1) then
			runes:SetStatusBarTexture("Interface\\AddOns\\DKCrutch\\media\\unholy.tga")
		elseif (i==2) then
			runes:SetStatusBarTexture("Interface\\AddOns\\DKCrutch\\media\\frost.tga")
		elseif (i==3) then
			runes:SetStatusBarTexture("Interface\\AddOns\\DKCrutch\\media\\blood.tga")
		end
		runes:SetWidth(64)
		runes:SetHeight(16)
		runes:SetMinMaxValues(0,20)
		runes:SetPoint('TOPLEFT',displayFrame,20,-i*16)
	
		DKCrutch.runeTracker[i] = runes
	end
	
	local deathRunes = CreateFrame("StatusBar", nil, displayFrame)
	deathRunes:SetStatusBarTexture("Interface\\AddOns\\DKCrutch\\media\\death.tga")
	deathRunes:SetWidth(64)
	deathRunes:SetHeight(16)
	deathRunes:SetMinMaxValues(0,20)
	deathRunes:SetPoint('TOPLEFT',displayFrame,20,0)

	DKCrutch.deathTracker = deathRunes

	DKCrutch.displayFrame = displayFrame

	DKCrutch:adjustDeathTracker()
	
	local advisorFrame = CreateFrame("Frame", "DKCrutchAdvisorFrame", UIParent)
	advisorFrame:SetFrameStrata("BACKGROUND")
	advisorFrame:SetWidth(64)
	advisorFrame:SetHeight(64)
	advisorFrame:SetBackdrop({
          bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", tile = true, tileSize = 32,
	})
	advisorFrame:SetBackdropColor(0, 0, 0, .0)

	local t = advisorFrame:CreateTexture(nil,"BACKGROUND")
	t:SetTexture("")
	t:SetAllPoints(advisorFrame)
	advisorFrame.texture = t
	advisorFrame:SetAlpha(DKCrutchDB.advisor.alpha)
	advisorFrame:SetPoint(DKCrutchDB.advisor.relativePoint,DKCrutchDB.advisor.x,DKCrutchDB.advisor.y)

	local cooldownFrame = CreateFrame("Cooldown","$parent_cooldown", advisorFrame, "CooldownFrameTemplate")
	cooldownFrame:SetHeight(64)
	cooldownFrame:SetWidth(64)
	cooldownFrame:ClearAllPoints()
	cooldownFrame:SetPoint("CENTER", advisorFrame, "CENTER", 0, 0)
	cooldownFrame:SetReverse(false)

	DKCrutch.cooldownFrame = cooldownFrame

	DKCrutch.advisorFrame = advisorFrame

	local procFrame = CreateFrame("Cooldown", "DKCrutchProcFrame", UIParent)
	procFrame:SetFrameStrata("BACKGROUND")
	procFrame:SetWidth(32)
	procFrame:SetHeight(32)
	procFrame:SetBackdrop({
          bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", tile = true, tileSize = 32,
	})
	procFrame:SetBackdropColor(0, 0, 0, .0)

	t = procFrame:CreateTexture(nil,"BACKGROUND")
	t:SetTexture("")
	t:SetAllPoints(procFrame)
	procFrame.texture = t
	procFrame:SetAlpha(DKCrutchDB.proc.alpha)
	procFrame:SetPoint(DKCrutchDB.proc.relativePoint,DKCrutchDB.proc.x,DKCrutchDB.proc.y)

	t = procFrame:CreateFontString("$parent_ProcText","OVERLAY","GameFontHighlightSmallOutline");
	t:SetPoint("BOTTOM",procFrame,"BOTTOM",0,0)
	t:SetAlpha(1)
	t:SetText("")
	
	DKCrutch.procText = t
	DKCrutch.procFrame = procFrame
	
	local weaponFrame = CreateFrame("StatusBar", "DKCrutchWeaponFrame", UIParent)
	weaponFrame:SetFrameStrata("BACKGROUND")
	weaponFrame:SetWidth(64)
	weaponFrame:SetHeight(20)
	weaponFrame:SetBackdrop({
          bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", tile = true, tileSize = 32,
	})
	weaponFrame:SetOrientation("HORIZONTAL")
	weaponFrame:SetMinMaxValues(0, 15)
	weaponFrame:SetValue(0)
	weaponFrame:SetStatusBarTexture("Interface\\AddOns\\DKCrutch\\media\\weapon.tga")
	t = weaponFrame:CreateTexture(nil,"BACKGROUND")
	t:SetTexture("")
	t:SetAllPoints(weaponFrame)
	weaponFrame.texture = t
	weaponFrame:SetAlpha(DKCrutchDB.weapon.alpha)
	weaponFrame:SetPoint(DKCrutchDB.weapon.relativePoint,DKCrutchDB.weapon.x,DKCrutchDB.weapon.y)

	t = weaponFrame:CreateFontString("$parent_WeaponText","OVERLAY","GameFontHighlightSmallOutline");
	t:SetPoint("CENTER",weaponFrame,"CENTER",0,0)
	t:SetAlpha(1)
	t:SetText("")
	
	DKCrutch.weaponText = t
	DKCrutch.weaponFrame = weaponFrame

	local runicFrame = CreateFrame("Frame", "DKCrutchRunicFrame", UIParent)
	runicFrame:SetFrameStrata("BACKGROUND")
	runicFrame:SetWidth(128)
	runicFrame:SetHeight(128)
	runicFrame:SetBackdrop({
          bgFile = "Interface\\AddOns\\DKCrutch\\media\\runic_circle.tga", tile = false, tileSize = 128,
	})

	t = runicFrame:CreateTexture(nil,"MEDIUM")
	t:SetTexture("Interface\\AddOns\\DKCrutch\\media\\runic_power.tga", false)
	t:SetAllPoints(runicFrame)
	t:SetPoint("CENTER", "DKCrutchRunicFrame", "CENTER", 0, 0);
	runicFrame.texture = t
	runicFrame:SetAlpha(DKCrutchDB.runic.alpha)
	runicFrame:SetPoint(DKCrutchDB.runic.relativePoint,DKCrutchDB.runic.x,DKCrutchDB.runic.y)

	DKCrutch.runicFrame = runicFrame

	local bloodFrame = CreateFrame("Frame", "DKCrutchRunicFrame", runicFrame);
	bloodFrame:SetFrameStrata("BACKGROUND");
	bloodFrame:SetAllPoints( runicFrame );
	DKCrutch.bloodFrame = bloodFrame;

	t = bloodFrame:CreateTexture(nil,"MEDIUM")
	t:SetTexture("Interface\\AddOns\\DKCrutch\\media\\blood_charges.tga", false);
	t:SetTexCoord(0, 0.25, 0, 0.25);
	t:SetAllPoints(bloodFrame)
	t:SetPoint("CENTER", "DKCrutchRunicFrame", "CENTER", 0, 0);
	bloodFrame.texture = t

	local debuffFrame = CreateFrame("Frame", "DKCrutchDebuffFrame", UIParent)
	debuffFrame:SetFrameStrata("BACKGROUND")
	debuffFrame:SetWidth(64)
	debuffFrame:SetHeight(32)
	debuffFrame:SetBackdrop({
          bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", tile = true, tileSize = 64,
	})
	debuffFrame:SetBackdropColor(0, 0, 0, .0)

	local d1 = CreateFrame("Cooldown", "DKCrutchDebuff1Frame", DKCrutchDebuffFrame, "CooldownFrameTemplate")
	d1:SetWidth(32)
	d1:SetHeight(32)
	d1:ClearAllPoints()
	d1:SetPoint("TOPLEFT", debuffFrame, "TOPLEFT", 0, 0)
	t = d1:CreateTexture(nil,"MEDIUM")
	t:SetTexture("")
	t:SetAllPoints(d1)
	d1.texture = t

	DKCrutch.debuff1Frame = d1
	
	local d2 = CreateFrame("Cooldown", "DKCrutchDebuff2Frame", DKCrutchDebuffFrame, "CooldownFrameTemplate")
	d2:SetWidth(32)
	d2:SetHeight(32)
	d2:ClearAllPoints()
	d2:SetPoint("TOPRIGHT", debuffFrame, "TOPRIGHT", 0, 0)
	t = d2:CreateTexture(nil,"MEDIUM")
	t:SetTexture("")
	t:SetAllPoints(d2)
	d2.texture = t

	DKCrutch.debuff2Frame = d2

	debuffFrame:SetAlpha(DKCrutchDB.debuff.alpha)
	debuffFrame:SetPoint(DKCrutchDB.debuff.relativePoint,DKCrutchDB.debuff.x,DKCrutchDB.debuff.y)

	DKCrutch.debuffFrame = debuffFrame
	
	local swingFrame = CreateFrame("StatusBar", "DKCrutchSwingFrame", UIParent)
	swingFrame:SetFrameStrata("BACKGROUND")
	swingFrame:SetWidth(128)
	swingFrame:SetHeight(8)
	swingFrame:SetBackdrop({
          bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", tile = true, tileSize = 32,
	})
	swingFrame:SetOrientation("HORIZONTAL")
	swingFrame:SetMinMaxValues(0, 128)
	swingFrame:SetValue(0)
	swingFrame:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
	swingFrame:SetStatusBarColor(0,0,0,1)
	swingFrame:SetAlpha(DKCrutchDB.swing.alpha or 1)
	swingFrame:SetPoint(DKCrutchDB.swing.relativePoint or "CENTER",DKCrutchDB.swing.x or -20,DKCrutchDB.swing.y or 180)

	DKCrutch.swingFrame = swingFrame

	if (not DKCrutchDB.locked) then
		DKCrutch:UnLockFrames()
	end
end
