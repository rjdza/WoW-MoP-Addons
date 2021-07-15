
local rematch = Rematch
local browser = rematch.browser
local roster = rematch.roster
local settings

function rematch:InitializeBrowser()

	settings = RematchSettings

	-- setup list scrollFrame
	local scrollFrame = browser.list.scrollFrame
	scrollFrame.update = rematch.UpdateBrowserList
	scrollFrame.stepSize = 180
	HybridScrollFrame_CreateButtons(scrollFrame, "RematchBrowserListButtonTemplate") -- , 2, 1, "TOPLEFT", "TOPLEFT", 0, 2, "TOP", "BOTTOM")
	local scrollBar = scrollFrame.scrollBar
	scrollBar.doNotHide = true
	scrollBar.trackBG:SetPoint("TOPLEFT",-2,15)
	scrollBar.trackBG:SetPoint("BOTTOMRIGHT",2,-15)
	scrollBar.trackBG:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
	scrollBar.trackBG:SetGradientAlpha("HORIZONTAL",.125,.125,.125,1,.05,.05,.05,1)

	-- when scrolling with the mousewheel, update the card to the new pet under the mouse
	scrollBar:HookScript("OnValueChanged",function(self)
		if MouseIsOver(scrollFrame) then
			local focus = GetMouseFocus()
			local petID = focus and focus.petID
			if petID then
				rematch:ShowFloatingPetCard(petID,focus)
			end
		end
	end)

	-- set texture and position for typebar pet type buttons
	for i=1,10 do
		local button = browser.typeBar.buttons[i]
		button.icon:SetTexture("Interface\\Icons\\Icon_PetFamily_"..PET_TYPE_SUFFIX[i])
		button:SetPoint("BOTTOMLEFT",(i-1)*20+4,5)
	end
	-- set up type/strong/tough "tabs"
	for i=1,3 do
		local tab = browser.typeBar.tabs[i]
		tab:SetPoint("TOPLEFT",i==1 and 6 or i==2 and 60 or 124,-5)
		tab:SetHitRectInsets(0,i==1 and -30 or -45,0,0) -- i==1 and -30 or -45,0,0)
		tab.text:SetText(i==1 and "Type" or i==2 and "Strong" or "Tough")
		tab.text:SetFontObject("GameFontHighlightSmall")
		tab.text:SetPoint("LEFT",tab,"RIGHT",2,0)
		tab:SetScript("OnClick",rematch.TypeBarTabOnClick)
	end

end

function rematch:UpdateBrowserPosition()
	browser:SetShown((settings.browserOpen and not rematch.journalOpen)and rematch.drawer:IsVisible())
	browser:ClearAllPoints()
	if rematch.toggle:GetRight()*rematch.toggle:GetEffectiveScale() < (UIParent:GetWidth()*UIParent:GetEffectiveScale())/2 then
		browser:SetPoint("BOTTOMLEFT",rematch,"BOTTOMRIGHT",-3,0)
	else
		browser:SetPoint("BOTTOMRIGHT",rematch,"BOTTOMLEFT",3,0)
	end
end

-- this is for the key binding: toggle whole window with browser
function rematch:ToggleBrowser()
	if rematch:IsVisible() and rematch.browser:IsVisible() then
		rematch:Hide()
	else
		rematch:RematchBrowserButton()
	end
end

-- when hitting the Pets button on main window, if collapsed always open browser.
-- if drawer open, toggle browser
function rematch:RematchBrowserButton()
	local showBrowser
	if not browser:IsVisible() and PetJournal and PetJournal:IsVisible() then
		HideUIPanel(PetJournalParent)
		showBrowser = true
	end
	if not rematch:IsVisible() then
		rematch:Toggle()
		showBrowser = true
	end
	if not InCombatLockdown() then
		if not rematch.drawer:IsVisible() then
			settings.browserOpen = true
			rematch:ToggleDrawer()
		else
			settings.browserOpen = showBrowser or not settings.browserOpen
			rematch:UpdateBrowserPosition()
		end
	end
