local rematch = Rematch
local settings -- RematchSettings global settings savedvar
local savedTeams -- RematchSaved global saved teams savedvar

rematch.info = {} -- reusable generic table (to reduce table/garbage creation)
rematch.abilityList = {} -- reusable table for GetPetAbilityList
rematch.levelList = {} -- reusable table for GetPetABilityList
rematch.selectedTeam = nil -- team currently selected (to be displayed in saved window)
rematch.escFrame = nil -- frame currently ESCable
rematch.tempTeamName = nil -- at times we need to create temporary teams, store them in savedTeams["~temp~"] and name them in this variable
rematch.oldDropDownInit = nil -- will be the pet menu initialization function (PetJournalPetOptionsMenu or PetJournalEnhancedPetMenu)
rematch.emptyPetID = "0x0000000000000000" -- petID to load for an empty slot
rematch.petsNotLoaded = true -- changes to nil after pets are loaded on login/reload

BINDING_HEADER_REMATCH = "Rematch"

rematch:SetScript("OnEvent",function(self,event,...)
	if self[event] then
		self[event](self,...)
	end
end)

function rematch:PLAYER_LOGIN()
	rematch:InitializeSavedVars()
	rematch:InitializeMain()
	rematch:InitializeOptions()
	rematch:InitializeCurrent()
	rematch:InitializeSaved()
	rematch:InitializeDrawer()
	rematch:InitializeLeveling()
	rematch:InitializePetLoading()
	rematch:InitializeConfirm()
	rematch:InitializeShare()
	rematch:InitializeBrowser()
end

function rematch:InitializeMain()
	rematch.petheal.icon:SetTexture((GetSpellTexture(125439)))
	rematch.bandage.icon:SetTexture(GetItemIcon(86143))
	rematch:RegisterEvent("PLAYER_TARGET_CHANGED")
	rematch:RegisterEvent("PLAYER_REGEN_DISABLED") -- to close rematch when entering combat
	rematch:RegisterEvent("PLAYER_REGEN_ENABLED") -- to resume target watching when leaving combat
	rematch:RegisterEvent("UPDATE_SUMMONPETS_ACTION")
	rematch:RegisterEvent("PET_JOURNAL_LIST_UPDATE")
	-- pet journal stuff needs to wait until it loads
	if IsAddOnLoaded("Blizzard_PetJournal") then
		rematch:ADDON_LOADED("Blizzard_PetJournal") -- another addon forced a load, run the event manually
	else
		rematch:RegisterEvent("ADDON_LOADED")
	end

	-- dropdown menu for various pet options
	rematch.dropDownFrame = CreateFrame("Frame","RematchSharedDropDown",rematch,"UIDropDownMenuTemplate")
	rematch.dropDownMenu = {} -- contents of the dropdown menu
	rematch.dropDownPetID = nil -- will be petID for the dropdown func to act upon
	DropDownList1:HookScript("OnHide",function(self)
		-- mouse goes all over the place when menu is open; opening a menu sets a flag to disable OnEnters
		-- when an area wants (browser mostly), and menu going away will restore OnEnter soon after
		if UIDROPDOWNMENU_OPEN_MENU==rematch.dropDownFrame then
			rematch:StartTimer("EnableOnEnters",0.1,function() rematch.disableOnEnters=nil end)
		end
	end)


	rematch:SetScale(settings.LargeWindow and 1.25 or 1)

	rematch:ClearAllPoints()
	rematch:SetPoint("BOTTOMLEFT",settings.XPos,settings.YPos)

	hooksecurefunc(C_PetJournal,"CagePetByID",rematch.CagePetByID)

	SlashCmdList["REMATCH"] = rematch.SlashHandler
	SLASH_REMATCH1 = "/rematch"

	rematch.breedable = IsAddOnLoaded("BattlePetBreedID")

end

function rematch.SlashHandler(msg)
	msg = (msg or ""):lower()
	if msg=="reset" then
		local wasVisible = rematch:IsVisible()
		rematch:Hide()
		for setting,opt in pairs(rematch.optionsText) do
			rematch.drawer.options.checks[setting]:SetChecked(0) -- wipe checks
		end
		wipe(settings)
		rematch:SetScale(1)
		rematch:ClearAllPoints()
		rematch:SetPoint("CENTER")
		rematch:InitializeSavedVars()
		rematch:InitializeMain()
		rematch:SetShown(wasVisible)
		print("\124cffff8800Rematch is now reset to default settings.")
	elseif msg=="help" then
		print("\124cffff8800Rematch v"..GetAddOnMetadata("Rematch","Version"))
		print("\124cffffd200/rematch reset\124cffffffff : reset settings and position")
		print("\124cffffd200/rematch import\124cffffffff : copy PetBattleTeams teams if PBT is enabled")
		print("\124cffffd200/rematch import over\124cffffffff : import & overwrite teams of the same name")
	elseif msg=="migrate" or msg:match("^import") then
		rematch:MigratePBT(msg:match("over"))
	else
		rematch:Toggle()
	end
end

function rematch:InitializeSavedVars()
	RematchSettings = RematchSettings or {}
	settings = RematchSettings
	RematchSaved = RematchSaved or {}
	savedTeams = RematchSaved

	-- from 1.x to 2.0.3: move settings out to a separate variable
	savedTeams.Settings = nil
	-- 2.0.6: KeepFirst depreciated, replaced by Keep[1] Keep[2] and Keep[3]
	settings.KeepFirst = nil
	-- 2.1.3: Create LevelingQueue if one doesn't exist
	settings.LevelingQueue = settings.LevelingQueue or {}
	-- 2.2.0: one ~temp~ team now used
	savedTeams["~temp~"] = savedTeams["~temp~"] or {{},{},{}}
	settings.XPos = settings.XPos or rematch:GetLeft()
	settings.YPos = settings.YPos or rematch:GetBottom()
	-- 2.2.2: LastTeamTableLoaded to note what team was loaded (to go with LastTeamNameLoaded)
	settings.LastTeamTableLoaded = settings.LastTeamTableLoaded or {{},{},{}}

	settings.backup224 = nil -- remove the team backups made for 2.2.4 update
	settings.problemWith224 = nil
end

function rematch:UPDATE_SUMMONPETS_ACTION()
	local oldPetID = rematch:GetLevelingPetID()
	rematch:ProcessLevelingQueue()
	rematch:UpdateWindow() -- UpdateCurrentPets()
	local newPetID = rematch:GetLevelingPetID()
	if oldPetID and newPetID and oldPetID~=newPetID then -- if leveling pet changes, toast new leveling pet
		rematch:ToastNextLevelingPet(newPetID)
	end
end

function rematch:PLAYER_REGEN_DISABLED()
	rematch:UnregisterEvent("PLAYER_TARGET_CHANGED")
	if rematch:IsVisible() then
		rematch.returnAfterCombat = settings.LockWindow -- come back after combat if LockWindow set
		rematch:Hide()
	end
end

