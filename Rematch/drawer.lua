
local rematch = Rematch
local settings, savedTeams

rematch.teamList = {} -- ordered list of teams to display in drawer

function rematch:InitializeDrawer()
	settings = RematchSettings
	savedTeams = RematchSaved

	local scrollFrame = rematch.drawer.teams.scrollFrame
	scrollFrame.update = rematch.UpdateTeamList
	scrollFrame.stepSize = 54
	HybridScrollFrame_CreateButtons(scrollFrame,"RematchTeamTemplate")
	local scrollBar = scrollFrame.scrollBar
	scrollBar.doNotHide = true
	scrollBar.trackBG:SetPoint("TOPLEFT",-2,15)
	scrollBar.trackBG:SetPoint("BOTTOMRIGHT",2,-15)
	scrollBar.trackBG:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
	scrollBar.trackBG:SetGradientAlpha("HORIZONTAL",.125,.125,.125,1,.05,.05,.05,1)

	rematch.teamMenu = {
		{text="Rename",notCheckable=true,func=rematch.RenameSelectedTeam},
		{text="Send",notCheckable=true,func=rematch.SendSelectedTeam,disabled=true},
		{text="Export",notCheckable=true,func=rematch.ExportSelectedTeam},
		{text="Delete",notCheckable=true,func=rematch.DeleteSelectedTeam},
		{text="Cancel",notCheckable=true},
	}

	rematch.drawer:SetShown(settings.drawerShown)

	rematch.sidePanel:SetBackdropBorderColor(0.65,0.533,0)
end

function rematch:ToggleDrawer()
	local showDrawer = not rematch.drawer:IsVisible()
	rematch.drawer:SetShown(showDrawer)
	settings.drawerShown = settings.LockDrawer and showDrawer
	rematch:HideDropDown()
end

function rematch:DrawerOnShow()
	settings.drawerShown = settings.LockDrawer
	rematch:UpdateWindow()
	rematch:SetLevelingPet()
	rematch:MoveSidePanelStuff()
end

function rematch:DrawerOnHide()
	rematch.drawer.help:Hide()
	rematch:UpdateWindow()
end

function rematch:OrderTeamList()
	wipe(rematch.teamList)
	for k,v in pairs(savedTeams) do
		if k~="~temp~" then
			tinsert(rematch.teamList,k)
		end
	end
	table.sort(rematch.teamList,function(e1,e2) return e1:lower()<e2:lower() end)
end

function rematch:UpdateTeamList()
	rematch.drawer.teams.renameEditBox:Hide()
	rematch:HideDropDown()
	local numData = #rematch.teamList
	local scrollFrame = rematch.drawer.teams.scrollFrame
	local offset = HybridScrollFrame_GetOffset(scrollFrame)
	local buttons = scrollFrame.buttons
	for i=1, #buttons do
		local index = i + offset
		local button = buttons[i]
		button:Hide()
		button.selectedTexture:Hide()
		if ( index <= numData) then
			local team = rematch.teamList[index]
			button.team = team
			button.index = index
			if team==rematch.selectedTeam then
				button.selectedTexture:Show()
			end
			if savedTeams[team][4] then
				button.name:SetTextColor(1,1,1)
			else
				button.name:SetTextColor(1,.82,0)
			end
			button.name:SetText(team)
			for j=1,3 do
				local pet = savedTeams[team][j][1]
				local icon
				if pet==0 then
					icon = rematch.levelingIcon
				elseif type(pet)=="string" then -- this is an owned pet
					icon = select(9,C_PetJournal.GetPetInfoByPetID(pet))
				elseif type(pet)=="number" then -- this is a missing pet (species ID)
					icon = select(2,C_PetJournal.GetPetInfoBySpeciesID(pet))
				end
				button.ability[j]:SetTexture(icon or "Interface\\Buttons\\UI-PageButton-Background")
			end
			button:Show()
		end
	end
	HybridScrollFrame_Update(scrollFrame,18*numData,18)
--	rematch:VerifyButtons()
end