end

function rematch:BrowserOnShow()
	if PetJournal and PetJournal:IsVisible() then
		HideUIPanel(PetJournalParent)
	end
	rematch:HideFloatingPetCard(true)

	if not browser.filterMenu then
		browser.filterMenu = CreateFrame("Frame","RematchBrowserFilterDropDown",browser.filterButton,"UIDropDownMenuTemplate")
		UIDropDownMenu_Initialize(browser.filterMenu,rematch.BrowserFilterDropDownMenu,"MENU")
	end

	C_PetJournal.ClearSearchFilter() -- clear live search
	C_PetJournal.SetFlagFilter(LE_PET_JOURNAL_FLAG_FAVORITES,false) -- clear live favorites
	rematch:ClearSearchBox()
	roster:SetTypeMode(1)
	roster:ClearTypeFilters(true)
	roster:ClearRarityFilters()
	roster:SetCurrentZoneFilter(nil)
	roster:SetFavoriteFilter(nil)
	rematch:BrowserScrollToTop()
	rematch:UpdateBrowser()
end

function rematch:ClearSearchBox()
	local searchBox = Rematch.browser.searchBox
	searchBox:SetText("")
	searchBox:GetScript("OnEditFocusLost")(searchBox)
end

function rematch:UpdateBrowser()
	if browser:IsVisible() then
		roster:Update()
		rematch:UpdateBrowserList()
		rematch:UpdateTypeBar()
		rematch:UpdateBrowserResults()
	end
end

-- this updates the HybridScrollFrame with roster's pets, the big list of pets
function rematch:UpdateBrowserList()
	local numData = roster:GetNumPets()
	local scrollFrame = browser.list.scrollFrame
	local offset = HybridScrollFrame_GetOffset(scrollFrame)
	local buttons = scrollFrame.buttons
	local isBreedable = IsAddOnLoaded("BattlePetBreedID")
	for i=1, #buttons do
		local index = i + offset
		local button = buttons[i]
		button.index = index
		if ( index <= numData) then
			button:SetID(index)
			button.favorite:Hide()
			button.dead:Hide()
			local petID = roster:GetPetByIndex(index)
			button.petID = petID
			if type(petID)=="string" then -- an owned petID
				local speciesID,customName,level,_,_,_,favorite,speciesName,icon,petType = C_PetJournal.GetPetInfoByPetID(petID)
				button.name:SetText(customName or speciesName)
				button.icon:SetTexture(icon)
				button.level:SetText(level)
				button.type:SetTexture("Interface\\PetBattles\\PetIcon-"..PET_TYPE_SUFFIX[petType])
				if favorite then
					button.favorite:Show()
				end
				local health,maxHealth,_,_,rarity = C_PetJournal.GetPetStats(petID)
		    local r,g,b = ITEM_QUALITY_COLORS[rarity-1].r, ITEM_QUALITY_COLORS[rarity-1].g, ITEM_QUALITY_COLORS[rarity-1].b
		    button.rarity:SetGradientAlpha("VERTICAL",r,g,b,1,r,g,b,0)
		    button.rarity:Show()
				if health<1 and maxHealth>0 then
					button.dead:Show()
				end
		    button.icon:SetDesaturated(0)
		    button.type:SetDesaturated(0)
		    button.name:SetTextColor(1,.82,.2)
				button.leveling:SetShown(rematch:IsPetLeveling(petID))
				if isBreedable then
					button.breed:SetText(GetBreedID_Journal(petID) or "")
					button.name:SetPoint("BOTTOMRIGHT",-24,2)
				else
					button.breed:SetText("")
					button.name:SetPoint("BOTTOMRIGHT",-8,2)
				end
			elseif type(petID)=="number" then -- an unowned species
				local name,icon,petType = C_PetJournal.GetPetInfoBySpeciesID(petID)
				button.name:SetText(name)
				button.icon:SetTexture(icon)
				button.level:SetText("")
				button.type:SetTexture("Interface\\PetBattles\\PetIcon-"..PET_TYPE_SUFFIX[petType])
				button.favorite:Hide()
				button.leveling:Hide()
		    button.rarity:Hide()
		    button.icon:SetDesaturated(1)
		    button.type:SetDesaturated(1)
		    button.name:SetTextColor(.8,.8,.8)
				button.breed:SetText("")
				button.name:SetPoint("BOTTOMRIGHT",-8,2)
			end
			button:Show()
		else
			button:Hide()
		end

	end
	HybridScrollFrame_Update(scrollFrame, 30*numData, 30)

	-- possible fix for bug reported http://www.warcraftpets.com/community/forum/viewtopic.php?f=3&t=9205&start=80#p78632
	-- i can't reproduce it. the hybridscrollframe is supposed to reset itself when its height is less than range
	if not scrollFrame.scrollBar:IsEnabled() and HybridScrollFrame_GetOffset(scrollFrame)~=0 then
		rematch:BrowserScrollToTop()
	end