function rematch:PLAYER_REGEN_ENABLED()
	rematch:RegisterEvent("PLAYER_TARGET_CHANGED")
	if rematch.returnAfterCombat then
		rematch:Show()
		rematch.returnAfterCombat = nil
	end
	if rematch.preLoadCompanion then
		rematch:RestoreCompanion()
	end
	if rematch.queueNeedsProcessed then
		rematch:ProcessLevelingQueue()
		rematch.queueNeedsProcessed = nil
	end
end

-- when pets finish loading on login, go through all teams and validate them
-- after pets are loaded, this event updates the browser (carefully avoiding triggering another LIST_UPDATE)
function rematch:PET_JOURNAL_LIST_UPDATE()
--	print("PET_JOURNAL_LIST_UPDATE")
	if rematch.petsNotLoaded then
		local _,owned = C_PetJournal.GetNumPets()
		if owned and owned>0 then
			rematch.petsNotLoaded = nil
			for teamName,team in pairs(savedTeams) do
				rematch:ValidateTeam(team)
			end
		end
	else
		rematch:UpdateBrowser()
	end
end

-- registered only while window shown: hide window
function rematch:PET_BATTLE_OPENING_START()
	if not settings.StayForBattle then
		rematch:Hide()
		rematch.returnAfterBattle = 1
		rematch:RegisterEvent("PET_BATTLE_OVER")
	end
end

-- registered if a queue tries to process during a pet battle, if a team tries to load during battle,
-- or the window was up when battle started (so it can return afterwards)
function rematch:PET_BATTLE_OVER()
	rematch:UnregisterEvent("PET_BATTLE_OVER")
	rematch:ProcessLevelingQueue()
	if rematch.reloadTeamName then
		rematch:LoadPets(rematch.reloadTeamName)
	end
	if rematch.returnAfterBattle then
		rematch:Show()
		rematch.returnAfterBattle = nil
	end
end

function rematch:Toggle()
	if InCombatLockdown() then
		print("\124cffff8800You're in combat. Blizzard has restrictions on what we can do with pets during combat. Try again when you're out of combat. Sorry!")
	else
		rematch:SetShown(not rematch:IsVisible())
	end
end

function rematch:FrameStartMoving()
	if not settings.LockWindow or IsShiftKeyDown() then
		rematch.isMoving = true
		rematch:StartMoving()
	end
end

function rematch:FrameStopMoving()
	if rematch.isMoving then
		rematch.isMoving = nil
		rematch:StopMovingOrSizing()
		settings.XPos,settings.YPos = rematch:GetLeft(),rematch:GetBottom()
		if settings.ShowSidePanel then
			rematch:UpdateSidePanel()
		end
		rematch:UpdateBrowserPosition()
	end
end

--[[ OnShows/OnHides ]]

function rematch:OnShow()
	rematch:UpdateTargetedInfo()
	rematch:UpdateWindow()
	rematch:WatchForChangingPets()
	rematch:UpdateHealButtons()
	rematch:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
	rematch:RegisterEvent("BAG_UPDATE")
	rematch:RegisterEvent("PET_BATTLE_OPENING_START")
end

function rematch:OnHide()
	rematch:UnregisterEvent("PET_BATTLE_OPENING_START")
	rematch:UnregisterEvent("BAG_UPDATE")
	rematch:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED")
	rematch:HideFloatingPetCard(true)
	rematch:HideAbilityFlyout()
	RematchConfirm:Hide()
	rematch.drawer.help:Hide()
	rematch.drawer.options:Hide()
	rematch.saveAs:Hide()
	rematch.drawer.share:Hide()
	rematch.alreadyShown = nil
end

--[[ ESCable system

	ESC is heavily supported to go back panels. If the window and drawer are not locked, and the
	user is looking at options, esc will return from options to drawer, esc again will collapse
	the drawer, and esc again will close the window entirely.

	Only one frame can be ESCable at a time.

	Remember:
	- a frame's OnHide runs when its parent is hidden too
	- remember that at any time the whole frame needs hidden due to entering combat
	- any new escable frames must be in rematch.escableFrames
	- any frames beyond main/drawer/selected need hidden in rematch:OnHide()
	- hide frames as soon as possible
]]

rematch.escableFrames = { "Rematch", "RematchDrawer", "RematchSelectedFrame", "RematchOptions",
	 "RematchSaveAs", "RematchConfirm", "RematchShare", "RematchHelp", "RematchLevelingQueueFrame",
	 "RematchRenameEditBox", "RematchFloatingPetCard" }