function rematch:TeamOnClick(button)
	local team = self.team
	if rematch.selectedTeam==team and button~="RightButton" then
		rematch:SetSelectedTeam(nil)
	else
		rematch:SetSelectedTeam(team)
	end
	rematch:UpdateTeamList()
	if button=="RightButton" then
		rematch.teamMenu[2].disabled = settings.DisableShare
		EasyMenu(rematch.teamMenu,rematch.dropDownFrame,"cursor",0,0,"MENU")
	end
end

function rematch:TeamOnDoubleClick(button)
	if button~="RightButton" then
		rematch.selectedTeam = self.team
		rematch:UpdateTeamList()
		rematch:UpdateSavedPets()
		rematch:LoadPets(self.team)
	end
end

function rematch:TeamOnEnter()
	if settings.JumpToTeam then
		rematch.drawer.teams:SetBackdropBorderColor(1,1,1)
	end
end

function rematch:TeamOnLeave()
	if settings.JumpToTeam then
		rematch.drawer.teams:SetBackdropBorderColor(1,.82,0)
	end
end

function rematch:GetSelectedIndex()
	for i=1,#rematch.teamList do
		if rematch.selectedTeam == rematch.teamList[i] then
			return i
		end
	end
end

function rematch:ScrollToSelectedTeam()
	return rematch:ScrollToTeamIndex(rematch:GetSelectedIndex())
end