end

function rematch:BrowserScrollToTop()
	local scrollFrame = rematch.browser.list.scrollFrame
	HybridScrollFrame_SetOffset(scrollFrame,0)
	scrollFrame.scrollBar:SetValue(0)
end

function rematch:BrowserPetOnEnter()
	if self.petID and not rematch.disableOnEnters then
		rematch:ShowFloatingPetCard(self.petID,self)
	end
end

function rematch:BrowserPetOnLeave()
	rematch:HideFloatingPetCard()
end

function rematch:BrowserPetOnDrag()
	if self.petID then
		C_PetJournal.PickupPet(self.petID)
	end
end

function rematch:BrowserPetOnClick(button)
	if button=="RightButton" and self.petID then
		rematch.dropDownPetID = self.petID
		rematch.dropDownPetSlot = nil
		rematch:ShowDropDown(5)
	else
		local cardID = RematchFloatingPetCard.petID

		if IsModifiedClick("CHATLINK") and type(cardID)=="string" then
			ChatEdit_InsertLink(C_PetJournal.GetBattlePetLink(cardID))
			return
		end

		rematch:LockFloatingPetCard()
		if self.petID ~= cardID then
			rematch:ShowFloatingPetCard(self.petID,self)
			rematch:LockFloatingPetCard() -- lock it again
		end
	end
end

function rematch:BrowserPetOnDoubleClick(button)
	if self.petID then
		C_PetJournal.SummonPetByGUID(self.petID)
		rematch:HideFloatingPetCard(true)
	end
end

--[[ Type Bar ]]

function rematch:ToggleTypeBar()
	settings.UseTypeBar = not settings.UseTypeBar
	rematch:UpdateTypeBar()
end

function rematch:UpdateTypeBar()
	local typeBar = browser.typeBar
	if settings.UseTypeBar then -- show typeBar

		browser.toggle:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollUp-Up")
		browser.toggle:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollUp-Down")
		browser.list:SetPoint("TOPLEFT",typeBar,"BOTTOMLEFT")

		-- update type/strong/tough tabs
		for i=1,3 do
			if roster:GetTypeMode()==i then
				typeBar.tabs[i]:SetChecked(true)
				typeBar.tabs[i].text:SetTextColor(1,.82,0)
			else
				typeBar.tabs[i]:SetChecked(false)
				typeBar.tabs[i].text:SetTextColor(.9,.9,.9)
			end
		end
		-- update 10 type buttons
		local typesClear = roster:IsTypeFiltersClear()
		typeBar.clear:SetShown(not typesClear)
		for i=1,10 do
			local isChecked = roster:GetTypeFilter(i)
			typeBar.buttons[i].icon:SetDesaturated(not (isChecked or typesClear))
			typeBar.buttons[i]:SetChecked(isChecked)
		end
		typeBar:Show()

	else -- hide typeBar
		browser.toggle:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Up")
		browser.toggle:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Down")
		browser.list:SetPoint("TOPLEFT",browser,"TOPLEFT",7,-28)
		typeBar:Hide()
	end

