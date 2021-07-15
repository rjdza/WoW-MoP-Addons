
local rematch = Rematch
local queueFrame = RematchLevelingQueueFrame
local settings

-- the ordered leveling queue is settings.LevelingQueue
rematch.levelingPetsByID = {} -- for faster lookups, this is all pets in the queue indexed by petID

rematch.levelingIcon = "Interface\\AddOns\\Rematch\\leveling" -- future updates will have this line only and not check if on 2.2.6

function rematch:InitializeLeveling()
	settings = RematchSettings

	-- setup levelingQueue HybridsScrollFrame (queueFrame.scrollFrame)
	local scrollFrame = queueFrame.scrollFrame
	scrollFrame.update = rematch.UpdateLevelingQueue
	scrollFrame.stepSize = 22
	HybridScrollFrame_CreateButtons(scrollFrame,"RematchLevelingQueueTemplate")
	local scrollBar = scrollFrame.scrollBar
	RematchLevelingQueueFrameScrollFrameScrollBarScrollUpButton:SetSize(14,12)
	RematchLevelingQueueFrameScrollFrameScrollBarScrollDownButton:SetSize(14,12)
	scrollBar.thumbTexture:SetSize(14,18)
	scrollBar.doNotHide = true
	scrollBar.trackBG:SetPoint("TOPLEFT",-1,15)
	scrollBar.trackBG:SetPoint("BOTTOMRIGHT",0,-15)
	scrollBar.trackBG:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
	scrollBar.trackBG:SetGradientAlpha("HORIZONTAL",.125,.125,.125,1,.05,.05,.05,1)
	queueFrame.emptyCapture:SetFrameLevel(scrollFrame:GetFrameLevel()+2)

	rematch.drawer.leveling.set = 3 -- set 3 is leveling pet
	rematch.drawer.leveling:RegisterForClicks("LeftButtonUp","RightButtonUp")
	rematch.drawer.leveling:RegisterForDrag("LeftButton")

	rematch.drawer.leveling.leveling:Show() -- SetShown(petID~=nil)

end

--[[ Leveling Pet System ]]

function rematch:GetLevelingPetID()
	return settings.LevelingQueue[1]
end

function rematch:GetLevelingPetIcon()
	local petID = settings.LevelingQueue[1]
	local icon = petID and (select(9,C_PetJournal.GetPetInfoByPetID(petID))) or rematch.levelingIcon
	return icon
end

-- pass no petID when just wanting to update the slot
function rematch:SetLevelingPet(petID)
	local oldPetID = rematch.drawer.leveling.petID
	if petID and C_PetJournal.GetPetInfoByPetID(petID) then
		rematch:DeleteFromLevelingQueue(petID) -- if petID already in queue, remove it
		tinsert(settings.LevelingQueue,1,petID) -- and insert it into top of queue
	end
	local currentPetID = rematch:GetLevelingPetID()
	rematch.drawer.leveling.petID = currentPetID
	rematch.drawer.leveling.icon:SetTexture(rematch:GetLevelingPetIcon())
	rematch:UpdateLevelingBorders()
	rematch:UpdateSavedPets()
	if oldPetID and currentPetID and oldPetID~=currentPetID then
		-- there was an old leveling pet and now there's a new one
		-- see if old one is in any loadout slots and replace with new one if so
		for i=1,3 do
			if C_PetJournal.GetPetLoadOutInfo(i)==oldPetID then
				rematch:SummonedPetMayChange()
				C_PetJournal.SetPetLoadOutInfo(i,currentPetID)
				break
			end
		end
	end
	-- update pet level display
	if currentPetID then
		rematch.drawer.leveling.level.text:SetText((select(3,C_PetJournal.GetPetInfoByPetID(currentPetID))))
	end
	rematch.drawer.leveling.level:SetShown(currentPetID and true)
	RematchSidePanelQueueButton:SetEnabled(rematch:GetLevelingPetID() and true)
end

-- returns true if petID is below 25 and can battle
function rematch:PetCanLevel(petID)
	if petID or type(petID)=="string" then
		local _,_,level,_,_,_,_,_,_,_,_,_,_,_,canBattle = C_PetJournal.GetPetInfoByPetID(petID)
		if level and level<25 and canBattle then
			return true
		end
	end
end

-- returns true if the petID is the *current* leveling pet
function rematch:IsCurrentLevelingPet(petID)
	return petID and settings.LevelingQueue[1]==petID
end

-- returns index in queue, whether it's the last pet if petID is in queue, and queue length
function rematch:GetLevelingPetSlot(petID)
	local queue = settings.LevelingQueue
	if rematch:IsPetLeveling(petID) then
		for i=1,#queue do
			if queue[i]==petID then
				return i,i==#queue,#queue
			end
		end
	end
	return nil,nil,#queue
end

function rematch:IsPetLeveling(petID)
	return petID and rematch.levelingPetsByID[petID]
end