-- scrolls to an index in teamList and returns the button it scrolled to
function rematch:ScrollToTeamIndex(index)
	if index then
		local scrollFrame = rematch.drawer.teams.scrollFrame
		local buttons = scrollFrame.buttons
		local height = math.max(0,floor(scrollFrame.buttonHeight*(index-(#buttons)/2)))
		HybridScrollFrame_SetOffset(scrollFrame,height)
		scrollFrame.scrollBar:SetValue(height)
		for i=1,#buttons do
			if buttons[i].index==index then
				return buttons[i]
			end
		end
	end
end

--[[ Help Plates ]]--

rematch.helpPlate = {
	FramePos={x=0,y=0},	FrameSize={width=282,height=295},
	[1] = {ButtonPos={x=102, y=-32}, HighLightBox={x=6, y=-12, width=238, height=82}, ToolTipDir="DOWN", ToolTipText = "These are your currently loaded pets and their abilities.\n\nYou can drag pets to or from here. You can also swap abilities here as well.\n\nIf a pet is under 25 you can right-click it to mark it as a leveling pet." },
	[2] = {ButtonPos={x=237, y=-32}, HighLightBox={x=246, y=-20, width=28, height=66}, ToolTipDir="LEFT", ToolTipText = "Revive Battle Pet and Battle Pet Bandages can be used to heal your pets." },
	[3] = {ButtonPos={x=84, y=-122}, HighLightBox={x=6, y=-118, width=196, height=54}, ToolTipDir="DOWN", ToolTipText = "This area displays the pets and abilities saved in a selected team." },
	[4] = {ButtonPos={x=220, y=-122}, HighLightBox={x=206, y=-118, width=70, height=54}, ToolTipDir="LEFT", ToolTipText = "This area displays pet types your selected team is strongest and weakest against." },
	[5] = {ButtonPos={x=216, y=-204}, HighLightBox={x=210, y=-195, width=56, height=63}, ToolTipDir="LEFT", ToolTipText = "This is the leveling slot.\n\nDrag a level 1-24 pet here to set it as the current leveling pet.\n\nWhen a team is saved with the current leveling pet, that pet's place on the team is reserved for future leveling pets.\n\nThis slot can contain as many leveling pets as you want. When a pet reaches 25 the next pet in the queue becomes your new leveling pet." },
	[6] = {ButtonPos={x=84, y=-252},	HighLightBox={x=6, y=-175,width=196,height=200}, ToolTipDir="UP", ToolTipText = "These are the battle pet teams you've saved.\n\nA white name means it was saved for a specific NPC ID.\n\nRight-click a team to rename it, send it to a friend, export or delete it." },
}

function rematch:RematchHelpButton()
	rematch.drawer.help:SetShown(not rematch.drawer.help:IsVisible())
end

function rematch:ScaleHelpPlates()
	local coefficient
	local helpPlate = rematch.helpPlate
	if settings.LargeWindow and not helpPlate.LargeWindow then
		coefficient = 1.25
	elseif not settings.LargeWindow and helpPlate.LargeWindow then
		coefficient = 1/1.25
	end

	if coefficient then
		local index = 1
		while helpPlate[index] do
			for _,area in pairs(helpPlate[index]) do
				if type(area)=="table" then
					for key,value in pairs(area) do
						area[key] = area[key] * coefficient
					end
				end
			end
			index = index + 1
		end
		helpPlate.LargeWindow = settings.LargeWindow
	end

end

function rematch:HelpOnShow()
	rematch:ScaleHelpPlates()
	HelpPlate_Show(rematch.helpPlate, rematch, rematch.drawer.helpButton, true)
end

function rematch:HelpOnHide()
	if HelpPlate_IsShowing(rematch.helpPlate) then
		HelpPlate_Hide(false)
	end
end

--[[ Rename ]]--

-- rename panel button
function rematch:RenameSelectedTeam()
	if rematch.selectedTeam then
		local editBox = rematch.drawer.teams.renameEditBox
		local oldName = rematch.selectedTeam
		local button = rematch:ScrollToSelectedTeam()
		if button then
			editBox:SetFrameLevel(rematch.drawer.teams.scrollFrame:GetFrameLevel()+4)
			editBox:SetPoint("TOPLEFT",button,"TOPLEFT",3,0)
			editBox:SetText(oldName)
			editBox:Show()
		end
	end
end

function rematch:RenameOnTextChanged()
	local editBox = rematch.drawer.teams.renameEditBox
	local teamName = editBox:GetText()
	if teamName~=rematch.selectedTeam and savedTeams[teamName] then
		editBox:SetTextColor(1,.1,.1) -- colors editbox red when name matches an existing team
	else
		editBox:SetTextColor(1,.82,0)
	end
end

function rematch:RenameOnEnterPressed()
	local editBox = rematch.drawer.teams.renameEditBox
	local teamName = editBox:GetText()
	if teamName==rematch.selectedTeam then
		editBox:Hide() -- name is unchanged, hide editbox and don't do anything
		return
	elseif not teamName or teamName=="" or savedTeams[teamName] then
		return -- not a valid name, don't do anything
	end
	editBox:Hide()
	-- copy teamName from editbox to selectedTeam
	savedTeams[teamName] = {}
	for i=1,3 do
		savedTeams[teamName][i] = {}
		for j=1,4 do
			savedTeams[teamName][i][j] = savedTeams[rematch.selectedTeam][i][j]
		end
	end
	savedTeams[rematch.selectedTeam] = nil
	rematch:SetSelectedTeam(teamName)
	rematch:ScrollToSelectedTeam()
end

--[[ Side Panel ]]

-- this changes the shape/position/visibility of the pullout side panel
-- MoveSidePanelStuff does the actual moving of stuff from the drawer to the panel and vice versa
function rematch:UpdateSidePanel()
	local panel = rematch.sidePanel
	panel:SetShown(not rematch.drawer:IsVisible() and settings.ShowSidePanel)
	if rematch.drawer:IsVisible() or not settings.ShowSidePanel then
		return
	end
	local normalTex = panel.toggleButton:GetNormalTexture()
	local highlightTex = panel.toggleButton:GetHighlightTexture()

	local isLeft = rematch.toggle:GetRight()*rematch.toggle:GetEffectiveScale() < (UIParent:GetWidth()*UIParent:GetEffectiveScale())/2

	panel:ClearAllPoints()
	panel.toggleButton:ClearAllPoints()
	if settings.sidePanelOpen then
		if not isLeft then
			panel:SetPoint("TOPRIGHT",rematch,"TOPLEFT",8,0)
			normalTex:SetTexCoord(1,.5,0,1)
			highlightTex:SetTexCoord(1,.5,0,1)
		else
			panel:SetPoint("TOPLEFT",rematch,"TOPRIGHT",-8,0)
			normalTex:SetTexCoord(.5,1,0,1)
			highlightTex:SetTexCoord(.5,1,0,1)
		end
	else
		if not isLeft then
			panel:SetPoint("TOPRIGHT",rematch,"TOPLEFT",69,0)
			normalTex:SetTexCoord(.5,0,0,1)
			highlightTex:SetTexCoord(.5,0,0,1)
		else
			panel:SetPoint("TOPLEFT",rematch,"TOPRIGHT",-69,0)
			normalTex:SetTexCoord(0,.5,0,1)
			highlightTex:SetTexCoord(0,.5,0,1)
		end
	end
	if isLeft then
		panel.toggleButton:SetPoint("RIGHT",-3,0)
		panel.backShadow:SetTexCoord(1,0,0,1)
	else
		panel.toggleButton:SetPoint("LEFT",3,0)
		panel.backShadow:SetTexCoord(0,1,0,1)
	end
	rematch:MoveSidePanelStuff()
end

function rematch:SidePanelToggle()
	settings.sidePanelOpen = not settings.sidePanelOpen
	rematch:UpdateSidePanel()
end

function rematch:SidePanelOnShow()
	rematch:MoveSidePanelStuff()
	RematchLevelingQueueFrame:Hide()
end

-- moves elements from drawer to side panel and vice versa
-- only needs to run when drawer opened or closed
function rematch:MoveSidePanelStuff()
	local drawerOpen = rematch.drawer:IsVisible() or not settings.sidePanelOpen or not settings.ShowSidePanel
	local levelingSlot = rematch.drawer.leveling
	local panel = rematch.sidePanel

	-- small adjustment to re-center depending on whether panel opens to left or right
	local xoff = rematch.sidePanel:GetPoint()=="TOPLEFT" and -2 or 2

	-- move leveling slot and queue
	levelingSlot:ClearAllPoints()
	levelingSlot:SetParent(drawerOpen and rematch.drawer or panel)
	if drawerOpen then
		levelingSlot:SetPoint("BOTTOM",rematch.drawer.optionsButton,"TOP",0,40)
	else
		levelingSlot:SetPoint("TOP",xoff,-24)
	end
	local queue = RematchLevelingQueueFrame
	queue:ClearAllPoints()
	queue:SetPoint("TOP",drawerOpen and rematch.drawer.leveling or panel,drawerOpen and "BOTTOM" or "TOP",drawerOpen and 0 or xoff,drawerOpen and 0 or -5)
	queue:SetFrameStrata("HIGH") -- need to reassert strata when parent reparented

	-- nudge queue button
	RematchSidePanelQueueButton:ClearAllPoints()
	RematchSidePanelQueueButton:SetPoint("BOTTOM",xoff,36)

	-- move/reshape auto load option
	local autoLoad = rematch.drawer.options.checks.AutoLoad
	autoLoad:SetParent(drawerOpen and rematch.drawer.options.checks or panel)
	autoLoad:ClearAllPoints()
	if drawerOpen then
		autoLoad:SetPoint("TOPLEFT",rematch.drawer.options.checks.AutoShow,"BOTTOMLEFT",0,4)
		autoLoad.text:SetText("Auto load")
		autoLoad:SetHitRectInsets(0,-80,0,0)
	else
		autoLoad:SetPoint("BOTTOMLEFT",rematch.sidePanel,"BOTTOMLEFT",11,8)
		autoLoad.text:SetText("Auto\nLoad")
		autoLoad:SetHitRectInsets(0,0,0,0)
	end

end

function rematch:RematchSidePanelQueueButton()
	if rematch:GetLevelingPetID() then
		rematch:ProcessLevelingQueue()
		rematch:UpdateLevelingQueue()
		RematchLevelingQueueFrame:Show()
	end
end