end

function rematch:BrowserTypeButtonOnClick()
	roster:SetTypeFilter(self:GetID(),self:GetChecked())
	rematch:UpdateBrowser()
end

function rematch:TypeBarClearOnClick()
	roster:ClearTypeFilters(true)
	rematch:UpdateBrowser()
end

function rematch:TypeBarTabOnClick()
	self:SetChecked(true)
	roster:SetTypeMode(self:GetID())
	rematch:UpdateBrowser()
end

function rematch:SearchBoxOnTextChanged()
	roster:SetSearch(self:GetText())
	rematch:UpdateBrowser()
end

--[[ Filter button UIDropDownMenu context menu ]]

-- generic func for dropdown option clicks
function rematch:ProcessDropDownOption(arg1,arg2,value)
	if self.value==COLLECTED then -- Collected
		C_PetJournal.SetFlagFilter(LE_PET_JOURNAL_FLAG_COLLECTED,value)
		if (value) then
			UIDropDownMenu_EnableButton(1,2)
		else
			UIDropDownMenu_DisableButton(1,2)
		end
	elseif self.value==FAVORITES_FILTER then -- Only Favorites
		roster:SetFavoriteFilter(value)
	elseif self.value==NOT_COLLECTED then -- Not Collected
		C_PetJournal.SetFlagFilter(LE_PET_JOURNAL_FLAG_NOT_COLLECTED,value)
	elseif self.value=="Current Zone" then
		roster:SetCurrentZoneFilter(value)
	elseif self.value==CHECK_ALL then -- Sources->Check All
		C_PetJournal.AddAllPetSourcesFilter()
		UIDropDownMenu_Refresh(browser.filterMenu,2,2)
	elseif self.value==UNCHECK_ALL then -- Sources->Uncheck All
		C_PetJournal.ClearAllPetSourcesFilter()
		UIDropDownMenu_Refresh(browser.filterMenu,2,2)
	elseif self.value==RESET and UIDROPDOWNMENU_MENU_LEVEL==3 then -- Reset on any of the three type menus
		roster:ClearTypeFilters(true)
		UIDropDownMenu_Refresh(browser.filterMenu,3,3)
	elseif self.value==RESET and UIDROPDOWNMENU_MENU_VALUE==4 then -- rarity filter
		roster:ClearRarityFilters()
		UIDropDownMenu_Refresh(browser.filterMenu,4,2)
	elseif self.value=="Reset All" then
		rematch:ResetAllBrowserFilters()
		rematch:HideDropDown()
	else
--		print(self.value,UIDROPDOWNMENU_MENU_LEVEL,UIDROPDOWNMENU_MENU_VALUE)
		return
	end
	rematch:UpdateBrowser()
end

-- source filter menu clicks
function rematch:ProcessDropDownSource(_,_,value)
	C_PetJournal.SetPetSourceFilter(self.value,value)
	rematch:UpdateBrowser()
end
function rematch:CheckedDropDownSource(_,_,value)
	return not C_PetJournal.IsPetSourceFiltered(self.value)
end

-- type mode filter menu clicks
function rematch:ProcessDropDownTypeMode(_,_,value)
	roster:SetTypeMode(self.value)
	UIDropDownMenu_Refresh(browser.filterMenu,2,2)
	rematch:UpdateBrowser()
end
function rematch:CheckedDropDownTypeMode(_,_,value)
	return self.value == roster:GetTypeMode()
end

-- pet type filter menu clicks
function rematch:ProcessDropDownTypeFilter(_,_,value)
	if UIDROPDOWNMENU_MENU_VALUE ~= roster:GetTypeMode() then
		roster:SetTypeMode(UIDROPDOWNMENU_MENU_VALUE)
	end
	roster:SetTypeFilter(self.value,value)
	rematch:UpdateBrowser()
	UIDropDownMenu_Refresh(browser.filterMenu,2,2)