rematch.ESCHandler = CreateFrame("Frame",nil,rematch)
rematch.ESCHandler:SetPropagateKeyboardInput(true)
rematch.ESCHandler:SetScript("OnKeyDown",function(self,key) -- this only runs while frame is visible
	if key==GetBindingKey("TOGGLEGAMEMENU") then
		-- first check if any dropdowns up, if one of ours gets hidden, don't pass ESC
		if rematch:HideDropDown() then
			self:SetPropagateKeyboardInput(false)
			return
		end
		if rematch.browser.searchBox:HasFocus() then
			return
		end
		-- next check for our ESCable frames
		for i=#rematch.escableFrames,1,-1 do
			if _G[rematch.escableFrames[i]]:IsVisible() then
				if not (i==1 and settings.LockWindow) and not (i==2 and settings.LockDrawer) then
					for j=1,#UISpecialFrames do
						local special = UISpecialFrames[j]
						if special and _G[special] and _G[special]:IsVisible() then
							self:SetPropagateKeyboardInput(true)
							return
						end
					end
					self:SetPropagateKeyboardInput(UnitExists("target"))
					local wasLocked = RematchFloatingPetCard.locked
					_G[rematch.escableFrames[i]]:Hide()
					if rematch.escableFrames[i]~="RematchFloatingPetCard" or wasLocked then
						return -- if this isn't the card, or it was locked, don't go onto next frame
					end
				end
			end
		end
	elseif settings.JumpToTeam and not IsModifierKeyDown() then
		-- if JumpToTeam enabled, intercept keys if mouse is over teams or browser
		local focus = GetMouseFocus()
		if focus and key:len()==1 then
			local parent = focus:GetParent()
			local keySearch = format("^[%s%s]",key,key:lower())
			if parent==rematch.drawer.teams.scrollFrame.scrollChild then -- over teams
				self:SetPropagateKeyboardInput(false)
				local teamIndex = rematch:GetSelectedIndex() or 0
				for i=1,#rematch.teamList do
					teamIndex = (teamIndex%#rematch.teamList)+1
					if rematch.teamList[teamIndex]:match(keySearch) then
						rematch:SetSelectedTeam(rematch.teamList[teamIndex])
						rematch:ScrollToSelectedTeam()
						return
					end
				end
				return
			elseif parent==rematch.browser.list.scrollFrame.scrollChild then -- over browser
				-- the mouse is over browser, intercept keys to find a pet that begins with pressed key
				self:SetPropagateKeyboardInput(false)
				local petIndex = rematch.jumpToBrowserPet or 0
				local roster = rematch.roster
				for i=1,roster:GetNumPets() do
					petIndex = (petIndex%roster:GetNumPets())+1
					local petName = roster:GetPetNameByIndex(petIndex)
					if petName and petName:match(keySearch) then
						rematch.jumpToBrowserPet = petIndex
						local scrollFrame = rematch.browser.list.scrollFrame
						local buttons = scrollFrame.buttons
						local height = math.max(0,floor(scrollFrame.buttonHeight*(petIndex-(#buttons)/2)))
						HybridScrollFrame_SetOffset(scrollFrame,height)
						scrollFrame.scrollBar:SetValue(height)
						rematch:ClearTemporaryBrowserHighlight()
						for i=1,#buttons do
							if buttons[i].index==petIndex then
								buttons[i]:LockHighlight()
								rematch:StartTimer("TemporaryBrowserHighlight",1,rematch.ClearTemporaryBrowserHighlight)
								break
							end
						end
						return
					end
				end
				return
			end
		end
	end
	self:SetPropagateKeyboardInput(true)
end)

-- in a future update, browser pets can be selected and Jump to key will select the pet
-- it jumps to.  Right now, it only locks highlight. After a delay this gets run to clear it.
function rematch:ClearTemporaryBrowserHighlight()
	local buttons = rematch.browser.list.scrollFrame.buttons
	for i=1,#buttons do
		buttons[i]:UnlockHighlight()
	end
end

--[[ Reused pet frame functions ]]

-- wipes frames of any leftover pets/abilities
function rematch:WipePetFrames(parent)
	for i=1,3 do
		parent[i].petID = nil
		parent[i].icon:Hide()
		parent[i].leveling:Hide()
		parent[i].dead:Hide()
		for j=1,3 do
			parent[i].ability[j].abilityID = nil
			parent[i].ability[j].icon:Hide()
			if parent[i].ability[j].level then
				parent[i].ability[j].level:Hide()
			end
		end
	end
end

-- for reusable teamTables, wipe components to avoid generating any garbage
function rematch:WipeTeamTable(teamTable)
	for i=1,#teamTable do
		if type(teamTable[i])=="table" then
			wipe(teamTable[i])
		else
			teamTable[i] = nil
		end
	end
end

function rematch:DesaturateIfMissing(texture,missing)
	texture:SetDesaturated(missing)
	if missing then
		texture:SetVertexColor(.75,.75,.75)
	else
		texture:SetVertexColor(1,1,1)
	end
end

-- takes a speciesID and returns a petID if one found and its icon
function rematch:GetPetIDFromSpeciesID(speciesID,team)
	if type(speciesID)=="number" then
		local speciesName,icon = C_PetJournal.GetPetInfoBySpeciesID(speciesID)
		if speciesName then
			local _,petID = C_PetJournal.FindPetIDByName(speciesName)
			if petID then
				-- check if this found pet already exists on the team
				local count = 0
				for i=1,3 do
					if team[i][5]==speciesID then
						count=count+1
					end
				end
				if count>1 then
					return nil,icon
				else
					return petID,icon
				end
			else
				return nil,icon
			end
		end
	end
end

-- populates pet frames from a team table
function rematch:FillPetFramesFromTeam(parent,team)

	for i=1,3 do
		local icon,foundPetID,missing
		local petID = team[i][1]
		if petID==0 then
			icon = rematch:GetLevelingPetIcon()
		elseif type(petID)=="string" then
			icon = select(9,C_PetJournal.GetPetInfoByPetID(petID))
		elseif type(petID)=="number" then
			foundPetID,icon = rematch:GetPetIDFromSpeciesID(petID,team)
			if foundPetID then
				petID = foundPetID
				team[i][1] = petID
			else
				missing = 1
			end
		end
		if icon then
			parent[i].petID = petID -- can be a speciesID too if pet not known
			parent[i].icon:SetTexture(icon)
			parent[i].icon:Show()
			rematch:DesaturateIfMissing(parent[i].icon,missing)
			for j=1,3 do
				if team[i][j+1] then
					local _,_,abilityIcon = C_PetBattles.GetAbilityInfoByID(team[i][j+1])
					if abilityIcon then
						parent[i].ability[j].abilityID = team[i][j+1]
						parent[i].ability[j].icon:SetTexture(abilityIcon)
						parent[i].ability[j].icon:Show()
						rematch:DesaturateIfMissing(parent[i].ability[j].icon,missing)
					end
				end
			end
		end
		parent[i].leveling:SetShown(petID==0)
	end

end

-- all RematchPanelButtonTemplate-inherited button clicks go through here
function rematch:PanelButtonOnClick()
	local name = self:GetName()
	if rematch[name] then
		if self~=rematch.drawer.helpButton then
			rematch.drawer.help:Hide()
		end
		if self~=rematch.drawer.renameButton then
			rematch.drawer.teams.renameEditBox:Hide()
		end
		rematch:HideDropDown()
		rematch[name](rematch)
	end
end

-- enables/disables panel buttons based on whether a team is selected
function rematch:UpdatePanelButtons()
	local selected = rematch.selectedTeam and rematch.selectedTeam~="~temp~"
	rematch.loadButton:SetEnabled(selected)
	rematch.saveButton:SetText((selected or rematch.targetedNpcID) and "Save" or "Save As")
end

function rematch:RematchCloseButton()
	rematch:Hide()
end

-- updates everything in the window
function rematch:UpdateWindow()

	if not rematch:IsVisible() then return end

	rematch:SetScale(settings.LargeWindow and 1.25 or 1)
	rematch:ClearAllPoints()
	rematch:SetPoint("BOTTOMLEFT",settings.XPos,settings.YPos)

	rematch:UpdateCurrentPets()

	local drawerOpen = rematch.drawer:IsVisible()
	local showSaved

	-- if window is collapsed, and the selected team is same as one current pets displays, unselect it
	if not drawerOpen and rematch.selectedTeam and rematch.current.header.text:GetText()==rematch.selectedTeam then
		showSaved = false
	elseif drawerOpen or rematch.selectedTeam then
		showSaved = true
	end

	local cy = 128
	rematch.current:SetHeight(showSaved and 108 or 98)
	if showSaved then
		cy = cy+74 -- 10 padding for saved header + 64 saved frame height
	end
	if drawerOpen then
		cy = cy+200 -- was 180
	end
	rematch:SetHeight(cy)

--	rematch.panel.backShadow:SetTexCoord(1,0,1-(cy-98)/284,1) -- adjust shadow on background to window height
	rematch.saved:SetShown(showSaved)

	if rematch.saved:IsVisible() then
		rematch:UpdateSavedPets()
	end

	if rematch.drawer:IsVisible() then
		rematch:OrderTeamList()
		rematch:UpdateTeamList()
	end

	rematch:UpdatePanelButtons()
	rematch:UpdateSidePanel()
	rematch:UpdateBrowserPosition()
	rematch:HideFloatingPetCard(true)

end

function rematch:PLAYER_TARGET_CHANGED()

	rematch:UpdateTargetedInfo()

	if rematch.selectedTeam and (settings.AutoShow or settings.AutoLoad) then
		rematch.alreadyShown = rematch:IsVisible()
		if rematch:PetsNeedLoading(rematch.selectedTeam) then
			if settings.AutoShow then
				rematch:Show()
				rematch.selectedTeam = rematch.targetedName
			end
			if settings.AutoLoad then
				rematch:AutoLoadTeam(rematch.selectedTeam)
			end
		elseif rematch.lastAutoLoaded~=rematch.selectedTeam then
			rematch.lastAutoLoaded = rematch.selectedTeam
		end
	end

	if rematch:IsVisible() then
		rematch:UpdateWindow()
		if rematch.drawer:IsVisible() then
			if rematch.selectedTeam then
				rematch:ScrollToSelectedTeam()
			end
		end
	end

end

function rematch:UPDATE_MOUSEOVER_UNIT(...)
	if not InCombatLockdown() then
		local mouseoverName,mouseoverNpcID = rematch:GetUnitNameandID("mouseover")
		local team = savedTeams[mouseoverName]
		if team and (not team[4] or team[4]==mouseoverNpcID) then
			if rematch:PetsNeedLoading(mouseoverName) then
				rematch:AutoLoadTeam(mouseoverName)
			elseif rematch.lastAutoLoaded~=mouseoverName then
				rematch.lastAutoLoaded = mouseoverName -- pretend a load happened if no load needed
			end
		end
	end
end

function rematch:AutoLoadTeam(teamName)
	if rematch.lastAutoLoaded~=teamName or settings.AutoLoadAlways then
		rematch.lastAutoLoaded = teamName
		rematch:LoadPets(teamName)
	end
end

function rematch:UpdateTargetedInfo()
	rematch.targetedName,rematch.targetedNpcID = rematch:GetUnitNameandID("target")
	local selectedCandidate = nil
	if savedTeams[rematch.targetedName] and (not savedTeams[rematch.targetedName][4] or savedTeams[rematch.targetedName][4]==rematch.targetedNpcID) then
		-- but if we have an npc targeted with a matching name, set selectedTeam to that target
		-- note this can set selectedTeam to named players with matching team names (which is ok)
		selectedCandidate = rematch.targetedName
	end
	rematch:SetSelectedTeam(selectedCandidate)
end

-- returns name of the given unit and npcID if it's an npc, or nil if unit doesn't exist
function rematch:GetUnitNameandID(unit)
	if UnitExists(unit) then
		local name = UnitName(unit)
		local npcID = tonumber(UnitGUID(unit):sub(6,10),16)
		if npcID~=0 then
			return name,npcID -- this is an npc, return its name and npcID
		else
			return name -- this is a player, return its name
		end
	end
end

--[[ Timer Management ]]

rematch.timerFuncs = {} -- indexed by arbitrary name, the func to run when timer runs out
rematch.timerTimes = {} -- indexed by arbitrary name, the duration to run the timer
rematch.timerFrame = CreateFrame("Frame") -- timer independent of main frame visibility
rematch.timerFrame:Hide()

function rematch:StartTimer(name,duration,func)
	rematch.timerFuncs[name] = func
	rematch.timerTimes[name] = duration
	rematch.timerFrame:Show()
end

function rematch:StopTimer(name)
	if name and rematch.timerTimes[name] then
		rematch.timerTimes[name] = nil
	end
end

rematch.timerFrame:SetScript("OnUpdate",function(self,elapsed)
	local tick
	local times = rematch.timerTimes
  for name in pairs(times) do
		times[name] = times[name] - elapsed
		if times[name] < 0 then
			times[name] = nil
			rematch.timerFuncs[name]()
		end
		tick = 1
	end
	if not tick then
		self:Hide()
	end
end)

function rematch:SetSelectedTeam(teamName,force)
	if rematch.selectedTeam~=teamName or force then
		rematch.selectedTeam = teamName
		if rematch:IsVisible() then
			rematch:UpdateWindow()
			rematch.selectedFrame:SetShown(rematch.selectedTeam and savedTeams[rematch.selectedTeam])
		end
	end
end

function rematch:ClearSelected()
	rematch:SetSelectedTeam(nil)
	rematch:UpdateSavedPets()
	if rematch.drawer:IsVisible() then
		rematch:UpdateTeamList()
	end
end

function rematch:SelectedFrameOnHide()
	rematch:SetSelectedTeam(nil)
end

--[[ changes to default pet journal ]]

-- when pet journal is loaded/shown, we create/anchor a rematch button to it
function rematch:ADDON_LOADED(addon)
	if addon=="Blizzard_PetJournal" then
		rematch:UnregisterEvent("ADDON_LOADED")

		-- Rematch button the pet journal
		local button = CreateFrame("Button","RematchPetJournalButton",PetJournal,"MagicButtonTemplate")
		button:SetSize(140,22)
		button:SetText("Rematch")
		button:SetScript("OnClick",rematch.Toggle)
		button:SetScript("OnEnter",function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:SetText("Rematch",1,1,1)
			GameTooltip:AddLine("Toggles the Rematch window to manage battle pet teams.",nil,nil,nil,true)
			GameTooltip:Show()
		end)
		button:SetScript("OnLeave",function(self)
			GameTooltip:Hide()
		end)
		-- when pet journal is shown, adjust position of Rematch button based on existence of non-default buttons
		PetJournal:HookScript("OnShow",function(self)
			rematch.journalOpen = true
			rematch.browser:Hide()
			local ourButton = RematchPetJournalButton
			local leftJournal = PetJournal:GetLeft()
			local midJournal = PetJournal:GetWidth()/2 + leftJournal
			local topJournalButtons = PetJournal:GetBottom()+30
			local leftUsed,rightUsed
			for _,button in pairs({PetJournal:GetChildren()}) do
			  local topButton = button:GetTop()
			  if topButton and topButton<topJournalButtons and button~=PetJournalFindBattle and button~=PetJournalSummonButton and button~=ourButton then
					if button:GetLeft() < midJournal then -- something is in the bottomleft next to default summon button
						leftUsed = true
					else -- something is in the bottomright next to default find battle button
						rightUsed = true
					end
			  end
			end
			ourButton:ClearAllPoints()
			if not rightUsed then
				ourButton:SetPoint("RIGHT",PetJournalFindBattle,"LEFT")
			elseif not leftUsed then
				ourButton:SetPoint("LEFT",PetJournalSummonButton,"RIGHT")
			end
			ourButton:SetShown(not (rightUsed and leftUsed))
		end)
		PetJournal:HookScript("OnHide",function(self)
			rematch.journalOpen = nil
			rematch:UpdateWindow()
		end)

		-- hook the pet menu drop-down menu to rematch.NewDropDownMenu after giving time for all LoadWith to get done
		rematch:StartTimer("DropDownInit",.5,function()
			local parent = PetJournalEnhancedPetMenu or PetJournalPetOptionsMenu
			rematch.oldDropDownInit = parent.initialize
			parent.initialize = rematch.NewPetMenuDropDownInit
		end) -- come back in .5 seconds to look for them
		hooksecurefunc("HybridScrollFrame_Update",rematch.UpdateLevelingMarkersHook)
	end
end

-- migrate any teams saved in Pet Battle Teams, whose name doesn't already exist, into Rematch
function rematch:MigratePBT(over)
	if IsAddOnLoaded("PetBattleTeams") and PetBattleTeamsDB and PetBattleTeamsDB.namespaces and PetBattleTeamsDB.namespaces.TeamManager then
		local PBTsaved = PetBattleTeamsDB.namespaces.TeamManager.global.teams
		local mentionOver
		for team=1,#PBTsaved do
			local teamName = PBTsaved[team].name or "Team: "..team
			if not savedTeams[teamName] or over then -- only migrate teams that don't already exist
				savedTeams[teamName] = {{},{},{}}
				for pet=1,3 do
					local petID = PBTsaved[team][pet].petID
					if petID then
						petID = petID:gsub("%x",function(c) return c:upper() end)
						if petID==rematch.emptyPetID or not petID then
							savedTeams[teamName][pet] = {0,0,0,0} -- convert missing pet to leveling slot
						else
							savedTeams[teamName][pet][1] = petID
							for ability=1,3 do
								savedTeams[teamName][pet][ability+1] = PBTsaved[team][pet].abilities[ability]
							end
						end
					else
						savedTeams[teamName][pet] = {0,0,0,0}
					end
				end
				print("\124cffffd200",teamName,"\124cffffffffcopied to Rematch.")
			else
				print("\124cffffd200",teamName,"\124cffffffffwas not copied. A team of that name already exists.")
				mentionOver = 1
			end
		end
		if mentionOver then
			print("\124cffff8800You can \124cffffd200/rematch import over\124cffff8800 to overwrite existing teams.")
		end
		settings.EmptyMissing = 1
		rematch.drawer.options.checks.EmptyMissing:SetChecked(1)
		print("\124cffffd200The Rematch option 'Empty Missing' was also enabled for an easier transition. You can turn it off in options.")
		if rematch.drawer:IsVisible() then
			rematch:OrderTeamList()
			rematch:UpdateTeamList()
		end
	else
		print("\124cffff8800PetBattleTeams isn't loaded. No PBT teams were imported.")
	end
end

--[[ Base pet slot interaction ]]--

function rematch:PetOnEnter()
	local petID
	if self.petID then
		if self.petID~=0 then
			petID = self.petID -- this is a normal petID
		else
			petID = rematch:GetLevelingPetID() -- fetch leveling petID if there is one
		end
		rematch:ShowFloatingPetCard(petID,self)
	end
end

function rematch:PetOnLeave()
	rematch:HideFloatingPetCard()
end

function rematch:PetOnDragStart()
	if self.petID and (self.set==1 or self.set==3) then
		C_PetJournal.PickupPet(self.petID)
	end
end

function rematch:PetOnReceiveDrag()
	local cursorType,petID = GetCursorInfo()
	local clear
	if cursorType=="battlepet" and petID then
		if self.set==1 and self:GetID()>0 and self:GetID()<4 then
			rematch:SummonedPetMayChange()
			C_PetJournal.SetPetLoadOutInfo(self:GetID(),petID)
			if PetJournal then
				PetJournal_UpdatePetLoadOut() -- update petjournal if it's open
			end
			clear = true
		elseif self.set==3 then
			if rematch:PetCanLevel(petID) then
				rematch:SetLevelingPet(petID)
				rematch:ProcessLevelingQueue()
				rematch:UpdateLevelingQueue()
				rematch:UpdateLevelingMarkersOnJournal()
				clear = true
			end
		end
	end
	if clear then
		ClearCursor()
		rematch:HideFloatingPetCard()
	end
end

-- this makes the current pets glow when a pet is picked up onto the cursor
function rematch:CURSOR_UPDATE()
  local hasPet,petID = GetCursorInfo()
	hasPet = hasPet=="battlepet"
	for i=1,3 do
		rematch.current.pet[i].glow:SetShown(hasPet)
	end
	rematch.drawer.leveling.glow:Hide()
	RematchLevelingQueueFrame.glow:Hide()
	if hasPet then
		if rematch:PetCanLevel(petID) then
			rematch.drawer.leveling.glow:Show()
			RematchLevelingQueueFrame.glow:Show()
		end
		rematch:RegisterEvent("CURSOR_UPDATE") -- this is the only place this event is registered
	else
		rematch:UnregisterEvent("CURSOR_UPDATE") -- cursor clear, stop watching cursor changes
	end
end
hooksecurefunc(C_PetJournal,"PickupPet",rematch.CURSOR_UPDATE)

function rematch:PetOnClick(button)
	if GetCursorInfo()=="battlepet" then
		rematch.PetOnReceiveDrag(self) -- a battlepet is on the cursor, pretend it's a drag receive
		return
	end
	local petID = self.petID
	if petID==0 then
		petID = rematch:GetLevelingPetID()
	end
	if petID then
		-- shift+click to link pet (only known pets work--default can't link missing either)
		if IsModifiedClick("CHATLINK") and type(petID)=="string" then
			ChatEdit_InsertLink(C_PetJournal.GetBattlePetLink(petID))
			return
		end
		if button=="RightButton" then
			if self.set==1 then
				rematch.dropDownPetID = petID
				rematch.dropDownPetSlot = self:GetID()
				rematch:ShowDropDown(1)
				return
			end
		end
		-- otherwise lock pet card or show current one if one was locked
		local cardID = RematchFloatingPetCard.petID
		rematch:LockFloatingPetCard()
		if petID ~= cardID then
			rematch:ShowFloatingPetCard(petID,self)
			rematch:LockFloatingPetCard() -- lock it again
		end
	end
end

function rematch:AbilityOnClick()
	if self.abilityID then
		if IsModifiedClick("CHATLINK") then
			local petID = self:GetParent().petID
			local maxHealth,power,speed,_ = 100,0,0
			if type(petID)=="string" then
				_,maxHealth,power,speed = C_PetJournal.GetPetStats(petID)
			end
			ChatEdit_InsertLink(GetBattlePetAbilityHyperlink(self.abilityID,maxHealth,power,speed))
		elseif self:GetParent().petID then
			rematch.PetOnClick(self:GetParent()) -- pretend we clicked parent pet
		end
	end
end

--[[ Pet Ability Tooltips ]]

-- ability tooltips use FloatingPetBattleAbilityTooltip with a few tweaks
function rematch:AbilityOnEnter(petID)
	rematch.borderKeys = rematch.borderKeys or {"BorderTopLeft","BorderTopRight","BorderBottomLeft","BorderBottomRight","BorderLeft","BorderRight","BorderTop","BorderBottom"}
	petID = petID or self:GetParent().petID
	if petID and self.abilityID then
		local _,maxHealth,power,speed
		if type(petID)=="string" then
			_,maxHealth,power,speed = C_PetJournal.GetPetStats(petID)
		else
			maxHealth,power,speed = 100,0,0 -- missing pets are weak!
		end
		FloatingPetBattleAbility_Show(self.abilityID,maxHealth,power,speed)
		local tooltip = FloatingPetBattleAbilityTooltip
		rematch:SmartAnchor(tooltip,self)
		-- make border gold (Blizzard why you no use tooltip Backdrop)
		for _,key in pairs(rematch.borderKeys) do
			tooltip[key]:SetVertexColor(.9,.738,0)
		end
		-- hide close button that can't be clicked anyway
		tooltip.CloseButton:Hide()
		-- if LargeWindow not checked, shrink tooltip by 10%
		tooltip:SetScale(settings.LargeWindow and 1 or .9)
		tooltip:EnableMouse(false)
		local _,_,icon = C_PetBattles.GetAbilityInfoByID(self.abilityID)
		if icon then
			if not tooltip.rematchAbility then
				tooltip.rematchAbility = CreateFrame("Frame",nil,tooltip)
				tooltip.rematchAbility:SetSize(36,36)
				tooltip.rematchAbility:SetPoint("TOPRIGHT",-6,-6)
				tooltip.rematchAbility.icon = tooltip.rematchAbility:CreateTexture(nil,"BORDER")
				tooltip.rematchAbility.icon:SetAllPoints(true)
--				tooltip.rematchAbility.border = tooltip.rematchAbility:CreateTexture(nil,"ARTWORK")
--				tooltip.rematchAbility.border:SetAllPoints(true)
--				tooltip.rematchAbility.border:SetTexture("Interface\\PetBattles\\PetBattleHUD")
--				tooltip.rematchAbility.border:SetTexCoord(0.884765625,0.943359375,0.681640625,0.798828125)
			end
			-- ability "Scratch" probably among others is not at least 64x64 and can't SetPortraitToTexture :(
--			SetPortraitToTexture(tooltip.rematchAbility.icon,icon)
			tooltip.rematchAbility.icon:SetTexture(icon)
			tooltip.rematchAbility:Show()
		end
	end
	if self.abilityID and self.arrow then
		self.arrow:Show()
	end
end

function rematch:AbilityOnLeave()
	local tooltip = FloatingPetBattleAbilityTooltip
	tooltip:Hide()
	-- revert gold border, show close button again and restore scale
	if rematch.borderKeys then
		for _,key in pairs(rematch.borderKeys) do
			tooltip[key]:SetVertexColor(1,1,1)
		end
		tooltip.CloseButton:Show()
		tooltip:SetScale(1)
		tooltip:EnableMouse(true)
	end
	if tooltip.rematchAbility then
		tooltip.rematchAbility:Hide()
	end
	if self.arrow then
		self.arrow:Hide()
	end
end

function rematch:AbilityOnClick()
	if self.abilityID then
		if IsModifiedClick("CHATLINK") then
			local petID = self:GetParent().petID
			local maxHealth,power,speed,_ = 100,0,0
			if type(petID)=="string" then
				_,maxHealth,power,speed = C_PetJournal.GetPetStats(petID)
			end
			ChatEdit_InsertLink(GetBattlePetAbilityHyperlink(self.abilityID,maxHealth,power,speed))
		elseif self:GetParent().petID then
			rematch.PetOnClick(self:GetParent()) -- pretend we clicked parent pet
		end
	end
end

--[[ Keep Summoned ]]

-- primarilyy for KeepSummoned, call this before pets are about to change
function rematch:SummonedPetMayChange()
	if settings.KeepSummoned then
		rematch.preLoadCompanion = rematch.preLoadCompanion or C_PetJournal.GetSummonedPetGUID()
		rematch:RegisterEvent("UNIT_PET")
		rematch:StartTimer("RestoreTimeout",1,rematch.RestoreTimeout)
	end
end

function rematch:UNIT_PET()
	rematch:StopTimer("RestoreTimeout")
	rematch:UnregisterEvent("UNIT_PET")
	rematch:StartTimer("RestoreCompanion",1.6,rematch.RestoreCompanion) -- wait a GCD before restoring
end

function rematch:RestoreCompanion()
	if not InCombatLockdown() then -- can't SummonPetByGUID in combat :(
		local nowSummoned = C_PetJournal.GetSummonedPetGUID()
		if not rematch.preLoadCompanion and nowSummoned then
			C_PetJournal.SummonPetByGUID(nowSummoned) -- something summoned, had nothing before
		elseif nowSummoned ~= rematch.preLoadCompanion then
			C_PetJournal.SummonPetByGUID(rematch.preLoadCompanion) -- something summoned different than before
		end
		rematch.preLoadCompanion = nil
	end
end

-- if no UNIT_PET fired, unregister it. apparently no pet was loaded
function rematch:RestoreTimeout()
	rematch.preLoadCompanion = nil
	rematch:UnregisterEvent("UNIT_PET")
end

--[[ Pet DropDown Menus ]]

-- this is a prehook to the dropdown initialization for the journal pet menu (hook made when journal loads)
function rematch:NewPetMenuDropDownInit(level)
	local petID = PetJournal.menuPetID
	if petID then
	  local info = UIDropDownMenu_CreateInfo()
	  info.notCheckable = true
		rematch.dropDownPetID = petID
		if rematch:IsPetLeveling(petID) then
			info.text = "Stop Leveling"
			info.func = rematch.DropDownFuncStopLeveling
		  UIDropDownMenu_AddButton(info,level)
		else
			if rematch:PetCanLevel(petID) then
				local info = UIDropDownMenu_CreateInfo()
				info.notCheckable = true
				info.text = "Start Leveling"
				info.func = rematch.DropDownFuncSendToStart
				UIDropDownMenu_AddButton(info,level)
				if #settings.LevelingQueue>0 then
					info.text = "Add to Leveling Queue"
					info.func = rematch.DropDownFuncSendToEnd
					UIDropDownMenu_AddButton(info,level)
				end
			end
		end
	end
	rematch.oldDropDownInit(self,level)
end

-- this is for the dropdowns on rematch frames
-- mode 1=current pet, 2=saved pets, 3=leveling slot, 4=leveling queue, 5=browser
function rematch:ShowDropDown(mode)
	rematch:HideFloatingPetCard()
	local menu = rematch.dropDownMenu
	wipe(menu)
	local petID = rematch.dropDownPetID

	if type(petID)~="string" then
		rematch:HideDropDown()
		return -- leave if we've right clicked a pet we don't own
	end

	rematch.disableOnEnters = true

	local hasPet = rematch.dropDownPetSlot and C_PetJournal.GetPetLoadOutInfo(rematch.dropDownPetSlot)
	if petID then
		local _,customName,_,_,_,_,_,realName = C_PetJournal.GetPetInfoByPetID(petID)
		tinsert(menu,{text=(hasPet or not rematch.dropDownSlot) and (customName or realName) or "Empty Slot",notCheckable=true,isTitle=true})
		local canLevel = rematch:PetCanLevel(petID)
		local queueSlot, isLast, queueLength
		if canLevel then
			queueSlot, isLast, queueLength = rematch:GetLevelingPetSlot(petID)
			if queueSlot then
				tinsert(menu,{text="Stop Leveling",notCheckable=true,func=rematch.DropDownFuncStopLeveling})
			else
				tinsert(menu,{text="Start Leveling",notCheckable=true,func=rematch.DropDownFuncSendToStart})
				if queueLength>0 then
					tinsert(menu,{text="Add to Leveling Queue",notCheckable=true,func=rematch.DropDownFuncSendToEnd})
				end
			end
			if queueSlot and queueSlot>1 then
				tinsert(menu,{text="Send to Start of Queue",notCheckable=true,func=rematch.DropDownFuncSendToStart})
			end
			if queueSlot and not isLast and queueLength>0 then
				tinsert(menu,{text="Send to End of Queue",notCheckable=true,func=rematch.DropDownFuncSendToEnd})
			end
			if queueSlot==1 and queueLength>1 then
				tinsert(menu,{text="Swap with Next in Queue",notCheckable=true,func=rematch.DropDownFuncSwapWithNext})
			end
		end
		if mode==1 then
			if queueSlot~=1 then
				tinsert(menu,{text="Put Leveling Pet Here",notCheckable=true,func=rematch.DropDownFuncPlaceLeveling,disabled=not rematch:GetLevelingPetID()})
			end
			if hasPet then
				tinsert(menu,{text="Empty Slot",notCheckable=true,func=rematch.DropDownFuncEmptySlot})
			end
		end
		-- dismiss/summon is common for all modes
		if hasPet or mode>1 then
			tinsert(menu,{text=C_PetJournal.GetSummonedPetGUID()==petID and PET_ACTION_DISMISS or SUMMON,notCheckable=true,func=rematch.DropDownFuncSummonOrDismiss})
		end
		-- browser menu
		if mode==5 then
			-- rename
			tinsert(menu,{text=BATTLE_PET_RENAME,notCheckable=true,disabled=not C_PetJournal.IsJournalUnlocked(),func=function() LoadAddOn("Blizzard_PetJournal") StaticPopup_Show("BATTLE_PET_RENAME",nil,nil,petID) end})
			-- favorite
			if C_PetJournal.PetIsFavorite(petID) then
				tinsert(menu,{text=BATTLE_PET_UNFAVORITE,notCheckable=true,func=function() C_PetJournal.SetFavorite(petID,0) end})
			else
				tinsert(menu,{text=BATTLE_PET_FAVORITE,notCheckable=true,func=function() C_PetJournal.SetFavorite(petID,1) end})
			end
			-- release
			if C_PetJournal.PetCanBeReleased(petID) then
				local isDisabled = C_PetJournal.PetIsSlotted(petID) or C_PetBattles.IsInBattle() or not C_PetJournal.IsJournalUnlocked()
				local _,customName,_,_,_,_,_,realName = C_PetJournal.GetPetInfoByPetID(petID)
				tinsert(menu,{text=BATTLE_PET_RELEASE,notCheckable=true,disabled=isDisabled,func=function() LoadAddOn("Blizzard_PetJournal") StaticPopup_Show("BATTLE_PET_RELEASE",customName or realName,nil,petID) end})
			end
			-- cage
			if C_PetJournal.PetIsTradable(petID) then
				local text = BATTLE_PET_PUT_IN_CAGE
				local isDisabled
				if C_PetJournal.PetIsSlotted(petID) then
					text = BATTLE_PET_PUT_IN_CAGE_SLOTTED
					isDisabled = true
				elseif C_PetJournal.PetIsHurt(petID) then
					text = BATTLE_PET_PUT_IN_CAGE_HEALTH
					isDisabled = true
				end
				tinsert(menu,{text=text,notCheckable=true,disabled=isDisabled,func=function() LoadAddOn("Blizzard_PetJournal") StaticPopup_Show("BATTLE_PET_PUT_IN_CAGE",nil,nil,petID) end})
			end

		end
	end

	tinsert(menu,{text="Cancel",notCheckable=true})
	EasyMenu(menu,rematch.dropDownFrame,"cursor",0,0,"MENU")
end

function rematch:HideDropDown()
	if UIDROPDOWNMENU_OPEN_MENU==rematch.dropDownFrame or UIDROPDOWNMENU_OPEN_MENU==RematchBrowserFilterDropDown then
		if DropDownList1:IsVisible() then
			CloseDropDownMenus()
			return true
		end
	end
end

function rematch:DropDownFuncStopLeveling()
	rematch:DeleteFromLevelingQueue(rematch.dropDownPetID)
	rematch:ProcessLevelingQueue()
	rematch:UpdateLevelingQueue()
	rematch:UpdateLevelingMarkersOnJournal()
end

function rematch:DropDownFuncSendToStart()
	rematch:SetLevelingPet(rematch.dropDownPetID)
	rematch:ProcessLevelingQueue()
	rematch:UpdateLevelingQueue()
	rematch:UpdateLevelingMarkersOnJournal()
end

function rematch:DropDownFuncSendToEnd()
	rematch:DeleteFromLevelingQueue(rematch.dropDownPetID)
	tinsert(settings.LevelingQueue,rematch.dropDownPetID)
	rematch:ProcessLevelingQueue()
	rematch:UpdateLevelingQueue()
	rematch:UpdateLevelingMarkersOnJournal()
end

function rematch:DropDownFuncSummonOrDismiss()
	C_PetJournal.SummonPetByGUID(rematch.dropDownPetID)
end

function rematch:DropDownFuncPlaceLeveling()
	local petID = rematch:GetLevelingPetID()
	if petID and rematch.dropDownPetSlot then
		rematch:SummonedPetMayChange()
		C_PetJournal.SetPetLoadOutInfo(rematch.dropDownPetSlot,petID)
	end
end

function rematch:DropDownFuncEmptySlot()
	C_PetJournal.SetPetLoadOutInfo(rematch.dropDownPetSlot,rematch.emptyPetID)
end

function rematch:DropDownFuncSwapWithNext()
	local petID = rematch:GetLevelingPetByIndex(2)
	if petID then
		rematch:SetLevelingPet(petID)
		rematch:UpdateLevelingQueue()
	end
end

-- does a "criterea" toast to alert that the leveling pet has changed
function rematch:ToastNextLevelingPet(petID)
	local _,customName,_,_,_,_,_,realName,icon = C_PetJournal.GetPetInfoByPetID(petID)
	if icon then
    local frame = CriteriaAlertFrame_GetAlertFrame()
		if frame then
			local frameName = frame:GetName()
			_G[frameName.."Name"]:SetText(customName or realName)
			_G[frameName.."Unlocked"]:SetText("Next leveling pet:")
	    _G[frameName.."IconTexture"]:SetTexture(icon)
	    frame.id = nil
	    AlertFrame_AnimateIn(frame)
      AlertFrame_FixAnchors()
			if not frame.rematchHide then
				-- add an OnHide secure hook to change "Unlocked" back to "Achievement Progress"
				frame.rematchHide = true
				frame:HookScript("OnHide",function(self) _G[self:GetName().."Unlocked"]:SetText(ACHIEVEMENT_PROGRESSED) end)
			end
		end
	end
end

-- this is for a secure hook to C_PetJournal.CagePetByID: when a pet is caged, go through all teams
-- and replace the petID being caged with its speciesID.
function rematch.CagePetByID(petID)
	if petID then
		rematch:ClearSelected()
		local speciesID = C_PetJournal.GetPetInfoByPetID(petID)
		if speciesID then
			for teamName,team in pairs(savedTeams) do
				for i=1,3 do
					if team[i][1]==petID then
						team[i][1] = speciesID
					end
				end
			end
		end
	end
	rematch:DeleteFromLevelingQueue(petID)
	rematch:ProcessLevelingQueue()
end

--[[ Heal buttons ]]

-- track when Revive Battle Pets & Battle Pet Bandage is used (only registered when window visible)
function rematch:UNIT_SPELLCAST_SUCCEEDED(unit,_,_,_,spellID)
	-- 125439 is revive pet spell
	if unit=="player" and spellID==125439 then -- revive battle pet
		rematch:StartTimer("UpdateHealButtons",0.1,rematch.UpdatePetHealButton)
	end
end

-- can't just track when bandages used, also need to track when bandages received
-- this is only registered while the rematch window is visible
function rematch:BAG_UPDATE()
	rematch:StartTimer("UpdateHealbuttons",0.1,rematch.UpdateBandageButton)
end

function rematch:UpdatePetHealButton()
	rematch.petheal.cooldown:SetCooldown(GetSpellCooldown(125439))
end

function rematch:UpdateBandageButton()
	local count = GetItemCount(86143)
	local vertex = count==0 and .5 or 1
	rematch.bandage.icon:SetVertexColor(vertex,vertex,vertex)
	rematch.bandage.count:SetText(GetItemCount(86143))
end

-- when we need to update both buttons
function rematch:UpdateHealButtons()
	rematch:UpdatePetHealButton()
	rematch:UpdateBandageButton()
end

function rematch:HealButtonOnEnter()
	GameTooltip:SetOwner(self,"ANCHOR_RIGHT")
	if self:GetAttribute("type")=="spell" then
		GameTooltip:SetSpellByID(self:GetAttribute("spell")) -- 125439)
	else
		local itemID = tonumber(self:GetAttribute("item"):match("item:(%d+)"))
		GameTooltip:SetItemByID(itemID) -- 86143)
	end
	GameTooltip:Show()
	rematch:SmartAnchor(GameTooltip,self)
end

--[[ Best of Species aka Auto Upgrade ]]

function rematch:SetupBestOfSpecies()
	if settings.BestOfSpecies then
		if not rematch.BoS then
			-- creating a separate frame to handle this that we can rip out when full journal list support added
			rematch.BoS = CreateFrame("Frame")
			rematch.BoS:SetScript("OnEvent",rematch.BestOfSpeciesOnEvent)
			rematch.BoS.filter = BATTLE_PET_NEW_PET:gsub("%%s","^(.-)")
			rematch.BoS.teamSpecies = {} -- will use to note species
		end
		rematch.BoS:RegisterEvent("CHAT_MSG_SYSTEM")
	elseif rematch.BoS then
		rematch.BoS:UnregisterEvent("CHAT_MSG_SYSTEM")
	end
end

function rematch:BestOfSpeciesOnEvent(event,msg)
	if event=="CHAT_MSG_SYSTEM" then -- when learning a pet, note its species and wait for it to enter journal
		local link = msg:match(rematch.BoS.filter)
		if link and link:match("battlepet") then
			rematch.BoS.speciesID = tonumber(link:match("battlepet:(%d+)"))
			rematch.BoS:RegisterEvent("PET_JOURNAL_LIST_UPDATE")
		end
	elseif event=="PET_JOURNAL_LIST_UPDATE" then -- should always be first fire after learning
		rematch.BoS:UnregisterEvent("PET_JOURNAL_LIST_UPDATE")

		-- get the best (highest level/rarity) petID for the learned species
		local bestPetID = rematch:GetBestPetIDForSpecies(rematch.BoS.speciesID)

		-- and if there is one, apply it to all teams that contain that species
		if bestPetID then
			for teamName,team in pairs(savedTeams) do
				for i=1,3 do
					local petID = team[i][1]
					-- if petID is the species we're upgrading, or the species of the petID is the species we're upgrading, set the bestPetID
					if (type(petID)=="number" and petID==rematch.BoS.speciesID) or (type(petID)=="string" and C_PetJournal.GetPetInfoByPetID(petID)==rematch.BoS.speciesID) then
						team[i][1] = bestPetID
					end
				end
			end
		end

		if rematch:IsVisible() then
			rematch:UpdateSavedPets() -- update saved team display in case we have an affected team selected
		end
	end
end

-- go through the journal and get the highest level/rarity pet of a given species
function rematch:GetBestPetIDForSpecies(speciesID)
	local bestLevel,bestRarity,bestPetID = -1,-1
	for i=1,C_PetJournal.GetNumPets() do
		local petID,speciesID,_,_,level = C_PetJournal.GetPetInfoByIndex(i)
		if petID and speciesID==rematch.BoS.speciesID then
			rarity = select(5,C_PetJournal.GetPetStats(petID))
			if level>=bestLevel and rarity>=bestRarity then
				bestPetID = petID
				bestLevel = level
				bestRarity = rarity
			end
		end
	end
	return bestPetID
end

-- go through each pet in a team and confirms its petID is valid.
-- if so, and a speciesID isn't saved, adds it to the team.
-- if not, it will try to find one from its speciesID.
function rematch:ValidateTeam(team)
	for i=1,3 do
		local petID = team[i][1]
		if not petID then
			team[i][1] = rematch.emptyPetID
		elseif type(petID)=="string" then -- if the pet is a petID
			local speciesID = C_PetJournal.GetPetInfoByPetID(petID)
			if speciesID and not team[i][5] then -- if a valid petID doesn't have a species known yet
				team[i][5] = speciesID -- add its species
			elseif not speciesID then -- if it's not a valid petID
				if team[i][5] then -- and it has a saved speciesID
					local foundPetID = rematch:GetPetIDFromSpeciesID(team[i][5],team)
					if foundPetID then
						team[i][1] = foundPetID -- new petID found
					else
						team[i][1] = team[i][5] -- no petID found, use speciesID in place of petID
					end
				end
			end
		elseif type(petID)=="number" then -- if the pet is a speciesID
			local foundPetID = rematch:GetPetIDFromSpeciesID(petID,team) -- look for a petID for the species
			if foundPetID then
				team[i][1] = foundPetID
				team[i][5] = petID -- this is actually speciesID
			end
		end
	end
end

-- anchors frame to relativeTo depending on where relativeTo is on the screen, based on
-- the center of the reference frame (rematch frame itself if no reference given)
-- specifically, frame will be anchored to the corner furthest from the edge of the screen
function rematch:SmartAnchor(frame,relativeTo,reference)
	reference = reference or rematch
	local referenceScale = reference:GetEffectiveScale()
	local UIParentScale = UIParent:GetEffectiveScale()
	local isLeft = (reference:GetRight()*referenceScale+reference:GetLeft()*referenceScale)/2 < (UIParent:GetWidth()*UIParentScale)/2
	local isBottom = (reference:GetTop()*referenceScale+reference:GetBottom()*referenceScale)/2 < (UIParent:GetHeight()*UIParentScale)/2
	if isLeft then
		anchorPoint = isBottom and "BOTTOMLEFT" or "TOPLEFT"
		relativePoint = isBottom and "TOPRIGHT" or "BOTTOMRIGHT"
	else
		anchorPoint = isBottom and "BOTTOMRIGHT" or "TOPRIGHT"
		relativePoint = isBottom and "TOPLEFT" or "BOTTOMLEFT"
	end
	frame:ClearAllPoints()
	frame:SetPoint(anchorPoint,relativeTo,relativePoint)
end