function rematch:GetLevelingPetByIndex(index)
	return settings.LevelingQueue[index]
end

function rematch:UpdateLevelingBorders()
	local petID = settings.LevelingQueue[1]
	for i=1,3 do
		rematch.current.pet[i].leveling:SetShown(petID and rematch.current.pet[i].petID==petID)
	end
end

--[[ Leveling Slot ]]

function rematch:LevelingSlotOnEnter()
	if not queueFrame:IsVisible() and rematch.drawer.leveling:GetParent()==rematch.drawer then
		rematch:ProcessLevelingQueue()
		rematch:UpdateLevelingQueue()
		if #settings.LevelingQueue>0 then
			queueFrame:Show() -- show queue on mouseover (if there's already a leveling pet)
		end
	end
	if not rematch:GetLevelingPetID() then
		local cursorType,petID = GetCursorInfo()
		if cursorType=="battlepet" and select(3,C_PetJournal.GetPetInfoByPetID(petID))<25 then
			return -- don't show helpplate (or floatingpetcard) if a pet under 25 is on mouse
		end
		HelpPlate_TooltipHide()
		HelpPlateTooltip.ArrowLEFT:Show()
		HelpPlateTooltip.ArrowGlowLEFT:Show()
		HelpPlateTooltip:SetPoint("RIGHT", self, "LEFT", -10, 0)
		HelpPlateTooltip.Text:SetText(Rematch.helpPlate[5].ToolTipText)
		HelpPlateTooltip:Show()
	else
		rematch:ShowFloatingPetCard(self.petID,self)
	end
end

function rematch:LevelingSlotOnLeave()
	HelpPlate_TooltipHide()
	rematch.PetOnLeave(self)
end

function rematch:LevelingSlotOnClick(button)
	if button=="RightButton" and rematch:GetLevelingPetID() then
		rematch.dropDownPetID = self.petID
		rematch.dropDownPetSlot = nil
		rematch:ShowDropDown(3)
	else
		rematch.PetOnClick(self,button)
		rematch:ProcessLevelingQueue()
		rematch:UpdateLevelingQueue()
		rematch:UpdateLevelingMarkersOnJournal()
	end
end

--[[ Leveling Queue ]]

-- updates the hybridscrollframe in the levelingqueue
function rematch:UpdateLevelingQueue()
	local queue = settings.LevelingQueue
	local numData = #queue
	local scrollFrame = queueFrame.scrollFrame
	local offset = HybridScrollFrame_GetOffset(scrollFrame)
	local buttons = scrollFrame.buttons
	local lastButton
	for i=1, #buttons do
		local index = i + offset
		local button = buttons[i]
		if ( index <= numData) then
			button.petID = queue[index]
			button.index = index
			local _,_,level,_,_,_,_,_,icon,petType = C_PetJournal.GetPetInfoByPetID(button.petID)
			if icon then
				button.icon:SetTexture(icon)
				button.level:SetText(level)
				local rarity = select(5,C_PetJournal.GetPetStats(button.petID))
		    local r,g,b = ITEM_QUALITY_COLORS[rarity-1].r, ITEM_QUALITY_COLORS[rarity-1].g, ITEM_QUALITY_COLORS[rarity-1].b
		    button.rarity:SetGradientAlpha("VERTICAL",r,g,b,.25,r,g,b,.6)
				if button==GetMouseFocus() then
					rematch.LevelingQueueOnEnter(button) -- we're scrolling, pretend moving into this button
				end
			end
			lastButton = button
			button:Show()
		else
			button.petID = nil
			button.index = nil
			button:Hide()
		end
	end
	-- a scrollframe can't receive clicks/drags; this invisible button will capture clicks/drags to empty area of scrollframe
	if numData<5 then
		queueFrame.emptyCapture:SetPoint("TOPLEFT",lastButton,"BOTTOMLEFT",0,0)
		queueFrame.emptyCapture:Show()
	else
		queueFrame.emptyCapture:Hide()
	end
	HybridScrollFrame_Update(scrollFrame,22*numData,22)
end

function rematch:LevelingQueueOnUpdate(elapsed)
	local focus = GetMouseFocus()
	-- if mouse is no longer over queue/leveling slot and menu isn't up, the hide queue and process leveling queue in case anything moved to first
	if not queueFrame:IsMouseOver() and focus~=rematch.drawer.leveling and not (UIDROPDOWNMENU_OPEN_MENU==rematch.dropDownFrame and DropDownList1:IsVisible()) then
		queueFrame.draggingPetID = nil
		queueFrame.draggingIndex = nil
		self:Hide()
		rematch:HideDropDown()
		rematch:ProcessLevelingQueue()
	else
		-- otherwise see if a pet is being dragged from within the queue and needs to swap
		if queueFrame.draggingIndex and focus and focus.index and focus.index~=queueFrame.draggingIndex and focus.petID then
			local focusPetID = focus.petID
			settings.LevelingQueue[focus.index] = queueFrame.draggingPetID
			settings.LevelingQueue[queueFrame.draggingIndex] = focusPetID
			queueFrame.draggingIndex = focus.index
			rematch:UpdateLevelingQueue()
		end
	end
end

function rematch:DeleteFromLevelingQueue(petID)
	if petID then
		local queue = settings.LevelingQueue
		for i=1,#queue do
			if queue[i]==petID then
				table.remove(queue,i)
				return
			end
		end
	end
end

function rematch:ProcessLevelingQueue()
	if C_PetBattles.IsInBattle() then
		rematch:RegisterEvent("PET_BATTLE_OVER") -- in case a pet levels to 25 when we're in pet battle
	end
	if InCombatLockdown() then
		rematch.queueNeedsProcessed = true -- in case a pet levels to 25 when we're in combat
		return
	end
	local queue = settings.LevelingQueue
	for i=#queue,1,-1 do -- remove any pets that no longer exist, are 25 or can't battle
		if not rematch:PetCanLevel(queue[i]) then
			tremove(queue,i)
		end
	end
	wipe(rematch.levelingPetsByID)
	for i=1,#queue do
		rematch.levelingPetsByID[queue[i]] = 1
	end
	rematch:SetLevelingPet()
end

-- display floating pet card of pet within the queue
function rematch:LevelingQueueOnEnter()
	local button = self or GetMouseFocus()
	if button and button.petID then
		rematch:ShowFloatingPetCard(button.petID,button)
	else
		rematch:HideFloatingPetCard()
	end
end

function rematch:LevelingQueueOnLeave()
	rematch:HideFloatingPetCard()
end

-- when pets within the queue are dragged around, note the ID and index for the OnUpdate to watch
function rematch:LevelingQueueOnDragStart()
	if not GetCursorInfo() then
		queueFrame.draggingPetID = self.petID
		queueFrame.draggingIndex = self.index
	end
end

-- when dragging stops, clear the dragging info; but note this handler happens anywhere the mouse button is released
function rematch:LevelingQueueOnDragStop()
	if GetMouseFocus()==rematch.drawer.leveling then -- if dragging to levelingslot, set the leveling pet
		rematch:SetLevelingPet(queueFrame.draggingPetID)
		rematch:UpdateLevelingQueue()
	end
	queueFrame.draggingPetID = nil
	queueFrame.draggingIndex = nil
end

-- when a pet within the queue is clicked
function rematch:LevelingQueueOnClick(button)
	if button=="RightButton" and self.petID then
		rematch.dropDownPetID = self.petID
		rematch:ShowDropDown(4)
	else
		if GetCursorInfo()=="battlepet" then
			rematch:LevelingQueueOnReceiveDrag()
		else
			rematch.PetOnClick(self,button) -- do left-click stuff
		end
	end
end

-- remember that this handler can trigger when draggingPetIDs are dragged around too
function rematch:LevelingQueueOnReceiveDrag()
	local cursorType,petID = GetCursorInfo()
	local focus = GetMouseFocus()
	if cursorType=="battlepet" and rematch:PetCanLevel(petID) then
		rematch:DeleteFromLevelingQueue(petID)
		if focus.index then -- dragged onto an existing pet in queue
			tinsert(settings.LevelingQueue,focus.index,petID)
		else -- dragged onto empty area of queue (add to end)
			tinsert(settings.LevelingQueue,petID)
		end
		rematch:ProcessLevelingQueue()
		rematch:UpdateLevelingQueue()
		rematch:UpdateLevelingMarkersOnJournal()
		ClearCursor()
	end
end

-- in ADDON_LOADED of the pet journal, HybridScrollFrame_Update is hooked to this
-- to go through all buttons in the journal to show/hide a leveling icon
function rematch:UpdateLevelingMarkersHook()
	if self==PetJournalListScrollFrame or self==PetJournalEnhancedListScrollFrame then
		for i=1,#self.buttons do
			local petID = self.buttons[i].petID
			local showIcon
			local icon = self.buttons[i].rematchLevelingPet
			if petID and rematch:IsPetLeveling(petID) then
				if not icon then
					self.buttons[i].rematchLevelingPet = self.buttons[i]:CreateTexture(nil,"ARTWORK")
					icon = self.buttons[i].rematchLevelingPet
					icon:SetSize(24,24)
					icon:SetPoint("RIGHT",-8,0)
					icon:SetTexture(rematch.levelingIcon)
				end
				showIcon = true
			end
			if icon then
				icon:SetShown(showIcon)
			end
		end
	end
end

-- call when pets are added or removed from leveling queue manually
function rematch:UpdateLevelingMarkersOnJournal()
	if PetJournalEnhanced then
		rematch.UpdateLevelingMarkersHook(PetJournalEnhancedListScrollFrame)
	elseif PetJournal then
		rematch.UpdateLevelingMarkersHook(PetJournalListScrollFrame)
	end
	if rematch.browser:IsVisible() then
		rematch:UpdateBrowser()
	end
end