end
function rematch:CheckedDropDownTypeFilter(_,_,value)
	if UIDROPDOWNMENU_MENU_VALUE==roster:GetTypeMode() and not roster:IsTypeFiltersClear() then
		return roster:GetTypeFilter(self.value)
	end
end

function rematch:ProcessDropDownRarityFilter(_,_,value)
	roster:SetRarityFilter(self.value,value)
	rematch:UpdateBrowser()
end
function rematch:CheckedDropDownRarityFilter(_,_,value)
	return roster:GetRarityFilter(self.value)
end

-- sort filter menu clicks
function rematch:ProcessDropDownSort(_,_,value)
	C_PetJournal.SetPetSortParameter(self.value)
	UIDropDownMenu_Refresh(browser.filterMenu,2,2)
	rematch:UpdateBrowser()
end
function rematch:CheckedDropDownSort(_,_,value)
	return C_PetJournal.GetPetSortParameter() == self.value
end

function rematch:ProcessDropDownUseTypeBar(_,_,value)
	settings.UseTypeBar = value
	rematch:UpdateBrowser()
end
function rematch:CheckedDropDownUseTypeBar(_,_,value)
	return settings.UseTypeBar
end

function rematch:BrowserFilterDropDownMenu(level,menuList)

	local info = UIDropDownMenu_CreateInfo()
	info.keepShownOnClick = true
	info.isNotRadio = true

	if (level or 1) == 1 then -- toplevel: collected/favorites/not collected/current zone/families>/sources>/rarity>/sort>

		info.text = COLLECTED
		info.func = rematch.ProcessDropDownOption
		info.checked = not C_PetJournal.IsFlagFiltered(LE_PET_JOURNAL_FLAG_COLLECTED);
		UIDropDownMenu_AddButton(info,level)
		info.text = FAVORITES_FILTER
		info.leftPadding = 8
		info.checked = roster:GetFavoriteFilter()
		UIDropDownMenu_AddButton(info,level)
		info.text = NOT_COLLECTED
		info.leftPadding = nil
		info.checked = not C_PetJournal.IsFlagFiltered(LE_PET_JOURNAL_FLAG_NOT_COLLECTED)
		UIDropDownMenu_AddButton(info,level)

		info.text = "Current Zone"
		info.checked = roster.GetCurrentZoneFilter
		UIDropDownMenu_AddButton(info,level)

		info.notCheckable = true
		info.func = nil
		info.hasArrow = true

		info.text = PET_FAMILIES
		info.value = 1
		UIDropDownMenu_AddButton(info,level)

		info.text = SOURCES
		info.value = 2
		UIDropDownMenu_AddButton(info,level)

		info.text = RARITY
		info.value = 4
		UIDropDownMenu_AddButton(info,level)

		info.text = RAID_FRAME_SORT_LABEL
		info.value = 3
		UIDropDownMenu_AddButton(info,level)

		info.hasArrow = nil
		info.text = "Reset All"
		info.value = nil
		info.func = rematch.ProcessDropDownOption
		UIDropDownMenu_AddButton(info,level)

	elseif level==2 then

		if UIDROPDOWNMENU_MENU_VALUE == 1 then -- Pet Families

			info.hasArrow = true
			info.isNotRadio = nil

			info.text = "Pet Type"
			info.value = 1
			info.func = rematch.ProcessDropDownTypeMode
			info.checked = rematch.CheckedDropDownTypeMode
			UIDropDownMenu_AddButton(info,level)
			info.text = "Strong vs"
			info.value = 2
			UIDropDownMenu_AddButton(info,level)
			info.text = "Tough vs"
			info.value = 3
			UIDropDownMenu_AddButton(info,level)

			info.text = "Use Type Bar"
			info.func = rematch.ProcessDropDownUseTypeBar
			info.checked = rematch.CheckedDropDownUseTypeBar
			info.hasArrow = nil
			info.notCheckable = nil
			info.isNotRadio = true
			UIDropDownMenu_AddButton(info,level)

		elseif UIDROPDOWNMENU_MENU_VALUE == 2 then -- Sources

			info.notCheckable = true

			info.func = rematch.ProcessDropDownOption
			info.text = CHECK_ALL
			UIDropDownMenu_AddButton(info, level)

			info.text = UNCHECK_ALL
			UIDropDownMenu_AddButton(info, level)

			info.notCheckable = false
			info.func = rematch.ProcessDropDownSource
			info.checked = rematch.CheckedDropDownSource
			local numSources = C_PetJournal.GetNumPetSources()
			for i=1,numSources do
				info.text = _G["BATTLE_PET_SOURCE_"..i]
				info.value = i
				UIDropDownMenu_AddButton(info,level)
			end

		elseif UIDROPDOWNMENU_MENU_VALUE == 3 then -- Sort

			info.isNotRadio = nil
			info.func = rematch.ProcessDropDownSort
			info.checked = rematch.CheckedDropDownSort

			info.text = NAME
			info.value = LE_SORT_BY_NAME
			UIDropDownMenu_AddButton(info,level)

			info.text = LEVEL
			info.value = LE_SORT_BY_LEVEL
			UIDropDownMenu_AddButton(info,level)

			info.text = RARITY
			info.value = LE_SORT_BY_RARITY
			UIDropDownMenu_AddButton(info,level)

			info.text = TYPE
			info.value = LE_SORT_BY_PETTYPE
			UIDropDownMenu_AddButton(info,level)

		elseif UIDROPDOWNMENU_MENU_VALUE == 4 then -- Rarity

			info.isNotRadio = true
			info.notCheckable = false
			info.func = rematch.ProcessDropDownRarityFilter
			info.checked = rematch.CheckedDropDownRarityFilter

			for i=1,4 do
				info.text = _G["BATTLE_PET_BREED_QUALITY"..i]
				info.colorCode = "\124c"..select(4,GetItemQualityColor(i-1))
				info.value = i
				UIDropDownMenu_AddButton(info,level)
			end

			info.notCheckable = true
			info.text = RESET
			info.colorCode = nil
			info.value = nil
			info.func = rematch.ProcessDropDownOption
			UIDropDownMenu_AddButton(info,level)

		end

	elseif level==3 then -- Pet Families submenu (the 10 pet types)

		info.notCheckable = true

		if UIDROPDOWNMENU_MENU_VALUE==1 then
			info.text = "Pet Type"
		elseif UIDROPDOWNMENU_MENU_VALUE==2 then
			info.text = "Strong vs"
		else
			info.text = "Tough vs"
		end
		info.isTitle = true
		UIDropDownMenu_AddButton(info,level)

		info.isTitle = nil
		info.disabled = nil
		info.notCheckable = nil

		for i=1,C_PetJournal.GetNumPetTypes() do
			info.text = _G["BATTLE_PET_NAME_"..i]
			info.value = i
			info.func = rematch.ProcessDropDownTypeFilter
			info.checked = rematch.CheckedDropDownTypeFilter
			UIDropDownMenu_AddButton(info,level)
		end

		info.text = RESET
		info.value = nil
		info.notCheckable = true
		info.func = rematch.ProcessDropDownOption
		UIDropDownMenu_AddButton(info,level)

	end
end

--[[ Results bar ]]

function rematch:UpdateBrowserResults()
	local bar = browser.resultsBar
	bar.count:SetText(format("Pets: \124cffffffff%d",roster:GetNumPets()))
	local filters = roster:GetFilterResults()
	if filters then
		bar.owned:Hide()
		bar.filters:SetText(filters)
		bar.filters:Show()
		bar.filterClear:Show()
	else
		bar.filters:Hide()
		bar.filterClear:Hide()
		bar.owned:SetText(format("Owned: \124cffffffff%d",select(2,C_PetJournal.GetNumPets())))
		bar.owned:Show()
	end
end

function rematch:ResetAllBrowserFilters()
	rematch:HideDropDown()
	roster:ClearAllFilters()
	rematch:ClearSearchBox()
	rematch:BrowserScrollToTop()
end
